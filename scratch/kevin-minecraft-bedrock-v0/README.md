# scratch/kevin-minecraft-bedrock-v0

Authority: FREE/SAFE scaffold + device-code design. UNDYING GREEN+YELLOW.
Companion PLAN: docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md
Edition: Bedrock LOCKED. Gamertag: kevinsk8erkid (Matt Xbox / Realm owner: hessmodee).

## Goal

Kevin joins Matts existing Bedrock Realm (HESSMODEEs Realm) as kevinsk8erkid via bedrock-protocol + prismarine-auth device-code. Not Mineflayer. Not hessmodee credentials.

## Owner facts (2026-09-04 ~23:12 MT)

- Invite: DONE (kevinsk8erkid invited to HESSMODEEs Realm)
- Bed spawn: set at house
- No new paid Realm

## Stack

- bedrock-protocol ΓÇö Bedrock/RakNet client; realms pickRealm helper
- prismarine-auth ΓÇö Xbox/Microsoft device-code; token cache under credentials/kevin-minecraft/
- Realms 26.10+ may require NetherNet / NETHERNET_JSONRPC (PrismarineJS bedrock-protocol issue 717)

## Scripts

- install-deps.cmd ΓÇö Owner double-click to install deps + DEPS_OK
- node scripts/check-deps.js ΓÇö require deps
- node scripts/offline-lan-join.js ΓÇö LAN/BDS offline prove -> KEVIN_MC_BEDROCK_V0_OK
- node scripts/device-code-auth.js ΓÇö READY_FOR_OWNER_DEVICE_CODE as kevinsk8erkid
- node scripts/realms-join.js ΓÇö fail-closed without token; KEVIN_REALMS_JOIN_OK

## Auth token cache

- Path: credentials/kevin-minecraft/ (profilesFolder)
- README only in git; never invent password; never use hessmodee

## Hard no

- No live join without owner device-code
- No purchase; no Chat Minecraft tool; no kill Chat 18789 / Reader 19001
- Mineflayer Java gym = NON-PATH for Realms

## Auth failure note (2026-09-04 night)

First-party consent error = opened `microsoft.com/link?otc=...`. Fix: open plain `https://www.microsoft.com/link` and **type** the code. See `READY_FOR_OWNER_AUTH.md`.

Scripts: `device-code-auth.js` (primary), `sisu-auth.js`, `msal-device-auth.js` (last resort).
