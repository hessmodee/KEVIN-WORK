# BRIDGE DESIGN — inject JOIN_OK client into bedrockflayer

**Updated:** 2026-09-05 ~09:45 MT
**Status:** Scaffold only. **Not** `KEVIN_MC_STACK_JOIN_COMPAT_OK`.
**Lockfile:** NEVER mutate `kevin-minecraft-bedrock-v0/package-lock.json`.

## Problem

- JOIN_OK gym joins Realms via **NetherNet + identity SDP + protocol 2169 / 1.26.45** (`bedrock-protocol.createClient` with `realms.pickRealm`).
- Vendor `bedrockflayer.createBot` always calls `createClient({host,port,...})` — LAN/BDS UDP path.
- Therefore **Realms join is not via createBot yet**.

## Chosen approach (P1)

**Inject** an already-joined JOIN_OK client into BedrockBot:

1. Monkey-patch `bedrock-protocol.createClient` for one call inside spike-local `bridge/create-bot-injected.js`.
2. `createBotFromClient(client, opts)` returns a BedrockBot bound to that client.
3. Late-bind: if client already spawned, re-emit `connect`/`spawn` + `_onStartGame(startGameData)` when present.
4. Companion defaults: load `guard`, `targetPlayers=false`, whitelist `hessmodee`.

Alternative (not chosen first): adapt gym to host pathfinder — higher risk of gym churn.

## Files (spike-only)

| Path | Role |
| --- | --- |
| `bridge/paths.js` | vendor/gym paths; never-hessmodee identity assert |
| `bridge/create-bot-injected.js` | `createBotFromClient` |
| `bridge/join-ok-client-factory.js` | read-only gym require; live join gated by env |
| `bridge/find-matt.js` | find `hessmodee` entity |
| `bridge/companion-wire.js` | GoalFollow / hostile guard / packet queue helpers |
| `smoke-bridge.js` | dry require + fake-client inject smoke |

## Packets JOIN_OK already uses

- Proven: `client.queue("text", …)` chat (JOIN_OK marker).
- Scaffolded (same `queue` surface, **not Realms-proven**): `inventory_transaction` attack shape from bedrockflayer combat; `animate` swing.

## Prove ladder

1. `smoke-require.cmd` → IMPORT_OK (done)
2. `smoke-bridge.cmd` → dry inject OK (no Realms)
3. Matt closes Minecraft.Windows if BLOCKED_MC_UI → `rejoin.cmd` stay
4. Operator experiment: pass live client into `createBotFromClient` → watch spawn/plugins
5. Only then: GoalFollow near Matt / hostile guard — still need receipts for OK markers

## Non-claims

No FOLLOW_OK / COMBAT_OK / GUARD_OK / JOIN_COMPAT_OK until live receipts.
