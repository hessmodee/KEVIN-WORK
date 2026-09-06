# LESSON — Public continuation history, owner-value routing, HQ owl floor

**Date:** 2026-09-06
**Authority:** GREEN diagnosis + bounded source repair. No history reset. No forced mission execution.

## What was actually true

Platform recovery (v4) remained proven. The seeded West Motor dispatch mission was **admitted and selected** by Supervisor:

- `2026-09-06T16:05:49-06:00` public receipt: `AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF`, `selected_id=owner-west-motor-transport-dispatch-template-v1`, `eligible_count=1`, `same_fingerprint_turns=2`, `tool_calls=4`, `outcome_proven=false`.
- `2026-09-06T16:09:31-06:00`: `WAITING_ITEM_BUDGETS`, `eligible_count=1` (MIN_REPEAT after that turn).

Eligibility was not the remaining defect. Three other defects were:

1. **Public serializer fail-closed.** `Get-PublicContinuation` threw on any invalid history row (`status` not in a tiny allow-list, missing status, identity/time parse) and wiped `history` while setting `history_error=true`. Deferred reasons (`MIN_REPEAT` vs `BOUNDED_TURNS_REQUIRES_NEW_EVIDENCE`) were computed in-cycle but never copied onto the public receipt, so WAITING_ITEM_BUDGETS was opaque.
2. **Wrong worker.** `owner-value-skills` items with `lane=production` and no `worker` were dispatched to **tool-less fixed:main**. The capability router already inferred Skill Lab from program, but Supervisor only inspected `lane`/`worker`. Main cannot create the spreadsheet/text artifacts. Turns were charged **before** the route check, so a later Skill Lab handoff would still burn the last bounded turn.
3. **HQ Ops overlay.** `docs/ops/embed.html` loaded `ops-mission-floor-v1.js` last. That script adds `body.mof-on`, which **hides the worker-owl topology** (`display:none` on `.topology`) and paints FIND_WOLF / X-eyes STALE (2-minute stale window vs 15-minute dashboard tick).

## Repair (this change)

- Skip invalid history rows; `history_error` only if `Read-State` itself fails. Publish sanitized `deferred[]` on WAITING_ITEM_BUDGETS.
- Infer Skill Lab from `program` (`owner-value-skills`, `skill-learning`, `capability-growth`) **before** charging a turn. Routing handoff is not a main-agent attempt.
- Restore Ops Floor primary view to the v11 worker-owl ring. FIND_WOLF overlay remains at `docs/ops/embed-mission-v1.html` only.
- Tests: OPEN/GREEN/production/owner-value fixture (v1.1 + v1.2); west-motor-shaped router case; public-receipt skip + deferred (v1.8.10).

## What this does not do

- Does not reset `continuation-state.json`.
- Does not change the seeded west-motor item status/fingerprint.
- Does not enqueue the skill pack into Skill Lab `ready/` (that would skip the governed selection proof).
- Does not claim an owner outcome. `AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF` is still not an accomplishment.

## Next proof

After this Supervisor is installed on HESS-PC, the next scheduled cycle should `ROUTED_TO_SKILL_LAB` for west-motor without charging turn 3. Then stage `inbox/skills/west-motor-transport-dispatch-template-v1.json` through the existing Relay/Skill Lab GREEN path so the workbook + operating note can be proven.
