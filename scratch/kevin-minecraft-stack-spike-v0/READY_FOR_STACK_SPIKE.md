READY_FOR_STACK_SPIKE
Updated: 2026-09-05 ~09:55 MT
Isolated spike only. Do not mutate JOIN_OK gym lockfile.
Vendor: vendor/mineflayer-for-bedrock-main (bedrockflayer 0.1.0).
**IMPORT_OK stamp:** KEVIN_MC_STACK_SPIKE_IMPORT_OK (2026-09-05 ~09:34 MT) — install-deps.cmd INSTALL_OK; smoke-require.js PASS.
Gym lock SHA256 26397A3E84558B6841143C75CC9DEE5B25928AE7CBC58C384C2C1592F8BC865D UNCHANGED.
**P2 wire:** `bridge/join-ok-client-factory.js` createJoinOkClient uses gym NetherNet overlay (protocol 2169 / 1.26.45). `rejoin-companion.cmd` = preflight → JOIN stay → inject → GoalFollow/guard/autoEat (WIRED_NOT_PROVEN).
**Honest gap:** No live KEVIN_MC_STACK_JOIN_COMPAT_OK / FOLLOW_OK / COMBAT_OK / GUARD_OK until spawn+entity receipts.
**MC UI:** If Minecraft.Windows running → READY_FOR_LIVE_INJECT (see READY_FOR_LIVE_INJECT.md). Never kill UWP.
Dry anytime: smoke-bridge.cmd + smoke-companion-wire.cmd.
No combat/follow autopilot claim.
