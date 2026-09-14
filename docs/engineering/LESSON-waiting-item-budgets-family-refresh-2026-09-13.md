# LESSON — WAITING_ITEM_BUDGETS is not idle-without-work

**Date:** 2026-09-13  
**Actor:** GROK_BUILD_ACTED (Grok Bot credits dead; no HESS shell)  
**Not PASS.**

## Symptom

HQ showed 5 eligible + READY + cycle increment. Floor `WAITING_ITEM_BUDGETS` / `THROTTLED`. Last owner invoke still Friday night. Tick kept counting (487 → 636). People read that as “Kevin is working.” He was not.

## Root cause

Supervisor v1.8.12 is a **consumer** of `inbox/autonomy/work-items.json`.

| Queue | What was true 2026-09-13 22:20 MT |
|---|---|
| OPEN items | 5 research predecessors, `blocked=false` |
| Continuation | `BOUNDED_TURNS_REQUIRES_NEW_EVIDENCE` on all 5 (3 turns each) |
| Production execution WIs with `required_skill_key` | All COMPLETE |
| Standing catalog | Guardians + research only — **no West Motor family loop with a proven skill key** |
| Tick | Publish floor + outcomes rebuild. Does **not** materialize the next due owner WI |

So `eligible_count=5` and `NO_ELIGIBLE_MISSION` can both be true. The five are deferred. There is no fresh production invoke target. `WAITING_ITEM_BUDGETS` is fail-closed honesty, not a license to wipe history.

## Comparable local-agent lesson (keep, do not plant)

OpenClaw Heartbeat ≠ work. Hermes isolates cron from chat. Successful local agents treat owner-value as **recurring due instances of existing skills**, not one-shot WIs that spend a budget forever. ClawHub / Hermes / Night Forge stay out of the plant. Kevin already has Tick (heartbeat) and Supervisor (select). The missing piece was the **family-loop materialize** step.

## Repair (this cycle)

1. One new OPEN production WI `owner-west-motor-parts-chase-refresh-2026-09-13-v1` bound to **existing** `west-motor-parts-chase-board-pack@1`.
2. COMPLETE parents stay COMPLETE. No budget wipe.
3. Puller v1.7 runs `Materialize-Kevin-FamilyLoop-v1.ps1` so the next `WAITING_ITEM_BUDGETS` does not need Grok Bot.
4. Standing catalog gains `west-motor-owner-value-family-loop-v1` (24h, same skill key, clone freeze).

## Never

- Solve this by deleting WorkInstances or resetting turns.
- Mint another `*-fresh-YYYY-MM-DD-vN` spreadsheet+text PROVE alias.
- Count cycle++ as an owner outcome.
- Put a work checklist in `HEARTBEAT.md` (intentionally empty so OpenClaw does not compete with Supervisor).
