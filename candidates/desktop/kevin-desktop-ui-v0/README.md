# kevin-desktop-ui-v0 — DISABLED-BY-DEFAULT plugin candidate

**Status:** PHASE 2 CANDIDATE ONLY — **NOT LIVE**
**Authority delta:** NONE
**Auth:** UNDYING GREEN+YELLOW `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
**PLAN:** `docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md`
**Crossing contract:** `docs/engineering/KEVIN-DESKTOP-UI-CALC-CROSSING-CONTRACT-2026-09-04.md`

## Hard guarantees

- **Refuse-by-default.** All UI actions return `disabled_by_default` unless explicit enable for isolated prove harness (`KEVIN_DESKTOP_UI_V0_ENABLE=1`).
- **Not registered** in live `openclaw.json`.
- **Not** on Chat `tools.allow` / `alsoAllow`.
- Calculator catalog only (digits, + - * / =, clear). No xy click. No `kevin_shell`. No CUA.
- Do not kill Chat 18789 / Reader 19001. No purchases. No GROK-HANDOVER.

## Layout

| Path | Role |
|---|---|
| `module/ui_control.py` | Plugin-shaped API (focus/click/type/read/prove) with refuse gate |
| `module/refuse.py` | Unit denies without UIA |
| `calc_uia_prove.ps1` | Ported PowerShell UIA prove (scratch → candidate) |
| `calculator-catalog.v0.json` | Allowlisted controls |
| `schemas/kevin_ui_tools.v0.schema.json` | Tool arg schemas (`additionalProperties: false`) |
| `fixtures/` | Catalog + deny fixtures |
| `tests/` | Refuse-default + negatives + catalog |
| `docs/E2E-OUTLINE.md` | Isolated E2E (not Chat) |
| `docs/AUDIT.md` | Audit receipt shape |
| `docs/ROLLBACK.md` | Rollback (no live config yet = delete/revert) |
| `openclaw.plugin.json.candidate` | Manifest **candidate only** — do not install |

## Prove (isolated)

```powershell
$env:KEVIN_DESKTOP_UI_V0_ENABLE = '1'
py -3 -m module.ui_control prove
py -3 -m module.refuse
Remove-Item Env:KEVIN_DESKTOP_UI_V0_ENABLE
```

Success marker: `KEVIN_DESKTOP_UI_CALC_V0_OK` (plan alias `KEVIN_UI_CALC_V0_OK` accepted).

Default (no enable env):

```powershell
py -3 -m module.ui_control focus
# -> {"ok": false, "error": "disabled_by_default", ...}
```

## Next (NOT this PR)

Phase 3 typed Chat crossing only after full YELLOW proof bar: schema/fixtures/neg/E2E/audit/rollback + Benchmark 30/30 critical 0 + exact-N packet. Future home may be `extensions/kevin-desktop-ui` still disabled until crossing.
