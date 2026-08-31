#!/usr/bin/env python3
"""Kevin deterministic work-admission and priority selector.

This component does not execute work and does not grant authority. It decides which
already-authorized GREEN item is eligible to be considered next, using explicit
WIP, cooldown, duplicate, acceptance, dependency and failure-budget rules.
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
ALLOWED_LANES = {"production", "staging", "research"}
ALLOWED_STATUS = {"OPEN", "READY"}
MAX_FAILURE_ATTEMPTS = 3


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


def validate_state(data: dict[str, Any]) -> dict[str, int]:
    require(data.get("schema") == 1, "state schema must be 1")
    wip = data.get("wip", {})
    result: dict[str, int] = {}
    for lane in ALLOWED_LANES:
        value = wip.get(lane, 0)
        require(isinstance(value, int) and value >= 0, f"invalid WIP count for {lane}")
        result[lane] = value
    return result


def item_block_reasons(item: dict[str, Any], programs: dict[str, Program], wip: dict[str, int], now: dt.datetime) -> list[str]:
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
        limit = 1
        if wip[lane] >= limit:
            reasons.append(f"WIP_{lane.upper()}_FULL")
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
        # Small preference for high-value work that can close quickly; never enough
        # to outrank critical reliability work by itself.
        if estimated_minutes <= 15:
            score += 6
            why.append("quick_close=+6")
        elif estimated_minutes <= 60:
            score += 3
            why.append("quick_close=+3")

    return score, why


def select(program_data: dict[str, Any], items_data: dict[str, Any], state_data: dict[str, Any], now: dt.datetime) -> dict[str, Any]:
    programs = validate_programs(program_data)
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
        reasons = item_block_reasons(raw, programs, wip, now)
        if reasons:
            blocked.append({"id": iid or "<missing>", "reasons": reasons})
            continue
        program = programs[str(raw["program"])]
        score, why = score_item(raw, program)
        eligible.append({
            "id": iid,
            "program": program.id,
            "lane": str(raw["lane"]).lower(),
            "score": score,
            "score_factors": why,
            "next_action": str(raw.get("next_action", "")),
        })

    eligible.sort(key=lambda x: (-x["score"], x["id"]))
    chosen = eligible[0] if eligible else None
    return {
        "schema": 1,
        "kind": "kevin-work-selection",
        "generated_at": now.isoformat().replace("+00:00", "Z"),
        "authority_effect": "NONE_SELECTION_ONLY",
        "advisory_only": True,
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
    state = {"schema": 1, "wip": {"production": 0, "staging": 0, "research": 0}}
    now = dt.datetime(2026, 8, 31, 19, 0, tzinfo=UTC)
    items = {
        "schema": 1,
        "kind": "kevin-work-items",
        "items": [
            {
                "id": "repair-stale-bridge", "program": "platform-reliability", "authority_class": "GREEN",
                "status": "READY", "lane": "production", "acceptance_criteria": ["fresh heartbeat"],
                "dependencies_ready": True, "severity": "high", "owner_value": 4, "repairs_false_success": True,
                "next_action": "typed restart"
            },
            {
                "id": "random-candidate", "program": "bounded-research-design", "authority_class": "GREEN",
                "status": "READY", "lane": "research", "acceptance_criteria": ["test"], "dependencies_ready": True,
                "work_type": "candidate", "hypothesis_id": "h1", "next_action": "generate"
            },
            {
                "id": "business-sheet", "program": "business-value", "authority_class": "GREEN",
                "status": "READY", "lane": "staging", "acceptance_criteria": ["valid workbook"],
                "dependencies_ready": True, "owner_value": 5, "reuses_proven_capability": True,
                "produces_owner_deliverable": True, "next_action": "create workbook"
            },
        ],
    }
    result = select(programs, items, state, now)
    assert result["selection"]["id"] == "repair-stale-bridge", result
    blocked = {b["id"]: b["reasons"] for b in result["blocked"]}
    assert "NO_DOWNSTREAM_CONSUMER" in blocked["random-candidate"]

    items2 = {"schema": 1, "kind": "kevin-work-items", "items": [{
        "id": "spent", "program": "platform-reliability", "authority_class": "GREEN", "status": "READY",
        "lane": "production", "acceptance_criteria": ["fixed"], "dependencies_ready": True,
        "failure_attempts": 3, "next_action": "retry"
    }]}
    result2 = select(programs, items2, state, now)
    assert result2["status"] == "NO_ELIGIBLE_WORK"
    assert "FAILURE_BUDGET_EXHAUSTED" in result2["blocked"][0]["reasons"]

    items3 = {"schema": 1, "kind": "kevin-work-items", "items": [{
        "id": "yellow", "program": "business-value", "authority_class": "YELLOW", "status": "READY",
        "lane": "staging", "acceptance_criteria": ["x"], "dependencies_ready": True
    }]}
    result3 = select(programs, items3, state, now)
    assert "NOT_GREEN" in result3["blocked"][0]["reasons"]
    print("KEVIN WORK SELECTOR v1 SELFTEST PASS authority_effect=NONE no_spin=true max_attempts=3 wip=1/1/1")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--programs")
    parser.add_argument("--items")
    parser.add_argument("--state")
    parser.add_argument("--now")
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.selftest:
        selftest()
        return 0
    if not (args.programs and args.items and args.state):
        parser.error("--programs, --items and --state are required unless --selftest is used")
    now = parse_time(args.now) if args.now else dt.datetime.now(UTC)
    assert now is not None
    try:
        result = select(load_json(args.programs), load_json(args.items), load_json(args.state), now)
    except (OSError, json.JSONDecodeError, ContractError) as exc:
        print(json.dumps({"schema": 1, "kind": "kevin-work-selection-error", "error": str(exc)}))
        return 2
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
