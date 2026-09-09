# LESSON — Henry / OpenClaw autonomy patterns (2026-09-09)

**Failure family:** `autonomy-pattern-gap-v1` (OPEN)  
**Authority:** GREEN-A research. No machine change. No authority expansion.

## What successful local builds actually do

Alex Finn's Henry is an **org chart**, not a swarm: owner at top, chief of staff (Henry on a frontier model) approving/disapproving, then specialist employees (Ralph QA, Charlie coder on local Qwen) doing the work. OpenClaw 2.0 added heartbeat, Active Memory, and self-learning, but Windows console flash remains a known bug and ClawHub had a major malicious-skill campaign (ClawHavoc: 1,184+ skills; later audits flagged 30%+ suspicious).

Community patterns that repeatedly produce durable autonomy:

1. **Durable state outside the prompt** — work progress on disk; a cleared session must still be able to resume.
2. **Governed self-modification tiers** — propose → test → qualify → install; never let the agent rewrite its own verifier or permissions.
3. **Deterministic verification** — every "done" has a verifiable side effect (file hash, receipt), not a model claim.
4. **Anti-narcissism** — the agent cannot mark itself healthy; an independent judge does.
5. **End-to-end tested self-healing** — recovery chains that look connected but are not silently fail; test each handoff.
6. **Do not blindly self-upgrade** — most OpenClaw updates break the install; use typed, qualified crossings.
7. **Skills as proven procedures, not prompt templates** — exact identity, pinned manifest/proof, fresh inputs, actual artifacts.

## Where Kevin already matches

- Local always-on hardware (HESS-PC), durable WorkInstances, heartbeat, 27 PROVEN composite skills, Supervisor/Skill Lab/invocation, typed Maintenance ladder, Benchmark 30/30, independent artifact hashing, GREEN/YELLOW authority split, Night Forge disabled, exact-five desktop.

## Where Kevin still trails Henry

- First proven skill not yet callable on fresh inputs (worker fail-closed).
- No public `reason` field on continuation (private state only).
- No browser / communications / Minecraft player adapter yet.
- No Kevin-originated skills through the missing-capability loop.
- Owner UX (HQ bounce, console flash) still interrupting.

## Decision

Do **not** copy an unrestricted swarm or install marketplace skills. Close the worker path first, then grow capabilities through the same discover→build→isolate→test→prove→register→invoke→verify→learn loop. That is how Kevin becomes the Henry-shaped worker without the Henry-shaped risk.
