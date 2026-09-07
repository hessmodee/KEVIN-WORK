# Kevin tools (lean)

Full notes: `docs/engineering/KEVIN-TOOLS-FULL-v1.md` (read on demand).

Use only tools that exist and are permitted. Prefer deterministic typed helpers and native OpenClaw primitives. Do not invent tool names. Distinguish model judgment (planning) from deterministic enforcement (authority, hashes, schemas, rollback). Resource-aware on local models: keep prompts lean; deep docs on demand.

## Execution truth boundary

A tool's actual contract is the capability boundary. Do not turn a weaker tool into a stronger capability by narration.

- A tool receipt proves only what that tool contract says it did.
- Persistent-file success requires a writer plus a semantic readback/postcondition. Chat output alone is not a file.
- If a requested action has no visible tool/capability, report **`NOT_EXECUTED: capability_unavailable`**.
- If an action ran but the requested postcondition is not proven, report **`ATTEMPTED_UNVERIFIED`**.
- `kevin_app_launch` launches only a fixed allowlisted app. It does **not** type, click, draw, save, generate images, author files, or prove an artifact exists.
- Historical playbooks, scratch tools, Phase2 candidates, or typed maintenance operations are not automatically available in Chat. Never infer a Chat capability from documentation alone.

## fixed:main live inventory (exact-5 — verify via systemPromptReport, not assumptions)

- `kevin_system_status`
- `kevin_desktop_find_folder` (name → find on Desktop)
- `kevin_desktop_open_folder` (name → open in Explorer)
- `kevin_desktop_list_folder` (list Desktop / allowed folder names)
- `kevin_app_launch` (fixed allowlisted app launch only)

**Not in fixed:main exact-5:** generic file write/edit, shell/exec, keyboard typing, mouse click, save-dialog control, image generation, app close, Minecraft control, email/social send, or arbitrary process launch.

**Hard rule:** never describe desktop/app state without a same-turn tool result. Never describe a persistent artifact as created/saved without a same-turn semantic postcondition. If tools fail, overflow, or the needed capability is absent, say so truthfully. Distrust stale docs that still say exact-4 or imply a historical capability is live. Negative evals: `docs/engineering/evals/NEG-hallucinated-desktop-success-v1.json` and `docs/engineering/evals/NEG-side-effect-claim-without-receipt-v1.json`.

## Desktop UI Phase2 (NOT on Chat tools.allow)

Candidate/scratch only: focus/click/type for Calculator prove. Markers `KEVIN_DESKTOP_UI_CALC_V0_OK` / `KEVIN_DESKTOP_UI_PHASE2_REFUSE_OK` / `KEVIN_DESKTOP_UI_PHASE2_EXT_VITEST_OK`. **Never widen** live Chat allowlist without proof bar + crossing packet. Playbook: `docs/engineering/KEVIN-PLAYBOOK-operate-desktop-apps-v1.md`.

## Play-with-Matt / Minecraft

Not a Chat tool. Route via playbook `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md` + client-UI/protocol recipes. Identity kevinsk8erkid only. A historical JOIN_OK or companion receipt never proves a new live action in the current Chat turn.
