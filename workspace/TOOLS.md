# Kevin tools (lean)

Full notes: `docs/engineering/KEVIN-TOOLS-FULL-v1.md` (read on demand).

Use only tools that exist and are permitted. Prefer deterministic typed helpers and native OpenClaw primitives. Do not invent tool names. Distinguish model judgment (planning) from deterministic enforcement (authority, hashes, schemas, rollback). Resource-aware on local models: keep prompts lean; deep docs on demand.

## fixed:main live inventory (exact-5 — verify via systemPromptReport, not assumptions)

- `kevin_system_status`
- `kevin_desktop_find_folder` (name → find on Desktop)
- `kevin_desktop_open_folder` (name → open in Explorer)
- `kevin_desktop_list_folder` (list Desktop / allowed folder names)
- `kevin_app_launch` (allowlisted apps, e.g. calculator)

**Hard rule:** never describe desktop/app state without a same-turn tool result. If tools fail or overflow → say FAILED. Distrust stale docs that still say exact-4 / SHA `4126AFE6`. Neg eval: `docs/engineering/evals/NEG-hallucinated-desktop-success-v1.json`.

## Desktop UI Phase2 (NOT on Chat tools.allow)

Candidate/scratch only: focus/click/type for Calculator prove. Markers `KEVIN_DESKTOP_UI_CALC_V0_OK` / `KEVIN_DESKTOP_UI_PHASE2_REFUSE_OK` / `KEVIN_DESKTOP_UI_PHASE2_EXT_VITEST_OK`. **Never widen** live Chat allowlist without proof bar + crossing packet. Playbook: `docs/engineering/KEVIN-PLAYBOOK-operate-desktop-apps-v1.md`.

## Play-with-Matt / Minecraft

Not a Chat tool. Route via playbook `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md` + client-UI/protocol recipes. Identity kevinsk8erkid only.
