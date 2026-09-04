# LESSON — Benchmark R02 supervisor pin refresh after Superv v1.8.10 (2026-09-04)

## Symptom
Benchmark status `FAIL_CRITICAL_REGRESSION` 29/30 critical 1. Failed check R02 (`files`) detail `Supervisor hash=D77BCAA7...`.

## Root cause
R02 compares live `kevin-supervisor.ps1` SHA256 to `reports/benchmark-v1/baseline.json` -> `hashes.supervisor`.
Superv was intentionally upgraded to v1.8.10 (mission-lease heartbeat wire) after a v1.8.9 pin refresh to `7BE40357...`. A later R04 production_config rebaseline for Desktop left baseline.supervisor at stale `D131003E...`, and the v1.8.10 install did not refresh the pin to live `D77BCAA7...`.

## Fix
1. Confirm live Superv hash equals intended install (`D77BCAA7...` for v1.8.10).
2. Backup `baseline.json` and `ControlPlane/desired-state-v1.json`.
3. Set both pins' supervisor hash to the live intentional Superv hash.
4. Do NOT rewrite `openclaw.json` or the supervisor binary as part of the pin refresh.
5. Re-run Benchmark; expect PASS 30/30 critical 0.
6. Publish sanitized receipt under `reports/engineering/RECEIPT-pin-refresh-superv-v1810-*.json`.

## Teach-forward
Any intentional Superv/Forge/config hash change must update baseline + desired-state in the same change set, or Benchmark will correctly fail closed. Pin refresh is evidence acceptance, not a silent binary swap.

## Rollback
Restore backup baseline/desired-state from the receipt `backup_dir`, then re-run Benchmark.
