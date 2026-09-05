# KEVIN PLAYBOOK - Play with Matt (Minecraft Bedrock Realms) v1.4

**Updated:** 2026-09-05 ~08:24 MT
**Authority:** UNDYING GREEN+YELLOW teach/docs.
**Cold-start rule:** When Matt says "play a game with me" / "play Minecraft" / "join my Realm" / co-op, Kevin follows this checklist.
**Drift note:** Earlier overnight beats claimed v1.2/v1.3 stay/preflight sync; live file had lagged at v1.1 ~01:14 — this v1.4 absorbs stay harden + preflight + READY_FOR_PLAY operator path.

## 0. Identity lock (hard)

| Role | Tag / surface | Rule |
| --- | --- | --- |
| **Kevin** | **kevinsk8erkid** | Only play identity |
| **Matt** | **hessmodee** on **Xbox** | Partner / Realm owner - never bot-login |
| **Realm** | **HESSMODEE's Realm** | Existing invite; no purchase |
| **Home** | **Bed at the house** | Spawn / reunite point |

**NEVER** authenticate, join, chat, or act as **hessmodee**.

## 0b. READY_FOR_PLAY (honest)

Checklist: `docs/engineering/KEVIN-CHECKLIST-READY-FOR-PLAY-realms-2026-09-05.md`  
Operator card: `docs/engineering/KEVIN-OPERATOR-CARD-realms-close-mc-then-rejoin-v1.md`  
Status (no join): `scratch/kevin-minecraft-bedrock-v0/status-play-ready.cmd`

| State | Meaning |
| --- | --- |
| **PARTIAL** | JOIN_OK + teach + preflight proven; stay smoke deferred while Minecraft.Windows UI mid-session |
| **FULL** | Same + stay smoke PASS after UI clear (heartbeat under STAY=1) |
| Near stubs | eat/feed/brew/enchant = **not** live-proven — coach only |

**Never kill** `Minecraft.Windows.exe`. If preflight prints `KEVIN_REALMS_STAY_PREFLIGHT_BLOCKED_MC_UI`, wait for Matt to close the UI, then rejoin.

## 1. When Matt prompts "play ..."

1. Read this playbook + coop recipe + READY_FOR_PLAY checklist.
2. Optional: run `status-play-ready.cmd` (expect PARTIAL + BLOCKED_MC_UI if human client up).
3. Confirm AUTH_CACHE_OK (do not re-device-code unless cache empty).
4. If MC UI up → ask Matt to close it; **do not** taskkill; **do not** rejoin yet.
5. When clear → **one command:** `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd` (preflight + stay).
6. Expect marker `KEVIN_REALMS_JOIN_OK` (proven 2026-09-05 ~01:12 MT via NetherNet / protocol 2169).
7. Soft residual `packet_violation_warning` after JOIN_OK is non-blocking when stay=1 (heartbeat ~30s).
8. Proceed section 2 play loop.

## 2. In-world play loop (after JOIN_OK)

1. **Wait at house bed** - idle until Matt present / cues.
2. **Follow Matt** when invited; safe distance; no shortcuts through builds.
3. **Chat** - short friendly hello; rate-limit; never impersonate hessmodee.
4. **Mine / build** - only when Matt invites; agreed areas; no grief / chests / redstone.
5. **Death** -> house bed -> reunite.
6. **Fail-closed** on kick / auth fail / wrong-identity risk / purchase prompt.

Markers: `KEVIN_REALMS_JOIN_OK` -> then `KEVIN_REALMS_COOP_OK` when etiquette loop observed.

## 2b. Survival / craft / farm / build (teach)

If Matt asks to farm, craft tools/food, gather, or build from a picture: load `docs/engineering/KEVIN-PLAYBOOK-minecraft-survival-craft-farm-build-v1.md` (Layer A READY coach; B/C not live-proven). Blueprint PLAN: `docs/engineering/PLAN-kevin-minecraft-blueprint-from-image-v1.md`. Never fake castle/farm complete.

## 2c. SUPER PLAYER (self-care / animals / potions / enchant)

If Matt says care / feed / animals / potion / enchant / "super player": load `docs/engineering/KEVIN-PLAYBOOK-minecraft-super-player-v1.md`. READY = coach + join etiquette; Near = stubs not live-proven; never fake brew/enchant; never kill Matt pets; never hessmodee.

## 2d. Companion proactive / combat / build

If Matt says companion / fight / guard / stay close / help fight / build with me / do not AFK: load `docs/engineering/KEVIN-PLAYBOOK-minecraft-companion-proactive-combat-build-v1.md`. READY coach+join; Near stubs; Destination stack PLAN. No fake kills/builds; no PvP Matt; no grief; never hessmodee.

## 3. Join path truth (2026-09-05)

| Path | Stack | Status |
| --- | --- | --- |
| Protocol | bedrock-protocol + prismarine-auth + NetherNet overlay | **JOIN_OK proven** (2169 / 1.26.45) |
| Stay | STAY=1 + soft residual + heartbeat + preflight | **CODE READY**; smoke blocked while MC UI up |
| Client UI | MinecraftUWP + OCR/input | optional alternate; not required now that protocol works |

Rejoin command: `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd`  
Preflight: `scratch/kevin-minecraft-bedrock-v0/preflight-stay.cmd`  
Status: `scratch/kevin-minecraft-bedrock-v0/status-play-ready.cmd`  
Receipt JOIN_OK: `reports/engineering/RECEIPT-minecraft-bedrock-realms-join-ok-20260905-0112.md`

## 4. Desktop ladder (to open Minecraft UWP if needed)

Use `docs/engineering/KEVIN-PLAYBOOK-operate-desktop-apps-v1.md`.
Do not widen Chat tools.allow for UI click/type without proof bar.
Do **not** use Desktop kill/process tools against Minecraft.Windows for Realms stay.

## 5. Hard nos

- No hessmodee bot login; no invent passwords; no secrets in MEMORY/git/HQ.
- No purchases / marketplace.
- Do not stop Chat 18789 / Reader 19001 / Operator 19101.
- Never kill Minecraft.Windows; never rejoin while preflight BLOCKED_MC_UI.
- No Chat Minecraft tool until typed crossing.
- No fake Near-stub success (brew/enchant/feed).

## 6. Pointers

- READY_FOR_PLAY checklist: `docs/engineering/KEVIN-CHECKLIST-READY-FOR-PLAY-realms-2026-09-05.md`
- Operator card: `docs/engineering/KEVIN-OPERATOR-CARD-realms-close-mc-then-rejoin-v1.md`
- RECIPE overlay v2: `docs/engineering/RECIPE-nethernet-realms-overlay-v2.md`
- LESSON JOIN_OK: `docs/engineering/LESSON-nethernet-realms-join-ok-2026-09-05.md`
- LESSON stay soft residual: `docs/engineering/LESSON-realms-stay-packet-violation-soft-2026-09-05.md`
- LESSON preflight: `docs/engineering/LESSON-realms-stay-preflight-mc-ui-2026-09-05.md`
- Recipe coop: `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`
- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Eval: `docs/engineering/evals/EVAL-minecraft-realms-coop-etiquette-failclosed-v1.json`

