import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

spec = importlib.util.spec_from_file_location("replay_engine", ROOT / "replay_engine.py")
engine = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = engine
spec.loader.exec_module(engine)

FIXTURES = json.loads((ROOT / "phase-a-replay-fixtures.v0.1.json").read_text())


def test_all_phase_a_cases_match_expected_outcome():
    cases = FIXTURES["cases"]
    assert len(cases) == 14
    for case in cases:
        decision = engine.evaluate(case)
        assert decision.outcome == case["expected"], (
            case["name"], case["expected"], decision.outcome, decision.reason
        )


def test_green_pass_is_semantically_complete():
    case = next(x for x in FIXTURES["cases"] if x["name"] == "VALID_GREEN_PASS")
    decision = engine.evaluate(case)
    assert decision.outcome == "PASS"
    assert decision.reason == "INTEGRATION_CHAIN_VERIFIED"
    assert decision.rollback_required is False
    assert decision.rotate_mission is False


def test_mutation_failure_requires_available_rollback():
    decision = engine.evaluate({
        "postcondition_ok": False,
        "mutation": True,
        "rollback_available": True,
    })
    assert decision.outcome == "ROLLBACK_REQUIRED"
    assert decision.rollback_required is True

    no_rollback = engine.evaluate({
        "postcondition_ok": False,
        "mutation": True,
        "rollback_available": False,
    })
    assert no_rollback.outcome == "BLOCKED"
    assert no_rollback.reason == "POSTCONDITION_FAILED_NO_ROLLBACK"


def test_more_than_one_heavy_worker_fails_closed():
    decision = engine.evaluate({"heavy_workers": 2})
    assert decision.outcome == "BLOCKED"
    assert decision.reason == "ONE_HEAVY_WORKER_INVARIANT"


def test_mission_local_failure_rotates_only_when_alternative_exists():
    rotate = engine.evaluate({
        "failure_count": 3,
        "failure_scope": "MISSION",
        "eligible_alternative": True,
    })
    assert rotate.outcome == "ROTATE"
    assert rotate.rotate_mission is True

    cool = engine.evaluate({
        "failure_count": 3,
        "failure_scope": "MISSION",
        "eligible_alternative": False,
    })
    assert cool.outcome == "COOLED"


def test_shared_pipeline_failure_blocks_instead_of_rotating():
    decision = engine.evaluate({
        "failure_count": 3,
        "failure_scope": "SHARED",
        "eligible_alternative": True,
    })
    assert decision.outcome == "BLOCKED"
    assert decision.rotate_mission is False


def test_resume_rejects_replay_of_verified_stage():
    ok = engine.evaluate({"resume": True, "verified_stage_replay": False})
    assert ok.outcome == "PASS"

    replay = engine.evaluate({"resume": True, "verified_stage_replay": True})
    assert replay.outcome == "REJECTED"
    assert replay.reason == "VERIFIED_STAGE_REPLAY"


def test_authority_injection_fails_closed():
    decision = engine.evaluate({
        "authority_override": "RED",
        "arbitrary_shell": True,
        "production_promotion": True,
    })
    assert decision.outcome == "BLOCKED"
    assert decision.reason == "AUTHORITY_INJECTION"


def test_unknown_fixture_field_is_rejected():
    decision = engine.evaluate({"mystery_field": "value"})
    assert decision.outcome == "REJECTED"
    assert decision.reason == "UNKNOWN_FIXTURE_FIELD"
