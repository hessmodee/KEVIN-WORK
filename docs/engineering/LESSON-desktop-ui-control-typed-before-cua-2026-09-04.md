# LESSON — Desktop UI Calculator scratch prove + Phase 2 candidate (2026-09-04)

**Status:** TEACH-AND-TRANSFER (scratch PASS; candidate authored; still NOT live)

## What happened
1. Phase 1 scratch under `scratch/kevin-desktop-ui-v0` used PowerShell `UIAutomationClient` (no pywinauto install) to focus Calculator, click catalog controls, and prove `1+1=` → Display is 2.
2. Marker: `KEVIN_DESKTOP_UI_CALC_V0_OK`. Refuse-unit PASS (invalid_app/control, secret_deny, text_too_long).
3. Phase 2 ported the prove into `candidates/desktop/kevin-desktop-ui-v0` as a **refuse-by-default** plugin-shaped module (`module/ui_control.py` + `calc_uia_prove.ps1`) with schema/fixtures/negatives/E2E outline/audit/rollback.
4. `openclaw.json` untouched. Chat tools.allow untouched. No CUA.

## Teach-forward
1. **Typed allowlist > CUA** on Qwen 2.5 14B for always-on coworker agency.
2. **Refuse-by-default** is mandatory for UI candidates until typed Chat crossing clears the full YELLOW proof bar.
3. **Calculator catalog first** — tiny AutomationId map, clear OS postcondition, no xy.
4. **Exact-N widen only after** schema/fixtures/neg/E2E/audit/rollback + Benchmark. Do not sneak `kevin_ui_*` onto live `kevin-desktop` while frozen.
5. Model text claiming click/type without a tool result remains hallucination (LESSON-chat-desktop-tools-vs-hallucination).

## Evidence
- PLAN: `docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md`
- Crossing: `docs/engineering/KEVIN-DESKTOP-UI-CALC-CROSSING-CONTRACT-2026-09-04.md`
- Scratch receipt: `reports/engineering/RECEIPT-scratch-desktop-ui-calc-v0-20260904-1858.json`
- Candidate: `candidates/desktop/kevin-desktop-ui-v0/`

## Transfer / next
Next engineer: run candidate unit tests + isolated prove with `KEVIN_DESKTOP_UI_V0_ENABLE=1`, then author Phase 3 Chat crossing packet only if proof bar green. Do not apply openclaw.json; do not kill Chat/Reader.
