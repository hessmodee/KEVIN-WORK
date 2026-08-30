# Skill Lab Runner Recovery Spec v1

Status: OWNER CHECKPOINT REQUIRED FOR LOCAL RUNNER REPLACEMENT/RESTART
Date: 2026-08-30

## Current proven state

- Benchmark remains PASS 30/30, critical=0.
- Engineering Relay is healthy.
- Operator and Initiative self-tests pass.
- UI Bridge component hash matches its proven identity.
- Composite skill manifests validate and stage successfully.
- Skill Lab cron is enabled but repeatedly errors.
- At least one composite skill is stuck RUNNING and another may remain READY.

## Failure isolation

Primary failure family: `skill_lab_runner_orchestration`.

Ruled out by evidence:

- manifest hash/validation path
- `create_text` GREEN primitive
- Green Operator self-test
- Initiative Engine self-test
- UI Bridge pinned component identity
- Benchmark/core regression

This means the failing surface is the local Skill Lab runner/orchestration implementation or its state-transition/recovery logic, not the already-proven primitives.

## Recovery design requirements

Any replacement or repair must preserve the existing authority envelope and add no new primitive authority.

Required behavior:

1. Detect stale RUNNING composite work using a bounded lease/heartbeat.
2. Reconcile stale RUNNING work deterministically to either RETRYABLE or FAILED with evidence; never leave permanent RUNNING tombstones.
3. Use idempotent per-step work-order IDs so a runner restart cannot duplicate a proven primitive action.
4. Before advancing a step, read the Operator result and verify expected evidence/hash rather than trusting process exit alone.
5. Persist runner state before and after every transition.
6. Use bounded retries and cool down a repeated failure family after three materially distinct failed attempts.
7. Never auto-promote a skill to PROVEN unless every declared step has deterministic evidence.
8. Never accept arbitrary shell/code, arbitrary file paths, new primitive types, credentials, permission changes, external sends, purchases, or Yellow/Red actions.
9. Preserve current Relay allowlist and owner locks.
10. Run a fresh Benchmark after repair and require PASS 30/30 critical=0 before declaring recovery proven.

## Recovery proof sequence

A repaired runner is not PROVEN until all of the following pass:

1. parser/static validation of candidate runner
2. existing Skill Lab self-test
3. stale-RUNNING recovery test
4. one-step `create_text` isolation composite
5. two-step `create_text -> ui_notepad_write` composite
6. duplicate/replay test proving no duplicate action
7. intentional primitive failure proving FAILED evidence is recorded
8. restart/resume test proving deterministic recovery
9. fresh Benchmark PASS 30/30 critical=0
10. durable recovery proof artifact with exact hashes

## Owner checkpoint

Current GREEN remote maintenance authority does not authorize restarting or replacing the local Skill Lab runner. The next machine-side action therefore requires a specific owner-approved local repair/install step or an explicit extension of typed GREEN maintenance to this narrowly defined runner recovery action.

No arbitrary remote shell should be introduced to solve this problem.
