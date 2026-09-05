# Next prove steps (follow / combat) — when Matt is in Realm

**Updated:** 2026-09-05 ~09:55 MT
**Not proven:** follow, combat, guard autopilot, createBot Realms join-compat.

1. DONE: `install-deps.cmd` -> `smoke-require.cmd` -> `KEVIN_MC_STACK_SPIKE_IMPORT_OK`
2. Hash-check JOIN_OK `package-lock.json` unchanged (26397A3E…865D)
3. DONE scaffold: `bridge/` + `smoke-bridge.cmd` (dry)
4. DONE P2 wire: `createJoinOkClient` (gym NetherNet) + `enableStayCompanion` + `rejoin-companion.cmd`
5. DONE unit: `smoke-companion-wire.cmd` (fake packets / NEG) — not live
6. If Minecraft.Windows open: `READY_FOR_LIVE_INJECT` — Matt closes UWP (never kill)
7. When UI clear: `rejoin-companion.cmd` stay+companion — receipt before FOLLOW_OK
8. Hostile-only combat + guard whitelist Matt — never PvP Matt, no grief
