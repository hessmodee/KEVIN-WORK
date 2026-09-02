"""Metadata-only diagnosis; this module cannot execute or authorize a repair.

The CLI reads the one public main-canary receipt in this repository. The pure
envelope classifier is also available for a future, separately qualified local
collector. No raw model text, error messages, tool names, or config are emitted.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

VERSION = "1.0.0"
MAX_RECEIPT_BYTES = 65536
MAX_TOOLS = 256
MAX_PAYLOADS = 128
MISSING = object()
SHA256 = re.compile(r"[0-9a-fA-F]{64}\Z")
TOOL_NAME = re.compile(r"[A-Za-z][A-Za-z0-9_.:-]{0,127}\Z")

# Fingerprint of the public upstream overflow/recovery banner, not private text.
# Source: openclaw/openclaw@0790d9f593ad30c940ed93b5872a8cf6d6f3cf8c
# src/agents/embedded-agent-runner/run.ts (overflowRecoveryText).
OVERFLOW_SHA256 = "3C9BD342FA050017F16FF421A1288D97BE4F116174831E0A55A351C336112B4B"
OVERFLOW_CHARACTERS = 127
KNOWN_ERRORS = frozenset({
    "context_overflow", "compaction_failure", "context_window_too_small",
    "role_ordering", "image_too_large", "image_dimension", "retry_limit",
    "incomplete_turn", "hook_block",
})
KNOWN_STAGES = frozenset({
    "gateway_probe", "agent_cli", "agent_json_parse", "semantic_contract",
    "tool_evidence_missing_or_nonzero", "runtime_error", "",
})


def _path(obj: Any, *parts: str) -> Any:
    for part in parts:
        if not isinstance(obj, dict) or part not in obj:
            return MISSING
        obj = obj[part]
    return obj


def _integer(value: Any, maximum: int) -> bool:
    return type(value) is int and 0 <= value <= maximum


def _timestamp(value: Any) -> str | None:
    if (not isinstance(value, str) or len(value) > 40
            or not re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,9})?(?:Z|[+-][0-9]{2}:[0-9]{2})", value)):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None or not 2000 <= parsed.year <= 2100:
        return None
    return value


def _authority() -> dict[str, Any]:
    return {
        "authority_effect": "NONE",
        "retry_authorized": False,
        "acceptance_changed": False,
        "tool_policy_change_authorized": False,
        "root_cause_determined": False,
    }


def classify_runtime_envelope(envelope: Any) -> dict[str, Any]:
    """Keep runtime errors and missing inventory distinct from semantic failure.

    Only fixed, known paths are inspected. This does not certify the input's
    origin, correlate a turn, prove actual tool use, or declare canary success.
    """
    result: dict[str, Any] = {
        "schema": 1,
        "runtime_error_state": "UNKNOWN",
        "runtime_error_kind": None,
        "payload_error_reported": None,
        "inventory_state": "UNKNOWN",
        "inventory_sources": [],
        "visible_tool_count": None,
        "visible_tool_names_sha256": None,
        "has_kevin_system_status": None,
        "reported_tool_calls": None,
        "tool_call_evidence_state": "UNKNOWN",
        "actual_tool_use_proven": False,
        **_authority(),
    }
    if not isinstance(envelope, dict):
        result.update(runtime_error_state="INVALID", inventory_state="INVALID",
                      tool_call_evidence_state="INVALID")
        return result

    metas = [("META", _path(envelope, "meta")),
             ("RESULT_META", _path(envelope, "result", "meta"))]
    errors: list[str | None] = []
    bad_error = False
    inventories: list[tuple[str, list[str] | None]] = []
    bad_inventory = False
    calls: list[int] = []
    bad_calls = False
    for source, meta in metas:
        if meta is MISSING or meta is None:
            continue
        if not isinstance(meta, dict):
            bad_error = bad_inventory = bad_calls = True
            continue
        error = _path(meta, "error")
        if error is None:
            errors.append(None)
        elif error is not MISSING:
            kind = _path(error, "kind")
            if not isinstance(error, dict) or not isinstance(kind, str) or not kind or len(kind) > 80:
                bad_error = True
            else:
                # Retain only in memory to detect conflicting unknown kinds.
                # Never publish arbitrary error.kind values or error.message.
                errors.append(kind)

        entries = _path(meta, "systemPromptReport", "tools", "entries")
        if entries is not MISSING:
            result["inventory_sources"].append(source)
            if entries is None:
                inventories.append((source, None))
            elif not isinstance(entries, list) or len(entries) > MAX_TOOLS:
                bad_inventory = True
            else:
                names = []
                for entry in entries:
                    name = entry if isinstance(entry, str) else _path(entry, "name")
                    if not isinstance(name, str) or TOOL_NAME.fullmatch(name) is None:
                        bad_inventory = True
                        break
                    names.append(name)
                if len(set(names)) != len(names):
                    bad_inventory = True
                inventories.append((source, sorted(names)))

        count = _path(meta, "toolSummary", "calls")
        if count is not MISSING and count is not None:
            if _integer(count, 10000):
                calls.append(count)
            else:
                bad_calls = True

    payload_error: list[bool] = []
    for parts in [("payloads",), ("result", "payloads")]:
        payloads = _path(envelope, *parts)
        if payloads is MISSING or payloads is None:
            continue
        if not isinstance(payloads, list) or len(payloads) > MAX_PAYLOADS:
            bad_error = True
            continue
        group: list[bool] = []
        for payload in payloads:
            if not isinstance(payload, dict):
                bad_error = True
                continue
            flag = payload.get("isError", MISSING)
            if flag is not MISSING:
                if type(flag) is not bool:
                    bad_error = True
                else:
                    group.append(flag)
        if group:
            payload_error.append(any(group))
    if len(set(payload_error)) > 1:
        bad_error = True
    if payload_error:
        result["payload_error_reported"] = any(payload_error)
    if len(set(errors)) > 1:
        bad_error = True
    if errors and all(error is None for error in errors) and any(payload_error):
        bad_error = True
    if bad_error:
        result["runtime_error_state"] = "INVALID"
    elif errors and errors[0] is not None:
        kind = errors[0] if errors[0] in KNOWN_ERRORS else "OTHER_REPORTED_ERROR"
        result.update(runtime_error_state="ERROR_REPORTED", runtime_error_kind=kind)
    elif any(payload_error):
        result.update(runtime_error_state="ERROR_REPORTED", runtime_error_kind="UNCLASSIFIED")
    elif errors or payload_error:
        result["runtime_error_state"] = "NO_ERROR_REPORTED"

    if len(inventories) > 1 and inventories[0][1] != inventories[1][1]:
        bad_inventory = True
    if bad_inventory:
        result["inventory_state"] = "INVALID"
    elif inventories and inventories[0][1] is not None:
        names = inventories[0][1]
        result.update(
            inventory_state="REPORTED_NONEMPTY" if names else "REPORTED_EMPTY",
            visible_tool_count=len(names),
            visible_tool_names_sha256=hashlib.sha256("\n".join(names).encode()).hexdigest().upper(),
            has_kevin_system_status="kevin_system_status" in names,
        )
    if bad_calls or len(set(calls)) > 1:
        result["tool_call_evidence_state"] = "INVALID"
    elif calls:
        result.update(reported_tool_calls=calls[0], tool_call_evidence_state="REPORTED_ONLY")
    return result


def diagnose_public_receipt(receipt: Any) -> dict[str, Any]:
    """Recognize an exact published fingerprint without recovering private text."""
    report: dict[str, Any] = {
        "schema": 1,
        "kind": "kevin-main-canary-diagnosis-public",
        "classifier_version": VERSION,
        "safe_for_public_repo": True,
        "diagnosis": "INVALID_RECEIPT",
        "source_generated_at": None,
        "source_state": None,
        "source_failure_stage": None,
        "signature_match": False,
        "signature_id": None,
        "source_output_sha256": None,
        "source_final_characters": None,
        "transcript_state": "UNKNOWN",
        "tool_calls": None,
        "tool_inventory_state": "UNKNOWN",
        "next_evidence": [],
        **_authority(),
        "truth_boundary": "Deterministic classification of supplied metadata; no runtime repair, independent source authentication, complete-turn proof, or responsibility transfer is implied.",
    }
    if not isinstance(receipt, dict):
        return report
    stamp = _timestamp(receipt.get("generated_at"))
    shape = receipt.get("canary_shape")
    digest = receipt.get("output_sha256")
    state = receipt.get("state")
    if (receipt.get("schema") != 1 or type(receipt.get("schema")) is not int
            or receipt.get("kind") != "kevin-main-agent-canary-public"
            or receipt.get("agent") != "fixed:main"
            or receipt.get("safe_for_public_repo") is not True
            or state not in ("REJECT", "OMEN_PROVEN")
            or stamp is None
            or type(receipt.get("exact_expected_reply")) is not bool):
        return report
    stage = receipt.get("failure_stage")
    report.update(source_generated_at=stamp, source_state=state,
                  source_failure_stage=stage if isinstance(stage, str) and stage in KNOWN_STAGES else "UNKNOWN")
    # The existing publisher legitimately has no final-shape evidence when the
    # Gateway/CLI/JSON boundary fails before a final answer can be extracted.
    if (shape is None and state == "REJECT" and not receipt["exact_expected_reply"]
            and isinstance(stage, str) and stage in {"gateway_probe", "agent_cli", "agent_json_parse"}
            and isinstance(digest, str) and (digest == "" or SHA256.fullmatch(digest))):
        report.update(diagnosis="NO_FINAL_SIGNATURE_AVAILABLE",
                      next_evidence=["COLLECT_FIXED_RUNTIME_FAILURE_METADATA"])
        return report
    if (not isinstance(shape, dict) or not isinstance(digest, str)
            or not SHA256.fullmatch(digest) or not _integer(shape.get("final_length"), 1000000)):
        return report
    digest = digest.upper()
    report.update(
        diagnosis="UNCLASSIFIED_RECEIPT", source_generated_at=stamp,
        source_state=state, source_output_sha256=digest,
        source_final_characters=shape["final_length"],
        source_failure_stage=stage if isinstance(stage, str) and stage in KNOWN_STAGES else "UNKNOWN",
    )
    for field in ("final_exact_case_sensitive", "final_contains_expected"):
        if field in shape and type(shape[field]) is not bool:
            report["diagnosis"] = "INVALID_RECEIPT"
            return report
    trace = shape.get("transcript")
    if isinstance(trace, dict):
        complete = trace.get("complete")
        if complete is False:
            report["transcript_state"] = "INCOMPLETE_REPORTED"
        elif complete is True:
            count = trace.get("tool_calls")
            if (trace.get("present") is not True or trace.get("user_messages") != 1
                    or type(trace.get("user_messages")) is not int
                    or not _integer(trace.get("assistant_messages"), 1000)
                    or trace["assistant_messages"] < 1 or not _integer(count, 10000)
                    or receipt.get("tool_calls") != count
                    or type(receipt.get("tool_calls")) is not int):
                report["diagnosis"] = "CONTRADICTORY_RECEIPT"
                return report
            report.update(transcript_state="COMPLETE_REPORTED", tool_calls=count)
        elif complete is not None:
            report["diagnosis"] = "INVALID_RECEIPT"
            return report

    if digest == OVERFLOW_SHA256:
        report.update(signature_match=True, signature_id="OPENCLAW_CONTEXT_OVERFLOW_BANNER_V1")
        if (shape["final_length"] != OVERFLOW_CHARACTERS
                or state != "REJECT" or receipt["exact_expected_reply"]
                or shape.get("final_exact_case_sensitive") is True
                or shape.get("final_contains_expected") is True
                or (isinstance(trace, dict) and trace.get("final_exact") is True)):
            report["diagnosis"] = "CONTRADICTORY_RECEIPT"
            return report
        report.update(
            diagnosis="RUNTIME_CONTEXT_OVERFLOW_SIGNATURE_MATCH",
            next_evidence=[
                "QUALIFY_INSTALLED_RUNTIME_AND_COLLECTOR_SOURCE",
                "READ_EFFECTIVE_MAIN_MODEL_AND_CONTEXT_CONFIGURATION",
                "MEASURE_BOOTSTRAP_SKILLS_TOOLS_AND_RESERVED_OUTPUT_BUDGET",
                "READ_EXISTING_CORRELATED_SESSION_ERROR_METADATA",
                "REQUIRE_A_MATERIALLY_NEW_BOUNDED_REPAIR_HYPOTHESIS",
            ],
        )
    return report


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    obj: dict[str, Any] = {}
    for key, value in pairs:
        if key in obj:
            raise ValueError("duplicate JSON property")
        obj[key] = value
    return obj


def _reject_nonfinite(_token: str) -> None:
    raise ValueError("nonfinite JSON")


def read_fixed_public_receipt() -> dict[str, Any]:
    root = Path(__file__).resolve().parents[2]
    reports = root / "reports"
    path = reports / "main-agent-canary-omen.json"
    if reports.is_symlink() or path.is_symlink() or not path.is_file():
        raise ValueError("fixed receipt is unavailable")
    with path.open("rb") as stream:
        raw = stream.read(MAX_RECEIPT_BYTES + 1)
    if len(raw) > MAX_RECEIPT_BYTES:
        raise ValueError("receipt exceeds size bound")
    return json.loads(raw.decode("utf-8-sig"), object_pairs_hook=_unique_object,
                      parse_constant=_reject_nonfinite)


def main() -> int:
    if len(sys.argv) != 1:
        print(json.dumps({"error": "NO_CALLER_ARGUMENTS_ALLOWED", **_authority()}))
        return 2
    try:
        result = diagnose_public_receipt(read_fixed_public_receipt())
    except (OSError, ValueError, RecursionError):
        print(json.dumps({"error": "FIXED_RECEIPT_READ_REJECTED", **_authority()}))
        return 2
    print(json.dumps(result, indent=2, allow_nan=False))
    return 2 if result["diagnosis"] in ("INVALID_RECEIPT", "CONTRADICTORY_RECEIPT") else 0


if __name__ == "__main__":
    raise SystemExit(main())
