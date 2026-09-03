# Kevin Legacy Night Forge Recurrence — Root Cause and Repair Contract

**Date:** 2026-09-03  
**Authority:** GREEN diagnosis / fixed-task repair design  
**Owner objective:** Stop blocked Forge from continuing to produce work while preserving useful demand-gated Forge for future eligible owner work.

## Root cause

The recurring HQ `Blocked Forge is still producing work` condition is not coming from the current governed Supervisor v1.8.8 selector path alone. Historical HESS-PC proof established a separate Windows Scheduled Task named exactly `KevinNightForge`, with an hourly next-run cadence, whose purpose was the original baseline QA cycle and which publishes `current_task.id=night-forge`, title `Night Forge cycle` while it runs.

That legacy Windows task predates the modern failure-family admission contract. It can therefore wake and execute even when `finish-forge-v40-runtime-convergence` / `forge-demandless-supervisor-bypass` is BLOCKED. Current Support can return `night_forge=0` after the cycle finishes, which makes the incident appear intermittent even though the hourly trigger remains the underlying recurrence source.

The modern desired behavior is different:

- Forge v4 remains installed and available for typed eligible demand.
- A BLOCKED Forge failure family must produce zero Forge/Night Forge execution.
- No legacy hourly QA task may manufacture work independently of current governed demand.

## Repair contract

Add a narrow typed Maintenance operation `retire_legacy_night_forge` with **no caller-selected task name, path, executable, arguments, trigger, or command**.

Fixed target: Windows Scheduled Task `KevinNightForge` only.

Operation requirements:

1. Windows only; task name is hard-coded.
2. Read current task state/settings before mutation and capture enough rollback metadata to restore enabled state if postconditions fail.
3. If the task is currently running, stop only `KevinNightForge` and wait boundedly until it is not Running.
4. Disable (do not delete) only `KevinNightForge`.
5. Read back and require task state `Disabled` and no active run.
6. Do not modify current Forge v4, Supervisor, failure-family registry, Benchmark, permissions, credentials, or any other scheduled task.
7. Require fresh Benchmark PASS 30/30 critical0 after the change.
8. On failure after mutation, restore the prior enabled/disabled state and require Benchmark again.
9. Idempotent when already disabled.
10. Record a sanitized receipt containing only task name, prior/final enabled state, whether a running instance was stopped, Benchmark proof, and authority effect NONE.

## Acceptance / recurrence proof

Technical installation is not enough. Before closing the failure family:

- fresh Support reports `night_forge=0` and `design_forge=0`;
- dashboard has no `night-forge` current task;
- at least two former hourly Night Forge trigger opportunities pass with **zero new Night Forge task_start/evaluation** while the Forge family remains blocked;
- Benchmark remains PASS 30/30 critical0;
- a later explicit typed eligible demand can still use the modern governed Forge path exactly once.

## Kevin learning

Turn the incident into a reusable maintenance lesson:

`detect blocked-family execution -> identify independent legacy admission source -> distinguish worker completion from recurrence removal -> retire only the obsolete admission source -> verify two future trigger windows -> preserve modern capability -> record/replay`

Do not clear the HQ warning merely because the current worker count fell back to zero. The recurrence source is considered repaired only after the independent scheduled trigger is retired and the observation window passes.
