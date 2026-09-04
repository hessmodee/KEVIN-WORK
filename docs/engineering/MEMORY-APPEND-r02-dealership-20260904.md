## Taught 2026-09-04 10:40 MT ΓÇö Benchmark R02 Superv v1.8.10 pin + dealership friction stage

- Symptom: Benchmark FAIL_CRITICAL 29/30 R02 after Superv v1.8.10 lease wire; baseline.supervisor lagged at stale D131003E (R04 desktop rebaseline overwrote prior 7BE40357 pin).
- Fix: pin-refresh baseline + desired-state supervisor to live D77BCAA7; do not rewrite openclaw.json or Superv binary. Benchmark PASS 30/30.
- Teach: intentional hash change must update baseline+desired-state in same change set (LESSON-benchmark-r02-superv-pin-refresh-after-v1810-2026-09-04.md).
- GREEN lane: staged dealership-friction-reducer-pack@1 (skip appliance MIN_REPEAT). Relay reads GitHub inbox/engineering/request.json ΓÇö always remote-publish when staging.
