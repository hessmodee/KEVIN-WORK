# RECEIPT — scratch Calculator UIA prove v0 — 2026-09-04

**Result:** PASS
**Marker:** `KEVIN_DESKTOP_UI_CALC_V0_OK`
**When:** ~18:58 MT (America/Denver)
**Scratch:** `scratch/kevin-desktop-ui-v0/`
**Plan:** `docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md`

## What ran
- Fail-closed refuse unit: invalid_app, invalid_control, secret_deny, text_too_long — all PASS
- Live UIA: launch/focus Calculator → clear → click `1` `+` `1` `=` → read `Display is 2`
- Stack: PowerShell `UIAutomationClient` + catalog AutomationId map (no pywinauto install required)
- `openclaw.json` untouched; no live Desktop/Chat allowlist widen; Chat 18789 / Reader 19001 not touched

## Evidence
- `scratch/kevin-desktop-ui-v0/PROVE-OUT-20260904.json`
- `reports/engineering/RECEIPT-scratch-desktop-ui-calc-v0-20260904-1858.json`

## Residuals / next
- Phase 2: port to `extensions/kevin-desktop` (or `kevin-desktop-ui`) disabled-by-default
- Full YELLOW proof bar still required before any Chat typed crossing
- No CUA enable; no `kevin_shell`; Calculator allowlist only until catalog expands under proof

## Aging-inv Skill Lab (quick check)
- `west-motor-aging-inventory-action-pack@1` **STAGED** (PR #94 merged; Relay `grok-stage-wm-aging-inv-v1-20260904182600`; SHA `29CB300C...`)
- Standing note: leave Skill Lab alone to prove; teach-and-transfer closeout after PROVEN
