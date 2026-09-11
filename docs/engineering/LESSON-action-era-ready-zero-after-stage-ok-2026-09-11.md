# LESSON — Action Era ready=0 after STAGE_OK (2026-09-11)

**Family:** `invocation-worker-fail-closed-v1` (OPEN until first PASS)
**Not PASS.**

## Discriminating evidence (~13:43–13:46 MT)
- Public diagnose: `STAGE_OK_WAITING_ACTION_ERA`, `sticky_repair=ALREADY_CLEAN`, `supervisor_request_id_reason=STAGE_OK`, worker live `7E1129B7…`
- `live_action_era_ready_invoke_count=0`
- Engineering Action Era queues: `ready=0`, `running=0`, `done=70`, `failed=1`
- Autonomy continuation still `BLOCKED_INVOCATION_RUNTIME` / `68845506…` (= `SHA256("INVOCATION_WORKER_FAILED exit=1")`)
- Support Supervisor: `NO_ELIGIBLE_MISSION` (ControlPlane mission lane — not the same as autonomy WorkInstance selection)

## Rule
Sticky quarantine intentionally clears leftover `invoke-*` Action Era ready/failed (never DONE/receipts). `ready=0` after STAGE_OK is **expected**, not a missing skill. Next step is live Supervisor/autonomy-continuation re-select of `owner-west-motor-parts-chase-fresh-8-v1` so the worker stages fresh `create_spreadsheet` + `create_text` into Action Era ready. Isolated diagnose + sim queue is never Action Era.

If continuation stays `68845506…` after a clean STAGE_OK, chase **live worker exit=1** on RequestId `invoke-owner-west-motor-parts-chase-fresh-8-v1` (typed python reason / collision / payload), not another puller paste unless hashes drift.

## Kevin self-repair
1. Confirm diagnose STAGE_OK + sticky ALREADY_CLEAN + worker hash match.
2. Do not recopy Supervisor; do not reinstall worker v1.1; do not overwrite GitHub pin `16C49542…`.
3. Wait/force autonomy re-select; inspect Action Era ready for new `invoke-invoke-…-s0N` orders.
4. PASS = workbook + note + DONE + hashes + immutable receipt.
