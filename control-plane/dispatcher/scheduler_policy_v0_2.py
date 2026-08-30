#!/usr/bin/env python3
"""Pure policy model for Kevin work-conserving mission selection.

Candidate only. No process launch, no production writes, no authority changes.
The policy keeps the single heavy-model lane conservative while allowing explicitly
independent deterministic GREEN maintenance/evidence work to continue when the
shared model/reviewer pipeline is cooling.
"""
from datetime import datetime, timezone

GLOBAL_FAILURE_FAMILIES = {
    "review-output-contract",
    "runtime-transport",
    "model-timeout",
    "resource-guard",
}
ALLOWED_LANES = {"primary", "deterministic-green"}


def dt(v):
    if not v:
        return None
    x = datetime.fromisoformat(str(v).replace("Z", "+00:00"))
    return x if x.tzinfo else x.replace(tzinfo=timezone.utc)


def cooldown_active(entry, now):
    until = dt((entry or {}).get("cooldown_until"))
    return bool(until and until.astimezone(timezone.utc) > now.astimezone(timezone.utc))


def validate_catalog(catalog):
    policy = catalog.get("policy", {})
    if not policy.get("candidate_only", False):
        raise ValueError("catalog must remain candidate_only")
    if policy.get("allow_production_mutation", False):
        raise ValueError("production mutation is not allowed")
    if policy.get("allow_arbitrary_shell", False):
        raise ValueError("arbitrary shell is not allowed")

    seen = set()
    for mission in list(catalog.get("missions") or []):
        mission_id = str(mission.get("id") or "")
        lane = str(mission.get("lane") or "primary")
        if not mission_id or mission_id in seen:
            raise ValueError("mission ids must be unique and non-empty")
        seen.add(mission_id)
        if lane not in ALLOWED_LANES:
            raise ValueError("unknown mission lane")

        # This lane is deliberately narrow: it can survive a shared model/reviewer
        # cooldown only because it declares that it does not use that pipeline or
        # the single 14B worker and remains GREEN. Missing flags fail closed.
        if lane == "deterministic-green":
            if mission.get("uses_shared_pipeline", True):
                raise ValueError("deterministic-green must not use shared pipeline")
            if mission.get("requires_14b_worker", True):
                raise ValueError("deterministic-green must not require 14b worker")
            if mission.get("authority") != "GREEN":
                raise ValueError("deterministic-green must be GREEN")


def mission_block_reason(mission, state, now):
    """Return a scoped cooldown reason or None.

    Shared infrastructure families block missions that actually depend on the
    shared model/reviewer pipeline. Mission-local failure families block only the
    mission that produced them. Explicit deterministic GREEN work that does not
    use the shared pipeline can therefore continue while a primary lane cools.
    """
    mission_id = str(mission.get("id") or "")
    uses_shared_pipeline = bool(mission.get("uses_shared_pipeline", True))
    for entry in state.get("failure_cooldowns", []):
        family = str(entry.get("family") or "")
        if not cooldown_active(entry, now):
            continue
        if family in GLOBAL_FAILURE_FAMILIES and uses_shared_pipeline:
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
    validate_catalog(catalog)

    cooldown = float(catalog.get("policy", {}).get("mission_repeat_cooldown_minutes", 30))
    missions = list(catalog.get("missions") or [])
    by_id = {str(m.get("id")): m for m in missions}

    ordered = []
    if suggested and suggested in by_id:
        ordered.append(by_id[suggested])
    ordered.extend(sorted((m for m in missions if m not in ordered), key=lambda m: (-int(m.get("priority", 0)), str(m.get("id")))))

    evidence = []
    for mission in ordered:
        mission_id = str(mission.get("id") or "")
        lane = str(mission.get("lane") or "primary")
        reason = mission_block_reason(mission, state, now)
        if reason:
            evidence.append({"mission_id": mission_id, "lane": lane, "eligible": False, "reason": reason})
            continue
        if recently_run(mission_id, state, now, cooldown):
            evidence.append({"mission_id": mission_id, "lane": lane, "eligible": False, "reason": "mission-repeat-cooldown"})
            continue
        evidence.append({"mission_id": mission_id, "lane": lane, "eligible": True, "reason": "eligible"})
        return {"selected_mission": mission_id, "state": "SELECTED", "evidence": evidence}

    shared_block = any(str(e.get("reason", "")).startswith("global-family:") for e in evidence)
    return {"selected_mission": None, "state": "PIPELINE_COOLING" if shared_block else "QUEUE_COOLING", "evidence": evidence}


def record_failure(state, mission_id, family, attempts, cooldown_until):
    if attempts < 3:
        return state
    entry = {"mission_id": mission_id, "family": family, "cooldown_until": cooldown_until}
    kept = [e for e in state.get("failure_cooldowns", []) if not (e.get("mission_id") == mission_id and e.get("family") == family)]
    out = dict(state)
    out["failure_cooldowns"] = kept + [entry]
    return out
