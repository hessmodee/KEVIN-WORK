# PLAN - Kevin Discord TEXT remote (phone) via OpenClaw native channel

Date: 2026-09-04 ~13:35 MT (America/Denver)
Author: Grok Bot (HESS-PC inventory + OpenClaw Discord docs)
Audience: Matt / Davy / Kevin / Cursor agents
Auth: UNDYING GREEN+YELLOW `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`
North-star: `docs/engineering/PLAN-kevin-north-star-max-2026-09-04.md` (P3)
Teach-and-transfer: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`
Handover: `AI-HANDOVER.md` only (no GROK-HANDOVER). Execution: `inbox/CURRENT_TASK.md`.
Parallel: Tailscale remote HQ (other worker). Discord = phone TEXT chat; Tailscale = HQ/browser.

## 0. Decision (OpenClaw path vs separate bot)

**Choose: Kevin-owned OpenClaw Discord channel bound to fixed:main.**

- A. OpenClaw native channels.discord = PREFERRED. Same agent stack as Telegram; DM pairing + guild allowlist; SecretRef; Kevin owns end-state. Docs: https://docs.openclaw.ai/channels/discord.md
- B. Separate CoS/discord.js forever-proxy = REJECT as end-state. Scratch discord.js OK for library learning only.
- C. Voice/headset now = DEFER. Paid realtime RED. Local Whisper+Piper after text.

Scratch: scratch/kevin-discord-text-v0 proved DISCORDJS_SCRATCH_OK (construct-only). Recipe KEVIN-RECIPE-discordjs-scratch-v1.md.


## 1. Inventory (HESS-PC 2026-09-04 ~13:35 MT) — evidence

- Live config: `C:\Users\hessm\.openclaw\openclaw.json`
  - `channels`: **telegram only** (`enabled`, bot token field, `dmPolicy: pairing`). **No `channels.discord`.**
  - `commands.ownerAllowFrom`: `telegram:8590204640` (Matt).
  - Agent `main` tools (effective): `kevin_system_status`, `kevin_desktop_find_folder`, `kevin_desktop_open_folder`, `kevin_desktop_list_folder`, `kevin_app_launch` (exact-4 + list-in-flight; freeze honored).
  - SHA256 live (post-list): `DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4` — Discord block **not** present; do not widen Chat tools in this PLAN.
- Credentials dir: telegram pairing files only. **No Discord credential file.**
- `.env` key names only: `OLLAMA_API_KEY` (no `DISCORD_BOT_TOKEN` yet).
- OpenClaw CLI: present. Chat 18789 / Reader 19001: do not kill.
- Desktop freeze except documented Discord channel config.
- New Kevin secrets stub (empty): `C:\Users\hessm\.openclaw\credentials\kevin-discord\` (README only).
- Placeholder patch (not applied): `scratch/kevin-discord-text-v0/openclaw-discord.patch.json5` (SecretRef → env id `DISCORD_BOT_TOKEN`).

## 2. End-state (Kevin owns the channel)

1. Matt creates a Discord application + bot in the Developer Portal (owner action).
2. Matt invites the bot to a **private** server/channel he owns.
3. Matt places the bot credential in Kevin-local secret store on HESS-PC (not git, not MEMORY, not HQ — use CoS secret card / parent request flow).
4. OpenClaw `channels.discord` enabled with SecretRef; DM allowlist = **Matt only**; guild allowlist = Matt's private server; optional single `#kevin-chat` channel.
5. Gateway resolves SecretRef; Matt DMs bot then pairing approve; then guild text works without forever CoS proxy.
6. `/reset` guidance taught for Discord sessions.
7. Voice later (separate PLAN slice).

**Status this run: `READY_FOR_OWNER_TOKEN`** — free/safe prep done; no invent credential; no live Discord connect.

## 3. Owner checklist (Matt) — create bot + invite

Developer Portal: https://discord.com/developers/applications

1. New Application — name e.g. Kevin or Kevin-HESS.
2. Bot sidebar — Username Kevin — save.
3. Privileged Gateway Intents: enable Message Content Intent; enable Server Members Intent; leave Presence off for text v0.
4. Reset/Copy bot credential — password-class. Do NOT paste into git, MEMORY, HQ, Slack, or this PLAN. Deliver via CoS secret card (parent requests) into Kevin-local store on HESS-PC.
5. OAuth2 URL Generator: scopes bot + applications.commands. Permissions: View Channels, Send Messages, Read Message History, Embed Links, Attach Files.
6. Open invite URL — select Matt private server (create one if needed) — authorize.
7. Discord Developer Mode on — Copy Server ID + your User ID (for allowlist).
8. Create private text channel e.g. #kevin-chat.
9. Optional: server Privacy allow DMs from server members (first pairing DM).

After credential is on HESS-PC: tell Kevin/CoS User ID + Server ID to finish OpenClaw bind.

## 4. Kevin secrets path (no git)

Prefer env SecretRef (OpenClaw):

- Append `DISCORD_BOT_TOKEN=<value>` to `C:\Users\hessm\.openclaw\.env` (machine-local, never commit).

Alternate file:

- `C:\Users\hessm\.openclaw\credentials\kevin-discord\DISCORD_BOT_TOKEN` (raw value only, UTF-8).

Never store in workspace git, MEMORY.md, HQ, receipts, PLAN bodies, or public Discord channels.

## 5. OpenClaw bind steps (after credential exists)

Recipe: `docs/engineering/KEVIN-RECIPE-openclaw-discord-text-channel-v1.md`
Gate: `control-plane/staging/kevin-discord-text-token-gate-v1.ps1`
Patch template: `scratch/kevin-discord-text-v0/openclaw-discord.patch.json5`

1. Run gate — expect TOKEN_PRESENT (else stay READY_FOR_OWNER_TOKEN).
2. Fill Matt User ID + Server ID into a local patch copy.
3. Recommended v0 shape: enabled true; token SecretRef env id DISCORD_BOT_TOKEN; dmPolicy allowlist (or pairing first then tighten); allowFrom discord:MATT_USER_ID; groupPolicy allowlist; guilds[MATT_SERVER_ID] with users [MATT_USER_ID] and channel kevin-chat requireMention false.
4. Add discord:MATT_USER_ID to commands.ownerAllowFrom alongside existing telegram owner (do not remove Telegram).
5. openclaw config patch --dry-run then apply; restart gateway carefully; do not kill Reader.
6. Proof: Matt DM or #kevin-chat — reply marker KEVIN_DISCORD_TEXT_OK + receipt (no secret in receipt).
7. DMs share agent:main:main when session.dmScope=main (fixed:main). Guild channels are isolated discord:channel sessions.

### /reset guidance

- Guild channels = isolated sessions (not Telegram transcript).
- Native /reset or /new resets that Discord session.
- MEMORY.md auto-loads in DM sessions; guild channels use memory_search/memory_get on demand. Stable rules in AGENTS.md / USER.md.
- On Qwen context overflow: /reset the Discord session; do not widen tools.

## 6. Safety

- DM allowlist = Matt only.
- Guild allowlist = Matt private server; prefer single #kevin-chat map.
- allowBots default false.
- No kevin_shell; no Chat tool widen in this PLAN.
- No live trades / purchases / paid voice.
- Desktop exact-4(+list) freeze except this documented Discord channel config.
- Do not kill Chat 18789 / Reader 19001.

## 7. Voice later

Not now. After text GREEN: local Whisper+Piper or OpenClaw stt-tts local media; followUsers=Matt. Paid realtime = RED.

## 8. Tailscale parallel

Independent of Discord cloud text. Other worker owns Tailscale HQ.

## 9. This-run deliverables (FREE/SAFE)

| Artifact | Path |
| --- | --- |
| This PLAN | docs/engineering/PLAN-kevin-discord-text-remote-2026-09-04.md |
| LESSON | docs/engineering/LESSON-discord-text-openclaw-prefer-native-2026-09-04.md |
| Recipe | docs/engineering/KEVIN-RECIPE-openclaw-discord-text-channel-v1.md |
| Gate script | control-plane/staging/kevin-discord-text-token-gate-v1.ps1 |
| Patch placeholder | scratch/kevin-discord-text-v0/openclaw-discord.patch.json5 |
| Secrets stub | C:\Users\hessm\.openclaw\credentials\kevin-discord\README.txt |
| Receipt | reports/engineering/RECEIPT-discord-text-plan-prep-20260904-1335.md |

Not this run: invent/store credential; live openclaw config patch; gateway Discord connect; voice.

## 10. READY status

**READY_FOR_OWNER_TOKEN** (and while Omen offline for remaining sync: **READY_FOR_OMEN_ONLINE**)

Blocked on: (1) Matt creates bot + secret-card delivery into Kevin-local .env or credentials file; (2) HESS-PC local-exec online to land remaining docs/MEMORY/CURRENT_TASK/north-star pointer/PR publish if not yet synced.

## 7b. VOICE lane ACTIVE (2026-09-05 ~11:55 MT)

Sibling scratch/kevin-discord-voice-v0. Stack: Node24.19, discord.js, @discordjs/voice 0.19.2 + davey, opusscript, ffmpeg 9.0.1, faster-whisper + edge-tts installed. Smokes IMPORT_OK + text router OK. TEXT !k commands READY when owner credential present (gate READY_FOR_OWNER_TOKEN). VOICE join allowlisted; keep text primary tonight. Docs: PLAYBOOK/RESEARCH/OPERATOR-CARD + NEG eval.

