# LESSON — Mission lease live wire into Supervisor + Skill Lab (2026-09-04)

## What landed
- P0.3 library was already CI-proven on PR #76 (`kevin-mission-lease-v1.py`).
- After Desktop apply finished and PRs #74/#75/#76/#77 merged, live wire became safe.
- Wire path: `ControlPlane/Invoke-KevinMissionLease.ps1` → `control-plane/autonomy/kevin-mission-lease-v1.py` store actions.
- Supervisor v1.8.10: recover orphans each cycle; acquire/heartbeat on Skill Lab route / agent turn; release on waiting-budgets; SelfTest runs lease wire.
- Skill Lab: acquire/heartbeat on start/save; release on fail; SelfTest runs lease wire.

## Truth rules (do not re-learn)
1. WORKING = live lease + evidence-producing heartbeat. Lease alone is LEASE_WITHOUT_EVIDENCE.
2. Desktop is LIVE exact-4 on fixed:main (openclaw after SHA256 4126AFE6…). Not owner-gated. Do not widen tools or rewrite Desktop config.
3. After PR #74, Supervisor demand visibility is restored; IDLE_NO_ELIGIBLE_DEMAND is no longer the Skill Lab blocker. Current residual seen: WAITING_ITEM_BUDGETS / MIN_REPEAT.
4. Fail-soft lease calls must not expand authority or block GREEN selection if the bridge is momentarily unavailable — but SelfTest must fail closed if the bridge is missing.
5. Never race openclaw.json / Desktop config while wiring leases.

## Prove commands
```
python control-plane/autonomy/kevin-mission-lease-v1.py --selftest
powershell -File ControlPlane/Invoke-KevinMissionLease.ps1 -Action SelfTest
powershell -File kevin-supervisor.ps1 -SelfTest
powershell -File kevin-skill-lab.ps1 -SelfTest
```

## Rollback
Restore from `reports/engineering/backups/p03-lease-wire-20260904-0946/` (supervisor + skill-lab bak). Lease store is additive under `reports/autonomy-runtime/mission-leases-v1.json`.
