"""Pure contract for Kevin Benchmark R04 production-config rebaseline.

This module performs no filesystem, process, network, or configuration writes.
It exists so the exact one-leaf baseline transition can be proved independently
before any HESS-PC production crossing is attempted.
"""
from __future__ import annotations

import copy
import hashlib
import json
from typing import Any, Dict, Iterable, Tuple

TARGET_PATH = ("hashes", "production_config")
EXPECTED_CURRENT_CONFIG_SHA256 = "23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5"
EXPECTED_PREVIOUS_CONFIG_SHA256 = "215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84"
EXPECTED_BENCHMARK_SHA256 = "4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964"


class ContractError(ValueError):
    pass


def _sha(value: str, label: str) -> str:
    if not isinstance(value, str):
        raise ContractError(f"{label} must be a SHA256 string")
    out = value.strip().upper()
    if len(out) != 64 or any(c not in "0123456789ABCDEF" for c in out):
        raise ContractError(f"{label} must be a SHA256 string")
    return out


def _walk(value: Any, path: Tuple[str, ...] = ()) -> Iterable[Tuple[Tuple[str, ...], Any]]:
    if isinstance(value, dict) and value:
        for key in sorted(value):
            if not isinstance(key, str):
                raise ContractError("JSON object keys must be strings")
            yield from _walk(value[key], path + (key,))
        return
    if isinstance(value, list) and value:
        for index, item in enumerate(value):
            yield from _walk(item, path + (index,))
        return
    yield path, value


def semantic_leaf_map(value: Any) -> Dict[str, str]:
    if not isinstance(value, dict):
        raise ContractError("baseline root must be an object")
    result: Dict[str, str] = {}
    for path, leaf in _walk(value):
        # Encode unusual keys unambiguously; preserve familiar simple JSON paths.
        key = "$"
        for part in path:
            if isinstance(part, int):
                key += f"[{part}]"
            elif part.isidentifier():
                key += "." + part
            else:
                key += "[" + json.dumps(part, ensure_ascii=False) + "]"
        result[key] = json.dumps(leaf, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)
    return result


def non_target_fingerprint(value: Any) -> str:
    # Hash the complete structure, including empty containers and literal keys.
    value = copy.deepcopy(validate_baseline(value))
    del value["hashes"]["production_config"]
    canonical = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest().upper()


def validate_baseline(baseline: Any) -> Dict[str, Any]:
    if not isinstance(baseline, dict):
        raise ContractError("baseline root must be an object")
    if type(baseline.get("schema")) is not int or baseline["schema"] != 1:
        raise ContractError("baseline schema must be 1")
    if baseline.get("kind") != "kevin-benchmark-v1-baseline":
        raise ContractError("baseline kind mismatch")
    hashes = baseline.get("hashes")
    if not isinstance(hashes, dict):
        raise ContractError("baseline hashes object missing")
    required = {
        "supervisor",
        "forge",
        "production_config",
        "goal_os",
        "promotion_policy",
        "benchmark_spec",
        "benchmark_runner",
    }
    missing = sorted(required.difference(hashes))
    if missing:
        raise ContractError("baseline required hash keys missing: " + ",".join(missing))
    for key in required:
        _sha(hashes[key], f"baseline.hashes.{key}")
    if "reader_config" in hashes and hashes["reader_config"]:
        _sha(hashes["reader_config"], "baseline.hashes.reader_config")
    return baseline


def validate_preconditions(
    *,
    current_config_sha256: str,
    benchmark_runner_sha256: str,
    baseline: Any,
    latest_benchmark: Dict[str, Any],
) -> None:
    if _sha(current_config_sha256, "current config") != EXPECTED_CURRENT_CONFIG_SHA256:
        raise ContractError("current config identity does not match the owner-proven repaired config")
    if _sha(benchmark_runner_sha256, "benchmark runner") != EXPECTED_BENCHMARK_SHA256:
        raise ContractError("benchmark runner identity mismatch")
    baseline = validate_baseline(baseline)
    if _sha(baseline["hashes"]["production_config"], "baseline production_config") != EXPECTED_PREVIOUS_CONFIG_SHA256:
        raise ContractError("baseline production_config is not the exact pre-repair accepted identity")
    if _sha(baseline["hashes"]["benchmark_runner"], "baseline benchmark runner") != EXPECTED_BENCHMARK_SHA256:
        raise ContractError("baseline Benchmark runner anchor mismatch")
    if not isinstance(latest_benchmark, dict):
        raise ContractError("latest benchmark evidence missing")
    regression = latest_benchmark.get("regression")
    if not isinstance(regression, dict):
        raise ContractError("latest benchmark regression evidence missing")
    if latest_benchmark.get("status") != "FAIL_CRITICAL_REGRESSION":
        raise ContractError("latest benchmark status must be FAIL_CRITICAL_REGRESSION")
    for name, expected in (("passed", 29), ("total", 30), ("critical_failures", 1)):
        if type(regression.get(name)) is not int or regression[name] != expected:
            raise ContractError("latest benchmark must be exactly 29/30 critical1")
    rows = regression.get("rows")
    if not isinstance(rows, list) or len(rows) != 30:
        raise ContractError("Benchmark row evidence incomplete")
    expected_ids = {f"R{i:02d}" for i in range(1, 31)}
    seen = set()
    failed = []
    for row in rows:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str):
            raise ContractError("Benchmark row shape invalid")
        if row["id"] not in expected_ids or row["id"] in seen:
            raise ContractError("Benchmark row identity duplicate or unexpected")
        seen.add(row["id"])
        if type(row.get("pass")) is not bool or type(row.get("critical")) is not bool:
            raise ContractError("Benchmark row verdicts must be booleans")
        if not row["pass"]:
            failed.append(row)
    if len(failed) != 1 or failed[0]["id"] != "R04" or not failed[0]["critical"]:
        raise ContractError("latest benchmark row evidence is not R04-only critical failure")


def plan_rebaseline(baseline: Any) -> Dict[str, Any]:
    before = validate_baseline(copy.deepcopy(baseline))
    if _sha(before["hashes"]["production_config"], "before production_config") != EXPECTED_PREVIOUS_CONFIG_SHA256:
        raise ContractError("planner requires exact pre-repair accepted identity")
    before_fp = non_target_fingerprint(before)
    after = copy.deepcopy(before)
    after["hashes"]["production_config"] = EXPECTED_CURRENT_CONFIG_SHA256
    if non_target_fingerprint(after) != before_fp:
        raise ContractError("planner changed a non-target baseline leaf")
    before_leaves = semantic_leaf_map(before)
    after_leaves = semantic_leaf_map(after)
    changed = sorted(k for k in set(before_leaves) | set(after_leaves) if before_leaves.get(k) != after_leaves.get(k))
    if changed != ["$.hashes.production_config"]:
        raise ContractError("planner must change exactly $.hashes.production_config")
    return after


def validate_transition(before: Any, after: Any) -> None:
    validate_baseline(before)
    validate_baseline(after)
    if _sha(before["hashes"]["production_config"], "before production_config") != EXPECTED_PREVIOUS_CONFIG_SHA256:
        raise ContractError("transition requires exact pre-repair accepted identity")
    if _sha(after["hashes"]["production_config"], "after production_config") != EXPECTED_CURRENT_CONFIG_SHA256:
        raise ContractError("after production_config does not match repaired config")
    if non_target_fingerprint(before) != non_target_fingerprint(after):
        raise ContractError("non-target baseline semantics changed")
    before_leaves = semantic_leaf_map(before)
    after_leaves = semantic_leaf_map(after)
    changed = sorted(k for k in set(before_leaves) | set(after_leaves) if before_leaves.get(k) != after_leaves.get(k))
    if changed != ["$.hashes.production_config"]:
        raise ContractError("transition must change exactly one baseline leaf")
