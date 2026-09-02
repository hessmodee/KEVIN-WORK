# Lesson: Supervisor 5m cadence vs Benchmark R14 (2026-09-01)

## What broke
`ensure_autonomy_continuation_automation` kept failing with `benchmark failed exit=1` and rolling cadence back to 3m.

## Cause
`kevin-benchmark-v1.ps1` R14 required `everyMs == 180000` (3m). Qualified plan wants 5m (`300000`). At 5m, R14 failed (non-critical) but status became `FAIL_REGRESSION` (29/30) → exit 1 → Assert-Benchmark30 rejected the ensure.

## Fix Kevin owns
1. R14 now expects `300000` (5m).
2. Governed Supervisor job `af9ced44-…` (`Kevin Supervisor v1.6 High Gear` name preserved) cadence `everyMs=300000`.
3. Supervisor binary is v1.8.8 hash `F5D8C974…`; selector v1.1 `9DF1F770…`.

## Detection
If cadence ensure fails with benchmark exit=1 while critical rows are green, check R14 everyMs expectation vs actual cron.

## Standing auth
Owner standing auth for Chief of Staff Kevin-build: `docs/engineering/OWNER-STANDING-AUTH-CHIEF-OF-STAFF-KEVIN-BUILD-2026-09-01.md`.