# Maintenance v1.3.53 — Supervisor v1.8.12 worker-native fail-closed

**Status:** Runner INSTALLED on HESS-PC. Support `2026-09-08T14:36:36-06:00` hashes `kevin-maintenance-runner.ps1` as `EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50` with `ALREADY_APPLIED_PROVEN` for `grok-install-maint-v1353-20260908-2035`. Supervisor v1.8.11 remains the installed identity and still publishes `CONTROLLER_ERROR`. This file is the typed crossing for Supervisor v1.8.12. Controller install is queued as `install_autonomy_controller_v1812` / `grok-install-v1812-20260908-2050`. Queueing is not installation. Not an owner outcome.  
**Authority delta:** NONE. GREEN-C typed self-improvement through existing rollback/Benchmark gates.  
**Live slot:** `inbox/maintenance/manifest.json` is GREEN `install_autonomy_controller_v1812`. Do not repeat `replace_pinned_component` for the v1.3.53 runner.

## Why this exists

Live continuation `2026-09-08T14:30:27-06:00` publishes `version=1.8.11` `status=CONTROLLER_ERROR` `failure_sha256=5DD94CED…`. Engineering `2026-09-08T14:49:56-06:00` reports `kevin-supervisor-v1` `last_status=error` `consecutive_errors=8`. Support now hashes supervisor `685B34F3…` and runner `EF32D990…`. Benchmark is 30/30. The 8-vehicle WorkInstance is unblocked. Selector v1.2 would select it.

Installed v1.8.11 invokes the worker with `$ErrorActionPreference = 'Stop'` and `& powershell @workerArgs 2>&1`. Worker stderr / `throw` becomes a terminating `NativeCommandError`. The catch publishes `CONTROLLER_ERROR` and rethrows, so OpenClaw charges a scheduler error instead of a fail-closed invocation receipt.

v1.8.10 could not invoke a PROVEN skill. v1.8.11 can route to the worker, then crashes the parent. v1.8.12 is the smallest parent wrap: same worker pin, Continue + try/catch around the worker invoke, map failure to `BLOCKED_INVOCATION_RUNTIME`, return without throw.

Do not fake success. A fail-closed receipt is the next diagnostic, not PASS.

## Pins (LF Git blobs / Windows Get-FileHash)

| Identity | SHA-256 |
|---|---|
| Installed Maintenance v1.3.53 | `EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50` |
| Predecessor Maintenance v1.3.52 | `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24` |
| Supervisor installed (v1.8.11, predecessor) | `685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79` |
| Supervisor source (v1.8.12, not installed) | `F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB` |
| Selector v1.2 (unchanged) | `52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A` |
| Canonical invocation worker (unchanged) | `16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332` |
| Request builder | `8E1CDB6911A4F087099788C1DAD9E5A425686B63A6FED471E49D9478688ACCF9` |
| Invocation v1 python | `63FA334B85F895894481DF59314326F6F0F4B0785553B8FDD33DFBFC0E88147C` |
| Forge v4.0 baseline (must not change) | `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A` |

## Two-step ladder — current position

1. **Merge v1.3.53 + v1.8.12 source to `main`.** DONE (PR 163). Not installation.
2. **Queue `replace_pinned_component` / `target_alias=maintenance_runner` for v1.3.53.** DONE. Support hash `EF32D990…` and typed `ALREADY_APPLIED_PROVEN` exist.
3. **Queue `install_autonomy_controller_v1812`.** THIS TURN. Wait Support supervisor hash `F17F4B0A…`, continuation `version=1.8.12`, typed `ALREADY_APPLIED_PROVEN` / "Supervisor v1.8.12 worker-native fail-closed applied/verified.", Benchmark 30/30.
4. **Then** first fail-closed or routed receipt on `owner-west-motor-parts-chase-fresh-8-v1`. `BLOCKED_INVOCATION_RUNTIME` with `INVOCATION_WORKER_FAILED` is diagnostic, not PASS. `ROUTED_TO_PROVEN_SKILL_INVOCATION` is a routing receipt, not PASS.
5. **PASS** still requires a real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt.

Do not skip a rung. Install fetches from `main`.

## What v1.8.12 changes

- Worker invoke uses `$ErrorActionPreference = 'Continue'` (same pattern as `Invoke-Selector`).
- Native / throw failures map to `BLOCKED_INVOCATION_RUNTIME` `reason=INVOCATION_WORKER_FAILED` `turn_charged=false` and **return** (do not rethrow).
- Unexpected non-worker failures still publish `CONTROLLER_ERROR` and throw.
- Worker pin, selector pin, builder pin, invoker pin, desktop exact-five, and the invocation v1 allowlist (`west-motor-parts-chase-board-pack@1` only) are unchanged.

## WorkInstance hold — still released

`owner-west-motor-parts-chase-fresh-8-v1` stays OPEN/GREEN `blocked=false` with the existing 1 burned turn. Do not reset history. Do not send it to tool-less `fixed:main`.

## Not this source write

- No Engineering Relay verb invention.
- No Skill Lab replay of `west-motor-parts-chase-board-pack@1`.
- No history/budget reset.
- No claim that this GitHub source is HESS-PC installation or an owner outcome.
- No send of this WorkInstance to tool-less `fixed:main`.
- No worker-allowlist widening past `west-motor-parts-chase-board-pack@1` until the first fresh invocation is independently proven.
- No repeat of the v1.3.53 runner `replace_pinned_component`.
