# Kevin Maintenance v1.3.46 — fail-closed repair design

**Date:** 2026-09-03  
**Authority:** GREEN engineering / production effect NONE  
**Status:** DESIGN ONLY — not installed

## Evidence forcing this repair

Two independent typed GREEN maintenance operations failed closed while Benchmark remained healthy:

1. `reconcile_maintenance_cron_backoff` failed because the implementation assumes `openclaw cron get --declaration-key kevin-maintenance-intake-v1 --json` returns a root property named `declarationKey`. Installed OpenClaw evidence shows that assumption is not stable.
2. `ensure_ui_bridge_watchdog` reached its generated watchdog staging step and failed its staged PowerShell self-test. The generator writes the temporary candidate without a `.ps1` suffix even though the bounded runner invokes `powershell.exe -File` against it.

The failed watchdog manifest has been retired so the intake cannot keep retrying an unchanged failed hypothesis.

## Candidate contract

Build a v1.3.46 candidate from the reviewed repository v1.3.45 source with exactly two behavioral changes and no authority change.

### R1 — cron reconciliation identity verification

Keep the declaration key fixed in source: `kevin-maintenance-intake-v1`.

Do not trust a single root JSON property name. The repair must call only the fixed cron declaration, verify exactly one enabled match across bounded documented response shapes, fail closed on ambiguity or malformed state, perform only the existing fixed disable/enable reset, and verify the post-reset job is enabled with cleared error/backoff state. There must be no caller-selected job ID, cron key, command, executable, path, arguments, or shell string.

### R2 — UI watchdog staged self-test filename

The generated watchdog remains hash-pinned to the reviewed UI Bridge identity and fixed scheduled-task name. Change only the staging filename so the temporary script ends in `.ps1` before the existing bounded `powershell.exe -File ... -SelfTest` runner. Preserve the production target, bridge hash invariant, heartbeat verification, Benchmark postcondition, rollback and task-name restrictions.

## Qualification gate

Before any production crossing:

1. deterministic source transformation proves each intended anchor occurs exactly once;
2. Windows PowerShell parses the generated candidate;
3. staged watchdog `-SelfTest` is exercised using a `.ps1` candidate path;
4. cron response-shape fixtures cover valid, missing, duplicate, disabled and malformed cases;
5. negative scans reject arbitrary shell/paths/commands and authority expansion;
6. exact generated SHA256 is recorded;
7. HESS-PC installed Maintenance identity is separately qualified. Current Support reports `AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D`, which is not assumed to equal repository v1.3.45 bytes;
8. later production installation must use exact-current compare-and-swap, backup, rollback, self-test and fresh Benchmark 30/30 critical0.

## Proof boundary

This document does **not** claim CI-PROVEN, installed, OMEN-proven or self-reliant status. It records the smallest evidence-driven repair contract so the disproven implementation is not retried unchanged.
