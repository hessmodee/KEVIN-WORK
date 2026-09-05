# PLAN - Kevin Minecraft Realms co-op player (as Kevin's own account)

Date: 2026-09-04 ~23:15 MT (America/Denver) — update from ~14:42 / Bedrock lock ~15:05
Author: Grok Bot (HESS-PC) — teach-and-transfer
Audience: Matt / Davy / Kevin / Cursor agents
Auth: UNDYING GREEN+YELLOW `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
North-star: `docs/engineering/PLAN-kevin-north-star-max-2026-09-04.md` (**P2 Realms co-op**)
Teach-and-transfer: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`
Handover: `AI-HANDOVER.md` only (no GROK-HANDOVER). Execution: `inbox/CURRENT_TASK.md`.

## 0. End-state (Matt 2026-09-04)

Kevin plays Minecraft on Realms **with Matt** as **Kevin's own account** (fun coworker), not as Matt's account and not as a grief bot.

**Prefer:** invite Kevin to **Matt's existing Realm**. **No new paid Realms purchase**.

### Owner facts LOCKED (2026-09-04 ~23:12 MT)

| Fact | Value |
| --- | --- |
| Edition | **Bedrock LOCKED** (screenshots earlier; Mineflayer = NON-PATH) |
| Matt Xbox | **hessmodee** (Realm owner only — never bot creds) |
| Kevin gamertag | **kevinsk8erkid** (CORRECTED — not kevins8erkid) |
| Invite | **DONE** — kevinsk8erkid invited to HESSMODEE's Realm |
| Bed spawn | **DONE** — set at house |
| Purchase | None |

**Status this run:** Engineering max-progress toward join. Live auth waits on owner device-code. No invent Microsoft passwords. No hessmodee creds for bot. Chat 18789 / Reader 19001 untouched.

## 1. Stack (Bedrock path)

| Layer | Choice | Notes |
| --- | --- | --- |
| Protocol | `bedrock-protocol` + `prismarine-auth` | Device-code; profilesFolder = `credentials/kevin-minecraft/` |
| Java Mineflayer | **NON-PATH** for Realms | Keep `scratch/kevin-minecraft-v0` as Java gym only |
| Realms 26.10+ | **NetherNet / NETHERNET_JSONRPC gate** | PrismarineJS bedrock-protocol #717; nethernet work unfinished on main — may block live join after auth |

## 2. Ladder (tonight)

| Step | Status |
| --- | --- |
| A. Desktop list_folder | Other worker / observe |
| B. Bedrock scratch harden | IN FLIGHT — fail-closed realms-join + device-code scripts |
| C. Deps install | READY_FOR_OWNER_NPM if binder blocks agent |
| D. Device-code as kevinsk8erkid | READY_FOR_OWNER_DEVICE_CODE when deps OK |
| E. Realms join marker `KEVIN_REALMS_JOIN_OK` | After AUTH_CACHE_OK; may hit NETHERNET_GATE |
| F. Co-op etiquette skill stub | Teach: no grief, follow Matt, spawn at bed/house |

## 3. Scratch + credentials

- Scratch: `scratch/kevin-minecraft-bedrock-v0`
- Owner install: `install-deps.cmd` (double-click)
- Device-code: `node scripts/device-code-auth.js`
- Join: `node scripts/realms-join.js` (fail-closed without token)
- Token cache README: `credentials/kevin-minecraft/README.md` (no secrets in git)

## 4. Safety

- No grief; rate limits; Matt kick/uninvite = hard stop
- Credentials Kevin-local only; never git/MEMORY/HQ/receipts
- Never hessmodee for bot auth
- Never invent Kevin MS password
- Do not kill Chat 18789 / Reader 19001

## 5. READY status

**Primary owner blocker:** `READY_FOR_OWNER_DEVICE_CODE` (after deps) — Matt completes microsoft.com/link as **kevinsk8erkid**.

**If deps blocked in agent Shell:** `READY_FOR_OWNER_NPM` — double-click `scratch/kevin-minecraft-bedrock-v0/install-deps.cmd`.

**Possible post-auth blocker:** `NETHERNET_GATE` — document; do not invent workaround credentials.

## 8. Tonight max (2026-09-04 ~23:15 MT) — teach-and-transfer

**Gamertag LOCKED:** Kevin plays as **kevinsk8erkid** on **HESSMODEE's Realm**. Matt on Xbox as **hessmodee**. Bed spawn at house. Wait for Matt. No grief.

| Deliverable | Path |
| --- | --- |
| Recipe (join/auth/fail-closed, bed, etiquette) | `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md` |
| Etiquette knowledge stub | `knowledge/wiki/minecraft-realms-coop-etiquette.md` (live) + `docs/engineering/KEVIN-KNOWLEDGE-minecraft-realms-coop-etiquette-v1.md` |
| Optional GREEN etiquette pack | `inbox/skills/minecraft-realms-coop-etiquette-pack-v1.json` (docs/stage only; no live join) |
| Teach pointers | SOUL.md (live) / AGENTS.md / MEMORY.md |

**This worker:** teach-and-transfer only. **Other worker:** live Realm join/auth.
**Hard no unchanged:** no invent passwords; no purchases; do not kill Chat 18789 / Reader 19001; no GROK-HANDOVER; never act as hessmodee.

**Status:** **READY_FOR_COOP_WHEN_OTHER_WORKER_JOINS** — identity + etiquette taught; live join still other-worker gated.

## 9. Auth incident (2026-09-04 ~23:45 MT)

**Root cause:** Owner/agent READY card advertised `link?otc=CODE`. First-party Minecraft live client cannot complete remoteconnect consent → error on login.live.com oauth20_remoteconnect.

**Fix shipped:** `device-code-auth.js` writes `READY_FOR_OWNER_AUTH.md` with plain link + typed code only; added `sisu-auth.js` + `msal-device-auth.js`; cleared empty cache stubs.

**Matt next:** Phone → https://www.microsoft.com/link → type fresh code as kevinsk8erkid → AUTH_CACHE_OK → realms-join.js.

**Join status:** Not yet — blocked on fresh owner device-code (auth cache empty after clearing broken stubs).

## 10. Join attempt (2026-09-04 ~23:52 MT)

**AUTH_CACHE_OK = yes.** Matt completed device-code as **kevinsk8erkid** (Nintendo Switch title). Cache warm under `credentials/kevin-minecraft/`.

**Join result = NETHERNET_GATE.** `node scripts/realms-join.js` listed/picked **HESSMODEE's Realm**, then `Connect timed out` / `REALMS_JOIN_TIMEOUT` exit 4 (60s). Not `KEVIN_REALMS_JOIN_OK`.

| Token | Value |
| --- | --- |
| AUTH_CACHE_OK | yes |
| Join | NETHERNET_GATE (timeout) |
| KEVIN_REALMS_JOIN_OK | no |

**Residual:** protocol NetherNet / JSON-RPC (bedrock-protocol #717). Do not re-run device-code unless cache cleared. Receipt: `reports/engineering/RECEIPT-minecraft-bedrock-auth-join-nethernet-20260904-2352.md`.

**Status:** **AUTH_OK_JOIN_BLOCKED_NETHERNET** - owner auth complete; spawn gated on library support.

## 11. JOIN_OK proven (2026-09-05 ~01:12 MT)

| Token | Value |
| --- | --- |
| AUTH_CACHE_OK | yes |
| KEVIN_REALMS_JOIN_OK | **yes** (real) |
| Transport | nethernet / NETHERNET_JSONRPC |
| Version / protocol | 1.26.45 / **2169** (UWP 1.26.4501 matched) |
| Soft residual | late packet_violation_warning on close |
| In-world after prove | no (auto-close ~2s) |

Receipt: `reports/engineering/RECEIPT-minecraft-bedrock-realms-join-ok-20260905-0112.md`
Log pointer (local only): `scratch/kevin-minecraft-bedrock-v0/_realms-join-nethernet12-2169.log`
LESSON: `docs/engineering/LESSON-nethernet-realms-join-ok-2026-09-05.md`
RECIPE: `docs/engineering/RECIPE-nethernet-realms-overlay-v2.md`
Rejoin: `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd` (KEVIN_REALMS_STAY=1)

**Play loop:** wait house bed -> follow Matt -> chat -> invited build/mine -> fail-closed.
**Status:** JOIN_OK_TEACH_AND_TRANSFER - ready for next play session via rejoin.cmd.


