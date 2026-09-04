# STATUS — P0.3 Mission Leases + Checkpoints (2026-09-04)

**Result:** PASS (source/CI proof) — PLAN for live wiring
**Authority:** NONE in this packet — no Desktop install, no Supervisor replace (avoid race with apply workers)
**Yellow installs:** owner-authorized, but deferred for live wiring so this change cannot collide with concurrent Desktop/Superv apply
**Branch intent:** `grok/p03-leases-checkpoints-20260904`

## Done

- Design contract landed.
- Deterministic lease/checkpoint/orphan/resume library + tests + CI workflow.
- Permanent LESSON taught.
- P0.5 confirmed already on main; not duplicated.
- P0.2 PR #74 not duplicated.

## Not done (residual)

- Live executor heartbeat wiring (YELLOW crossing after apply-race window).
- Optional HQ lease truth consumption.
- P0.1 remains HOLD for Desktop.
