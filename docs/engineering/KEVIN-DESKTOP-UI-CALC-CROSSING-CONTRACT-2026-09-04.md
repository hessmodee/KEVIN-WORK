# Kevin Desktop UI — Calculator typed crossing contract (Phase 2 candidate)

**Date:** 2026-09-04
**Authority:** YELLOW qualification / production effect **NONE**
**Status:** CANDIDATE CONTRACT — **NOT INSTALLED** — refuse-by-default
**Auth:** UNDYING GREEN+YELLOW `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
**PLAN:** `docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md`
**Candidate:** `candidates/desktop/kevin-desktop-ui-v0/`
**Scratch prove:** PASS `KEVIN_DESKTOP_UI_CALC_V0_OK` (`scratch/kevin-desktop-ui-v0/`, RECEIPT-scratch-desktop-ui-calc-v0-20260904-1858)

## Scope (exact proposed tool ids — not live)

1. `kevin_ui_focus_app` — app enum: `calculator` only
2. `kevin_ui_click` — app + `control_id` from Calculator catalog v0
3. `kevin_ui_type` — app + text (max 64, secret-deny, expression chars via catalog clicks)

Optional later (out of scope tonight): `kevin_ui_read`.

**Do not** add these to Chat `tools.allow` / `alsoAllow` until Phase 3 packet clears full proof bar.

Live Desktop inventory remains exact-N (status + find/open/list + app_launch). This contract does **not** authorize widening that set.

## Fail-closed

- Refuse-by-default module gate (`KEVIN_DESKTOP_UI_V0_ENABLE` unset → `disabled_by_default`)
- Allowlist app: `calculator` only
- Allowlist controls: `calculator-catalog.v0.json`
- No screen XY; no SendKeys to arbitrary HWND; no `kevin_shell`; no CUA
- Secret-deny + max type length 64
- Process/window bound to Calculator
- Schema `additionalProperties: false`

## Proof bar (YELLOW — required before any Chat widen)

| Gate | Artifact |
|---|---|
| Schema | `candidates/desktop/kevin-desktop-ui-v0/schemas/kevin_ui_tools.v0.schema.json` |
| Fixtures | `candidates/desktop/kevin-desktop-ui-v0/fixtures/*` |
| Negatives | `tests/test_refuse_default.py` + fixtures (invalid app/control, secret, xy extra props) |
| E2E isolated | `docs/E2E-OUTLINE.md` — marker `KEVIN_DESKTOP_UI_CALC_V0_OK` (not Chat) |
| Audit | `docs/AUDIT.md` receipt shape |
| Rollback | `docs/ROLLBACK.md` (today: git revert; no openclaw mutate) |
| Crossing apply | **FORBIDDEN tonight** — separate Phase 3 packet after Benchmark + canaries |

## Protected denies that must remain

Existing global denies for shell/process/write/edit/web/skill-workshop remain. Crossing must not add arbitrary mouse/keyboard, caller-selected exe/path/argv, or Non-Calculator apps.

## Exact-current qualification before any future mutation

A future live wrapper must fail closed unless:

- active OpenClaw config SHA256 equals expected-current
- plugin registration fields identified for a **new** `kevin-desktop-ui` plugin (do not silently widen `kevin-desktop` live tools)
- fixed:main before inventory equals current exact-N Desktop set
- Benchmark PASS 30/30 critical 0
- exact-byte backup of openclaw.json
- semantic diff only predeclared plugin/tool-policy leaves
- positive Calculator E2E + forbidden negatives
- rollback tested

## Proof boundary

This document qualifies a **disabled-by-default candidate**. It does **not** claim Chat visibility, OMEN Chat tool_call proof, or responsibility transfer for UI control.
