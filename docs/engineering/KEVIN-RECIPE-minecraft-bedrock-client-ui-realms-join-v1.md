# KEVIN-RECIPE — Minecraft Bedrock CLIENT UI Realms join v1

**At:** 2026-09-05 ~00:12 MT (codified teach 00:20 MT)
**Status:** PARTIAL WIN codified (launch+OCR+refuse+identity+input path). Join prove in flight.
**Why:** Protocol path AUTH_CACHE_OK then NETHERNET_GATE (bedrock-protocol #717). Client UI = first-party player path.

## When Matt/Kevin says "play Minecraft / join my Realm"

1. Identity: **kevinsk8erkid ONLY** (never hessmodee).
2. Launch: shell:AppsFolder\Microsoft.MinecraftUWP_8wekyb3d8bbwe!Game
3. Do **not** expect UIA controls — window class Bedrock has zero ControlView children.
4. Use scratch/kevin-minecraft-client-ui-v0:
   - python refuse.py refuse-unit → KEVIN_MC_CLIENT_UI_REFUSE_OK
   - mc_client_join_prove.ps1 -Action ocr (Windows.Media.Ocr)
   - PROBE-AND-JOIN.ps1 → target marker KEVIN_REALMS_CLIENT_JOIN_OK
5. Menu path: center stack Play → Realms → HESSMODEE's Realm → Join (left "Play Now!" is promo, not Play).
6. OCR alias: Realms often reads as fiealms.
7. Clicks: use logical ClientToScreen / screenshot coords with SetCursorPos — do not x1.25 even if display scale is 125%.
8. Preserve Chat 18789 / Reader 19001. No purchase. No invent passwords. UAC → READY_FOR_OWNER_UAC.

## Proven facts (2026-09-05)
- MinecraftUWP 1.26.4501.0; Launch OK; UIA empty; OCR OK; refuse OK; kevin* session; logical SetCursorPos opens Settings; protocol AUTH_OK+NETHERNET_GATE

## Pointers
- Playbook: `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md`
- Coop recipe: `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`
- Desktop ops: `docs/engineering/KEVIN-PLAYBOOK-operate-desktop-apps-v1.md`
