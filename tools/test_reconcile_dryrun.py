#!/usr/bin/env python3
import importlib.util
from datetime import datetime
from pathlib import Path

MODULE = Path(__file__).with_name("reconcile_dryrun.py")
spec = importlib.util.spec_from_file_location("reconcile_dryrun", MODULE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def desired():
    return {
        "jobs": [
            {
                "declaration_key": "kevin-supervisor-v1",
                "must_be_enabled": True,
                "max_consecutive_errors": 0,
            }
        ],
        "benchmark": {"require_pass": True},
        "scheduler": {
            "work_conserving": True,
            "alternate_mission_after_throttle": True,
            "never_bypass_cooldown": True,
        },
    }


def healthy_snapshot(last_result="RECOVERY_THROTTLED"):
    return {
        "governance": {"ok": True},
        "cron": {
            "jobs": [
                {
                    "declaration_key": "kevin-supervisor-v1",
                    "enabled": True,
                    "consecutive_errors": 0,
                }
            ]
        },
        "benchmark": {"status": "PASS"},
        "supervisor": {
            "last_result": last_result,
            "next_eligible_at": "2026-08-29T14:28:27-06:00",
        },
        "active_workers": {"supervisor": 0, "benchmark": 0},
    }


def test_governance_blocks_everything():
    snap = healthy_snapshot()
    snap["governance"]["ok"] = False
    result = mod.reconcile(
        desired(), snap, datetime.fromisoformat("2026-08-29T14:30:41-06:00")
    )
    assert result["status"] == "BLOCKED_GOVERNANCE"
    assert result["proposals"] == []


def test_work_conserving_proposal_after_eligibility():
    result = mod.reconcile(
        desired(),
        healthy_snapshot(),
        datetime.fromisoformat("2026-08-29T14:30:41-06:00"),
    )
    assert [item["kind"] for item in result["proposals"]] == [
        "select_alternate_mission"
    ]


def test_saturated_recovery_also_selects_alternate_mission():
    result = mod.reconcile(
        desired(),
        healthy_snapshot("RECOVERY_SATURATED"),
        datetime.fromisoformat("2026-08-29T14:30:41-06:00"),
    )
    assert [item["kind"] for item in result["proposals"]] == [
        "select_alternate_mission"
    ]


def test_no_alternate_mission_before_eligibility():
    result = mod.reconcile(
        desired(),
        healthy_snapshot(),
        datetime.fromisoformat("2026-08-29T14:27:41-06:00"),
    )
    assert result["proposals"] == []


def test_disabled_declared_job_proposes_only_named_enable():
    snap = healthy_snapshot()
    snap["cron"]["jobs"][0]["enabled"] = False
    result = mod.reconcile(
        desired(), snap, datetime.fromisoformat("2026-08-29T14:27:41-06:00")
    )
    assert result["proposals"][0]["kind"] == "ensure_job_enabled"
    assert result["proposals"][0]["target"] == "kevin-supervisor-v1"


if __name__ == "__main__":
    test_governance_blocks_everything()
    test_work_conserving_proposal_after_eligibility()
    test_saturated_recovery_also_selects_alternate_mission()
    test_no_alternate_mission_before_eligibility()
    test_disabled_declared_job_proposes_only_named_enable()
    print("PASS: reconcile_dryrun safety tests")
