# kevin-desktop-ui-v0 (SCRATCH ONLY)

Fail-closed typed Calculator UI control via Windows UI Automation (PowerShell).
**Not installed. Not wired to openclaw.json. Not on Chat.**

See: `docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md`

## Prove

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\calc_uia_prove.ps1 -Action prove
python .\refuse.py prove
```

Success marker: `KEVIN_DESKTOP_UI_CALC_V0_OK` (also accepts plan alias `KEVIN_UI_CALC_V0_OK`).

## Fail-closed

- App allowlist: `calculator` only
- Control allowlist: `calculator-catalog.v0.json`
- Secret-deny + max type length 64
- No screen XY; UIA AutomationId under Calculator window only
