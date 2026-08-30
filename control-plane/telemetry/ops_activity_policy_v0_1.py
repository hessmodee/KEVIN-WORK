#!/usr/bin/env python3
"""Pure Kevin Ops Floor activity-state policy.

This module classifies sanitized telemetry only. It does not launch work, mutate the
host, change authority, or manufacture activity. Its purpose is to distinguish
ACTIVE work from an ARMED autonomous scheduler and from true IDLE time.
"""
from __future__ import annotations

from datetime import datetime, timezone

TERMINAL_OR_WAIT_PHASES = {
    "yield", "cooldown", "wait", "skip", "queued", "idle", "armed",
    "complete", "completed", "done", "stopped",
}


def _dt(value):
    if not value:
        return None
    d = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    if d.tzinfo is None or d.utcoffset() is None:
        raise ValueError("timestamp must be timezone-aware")
    return d.astimezone(timezone.utc)


def _recent(value, now, seconds):
    d = _dt(value)
    if d is None:
        return False
    return 0 <= (now.astimezone(timezone.utc) - d).total_seconds() <= seconds


def task_active(task):
    if not isinstance(task, dict) or not task:
        return False
    phase = str(task.get("phase") or "").strip().lower()
    return phase not in TERMINAL_OR_WAIT_PHASES


def classify(snapshot, now):
    """Return a truthful user-facing state and evidence.

    Priority: OFFLINE/DEGRADED -> ACTIVE -> COOLDOWN -> ARMED -> IDLE.
    ARMED never means work is currently executing. It means a healthy declared
    autonomous schedule is enabled and has fresh evidence of cycling or a known
    next run. This prevents short task gaps from being mislabeled as true idleness.
    """
    if not isinstance(snapshot, dict):
        raise ValueError("snapshot must be an object")
    if now.tzinfo is None or now.utcoffset() is None:
        raise ValueError("now must be timezone-aware")

    generated_at = snapshot.get("generated_at")
    if not _recent(generated_at, now, 15 * 60):
        return {"state": "OFFLINE", "executing": False, "evidence": ["telemetry-stale"]}

    health = str((snapshot.get("health") or {}).get("overall") or "").lower()
    if health and health not in {"healthy", "ready"}:
        return {"state": "DEGRADED", "executing": False, "evidence": ["health-degraded"]}

    task = snapshot.get("current_task")
    if task_active(task):
        return {"state": "ACTIVE", "executing": True, "evidence": ["active-current-task"]}

    support = snapshot.get("support") or {}
    supervisor = support.get("supervisor") or {}
    last_result = str(supervisor.get("last_result") or "").upper()
    if any(token in last_result for token in ("THROTTLED", "SATURATED", "WAIT", "COOL")):
        return {"state": "COOLDOWN", "executing": False, "evidence": ["supervisor-cooldown"]}

    cron = support.get("cron") or []
    sup_job = next((j for j in cron if j.get("declaration_key") == "kevin-supervisor-v1"), None)
    supervisor_armed = bool(sup_job and sup_job.get("enabled") is True and str(sup_job.get("last_status") or "").lower() == "ok")

    activity = list(snapshot.get("activity") or [])
    recent_engineering = any(
        e.get("event") in {"task_start", "task_finish", "task_progress"}
        and str(e.get("component") or "").lower() in {"forge", "supervisor", "benchmark", "skill-lab", "engineering"}
        and _recent(e.get("at"), now, 15 * 60)
        for e in activity
    )

    next_eligible = supervisor.get("next_eligible_at")
    has_fresh_next_cycle = False
    if next_eligible:
        d = _dt(next_eligible)
        if d is not None:
            delta = (d - now.astimezone(timezone.utc)).total_seconds()
            has_fresh_next_cycle = -5 * 60 <= delta <= 15 * 60

    if supervisor_armed and (recent_engineering or has_fresh_next_cycle):
        evidence = ["supervisor-schedule-armed"]
        if recent_engineering:
            evidence.append("recent-engineering-activity")
        if has_fresh_next_cycle:
            evidence.append("fresh-next-cycle")
        return {"state": "ARMED", "executing": False, "evidence": evidence}

    return {"state": "IDLE", "executing": False, "evidence": ["no-active-or-armed-work"]}
