# PLAN — Kevin Google Drive read-only bridge (YELLOW)

**Date:** 2026-09-04 (wrote ~08:59 MT; END STATE lock ~09:01 MT)  
**Author:** Grok Bot (HESS-PC workspace plan only)  
**Audience:** Matt / Davy / Kevin / Cursor slack agents  
**Status:** **YELLOW PLAN ONLY** — **NO OAuth**, **NO Kevin-local Google install**, **NO Desktop/Supervisor apply fights**.  
**Owner updates (same day):** (1) Kevin must eventually have **HIS OWN** Google Drive access — not only Chief of Staff (CoS) proxy. (2) **END STATE:** Kevin stands alone without CoS/Matt/other AIs; Kevin-owned Drive is **mandatory destination**; CoS connector is **interim only**; **teach-and-transfer every step**.

---

## 0) END STATE (locked)

**Kevin stands alone.** When this faculty is done, Kevin on HESS-PC can read Matt-approved Drive material **without** Chief of Staff, Cursor, Grok Bot MCP, or any other AI in the loop.

| Locked rule | Meaning |
|-------------|---------|
| **Mandatory destination** | Kevin-owned read-only Drive access on HESS-PC (local sync and/or typed faculty with **Kevin-local secrets**). Not optional polish. |
| **CoS = interim only** | Grok Bot / CoS Google Drive connector may curate sanitized packs **now**, but must never be treated as the permanent faculty. |
| **No forever-proxy** | "CoS will just keep reading Drive for Kevin" is an explicit non-end-state. |
| **Teach-and-transfer every step** | Each yellow gate, interim pack, sync path, and faculty design ships with LESSON/receipt/teach notes Kevin can re-run alone (`KEVIN-TEACH-AND-TRANSFER-RULE-v1`). No tribal CoS-only knowledge. |
| **Independence test** | Destination proven only when Kevin can allowlisted-read → Knowledge query → audit receipt **with CoS offline**. |

Interim work (option D) is allowed **only** if labeled `INTERIM_COS_CURATED` and paired with a teach note pointing at the Kevin-owned path (A→C).

---

## 1) Why (owner value)

Matt's important project/goal/need docs live in **Google Drive**. Kevin's north-star job is to be a durable local coworker who actually knows what Matt is building toward — without Matt re-explaining every wake.

**Owner value if done right:**
- Kevin learns projects, goals, and constraints from Matt's source-of-truth docs.
- Cuts CoS / Cursor re-briefing tax; improves continuity after restarts and lean MEMORY.
- Priority when appropriate/safe: after P0 Desktop/routing live-apply is healthy — high-leverage Knowledge faculty, not a shiny connector demo.
- **Ownership:** CoS already has a Google Drive connector for the user. That is **not** Kevin-local access on HESS-PC. Forever-proxy keeps Kevin blind when CoS is offline and blocks true coworker agency — incompatible with END STATE.

**Non-goals this plan:**
- Write/upload/share/delete in Drive.
- Full-account crawl.
- Publishing raw Drive contents to public HQ.
- Installing OAuth on Kevin while Desktop/Supervisor apply workers are racing.

---

## 2) Safety (read-only first)

Hard rules before any implementation:

| Rule | Requirement |
|------|-------------|
| **Read-only first** | No Drive write, move, share, or delete from Kevin. Destination faculty = read (+ local cache/ingest) only until a later RED-gated write plan exists. |
| **Deny secrets/keys** | Allowlist excludes credential dirs, `.env`, keystores, password exports, tax/banking dumps, private keys, OAuth client secrets, gateway tokens. Ingest filter denies known secret patterns; quarantine on hit. |
| **No public HQ publish** | Drive-derived content stays in Kevin Knowledge / private reports. Never sanitize-fail into public `dashboard-state` / HQ Talk / CDN. |
| **Allowlist folders** | Explicit folder IDs / synced path roots only (Matt-approved). Default deny everything else. Expand allowlist by owner edit, not agent discovery. |
| **Audit** | Every list/read/ingest emits a receipt: timestamp, folder/path, file id/name hash, bytes, actor (`KEVIN_OWNED` vs `INTERIM_COS_CURATED`), deny reasons. Retain under `reports/engineering/` (private). |
| **Kevin-owned secrets (destination)** | Credentials live in **Kevin-local secret store** on HESS-PC — not MEMORY, HQ, git, or CoS vaults. CoS must not be the long-term holder of Kevin's Drive token. |
| **Blast radius** | Reader/Operator/Chat stay split. Drive faculty = typed capability with deny-by-default tool policy. |
| **Teach-and-transfer** | Every gate/apply step leaves a LESSON or recipe Kevin can execute without CoS. |

Yellow means: plan + gates + optional dry receipts. Green apply of sync/OAuth waits for P0 clear + owner go-ahead on allowlist.

---

## 3) Options ranked

### A — Drive for Desktop sync + Knowledge ingest (allowlisted paths)
- Matt runs Google Drive for Desktop; selected folders sync to a local path on HESS-PC.
- Kevin Knowledge ingest watches **allowlisted local paths only** (rebuild-before-requery discipline).
- **Pros:** No custom OAuth faculty yet; OS sync handles auth; Kevin owns the local read path; fits Windows coworker model; teachable as path+ingest recipe.
- **Cons:** Depends on Desktop client health; sync lag; still need path allowlist + secret deny + audit; not a typed Drive API faculty.
- **Fit:** First Kevin-local Destination step once Desktop apply P0 is calm. **On the mandatory Destination path.**

### B — rclone read-only
- rclone remote with read-only scope / restricted token; pull allowlisted folders into staging; ingest.
- **Pros:** Scriptable, auditable, good sync receipts; Kevin-local credentials.
- **Cons:** Another binary + token lifecycle; easy to mis-scope; overlaps A unless Desktop sync unavailable.
- **Fit:** Fallback if A blocked. Still Kevin-owned (acceptable Destination variant).

### C — Typed Kevin Drive faculty (API read-only)
- First-class OpenClaw/Kevin tool: `drive_list` / `drive_read` over allowlisted folder IDs; Kevin-local OAuth secrets; audit receipts; Knowledge ingest hooks.
- **Pros:** True Kevin-owned Destination; precise allowlist; works with CoS fully offline; teach-transfer friendly.
- **Cons:** OAuth/install + token refresh + secret hygiene; must not race Desktop/Supervisor apply; highest eng cost.
- **Fit:** **Durable Destination end-state** after A proves value and P0 is stable. **Mandatory.**

### D — Near-term CoS curates sanitized Matt context pack → Kevin Knowledge
- CoS (Grok Bot MCP Drive) reads Matt-approved folders, sanitizes, drops bounded pack into Kevin Knowledge.
- **Pros:** Value **now** without Kevin OAuth; no Desktop-apply fight; CoS already has connector.
- **Cons:** **Not Kevin-owned.** Kevin stays dependent on CoS. Fails END STATE independence test alone.
- **Fit:** **Interim bridge only** while P0 finishes. Must ship with teach note + Destination backlog pointer.

**Explicit non-options:** CoS MCP Drive as permanent faculty; undocumented one-off CoS pastes with no teach-transfer.

---

## 4) Recommendation

**Destination (mandatory — Kevin stands alone):**
1. **A first** — Drive for Desktop sync + allowlisted Knowledge ingest (Kevin-local proof, minimal new auth).
2. **Then C** — typed Kevin Drive faculty with Kevin-local secrets, folder allowlist, audit (durable END STATE).
3. **B** only if A is blocked.

**Interim (now / when attention allows):** **D** — CoS curated sanitized pack → Knowledge, labeled `INTERIM_COS_CURATED`, with teach-and-transfer note toward A/C. Does **not** satisfy END STATE alone.

**Order (do not invert):**
1. Do not block **P0 Desktop/routing live apply**.
2. Optional interim **D** (docs/Knowledge only) + teach note.
3. Yellow gates for **A** (paths, deny, audit schema) — still no OAuth fight.
4. After P0 + A proof: design/apply **C** with Kevin-local secrets.
5. Independence proof: CoS offline, Kevin still reads allowlisted material.

**Do not:** Install OAuth on Kevin yet while Desktop/Superv apply workers are racing.

---

## 5) Yellow gates / proof bar

| Gate | Proof |
|------|-------|
| **Y-G1 Allowlist** | Written allowlist: folder names/IDs or local sync roots Matt approved; default-deny stated. Teach note so Kevin can re-read the allowlist contract. |
| **Y-G2 Secret deny** | Deny list + fixture scan (fake `.env` / keys) → DENY receipt; no ingest. |
| **Y-G3 HQ scrub** | Drive-derived text never appears in public HQ publish path. |
| **Y-G4 Audit schema** | Sample receipt JSON + dry receipt writer (no live Drive); actor field distinguishes `INTERIM_COS_CURATED` vs `KEVIN_OWNED`. |
| **Y-G5 Knowledge boundary** | Ingest uses rebuild-before-requery; packs tagged interim vs owned. |
| **Y-G6 P0 clear** | Desktop/routing live apply not racing; Maintenance/Supervisor apply workers not contested. |
| **Y-G7 Destination ownership** | Design note: Kevin-local secret location; CoS token not reused as Kevin long-term credential. |
| **Y-G8 Teach-and-transfer** | Each landed step has LESSON/recipe Kevin can run without CoS (`KEVIN-TEACH-AND-TRANSFER-RULE-v1`). |
| **Y-G9 Standalone proof (Destination)** | CoS offline; Kevin allowlisted-read → Knowledge hit → audit receipt. **Required to call END STATE done.** |

**Interim D bar (lighter):** sanitized pack in Knowledge; receipt; no secrets; no HQ leak; MEMORY one-liner that it is interim; teach pointer to A/C.

**Destination A/C bar (later green):** allowlisted read of ≥1 real Matt folder → Knowledge query returns project/goal fact → audit → still read-only → **Y-G9**.

---

## 6) Not ahead of P0 Desktop / routing live apply

- This plan is **YELLOW backlog**, not a competing apply lane.
- Do **not** touch Desktop crossing apply, Supervisor apply, Maintenance desired-state pins, or gateway tokens for Drive work yet.
- Do **not** open OAuth browser flows on HESS-PC for Kevin until Y-G6 + Matt allowlist.
- CoS interim **D** may proceed as docs/Knowledge curation only — no Kevin secret install, no Desktop fight.
- If Desktop/Superv workers are mid-apply: **stop at this PLAN**; resume gates when idle.

---

## 7) Recommended first step (after this PLAN)

While P0 Desktop/routing apply remains the live lane: start **interim D design only** — Matt names 1–3 allowlisted Drive folders for CoS to sanitize into a Kevin Knowledge pack (`INTERIM_COS_CURATED`), with secret-deny + no-HQ-publish checklist + **teach-and-transfer note** pointing at Kevin-owned A→C. **Do not** OAuth/install on Kevin. Parallel: draft Y-G1 allowlist stub for eventual Kevin-owned **A**.

---

## 8) Pointers

- Workspace plan: `docs/engineering/PLAN-kevin-google-drive-readonly-bridge-2026-09-04.md`
- Teach rule: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`
- Related: Knowledge rebuild LESSON; HQ scrub / no-secrets-in-public; Owner undying GREEN+YELLOW auth (plan/gates OK; RED reserved).
- CoS Drive connector ≠ Kevin-local HESS-PC access; interim ≠ END STATE.

---

*End PLAN — yellow only; END STATE locked: Kevin stands alone.*
