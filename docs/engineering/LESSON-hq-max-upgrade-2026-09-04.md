# LESSON — HQ Max upgrade Phase 0 (2026-09-04)

## What landed
- Command truth chips (Superv / Tools / Lease / Proven / Benchmark / Skill Lab R/Q/B) from named public sources only; missing fields render `unknown` — never invent exact-4, lease ACTIVE, Drive INTERIM, or grants_budget_unlock.
- `continuation.status` matching `/^(WAITING_|BLOCKED|NEEDS_|DEFERRED|COOLDOWN)/` classifies as **BLOCKED WORK**, not READY/IDLE, even if `eligible_count>0` (e.g. WAITING_ITEM_BUDGETS with eligible_count=1).
- Skill Lab queue path: if `action.skill_lab.queue` is absent, fall back to `action.composite_skills` then `action.queues` for ready/running/blocked/done/failed counts.
- HQ gate greps rotated off dead `hqCopyHandover`/`hqViewHandover` in `hq-overrides-v1.js` onto live dock IDs `kevinHandoverLaunch`/`kevinTalkLaunch` in `docs/index.html`.
- Cache bump `hq-owner-refinement-v3.js?v=3`.

## Truth rules (do not re-learn)
1. **WAITING = blocked.** Supervisor waiting/needs/deferred/cooldown is blocked work, not idle readiness theater.
2. **Dead Skill Lab path.** Counting only `action.skill_lab.queue` silently zeros Skill Lab when publishers move counts onto `composite_skills` or `queues`. Always fall back.
3. **CI grep rot.** Gate assertions must track the live dock/handover controls. Old override button IDs rot after shell consolidation and falsely fail (or falsely pass) HQ gates.
4. **Phase 0 vs Phase A publishers.** Phase 0 is HQ shell truth + gate hygiene. Do not claim publisher/schema work done until Phase A lands with snapshot evidence.
5. **Desktop LIVE facts stay.** Exact-4 Desktop LIVE on HESS-PC (PR#77) is unchanged and must not be rewritten by HQ chip work. No openclaw.json / Desktop / Chat port / Owl edits from this lesson.
6. Teach-and-transfer: durable PLAN+LESSON + CURRENT_TASK evidence; no GROK-HANDOVER. `AI-HANDOVER.md` remains the one human canonical handover.

## Prove
```
node --check docs/hq-owner-refinement-v3.js
node .github/scripts/test-hq-owner-invariants.cjs
grep -q 'kevinHandoverLaunch' docs/index.html
grep -q 'kevinTalkLaunch' docs/index.html
```

## Rollback
Revert the HQ max Phase 0 PR/commit. Restore `?v=2` only if Pages must pin the prior shell briefly.
