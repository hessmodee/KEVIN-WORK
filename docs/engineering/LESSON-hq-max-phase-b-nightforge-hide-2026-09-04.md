# LESSON — Night Forge Disabled must not paint READY (2026-09-04)

## What happened
KevinNightForge was Disabled (P0.7 disable-first) but HQ Ops still showed Night Forge **READY** whenever `active_workers.night_forge=0`. Idle-enabled and Disabled were indistinguishable.

## Lesson
1. **Worker count 0 ≠ armed/ready** when the scheduled task itself is Disabled.
2. Publish scrubbed `public_truth.night_forge_task_state` from the **fixed** task name only; HQ hides the chip when Disabled/Absent.
3. Keep Phase B UI/publisher separate from exact task retirement (still observe, then exact remove under Production Crossing).

## Evidence
- Live task State=Disabled (HESS-PC).
- PLAN: `docs/engineering/PLAN-hq-max-phase-b-nightforge-hide-2026-09-04.md`
- Helper selftest emits `night_forge_task_state=Disabled`.

## Transfer
Next engineer: confirm Pages after merge shows no Night Forge READY; continue P0.7 observe window before exact remove. Do not widen Desktop tools.
