# P0.2 Capability-Aware Routing — Status (America/Boise)

**When:** 2026-09-04 ~08:30 MT  
**Actor:** Grok Bot  
**Authority:** NONE (docs + typed planner/config/tests; no Desktop install; no live Supervisor replace)

## Root cause
Selector `UNKNOWN_PROGRAM` for `owner-value-skills` made OPEN Skill Lab owner work ineligible (`eligible=0`, blocked backlog present). Supervisor v1.8.8 then reported `IDLE_NO_ELIGIBLE_DEMAND` and would only ever dispatch to `fixed:main`.

## Landed
See receipt JSON. Admission proves appliance OPEN → `ROUTE_TO_SKILL_LAB` / `DEFER_TO_SKILL_LAB_DO_NOT_CALL_MAIN`.

## Next
1. Merge PR + CI green.  
2. YELLOW typed install of Supervisor v1.8.9 + selector v1.2 together (not this packet).  
3. Keep P0.1 Desktop crossing on Matt HOLD.
