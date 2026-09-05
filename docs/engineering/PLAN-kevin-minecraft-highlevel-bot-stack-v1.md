# PLAN — Kevin Minecraft high-level Bedrock bot stack v1

**Updated:** 2026-09-05 ~09:45 MT
**Edition:** Bedrock Realms via **NetherNet overlay** — JOIN_OK proven (protocol **2169** / 1.26.45).
**Identity:** kevinsk8erkid only. Never hessmodee.
**Authority:** GREEN teach/PLAN. No Chat tool widen. No purchases. No force Realms addons.

## Goal

High-level Bedrock bot API so Kevin can eventually follow, fight, dig/place, eat, guard — without breaking NetherNet join.

## Non-goals

- Do not mutate JOIN_OK gym deps until spike proves coexistence
- Do not claim Java mineflayer works on Bedrock Realms
- Do not force world addons; no PvP Matt; no grief; no fake OK markers

## Candidates (research — not claimed installed)

| Stack | Strengths | Risks vs overlay |
| --- | --- | --- |
| **torzodmc/mineflayer-for-bedrock** | pathfinder GoalFollow/Near, combat, dig/place, craft, auto_eat, guard | protocol pin / Realms+NetherNet unknown |
| **deepslate-bedrock/prismarine-bedrock** | Mineflayer-like rebuild | pathfinding still biggest gap |
| **MineToring** | high-level API on bedrock-protocol | version matrix may lag 2169 |
| **Our scratch skills** | zero join regression | coach + scaffolds |
| **mineflayer-pathfinder (Java)** | GoalFollow patterns to port | Java only — reference |

**Recommendation:** Spike **mineflayer-for-bedrock** in isolated `scratch/kevin-minecraft-stack-spike-v0`. Keep `kevin-minecraft-bedrock-v0` JOIN_OK until: import OK, NetherNet+2169 compat (or documented gap), follow+hostile smoke. Else leave READY_FOR_STACK_SPIKE.

Fallback: mineflayer-for-bedrock → MineToring → prismarine-bedrock + ported pathfinder → deepen stubs.

## Phases

| Phase | Prove | Marker |
| --- | --- | --- |
| P0 | Isolated install/import; no JOIN_OK lockfile touch | KEVIN_MC_STACK_SPIKE_IMPORT_OK |
| P1 | Auth/join compat note + inject bridge scaffold | KEVIN_MC_STACK_JOIN_COMPAT_OK (live only) |
| P2 | GoalFollow near Matt | KEVIN_MC_FOLLOW_OK |
| P3 | Dig/place invited | KEVIN_MC_DIG_OK / PLACE_OK |
| P4 | Combat + no friendly fire | KEVIN_MC_COMBAT_OK |
| P5 | Guard + auto_eat + rejoin persist | KEVIN_MC_GUARD_OK |

## Optional later

Understudy / Simulated Players / Auto Companions if Matt asks. Prefer protocol bot.

## Safety

Never hessmodee; no PvP Matt; no grief; no Chat/Reader kill; no purchases; never mutate gym lockfile.
Policy: `control-plane/game/minecraft-companion-policy-v1.py`.

## Pointers

- Playbook companion proactive combat/build v1
- RECIPE-nethernet-realms-overlay-v2.md
- LESSON-mineflayer-java-not-bedrock-realms-fork-2026-09-04.md
- BRIDGE-DESIGN.md in spike

## Spike status (2026-09-05 ~09:45 MT)

P0 **IMPORT_OK** (install-deps + smoke-require). P1 **bridge scaffolded** (`bridge/create-bot-injected.js`, dry `smoke-bridge`) — Realms join still **not** via createBot; JOIN_COMPAT_OK not claimed. Skills deepened hostile-only / follow-Matt / whitelist. JOIN_OK gym lock untouched (SHA256 26397A3E…865D).
