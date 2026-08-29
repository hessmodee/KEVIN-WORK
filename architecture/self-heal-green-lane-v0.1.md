# Kevin Self-Heal Reconciler + GREEN Maintenance Lane v0.1

Status: draft candidate; no production authority is granted by this document.

## Goal

Keep Kevin near a declared healthy state without creating arbitrary execution authority. The reconciler compares a small Desired State document with sanitized support telemetry and emits typed proposals. A separate policy gate may later execute only explicitly allowlisted GREEN operations.

## Safety boundary

The reconciler never expands permissions and never authorizes arbitrary shell, production chat tools, credential access, external sends, purchases, financial actions, automatic production promotion, or safety weakening. If `governance.ok` is false, reconciliation is blocked.

GREEN operations must be deterministic, reversible, named in advance, and bounded. Candidate operation types for the first execution lane are:

- `ensure_job_enabled`: only for a job already declared by exact `declaration_key` in Desired State.
- `refresh_public_snapshot`: request regeneration of sanitized metadata-only telemetry.
- `run_benchmark_if_due`: invoke the existing named benchmark path only when policy says it is due.
- `select_alternate_mission`: scheduler decision only; it may choose another already-authorized mission but may not create new authority.

The dry-run prototype in `tools/reconcile_dryrun.py` performs no writes and emits proposals only.

## Desired State contract

Desired State is owner-controlled configuration. Initial fields intentionally stay narrow:

- required declared cron jobs and whether each must be enabled;
- maximum accepted consecutive errors;
- benchmark PASS requirement;
- work-conserving scheduler policy.

A future production reconciler should include a versioned schema, hash the Desired State used for every decision, and write an evidence record containing before-state, proposal, validation, result, and rollback outcome.

## Work-conserving mission scheduling

Throttle/cooldown is mission-specific protection, not a reason for Kevin to be generally idle.

When all of the following are true:

1. governance is healthy;
2. no worker is active;
3. the previous result is throttle/wait related;
4. `now >= next_eligible_at`;
5. another authorized mission is available;

Mission Control should evaluate another eligible mission rather than simply repeating the throttled candidate or remaining idle. It must still honor resource limits, duplicate-work fingerprints, cooldowns, benchmark gates, and owner-locked governance.

Telemetry should distinguish these states explicitly: `idle_no_work`, `cooldown_wait`, `alternate_mission_selected`, `blocked_governance`, and `worker_active`.

## Validation gates before any production executor

1. Dry-run against at least one healthy snapshot and one degraded fixture.
2. Deterministic output for identical Desired State + snapshot + time.
3. Reject unknown action kinds.
4. Reject undeclared job targets.
5. Block all proposals when governance is unhealthy.
6. Bounded retry count and cooldown for any future executor.
7. Evidence record for every attempted repair.
8. Rollback path validated for each executable GREEN action.

## Current observed reason for this candidate

The support snapshot showed healthy governance, all declared jobs enabled with zero consecutive errors, benchmark 30/30 PASS, no active workers, and a previous `RECOVERY_THROTTLED` supervisor result. This is a useful fixture for validating work-conserving scheduling without weakening the recovery throttle itself.
