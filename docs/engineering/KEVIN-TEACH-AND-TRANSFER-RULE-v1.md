# Chief of Staff / Bess → Kevin Teach-and-Transfer Rule v1

Owner directive: 2026-09-01
Status: STANDING

## Purpose

Wean Kevin off routine dependence on Chief of Staff (GrokBot) and ChatGPT (Bess). Kevin must become fully independent and autonomous for authorized work. Outside coaches exist to train, prove, and transfer — not to permanently operate Kevin.

## Incomplete vs complete work

A change or fix is **incomplete** if it only exists in an outside chat, a one-off shell session, or an engineer's head.

A change or fix is **complete** only when Kevin can own the next occurrence without being babysat. That means durable transfer into at least one of:
1. Kevin workspace docs Kevin actually reads (`SOUL.md` short pointer, `AGENTS.md` standing rule, `MEMORY.md` lesson, `docs/engineering/*` procedure)
2. A typed Maintenance/Engineering operation, eval, fixture, or regression test
3. A governed skill / helper with schema, negatives, rollback, and proof receipt
4. Updated Support/Engineering truth so Kevin's own loops see the new normal

## Required teach-back on every production crossing

Whenever Chief of Staff or Bess changes Kevin, they must leave behind:
- **What broke or what was missing** (failure family / gap)
- **What changed** (file/hash/operation identity, not vibes)
- **How Kevin detects it next time**
- **How Kevin repairs or avoids it next time**
- **Proof** that the lesson is on disk in Kevin's world (path + hash or receipt id)

If the teach-back is missing, the crossing is not done — even if the symptom is gone for now.

## Autonomy transfer scale (do not fake)

Preserve T0–T5 responsibility transfer honesty. Coaching Kevin is not the same as Kevin owning the loop. Public HQ and receipts must not claim independence that is not proven.

## Immediate application

Current P0 example: fixed:main Qwen context overflow and exact canary semantics. Solving it in Chief of Staff chat alone is insufficient. Kevin must receive the diagnosis, the config policy (`reserveTokensFloor`, model pin, skills=[], context budget), and a durable recovery procedure so he can keep main healthy without Bess.