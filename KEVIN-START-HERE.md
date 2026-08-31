# Kevin Build — START HERE

This is the canonical entrypoint for any **new ChatGPT conversation, replacement engineer, or recovered Kevin Build session**.

If you are a fresh AI helping Matt with Kevin, do **not** ask Matt to reconstruct the project from memory and do not assume an old chat summary is current. Rebuild context from the repository and fresh evidence in this order.

## Mandatory startup sequence

1. Read this file completely.
2. Read `AI-HANDOVER.md` for the current engineering narrative, proof levels, blockers, exact hashes/PRs, and immediate queue.
3. Read `inbox/CURRENT_TASK.md` for the owner's current execution contract and priority order.
4. Read `control-plane/OWNER-AUTHORIZATION-v1.md` plus any narrowly applicable authorization file before consequential work.
5. Inspect the newest trustworthy live evidence before acting:
   - `reports/support-latest.json`
   - `reports/dashboard-state.json`
   - `reports/control-plane-latest.json`
   - `reports/engineering/latest.json`
   - `reports/autonomy-latest.json`
   - `reports/skills.json`
   - current maintenance/Benchmark evidence when relevant
   - open PR/CI state when a candidate or production crossing is relevant
6. Compare timestamps, request IDs, idempotency keys, hashes, PR heads, CI conclusions, active-worker state, and postconditions. **Fresh evidence outranks handover prose.**
7. State internally what is current, what is stale, what is blocked, and the single highest-value safe next action before mutating anything.
8. Preserve the scheduled single-writer rule: **Kevin Chief Engineer is the only scheduled automation allowed to steer/mutate Kevin execution state.** Read-only scorecards may observe but must not steer.

## Proof language is mandatory

Never collapse these states:

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

A new chat must not call a capability "working" merely because code exists, CI passed, a task is present, or telemetry says healthy.

## New-chat recovery rule

If Matt starts a fresh conversation and says **"Resume Kevin Build"** or **"Continue Kevin from the handoff"**, immediately perform the startup sequence above. Do not make Matt paste the previous conversation unless a genuinely missing owner decision cannot be recovered from the repository/project context.

After reconstructing state, respond with a compact checkpoint:

- current sprint / owner objective;
- latest proven production capabilities;
- current P0 work and exact proof level;
- live blockers/cooldowns;
- what is actively in flight;
- the next safe action you will take.

Then continue the work.

## Before a long chat ends

When context is getting crowded, or after any substantive proof transition, repair, owner decision, blocker, production promotion/rollback, or new authority boundary:

1. Re-check fresh evidence.
2. Update `AI-HANDOVER.md` by **reconciling** current truth, not appending contradictory history.
3. Ensure `inbox/CURRENT_TASK.md` still reflects the active owner objective.
4. Refresh `reports/handoff-latest.json` with compact pointers/status if available.
5. Record exact hashes, request IDs, PR/CI heads, proof levels, and owner-required checkpoints needed by the next AI.
6. Never store secrets/private message bodies in handoff artifacts.

## Durable project sources

- Canonical narrative handoff: `AI-HANDOVER.md`
- Current execution contract: `inbox/CURRENT_TASK.md`
- Stable owner authority: `control-plane/OWNER-AUTHORIZATION-v1.md`
- Capability roadmap: `docs/engineering/OWNER-CAPABILITY-ROADMAP-v1.md`
- Full-steam doctrine: `docs/engineering/FULL-STEAM-CONTINUOUS-IMPROVEMENT-DOCTRINE-v1.md`
- Direct comms/Green mastery campaign: `docs/engineering/OWNER-DIRECT-COMMS-AND-GREEN-MASTERY-CAMPAIGN-v1.md`
- Detailed handoff protocol: `docs/engineering/CHAT-HANDOFF-PROTOCOL-v1.md`

## Non-negotiable safety/truth boundaries

No arbitrary shell or arbitrary remote-code authority; no secret/private-data exposure; no silent trust-anchor blessing; no widening permissions/RED authority/recipient scopes; no purchases, money movement, live trades, or unauthorized public/third-party owner-representing sends; no novel YELLOW/RED auto-promotion. Natural-language owner messages are intent, never executable shell. Require bounded retries, semantic success, independent postconditions, idempotency, evidence, and rollback.

The goal of this file is simple: **a new AI should be able to resume Kevin Build in minutes without losing project direction, inventing stale facts, or making Matt retell the story.**
