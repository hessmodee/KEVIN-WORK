#!/usr/bin/env python3
"""Pure state adapter for Kevin's scoped cooldown dispatcher candidate.

No execution surface. Converts legacy global cooldown state into a v2 structure
that can be consumed by scheduler_policy_v0_2 without granting new authority.
"""
from __future__ import annotations

from copy import deepcopy
from datetime import datetime, timezone

GLOBAL_FAILURE_FAMILIES = {
    "review-output-contract",
    "runtime-transport",
    "model-timeout",
    "resource-guard",
}
SUCCESS_RESULTS = {"PASS", "PROVEN", "VERIFIED", "ACCEPT", "CHAMPION", "SUCCEEDED"}
FAIL_RESULTS = {"REJECT", "FAIL", "FAILED"}


def _dt(value):
    if not value:
        return None
    d = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    return d if d.tzinfo else d.replace(tzinfo=timezone.utc)


def upgrade_state(state):
    """Upgrade schema-1 dispatcher state without inventing successful work."""
    src = deepcopy(state or {})
    out = {
        "schema": 2,
        "queue_index": int(src.get("queue_index", 0) or 0),
        "last_mission": str(src.get("last_mission") or ""),
        "last_result": str(src.get("last_result") or ""),
        "recent": list(src.get("recent") or []),
        "failure_attempts": list(src.get("failure_attempts") or []),
        "failure_cooldowns": list(src.get("failure_cooldowns") or []),
        "updated_at": src.get("updated_at"),
    }

    # Preserve an already-active legacy cooldown conservatively. We cannot prove
    # its original scope, so it becomes a pipeline cooldown instead of being
    # silently discarded or narrowed.
    legacy_until = src.get("cooldown_until")
    legacy_family = str(src.get("failure_family") or "")
    legacy_attempts = int(src.get("attempts", 0) or 0)
    legacy_mission = str(src.get("last_mission") or "")
    if legacy_attempts:
        out["failure_attempts"].append({
            "mission_id": legacy_mission,
            "family": legacy_family or "legacy-unknown",
            "attempts": legacy_attempts,
            "migrated": True,
        })
    if legacy_until:
        out["failure_cooldowns"].append({
            "mission_id": legacy_mission,
            "family": legacy_family if legacy_family in GLOBAL_FAILURE_FAMILIES else "runtime-transport",
            "cooldown_until": legacy_until,
            "scope": "pipeline",
            "migrated": True,
        })
    return out


def record_failure(state, mission_id, family, cooldown_until=None, threshold=3):
    """Increment only the matching mission/family and optionally create cooldown."""
    out = upgrade_state(state)
    hit = None
    for item in out["failure_attempts"]:
        if item.get("mission_id") == mission_id and item.get("family") == family:
            hit = item
            break
    if hit is None:
        hit = {"mission_id": mission_id, "family": family, "attempts": 0}
        out["failure_attempts"].append(hit)
    hit["attempts"] = int(hit.get("attempts", 0)) + 1

    if hit["attempts"] >= threshold and cooldown_until:
        scope = "pipeline" if family in GLOBAL_FAILURE_FAMILIES else "mission"
        out["failure_cooldowns"] = [
            x for x in out["failure_cooldowns"]
            if not (x.get("mission_id") == mission_id and x.get("family") == family)
        ]
        out["failure_cooldowns"].append({
            "mission_id": mission_id,
            "family": family,
            "cooldown_until": cooldown_until,
            "scope": scope,
        })
    return out


def record_success(state, mission_id, result, at):
    """Clear mission-local failure evidence only for semantic success.

    A recovery/planning pass is not equivalent to a successful candidate. REJECT,
    FAIL, and unknown result vocabularies are refused here so they cannot erase
    accumulated evaluator evidence or bypass the three-failure cooling rule.
    """
    result_norm = str(result or "").upper()
    if result_norm not in SUCCESS_RESULTS:
        raise ValueError("record_success requires a semantically successful terminal result")

    out = upgrade_state(state)
    out["last_mission"] = mission_id
    out["last_result"] = result_norm
    out["recent"].append({"mission_id": mission_id, "at": at, "result": result_norm})
    out["failure_attempts"] = [x for x in out["failure_attempts"] if x.get("mission_id") != mission_id]
    out["failure_cooldowns"] = [
        x for x in out["failure_cooldowns"]
        if x.get("mission_id") != mission_id or x.get("scope") == "pipeline"
    ]
    return out


def record_evaluation(state, mission_id, verdict, family, at, cooldown_until=None, threshold=3):
    """Bind evaluator terminal verdicts to durable failure/success accounting.

    This prevents a successful recovery/planning cycle from silently erasing a
    rejected candidate attempt. Unknown verdicts fail closed.
    """
    verdict_norm = str(verdict or "").upper()
    if verdict_norm in SUCCESS_RESULTS:
        return record_success(state, mission_id, verdict_norm, at)
    if verdict_norm not in FAIL_RESULTS:
        raise ValueError("unknown evaluator verdict")

    out = record_failure(state, mission_id, family, cooldown_until, threshold)
    out["last_mission"] = mission_id
    out["last_result"] = verdict_norm
    out["recent"].append({"mission_id": mission_id, "at": at, "result": verdict_norm, "failure_family": family})
    return out
