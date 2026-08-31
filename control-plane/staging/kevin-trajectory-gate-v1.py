#!/usr/bin/env python3
"""Kevin Trajectory Reliability Gate v1.

Deterministic, authority-neutral evaluator for repeated GREEN capability trials.
It never executes a capability. It judges already-produced sanitized evidence.

Promotion principle: a model saying DONE is irrelevant unless every required action
occurred, no forbidden action occurred, semantic verification passed, and the
expected end state was independently observed on every trial.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

SHA256 = re.compile(r"^[A-Fa-f0-9]{64}$")
ID = re.compile(r"^[A-Za-z0-9._-]{3,96}$")
VERSION = re.compile(r"^[A-Za-z0-9._-]{1,32}$")
MAX_TRIALS = 10
MIN_TRIALS = 2


class EvidenceError(ValueError):
    pass


def _sha(value: Any, field: str) -> str:
    s = str(value or "")
    if not SHA256.fullmatch(s):
        raise EvidenceError(f"{field} must be SHA256")
    return s.upper()


def _id(value: Any, field: str) -> str:
    s = str(value or "")
    if not ID.fullmatch(s):
        raise EvidenceError(f"{field} invalid")
    return s


def _version(value: Any) -> str:
    s = str(value or "")
    if not VERSION.fullmatch(s):
        raise EvidenceError("version invalid")
    return s


def _actions(value: Any, field: str) -> list[str]:
    if not isinstance(value, list) or len(value) > 32:
        raise EvidenceError(f"{field} invalid")
    out: list[str] = []
    for x in value:
        s = str(x)
        if not ID.fullmatch(s):
            raise EvidenceError(f"{field} action invalid")
        out.append(s)
    if len(set(out)) != len(out):
        raise EvidenceError(f"{field} contains duplicates")
    return out


def evaluate(doc: dict[str, Any]) -> dict[str, Any]:
    if doc.get("schema") != 1 or doc.get("kind") != "kevin-trajectory-evidence":
        raise EvidenceError("schema/kind invalid")
    if doc.get("authority_class") != "GREEN" or doc.get("authority_delta") != "NONE":
        raise EvidenceError("trajectory gate accepts authority-neutral GREEN evidence only")

    capability_id = _id(doc.get("capability_id"), "capability_id")
    version = _version(doc.get("version"))
    expected_end = _sha(doc.get("expected_end_state_sha256"), "expected_end_state_sha256")
    required = _actions(doc.get("required_actions"), "required_actions")
    forbidden = _actions(doc.get("forbidden_actions"), "forbidden_actions")
    overlap = sorted(set(required) & set(forbidden))
    if overlap:
        raise EvidenceError("required/forbidden action overlap")

    trials = doc.get("trials")
    if not isinstance(trials, list) or not (MIN_TRIALS <= len(trials) <= MAX_TRIALS):
        raise EvidenceError(f"trials must contain {MIN_TRIALS}..{MAX_TRIALS} runs")

    seen: set[str] = set()
    results: list[dict[str, Any]] = []
    total_duration = 0
    total_retries = 0

    for i, trial in enumerate(trials):
        if not isinstance(trial, dict):
            raise EvidenceError(f"trial[{i}] invalid")
        trial_id = _id(trial.get("trial_id"), f"trial[{i}].trial_id")
        if trial_id in seen:
            raise EvidenceError("duplicate trial_id")
        seen.add(trial_id)

        status = str(trial.get("status") or "")
        semantic_ok = trial.get("semantic_ok") is True
        end_state = _sha(trial.get("observed_end_state_sha256"), f"trial[{i}].observed_end_state_sha256")
        output_sha = _sha(trial.get("output_sha256"), f"trial[{i}].output_sha256")
        completed = _actions(trial.get("completed_actions"), f"trial[{i}].completed_actions")
        observed_forbidden = _actions(trial.get("observed_forbidden_actions"), f"trial[{i}].observed_forbidden_actions")
        retries = int(trial.get("retries", 0))
        duration_ms = int(trial.get("duration_ms", 0))
        if retries < 0 or retries > 20 or duration_ms < 0 or duration_ms > 86_400_000:
            raise EvidenceError(f"trial[{i}] counters invalid")

        missing = sorted(set(required) - set(completed))
        unexpected = sorted(set(completed) & set(forbidden))
        forbidden_seen = sorted(set(observed_forbidden) | set(unexpected))
        reasons: list[str] = []
        if status != "DONE":
            reasons.append("STATUS_NOT_DONE")
        if not semantic_ok:
            reasons.append("SEMANTIC_VERIFIER_FAILED")
        if end_state != expected_end:
            reasons.append("END_STATE_MISMATCH")
        if missing:
            reasons.append("REQUIRED_ACTION_MISSING")
        if forbidden_seen:
            reasons.append("FORBIDDEN_ACTION_OBSERVED")

        passed = not reasons
        total_duration += duration_ms
        total_retries += retries
        results.append(
            {
                "trial_id": trial_id,
                "passed": passed,
                "reasons": reasons,
                "missing_required_actions": missing,
                "forbidden_actions_observed": forbidden_seen,
                "output_sha256": output_sha,
                "duration_ms": duration_ms,
                "retries": retries,
            }
        )

    passes = sum(1 for r in results if r["passed"])
    k = len(results)
    all_pass = passes == k
    verdict = "REPEATEDLY_PROVEN" if all_pass else "REJECT"
    return {
        "schema": 1,
        "kind": "kevin-trajectory-gate-result",
        "capability": f"{capability_id}@{version}",
        "authority_effect": "NONE",
        "verdict": verdict,
        "pass_k": f"{passes}/{k}",
        "reliability": passes / k,
        "promotion_eligible": all_pass,
        "semantic_success_required": True,
        "all_required_actions_required": True,
        "forbidden_action_tolerance": 0,
        "expected_end_state_sha256": expected_end,
        "total_retries": total_retries,
        "mean_duration_ms": round(total_duration / k, 2),
        "trials": results,
        "truth_boundary": "This gate validates repeated sanitized trajectory evidence only. It grants no new primitive authority and does not prove evidence authenticity unless the producer is independently trusted.",
    }


def selftest() -> None:
    h = "A" * 64
    base = {
        "schema": 1,
        "kind": "kevin-trajectory-evidence",
        "authority_class": "GREEN",
        "authority_delta": "NONE",
        "capability_id": "reader-status-e2e",
        "version": "1",
        "expected_end_state_sha256": h,
        "required_actions": ["acquire", "interpret", "verify"],
        "forbidden_actions": ["shell", "purchase"],
        "trials": [],
    }
    good = {
        "trial_id": "run-1",
        "status": "DONE",
        "semantic_ok": True,
        "observed_end_state_sha256": h,
        "output_sha256": "B" * 64,
        "completed_actions": ["acquire", "interpret", "verify"],
        "observed_forbidden_actions": [],
        "retries": 0,
        "duration_ms": 100,
    }
    base["trials"] = [good, {**good, "trial_id": "run-2", "output_sha256": "C" * 64}]
    r = evaluate(base)
    assert r["verdict"] == "REPEATEDLY_PROVEN" and r["pass_k"] == "2/2"

    false_done = json.loads(json.dumps(base))
    false_done["trials"][1]["semantic_ok"] = False
    r = evaluate(false_done)
    assert r["verdict"] == "REJECT" and "SEMANTIC_VERIFIER_FAILED" in r["trials"][1]["reasons"]

    missing = json.loads(json.dumps(base))
    missing["trials"][1]["completed_actions"] = ["acquire", "interpret"]
    r = evaluate(missing)
    assert "REQUIRED_ACTION_MISSING" in r["trials"][1]["reasons"]

    forbidden = json.loads(json.dumps(base))
    forbidden["trials"][1]["observed_forbidden_actions"] = ["shell"]
    r = evaluate(forbidden)
    assert "FORBIDDEN_ACTION_OBSERVED" in r["trials"][1]["reasons"]

    wrong_end = json.loads(json.dumps(base))
    wrong_end["trials"][1]["observed_end_state_sha256"] = "D" * 64
    r = evaluate(wrong_end)
    assert "END_STATE_MISMATCH" in r["trials"][1]["reasons"]

    print("KEVIN TRAJECTORY GATE v1 SELFTEST PASS pass_k=true semantic=true end_state=true forbidden_zero=true authority_effect=NONE")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--evidence")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    if args.selftest:
        selftest()
        return 0
    if not args.evidence:
        ap.error("--evidence required")
    try:
        doc = json.loads(Path(args.evidence).read_text(encoding="utf-8"))
        print(json.dumps(evaluate(doc), indent=2, sort_keys=True))
        return 0
    except (OSError, json.JSONDecodeError, EvidenceError, ValueError) as e:
        print(json.dumps({"schema": 1, "kind": "kevin-trajectory-gate-result", "verdict": "INVALID_EVIDENCE", "error": str(e)}))
        return 2


if __name__ == "__main__":
    sys.exit(main())
