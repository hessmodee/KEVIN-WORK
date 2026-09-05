# CURRENT_TASK

**Updated:** 2026-09-05 ~00:20 MT
**Role:** current execution contract only. `AI-HANDOVER.md` remains the one human canonical handover.
**Cold-start:** `docs/engineering/KEVIN-TURNOVER-LATEST.md`.

## P0 — Play with Matt / Minecraft Realms (standing recall)

When Matt says **"play a game with me" / play Minecraft / join Realm / co-op**:
1. Load `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md`
2. Identity **kevinsk8erkid** only (never **hessmodee**)
3. AUTH_CACHE_OK; protocol residual NETHERNET_GATE — do not fake JOIN_OK
4. Client UI path: `docs/engineering/KEVIN-RECIPE-minecraft-bedrock-client-ui-realms-join-v1.md` (join prove may be in flight)
5. After join: house bed → follow Matt → chat → invited mine/build → fail-closed
6. Desktop ops ladder: `docs/engineering/KEVIN-PLAYBOOK-operate-desktop-apps-v1.md`

NEG: `docs/engineering/evals/NEG-play-with-matt-wrong-identity-or-fake-join-v1.json`
Routing stub: `inbox/skills/play-with-matt-minecraft-routing-stub-v1.json`

Hard no: hessmodee bot login; invent passwords; purchases; kill Chat 18789 / Reader 19001; Chat tools.allow widen without proof bar.

## Desktop exact-5 + UI Phase2 (standing)

- Live Chat Desktop **exact-5**: status, find_folder, open_folder, list_folder, app_launch.
- Distrust stale exact-4 / `4126AFE6`.
- UI Phase2: Calculator scratch PROVEN; candidate + disabled ext refuse — **not** on Chat tools.allow.
- Never claim Desktop/app state without same-turn tool result.

## Active Desktop UI control PLAN (retained)

- PLAN: `docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md`
- Status: Phase2 candidate / disabled-ext — no Chat widen
- Proof bar before exact-N widen: schema/fixtures/neg/E2E/audit/rollback + crossing packet

## Active Minecraft Realms facts (retained)

- Bedrock LOCKED; invite DONE; house bed DONE; AUTH_CACHE_OK=yes; join=NETHERNET_GATE (protocol) / client UI in flight
- Recipe coop: `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`
- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`

## Standing Auth (UNDYING 2026-09-04)

Do not wait for per-step permission on green/yellow Kevin work. RED/purchasing/trading reserved.
Card: `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`.
