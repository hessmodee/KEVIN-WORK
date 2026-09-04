# LESSON — Mission leases + checkpoints (2026-09-04)

## What broke / what was missing

Long-running Kevin work had no first-class lease or checkpoint primitive. WORKING could be inferred from schedules, stale task strings, or a held lock without evidence. Overnight restarts could not resume safely, and orphaned holders could look busy forever.

## Permanent rule

1. **WORKING = live lease + evidence-producing heartbeat.** Lease alone is `LEASE_WITHOUT_EVIDENCE`, never owner WORKING.
2. **Checkpoints are append-only under an active lease.** Resume after death requires orphan recovery + new lease + latest checkpoint.
3. **Orphan recovery is fail-closed.** Expired, stale-heartbeat, or evidence-less leases become `ORPHANED` → `NOT_WORKING`.
4. **No silent production install racing Desktop/Superv apply.** Library/CI first; live wiring is a separate YELLOW crossing that must not touch the same config files concurrent apply workers mutate.
5. Draft PR #12 is a different checkpoint-envelope candidate — do not confuse it with this mission-lease contract.
6. P0.5 Skill Lab Command counting is already on `main` (`cb718f586`); do not re-implement it inside lease work.

## Proof

- `python control-plane/autonomy/kevin-mission-lease-v1.py --selftest`
- `python tools/test-kevin-mission-lease-v1.py`
- Design: `docs/engineering/KEVIN-MISSION-LEASES-CHECKPOINTS-v1.md`
