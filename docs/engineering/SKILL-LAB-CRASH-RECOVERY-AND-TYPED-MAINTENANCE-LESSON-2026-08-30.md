# Skill Lab crash recovery + typed maintenance lesson — 2026-08-30

Status: engineering lesson captured; live recovery bootstrap staged, not yet applied.

## What failed

Skill Lab v1.0.2 created a deterministic Operator work-order record before durably linking that order ID into the composite-run state. If the runner stopped in that crash window, the next run found the legitimate pre-existing deterministic order and classified it as an ID collision. The composite could remain RUNNING while the Operator itself remained healthy.

This is an orchestration/idempotency failure, not a failure of the proven GREEN primitives.

## Permanent Skill Lab rule

For every composite step:

1. derive a deterministic step ID and semantic key;
2. persist enqueue intent before creating the work order;
3. on every resume, reconcile READY/RUNNING/DONE/FAILED queues by deterministic ID;
4. adopt an exactly matching READY/RUNNING order rather than duplicate it;
5. consume DONE only after operation, semantic key, authority, payload fingerprint, and result evidence validate;
6. fail closed on same-ID conflicting content or duplicate queue records;
7. never replay a completed step;
8. bound stale-missing-order recovery to three attempts;
9. record failure evidence and state transitions durably;
10. never mark the composite PROVEN until every step has deterministic evidence.

Skill Lab v1.0.3 candidate SHA256:
`A771B050A5DA3D49BC3445BE4C20B4BF928C86AFA22E6634550CFBA4F30DB865`

Independent candidate evidence:
- 19/19 crash/restart/replay model cases pass;
- PowerShell parser + runner self-test pass;
- fixed primitive envelope remains `create_text`, `create_spreadsheet`, `ui_notepad_write`;
- arbitrary shell and generic mouse/keyboard remain unavailable.

The candidate remains CI-qualified, not Omen-PROVEN, until the live recovery proof sequence completes.

## What the repair process exposed

Maintenance Runner v1.1d correctly verifies hash-pinned GREEN PowerShell proposals but its scheduled intake is intentionally `-CheckOnly`. It also cannot directly target Skill Lab or UI Bridge. Therefore owner approval existed, but there was no typed end-to-end delivery verb for these two known GREEN repairs.

Do not solve this gap with arbitrary remote shell or by disguising an unrelated executable package as a repair.

## Typed Maintenance v1.2 doctrine

Typed Maintenance v1.2 adds only two declarative operations:

- `replace_pinned_file` — target alias fixed to `skill_lab_runner`, source fixed to `control-plane/skill-lab/*.ps1`, with exact source/current/after hashes, parser, fixed self-test, backup/rollback, and fresh Benchmark proof.
- `restart_ui_bridge` — target alias fixed to `ui_bridge_runner`, exact UI Bridge hash, exact scheduled-task name `Kevin UI Bridge v0.3`, bounded heartbeat recovery, and fresh Benchmark proof.

Every schema-2 typed manifest must remain GREEN, authority delta NONE, production effect NONE, owner-policy exact, and owner-preauthorized. The live desired state must still deny arbitrary shell, authority expansion, and novel production promotion. Repeated failures stop after three attempts. A previously PROVEN manifest ID never replays.

Typed Maintenance v1.2 candidate SHA256:
`3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483`

Independent candidate evidence:
- 18/18 typed-maintenance policy cases pass;
- PowerShell parser + self-test pass;
- static authority-boundary gate passes;
- no caller-selected local path or arbitrary command/process arguments;
- legacy executable packages do not auto-apply under v1.2.

## One-time bootstrap

The old v1.1d runner is itself an allowlisted maintenance target, so it can perform one narrow owner-approved self-upgrade to the CI-qualified v1.2 bytes. The bootstrap package:

- requires old runner SHA256 `B47714C91EFDCCD1FAE6C2CB0B97D72F799125A63C084956916A8BD5A07678C1`;
- requires new runner SHA256 `3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483`;
- fetches only the fixed v1.2 candidate source;
- parses and self-tests it;
- backs up only `kevin-maintenance-runner.ps1`;
- replaces only that file;
- verifies the after hash;
- rolls back on failure;
- makes no Skill Lab, UI Bridge, cron, desired-state, permission, or authority change.

Bootstrap package SHA256:
`8DAD35982EFACAB9165D3100C977D42DB5442002413E093A2A01B01600292935`

Live Maintenance Intake independently reached `STAGED_APPROVAL_REQUIRED` for manifest `maintenance-bootstrap-v12-20260830-1015` at 2026-08-30 10:16 local. A fresh Benchmark at 10:15:30 remained PASS 30/30 critical=0.

The remaining bootstrap transport step is the existing v1.1d local `-ApplyOnce` invocation. No currently proven remote typed verb exposes that switch; do not introduce arbitrary remote execution to avoid this one bounded bootstrap.

## Follow-on proof order

After v1.2 bootstrap is independently observed:

1. typed UI Bridge restart; require exact binary hash + fresh READY heartbeat + fresh 30/30 Benchmark;
2. typed Skill Lab v1.0.3 replacement; require exact before/after hashes + runner self-test + fresh 30/30 Benchmark;
3. stale-RUNNING recovery proof;
4. one-step `create_text` composite;
5. two-step `create_text -> ui_notepad_write` composite;
6. duplicate/replay proof;
7. intentional primitive failure proof;
8. restart/resume proof;
9. final fresh Benchmark PASS 30/30 critical=0;
10. only then mark Skill Lab recovery Omen-PROVEN and codify reusable composite skills.

## General engineering lesson

A system is not autonomous merely because it can diagnose a repair and the owner has approved it. The delivery path must itself be typed, bounded, idempotent, independently verified, and recoverable. When a required maintenance action cannot travel through that contract, improve the contract narrowly rather than adding a generic executor.
