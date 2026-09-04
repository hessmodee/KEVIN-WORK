#!/usr/bin/env python3
"""Kevin deterministic work-admission and priority selector v1.2.

This component never executes work and never grants authority. It selects among
already-authorized GREEN items using explicit WIP, dependency, duplicate,
cooldown, semantic failure-family and acceptance rules.

v1.2 adds skill-lab lane + capability/worker routing metadata for admission.

v1.1 closed the request-ID/iteration reset loophole: a semantic failure family is
shared across work-item names, candidate IDs and retries. BLOCKED/COOLED families
remain ineligible until the family registry is explicitly reopened by materially
new evidence. A narrowly marked read-only diagnosis may remain eligible.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

UTC = dt.timezone.utc
ALLOWED_LANES = {"production", "staging", "research", "skill-lab"}
WIP_LANE_ALIASES = {"skill-lab": "staging"}  # skill-lab shares staging WIP budget
ALLOWED_STATUS = {"OPEN", "READY"}
MAX_FAILURE_ATTEMPTS = 3
BLOCKING_FAMILY_STATES = {"BLOCKED", "COOLED"}


class ContractError(ValueError):
    pass


def parse_time(value: str | None) -> dt.datetime | None:
    if not value:
        return None
    text = str(value).strip().replace("Z", "+00:00")
    parsed = dt.datetime.fromisoformat(text)
    if parsed.tzinfo is None:
        raise ContractError("timestamps must be timezone-aware")
    return parsed.astimezone(UTC)


def load_json(path: str) -> Any:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


@dataclass(frozen=True)
class Program:
    id: str
    base_priority: int


@dataclass(frozen=True)
class FailureFamily:
    id: str
    state: str
    attempts: int


def validate_programs(data: dict[str, Any]) -> dict[str, Program]:
    require(data.get("schema") == 1, "program registry schema must be 1")
    require(data.get("kind") == "kevin-standing-program-registry", "program registry kind mismatch")
    programs: dict[str, Program] = {}
    for raw in data.get("programs", []):
        pid = str(raw.get("id", ""))
        priority = raw.get("base_priority")
        require(pid and pid not in programs, f"invalid/duplicate program id {pid!r}")
        require(isinstance(priority, int) and 0 <= priority <= 200, f"invalid base priority for {pid}")
        programs[pid] = Program(pid, priority)
    require(bool(programs), "program registry cannot be empty")
    return programs


def validate_failure_families(data: dict[str, Any]) -> dict[str, FailureFamily]:
    require(data.get("schema") == 1, "failure-family registry schema must be 1")
    require(data.get("kind") == "kevin-failure-family-registry", "failure-family registry kind mismatch")
    policy = data.get("policy", {})
    require(policy.get("rename_does_not_reset_budget") is True, "failure-family rename protection required")
    require(policy.get("request_id_does_not_reset_budget") is True, "failure-family request-id protection required")
    require(policy.get("iteration_does_not_reset_budget") is True, "failure-family iteration protection required")
    require(policy.get("reopen_requires_material_new_evidence") is True, "failure-family reopen evidence rule required")
    max_attempts = policy.get("max_material_attempts")
    require(isinstance(max_attempts, int) and max_attempts == MAX_FAILURE_ATTEMPTS, "failure-family max attempts mismatch")

    result: dict[str, FailureFamily] = {}
    for raw in data.get("families", []):
        fid = str(raw.get("id", ""))
        state = str(raw.get("state", "")).upper()
        attempts = raw.get("attempts", 0)
        require(fid and fid not in result, f"invalid/duplicate failure family {fid!r}")
        require(state in {"OPEN", "WATCH", "COOLED", "BLOCKED", "RESOLVED"}, f"invalid failure-family state {state}")
        require(isinstance(attempts, int) and attempts >= 0, f"invalid attempts for failure family {fid}")
        result[fid] = FailureFamily(fid, state, attempts)
    return result


def validate_state(data: dict[str, Any]) -> dict[str, int]:
    require(data.get("schema") == 1, "state schema must be 1")
    wip = data.get("wip", {})
    result: dict[str, int] = {}
    for lane in ALLOWED_LANES:
        value = wip.get(lane, 0)
        require(isinstance(value, int) and value >= 0, f"invalid WIP count for {lane}")
        result[lane] = value
    return result


def family_block_reason(item: dict[str, Any], families: dict[str, FailureFamily]) -> str | None:
    fid = str(item.get("failure_family", "")).strip()
    if not fid:
        return None
    fam = families.get(fid)
    if fam is None:
        return "UNKNOWN_FAILURE_FAMILY"
    if fam.state not in BLOCKING_FAMILY_STATES:
        return None
    read_only = item.get("read_only_diagnosis") is True
    work_type = str(item.get("work_type", "execution")).lower()
    if read_only and work_type == "research" and item.get("production_effect") in {None, "NONE"}:
        return None
    return f"FAILURE_FAMILY_{fam.state}"


def item_block_reasons(
    item: dict[str, Any],
    programs: dict[str, Program],
    families: dict[str, FailureFamily],
    wip: dict[str, int],
    now: dt.datetime,
) -> list[str]:
    reasons: list[str] = []
    iid = str(item.get("id", ""))
    if not iid:
        reasons.append("MISSING_ID")
    if item.get("authority_class") != "GREEN":
        reasons.append("NOT_GREEN")
    if str(item.get("status", "")).upper() not in ALLOWED_STATUS:
        reasons.append("NOT_OPEN_OR_READY")
    program = str(item.get("program", ""))
    if program not in programs:
        reasons.append("UNKNOWN_PROGRAM")
    lane = str(item.get("lane", "")).lower()
    if lane not in ALLOWED_LANES:
        reasons.append("UNKNOWN_LANE")
    else:
        wip_key = WIP_LANE_ALIASES.get(lane, lane)
        if wip.get(wip_key, 0) >= 1:
            reasons.append(f"WIP_{wip_key.upper()}_FULL")
    criteria = item.get("acceptance_criteria")
    if not isinstance(criteria, list) or not any(str(c).strip() for c in criteria):
        reasons.append("MISSING_ACCEPTANCE_CRITERIA")
    if item.get("dependencies_ready") is False:
        reasons.append("DEPENDENCY_BLOCKED")
    if item.get("owner_checkpoint_required") is True:
        reasons.append("WAITING_OWNER_CHECKPOINT")
    if item.get("blocked") is True:
        reasons.append("EXPLICITLY_BLOCKED")
    if item.get("duplicate_of"):
        reasons.append("DUPLICATE")
    cooldown = parse_time(item.get("cooldown_until"))
    if cooldown and cooldown > now:
        reasons.append("COOLING_DOWN")
    attempts = item.get("failure_attempts", 0)
    if not isinstance(attempts, int) or attempts < 0:
        reasons.append("INVALID_FAILURE_ATTEMPTS")
    elif attempts >= MAX_FAILURE_ATTEMPTS and not item.get("material_new_evidence", False):
        reasons.append("FAILURE_BUDGET_EXHAUSTED")
    fam_reason = family_block_reason(item, families)
    if fam_reason:
        reasons.append(fam_reason)
    work_type = str(item.get("work_type", "execution")).lower()
    if work_type in {"candidate", "research", "design"}:
        if not str(item.get("downstream_consumer", "")).strip():
            reasons.append("NO_DOWNSTREAM_CONSUMER")
    if work_type in {"candidate", "design"} and not str(item.get("hypothesis_id", "")).strip():
        reasons.append("NO_HYPOTHESIS_ID")
    if item.get("reserved_effect") is True:
        reasons.append("RESERVED_EFFECT")
    return reasons


def score_item(item: dict[str, Any], program: Program) -> tuple[int, list[str]]:
    score = program.base_priority
    why = [f"program={program.base_priority}"]
    severity_points = {"critical": 35, "high": 25, "medium": 10, "low": 0}.get(str(item.get("severity", "low")).lower(), 0)
    score += severity_points
    if severity_points:
        why.append(f"severity=+{severity_points}")
    owner_value = item.get("owner_value", 0)
    if isinstance(owner_value, int):
        owner_value = max(0, min(owner_value, 5))
        points = owner_value * 6
        score += points
        if points:
            why.append(f"owner_value=+{points}")
    bonuses = [
        ("near_acceptance", 20),
        ("closes_proof_gap", 18),
        ("reduces_bess_intervention", 18),
        ("reuses_proven_capability", 14),
        ("repairs_false_success", 14),
        ("produces_owner_deliverable", 12),
    ]
    for key, points in bonuses:
        if item.get(key) is True:
            score += points
            why.append(f"{key}=+{points}")
    attempts = item.get("failure_attempts", 0)
    if isinstance(attempts, int) and attempts > 0:
        penalty = min(attempts, 3) * 5
        score -= penalty
        why.append(f"failure_attempts=-{penalty}")
    estimated_minutes = item.get("estimated_minutes")
    if isinstance(estimated_minutes, int) and estimated_minutes > 0:
        if estimated_minutes <= 15:
            score += 6
            why.append("quick_close=+6")
        elif estimated_minutes <= 60:
            score += 3
            why.append("quick_close=+3")
    return score, why


def select(
    program_data: dict[str, Any],
    items_data: dict[str, Any],
    state_data: dict[str, Any],
    family_data: dict[str, Any],
    now: dt.datetime,
) -> dict[str, Any]:
    programs = validate_programs(program_data)
    families = validate_failure_families(family_data)
    wip = validate_state(state_data)
    require(items_data.get("schema") == 1, "items schema must be 1")
    require(items_data.get("kind") == "kevin-work-items", "items kind mismatch")
    items = items_data.get("items", [])
    require(isinstance(items, list), "items must be a list")

    eligible: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    seen: set[str] = set()
    for raw in items:
        require(isinstance(raw, dict), "each work item must be an object")
        iid = str(raw.get("id", ""))
        if iid and iid in seen:
            blocked.append({"id": iid, "reasons": ["DUPLICATE_ID"]})
            continue
        if iid:
            seen.add(iid)
        reasons = item_block_reasons(raw, programs, families, wip, now)
        if reasons:
            blocked.append({
                "id": iid or "<missing>",
                "failure_family": str(raw.get("failure_family", "")),
                "reasons": reasons,
            })
            continue
        program = programs[str(raw["program"])]
        score, why = score_item(raw, program)
        entry = {
            "id": iid,
            "program": program.id,
            "lane": str(raw["lane"]).lower(),
            "failure_family": str(raw.get("failure_family", "")),
            "score": score,
            "score_factors": why,
            "next_action": str(raw.get("next_action", "")),
        }
        if raw.get("worker"):
            entry["worker"] = str(raw.get("worker"))
        if raw.get("required_capabilities") is not None:
            entry["required_capabilities"] = list(raw.get("required_capabilities") or [])
        eligible.append(entry)

    eligible.sort(key=lambda x: (-x["score"], x["id"]))
    chosen = eligible[0] if eligible else None
    return {
        "schema": 2,
        "kind": "kevin-work-selection",
        "version": "1.2",
        "generated_at": now.isoformat().replace("+00:00", "Z"),
        "authority_effect": "NONE_SELECTION_ONLY",
        "advisory_only": True,
        "semantic_failure_families": True,
        "wip": wip,
        "selection": chosen,
        "eligible_count": len(eligible),
        "eligible": eligible,
        "blocked_count": len(blocked),
        "blocked": blocked,
        "status": "SELECTED" if chosen else "NO_ELIGIBLE_WORK",
    }


def selftest() -> None:
    programs = {
        "schema": 1,
        "kind": "kevin-standing-program-registry",
        "programs": [
            {"id": "platform-reliability", "base_priority": 100},
            {"id": "business-value", "base_priority": 70},
            {"id": "bounded-research-design", "base_priority": 60},
        ],
    }
    families = {
        "schema": 1,
        "kind": "kevin-failure-family-registry",
        "policy": {
            "max_material_attempts": 3,
            "rename_does_not_reset_budget": True,
            "request_id_does_not_reset_budget": True,
            "iteration_does_not_reset_budget": True,
            "reopen_requires_material_new_evidence": True,
        },
        "families": [
            {"id": "forge-loop", "state": "BLOCKED", "attempts": 3},
            {"id": "reader-path", "state": "OPEN", "attempts": 0},
        ],
    }
    state = {"schema": 1, "wip": {"production": 0, "staging": 0, "research": 0}}
    now = dt.datetime(2026, 8, 31, 19, 0, tzinfo=UTC)
    items = {
        "schema": 1,
        "kind": "kevin-work-items",
        "items": [
            {
                "id": "forge-retry-renamed-999", "failure_family": "forge-loop",
                "program": "platform-reliability", "authority_class": "GREEN", "status": "READY",
                "lane": "production", "acceptance_criteria": ["fixed"], "dependencies_ready": True,
                "failure_attempts": 0, "material_new_evidence": True, "next_action": "retry under new id"
            },
            {
                "id": "business-sheet", "program": "business-value", "authority_class": "GREEN",
                "status": "READY", "lane": "staging", "acceptance_criteria": ["valid workbook"],
                "dependencies_ready": True, "owner_value": 5, "reuses_proven_capability": True,
                "produces_owner_deliverable": True, "next_action": "create workbook"
            },
        ],
    }
    result = select(programs, items, state, families, now)
    assert result["selection"]["id"] == "business-sheet", result
    blocked = {b["id"]: b["reasons"] for b in result["blocked"]}
    assert "FAILURE_FAMILY_BLOCKED" in blocked["forge-retry-renamed-999"]

    diag_items = {"schema": 1, "kind": "kevin-work-items", "items": [{
        "id": "forge-readonly-diagnosis", "failure_family": "forge-loop",
        "program": "bounded-research-design", "authority_class": "GREEN", "status": "READY",
        "lane": "research", "work_type": "research", "read_only_diagnosis": True,
        "production_effect": "NONE", "downstream_consumer": "forge-admission-repair",
        "acceptance_criteria": ["diagnosis evidence"], "dependencies_ready": True,
        "next_action": "read-only diagnosis"
    }]}
    diag = select(programs, diag_items, state, families, now)
    assert diag["selection"]["id"] == "forge-readonly-diagnosis", diag

    unknown = {"schema": 1, "kind": "kevin-work-items", "items": [{
        "id": "unknown-family", "failure_family": "renamed-mystery",
        "program": "business-value", "authority_class": "GREEN", "status": "READY",
        "lane": "staging", "acceptance_criteria": ["x"], "dependencies_ready": True
    }]}
    u = select(programs, unknown, state, families, now)
    assert "UNKNOWN_FAILURE_FAMILY" in u["blocked"][0]["reasons"]
    print("KEVIN WORK SELECTOR v1.2 SELFTEST PASS semantic_failure_families=true rename_reset=false request_id_reset=false iteration_reset=false read_only_diagnosis=true")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--programs")
    parser.add_argument("--items")
    parser.add_argument("--state")
    parser.add_argument("--failure-families")
    parser.add_argument("--now")
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.selftest:
        selftest()
        return 0
    if not (args.programs and args.items and args.state and args.failure_families):
        parser.error("--programs, --items, --state and --failure-families are required unless --selftest is used")
    now = parse_time(args.now) if args.now else dt.datetime.now(UTC)
    assert now is not None
    try:
        result = select(
            load_json(args.programs),
            load_json(args.items),
            load_json(args.state),
            load_json(args.failure_families),
            now,
        )
    except (OSError, json.JSONDecodeError, ContractError) as exc:
        print(json.dumps({"schema": 1, "kind": "kevin-work-selection-error", "error": str(exc)}))
        return 2
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
