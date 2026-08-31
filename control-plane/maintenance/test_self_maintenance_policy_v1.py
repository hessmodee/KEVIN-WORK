#!/usr/bin/env python3
from copy import deepcopy
from self_maintenance_policy_v1 import ALIASES, resolve_alias, validate_manifest, validate_remote_order

BASE = {
    "schema": 3,
    "kind": "kevin-self-maintenance-manifest",
    "id": "self-maintenance-test-001",
    "authority_class": "GREEN",
    "authority_delta": "NONE",
    "production_effect": "NONE",
    "owner_policy": "Kevin Owner Authorization v1",
    "preauthorized": True,
    "operation": "replace_pinned_component",
    "target_alias": "maintenance_runner",
    "source_path": "control-plane/maintenance/kevin-maintenance-runner-v1.3.ps1",
    "source_sha256": "A" * 64,
    "expected_current_sha256": "B" * 64,
    "expected_after_sha256": "A" * 64,
    "expires_at": "2026-08-31T00:00:00-06:00",
}
ORDER = {
    "schema": 1,
    "kind": "kevin-work-order",
    "id": "maintenance-wake-001",
    "idempotency_key": "maintenance-wake-001-once",
    "created_at": "2026-08-30T12:00:00-06:00",
    "expires_at": "2026-08-30T13:00:00-06:00",
    "authority_class": "GREEN",
    "verb": "run_typed_maintenance",
    "target": "kevin-maintenance-v1",
    "reason": "Wake fixed local reconciler only",
}


def test_each_fixed_alias_has_exact_root():
    cases = {
        "maintenance_runner": "control-plane/maintenance/kevin-maintenance-runner-v1.3.ps1",
        "work_order_intake": "control-plane/intake/kevin-work-order-intake-v1.2.ps1",
        "skill_lab_runner": "control-plane/skill-lab/kevin-skill-lab-v1.0.3.ps1",
    }
    for alias, source in cases.items():
        x = deepcopy(BASE); x["target_alias"] = alias; x["source_path"] = source
        assert validate_manifest(x) == []
        assert resolve_alias(alias) == ALIASES[alias]["local"]


def test_alias_cannot_escape_to_other_root():
    x = deepcopy(BASE); x["source_path"] = "control-plane/intake/kevin-work-order-intake-v1.2.ps1"
    assert "source path outside alias root" in validate_manifest(x)


def test_unknown_alias_fails_closed():
    x = deepcopy(BASE); x["target_alias"] = "supervisor"
    assert "target alias not allowlisted" in validate_manifest(x)


def test_arbitrary_operation_fails_closed():
    x = deepcopy(BASE); x["operation"] = "shell"
    assert "operation not allowlisted" in validate_manifest(x)


def test_authority_and_production_expansion_rejected():
    for field, value, expected in (
        ("authority_class", "YELLOW", "authority must be GREEN"),
        ("authority_delta", "ADD", "authority_delta must be NONE"),
        ("production_effect", "CHAT_SEND", "production_effect must be NONE"),
        ("preauthorized", False, "preauthorized must be true"),
    ):
        x=deepcopy(BASE); x[field]=value
        assert expected in validate_manifest(x)


def test_hashes_are_exact_and_after_equals_source():
    x=deepcopy(BASE); x["expected_current_sha256"]="bad"
    assert "expected_current_sha256 invalid" in validate_manifest(x)
    x=deepcopy(BASE); x["expected_after_sha256"]="C"*64
    assert "source hash must equal after hash" in validate_manifest(x)


def test_manifest_cannot_supply_command_argv_or_path():
    for field, value in (
        ("command", "powershell -enc ..."),
        ("argv", ["cmd.exe", "/c", "whoami"]),
        ("local_path", "C:/Windows/System32/cmd.exe"),
        ("task_name", "Anything"),
        ("url", "https://evil.invalid/payload.ps1"),
    ):
        x=deepcopy(BASE); x[field]=value
        assert "unknown manifest field" in validate_manifest(x)


def test_remote_wake_order_is_exact_fixed_verb_and_target():
    assert validate_remote_order(deepcopy(ORDER)) == []
    x=deepcopy(ORDER); x["verb"]="run_shell"
    assert "verb not allowlisted" in validate_remote_order(x)
    x=deepcopy(ORDER); x["target"]="arbitrary"
    assert "target mismatch" in validate_remote_order(x)


def test_remote_order_cannot_carry_execution_data():
    for field, value in (
        ("command", "powershell.exe"),
        ("args", ["-File", "anything.ps1"]),
        ("path", "C:/temp/a.ps1"),
        ("manifest", {"operation":"shell"}),
    ):
        x=deepcopy(ORDER); x[field]=value
        assert "unknown work-order property" in validate_remote_order(x)


def test_remote_order_must_remain_green():
    x=deepcopy(ORDER); x["authority_class"]="RED"
    assert "authority must be GREEN" in validate_remote_order(x)


if __name__ == "__main__":
    tests=[v for k,v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:t()
    print(f"PASS {len(tests)}/{len(tests)} self-maintenance transport policy cases")
