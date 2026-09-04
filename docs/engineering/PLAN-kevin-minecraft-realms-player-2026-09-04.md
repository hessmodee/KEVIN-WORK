# PLAN - Kevin Minecraft Realms co-op player (as Kevin's own account)

Date: 2026-09-04 ~14:42 MT (America/Denver); **Bedrock LOCK amended 2026-09-04 ~15:05 MT**
Author: Grok Bot (HESS-PC inventory + prior Mineflayer v0 prove + Matt screenshot confirm)
Audience: Matt / Davy / Kevin / Cursor agents
Auth: UNDYING GREEN+YELLOW `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
North-star: `docs/engineering/PLAN-kevin-north-star-max-2026-09-04.md` (**P2 Realms co-op Bedrock LOCKED** — this PLAN)
Teach-and-transfer: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`
Handover: `AI-HANDOVER.md` only (no GROK-HANDOVER). Execution: `inbox/CURRENT_TASK.md`.
Prior prove: scratch/kevin-minecraft-v0 — Mineflayer + pathfinder; localhost offline **KEVIN_MC_V0_OK** PASS (~13:14 MT). Recipe `docs/engineering/KEVIN-RECIPE-mineflayer-scratch-v1.md`. LESSON `docs/engineering/LESSON-minecraft-v0-local-prove-2026-09-04.md`.
**Mineflayer Realms path: NON-PATH** (Java gym only). See LESSON `docs/engineering/LESSON-mineflayer-java-not-bedrock-realms-fork-2026-09-04.md`.

## 0. End-state (Matt 2026-09-04)

Kevin plays Minecraft on Realms **with Matt** as **Kevin's own account** (fun coworker), not as Matt's account and not as a grief bot.

**Prefer:** invite Kevin to **Matt's existing Realm**. **No new paid Realms purchase** without a separate named owner auth.

**Status this run: PLAN/docs/research only (YELLOW).** No live Realm join. No invent Microsoft passwords. No purchasing. No widen Desktop tools. Chat 18789 / Reader 19001 untouched.

## 1. Edition LOCKED — Bedrock (Matt confirmed 2026-09-04)

| Field | Value |
| --- | --- |
| **Edition** | **Bedrock LOCKED** (screenshot-confirmed by Matt; not Java) |
| Realm | HESSMODEE's Realm / Electric Boogaloo 2 / Hall of Heroes / Realm Hub |
| Matt play surface | Xbox — gamertag **hessmodee** |
| Kevin account model | **Kevin's own Microsoft account on the Omen PC** (built by Matt); Matt stays on Xbox as hessmodee |
| Mineflayer | **NON-PATH for Realms** — Java protocol only; keep as **side gym** (`scratch/kevin-minecraft-v0` / `KEVIN_MC_V0_OK`) |

| Edition | Protocol path | Mineflayer fit | Notes |
| --- | --- | --- | --- |
| Java Edition Realms | Java protocol | YES historically | **Not Matt's Realm** — do not pursue for co-op |
| **Bedrock Edition Realms** | Bedrock / RakNet (+ Realms 26.10+ NetherNet/JSON-RPC signalling) | **NO** | **ACTIVE PATH** — see §1.1 Bedrock stack |

LESSON: `docs/engineering/LESSON-mineflayer-java-not-bedrock-realms-fork-2026-09-04.md` (amended: edition LOCKED Bedrock; Mineflayer = side gym).

### 1.1 Bedrock stack candidates (research)

PRIMARY: bedrock-protocol + prismarine-auth (PrismarineJS MIT).
- Realms helpers need invite/ownership; device-code auth; Kevin-local token cache.
- NetherNet gate: Realms 26.10+ NETHERNET_JSONRPC (issue 717; PRs 533/735).
- Optional later high-level Bedrock bot layer; evaluate pin first.

SECONDARY: Script API @minecraft/server — world packs only; not co-player identity on Realms.
LOCAL GYM: BDS/offline localhost UDP 19132; marker KEVIN_MC_BEDROCK_V0_OK; no MS login.
NON-CANDIDATES: Mineflayer Realms; CUA primary; paid hosts; new Realm purchase.

### 1.2 Risks - ToS / auth / account safety

| Risk | Mitigation |
| --- | --- |
| ToS / automation | Device-code owner-attended; private invited Realm; Matt kick = hard stop |
| Account safety | Never use hessmodee for bot; Kevin MS on Omen; fail-closed |
| Secrets | Kevin-local cache only; never git/MEMORY/HQ/receipts |
| NetherNet churn | Pin versions; gate before Realm-ready claim |
| Grief | Rate limits; no TNT/mass break/inventory steal |
| Purchase | Engineering does not buy Realms/Minecraft |

## 2. Evidence already on disk (Java gym only — do not re-prove v0; does not prove Bedrock/Realms)

- Scratch: `scratch/kevin-minecraft-v0` (mineflayer ^4.38.0, mineflayer-pathfinder ^2.4.5, flying-squid ^1.12.0)
- Proof: offline localhost join, chat marker `KEVIN_MC_V0_OK`, quit, server stop
- Receipt: `reports/engineering/RECEIPT-minecraft-v0-local-prove-20260904-1314.json`
- Invariants held: no Microsoft login, no paid/public server, no Chat MC tool, ports 18789/19001 untouched

## 3. Ladder (A → F) — Bedrock Realms path

### A) Desktop `list_folder` LIVE (in flight elsewhere)

- Owner value: Chat can list a Desktop child folder via typed tool (supports launcher inventory later).
- Owner of this beat: **other worker** (do not race).
- This PLAN: observe only. Do **not** widen Desktop tools here.
- Gate: exact allowlist freeze; Chat 18789 / Reader 19001 stay up.

### B) Typed Desktop UI control pack (proof bar) — optional for launcher

- Optional path: typed UI to open Minecraft Launcher / join UI.
- **Primary play path is Bedrock protocol bot (C)**, not screenshot-click CUA.
- Proof bar (if pursued later): allowlisted launcher actions only; deny generic shell; rollback packet; **after** P0 Desktop live-prove GREEN.
- RED: no CUA enable; no Chat widen sneak; no invent credentials in UI automation.

### C) Bedrock stack scratch + auth design (engineering; FREE/SAFE until live auth)

| Substep | Scope | Auth zone |
| --- | --- | --- |
| C0 | **Mineflayer Realms = NON-PATH.** Keep Java gym for skills practice only | GREEN gym |
| C1 | Scaffold `scratch/kevin-minecraft-bedrock-v0` (README + later package pins; **no live auth**) | GREEN |
| C2 | Local BDS or offline bedrock-protocol join on localhost:19132; marker `KEVIN_MC_BEDROCK_V0_OK` | GREEN |
| C3 | Design authenticated Realms join for **Kevin MS on Omen**: device-code via prismarine-auth; secrets Kevin-local; NetherNet gate documented | YELLOW design / RED live until invite+account ready |
| C4 | Skills after join: chat, bounded move/look, fail-closed; optional high-level Bedrock bot layer later | GREEN/YELLOW |
| C5 | Script API: optional research only; not Realms co-player identity | GREEN research |

Fail-closed: no retry-spam; no silent offline→online; no credential in logs/receipts; abort live Realms if auth/invite/NetherNet gate unmet.

### D) Owner: create Kevin Microsoft + Minecraft ownership; invite to Matt Realm

**Owner phone / portal steps (Matt):**

1. Create **Kevin's own** Microsoft account (not Matt's login reused as Kevin).
2. Ensure Minecraft ownership matches Realm edition:
   - Java Realm → Java Edition ownership on Kevin's MS account
   - Bedrock Realm → Bedrock ownership on Kevin's MS account
3. **Prefer invite** Kevin's gamertag/username to **Matt's existing Realm** (no new paid Realms purchase without separate auth).
4. Deliver Kevin MS credentials into **Kevin-local secret store** on HESS-PC via CoS secret card / parent flow — never paste into git, MEMORY, HQ, Slack, or this PLAN.
5. Tell Kevin/CoS: **Java or Bedrock**, Realm invite done, gamertag visible.

**Engineering must not:** invent passwords; buy Realms; buy Minecraft; guess edition.

### E) Prove `KEVIN_REALMS_COOP_OK` with Matt online

Acceptance (live, only after D + Bedrock stack ready):

1. Kevin bot authenticates as Kevin's own MS/Xbox identity (not offline spoof; not hessmodee).
2. Joins Matt's Bedrock Realm (invite path).
3. Matt is online in-world (or agrees async window) — Xbox hessmodee.
4. Bot sends chat marker **`KEVIN_REALMS_COOP_OK`**, performs one safe hello (no grief), then idles or quits per Matt.
5. Receipt under `reports/engineering/` with edition=Bedrock, package versions, NetherNet/transport note — **no secrets**.
6. Chat 18789 / Reader 19001 still up; Desktop tools not widened.

### F) Safety

- No grief (no TNT spam, no mass break/place, no inventory steal).
- Rate limits on chat and actions; fail-closed on errors.
- Matt can kick / uninvite anytime — treat as hard stop; do not reconnect loops.
- Credentials: Kevin-local only; never git, MEMORY, HQ, receipts, PLAN bodies.
- No paid Realms purchase without separate named auth.
- Do not kill Chat 18789 / Reader 19001.
- Do not add Minecraft tool to Chat until a separate typed crossing exists.

## 4. Branch table (LOCKED)

| Matt says | Live path | Blocked |
| --- | --- | --- |
| **Bedrock (LOCKED)** | bedrock-protocol + prismarine-auth → invited Realm → E | Mineflayer Realms join |
| Java | N/A for this Realm | — |
| UNKNOWN | obsolete — edition confirmed | — |

## 5. This-run deliverables (FREE/SAFE)

| Artifact | Path |
| --- | --- |
| This PLAN (Bedrock LOCK) | `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md` |
| LESSON (Mineflayer NON-PATH) | `docs/engineering/LESSON-mineflayer-java-not-bedrock-realms-fork-2026-09-04.md` |
| MEMORY one-liner | `MEMORY.md` (top) |
| CURRENT_TASK pointer | `inbox/CURRENT_TASK.md` |
| North-star P2 update | `docs/engineering/PLAN-kevin-north-star-max-2026-09-04.md` |
| Scratch README only | `scratch/kevin-minecraft-bedrock-v0/README.md` (no live auth) |
| Receipt | `reports/engineering/RECEIPT-minecraft-bedrock-lock-20260904-1505.md` |
| Sanitized PR | amend https://github.com/hessmodee/KEVIN-WORK/pull/88 |

**Not this run:** live Realm join; invent MS passwords; purchase Realms/Minecraft; widen Desktop; kill Chat/Reader; GROK-HANDOVER; network login during auth experiments.

## 6. Next steps (split)

- **Next free engineering step:** scaffold/install scratch/kevin-minecraft-bedrock-v0 packages (bedrock-protocol, prismarine-auth) offline/local only; localhost BDS or offline join proof KEVIN_MC_BEDROCK_V0_OK; NetherNet gate + device-code auth design (no live Realm). Keep Java Mineflayer gym separate.
- **Next owner step:** (1) finish Kevin MS account on Omen + Bedrock ownership; (2) invite Kevin gamertag to existing Realm from Xbox/hessmodee; (3) device-code/secret-card for Kevin-local store — no new Realm purchase.

## 7. READY status

**READY_FOR_OWNER_KEVIN_MS_AND_REALM_INVITE** — edition **Bedrock LOCKED**; Mineflayer Realms = NON-PATH; live Realms blocked on Kevin Omen MS account + invite + Bedrock stack local prove (no purchase assumed).
