# Kevin Build — START HERE

This is the canonical entrypoint for any **new ChatGPT conversation, replacement engineer, or recovered Kevin Build session**.

If you are a fresh AI helping Matt with Kevin, do **not** ask Matt to reconstruct the project from memory and do not assume an old chat summary is current. Rebuild context from the repository and fresh evidence in this order.

## North star — train Kevin to replace Bess operationally

Read `docs/engineering/KEVIN-AUTONOMY-MASTER-PLAN-v1.md`, `docs/engineering/BESS-TO-KEVIN-AUTONOMY-TRANSFER-DOCTRINE-v1.md`, and `docs/engineering/RESPONSIBILITY-TRANSFER-LEDGER-v1.md` as first-class project doctrine.

The long-term goal is not for Bess/ChatGPT to remain Kevin's remote operator. The goal is to progressively transfer routine planning, execution, verification, monitoring, repair, learning, communication, handoff, and work-selection responsibilities from Bess to Kevin until Bess is unnecessary in Kevin's normal authorized operating loop.

Track this separately from technical proof using:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

Whenever Bess repeatedly performs a useful action, treat that recurring action as autonomy debt and ask how to encode it as an observable, typed, testable, reversible Kevin responsibility. Once a responsibility reaches T4 with repeated evidence, Bess should stop routinely doing it.

## Mandatory startup sequence

1. Read this file completely.
2. Read `docs/engineering/KEVIN-AUTONOMY-MASTER-PLAN-v1.md` for the research-backed target architecture, no-spin/WIP rules and phased execution plan.
3. Read `AI-HANDOVER.md` for the current engineering narrative, proof levels, blockers, exact hashes/PRs, and immediate queue.
4. Read `inbox/CURRENT_TASK.md` for the owner's current execution contract and priority order.
5. Read `docs/engineering/BESS-TO-KEVIN-AUTONOMY-TRANSFER-DOCTRINE-v1.md`, `docs/engineering/RESPONSIBILITY-TRANSFER-LEDGER-v1.md`, `reports/responsibility-transfer-latest.json`, and `reports/autonomy-master-scorecard.json` for current Bess-dependency/transfer and master-lane state.
6. Read `control-plane/OWNER-AUTHORIZATION-v1.md` plus any narrowly applicable authorization file before consequential work.
7. Inspect the newest trustworthy live evidence before acting:
   - `reports/support-latest.json`
   - `reports/dashboard-state.json`
   - `reports/control-plane-latest.json`
   - `reports/engineering/latest.json`
   - `reports/autonomy-latest.json`
   - `reports/skills.json`
   - current maintenance/Benchmark evidence when relevant
   - open PR/CI state when a candidate or production crossing is relevant
8. Compare timestamps, request IDs, idempotency keys, hashes, PR heads, CI conclusions, active-worker state, and postconditions. **Fresh evidence outranks handover prose.**
9. State internally what is current, what is stale, what is blocked, what WIP slots are occupied, what routine Bess responsibility can be transferred next, and the single highest-value safe next action before mutating anything.
10. Preserve the scheduled single-writer rule: **Kevin Chief Engineer is the only scheduled automation allowed to steer/mutate Kevin execution state.** Read-only scorecards may observe but must not steer.

## Architecture convergence rules

Prefer native OpenClaw durability where it cleanly replaces bespoke orchestration:

- Standing Orders for permanent programs;
- Automations for recurring scheduled work;
- Heartbeat for ambient monitoring only;
- Task Flow for durable multi-step work;
- Lobster for constrained deterministic pipelines/approval-resume flows;
- Skill Workshop/self-learning for governed procedural learning;
- Kevin Skill Lab for executable composites composed only from proven GREEN primitives;
- native workspace memory + pre-compaction memory flush for always-loaded continuity;
- GitHub for source, doctrine, PR/CI and sanitized durable evidence rather than the long-term primary live task queue.

Do not rip out proven components merely to use a native feature. Migrate only with evidence and rollback.

## No-spin / WIP rule

Default global WIP:
- 1 ACTIVE production/proof crossing;
- 1 STAGING/EVAL item;
- 1 RESEARCH/DESIGN item with a named downstream consumer.

Do not count heartbeat/pulse/dashboard churn, raw cycle count, PONG/model smoke checks, duplicate requests, uninstalled candidates, or task/hash presence as owner-visible progress.

Round-robin Forge design without demand is not useful work. Any design/forge mission needs a current owner objective, explicit missing capability/hypothesis, acceptance tests, downstream consumer, WIP capacity and a non-cooled failure family.

## Proof language is mandatory

Never collapse these states:

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

A new chat must not call a capability "working" merely because code exists, CI passed, a task is present, or telemetry says healthy.

Technical proof and responsibility transfer are separate. An OMEN-PROVEN capability can still be only T2 if Bess must notice and dispatch every use.

## New-chat recovery rule

If Matt starts a fresh conversation and says **"Resume Kevin Build"** or **"Continue Kevin from the handoff"**, immediately perform the startup sequence above. Do not make Matt paste the previous conversation unless a genuinely missing owner decision cannot be recovered from the repository/project context.

After reconstructing state, respond with a compact checkpoint:

- current sprint / owner objective;
- latest proven production capabilities;
- current P0 work and exact proof level;
- current responsibility-transfer level for the major P0 lanes;
- WIP slots and no-spin concerns;
- live blockers/cooldowns;
- what is actively in flight;
- what Bess responsibility is being retired next;
- the next safe action you will take.

Then continue the work.

## Before a long chat ends

When context is getting crowded, or after any substantive proof transition, repair, owner decision, blocker, production promotion/rollback, new authority boundary, responsibility-transfer promotion/demotion, or master-plan/WIP change:

1. Re-check fresh evidence.
2. Update `AI-HANDOVER.md` by **reconciling** current truth, not appending contradictory history.
3. Ensure `inbox/CURRENT_TASK.md` still reflects the active owner objective.
4. Refresh `reports/handoff-latest.json` with compact pointers/status if available.
5. Reconcile `docs/engineering/RESPONSIBILITY-TRANSFER-LEDGER-v1.md`, `reports/responsibility-transfer-latest.json`, and `reports/autonomy-master-scorecard.json` when evidence changes responsibility or master-lane truth.
6. Record exact hashes, request IDs, PR/CI heads, proof levels, transfer levels, WIP state and owner-required checkpoints needed by the next AI.
7. Never store secrets/private message bodies in handoff artifacts.

## Durable project sources

- Master architecture: `docs/engineering/KEVIN-AUTONOMY-MASTER-PLAN-v1.md`
- Master scorecard: `reports/autonomy-master-scorecard.json`
- Canonical narrative handoff: `AI-HANDOVER.md`
- Current execution contract: `inbox/CURRENT_TASK.md`
- Stable owner authority: `control-plane/OWNER-AUTHORIZATION-v1.md`
- Capability roadmap: `docs/engineering/OWNER-CAPABILITY-ROADMAP-v1.md`
- Full-steam doctrine: `docs/engineering/FULL-STEAM-CONTINUOUS-IMPROVEMENT-DOCTRINE-v1.md`
- Direct comms/Green mastery campaign: `docs/engineering/OWNER-DIRECT-COMMS-AND-GREEN-MASTERY-CAMPAIGN-v1.md`
- Autonomy-transfer doctrine: `docs/engineering/BESS-TO-KEVIN-AUTONOMY-TRANSFER-DOCTRINE-v1.md`
- Responsibility-transfer ledger: `docs/engineering/RESPONSIBILITY-TRANSFER-LEDGER-v1.md`
- Compact transfer checkpoint: `reports/responsibility-transfer-latest.json`
- Detailed handoff protocol: `docs/engineering/CHAT-HANDOFF-PROTOCOL-v1.md`

## Non-negotiable safety/truth boundaries

No arbitrary shell or arbitrary remote-code authority; no secret/private-data exposure; no silent trust-anchor blessing; no widening permissions/RED authority/recipient scopes; no purchases, money movement, live trades, or unauthorized public/third-party owner-representing sends; no novel YELLOW/RED auto-promotion. Natural-language owner messages are intent, never executable shell. Require bounded retries, semantic success, independent postconditions, idempotency, evidence, and rollback.

Greater autonomy comes from better proven capability inside owner-approved boundaries, never from Kevin granting himself new authority.

The goal of this file is simple: **a new AI should be able to resume Kevin Build in minutes without losing project direction, inventing stale facts, making Matt retell the story, forgetting the no-spin architecture, or forgetting that Bess is supposed to make itself unnecessary.**
