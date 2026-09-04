# LESSON — Budget-unlock identity-key + Forge M1 LARGE apply (2026-09-04)

**When:** 2026-09-04 ~09:42 MT  
**Auth:** OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04 (yellow; no per-step ask)

## What
1. **Budget-unlock** is not a fingerprint wipe. Author Superv so `Get-ItemFingerprint` uses identity fields only (`id,program,lane,status,authority_class,failure_family,acceptance_criteria,dependencies_ready,blocked,failure_attempts`). Annotation prose (`next_action`,`completion_evidence`) and bare `material_new_evidence` must NOT reset turns.
2. **Forge M1** retires live migrate/repair ops with immediate `retired_vs_live_v189` throws (no disk write), dual-accepts cron names, and retargets `Ensure-AutonomyContinuationAutomation` to live Superv + selector v1.2.
3. After Superv mutate, **refresh Benchmark baseline + desired-state pins** or Benchmark fails critical regression on hash drift.
4. Preflight `-Apply` refuse scripts are NOT the LARGE packages — author real apply scripts under `control-plane/staging/` with TOCTOU, backup, SelfTest, receipts.

## Do / Don't
| Do | Don't |
|----|-------|
| Backup under `reports/maintenance/backups/` | Wipe continuation fingerprints to "unlock" |
| SelfTest + fixtures 7/7 before mutate | Touch openclaw.json / Desktop Chat tools |
| Pin refresh after hash-changing apply | Expand `$vars` inside `@"..."@` when inserting PS source |
| Teach-and-transfer packages + receipts | Claim Forge COMPLETE from M1 alone |

## Evidence
- `RECEIPT-budget-unlock-identity-key-apply-20260904-093429.json` (Superv → D131003E…)
- `RECEIPT-forge-m1-maintenance-retire-apply-20260904-093732.json` (Maint → 715E40DF… v1.3.49)
- Benchmark PASS 30/30 after pin refresh
