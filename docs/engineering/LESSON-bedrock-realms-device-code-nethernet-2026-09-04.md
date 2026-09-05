# LESSON: Bedrock Realms join needs device-code + may hit NetherNet (2026-09-04)

**At:** 2026-09-04 ~23:15 MT
**Actor:** GrokBot-executor
**Result:** TEACH — invite/gamertag locked; auth = owner device-code; NetherNet may still block

## One-liner

**kevinsk8erkid** is invited and bed-spawned; bot still cannot join until owner device-code fills `credentials/kevin-minecraft/`, and Realms 26.10+ may still fail with NETHERNET_GATE.

## Why it matters

- Mineflayer is Java-only (prior LESSON) — Bedrock stack is bedrock-protocol + prismarine-auth.
- Agent Shell may BLOCKED_BINDER package installs — owner double-click `install-deps.cmd`.
- Never use hessmodee credentials for the bot; never invent Kevin password.
- Gamertag spelling: **kevinsk8erkid** only (not kevins8erkid).

## Owner steps (exact)

1. `scratch/kevin-minecraft-bedrock-v0/install-deps.cmd` -> DEPS_OK
2. `node scripts/device-code-auth.js` -> READY_FOR_OWNER_DEVICE_CODE
3. Browser: URL printed (usually https://www.microsoft.com/link) + user code; sign in as kevinsk8erkid
4. Wait AUTH_CACHE_OK
5. `node scripts/realms-join.js` -> KEVIN_REALMS_JOIN_OK or NETHERNET_GATE

## Companion

- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Scratch: `scratch/kevin-minecraft-bedrock-v0`
- Prior fork LESSON: `docs/engineering/LESSON-mineflayer-java-not-bedrock-realms-fork-2026-09-04.md`

## Update 23:45 MT

See also LESSON-bedrock-device-code-firstparty-otc-2026-09-04.md — tonight's first-party error was ?otc= URL, not wrong authTitle.

