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
    "pipeline_dependent": True,
    "requires_14b_worker": True,
    "authority": "",
    "evaluator_verdict": "",
    "recovery_result": "",
    "failure_count_before": 0,
    "failure_count_after": 0,
    "failure_evidence_cleared": False,
    "mutation": False,
    "rollback_available": False,
    "resume": False,
    "verified_stage_replay": False,
}

SAFE_FIXTURE_METADATA = {"name", "expected"}
AUTHORITY_INJECTION_KEYS = {
    "authority_override",
    "authority_class",
    "arbitrary_shell",
    "permission_widening",
    "production_promotion",
    "external_send",
    "money_movement",
    "purchase",
    "credential_access",
}


def _state(case: Mapping[str, Any]) -> dict[str, Any]:
    state = dict(DEFAULTS)
    state.update(case)
    return state


def _evaluate_rejection_accounting(s: Mapping[str, Any]) -> ReplayDecision | None:
    verdict = str(s.get("evaluator_verdict") or "").upper()
    if not verdict:
        return None
    if verdict != "REJECT":
        return ReplayDecision("REJECTED", "UNKNOWN_EVALUATOR_VERDICT")

    before = int(s.get("failure_count_before") or 0)
    after = int(s.get("failure_count_after") or 0)
    cleared = bool(s.get("failure_evidence_cleared"))
    recovery = str(s.get("recovery_result") or "").upper()

    if cleared:
        return ReplayDecision("REJECTED", "REJECT_EVIDENCE_CLEARED")
    if recovery:
        if recovery != "RECOVERY_PASS":
            return ReplayDecision("REJECTED", "UNKNOWN_RECOVERY_RESULT")
        # Recovery/planning may succeed without changing the evaluator failure
        # count. It may never erase the existing rejected-candidate evidence.
        if after != before:
            return ReplayDecision("REJECTED", "RECOVERY_CHANGED_FAILURE_COUNT")
    elif after != before + 1:
        return ReplayDecision("REJECTED", "REJECT_NOT_ACCOUNTED")

    return ReplayDecision("FAILURE_RETAINED", "REJECT_EVIDENCE_PRESERVED")


def evaluate(case: Mapping[str, Any]) -> ReplayDecision:
    """Evaluate one synthetic integration case using fail-closed ordering."""
    keys = set(case)
    if keys & AUTHORITY_INJECTION_KEYS:
        return ReplayDecision("BLOCKED", "AUTHORITY_INJECTION")

    unknown = keys - set(DEFAULTS) - SAFE_FIXTURE_METADATA
    if unknown:
        return ReplayDecision("REJECTED", "UNKNOWN_FIXTURE_FIELD")

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

    rejection = _evaluate_rejection_accounting(s)
    if rejection is not None:
        return rejection

    failure_count = int(s["failure_count"])
    if failure_count >= 3:
        scope = str(s["failure_scope"]).upper()
        if scope == "MISSION" and bool(s["eligible_alternative"]):
            return ReplayDecision("ROTATE", "MISSION_LOCAL_COOLDOWN", rotate_mission=True)
        if scope == "SHARED":
            if not bool(s["pipeline_dependent"]):
                if bool(s["requires_14b_worker"]):
                    return ReplayDecision("BLOCKED", "DETERMINISTIC_LANE_REQUIRES_14B")
                if str(s["authority"]).upper() != "GREEN":
                    return ReplayDecision("BLOCKED", "DETERMINISTIC_LANE_NOT_GREEN")
                if not bool(s["eligible_alternative"]):
                    return ReplayDecision("COOLED", "NO_INDEPENDENT_DETERMINISTIC_WORK")
                return ReplayDecision(
                    "ROTATE_DETERMINISTIC_GREEN",
                    "SHARED_PIPELINE_COOL_BUT_INDEPENDENT_GREEN_ELIGIBLE",
                    rotate_mission=True,
                )
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
