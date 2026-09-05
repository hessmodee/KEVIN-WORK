# KEVIN RECIPE - Bedrock Realms co-op as kevinsk8erkid v1.2 (JOIN_OK)

Authority: UNDYING GREEN+YELLOW.
Companion PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
Edition: **Bedrock LOCKED**. Mineflayer Realms = **NON-PATH**.
Updated: 2026-09-05 01:14 MT

## Goal

Kevin plays Bedrock Realms with Matt as **kevinsk8erkid** on **HESSMODEE's Realm**, beds at house spawn, waits/follows Matt, chats friendly, builds only when invited, fail-closes on auth/kick.

## Identity table (hard)

| Role | Gamertag / surface | Rule |
| --- | --- | --- |
| **Kevin play identity** | **kevinsk8erkid** | Kevin owns play as this tag only |
| **Matt** | **hessmodee** on **Xbox** | Co-op partner / Realm owner surface |
| **Realm** | **HESSMODEE's Realm** | Invite existing; no new purchase |
| **Spawn** | **Bed at the house** | After join / death: house bed is home |

**NEVER** authenticate, join, chat, or act as **hessmodee**.

## Current truth (2026-09-05 01:14 MT)

| Token | Value |
| --- | --- |
| Invite | DONE |
| House bed spawn | DONE |
| AUTH_CACHE_OK | **yes** |
| KEVIN_REALMS_JOIN_OK | **yes** (real ~01:12 MT) |
| Protocol | 2169 / version 1.26.45 (UWP 1.26.4501) |
| Soft residual | packet_violation_warning on close |

Receipt: `reports/engineering/RECEIPT-minecraft-bedrock-realms-join-ok-20260905-0112.md`
Log pointer (local): `_realms-join-nethernet12-2169.log`

## Recipe A - Join / Rejoin Realm (fail-closed)

1. Preconditions: Bedrock; kevinsk8erkid; invite DONE; AUTH_CACHE_OK.
2. Play session: `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd` (stay mode).
3. Prove-only: `node scripts/realms-join.js` (auto-exit ~2s).
4. Success marker: **KEVIN_REALMS_JOIN_OK**.
5. Missing token -> READY_FOR_OWNER_DEVICE_CODE.
6. Kick / uninvite -> hard stop; no reconnect loops.

## Recipe B - Wait at bed

Idle near house bed until Matt present / cues. Do not break or reclaim Matt bed.

## Recipe C - Follow Matt

Safe follow distance; no terrain grief shortcuts. AFK -> return to bed.

## Recipe D - Chat etiquette

Short friendly hello as kevinsk8erkid. Rate-limit. Never impersonate hessmodee.

## Recipe E - Mine / build (invited only)

Default idle/follow/wait. Act only when Matt asks. No grief/TNT/chest loot.

## Recipe F - Fail-closed matrix

| Signal | Action |
| --- | --- |
| No token | Stop; READY_FOR_OWNER_DEVICE_CODE |
| Timeout / gate | Document; cool retries |
| Kick / uninvite | Hard stop |
| Wrong identity risk | Abort |
| Purchase prompt | Refuse |

## Markers

- KEVIN_REALMS_JOIN_OK - in Realm
- KEVIN_REALMS_COOP_OK - joined + etiquette loop observed

## Hard no

- No invent passwords; no secrets in git/MEMORY/HQ/receipts
- No purchases; no hessmodee bot auth
- Do not stop Chat 18789 / Reader 19001
- No GROK-HANDOVER
