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

Do not trust a single root JSON property name. The repair must:

- call only the fixed `cron get --declaration-key kevin-maintenance-intake-v1 --json` query;
- parse the response as JSON;
- accept only an enabled job whose identity is independently tied to the fixed declaration key using a bounded set of documented/observed response shapes;
- if the `get` shape is ambiguous, corroborate against fixed `cron list --json` and require exactly one matching enabled declaration;
- fail closed on zero matches, multiple matches, malformed JSON, missing enabled state, or contradictory identities;
- perform only the already-qualified fixed disable/enable reset for that same declaration key;
- verify the post-reset job is enabled and its error/backoff state is cleared before calling the operation successful.

There must be no caller-selected job ID, cron key, command, executable, path, arguments, or shell string.

### R2 — UI watchdog staged self-test filename

The generated watchdog candidate remains hash-pinned to the exact reviewed UI Bridge identity and fixed scheduled-task name. Change only the staging filename so the temporary script ends in `.ps1` before invoking the existing bounded `powershell.exe -File ... -SelfTest` runner.

The production target, bridge hash invariant, heartbeat verification, Benchmark postcondition, rollback and task-name restrictions remain unchanged.

## Qualification gate

Before any production crossing:

1. deterministic source transformation proves each intended anchor occurs exactly once;
2. Windows PowerShell parses the generated v1.3.46 candidate;
3. staged watchdog `-SelfTest` is exercised using a `.ps1` candidate path;
4. cron response-shape fixtures cover root-object, nested/list, missing identity, duplicate identity, disabled job and malformed JSON cases;
5. negative source scan rejects `Invoke-Expression`, caller-selected commands/paths, arbitrary shell, authority expansion and relaxed Benchmark/postcondition checks;
6. exact generated SHA256 is recorded;
7. HESS-PC installed Maintenance source identity is separately qualified. The currently reported installed SHA256 is `AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D`, which is not assumed to equal repository v1.3.45 bytes;
8. production installation, if later authorized by the existing GREEN typed contract, must use exact-current compare-and-swap, backup, rollback, self-test and fresh Benchmark 30/30 critical0.

## Proof boundary

This document does **not** claim the repair is CI-PROVEN, installed, OMEN-proven or self-reliant. It records the smallest evidence-driven repair contract so the next engineering step cannot silently widen Kevin's authority or retry the disproven implementation unchanged.
