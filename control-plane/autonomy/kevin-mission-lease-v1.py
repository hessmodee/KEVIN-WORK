#!/usr/bin/env python3
"""Kevin Mission Lease + Checkpoint v1 — authority-neutral overnight continuity primitives.

WORKING requires a live lease plus evidence-producing heartbeat.
Checkpoints enable resume after restart. Orphan recovery clears fake busy.
No production mutation, no Desktop install, no Supervisor replacement.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

VERSION = "1.0.0"
AUTHORITY = "NONE_LEASE_CHECKPOINT_ONLY"
SCHEMA = "kevin.mission_lease.v1"

VALID_LEASE_STATES = {"ACTIVE", "RELEASED", "EXPIRED", "ORPHANED"}
VALID_CHECKPOINT_STAGES = {
    "ACQUIRED",
    "PLAN",
    "EXECUTE",
    "VERIFY",
    "RECORD",
    "COMPLETE",
    "ABORT",
}


def _utc(dt: Optional[datetime] = None) -> datetime:
    if dt is None:
        return datetime.now(timezone.utc)
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _iso(dt: datetime) -> str:
    return _utc(dt).isoformat().replace("+00:00", "Z")


def _parse(ts: str) -> datetime:
    s = str(ts).strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    return _utc(datetime.fromisoformat(s))


def _digest(payload: Any) -> str:
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"), default=str).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()[:16].upper()


def new_store() -> Dict[str, Any]:
    return {
        "schema": SCHEMA,
        "version": VERSION,
        "authority_effect": AUTHORITY,
        "leases": {},
        "checkpoints": {},
    }


def acquire_lease(
    store: Dict[str, Any],
    *,
    mission_id: str,
    holder: str,
    now: Optional[datetime] = None,
    ttl_seconds: int = 900,
    evidence_uri: Optional[str] = None,
) -> Dict[str, Any]:
    """Acquire an exclusive mission lease. Fails closed if another live lease exists."""
    now = _utc(now)
    if ttl_seconds <= 0:
        raise ValueError("ttl_seconds must be > 0")
    mid = str(mission_id).strip()
    holder = str(holder).strip()
    if not mid or not holder:
        raise ValueError("mission_id and holder required")

    existing = store["leases"].get(mid)
    if existing and existing.get("state") == "ACTIVE":
        if _parse(existing["expires_at"]) > now:
            if existing.get("holder") != holder:
                return {
                    "ok": False,
                    "reason": "LEASE_HELD_BY_OTHER",
                    "lease": existing,
                    "truth_state": "WORKING_ELSEWHERE",
                }
            existing["expires_at"] = _iso(now + timedelta(seconds=ttl_seconds))
            existing["heartbeat_at"] = _iso(now)
            if evidence_uri:
                existing["evidence_uri"] = evidence_uri
                existing["evidence_producing"] = True
            store["leases"][mid] = existing
            return {
                "ok": True,
                "reason": "LEASE_RENEWED",
                "lease": existing,
                "truth_state": truth_for_mission(store, mid, now),
            }

    lease = {
        "mission_id": mid,
        "holder": holder,
        "state": "ACTIVE",
        "acquired_at": _iso(now),
        "heartbeat_at": _iso(now),
        "expires_at": _iso(now + timedelta(seconds=ttl_seconds)),
        "ttl_seconds": int(ttl_seconds),
        "evidence_uri": evidence_uri,
        "evidence_producing": bool(evidence_uri),
        "release_reason": None,
    }
    store["leases"][mid] = lease
    return {
        "ok": True,
        "reason": "LEASE_ACQUIRED",
        "lease": lease,
        "truth_state": truth_for_mission(store, mid, now),
    }


def heartbeat(
    store: Dict[str, Any],
    *,
    mission_id: str,
    holder: str,
    evidence_uri: str,
    now: Optional[datetime] = None,
    extend_ttl: bool = True,
) -> Dict[str, Any]:
    """Evidence-producing heartbeat. Without evidence_uri, WORKING is refused."""
    now = _utc(now)
    mid = str(mission_id).strip()
    lease = store["leases"].get(mid)
    if not lease or lease.get("state") != "ACTIVE":
        return {"ok": False, "reason": "NO_ACTIVE_LEASE", "truth_state": "NOT_WORKING"}
    if lease.get("holder") != holder:
        return {"ok": False, "reason": "HOLDER_MISMATCH", "truth_state": "WORKING_ELSEWHERE"}
    if _parse(lease["expires_at"]) <= now:
        lease["state"] = "EXPIRED"
        return {"ok": False, "reason": "LEASE_EXPIRED", "lease": lease, "truth_state": "NOT_WORKING"}
    if not evidence_uri or not str(evidence_uri).strip():
        return {
            "ok": False,
            "reason": "EVIDENCE_REQUIRED_FOR_WORKING",
            "lease": lease,
            "truth_state": "LEASE_WITHOUT_EVIDENCE",
        }
    lease["heartbeat_at"] = _iso(now)
    lease["evidence_uri"] = str(evidence_uri).strip()
    lease["evidence_producing"] = True
    if extend_ttl:
        lease["expires_at"] = _iso(now + timedelta(seconds=int(lease.get("ttl_seconds") or 900)))
    store["leases"][mid] = lease
    return {
        "ok": True,
        "reason": "HEARTBEAT_OK",
        "lease": lease,
        "truth_state": truth_for_mission(store, mid, now),
    }


def release_lease(
    store: Dict[str, Any],
    *,
    mission_id: str,
    holder: str,
    reason: str = "COMPLETE",
    now: Optional[datetime] = None,
) -> Dict[str, Any]:
    now = _utc(now)
    mid = str(mission_id).strip()
    lease = store["leases"].get(mid)
    if not lease:
        return {"ok": False, "reason": "NO_LEASE", "truth_state": "NOT_WORKING"}
    if lease.get("holder") != holder and lease.get("state") == "ACTIVE":
        return {"ok": False, "reason": "HOLDER_MISMATCH", "lease": lease}
    lease["state"] = "RELEASED"
    lease["release_reason"] = reason
    lease["released_at"] = _iso(now)
    store["leases"][mid] = lease
    return {"ok": True, "reason": "LEASE_RELEASED", "lease": lease, "truth_state": "NOT_WORKING"}


def save_checkpoint(
    store: Dict[str, Any],
    *,
    mission_id: str,
    holder: str,
    stage: str,
    payload: Dict[str, Any],
    resume_hint: str,
    now: Optional[datetime] = None,
) -> Dict[str, Any]:
    now = _utc(now)
    stage = str(stage).strip().upper()
    if stage not in VALID_CHECKPOINT_STAGES:
        return {"ok": False, "reason": "INVALID_STAGE", "allowed": sorted(VALID_CHECKPOINT_STAGES)}
    mid = str(mission_id).strip()
    lease = store["leases"].get(mid)
    if not lease or lease.get("state") != "ACTIVE" or lease.get("holder") != holder:
        return {"ok": False, "reason": "ACTIVE_LEASE_REQUIRED_FOR_CHECKPOINT"}
    if _parse(lease["expires_at"]) <= now:
        lease["state"] = "EXPIRED"
        return {"ok": False, "reason": "LEASE_EXPIRED"}

    hist: List[Dict[str, Any]] = store["checkpoints"].setdefault(mid, [])
    seq = (hist[-1]["seq"] + 1) if hist else 1
    tip = hist[-1] if hist else None
    digest = _digest(payload)
    if tip and tip.get("stage") == stage and tip.get("payload_digest") == digest:
        return {"ok": True, "reason": "CHECKPOINT_REPLAY_IDEMPOTENT", "checkpoint": tip}

    cp = {
        "mission_id": mid,
        "seq": seq,
        "stage": stage,
        "holder": holder,
        "created_at": _iso(now),
        "payload_digest": digest,
        "resume_hint": str(resume_hint),
        "payload": copy.deepcopy(payload),
    }
    hist.append(cp)
    store["checkpoints"][mid] = hist
    return {"ok": True, "reason": "CHECKPOINT_SAVED", "checkpoint": cp}


def latest_checkpoint(store: Dict[str, Any], mission_id: str) -> Optional[Dict[str, Any]]:
    hist = store.get("checkpoints", {}).get(str(mission_id).strip()) or []
    return copy.deepcopy(hist[-1]) if hist else None


def recover_orphans(
    store: Dict[str, Any],
    *,
    now: Optional[datetime] = None,
    stale_heartbeat_seconds: int = 600,
) -> Dict[str, Any]:
    """Mark expired or stale-heartbeat ACTIVE leases ORPHANED so WORKING cannot fake-busy."""
    now = _utc(now)
    orphans: List[Dict[str, Any]] = []
    for mid, lease in list(store.get("leases", {}).items()):
        if lease.get("state") != "ACTIVE":
            continue
        expired = _parse(lease["expires_at"]) <= now
        hb = _parse(lease.get("heartbeat_at") or lease["acquired_at"])
        stale = (now - hb).total_seconds() > stale_heartbeat_seconds
        no_evidence = not lease.get("evidence_producing")
        aged = (now - _parse(lease["acquired_at"])).total_seconds() > 60
        if expired or stale or (no_evidence and aged):
            lease["state"] = "ORPHANED"
            lease["orphan_at"] = _iso(now)
            lease["orphan_reasons"] = [
                r
                for r, cond in (
                    ("EXPIRED", expired),
                    ("STALE_HEARTBEAT", stale),
                    ("NO_EVIDENCE", no_evidence and aged),
                )
                if cond
            ]
            store["leases"][mid] = lease
            orphans.append(copy.deepcopy(lease))
    return {
        "ok": True,
        "reason": "ORPHAN_SCAN_COMPLETE",
        "orphan_count": len(orphans),
        "orphans": orphans,
        "authority_effect": AUTHORITY,
    }


def truth_for_mission(store: Dict[str, Any], mission_id: str, now: Optional[datetime] = None) -> str:
    """Truth vocabulary aligned with HQ: WORKING only with live lease + evidence."""
    now = _utc(now)
    lease = store.get("leases", {}).get(str(mission_id).strip())
    if not lease:
        return "NOT_WORKING"
    state = lease.get("state")
    if state in {"RELEASED", "EXPIRED", "ORPHANED"}:
        return "NOT_WORKING"
    if state != "ACTIVE":
        return "NOT_WORKING"
    if _parse(lease["expires_at"]) <= now:
        return "NOT_WORKING"
    if not lease.get("evidence_producing") or not lease.get("evidence_uri"):
        return "LEASE_WITHOUT_EVIDENCE"
    return "WORKING"


def global_truth(store: Dict[str, Any], now: Optional[datetime] = None) -> Dict[str, Any]:
    now = _utc(now)
    working = []
    lease_no_evidence = []
    for mid in store.get("leases", {}):
        t = truth_for_mission(store, mid, now)
        if t == "WORKING":
            working.append(mid)
        elif t == "LEASE_WITHOUT_EVIDENCE":
            lease_no_evidence.append(mid)
    if working:
        state = "WORKING"
    elif lease_no_evidence:
        state = "LEASE_WITHOUT_EVIDENCE"
    else:
        state = "NOT_WORKING"
    return {
        "truth_state": state,
        "working_mission_ids": working,
        "lease_without_evidence_ids": lease_no_evidence,
        "authority_effect": AUTHORITY,
        "observed_at": _iso(now),
    }


def resume_plan(store: Dict[str, Any], mission_id: str, now: Optional[datetime] = None) -> Dict[str, Any]:
    """Build a resume plan from latest checkpoint after orphan/restart. Does not auto-acquire."""
    now = _utc(now)
    mid = str(mission_id).strip()
    cp = latest_checkpoint(store, mid)
    lease = store.get("leases", {}).get(mid)
    if not cp:
        return {"ok": False, "reason": "NO_CHECKPOINT", "may_resume": False}
    if cp.get("stage") == "COMPLETE":
        return {"ok": True, "reason": "ALREADY_COMPLETE", "may_resume": False, "checkpoint": cp}
    orphaned = bool(lease and lease.get("state") in {"ORPHANED", "EXPIRED", "RELEASED"})
    needs_lease = (not lease) or lease.get("state") != "ACTIVE" or _parse(lease["expires_at"]) <= now
    return {
        "ok": True,
        "reason": "RESUME_AVAILABLE",
        "may_resume": True,
        "requires_new_lease": bool(needs_lease),
        "orphaned_prior_lease": orphaned,
        "checkpoint": cp,
        "next_stage_hint": cp.get("resume_hint"),
        "authority_effect": AUTHORITY,
    }


def selftest() -> int:
    store = new_store()
    t0 = datetime(2026, 9, 4, 15, 0, tzinfo=timezone.utc)
    a = acquire_lease(store, mission_id="m1", holder="skill-lab", now=t0, ttl_seconds=300)
    assert a["ok"] and a["reason"] == "LEASE_ACQUIRED"
    assert truth_for_mission(store, "m1", t0) == "LEASE_WITHOUT_EVIDENCE"
    h = heartbeat(
        store,
        mission_id="m1",
        holder="skill-lab",
        evidence_uri="reports/engineering/latest.json",
        now=t0 + timedelta(seconds=5),
    )
    assert h["ok"] and truth_for_mission(store, "m1", t0 + timedelta(seconds=5)) == "WORKING"
    b = acquire_lease(store, mission_id="m1", holder="other", now=t0 + timedelta(seconds=10), ttl_seconds=300)
    assert not b["ok"] and b["reason"] == "LEASE_HELD_BY_OTHER"
    c1 = save_checkpoint(
        store,
        mission_id="m1",
        holder="skill-lab",
        stage="EXECUTE",
        payload={"step": 1},
        resume_hint="continue step 2",
        now=t0 + timedelta(seconds=20),
    )
    assert c1["ok"] and c1["checkpoint"]["seq"] == 1
    c1b = save_checkpoint(
        store,
        mission_id="m1",
        holder="skill-lab",
        stage="EXECUTE",
        payload={"step": 1},
        resume_hint="continue step 2",
        now=t0 + timedelta(seconds=21),
    )
    assert c1b["reason"] == "CHECKPOINT_REPLAY_IDEMPOTENT"
    bad = heartbeat(store, mission_id="m1", holder="skill-lab", evidence_uri="  ", now=t0 + timedelta(seconds=30))
    assert not bad["ok"] and bad["reason"] == "EVIDENCE_REQUIRED_FOR_WORKING"
    store2 = new_store()
    acquire_lease(
        store2,
        mission_id="m2",
        holder="supervisor",
        now=t0,
        ttl_seconds=60,
        evidence_uri="reports/x.json",
    )
    orphan = recover_orphans(store2, now=t0 + timedelta(seconds=120), stale_heartbeat_seconds=30)
    assert orphan["orphan_count"] == 1
    assert store2["leases"]["m2"]["state"] == "ORPHANED"
    assert truth_for_mission(store2, "m2", t0 + timedelta(seconds=120)) == "NOT_WORKING"
    assert global_truth(store2, t0 + timedelta(seconds=120))["truth_state"] == "NOT_WORKING"
    store3 = new_store()
    acquire_lease(
        store3,
        mission_id="m3",
        holder="skill-lab",
        now=t0,
        ttl_seconds=300,
        evidence_uri="reports/e.json",
    )
    save_checkpoint(
        store3,
        mission_id="m3",
        holder="skill-lab",
        stage="VERIFY",
        payload={"n": 2},
        resume_hint="finish verify",
        now=t0 + timedelta(seconds=10),
    )
    recover_orphans(store3, now=t0 + timedelta(seconds=1000), stale_heartbeat_seconds=30)
    plan = resume_plan(store3, "m3", now=t0 + timedelta(seconds=1000))
    assert plan["may_resume"] and plan["requires_new_lease"] and plan["checkpoint"]["stage"] == "VERIFY"
    release_lease(store, mission_id="m1", holder="skill-lab", reason="COMPLETE", now=t0 + timedelta(seconds=40))
    assert truth_for_mission(store, "m1", t0 + timedelta(seconds=40)) == "NOT_WORKING"
    assert global_truth(new_store(), t0)["truth_state"] == "NOT_WORKING"
    print(f"KEVIN MISSION LEASE v1 SELFTEST PASS (8 scenarios) version={VERSION} authority={AUTHORITY}")
    return 0


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Kevin Mission Lease + Checkpoint v1")
    p.add_argument("--selftest", action="store_true")
    args = p.parse_args(argv)
    if args.selftest:
        return selftest()
    p.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
