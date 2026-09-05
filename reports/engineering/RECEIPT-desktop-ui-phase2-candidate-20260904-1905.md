# RECEIPT — Desktop UI Phase 2 candidate (disabled-by-default) — 2026-09-04

**Result:** PHASE2_CANDIDATE_AUTHORED — **STILL NOT LIVE**
**When:** ~19:05 MT (America/Denver)
**Candidate:** `candidates/desktop/kevin-desktop-ui-v0/`
**Crossing:** `docs/engineering/KEVIN-DESKTOP-UI-CALC-CROSSING-CONTRACT-2026-09-04.md`

## What landed
- Ported PowerShell UIA prove into plugin-shaped `module/ui_control.py` with **refuse-by-default** (`disabled_by_default` unless `KEVIN_DESKTOP_UI_V0_ENABLE=1`)
- Schema / fixtures / negatives / E2E outline / audit / rollback under candidate
- Scratch Phase 1 PASS retained (`KEVIN_DESKTOP_UI_CALC_V0_OK`)
- Aging-inv@1 teach-and-transfer CLOSED (already PROVEN)

## Explicit non-mutations
- `openclaw.json` **not** touched
- Chat `tools.allow` / `alsoAllow` **not** widened (`kevin_ui_*` not added)
- Chat 18789 / Reader 19001 not killed
- No purchases; no GROK-HANDOVER

## Next
Phase 3 typed Chat crossing packet only after full YELLOW proof bar + Benchmark.
