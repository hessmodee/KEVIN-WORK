# KEVIN RECIPE - Bedrock Realms co-op as kevinsk8erkid v1.1 (deepen teach)

Authority: UNDYING GREEN+YELLOW teach/docs. **No live Realm join in this teach worker.**
Companion PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
Edition: **Bedrock LOCKED**. Mineflayer Realms = **NON-PATH** (Java gym only).
Auth card: `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
Teach-and-transfer: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`
Updated: 2026-09-05 00:05 MT

## Goal

Kevin plays Bedrock Realms **with Matt** as **kevinsk8erkid** on **HESSMODEE's Realm**, beds at the house spawn, waits for / follows Matt, chats friendly, does basic mine/build only when invited, and **fail-closes** on auth/kick/NetherNet. Fun coworker — not Matt's account, not a grief bot.

## Identity table (hard)

| Role | Gamertag / surface | Rule |
| --- | --- | --- |
| **Kevin play identity** | **kevinsk8erkid** | Kevin owns play as this tag only |
| **Matt** | **hessmodee** on **Xbox** | Co-op partner / Realm owner surface |
| **Realm** | **HESSMODEE's Realm** | Invite existing; no new purchase |
| **Spawn** | **Bed at the house** | After join / death: house bed is home |

**NEVER** authenticate, join, chat, or act as **hessmodee**.

## Current truth (2026-09-05 00:05 MT)

| Token | Value |
| --- | --- |
| Invite | DONE |
| House bed spawn | DONE |
| AUTH_CACHE_OK | **yes** (do not re-run device-code unless cache empty) |
| KEVIN_REALMS_JOIN_OK | **no** — last result **NETHERNET_GATE** / REALMS_JOIN_TIMEOUT |
| Overnight priority | **Realms co-op readiness = P0** (teach + be ready when join clears) |

Receipt: `reports/engineering/RECEIPT-minecraft-bedrock-auth-join-nethernet-20260904-2352.md`

## Recipe A — Join Realm (fail-closed)

Live join is owned by the join worker / Matt window. Teach lane does **not** live-join.

1. Preconditions: Bedrock LOCKED; gamertag kevinsk8erkid; invite DONE; AUTH_CACHE_OK; Matt online or explicit async OK.
2. From `scratch/kevin-minecraft-bedrock-v0`: `node scripts/realms-join.js`
3. Success marker: **`KEVIN_REALMS_JOIN_OK`** (then proceed Recipe B).
4. Known non-success: **`NETHERNET_GATE`** / timeout → document; do **not** invent credentials or hessmodee fallback; do **not** spam retries.
5. Missing token → READY_FOR_OWNER_DEVICE_CODE (owner only; microsoft.com/link as kevinsk8erkid).
6. Kick / uninvite → **hard stop**; no reconnect loops.

Stack: `bedrock-protocol` + `prismarine-auth`. Mineflayer = NON-PATH for Realms.

## Recipe B — Wait at bed (house spawn)

On / after join success (or when already in-world):

1. Locate **house bed** (Matt's house / agreed bed). Spawn already set at house (**DONE**).
2. Idle near bed / front of house until Matt is present or gives a chat cue.
3. Do **not** move, break, or reclaim Matt's bed.
4. If lost: short chat to Matt ("hey at house?") then path home — no random tunnel through builds.
5. Marker mindset: **wait-at-bed ready** before any mine/build.

## Recipe C — Follow Matt

1. When Matt (hessmodee) is visible / chats "follow" / starts moving: stay within safe follow distance.
2. Prefer walking paths Matt uses; do not break terrain just to shortcut through builds.
3. If Matt AFK: return to house bed idle (Recipe B).
4. If Matt kicks or says stop: stop immediately (fail-closed).

## Recipe D — Chat etiquette

1. On join / ready: one short friendly hello as kevinsk8erkid (e.g. "hey matt — ready at house").
2. Rate-limit; no spam, no ALL CAPS floods, no command spam.
3. Ask before taking from chests, changing redstone, or building on shared plots.
4. Never impersonate hessmodee in chat or signs.

## Recipe E — Mine / build basics (invited only)

1. Default = **idle / follow / wait**. Mining/building only after Matt asks or agrees.
2. Mine only in agreed areas; leave farms, redstone, storage, and decorative builds alone.
3. Place blocks only in agreed plots; no lava/water grief; no TNT.
4. Do not empty chests or hoppers. If inventory full: ask Matt or deposit only where he points.
5. Death: respawn at house bed → reunite with Matt.

## Recipe F — Fail-closed matrix

| Signal | Action | Do not |
| --- | --- | --- |
| No token / auth fail | Stop; READY_FOR_OWNER_DEVICE_CODE | Invent password; use hessmodee |
| NETHERNET_GATE / timeout | Document; cool retries | Claim KEVIN_REALMS_JOIN_OK |
| Kick / uninvite | Hard stop | Reconnect loops |
| Wrong identity risk | Abort | Continue as hessmodee |
| Purchase / marketplace prompt | Refuse | Buy anything |
| Urge to kill Chat/Reader | Refuse | Touch ports 18789 / 19001 |

On fail: sanitized receipt (no secrets); leave Chat/Reader up; advance another authorized lane.

## Markers

- `KEVIN_REALMS_JOIN_OK` — in Realm
- `KEVIN_REALMS_COOP_OK` — joined + etiquette loop observed (wait/follow/chat; no grief)
- Teach-only workers never claim live join success

## Hard no

- No live Realm join in **this** teach worker
- No invent passwords; no secrets in git/MEMORY/HQ/receipts
- No purchases; no hessmodee bot auth
- Do not kill Chat 18789 / Reader 19001
- No GROK-HANDOVER (`AI-HANDOVER.md` only)
- No Chat Minecraft tool until typed crossing exists

## Cold-start pointer

Overnight **P0 = Realms**: AUTH_CACHE_OK; join blocked NETHERNET_GATE until library clears; when join works be ready — house bed → wait → follow Matt → chat → invited mine/build → fail-closed. Identity **kevinsk8erkid** only.
