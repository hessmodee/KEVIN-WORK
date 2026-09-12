# LESSON - artifact audit mirror + UTF-8 order read (2026-09-11)
**Actor:** GROKBOT_ACTED teach; VERIFY = PASS MIXED (not KEVIN_ACTED)
**Family:** DONE_ARTIFACT_MISSING_OR_OUTSIDE_ROOT + FINAL_ORDER_CORRELATION_MISMATCH_UTF8

## Fixes
1. green-operator mirrors DONE -> reports/invocations/artifacts/ (hash-checked)
2. worker Sync-DoneArtifactsToAuditRoot before reconcile (live sha DC28901F…; pin 16C49542… not overwritten)
3. Get-Content -Encoding UTF8 for order JSON (PS 5.1)

## Tick/Boot
- Rules: docs/engineering/TICK-BOOT-RULES-invoke-failure-family-v1.json
- Refresh: tools/Refresh-Kevin-PublicOutcomeProven-v1.ps1 (-Publish)
- STAGE_OK + matching puller hashes => do not re-paste puller
- Expect worker DC28901F… / operator 20CB3740… until typed pin refresh

## Boundary
PASS only from VERIFY receipt judgment. No KEVIN_ACTED claim on MIXED.
