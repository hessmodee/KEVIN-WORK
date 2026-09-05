# KEVIN RECIPE - Bedrock Realms co-op as kevinsk8erkid v1

Authority: UNDYING GREEN+YELLOW teach/docs. **No live Realm join in this recipe run.**
Companion PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
Edition: **Bedrock LOCKED**. Mineflayer Realms = **NON-PATH** (Java gym only).
Auth card: `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
Teach-and-transfer: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`

## Goal

Kevin plays Bedrock Realms **with Matt** as Kevin's own gamertag **kevinsk8erkid** on **HESSMODEE's Realm**, beds at the house spawn, waits for Matt, and never griefs. Fun coworker — not Matt's account, not a grief bot.

## Identity table (hard)

| Role | Gamertag / surface | Rule |
| --- | --- | --- |
| **Kevin play identity** | **kevinsk8erkid** (Kevin MS / Xbox on Omen) | Kevin owns play as this tag only |
| **Matt** | **hessmodee** on **Xbox** | Co-op partner; Realm host/member surface |
| **Realm** | **HESSMODEE's Realm** (Electric Boogaloo 2 / Hall of Heroes / Realm Hub) | Prefer invite to existing Realm |
| **Spawn** | **Bed at the house** | After join, return to / sleep at house bed; treat as home base |

**NEVER** authenticate, join, chat, or act as **hessmodee**. That identity is Matt's Xbox only.

## Join / auth / fail-closed (design — other worker owns live join)

Live join/auth is **out of scope for this worker**. Other worker handles join/auth when ready.

### Preconditions (all required before any live attempt elsewhere)

1. Edition = Bedrock (LOCKED).
2. Kevin MS account exists on Omen with Bedrock ownership matching Realm.
3. Gamertag **kevinsk8erkid** invited to HESSMODEE's Realm — **DONE** (owner invite).
4. Device-code / Kevin-local secret store ready — **no invent passwords**; secrets never in git, MEMORY, HQ, receipts, chat.
5. Matt window agreed (Matt online as hessmodee, or explicit async OK).

### Fail-closed (abort; do not retry-spam)

- Auth failure / device-code timeout / token missing
- Invite missing / kicked / uninvited (Matt kick = **hard stop**; no reconnect loops)
- NetherNet / signalling / transport unknown or error
- Wrong identity (anything that would act as hessmodee)
- Network errors without clear recovery
- Any prompt to invent, buy, or paste passwords into repo/docs

On fail: stop, record sanitized receipt (no secrets), leave Chat 18789 / Reader 19001 up, advance another authorized lane.

### Stack (Bedrock path; not Mineflayer)

- Candidate: `bedrock-protocol` + `prismarine-auth` (device-code; Kevin-local token cache).
- Local gym first: `scratch/kevin-minecraft-bedrock-v0` → marker `KEVIN_MC_BEDROCK_V0_OK` (localhost/BDS; no MS login).
- Live marker later (other worker): `KEVIN_REALMS_COOP_OK`.
- Mineflayer + flying-squid remains **Java side gym only** (`KEVIN_MC_V0_OK`) — does not prove Bedrock/Realms.

## Spawn / bed / house etiquette

1. After successful spawn in Realm: locate **house bed** (Matt's house / agreed bed).
2. Prefer sleeping / setting spawn at that bed so death returns home — **bed spawn at house** (**DONE** per owner).
3. Do not move Matt's bed, break the bed, or reclaim another player's bed without Matt asking.
4. If lost: chat a short hello to Matt, path home; do not dig random tunnels through builds.

## Co-op etiquette (standing)

- **Wait for Matt** before big projects, exploring far, or changing shared builds.
- Chat friendly; rate-limit messages; no spam.
- No grief: no TNT spam, no mass break/place, no inventory steal, no lava grief, no farm wreck.
- Do not take items from chests unless Matt says so.
- Build only in agreed areas; leave Matt's redstone/farms alone unless asked.
- If unsure: ask Matt in chat or idle near house.
- Matt can kick anytime — treat as hard stop.

## Hard no

- No live Realm join in **this** worker / this recipe apply
- No invent Microsoft / Xbox passwords
- No purchases (Minecraft, Realms, marketplace)
- Do not kill Chat 18789 / Reader 19001
- Do not use or spoof **hessmodee**
- No GROK-HANDOVER (canonical `AI-HANDOVER.md` only)
- No Chat Minecraft tool until typed crossing exists
- No secrets in MEMORY / PLAN / receipts / git

## Tonight max (2026-09-04)

Teach-and-transfer only: this recipe + PLAN gamertag lock + SOUL/AGENTS/MEMORY pointers + optional etiquette knowledge/GREEN stub. Live join = other worker.

## Cold-start pointer

Kevin next wake: play identity **kevinsk8erkid**; Matt **hessmodee** on Xbox; Realm HESSMODEE's; bed at house; wait for Matt; no grief; Bedrock stack / fail-closed; never hessmodee.

