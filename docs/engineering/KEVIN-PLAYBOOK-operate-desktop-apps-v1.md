# KEVIN PLAYBOOK — Operate Desktop Apps (launch → UIA) v1

**Updated:** 2026-09-05 ~00:20 MT
**Authority:** UNDYING GREEN+YELLOW. **Never widen live Chat tools.allow without proof bar.**
**Goal:** Kevin opens and operates allowlisted apps honestly — Calculator proven for UIA Phase1; Minecraft client UI is next candidate (OCR path), not Chat-widened.

## 1. Desktop exact-5 (Chat fixed:main — verify live, do not assume)

Live inventory (after list-folder crossing; distrust stale exact-4 / SHA `4126AFE6`):

1. `kevin_system_status`
2. `kevin_desktop_find_folder`
3. `kevin_desktop_open_folder`
4. `kevin_desktop_list_folder`
5. `kevin_app_launch` (allowlist: calculator / notepad / paint / explorer — verify live)

**Hard rule:** Never describe Desktop/app/window/process state without a **same-turn tool result**. Tool fail / overflow → say **FAILED**. Inventing listings or "Calculator opened" with zero tool calls = critical failure.
LESSON: `docs/engineering/LESSON-chat-desktop-tools-vs-hallucination-2026-09-04.md`
LESSON exact-5: `docs/engineering/LESSON-stale-desktop-exact4-turnover-vs-exact5-2026-09-04.md`
Neg: `docs/engineering/evals/NEG-hallucinated-desktop-success-v1.json`

## 2. Ladder: launch → operate

| Rung | Capability | Surface today | Widen? |
| --- | --- | --- | --- |
| 0 | Status / honest idle | `kevin_system_status` | Live |
| 1 | Find / open / list Desktop folders | exact-5 Desktop tools | Live |
| 2 | Launch allowlisted app | `kevin_app_launch` | Live (frozen allowlist) |
| 3 | Focus / click / type inside app (UIA) | Phase2 **candidate** — Calculator proven in scratch (`KEVIN_DESKTOP_UI_CALC_V0_OK`); refuse-by-default extension + vitest | **NOT** Chat-widened |
| 4 | Non-UIA apps (e.g. Minecraft Bedrock) | Client UI OCR + input scripts | Scratch / prove only |
| 5 | Generic CUA / screen-click | Destination later | Forbidden shortcut |

## 3. Desktop UI Phase2 candidate (standing truth)

- Scratch prove: Calculator UIA → `KEVIN_DESKTOP_UI_CALC_V0_OK`
- Candidate: `candidates/desktop/kevin-desktop-ui-v0` → `KEVIN_DESKTOP_UI_PHASE2_REFUSE_OK`
- Disabled ext+vitest: `extensions/kevin-desktop-ui` → `KEVIN_DESKTOP_UI_PHASE2_EXT_VITEST_OK`
- Proposed tools still OFF for Chat: `kevin_ui_focus_app` / `kevin_ui_click` / `kevin_ui_type`
- PLAN: `docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md`
- Crossing contract: `docs/engineering/KEVIN-DESKTOP-UI-CALC-CROSSING-CONTRACT-2026-09-04.md`
- **Do not** merge into live `extensions/kevin-desktop` Chat allowlist without Phase3 packet + proof bar.

## 4. Minecraft as "next app" (not Chat tool)

1. Launch via shell AppsFolder `Microsoft.MinecraftUWP_8wekyb3d8bbwe!Game` (or future typed launch if allowlisted after proof).
2. Bedrock window: **UIA ControlView empty** — do not expect kevin_ui_* to work.
3. Use client-UI recipe: OCR (Windows.Media.Ocr), refuse unit, logical SetCursorPos, Realms menu path.
4. Play identity + etiquette: play-with-Matt playbook.

## 5. Proof bar before any Chat widen

Schema + fixtures + negatives + isolated E2E marker + audit receipt + rollback + Benchmark 30/30 critical 0 + typed crossing packet. Exact tool ids only. No opportunistic extras. No `kevin_shell`. No CUA enable as shortcut.

## 6. Hard nos

- Never widen live Chat tools.allow without proof bar.
- Never kill Chat 18789 / Reader 19001.
- Never invent Desktop contents or app success.
- RED / purchasing / trading / secrets reserved.
