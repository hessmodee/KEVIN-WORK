# PLAN - Kevin Desktop UI control (typed click/type/focus) — 2026-09-04

Date: 2026-09-04 ~18:45 MT (America/Denver)
Author: Grok Bot (HESS-PC inventory + north-star)
Audience: Matt / Davy / Kevin / Cursor agents
Auth: UNDYING GREEN+YELLOW `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
North-star: `docs/engineering/PLAN-kevin-north-star-max-2026-09-04.md` (P0/P1 computer agency — typed tools before CUA)
Charter: `docs/engineering/KEVIN-SUPER-AI-NORTH-STAR-CHARTER-v1.md`
Teach-and-transfer: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`
Crossing contract: `docs/engineering/KEVIN-DESKTOP-TYPED-CROSSING-CONTRACT-2026-09-03.md`
Handover: `AI-HANDOVER.md` only (no GROK-HANDOVER). Execution: `inbox/CURRENT_TASK.md`.

## 0. Intent

Give Kevin **typed, fail-closed UI control** inside **allowlisted apps only** (prove Calculator first): focus window, click named controls, type bounded text — **not** generic mouse/keyboard/CUA, **not** a live Desktop allowlist widen tonight.

Owner value: Matt can ask Kevin to drive Calculator (and later Notepad) with real OS postconditions, without inventing success and without `kevin_shell`.

## 1. North-star alignment

- Peer lesson (north-star §1.2): **scoped typed effectors beat unattended OS agents** on always-on coworkers.
- OpenClaw CUA / screenshot-click = destination / later YELLOW — Qwen 2.5 14B is not a reliable CUA driver; enabling CUA would widen Chat tools. **Prefer typed tools.**
- Live surface today: Desktop exact-N (find/open/list + `kevin_app_launch` allowlist notepad/calculator/paint/explorer). **Do not break Chat 18789 / Reader 19001. Do not widen live allowlist without full proof bar.**
- This PLAN is **docs + optional scratch stub only**. No `openclaw.json` apply. No live plugin install from this beat.

## 2. Inventory (HESS-PC 2026-09-04)

- Plugin: `extensions/kevin-desktop` (`desktop.ts`) — launch/find/open/list only. **No click/type/focus tools yet.**
- Live Chat tools: Desktop exact inventory (status + find/open/list + app_launch). Frozen except via typed crossing contract + proof bar.
- Proven adjacent: Green Operator `ui_notepad_write` (Skill Lab / Action Era UI Bridge) — **different surface**, not Chat fixed:main.
- Calculator launch via `kevin_app_launch` already OS-proven (Chat honesty receipt). Focus/click/type inside Calculator = **new faculty**.

## 3. Proposed typed tools (v0 design — not installed)

| Tool id (proposed) | Args (typed) | Effect | Deny |
|---|---|---|---|
| `kevin_ui_focus_app` | `app`: enum allowlist starting with `calculator` | Foreground the allowlisted app window if running (or after launch) | Arbitrary titles, PID caller-select, other processes |
| `kevin_ui_click` | `app` + `control_id` (fixed catalog per app) OR `role`+`name` from allowlisted automation tree | Single click on resolved control inside that app only | Screen xy click, cross-app, drag, double-click spam |
| `kevin_ui_type` | `app` + `text` (length-capped) + optional `control_id` | Type into focused allowlisted control | Secrets patterns, paste from clipboard monitor, unbounded length |
| `kevin_ui_read` (optional later) | `app` + `control_id` | Return scrubbed control name/value metadata only | Full UI tree dump, OCR screenshot blob as authority |

**Prove-first app:** Windows Calculator (`calculator` / `CalculatorApp`). Catalog v0: digit buttons 0-9, operators `+ - * / =`, `clear`. No Store URI launches beyond existing `kevin_app_launch`.

**Secret-deny:** refuse if `text` matches credential-like patterns (reuse list_folder secret-deny spirit); never log raw typed secrets into HQ/MEMORY; receipts hash length + allowlist id only.

## 4. Fail-closed contract

1. **Allowlist-only apps** — code-owned enum; caller string outside enum → `invalid_app`.
2. **Allowlist-only controls** — code-owned catalog per app; unknown control → `invalid_control`.
3. **No generic input** — no absolute screen coordinates as primary API; no SendKeys to arbitrary HWND; no `kevin_shell`.
4. **Platform gate** — Windows only; unsupported → `unsupported_platform`.
5. **Process bound** — resolve target HWND/automation element under the allowlisted process; refuse if focus would leave the app.
6. **Rate / length caps** — max text length (e.g. 64 for Calculator prove); max actions per turn (documented).
7. **Secret-deny** — credential-like text rejected; no clipboard exfil tool.
8. **Absent proof ≠ success** — model text claiming click/type without tool result is hallucination (NEG eval).

## 5. Proof bar (YELLOW — required before any Chat widen)

Exact-N widen of fixed:main tools is **forbidden** until **all** of:

| Gate | Requirement |
|---|---|
| Schema | JSON schema / plugin manifest for each new tool id; `additionalProperties: false` |
| Fixtures | Unit fixtures: Calculator catalog resolve; focus when running; click digit; type refused when over length |
| Negatives | Deny: non-allowlisted app, xy click, cmd/PowerShell, cross-app focus, secret-like text, unknown control, symlink/host escape |
| E2E isolated | Isolated plugin harness (not Chat): launch Calculator → focus → click `1` `+` `1` `=` → independent UI/read or process postcondition → marker `KEVIN_UI_CALC_V0_OK` |
| Audit | Receipt with tool ids, allowlist versions, hashes (no secrets), before/after process evidence |
| Rollback | Exact bytes backup of openclaw.json + plugin registration; documented revert; Benchmark 30/30 critical 0 after any crossing |
| Crossing | Separate typed Chat crossing packet (exact new tool ids only) per `KEVIN-DESKTOP-TYPED-CROSSING-CONTRACT` — **not tonight** |

**Exact-N rule:** live allowlist grows only by the **exact** proven tool id set after the packet clears. No opportunistic extras.

## 6. Phased delivery

### Phase 0 — this PR (docs + optional scratch)

- This PLAN + LESSON stub + `inbox/CURRENT_TASK.md` pointer.
- Optional: `scratch/kevin-desktop-ui-v0/` stub **only** (README + empty catalog JSON + refuse-by-default module). **No live openclaw apply.**

### Phase 1 — scratch prove (Calculator)

- Implement UI Automation (Windows UIA) or WinAppDriver-free typed wrapper under scratch.
- Isolated tests + `KEVIN_UI_CALC_V0_OK`.
- Recipe: `docs/engineering/KEVIN-RECIPE-desktop-ui-calc-v0.md` (later).

### Phase 2 — plugin candidate

- Port into `extensions/kevin-desktop` or `extensions/kevin-desktop-ui` as disabled-by-default tools.
- CI candidate gate; still **not** on fixed:main.

### Phase 3 — typed Chat crossing (YELLOW)

- Owner packet + exact-current qualification + rollback.
- Widen Chat by exact proven tool ids only after E2E + Benchmark + neg canaries.

## 7. Non-goals / hard NOS (tonight and standing)

- Do **not** widen live Desktop / Chat allowlist tonight.
- Do **not** enable OpenClaw CUA / computer.act as a shortcut.
- Do **not** kill Chat 18789 or Reader 19001.
- Do **not** add `kevin_shell`, generic SendInput, or caller-selected exe/path/argv.
- No purchases. No GROK-HANDOVER. Teach-and-transfer only.
- Do not race or rewrite LIVE exact Desktop tools while frozen.

## 8. LESSON stub

See `docs/engineering/LESSON-desktop-ui-control-typed-before-cua-2026-09-04.md`.

## 9. Verify (this docs PR)

- Files exist: PLAN + LESSON stub.
- CURRENT_TASK points at this PLAN.
- Optional scratch path under `scratch/` only if present; must not touch `openclaw.json`.

## 10. Rollback

Revert this branch/PR. Scratch delete is sufficient for optional stub. No production config mutated by Phase 0.

## 11. Status

**READY_FOR_SCRATCH_CALC_PROVE** — design sealed; next eng = Phase 1 Calculator isolated prove under scratch; Chat widen blocked on full proof bar.
