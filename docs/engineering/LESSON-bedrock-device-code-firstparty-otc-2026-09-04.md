# LESSON: Bedrock device-code first-party error = ?otc= URL (2026-09-04)

**At:** 2026-09-04 ~23:45 MT
**Actor:** GrokBot-executor
**Result:** TEACH + FIX - clientId was fine; URL shape caused first-party consent fail

## One-liner

`Titles.MinecraftNintendoSwitch` (`00000000441cc96b`) + live + Nintendo is the correct Bedrock device-code client; opening `microsoft.com/link?otc=CODE` hits `oauth20_remoteconnect` and fails with first-party consent. Type the code on plain `https://www.microsoft.com/link`.

## Evidence

1. Matt code LEUVSQN6 via oauth20_remoteconnect → "application is a first party application, the user does not have consent..."
2. MultiMC/Prism community: embedding OTC in URL triggers the same first-party pre-auth error for Microsoft first-party client IDs.
3. Later code Y69M3S274 → "That code didn't work" + FetchError ECONNRESET during Xbox Live — expired/wrong code / network, not wrong clientId.

## Owner steps (exact)

1. Kill stale `node scripts/device-code-auth.js` if any.
2. `cd scratch/kevin-minecraft-bedrock-v0` → `node scripts/device-code-auth.js`
3. Phone: open **https://www.microsoft.com/link** (no query string)
4. Sign in **kevinsk8erkid** only; type code; wait `AUTH_CACHE_OK`
5. `node scripts/realms-join.js` → `KEVIN_REALMS_JOIN_OK` or `NETHERNET_GATE`

## Alternates

- sisu: `node scripts/sisu-auth.js` (same live client, sisu XBL)
- msal: `node scripts/msal-device-auth.js` (last resort; weaker title tokens)
- Omen browser: see `READY_FOR_OWNER_AUTH.md` request_box_help note

## Companion

- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Owner card: `scratch/kevin-minecraft-bedrock-v0/READY_FOR_OWNER_AUTH.md`
- Prior: `docs/engineering/LESSON-bedrock-realms-device-code-nethernet-2026-09-04.md` (still valid for NetherNet gate)
