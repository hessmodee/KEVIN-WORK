# Kevin Mission Leases + Checkpoints v1

Date: 2026-09-04
Status: GREEN/YELLOW source contract (CI-proven library; live Supervisor/Skill Lab/Desktop wiring is a separate crossing and must not race apply workers)
Authority effect: NONE
Related history: Draft PR #12 (`kevin-checkpoint-resume-v0.1`) is a different candidate envelope (worker-slot budgets). This P0.3 contract is the mission-lease + truthful-WORKING primitive; do not merge or confuse the two.

## Problem

Overnight/long work must survive restarts without fake busy status.

HQ/control can claim WORKING from stale task strings, schedules, or model turns. P0.5 already requires Skill Lab counts in global Command truth (landed on main). P0.3 adds the execution primitive:

> **WORKING** requires a **live lease** plus **evidence-producing execution**.

Long jobs also need checkpoint/resume and orphan recovery so real work continues after process death without inventing activity.

## Contract

### Lease

Exclusive per `mission_id`:

| Field | Rule |
|---|---|
| `holder` | Lane/worker that owns execution (`skill-lab`, `supervisor`, ...) |
| `state` | `ACTIVE` / `RELEASED` / `EXPIRED` / `ORPHANED` |
| `ttl_seconds` | Hard expiry; default 900s |
| `heartbeat_at` | Must advance with evidence |
| `evidence_uri` | Path/URI to fresh evidence artifact |
| `evidence_producing` | True only when evidence_uri present |

Exclusive: another holder cannot acquire while ACTIVE and unexpired. Same holder may renew.

### Checkpoint

Append-only per mission:

| Field | Rule |
|---|---|
| `seq` | Monotonic |
| `stage` | `ACQUIRED` / `PLAN` / `EXECUTE` / `VERIFY` / `RECORD` / `COMPLETE` / `ABORT` only |
| `payload_digest` | SHA256-16 of payload; identical tip stage+digest = idempotent replay |
| `resume_hint` | Human/machine next step |
| Active lease | Required to save |

### Orphan recovery

ACTIVE leases become `ORPHANED` when any of:

1. `expires_at <= now`
2. heartbeat older than `stale_heartbeat_seconds`
3. no evidence within 60s of acquire (anti fake-busy)

Orphaned missions are **NOT_WORKING**. Resume requires a **new lease** + existing checkpoint.

### Truth vocabulary

| State | Meaning |
|---|---|
| `WORKING` | ACTIVE unexpired lease **and** evidence_producing |
| `LEASE_WITHOUT_EVIDENCE` | Lease held but no evidence — **not** owner WORKING |
| `NOT_WORKING` | No live evidence-backed lease |

Schedule ticks, animations, and model turns alone never equal WORKING.

## Components

- `control-plane/autonomy/kevin-mission-lease-v1.py`
- `tools/test-kevin-mission-lease-v1.py`
- CI: `.github/workflows/autonomy-mission-lease-v1-proof.yml`
- Teach: `docs/engineering/LESSON-mission-leases-checkpoints-2026-09-04.md`

## Non-goals / race avoidance (this packet)

- Do **not** install Desktop in this packet.
- Do **not** replace live Supervisor binaries/config while Desktop/Superv apply workers may be racing the same files.
- Do **not** auto-wire HQ production paths here beyond design (P0.5 Skill Lab Command counts already on main).
- Do **not** grant authority, shell, or network.

Yellow installs are owner-authorized for later bounded crossings, but this PR stays library/CI/teach only so it cannot collide with concurrent apply workers.

## Success criteria

1. Selftest + tools test PASS offline/CI.
2. WORKING impossible without evidence-backed live lease.
3. Orphan scan clears stale leases to NOT_WORKING.
4. Checkpoint resume plan survives restart and requires new lease.
5. Permanent teach/lesson committed so next engineer does not re-learn.
