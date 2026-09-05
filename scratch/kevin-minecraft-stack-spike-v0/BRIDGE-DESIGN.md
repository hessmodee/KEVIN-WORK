# BRIDGE DESIGN — inject JOIN_OK client into bedrockflayer

**Updated:** 2026-09-05 ~09:55 MT
**Status:** P2 wire — real JOIN_OK `createClient` (NetherNet / 2169) path into inject + stay companion entry. **Not** `KEVIN_MC_STACK_JOIN_COMPAT_OK` / FOLLOW_OK until live receipts.
**Lockfile:** NEVER mutate `kevin-minecraft-bedrock-v0/package-lock.json`.

## Problem

- JOIN_OK gym joins Realms via **NetherNet + identity SDP + protocol 2169 / 1.26.45** (`bedrock-protocol.createClient` with `realms.pickRealm`).
- Vendor `bedrockflayer.createBot` always calls `createClient({host,port,...})` — LAN/BDS UDP path.
- Therefore **Realms join is not via createBot yet**.

## Chosen approach (P1 scaffold + P2 wire)

**Inject** an already-joined JOIN_OK client into BedrockBot:

1. Monkey-patch `bedrock-protocol.createClient` for one call inside spike-local `bridge/create-bot-injected.js`.
2. `createBotFromClient(client, opts)` returns a BedrockBot bound to that client.
3. Late-bind: if client already spawned, re-emit `connect`/`spawn` + `_onStartGame(startGameData)` when present.
4. Companion: `enableStayCompanion` → GoalFollow Matt + hostile-only guard + autoEat if safe.
5. Live entry: `rejoin-companion.cmd` (preflight MC UI → createJoinOkClient → inject → wire).

Alternative (not chosen first): adapt gym to host pathfinder — higher risk of gym churn.

## Files (spike-only)

| Path | Role |
| --- | --- |
| `bridge/paths.js` | vendor/gym paths; never-hessmodee identity assert |
| `bridge/create-bot-injected.js` | `createBotFromClient` / `createBotFromJoinOkClient` |
| `bridge/join-ok-client-factory.js` | gym NetherNet require; `createJoinOkClient` gated by env |
| `bridge/find-matt.js` | find `hessmodee` / display variants |
| `bridge/companion-wire.js` | GoalFollow / hostile guard / autoEat / packet queue |
| `rejoin-companion.cmd` | stay+companion entry (preflight → live) |
| `smoke-bridge.js` | dry require + fake-client inject smoke |
| `smoke-companion-wire.js` | fake packets + NEG unit smoke |
| `READY_FOR_LIVE_INJECT.md` | owner close step when MC UI blocks |

## Packets JOIN_OK already uses

- Proven: `client.queue("text", …)` chat (JOIN_OK marker).
- Scaffolded (same `queue` surface, **not Realms-proven**): `inventory_transaction` attack shape from bedrockflayer combat; `animate` swing.

## Prove ladder

1. `smoke-require.cmd` → IMPORT_OK (done)
2. `smoke-bridge.cmd` → dry inject OK (done)
3. `smoke-companion-wire.cmd` → fake NEG + wire smoke
4. Matt closes Minecraft.Windows if BLOCKED_MC_UI → `rejoin-companion.cmd`
5. Live: spawn + Matt entity → only then chase FOLLOW_OK receipt
6. Hostile guard / autoEat — still need receipts for OK markers

## Non-claims

No FOLLOW_OK / COMBAT_OK / GUARD_OK / JOIN_COMPAT_OK until live receipts.
When MC UI open: emit `READY_FOR_LIVE_INJECT` — never kill UWP.
