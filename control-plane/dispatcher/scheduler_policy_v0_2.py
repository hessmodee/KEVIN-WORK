#!/usr/bin/env python3
"""Pure policy model for Kevin work-conserving mission selection.

Candidate only. No process launch, no production writes, no authority changes.
"""
from datetime import datetime, timezone

GLOBAL_FAILURE_FAMILIES = {
    "review-output-contract",
    "runtime-transport",
    "model-timeout",
    "resource-guard",
}


def dt(v):
    if not v:
        return None
    x = datetime.fromisoformat(str(v).replace("Z", "+00:00"))
    return x if x.tzinfo else x.replace(tzinfo=timezone.utc)


def cooldown_active(entry, now):
    until = dt((entry or {}).get("cooldown_until"))
    return bool(until and until.astimezone(timezone.utc) > now.astimezone(timezone.utc))


def mission_block_reason(mission_id, state, now):
    """Return a scoped cooldown reason or None.

    Global infrastructure families block all mission-worker dispatch because every
    catalog mission uses the same worker/reviewer pipeline. Mission-local failure
    families block only the mission that produced them, allowing independent
    authorized missions to proceed.
    """
    for entry in state.get("failure_cooldowns", []):
        family = str(entry.get("family") or "")
        if not cooldown_active(entry, now):
            continue
        if family in GLOBAL_FAILURE_FAMILIES:
            return f"global-family:{family}"
        if str(entry.get("mission_id") or "") == mission_id:
            return f"mission-family:{family}"
    return None


def recently_run(mission_id, state, now, cooldown_minutes):
    for item in state.get("recent", []):
        if str(item.get("mission_id")) != mission_id:
            continue
        at = dt(item.get("at"))
        if at and (now.astimezone(timezone.utc) - at.astimezone(timezone.utc)).total_seconds() < cooldown_minutes * 60:
            return True
    return False


def pick_mission(catalog, state, now, suggested=None):
    if not catalog.get("policy", {}).get("candidate_only", False):
        raise ValueError("catalog must remain candidate_only")
    if catalog.get("policy", {}).get("allow_production_mutation", False):
        raise ValueError("production mutation is not allowed")
    if catalog.get("policy", {}).get("allow_arbitrary_shell", False):
        raise ValueError("arbitrary shell is not allowed")

    cooldown = float(catalog.get("policy", {}).get("mission_repeat_cooldown_minutes", 30))
    missions = list(catalog.get("missions") or [])
    by_id = {str(m.get("id")): m for m in missions}

    ordered = []
    if suggested and suggested in by_id:
        ordered.append(by_id[suggested])
    ordered.extend(sorted((m for m in missions if m not in ordered), key=lambda m: (-int(m.get("priority", 0)), str(m.get("id")))))

    evidence = []
    for m in ordered:
        mid = str(m.get("id") or "")
        if not mid:
            continue
        reason = mission_block_reason(mid, state, now)
        if reason:
            evidence.append({"mission_id": mid, "eligible": False, "reason": reason})
            continue
        if recently_run(mid, state, now, cooldown):
            evidence.append({"mission_id": mid, "eligible": False, "reason": "mission-repeat-cooldown"})
            continue
        evidence.append({"mission_id": mid, "eligible": True, "reason": "eligible"})
        return {"selected_mission": mid, "state": "SELECTED", "evidence": evidence}

    global_block = any(str(e.get("reason", "")).startswith("global-family:") for e in evidence)
    return {"selected_mission": None, "state": "PIPELINE_COOLING" if global_block else "QUEUE_COOLING", "evidence": evidence}


def record_failure(state, mission_id, family, attempts, cooldown_until):
    if attempts < 3:
        return state
    entry = {"mission_id": mission_id, "family": family, "cooldown_until": cooldown_until}
    kept = [e for e in state.get("failure_cooldowns", []) if not (e.get("mission_id") == mission_id and e.get("family") == family)]
    out = dict(state)
    out["failure_cooldowns"] = kept + [entry]
    return out
