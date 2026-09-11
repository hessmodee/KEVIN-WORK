# LESSON — sticky Supervisor RequestId vs isolated diagnose (2026-09-11)

**Family:** `invocation-worker-fail-closed-v1` (OPEN until first PASS)
**Machine:** HESS-PC / OpenClaw workspace
**Not PASS.** Follows `LESSON-builder-work-item-not-unique-2026-09-10.md`.

## Discriminating evidence

- Matt ran the v1.0.3 paste. Live hashes: invocation `471E5051…`, builder `83B3EDA6…`, puller v1.5.
- Isolated diagnose at 06:58:07 MDT published `STAGE_OK_WAITING_ACTION_ERA` / `python_exit=0` / `diagnose_ready_count=2` / `live_action_era_ready_invoke_count=0`.
- Uniqueness family is closed. GitHub `work-items.json` stays unique. Do not reset it.
- Continuation 33 seconds later is still `BLOCKED_INVOCATION_RUNTIME` / `failure_sha256=68845506…` = `SHA256("INVOCATION_WORKER_FAILED exit=1")`. Turn 1 at 09:31 kept.
- Diagnose RequestId is `diagnose-owner-west-motor-parts-chase-fresh-8-v1`. Supervisor RequestId is sticky `invoke-owner-west-motor-parts-chase-fresh-8-v1`. Order IDs are `invoke-invoke-…-s01`. Isolated diagnose can STAGE_OK forever while leftovers in `reports/invocations/runs/` or Action Era `ready/` keep the worker throwing.
- Registry repair only quarantines sticky runs when python hashes mismatch. After v1.0.3 is live, hashes match, so leftovers survive.

## Rule

Isolated diagnose is not Action Era. `STAGE_OK_WAITING_ACTION_ERA` means the builder+stage path works for a *different* RequestId. Next cheap test is: quarantine leftover `invoke-<work-id>*` run files and `invoke-invoke-<work-id>*` Action Era ready/failed orders (never DONE/receipts), then stage the Supervisor RequestId into an isolated sim queue, and publish the live worker hash. Do not recopy Supervisor. Do not queue another worker install. Do not overwrite GitHub ControlPlane pin `16C49542…`.

Kevin must publish the python reason **and** the live worker SHA. Public `68845506` cannot teach the next repair.

## Kevin self-repair

1. Confirm builder `83B3EDA6…` and invocation `471E5051…` are live. Uniqueness is closed.
2. Run `tools/Repair-Kevin-StickyInvokeState-v1.ps1` then `tools/Diagnose-Kevin-InvocationStage-v1.ps1` (puller v1.6 does both).
3. Read `reports/invocations/latest-public-reject.json`:
   - `INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST` / `WORK_ORDER_ID_COLLISION` → leftovers were the cause; quarantine should have healed; wait Supervisor.
   - `STAGE_OK_WAITING_ACTION_ERA` + `supervisor_request_id_reason=STAGE_OK` → python path is clean; inspect `worker_live_sha256` / `worker_has_hidden_python`.
   - Any other reason-code → repair that family. Do not recopy Supervisor.
4. Keep the 09:31 burned turn. Do not send the job to `fixed:main`.
5. PASS remains workbook + note + DONE + hashes + immutable receipt.

## Durable artifacts

- `tools/Repair-Kevin-StickyInvokeState-v1.ps1`
- Diagnose v1.3.2 (`supervisor_request_id`, worker hashes, `diagnose-worker-sim`)
- Puller v1.6
- Tests: registry-contract pins v1.6 + sticky script + Supervisor RequestId
