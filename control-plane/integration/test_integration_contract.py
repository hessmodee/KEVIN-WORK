import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONTRACT = json.loads((ROOT / "integration-contract.v0.1.json").read_text(encoding="utf-8"))
FIXTURES = json.loads((ROOT / "phase-a-replay-fixtures.v0.1.json").read_text(encoding="utf-8"))


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
    names = [c["name"] for c in FIXTURES["cases"]]
    assert set(names) == set(CONTRACT["phase_a_cases"])
    assert len(names) == len(set(names)) == 14


def test_valid_pass_fixture_proves_all_core_preconditions():
    case = next(c for c in FIXTURES["cases"] if c["name"] == "VALID_GREEN_PASS")
    assert case["expected"] == "PASS"
    for field in (
        "governance_ok", "precondition_fresh", "idempotency_unique", "budget_ok",
        "postcondition_ok", "evidence_ok", "semantic_ok", "handoff_fresh",
        "knowledge_verified", "knowledge_fresh",
    ):
        assert case[field] is True
    assert case["heavy_workers"] == 1


def test_failure_controls_are_explicit_not_implicit():
    by_name = {c["name"]: c for c in FIXTURES["cases"]}
    assert by_name["REPLAY_REJECTED"]["idempotency_unique"] is False
    assert by_name["STALE_PRECONDITION_REJECTED"]["precondition_fresh"] is False
    assert by_name["GOVERNANCE_DRIFT_BLOCKED"]["governance_ok"] is False
    assert by_name["BUDGET_EXHAUSTED"]["budget_ok"] is False
    assert by_name["SEMANTIC_HANDOFF_REJECTED"]["semantic_ok"] is False
    assert by_name["STALE_KNOWLEDGE_REJECTED"]["knowledge_fresh"] is False
    assert by_name["UNVERIFIED_KNOWLEDGE_NOT_AUTHORITATIVE"]["knowledge_verified"] is False


def test_three_failure_policy_distinguishes_local_and_shared_scope():
    by_name = {c["name"]: c for c in FIXTURES["cases"]}
    local = by_name["MISSION_LOCAL_COOLDOWN_ROTATES"]
    shared = by_name["SHARED_PIPELINE_COOLDOWN_BLOCKS"]
    assert local["failure_count"] == 3 and local["failure_scope"] == "MISSION"
    assert local["eligible_alternative"] is True and local["expected"] == "ROTATE"
    assert shared["failure_count"] == 3 and shared["failure_scope"] == "SHARED"
    assert shared["expected"] == "BLOCKED"


def test_mutable_postcondition_failure_requires_rollback_path():
    case = next(c for c in FIXTURES["cases"] if c["name"] == "FAILED_POSTCONDITION_REQUIRES_ROLLBACK")
    assert case["mutation"] is True
    assert case["postcondition_ok"] is False
    assert case["rollback_available"] is True
    assert case["expected"] == "ROLLBACK_REQUIRED"


def test_checkpoint_resume_fixture_forbids_verified_stage_replay():
    case = next(c for c in FIXTURES["cases"] if c["name"] == "CHECKPOINT_RESUME_NO_REDO")
    assert case["resume"] is True
    assert case["verified_stage_replay"] is False
    assert case["expected"] == "PASS"
