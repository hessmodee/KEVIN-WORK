# E2E outline — kevin-desktop-ui-v0 (isolated, not Chat)

**Status:** OUTLINE for Phase 2 candidate / Phase 3 gate. Do not run against live Chat.

## Preconditions
- HESS-PC Windows session with Calculator available
- Candidate path `candidates/desktop/kevin-desktop-ui-v0`
- `openclaw.json` unmodified (record SHA before/after)
- Chat 18789 / Reader 19001 stay up; no process kill
- Env enable only for this harness: `KEVIN_DESKTOP_UI_V0_ENABLE=1`

## Steps
1. Refuse-default (env unset): focus/click/type/prove → `disabled_by_default`
2. Refuse-unit: invalid_app, invalid_control, secret_deny, text_too_long → PASS
3. Enable env; run `py -3 -m module.ui_control prove`
4. Expect marker `KEVIN_DESKTOP_UI_CALC_V0_OK` and Display/result parse = 2 for `1+1=`
5. Unset enable env; confirm refuse returns again
6. Confirm `openclaw.json` SHA unchanged; Chat tools.allow unchanged

## Non-goals
- No fixed:main tool_call
- No CUA / screen xy
- No Non-Calculator apps
- No Chat widen

## Pass criteria
- Steps 1–6 green
- Receipt under `reports/engineering/RECEIPT-*-desktop-ui-calc-*` with hashes, no secrets
