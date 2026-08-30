#!/usr/bin/env python3
from copy import deepcopy
from datetime import datetime, timezone

from ops_activity_policy_v0_1 import classify

NOW = datetime.fromisoformat("2026-08-30T08:21:31-06:00")
BASE = {
    "generated_at": "2026-08-30T08:21:31-06:00",
    "health": {"overall": "healthy"},
    "current_task": None,
    "support": {
        "supervisor": {"last_result": "RECOVERY_PASS", "next_eligible_at": "2026-08-30T08:24:31-06:00"},
        "cron": [{"declaration_key": "kevin-supervisor-v1", "enabled": True, "last_status": "ok"}],
    },
    "activity": [
        {"at": "2026-08-30T08:18:45-06:00", "component": "forge", "event": "task_finish"}
    ],
}


def test_gap_between_real_cycles_is_armed_not_fake_active():
    r = classify(deepcopy(BASE), NOW)
    assert r["state"] == "ARMED"
    assert r["executing"] is False
    assert "recent-engineering-activity" in r["evidence"]


def test_real_current_task_is_active():
    x = deepcopy(BASE)
    x["current_task"] = {"id": "forge-v4", "phase": "evaluating"}
    r = classify(x, NOW)
    assert r == {"state": "ACTIVE", "executing": True, "evidence": ["active-current-task"]}


def test_wait_phase_is_not_mislabeled_active():
    x = deepcopy(BASE)
    x["current_task"] = {"id": "forge-v4", "phase": "wait"}
    r = classify(x, NOW)
    assert r["state"] == "ARMED" and r["executing"] is False


def test_supervisor_cooldown_is_explicit():
    x = deepcopy(BASE)
    x["support"]["supervisor"]["last_result"] = "RECOVERY_THROTTLED"
    r = classify(x, NOW)
    assert r["state"] == "COOLDOWN" and r["executing"] is False


def test_no_schedule_and_no_activity_is_true_idle():
    x = deepcopy(BASE)
    x["support"]["cron"][0]["enabled"] = False
    x["activity"] = []
    x["support"]["supervisor"]["next_eligible_at"] = None
    r = classify(x, NOW)
    assert r["state"] == "IDLE"


def test_stale_telemetry_is_offline_not_idle():
    x = deepcopy(BASE)
    x["generated_at"] = "2026-08-30T07:00:00-06:00"
    r = classify(x, NOW)
    assert r["state"] == "OFFLINE"


def test_bad_health_is_degraded_before_activity_claim():
    x = deepcopy(BASE)
    x["health"]["overall"] = "degraded"
    x["current_task"] = {"id": "forge-v4", "phase": "building"}
    r = classify(x, NOW)
    assert r["state"] == "DEGRADED" and r["executing"] is False


def test_recent_bridge_only_does_not_claim_autonomous_engineering():
    x = deepcopy(BASE)
    x["activity"] = [{"at": "2026-08-30T08:20:00-06:00", "component": "bridge", "event": "task_finish"}]
    x["support"]["supervisor"]["next_eligible_at"] = None
    r = classify(x, NOW)
    assert r["state"] == "IDLE"


def test_armed_requires_healthy_enabled_supervisor_job():
    x = deepcopy(BASE)
    x["support"]["cron"][0]["last_status"] = "error"
    r = classify(x, NOW)
    assert r["state"] == "IDLE"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:
        t()
    print(f"PASS {len(tests)}/{len(tests)} truthful Ops activity cases")
