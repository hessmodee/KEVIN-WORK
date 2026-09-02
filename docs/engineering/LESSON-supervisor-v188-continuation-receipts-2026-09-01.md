# Lesson: Supervisor v1.8.8 continuation receipts (2026-09-01)

## Where truth lives
Do **not** use legacy `reports/supervisor/supervisor-state.json` as v1.8.8 health. That file can stay stale on the old High Gear schema.

v1.8.8 writes:
- `reports/autonomy-continuation-latest.json` (controller state)
- `reports/autonomy-continuation-public.json` (sanitized publish)
- `reports/autonomy-selection-current.json` (last deterministic selection)
- `reports/autonomy-runtime/continuation-state.json` (per-item turn budgets)

## Observed after install (no handed work-item ID)
- Selector chose `hq-direct-chat-real-roundtrip` and `staging-trajectory-reliability-v1` itself.
- Both recorded `AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF` (honest: model turn ≠ outcome).
- Latest status `WAITING_ITEM_BUDGETS` / `ALL_ELIGIBLE_ITEMS_HAVE_RECORDED_DEFERRAL` with `MIN_REPEAT` — anti-spin working.

## Next for CONTINUE proof
Need a scheduled cycle where selected work produces independent semantic verification + durable result, not only an agent turn. Do not clear budgets by hand to fake progress.