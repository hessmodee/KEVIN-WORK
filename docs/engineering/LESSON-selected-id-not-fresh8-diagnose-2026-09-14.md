# LESSON — Diagnose followed a COMPLETE parent, not the live selected_id

**Date:** 2026-09-14  
**Family:** `INVOKE_SELECTED_ID_STALE_PARENT`  
**Authority delta:** NONE  
**Not PASS. Not HESS-PC install.**

## What was true on the machine

- Supervisor v1.8.12 selected `owner-west-motor-lot-walk-checklist-refresh-v1`.
- Floor / continuation: `ROUTED_TO_PROVEN_SKILL_INVOCATION`, `outcome_proven=false`, `action_era_ready_count=0`.
- Live diagnose `reports/invocations/latest-public-reject.json` still had `work_id_hint=owner-west-motor-parts-chase-fresh-8-v1` and `reason=OUTCOME_PROVEN`.
- That parent is `COMPLETE / COMPLETE_DO_NOT_RESELECT`. ready=0 after DONE is expected for *that* id — and is the wrong id.

## Why MIXED never became KEVIN_ACTED

Diagnose, sticky-RequestId repair, and the OUTCOME_PROVEN short-circuit were hard-coded to the first 8-vehicle job. Isolated STAGE_OK on `diagnose-owner-west-motor-parts-chase-fresh-8-v1` cannot stage `invoke-owner-west-motor-lot-walk-checklist-refresh-v1`. Chat/Grokbot then closed boards by hand. Actor = MIXED. `autonomy_credit=false`.

## Repair (source)

- Diagnose v1.3.5 resolves WorkId from `reports/hq-live-floor.json` then `reports/autonomy-continuation-latest.json`.
- Skip `COMPLETE` / `COMPLETE_DO_NOT_RESELECT`. Never fall back to fresh-8.
- If none open: publish `NO_OPEN_SELECTED_ID` and stop.
- Sticky v1.1.0 takes `-WorkId` and uses the same resolver.
- Hash pins restored: invocation `471E5051…`, builder `E7381E60…`. GitHub ControlPlane worker pin `16C49542…` unchanged.

## Do not

- Recopy Supervisor v1.8.12 / F17F4B0A.
- Overwrite GitHub worker pin `16C49542…`.
- Reopen COMPLETE parents.
- Claim HESS-PC installed this because GitHub changed.
- Claim KEVIN_ACTED for this source change.

## Next runtime proof

HESS must run Diagnose v1.3.5 against the live OPEN selected_id. PASS remains workbook + note + DONE + hashes + receipt closed by Tick + Supervisor + Action Era with no `diagnose-*` RequestId.
