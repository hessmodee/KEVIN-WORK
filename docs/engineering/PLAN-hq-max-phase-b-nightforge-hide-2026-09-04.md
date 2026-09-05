# PLAN — HQ Max Phase B: Night Forge hide when Disabled (2026-09-04)

## Intent
When Windows Scheduled Task `KevinNightForge` is **Disabled**, HQ Ops must **not** show a Night Forge **READY** chip. Disabled ≠ READY. Hide the Night Forge service-rail entry and topology worker; expose scrubbed `public_truth.night_forge_task_state`.

## Boundary
- Phase 0 (#82): HQ shell truth chips + WAITING=blocked.
- Phase A slice1 (#84): `desktop_tool_inventory_count` publisher helper.
- **Phase B (this PR):** Night Forge Disabled hide/truth — Ops UI (`docs/ops/ops-v11.js`) + core service rail (`docs/hq-core-v7.html`) + `workspace/kevin-public-truth-v1.ps1` field.

## Scope
1. `workspace/kevin-public-truth-v1.ps1` — publish `night_forge_task_state` from fixed task name `KevinNightForge` only (`Disabled|Ready|Running|Queued|Absent|Unknown`). Never caller-selected task names.
2. `docs/ops/ops-v11.js` — `workerState('night')` returns `disabled` when Disabled/Absent; rail + topology **hide** Night Forge when hidden; cache bump `ops-v11.js?v=18`.
3. `docs/hq-core-v7.html` — `forgeState()` respects Support `public_truth.night_forge_task_state`; service rail omits chip when hidden; cache bump `hq-core-v7.html?v=13`.
4. `.github/scripts/test-hq-live-data.cjs` — assert Disabled ≠ READY and hide helper.
5. Teach-and-transfer PLAN + LESSON; CURRENT_TASK pointer.

## Non-goals / hard constraints
- No `openclaw.json` / Desktop allowlist / Chat port edits.
- Do not delete/enable KevinNightForge in this PR (P0.7 retirement remains separate).
- Do not kill Chat 18789 / Reader 19001.
- No GROK-HANDOVER. Owl geometry untouched beyond chip hide.

## Verify
- `powershell -File workspace/kevin-public-truth-v1.ps1 -SelfTest` → count=4 and night_forge_task_state in allowlist (HESS-PC expect Disabled).
- `node .github/scripts/test-hq-live-data.cjs`
- `node .github/scripts/test-hq-owner-invariants.cjs`
- Live Support snapshot includes `public_truth.night_forge_task_state` after bridge refresh.

## Rollback
Revert this PR. Restore prior `kevin-public-truth-v1.ps1` (backup `kevin-public-truth-v1.ps1.pre-phase-b-20260904` on HESS-PC). Cache-busters fall back by reverting embed/index.
