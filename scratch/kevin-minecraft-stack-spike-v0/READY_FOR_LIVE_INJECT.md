# READY_FOR_LIVE_INJECT

**Updated:** 2026-09-05 ~09:55 MT (America/Denver)
**Status:** Live stay+companion inject **blocked** while Minecraft.Windows UWP is mid-session.
**Marker:** `READY_FOR_LIVE_INJECT`

## Why blocked

`Minecraft.Windows.exe` was observed running on HESS-PC. Stay preflight refuses rejoin against the human UI session (same gate as gym `preflight-stay.cmd`).

## Owner close step (Matt)

1. Save / leave Realm from the Minecraft UWP client when convenient.
2. Fully close Minecraft (UWP) — do **not** ask Kevin to kill the process.
3. Double-click:
   - `scratch\kevin-minecraft-stack-spike-v0\rejoin-companion.cmd`
   - or gym stay: `scratch\kevin-minecraft-bedrock-v0\rejoin.cmd`
4. Join Realm as **hessmodee** (Xbox). Kevin joins as **kevinsk8erkid** only.

## What rejoin-companion does (when UI clear)

1. Preflight no `Minecraft.Windows.exe`
2. Gym NetherNet overlay `createClient` (protocol **2169** / **1.26.45**) — JOIN_OK path
3. Inject client into spike `createBotFromClient` (no gym package-lock mutate)
4. On spawn: GoalFollow toward Matt (`hessmodee` / display variants) + hostile-only guard + autoEat if plugin safe
5. Stay heartbeat — **no** FOLLOW_OK / COMBAT_OK claim without entity/receipt proof

## Unit / dry (safe anytime)

- `smoke-bridge.cmd` — dry inject fake client
- `smoke-companion-wire.cmd` — fake packets + NEG deny PvP Matt / hessmodee login

## Do not

- Kill Minecraft.Windows / Chat 18789 / Reader 19001
- Login as hessmodee for the bot
- Grief / PvP Matt
- Mutate `kevin-minecraft-bedrock-v0/package-lock.json`
- Claim live follow/combat until spawn+entity receipts
