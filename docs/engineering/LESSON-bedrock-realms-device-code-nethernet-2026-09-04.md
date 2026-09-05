# LESSON: Bedrock Realms join needs device-code + may hit NetherNet (2026-09-04)

**At:** 2026-09-04 ~23:15 MT (update ~23:52 MT)
**Actor:** GrokBot-executor
**Result:** TEACH + PROVEN AUTH - invite/gamertag locked; AUTH_CACHE_OK achieved; live join hit NETHERNET_GATE

## One-liner

**kevinsk8erkid** device-code auth works (AUTH_CACHE_OK + Realm list/pick). Spawn still fails with REALMS_JOIN_TIMEOUT / **NETHERNET_GATE** (Realms 26.10+ / bedrock-protocol #717).

## Why it matters

- Mineflayer is Java-only (prior LESSON) - Bedrock stack is bedrock-protocol + prismarine-auth.
- Agent Shell may BLOCKED_BINDER package installs - owner double-click `install-deps.cmd`.
- Never use hessmodee credentials for the bot; never invent Kevin password.
- Gamertag spelling: **kevinsk8erkid** only (not kevins8erkid).
- First-party consent error = `?otc=` URL (see companion LESSON) - type code on plain microsoft.com/link.

## Owner steps (exact)

1. `scratch/kevin-minecraft-bedrock-v0/install-deps.cmd` -> DEPS_OK
2. `node scripts/device-code-auth.js` -> READY_FOR_OWNER_DEVICE_CODE
3. Browser: **https://www.microsoft.com/link** (no `?otc=`) + type user code; sign in as kevinsk8erkid
4. Wait AUTH_CACHE_OK
5. `node scripts/realms-join.js` -> KEVIN_REALMS_JOIN_OK or NETHERNET_GATE

## Evidence ~23:52 MT (HESS-PC)

1. Matt completed device-code as kevinsk8erkid (Nintendo Switch title client). Cache files under `credentials/kevin-minecraft/` (`6eb2d0_*`).
2. `realms-join.js` chose **HESSMODEE's Realm** using Kevin token cache (auth path proven).
3. Connect timed out 60s -> `REALMS_JOIN_TIMEOUT` exit 4 / documented **NETHERNET_GATE**. No KEVIN_REALMS_JOIN_OK.
4. Chat 18789 / Reader 19001 untouched.

## Residual / next

- Do **not** re-auth unless cache gone. Residual is protocol/NetherNet, not owner code typing.
- Watch PrismarineJS bedrock-protocol NetherNet / JSON-RPC work (#717); re-try `realms-join.js` when support lands.
- Optional: longer timeout / LAN BDS offline prove remains available via `offline-lan-join.js`.

## Companion

- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Scratch: `scratch/kevin-minecraft-bedrock-v0`
- Receipt: `reports/engineering/RECEIPT-minecraft-bedrock-auth-join-nethernet-20260904-2352.md`
- Prior fork LESSON: `docs/engineering/LESSON-mineflayer-java-not-bedrock-realms-fork-2026-09-04.md`
- First-party OTC LESSON: `docs/engineering/LESSON-bedrock-device-code-firstparty-otc-2026-09-04.md`
