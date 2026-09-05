# KEVIN PLAYBOOK — Play with Matt (Minecraft Bedrock Realms) v1

**Updated:** 2026-09-05 ~00:20 MT
**Authority:** UNDYING GREEN+YELLOW teach/docs. Live join owned by join/client-UI worker when gate clears.
**Cold-start rule:** When Matt says **"play a game with me" / "play Minecraft" / "join my Realm" / co-op**, Kevin follows this checklist — do not improvise identity or claim join success without markers.

## 0. Identity lock (hard)

| Role | Tag / surface | Rule |
| --- | --- | --- |
| **Kevin** | **kevinsk8erkid** | Only play identity |
| **Matt** | **hessmodee** on **Xbox** | Partner / Realm owner — never bot-login |
| **Realm** | **HESSMODEE's Realm** | Existing invite; no purchase |
| **Home** | **Bed at the house** | Spawn / reunite point |

**NEVER** authenticate, join, chat, or act as **hessmodee**.

## 1. When Matt prompts "play …"

1. Read this playbook + `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`.
2. Prefer **client UI join** path when protocol is gated: `docs/engineering/KEVIN-RECIPE-minecraft-bedrock-client-ui-realms-join-v1.md`.
3. Confirm AUTH_CACHE_OK (do not re-device-code unless cache empty).
4. If join still **NETHERNET_GATE** / timeout: document honestly; stay ready; do **not** claim `KEVIN_REALMS_JOIN_OK` / `KEVIN_REALMS_CLIENT_JOIN_OK`.
5. When join clears: proceed §2 play loop.

## 2. In-world play loop (after JOIN_OK)

1. **Wait at house bed** — idle until Matt present / cues.
2. **Follow Matt** when invited; safe distance; no shortcuts through builds.
3. **Chat** — short friendly hello; rate-limit; never impersonate hessmodee.
4. **Mine / build** — only when Matt invites; agreed areas; no grief / chests / redstone.
5. **Death** → house bed → reunite.
6. **Fail-closed** on kick / auth fail / wrong-identity risk / purchase prompt.

Markers: `KEVIN_REALMS_JOIN_OK` or `KEVIN_REALMS_CLIENT_JOIN_OK` → then `KEVIN_REALMS_COOP_OK` when etiquette loop observed.

## 3. Two join paths (truth)

| Path | Stack | Status (2026-09-05 ~00:20 MT) |
| --- | --- | --- |
| Protocol | bedrock-protocol + prismarine-auth (`scratch/kevin-minecraft-bedrock-v0`) | AUTH_CACHE_OK; residual **NETHERNET_GATE** (#717) |
| Client UI | MinecraftUWP + OCR/input (`scratch/kevin-minecraft-client-ui-v0`) | Launch/OCR/refuse/input proven; join prove in flight |

Protocol path does not fake JOIN_OK. Client UI: UIA empty on Bedrock window — use OCR + logical SetCursorPos (no DPI×1.25). Menu: Play → Realms → HESSMODEE's → Join (left "Play Now!" is promo).

## 4. Desktop ladder (to open Minecraft)

Use `docs/engineering/KEVIN-PLAYBOOK-operate-desktop-apps-v1.md`:
- Chat exact-5 for launch/list/find/open/status when available.
- Do **not** widen Chat tools.allow for UI click/type without proof bar.
- Minecraft client ops stay in scratch/prove scripts until typed crossing exists.

## 5. Hard nos

- No hessmodee bot login; no invent passwords; no secrets in MEMORY/git/HQ.
- No purchases / marketplace.
- Do not kill Chat **18789** / Reader **19001**.
- No Chat Minecraft tool until typed crossing.
- Teach workers do not claim live join success.

## 6. Pointers

- Recipe coop: `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`
- Recipe client UI: `docs/engineering/KEVIN-RECIPE-minecraft-bedrock-client-ui-realms-join-v1.md`
- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Etiquette: `docs/engineering/KEVIN-KNOWLEDGE-minecraft-realms-coop-etiquette-v1.md`
- Eval: `docs/engineering/evals/EVAL-minecraft-realms-coop-etiquette-failclosed-v1.json`
- Neg routing: `docs/engineering/evals/NEG-play-with-matt-wrong-identity-or-fake-join-v1.json`
- Skill stub: `inbox/skills/play-with-matt-minecraft-routing-stub-v1.json`
