# PLAN - Kevin Minecraft Realms co-op player (as Kevin's own account)

Date: 2026-09-04 ~14:42 MT (America/Denver)
Author: Grok Bot (HESS-PC inventory + prior Mineflayer v0 prove)
Audience: Matt / Davy / Kevin / Cursor agents
Auth: UNDYING GREEN+YELLOW `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
North-star: `docs/engineering/PLAN-kevin-north-star-max-2026-09-04.md` (**P2 Realms co-op** — this PLAN)
Teach-and-transfer: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`
Handover: `AI-HANDOVER.md` only (no GROK-HANDOVER). Execution: `inbox/CURRENT_TASK.md`.
Prior prove: scratch/kevin-minecraft-v0 — Mineflayer + pathfinder; localhost offline **KEVIN_MC_V0_OK** PASS (~13:14 MT). Recipe `docs/engineering/KEVIN-RECIPE-mineflayer-scratch-v1.md`. LESSON `docs/engineering/LESSON-minecraft-v0-local-prove-2026-09-04.md`.

## 0. End-state (Matt 2026-09-04)

Kevin plays Minecraft on Realms **with Matt** as **Kevin's own account** (fun coworker), not as Matt's account and not as a grief bot.

**Prefer:** invite Kevin to **Matt's existing Realm**. **No new paid Realms purchase** without a separate named owner auth.

**Status this run: PLAN/docs only (YELLOW).** No live Realm join. No invent Microsoft passwords. No purchasing. No widen Desktop tools. Chat 18789 / Reader 19001 untouched.

## 1. HARD UNKNOWN — Java Realms vs Bedrock Realms

| Edition | Protocol path | Mineflayer fit | Notes |
| --- | --- | --- | --- |
| **Java Edition Realms** | Java protocol | **YES** — Mineflayer is Java Edition protocol | Primary path if Matt's Realm is Java |
| **Bedrock Edition Realms** | Bedrock / RakNet | **NO** — Mineflayer does not speak Bedrock | Needs a different stack (e.g. Bedrock-compatible bot) if Matt uses Bedrock |

**Edition of Matt's Realm: UNKNOWN until Matt says.** Do not guess in live apply. Document both branches below; mark **UNKNOWN** in receipts until Matt answers Java or Bedrock.

LESSON: `docs/engineering/LESSON-mineflayer-java-not-bedrock-realms-fork-2026-09-04.md`.

## 2. Evidence already on disk (do not re-prove v0)

- Scratch: `scratch/kevin-minecraft-v0` (mineflayer ^4.38.0, mineflayer-pathfinder ^2.4.5, flying-squid ^1.12.0)
- Proof: offline localhost join, chat marker `KEVIN_MC_V0_OK`, quit, server stop
- Receipt: `reports/engineering/RECEIPT-minecraft-v0-local-prove-20260904-1314.json`
- Invariants held: no Microsoft login, no paid/public server, no Chat MC tool, ports 18789/19001 untouched

## 3. Ladder (A → F)

### A) Desktop `list_folder` LIVE (in flight elsewhere)

- Owner value: Chat can list a Desktop child folder via typed tool (supports launcher inventory later).
- Owner of this beat: **other worker** (do not race).
- This PLAN: observe only. Do **not** widen Desktop tools here.
- Gate: exact allowlist freeze; Chat 18789 / Reader 19001 stay up.

### B) Typed Desktop UI control pack (proof bar) — optional for launcher

- Optional path: typed UI to open Minecraft Launcher / join UI.
- **Primary play path is protocol bot (C)**, not screenshot-click CUA.
- Proof bar (if pursued later): allowlisted launcher actions only; deny generic shell; rollback packet; **after** P0 Desktop live-prove GREEN.
- RED: no CUA enable; no Chat widen sneak; no invent credentials in UI automation.

### C) Harden Mineflayer (engineering; FREE/SAFE until auth)

| Substep | Scope | Auth zone |
| --- | --- | --- |
| C1 | Keep offline localhost + pathfinder skills (follow, gather, chat) in scratch | GREEN |
| C2 | Design authenticated join for **Kevin MS account** (Java branch): microsoft auth via Mineflayer supported auth path; secrets Kevin-local never git | YELLOW design / RED live until owner account exists |
| C3 | Skills: pathfinder, chat, basic build; rate limits; fail-closed on auth/network errors | GREEN/YELLOW |
| C4 | **Bedrock branch (if Matt says Bedrock):** stop Mineflayer Realms path; open separate Bedrock-stack PLAN — do not force Mineflayer | UNKNOWN until Matt |

Fail-closed: no retry-spam; no silent offline→online; no credential in logs/receipts; abort if edition UNKNOWN at live gate.

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

Acceptance (live, only after D + edition known):

1. Kevin bot authenticates as Kevin's own account (not offline spoof of Matt).
2. Joins Matt's Realm (invite path).
3. Matt is online in-world (or agrees async window).
4. Bot sends chat marker **`KEVIN_REALMS_COOP_OK`**, performs one safe pathfinder hello (no grief), then idles or quits per Matt.
5. Receipt under `reports/engineering/` with edition, versions, hashes — **no secrets**.
6. Chat 18789 / Reader 19001 still up; Desktop tools not widened.

### F) Safety

- No grief (no TNT spam, no mass break/place, no inventory steal).
- Rate limits on chat and actions; fail-closed on errors.
- Matt can kick / uninvite anytime — treat as hard stop; do not reconnect loops.
- Credentials: Kevin-local only; never git, MEMORY, HQ, receipts, PLAN bodies.
- No paid Realms purchase without separate named auth.
- Do not kill Chat 18789 / Reader 19001.
- Do not add Minecraft tool to Chat until a separate typed crossing exists.

## 4. Branch table (apply only after Matt answers)

| Matt says | Live path | Blocked |
| --- | --- | --- |
| **Java** | Mineflayer microsoft auth → Realms join → E | Bedrock tools |
| **Bedrock** | New Bedrock-stack PLAN; Mineflayer Realms = N/A | Mineflayer Realms join |
| **UNKNOWN** (default now) | Docs + scratch skills only | Any live Realms join |

## 5. This-run deliverables (FREE/SAFE)

| Artifact | Path |
| --- | --- |
| This PLAN | `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md` |
| LESSON | `docs/engineering/LESSON-mineflayer-java-not-bedrock-realms-fork-2026-09-04.md` |
| MEMORY one-liner | `MEMORY.md` (top) |
| CURRENT_TASK pointer | `inbox/CURRENT_TASK.md` |
| North-star P2 update | `docs/engineering/PLAN-kevin-north-star-max-2026-09-04.md` |
| Sanitized PR | hessmodee/KEVIN-WORK (docs only) |

**Not this run:** live Realm join; invent MS passwords; purchase Realms/Minecraft; widen Desktop; kill Chat/Reader; GROK-HANDOVER.

## 6. Next steps (split)

- **Next free engineering step:** harden scratch skills (pathfinder/chat/build) + authenticated-join **design** for Java branch; keep fail-closed; edition gate stub that refuses live Realms until Matt says Java|Bedrock. Optional: observe Desktop list_folder prove (A) without racing.
- **Next owner phone step:** (1) tell Kevin **Java or Bedrock** for the Realm Matt wants; (2) create Kevin MS + matching Minecraft ownership; (3) invite Kevin to existing Realm; (4) secret-card Kevin credentials to HESS-PC Kevin-local store.

## 7. READY status

**READY_FOR_OWNER_EDITION_AND_ACCOUNT** — PLAN/docs landed; live Realms blocked on Matt edition answer + Kevin account + invite (no purchase assumed).
