# Bess ↔ Kevin Control Plane v0.1

Status: design-only candidate. This branch does not change Kevin production behavior.

## Objective

Remove routine human copy/paste from Kevin operations while preserving owner authority, evidence, rollback, and fail-closed behavior.

The control plane separates four concerns:

1. **Observe** — Kevin publishes sanitized machine-readable support state.
2. **Reconcile** — a deterministic local self-heal controller compares observed state with an owner-approved desired state.
3. **Repair** — only typed, pre-authorized GREEN repair verbs may auto-execute.
4. **Develop** — novel fixes/capabilities remain candidates until isolated tests and promotion evidence pass.

## Design principles

- Desired state and observed state are separate.
- A repair is successful only after independent postcondition verification.
- Repeated failure is not progress: bounded retries, cooldown, then BLOCKED/NEEDS_REVIEW.
- Remote control uses typed work orders, never arbitrary remote shell strings.
- Every mutable action is idempotent or guarded by explicit preconditions.
- Every write has an idempotency key and an audit result.
- Production Chat remains narrow and is not the repair executor.
- One 14B engineering worker at a time unless resource testing proves otherwise.
- No secrets, raw prompts, credentials, absolute host paths, or private environment data are published to the public repo.

## Authority classes

### GREEN — automatic after local policy validation

Only restoration/diagnostic operations that return Kevin toward an already owner-approved state and do not broaden authority. Initial verb set:

- `collect_diagnostics`
- `run_benchmark`
- `run_support_bridge`
- `run_doctor_lint`
- `enable_expected_automation`
- `restart_known_kevin_service`
- `restore_pinned_kevin_file`
- `clear_verified_stale_lock`

Each verb must have a fixed local implementation, fixed target allowlist, timeout, retry budget, postcondition, rollback or no-op safety, and audit evidence.

### YELLOW — candidate/test lane

New code, new tools, changed behavior, changed model policy, new file targets, or capability expansion. YELLOW may be staged and tested automatically but is not production-promoted by this v0.1 protocol.

### RED — never automatic

Permissions/authority expansion, arbitrary shell, credential access, safety weakening, financial transactions, purchases, external sends as owner, destructive user-file operations, or other owner-reserved actions.

## Desired-state reconciler

A deterministic controller should run on a short cadence and evaluate:

- pinned core hashes
- required automation declarations and enabled state
- recent automation run status and consecutive errors
- Benchmark pass/critical-failure state
- support snapshot freshness
- Supervisor recovery/cooldown state
- known Kevin service health
- active-worker/resource mutex state
- maintenance/control-plane state

For each drift item it selects either:

- `HEALTHY`
- `AUTO_REPAIR_ELIGIBLE`
- `REPAIRING`
- `VERIFIED`
- `COOLING_DOWN`
- `BLOCKED`
- `NEEDS_REVIEW`

A failed repair family gets at most three meaningful attempts. Attempt 2 must incorporate diagnosis; attempt 3 must materially change the approach. No fourth attempt occurs until evidence/dependency/state changes.

## Work-order transport

Remote work orders are JSON objects validated against `schemas/work-order-v1.schema.json`.

The receiver must reject a work order unless:

- schema/kind/version are exact
- id and idempotency key are new or safely replayable
- authority class is allowed for the requested mode
- verb is in the local typed registry
- target is in the local target allowlist
- preconditions match current observed state
- order is not expired
- budget limits are valid
- no forbidden authority delta is requested

The receiver maps the verb to preinstalled local code. It does **not** execute a command string supplied by the work order.

## Development lane

Novel repairs and new capabilities follow:

`problem → mission contract → candidate → isolated tests → adversarial review → benchmark/regression → rollback proof → promotion evidence`

Candidate generation and evaluation may be autonomous. Production promotion remains governed separately from the GREEN self-heal lane.

## Evidence contract

Each repair emits a result object containing:

- work order id
- observed pre-state hash/fingerprint
- selected verb and target
- attempt number
- start/end timestamps
- exit/result status
- postcondition evidence
- rollback evidence when applicable
- resulting state fingerprint
- reusable lesson/failure class when unsuccessful

The support snapshot should summarize current reconciler state and last repair result without publishing sensitive raw logs.

## Phased rollout

### Phase 0 — complete
- Support Bridge create/update proven.
- Maintenance Intake missing-manifest behavior proven.
- Core remains pinned.

### Phase 1 — next
- Install Desired State v1 and deterministic Self-Heal Reconciler v0.1.
- Start with read-only diagnosis plus 2–3 harmless GREEN verbs.
- Seed failures intentionally and prove recovery.

### Phase 2
- Enable typed remote work-order intake for GREEN verbs.
- Prove idempotency, stale-precondition rejection, replay rejection, cooldown, and rollback.

### Phase 3
- Add candidate package staging for YELLOW work.
- Candidate packages are hash-pinned, parsed/static-checked, sandbox-tested, benchmarked, and cannot auto-promote under v0.1 governance.

### Phase 4
- Expand GREEN registry only from recurring proven repairs.
- Add Knowledge v1, HandoffEnvelope v2, Tool Budget Governor, checkpoint/resume, postmortems, and measured skill lifecycle.

## Success criterion

Routine Kevin operational failures are detected, classified, repaired, verified, and reported without Matt relaying terminal commands. Novel engineering failures become structured candidate work with enough evidence for Bess and Kevin to collaborate through the repository/control plane rather than through manual PowerShell copy/paste.
