#!/usr/bin/env python3
"""Kevin Desired State reconciler dry-run.

Reads owner-controlled Desired State plus sanitized support telemetry and emits
allowlisted typed proposals. It performs no writes, starts no processes, changes
no permissions, and executes no maintenance actions.
"""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ALLOWED_ACTIONS = {
    "ensure_job_enabled",
    "refresh_public_snapshot",
    "run_benchmark_if_due",
    "select_alternate_mission",
}


def parse_dt(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def proposal(kind, target, reason, evidence):
    if kind not in ALLOWED_ACTIONS:
        raise ValueError(f"action not allowlisted: {kind}")
    return {
        "kind": kind,
        "target": target,
        "reason": reason,
        "evidence": evidence,
    }


def reconcile(desired, snapshot, now=None):
    now = now or datetime.now(timezone.utc)
    proposals = []
    observations = []

    governance = snapshot.get("governance") or {}
    if not governance.get("ok"):
        return {
            "status": "BLOCKED_GOVERNANCE",
            "proposals": [],
            "observations": ["governance.ok is false"],
        }

    jobs = {
        item.get("declaration_key"): item
        for item in (snapshot.get("cron") or {}).get("jobs", [])
    }
    declared = {item.get("declaration_key") for item in desired.get("jobs", [])}

    for spec in desired.get("jobs", []):
        key = spec.get("declaration_key")
        job = jobs.get(key)
        if not key:
            observations.append("desired-state job missing declaration_key")
            continue
        if not job:
            observations.append(f"missing declared job: {key}")
            continue
        if spec.get("must_be_enabled") and not job.get("enabled"):
            if key not in declared:
                raise ValueError(f"undeclared target: {key}")
            proposals.append(
                proposal(
                    "ensure_job_enabled",
                    key,
                    "desired-state requires enabled job",
                    {"enabled": job.get("enabled")},
                )
            )
        errors = int(job.get("consecutive_errors") or 0)
        max_errors = int(spec.get("max_consecutive_errors", 0))
        if errors > max_errors:
            observations.append(
                f"job unhealthy: {key} consecutive_errors={errors} max={max_errors}"
            )

    benchmark = snapshot.get("benchmark") or {}
    if desired.get("benchmark", {}).get("require_pass"):
        if benchmark.get("status") != "PASS":
            proposals.append(
                proposal(
                    "run_benchmark_if_due",
                    "benchmark",
                    "desired-state requires PASS evidence",
                    {"status": benchmark.get("status")},
                )
            )

    scheduler = desired.get("scheduler") or {}
    supervisor = snapshot.get("supervisor") or {}
    active = snapshot.get("active_workers") or {}
    active_count = sum(int(value or 0) for value in active.values())
    eligible = parse_dt(supervisor.get("next_eligible_at"))
    if eligible and eligible.tzinfo is None:
        eligible = eligible.replace(tzinfo=timezone.utc)

    throttle_results = {"RECOVERY_THROTTLED", "WAIT", "THROTTLED"}
    last_result = str(supervisor.get("last_result") or "").upper()

    if (
        scheduler.get("work_conserving")
        and scheduler.get("alternate_mission_after_throttle")
        and eligible
        and now >= eligible.astimezone(timezone.utc)
        and active_count == 0
        and last_result in throttle_results
    ):
        proposals.append(
            proposal(
                "select_alternate_mission",
                "supervisor",
                "work-conserving policy: idle capacity after throttle eligibility should evaluate another authorized mission",
                {
                    "last_result": supervisor.get("last_result"),
                    "next_eligible_at": supervisor.get("next_eligible_at"),
                    "active_workers": active_count,
                    "never_bypass_cooldown": bool(
                        scheduler.get("never_bypass_cooldown", True)
                    ),
                },
            )
        )

    return {
        "status": "OK",
        "proposals": proposals,
        "observations": observations,
    }


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Kevin Desired State reconciler dry-run. Emits typed proposals only; "
            "performs no writes."
        )
    )
    parser.add_argument("desired")
    parser.add_argument("snapshot")
    parser.add_argument("--now", help="optional ISO-8601 evaluation time")
    args = parser.parse_args()

    desired = json.loads(Path(args.desired).read_text(encoding="utf-8"))
    snapshot = json.loads(Path(args.snapshot).read_text(encoding="utf-8-sig"))
    now = parse_dt(args.now) if args.now else None
    result = reconcile(desired, snapshot, now)
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
