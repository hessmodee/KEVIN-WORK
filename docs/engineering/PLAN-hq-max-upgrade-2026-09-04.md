# PLAN — HQ Max upgrade Phase 0 (2026-09-04)

## Intent
Make Kevin HQ Command tell the truth about Supervisor waiting/blocked states, Skill Lab queue counts, and a small set of named public truth chips — without inventing Desktop exact-4, lease ACTIVE, Drive INTERIM, or grants_budget_unlock.

## Phase boundary (Phase 0 vs Phase A publishers)
- **Phase 0 (this PR):** source-only HQ shell + gate fixes + teach-and-transfer PLAN/LESSON + CURRENT_TASK evidence note. Safe to land without touching live publishers, openclaw.json, Desktop exact-4, Chat ports, or Owl geometry.
- **Phase A (later):** publisher/path work that may change Engineering/Support snapshot shapes, Skill Lab queue publishers, lease projection into `action.mission_lease` / continuation.lease, or Pages publish cadence. Do not conflate Phase 0 UI truth with Phase A data-plane publishers.

## Scope (Phase 0)
1. `docs/hq-owner-refinement-v3.js`
   - `skillQueue()` falls back when `action.skill_lab.queue` is missing: `action.composite_skills` then `action.queues` for ready/running/blocked/done/failed (dead Skill Lab path repair).
   - `truth()`: `continuation.status` matching `/^(WAITING_|BLOCKED|NEEDS_|DEFERRED|COOLDOWN)/` is **BLOCKED WORK**, never READY/IDLE, even when `eligible_count>0`.
   - Command truth chips from named public sources only (Superv, Tools, Lease, Proven, Benchmark, Skill Lab R/Q/B); absent → `unknown`.
   - Chips card after `.v3stats`; CSS `.v3chips`/`.v3chip`; pulse `#hqV3StateLine i`; `prefers-reduced-motion: animation none`.
   - `stateLine()` sets `className` to `truth().cls`.
2. `docs/index.html` cache bump `hq-owner-refinement-v3.js?v=3`.
3. `.github/workflows/hq-owner-updates-gate.yml` greps: replace rotten `hqCopyHandover`/`hqViewHandover` in overrides with live dock launchers `kevinHandoverLaunch`/`kevinTalkLaunch` in `docs/index.html`.
4. Teach-and-transfer PLAN + LESSON; append HQ max evidence to `inbox/CURRENT_TASK.md` while preserving Desktop LIVE facts.

## Non-goals / hard constraints
- No `openclaw.json` / Desktop exact-4 / Chat port edits.
- Owl geometry untouched.
- No `GROK-HANDOVER`; `AI-HANDOVER.md` remains canonical.
- Do not force-push `main`. Do not merge if CI fails.

## Verify
- `node --check docs/hq-owner-refinement-v3.js`
- `node .github/scripts/test-hq-owner-invariants.cjs`
- HQ owner-updates gate on PR

## Rollback
Revert this branch/PR. Cache-buster `?v=3` falls back by reverting `docs/index.html`.
