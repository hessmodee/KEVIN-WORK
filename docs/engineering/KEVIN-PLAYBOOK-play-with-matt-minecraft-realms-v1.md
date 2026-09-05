# KEVIN PLAYBOOK - Play with Matt (Minecraft Bedrock Realms) v1.1

**Updated:** 2026-09-05 ~01:14 MT
**Authority:** UNDYING GREEN+YELLOW teach/docs.
**Cold-start rule:** When Matt says "play a game with me" / "play Minecraft" / "join my Realm" / co-op, Kevin follows this checklist.

## 0. Identity lock (hard)

| Role | Tag / surface | Rule |
| --- | --- | --- |
| **Kevin** | **kevinsk8erkid** | Only play identity |
| **Matt** | **hessmodee** on **Xbox** | Partner / Realm owner - never bot-login |
| **Realm** | **HESSMODEE's Realm** | Existing invite; no purchase |
| **Home** | **Bed at the house** | Spawn / reunite point |

**NEVER** authenticate, join, chat, or act as **hessmodee**.

## 1. When Matt prompts "play ..."

1. Read this playbook + `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`.
2. Confirm AUTH_CACHE_OK (do not re-device-code unless cache empty).
3. Rejoin with stay: `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd`
4. Expect marker `KEVIN_REALMS_JOIN_OK` (proven 2026-09-05 ~01:12 MT via NetherNet / protocol 2169).
5. Soft residual packet_violation_warning on close is non-blocking if JOIN_OK already printed.
6. Proceed section 2 play loop.

## 2. In-world play loop (after JOIN_OK)

1. **Wait at house bed** - idle until Matt present / cues.
2. **Follow Matt** when invited; safe distance; no shortcuts through builds.
3. **Chat** - short friendly hello; rate-limit; never impersonate hessmodee.
4. **Mine / build** - only when Matt invites; agreed areas; no grief / chests / redstone.
5. **Death** -> house bed -> reunite.
6. **Fail-closed** on kick / auth fail / wrong-identity risk / purchase prompt.

Markers: `KEVIN_REALMS_JOIN_OK` -> then `KEVIN_REALMS_COOP_OK` when etiquette loop observed.

## 3. Join path truth (2026-09-05 ~01:14 MT)

| Path | Stack | Status |
| --- | --- | --- |
| Protocol | bedrock-protocol + prismarine-auth + NetherNet overlay | **JOIN_OK proven** (2169 / 1.26.45) |
| Client UI | MinecraftUWP + OCR/input | optional alternate; not required now that protocol works |

Rejoin command: `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd`
Receipt: `reports/engineering/RECEIPT-minecraft-bedrock-realms-join-ok-20260905-0112.md`

## 4. Desktop ladder (to open Minecraft UWP if needed)

Use `docs/engineering/KEVIN-PLAYBOOK-operate-desktop-apps-v1.md`.
Do not widen Chat tools.allow for UI click/type without proof bar.

## 5. Hard nos

- No hessmodee bot login; no invent passwords; no secrets in MEMORY/git/HQ.
- No purchases / marketplace.
- Do not stop Chat 18789 / Reader 19001.
- No Chat Minecraft tool until typed crossing.

## 6. Pointers

- RECIPE overlay v2: `docs/engineering/RECIPE-nethernet-realms-overlay-v2.md`
- LESSON JOIN_OK: `docs/engineering/LESSON-nethernet-realms-join-ok-2026-09-05.md`
- Recipe coop: `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`
- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Eval: `docs/engineering/evals/EVAL-minecraft-realms-coop-etiquette-failclosed-v1.json`
