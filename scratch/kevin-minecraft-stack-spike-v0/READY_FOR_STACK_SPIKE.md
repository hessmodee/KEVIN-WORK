READY_FOR_STACK_SPIKE
Updated: 2026-09-05 ~09:45 MT
Isolated spike only. Do not mutate JOIN_OK gym lockfile.
Vendor: vendor/mineflayer-for-bedrock-main (bedrockflayer 0.1.0).
**IMPORT_OK stamp:** KEVIN_MC_STACK_SPIKE_IMPORT_OK (2026-09-05 ~09:34 MT) — install-deps.cmd INSTALL_OK; smoke-require.js PASS; exports createBot/GoalFollow/GoalNear/GoalBlock/guard/autoEat/collectBlock; pluginFiles combat/guard/pathfinder true.
Gym lock SHA256 26397A3E84558B6841143C75CC9DEE5B25928AE7CBC58C384C2C1592F8BC865D UNCHANGED.
**Honest gap:** Realms join is NOT via createBot yet. JOIN_OK stays NetherNet/identity SDP createClient (protocol 2169 / 1.26.45). Spike bridge scaffolds client injection (see bridge/ + BRIDGE-DESIGN.md) — no live KEVIN_MC_STACK_JOIN_COMPAT_OK until injected client spawn proven.
**MC UI:** Minecraft.Windows may block rejoin stay (BLOCKED_MC_UI) until Matt closes UWP.
Next: smoke-bridge.cmd (dry) → when UI clear, rejoin.cmd stay → wire createBotFromClient on live JOIN_OK client.
No combat/follow autopilot claim. No KEVIN_MC_FOLLOW_OK / COMBAT_OK / GUARD_OK claim.
