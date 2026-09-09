# Maintenance v1.3.55 — Invocation worker v1.1 promotion

**Status:** SOURCE ONLY. Do **not** install this runner and do **not** queue `install_invocation_worker_v11` while live slot `grok-install-v1812-20260908-2050` remains (`expires_at=2026-09-09T22:00:00Z`). GitHub `ControlPlane/kevin-proven-skill-invoke-worker-v1.ps1` stays pin `16C49542…`. Not an owner outcome. Not HESS-PC apply.

**Authority delta:** NONE. GREEN-C typed self-improvement through existing rollback/Benchmark gates.

**Parent:** exact Maintenance v1.3.53 (`EF32D990…`). Not v1.3.54. Do not install v1.3.54 for this worker family.

## Why this exists

Supervisor v1.8.12 is independently proven (`F17F4B0A…` + typed `ALREADY_APPLIED_PROVEN`). Continuation publishes `BLOCKED_INVOCATION_RUNTIME` on `owner-west-motor-parts-chase-fresh-8-v1` with `failure_sha256=68845506…`. That hash is set on the worker-ran-or-threw path (`INVOCATION_WORKER_FAILED`), not on the missing-worker path.

Live ControlPlane worker v1 uses `$ErrorActionPreference='Stop'` plus native `& $py`. Python stderr becomes a terminating `NativeCommandError` even when the process exit code is 0. Source wrap `control-plane/autonomy/kevin-proven-skill-invoke-worker-v1.1.ps1` already exists on `main`: Continue + `ProcessStartInfo` `CreateNoWindow`. Supervisor v1.8.12 does **not** hash-check the worker at invoke time, so the ControlPlane filename can be replaced after the v1812 slot expires without recopying Supervisor.

v1.3.53 `install_autonomy_controller_v1812` still fetches and requires live worker `16C49542…`. Promoting the worker while that slot is live would make the next v1812 tick throw `invocation worker target contains unexpected identity`. That is why this pack is source-only until expiry.

## Pins (LF Git blobs / Windows Get-FileHash)

| Identity | SHA-256 |
|---|---|
| Parent Maintenance v1.3.53 (installed) | `EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50` |
| Maintenance v1.3.55 (this source, not installed) | `3E11C429D4540DBD5C4F6F7AD60AA1729D2C0A78D7DA209E76F196654589C261` |
| Supervisor v1.8.12 (verify only, do not recopy) | `F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB` |
| Live ControlPlane worker v1 (GitHub pin until apply) | `16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332` |
| Worker v1.1 source (autonomy wrap) | `7E1129B7FE2B21C90EED634B7A1A356B55630B56DD700A15A7A8C307AEB827AE` |
| Forge v4.0 baseline (must not change) | `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A` |

## What v1.3.55 adds

- Allowlist `install_invocation_worker_v11` only. Parent v1.3.53 still owns `install_autonomy_controller_v1812` and `replace_pinned_component`.
- Fetch allowlist is `control-plane/autonomy/kevin-proven-skill-invoke-worker-v1.1.ps1` plus parent/manifest paths. `?ref=main` only.
- Copy those bytes onto `ControlPlane/kevin-proven-skill-invoke-worker-v1.ps1` when live hash is `16C49542…`. Expected after: `7E1129B7…`.
- Abort if Supervisor is not `F17F4B0A…`. Do not recopy Supervisor, selector, builder, or invoker.
- First-apply receipt includes `idempotent=$false`. Replay includes `idempotent=$true`. Status via `Get-InstallStatus` (StrictMode-safe).
- Worker-only backup/rollback. Benchmark 30/30 required. History/work-items/mission-leases preserved.
- Exact-five desktop and invocation allowlist stay `west-motor-parts-chase-board-pack@1`.

## Install order — do not skip

1. Keep live `install_autonomy_controller_v1812` / `grok-install-v1812-20260908-2050` until it expires at `2026-09-09T22:00:00Z`. Do not occupy that slot.
2. Merge this source to `main`. That is not installation. GitHub ControlPlane worker stays `16C49542…`.
3. After expiry, queue `replace_pinned_component` / `target_alias=maintenance_runner` for v1.3.55 (`expected_current=EF32D990…`, `expected_after=3E11C429…`). Wait typed `APPLIED_PREAUTHORIZED_PROVEN` / `ALREADY_APPLIED_PROVEN` and Support hash `3E11C429…`.
4. Then queue `install_invocation_worker_v11` (`expected_current=16C49542…`, `expected_after=7E1129B7…`). Wait typed receipt, live ControlPlane worker hash `7E1129B7…`, Supervisor still `F17F4B0A…`, Benchmark 30/30.
5. Resume `owner-west-motor-parts-chase-fresh-8-v1`. Keep the 1 burned 09:31 turn. Do not send to tool-less `fixed:main`.
6. **PASS** still requires a real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt.

Do not skip a rung. Install fetches from `main`.

## Not this source write

- No Engineering Relay verb invention (`run_powershell` remains forbidden).
- No Skill Lab replay of `west-motor-parts-chase-board-pack@1`.
- No history/budget reset.
- No claim that this GitHub source is HESS-PC installation or an owner outcome.
- No send of the 8-vehicle WorkInstance to tool-less `fixed:main`.
- No worker-allowlist widening past `west-motor-parts-chase-board-pack@1`.
- No Supervisor v1.8.12 recopy.
- No Maintenance v1.3.54 install.
- No overwrite of GitHub `ControlPlane/kevin-proven-skill-invoke-worker-v1.ps1`.
