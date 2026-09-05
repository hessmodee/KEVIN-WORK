# LESSON: Minecraft stack spike P2 JOIN_OK live-wire + stay companion (2026-09-05)

**At:** 2026-09-05 ~09:55 MT
**Actor:** GrokBot-executor
**Result:** WIRED — real JOIN_OK NetherNet createClient path into inject + rejoin-companion entry; live stay **blocked** by Minecraft.Windows (`READY_FOR_LIVE_INJECT`); fake/unit companion smoke available; no FOLLOW/COMBAT/GUARD OK claimed

## One-liner

Spike wires gym JOIN_OK `createClient` (NetherNet / protocol 2169) into `createBotFromClient`, adds stay+companion entry with GoalFollow/hostile-guard/autoEat, and refuses live inject while UWP is open.

## Codified

- `bridge/join-ok-client-factory.js` — `createJoinOkClient`, `waitForClientSpawn`, `assertNethernetReady`, fake client
- `bridge/create-bot-injected.js` — `createBotFromJoinOkClient`, autoEat load in defaults
- `bridge/companion-wire.js` — `enableStayCompanion`, `enableAutoEatIfSafe`, stronger NEG deny
- `rejoin-companion.cmd` / `.js` — preflight → stay → inject → wire
- `smoke-companion-wire.*` — fake packets unit
- `READY_FOR_LIVE_INJECT.md` — owner close step

## Findings

1. MC UI gate must stay fail-closed: never kill Minecraft.Windows; emit READY_FOR_LIVE_INJECT + clear Matt close instructions.
2. Gym `node_modules/bedrock-protocol` with `src/nethernet.js` is required for live createClient — vendor alone is LAN path.
3. GoalFollow/guard/autoEat remain WIRED_NOT_PROVEN until spawn + Matt entity receipts.
4. JOIN_OK lock SHA256 26397A3E…865D must stay unchanged.

## Invariants

Never hessmodee bot login; no Chat/Reader kill; no purchases; no grief/PvP Matt; no FOLLOW/COMBAT/GUARD OK without live receipts; never mutate JOIN_OK lockfile.
