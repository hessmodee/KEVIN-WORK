import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONTRACT = json.loads((ROOT / "integration-contract.v0.1.json").read_text(encoding="utf-8"))


def test_candidate_only():
    assert CONTRACT["candidate_only"] is True
    assert CONTRACT["production_promotion"] == "OWNER_RESERVED"


def test_single_heavy_worker():
    policy = CONTRACT["worker_policy"]
    assert policy["heavy_model_slot"] == "14b-primary"
    assert policy["max_concurrent_heavy_workers"] == 1


def test_required_chain_is_complete_and_ordered():
    assert CONTRACT["required_stages"] == [
        "MISSION_ADMISSION",
        "WORK_SELECTION",
        "WORK_ORDER_VALIDATION",
        "PRECONDITION_GATE",
        "BUDGET_GATE",
        "GREEN_ACTUATOR_DECISION",
        "POSTCONDITION_VERIFICATION",
        "RECEIPT_VERIFICATION",
        "SEMANTIC_HANDOFF",
        "CHECKPOINT",
        "FAILURE_ACCOUNTING",
        "KNOWLEDGE_ADMISSION",
    ]


def test_mutation_proof_controls_required():
    controls = CONTRACT["required_controls"]
    for key in (
        "idempotency",
        "replay_rejection",
        "semantic_progress_required",
        "independent_postcondition",
        "rollback_for_mutation",
        "evidence_required",
        "freshness_required_for_consequential_claims",
        "unknown_authority_fields_fail_closed",
    ):
        assert controls[key] is True
    assert controls["bounded_retries"] == 3


def test_forbidden_authority_boundaries():
    forbidden = set(CONTRACT["forbidden_capabilities"])
    required = {
        "ARBITRARY_REMOTE_SHELL",
        "RED_AUTHORITY_EXPANSION",
        "PERMISSION_WIDENING",
        "MONEY_MOVEMENT",
        "PURCHASES",
        "OWNER_REPRESENTING_EXTERNAL_SEND",
        "AUTO_PROMOTE_NOVEL_YELLOW",
        "AUTO_BLESS_TRUST_ANCHOR_DRIFT",
        "OPS_FLOOR_REDESIGN",
    }
    assert required <= forbidden


def test_phase_a_adversarial_matrix():
    cases = set(CONTRACT["phase_a_cases"])
    required = {
        "VALID_GREEN_PASS",
        "REPLAY_REJECTED",
        "STALE_PRECONDITION_REJECTED",
        "GOVERNANCE_DRIFT_BLOCKED",
        "BUDGET_EXHAUSTED",
        "DUPLICATE_NO_PROGRESS_REJECTED",
        "MISSION_LOCAL_COOLDOWN_ROTATES",
        "SHARED_PIPELINE_COOLDOWN_BLOCKS",
        "FAILED_POSTCONDITION_REQUIRES_ROLLBACK",
        "SEMANTIC_HANDOFF_REJECTED",
        "CHECKPOINT_RESUME_NO_REDO",
        "THREE_FAILURE_COOLING",
        "STALE_KNOWLEDGE_REJECTED",
        "UNVERIFIED_KNOWLEDGE_NOT_AUTHORITATIVE",
    }
    assert required <= cases
    assert len(cases) == len(CONTRACT["phase_a_cases"])
