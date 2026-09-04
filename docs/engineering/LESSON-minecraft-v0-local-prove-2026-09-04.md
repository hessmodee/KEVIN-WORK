# LESSON: Mineflayer scratch localhost join (2026-09-04)

**At:** 2026-09-04 ~13:14 MT
**Actor:** GrokBot-executor
**Result:** PASS — KEVIN_MC_V0_OK

## What worked
- Scratch at scratch/kevin-minecraft-v0 with flying-squid 1.12.0 + mineflayer 4.38.0 + pathfinder 2.4.5
- 
ode prove-local.js starts offline local server (online-mode false), joins as KevinBot, chats marker, quits, destroys server
- Port auto-pick among 25565/25575/25665/25765/25865
- Recipe: docs/engineering/KEVIN-RECIPE-mineflayer-scratch-v1.md

## Invariants
- No Microsoft login, no paid/public server, no Chat tool surface for MC yet
- Keep scratch isolated from openclaw.json / Desktop exact-4

## Receipt

eports/engineering/RECEIPT-minecraft-v0-local-prove-20260904-1314.json
