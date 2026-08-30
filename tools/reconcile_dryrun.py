#!/usr/bin/env python3
"""Kevin Desired State reconciler dry-run.

Reads owner-controlled Desired State plus sanitized support telemetry and emits
allowlisted, typed, deterministic GREEN proposals. It performs no writes, starts
no processes, changes no permissions, and executes no maintenance actions.
"""

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

ALLOWED_ACTIONS = {
    "ensure_job_enabled",
    "run_benchmark",
    "run_support_bridge",
    "select_alternate_mission",
}


def parse_dt(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def digest(value):
    return hashlib.sha256(canonical(value).encode("utf-8")).hexdigest()


def validate_desired(desired):
    if desired.get("schema") != 1 or desired.get("kind") != "kevin-desired-state":
        raise ValueError("desired-state schema/kind mismatch")
    if desired.get("owner_controlled") is not True:
        raise ValueError("desired-state must be owner controlled")
    authority = desired.get("authority") or {}
    if not authority.get("green_only", False):
        raise ValueError("desired-state must remain GREEN-only")
    for key in (
        "allow_arbitrary_shell",
        "allow_authority_expansion",
        "allow_novel_production_promotion",
    ):
        if authority.get(key) is not False:
            raise ValueError(f"unsafe authority setting: {key}")
    slots = int((desired.get("resources") or {}).get("heavy_model_slots", 0))
    if slots != 1:
        raise ValueError("candidate policy requires exactly one heavy_model_slot")


def registry_entry(desired, verb, target):
    for item in desired.get("green_registry", []):
        if item.get("verb") != verb:
            continue
        exact = item.get("target")
        target_class = item.get("target_class")
        if exact == target:
            return item
        if target_class == "declared_job":
            declared = {x.get("declaration_key") for x in desired.get("jobs", [])}
            if target in declared:
                return item
    return None


def proposal(desired, kind, target, reason, evidence):
    if kind not in ALLOWED_ACTIONS:
        raise ValueError(f"action not allowlisted: {kind}")
    reg = registry_entry(desired, kind, target)
    if not reg:
        raise ValueError(f"action/target not in GREEN registry: {kind}:{target}")
    precondition = digest(evidence)
    idem = digest({"kind": kind, "target": target, "precondition": precondition})
    return {
        "schema": 1,
        "kind": kind,
        "target": target,
        "authority_class": "GREEN",
        "reason": reason,
        "precondition_fingerprint": precondition,
        "idempotency_key": idem,
        "postcondition_required": True,
        "rollback_required": bool(reg.get("rollback_required", False)),
        "evidence": evidence,
    }


def reconcile(desired, snapshot, now=None):
    validate_desired(desired)
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)

    proposals = []
    observations = []

    governance = snapshot.get("governance") or {}
    if not governance.get("ok"):
        return {
            "status": "BLOCKED_GOVERNANCE",
            "desired_state_fingerprint": digest(desired),
            "proposals": [],
            "observations": ["governance.ok is false"],
        }

    forbidden = set(desired.get("forbidden_authority") or [])
    live_forbidden = set(governance.get("never_self_authorize") or [])
    missing_forbidden = sorted(forbidden - live_forbidden)
    if missing_forbidden:
        return {
            "status": "BLOCKED_GOVERNANCE_DRIFT",
            "desired_state_fingerprint": digest(desired),
            "proposals": [],
            "observations": ["missing never_self_authorize: " + ",".join(missing_forbidden)],
        }

    pinned = desired.get("core_hashes") or {}
    live_hashes = snapshot.get("hashes") or {}
    drift = sorted(k for k, v in pinned.items() if live_hashes.get(k) != v)
    if drift:
        return {
            "status": "BLOCKED_CORE_DRIFT",
            "desired_state_fingerprint": digest(desired),
            "proposals": [],
            "observations": ["core hash drift: " + ",".join(drift)],
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
                    desired,
                    "ensure_job_enabled",
                    key,
                    "desired-state requires enabled job",
                    {
                        "declaration_key": key,
                        "enabled": bool(job.get("enabled")),
                        "last_status": job.get("last_status"),
                    },
                )
            )
        errors = int(job.get("consecutive_errors") or 0)
        max_errors = int(spec.get("max_consecutive_errors", 0))
        if errors > max_errors:
            observations.append(
                f"job unhealthy: {key} consecutive_errors={errors} max={max_errors}"
            )

    benchmark = snapshot.get("benchmark") or {}
    if desired.get("benchmark", {}).get("require_pass") and benchmark.get("status") != "PASS":
        proposals.append(
            proposal(
                desired,
                "run_benchmark",
                "kevin-benchmark-v1",
                "desired-state requires PASS benchmark evidence",
                {
                    "status": benchmark.get("status"),
                    "at": benchmark.get("at"),
                    "critical_failures": (benchmark.get("regression") or {}).get("critical_failures"),
                },
            )
        )

    scheduler = desired.get("scheduler") or {}
    supervisor = snapshot.get("supervisor") or {}
    active = snapshot.get("active_workers") or {}
    # Worker labels can overlap for one engineering activity. We only need an
    # evidence-backed busy/idle decision here, not a fake slot count.
    worker_busy = any(int(value or 0) > 0 for value in active.values())
    eligible = parse_dt(supervisor.get("next_eligible_at"))
    if eligible and eligible.tzinfo is None:
        eligible = eligible.replace(tzinfo=timezone.utc)

    alternate_results = {
        "RECOVERY_THROTTLED",
        "RECOVERY_SATURATED",
        "WAIT",
        "THROTTLED",
    }
    last_result = str(supervisor.get("last_result") or "").upper()

    if (
        scheduler.get("work_conserving")
        and scheduler.get("alternate_mission_after_throttle")
        and eligible
        and now >= eligible.astimezone(timezone.utc)
        and not worker_busy
        and last_result in alternate_results
    ):
        proposals.append(
            proposal(
                desired,
                "select_alternate_mission",
                "supervisor",
                "idle capacity after throttle/saturation eligibility should evaluate another already-authorized mission",
                {
                    "last_result": supervisor.get("last_result"),
                    "last_mission": supervisor.get("last_mission"),
                    "next_eligible_at": supervisor.get("next_eligible_at"),
                    "active_workers": active,
                    "candidate_queue": scheduler.get("candidate_queue") or [],
                    "never_bypass_cooldown": bool(scheduler.get("never_bypass_cooldown", True)),
                },
            )
        )

    return {
        "status": "OK",
        "desired_state_fingerprint": digest(desired),
        "proposals": proposals,
        "observations": observations,
    }


def main():
    parser = argparse.ArgumentParser(description="Kevin Desired State reconciler dry-run; no writes")
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
