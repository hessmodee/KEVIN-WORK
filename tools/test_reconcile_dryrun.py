#!/usr/bin/env python3
import copy
import importlib.util
from datetime import datetime
from pathlib import Path

MODULE = Path(__file__).with_name("reconcile_dryrun.py")
spec = importlib.util.spec_from_file_location("reconcile_dryrun", MODULE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

HASHES = {
    "supervisor": "EA28600FDE1E7572F431710416238DA8A4AD6B80321C9A8F0687C1C8A92421F7",
    "benchmark": "02447EE8F3302E3EA1EF00290DBA6804F30FAC9F46CAE8714F402EA2D013CC38",
    "forge": "0ED50A9714B4B5E778844006CD24E57D25FFA0873261E5BF63F990FBB4D5643E",
    "goal_os": "B20C7AC8EDC35C656ED544C4D13D3EB4FF4A79453AF0F49BD60B7DF31092AEF0",
    "support_bridge": "E72A2A635326CF1AB036404E64E274D2F56CE79CA5CEB268DBF9B2EA4B67BEA5",
    "maintenance_runner": "B47714C91EFDCCD1FAE6C2CB0B97D72F799125A63C084956916A8BD5A07678C1",
}
FORBIDDEN = [
    "permissions", "arbitrary_shell", "production_chat_tools", "financial_transactions",
    "purchases", "external_sends", "credential_access", "safety_weakening",
    "automatic_production_promotion",
]


def desired():
    return {
        "schema": 1,
        "kind": "kevin-desired-state",
        "owner_controlled": True,
        "authority": {
            "green_only": True,
            "allow_arbitrary_shell": False,
            "allow_authority_expansion": False,
            "allow_novel_production_promotion": False,
        },
        "core_hashes": copy.deepcopy(HASHES),
        "jobs": [{"declaration_key": "kevin-supervisor-v1", "must_be_enabled": True, "max_consecutive_errors": 0}],
        "benchmark": {"require_pass": True},
        "resources": {"heavy_model_slots": 1, "one_14b_worker": True, "worker_labels_are_not_slot_count": True},
        "green_registry": [
            {"verb": "run_benchmark", "target": "kevin-benchmark-v1", "mutating": False},
            {"verb": "run_support_bridge", "target": "kevin-support-bridge-v1", "mutating": False},
            {"verb": "ensure_job_enabled", "target_class": "declared_job", "mutating": True, "rollback_required": True},
            {"verb": "select_alternate_mission", "target": "supervisor", "mutating": False},
        ],
        "scheduler": {
            "work_conserving": True,
            "alternate_mission_after_throttle": True,
            "never_bypass_cooldown": True,
            "candidate_queue": ["benchmark-fixtures", "knowledge-provenance"],
        },
        "forbidden_authority": list(FORBIDDEN),
    }


def healthy_snapshot(last_result="RECOVERY_THROTTLED"):
    return {
        "hashes": copy.deepcopy(HASHES),
        "governance": {"ok": True, "never_self_authorize": list(FORBIDDEN)},
        "cron": {"jobs": [{"declaration_key": "kevin-supervisor-v1", "enabled": True, "consecutive_errors": 0, "last_status": "ok"}]},
        "benchmark": {"status": "PASS", "at": "2026-08-29T19:17:31-06:00", "regression": {"critical_failures": 0}},
        "supervisor": {"last_result": last_result, "last_mission": "knowledge", "next_eligible_at": "2026-08-29T19:22:03-06:00"},
        "active_workers": {"design_forge": 0, "night_forge": 0, "supervisor": 0, "benchmark": 0},
    }


NOW = datetime.fromisoformat("2026-08-29T19:24:15-06:00")


def test_governance_blocks_everything():
    snap = healthy_snapshot(); snap["governance"]["ok"] = False
    result = mod.reconcile(desired(), snap, NOW)
    assert result["status"] == "BLOCKED_GOVERNANCE" and result["proposals"] == []


def test_governance_drift_blocks_everything():
    snap = healthy_snapshot(); snap["governance"]["never_self_authorize"].remove("external_sends")
    result = mod.reconcile(desired(), snap, NOW)
    assert result["status"] == "BLOCKED_GOVERNANCE_DRIFT" and result["proposals"] == []


def test_core_hash_drift_blocks_everything():
    snap = healthy_snapshot(); snap["hashes"]["supervisor"] = "drift"
    result = mod.reconcile(desired(), snap, NOW)
    assert result["status"] == "BLOCKED_CORE_DRIFT" and result["proposals"] == []


def test_work_conserving_proposal_is_typed_and_deterministic():
    a = mod.reconcile(desired(), healthy_snapshot(), NOW)
    b = mod.reconcile(desired(), healthy_snapshot(), NOW)
    assert a == b
    p = a["proposals"][0]
    assert p["kind"] == "select_alternate_mission"
    assert p["authority_class"] == "GREEN"
    assert len(p["precondition_fingerprint"]) == 64 and len(p["idempotency_key"]) == 64
    assert p["postcondition_required"] is True


def test_saturated_recovery_also_selects_alternate_mission():
    result = mod.reconcile(desired(), healthy_snapshot("RECOVERY_SATURATED"), NOW)
    assert [item["kind"] for item in result["proposals"]] == ["select_alternate_mission"]


def test_no_alternate_mission_before_eligibility():
    result = mod.reconcile(desired(), healthy_snapshot(), datetime.fromisoformat("2026-08-29T19:21:41-06:00"))
    assert result["proposals"] == []


def test_overlapping_worker_labels_mean_busy_not_two_slots():
    snap = healthy_snapshot(); snap["active_workers"]["design_forge"] = 1; snap["active_workers"]["night_forge"] = 1
    result = mod.reconcile(desired(), snap, NOW)
    assert result["proposals"] == []


def test_disabled_declared_job_proposes_named_reversible_enable():
    snap = healthy_snapshot(); snap["cron"]["jobs"][0]["enabled"] = False
    result = mod.reconcile(desired(), snap, datetime.fromisoformat("2026-08-29T19:21:41-06:00"))
    p = result["proposals"][0]
    assert p["kind"] == "ensure_job_enabled" and p["target"] == "kevin-supervisor-v1"
    assert p["rollback_required"] is True and p["authority_class"] == "GREEN"


def test_benchmark_failure_proposes_only_named_benchmark():
    snap = healthy_snapshot(); snap["benchmark"]["status"] = "FAIL"
    result = mod.reconcile(desired(), snap, datetime.fromisoformat("2026-08-29T19:21:41-06:00"))
    assert [p["kind"] for p in result["proposals"]] == ["run_benchmark"]
    assert result["proposals"][0]["target"] == "kevin-benchmark-v1"


def test_invalid_heavy_model_slot_policy_rejected():
    d = desired(); d["resources"]["heavy_model_slots"] = 2
    try:
        mod.reconcile(d, healthy_snapshot(), NOW)
    except ValueError as e:
        assert "heavy_model_slot" in str(e)
    else:
        raise AssertionError("unsafe heavy-model slot policy accepted")


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for test in tests: test()
    print(f"PASS: {len(tests)} reconcile safety tests")
