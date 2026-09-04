#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "control-plane" / "autonomy" / "kevin-continuous-growth-v1.py"
POLICY_PATH = ROOT / "control-plane" / "autonomy" / "continuous-growth-policy-v1.json"
spec = importlib.util.spec_from_file_location("growth", SRC)
m = importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(m)
POLICY = json.loads(POLICY_PATH.read_text(encoding="utf-8"))


def base(**overrides):
    value = {
        "id": "growth-test",
        "program": "self-improvement",
        "authority_class": "GREEN",
        "owner_value": 5,
        "effects": [],
        "targets": ["control-plane/example.py"],
        "mutates_code_or_config": True,
        "acceptance_criteria": ["Real semantic postcondition is proven."],
        "verification_plan": ["Run deterministic tests.", "Verify postcondition independently."],
        "rollback_plan": ["Restore exact previous blob/hash."],
        "checkpoint_plan": ["Record before/after hashes and proof receipt."],
        "retry_policy": {"max_attempts_without_material_new_evidence": 3, "cooldown_seconds_after_exhaustion": 300}
    }
    value.update(overrides)
    return value


def test_green_bounded_growth_allowed():
    r = m.assess(base(), POLICY)
    assert r["verdict"] == "ALLOW_GREEN", r
    assert r["authority_effect"] == "NONE_VALIDATOR_ONLY"


def test_every_protected_effect_requires_owner_review():
    for effect in POLICY["protected_effects"]:
        r = m.assess(base(effects=[effect]), POLICY)
        assert r["verdict"] == "OWNER_REVIEW", (effect, r)


def test_governance_self_edit_requires_owner_review():
    for target in [
        "AGENTS.md",
        "docs/architecture/KEVIN-CONSTITUTION-v2.md",
        "control-plane/autonomy/continuous-growth-policy-v1.json",
        "control-plane/authority-policy-v3.json",
        "config/credential-policy.json"
    ]:
        r = m.assess(base(targets=[target]), POLICY)
        assert r["verdict"] == "OWNER_REVIEW", (target, r)


def test_mutable_change_needs_rollback_and_checkpoint():
    r = m.assess(base(rollback_plan=[], checkpoint_plan=[]), POLICY)
    assert r["verdict"] == "DENY", r
    assert "MUTABLE_CHANGE_REQUIRES:rollback_plan" in r["deny_reasons"]
    assert "MUTABLE_CHANGE_REQUIRES:checkpoint_plan" in r["deny_reasons"]


def test_hot_loop_retry_budget_denied():
    r = m.assess(base(retry_policy={"max_attempts_without_material_new_evidence": 99, "cooldown_seconds_after_exhaustion": 0}), POLICY)
    assert r["verdict"] == "DENY", r
    assert "RETRY_BUDGET_EXCEEDS_POLICY" in r["deny_reasons"]
    assert "COOLDOWN_BELOW_POLICY" in r["deny_reasons"]


def test_self_narrated_success_denied():
    r = m.assess(base(success_by_self_narration=True), POLICY)
    assert r["verdict"] == "DENY", r
    assert "SELF_NARRATED_SUCCESS_FORBIDDEN" in r["deny_reasons"]


def test_automatic_production_promotion_requires_owner_review():
    r = m.assess(base(automatic_production_promotion=True), POLICY)
    assert r["verdict"] == "OWNER_REVIEW", r


def test_non_growth_program_denied():
    r = m.assess(base(program="random-busywork"), POLICY)
    assert r["verdict"] == "DENY", r
    assert "PROGRAM_NOT_CONTINUOUS_GROWTH" in r["deny_reasons"]


def test_contract_has_all_permanent_responsibilities():
    doc = (ROOT / "docs" / "architecture" / "KEVIN-CONTINUOUS-GROWTH-v1.md").read_text(encoding="utf-8")
    for phrase in [
        "Self-heal", "Self-maintain / self-care", "Self-improve", "Learn and grow",
        "Recover blocked work", "Expand useful capability", "Proactively create owner value",
        "24/7 production truth", "false-success rate = 0%"
    ]:
        assert phrase in doc, phrase


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for test in tests:
        test()
    print(f"KEVIN CONTINUOUS GROWTH v1 SELFTEST PASS ({len(tests)} tests)")
