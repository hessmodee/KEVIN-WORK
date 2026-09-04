#!/usr/bin/env python3
"""Deterministic tests for kevin-mission-lease-v1."""
from __future__ import annotations

import importlib.util
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "control-plane" / "autonomy" / "kevin-mission-lease-v1.py"


def load():
    spec = importlib.util.spec_from_file_location("kevin_mission_lease_v1", LIB)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def main() -> int:
    m = load()
    assert m.AUTHORITY == "NONE_LEASE_CHECKPOINT_ONLY"
    assert m.selftest() == 0

    store = m.new_store()
    t0 = datetime(2026, 9, 4, 16, 0, tzinfo=timezone.utc)
    m.acquire_lease(store, mission_id="busy", holder="main", now=t0, ttl_seconds=120)
    g = m.global_truth(store, t0)
    assert g["truth_state"] == "LEASE_WITHOUT_EVIDENCE"
    assert "busy" not in g["working_mission_ids"]

    bad = m.save_checkpoint(store, mission_id="ghost", holder="x", stage="PLAN", payload={}, resume_hint="n/a", now=t0)
    assert not bad["ok"]

    m.heartbeat(store, mission_id="busy", holder="main", evidence_uri="reports/e.json", now=t0)
    inv = m.save_checkpoint(store, mission_id="busy", holder="main", stage="HACK", payload={}, resume_hint="n/a", now=t0)
    assert not inv["ok"] and inv["reason"] == "INVALID_STAGE"

    m.save_checkpoint(store, mission_id="busy", holder="main", stage="EXECUTE", payload={"i": 1}, resume_hint="step2", now=t0 + timedelta(seconds=5))
    m.recover_orphans(store, now=t0 + timedelta(hours=8), stale_heartbeat_seconds=600)
    plan = m.resume_plan(store, "busy", now=t0 + timedelta(hours=8))
    assert plan["may_resume"] and plan["requires_new_lease"]
    m.acquire_lease(store, mission_id="busy", holder="main", now=t0 + timedelta(hours=8, seconds=1), ttl_seconds=300, evidence_uri="reports/e2.json")
    assert m.truth_for_mission(store, "busy", t0 + timedelta(hours=8, seconds=1)) == "WORKING"

    print("tools/test-kevin-mission-lease-v1.py PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
