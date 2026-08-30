"""Pure deterministic Phase A replay engine for Kevin autonomy integration.

This module evaluates synthetic candidate-only fixtures. It performs no host mutation,
network access, process execution, shell execution, permission changes, external sends,
or production promotion.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping


@dataclass(frozen=True)
class ReplayDecision:
    outcome: str
    reason: str
    rollback_required: bool = False
    rotate_mission: bool = False


DEFAULTS = {
    "governance_ok": True,
    "precondition_fresh": True,
    "idempotency_unique": True,
    "budget_ok": True,
    "postcondition_ok": True,
    "evidence_ok": True,
    "semantic_ok": True,
    "semantic_progress": True,
    "handoff_fresh": True,
    "knowledge_verified": True,
    "knowledge_fresh": True,
    "heavy_workers": 1,
    "failure_count": 0,
    "failure_scope": "",
    "eligible_alternative": False,
    "mutation": False,
    "rollback_available": False,
    "resume": False,
    "verified_stage_replay": False,
}


def _state(case: Mapping[str, Any]) -> dict[str, Any]:
    state = dict(DEFAULTS)
    state.update(case)
    return state


def evaluate(case: Mapping[str, Any]) -> ReplayDecision:
    """Evaluate one synthetic integration case using fail-closed ordering."""
    s = _state(case)

    if int(s["heavy_workers"]) > 1:
        return ReplayDecision("BLOCKED", "ONE_HEAVY_WORKER_INVARIANT")

    if not bool(s["governance_ok"]):
        return ReplayDecision("BLOCKED", "GOVERNANCE_DRIFT")

    if not bool(s["idempotency_unique"]):
        return ReplayDecision("REJECTED", "REPLAY_OR_DUPLICATE")

    if not bool(s["precondition_fresh"]):
        return ReplayDecision("REJECTED", "STALE_PRECONDITION")

    if not bool(s["budget_ok"]):
        return ReplayDecision("REJECTED", "BUDGET_EXHAUSTED")

    if not bool(s["semantic_progress"]):
        return ReplayDecision("REJECTED", "NO_SEMANTIC_PROGRESS")

    failure_count = int(s["failure_count"])
    if failure_count >= 3:
        scope = str(s["failure_scope"]).upper()
        if scope == "MISSION" and bool(s["eligible_alternative"]):
            return ReplayDecision("ROTATE", "MISSION_LOCAL_COOLDOWN", rotate_mission=True)
        if scope == "SHARED":
            return ReplayDecision("BLOCKED", "SHARED_PIPELINE_COOLDOWN")
        return ReplayDecision("COOLED", "THREE_FAILURE_LIMIT")

    if not bool(s["postcondition_ok"]):
        if bool(s["mutation"]):
            if bool(s["rollback_available"]):
                return ReplayDecision("ROLLBACK_REQUIRED", "POSTCONDITION_FAILED", rollback_required=True)
            return ReplayDecision("BLOCKED", "POSTCONDITION_FAILED_NO_ROLLBACK")
        return ReplayDecision("REJECTED", "POSTCONDITION_FAILED")

    if not bool(s["evidence_ok"]):
        return ReplayDecision("REJECTED", "EVIDENCE_MISSING")

    if not bool(s["semantic_ok"]):
        return ReplayDecision("REJECTED", "SEMANTIC_HANDOFF_FAILED")

    if not bool(s["handoff_fresh"]):
        return ReplayDecision("REJECTED", "STALE_HANDOFF")

    if bool(s["verified_stage_replay"]):
        return ReplayDecision("REJECTED", "VERIFIED_STAGE_REPLAY")

    if not bool(s["knowledge_verified"]):
        return ReplayDecision("REJECTED", "KNOWLEDGE_UNVERIFIED")

    if not bool(s["knowledge_fresh"]):
        return ReplayDecision("REJECTED", "KNOWLEDGE_STALE")

    return ReplayDecision("PASS", "INTEGRATION_CHAIN_VERIFIED")
