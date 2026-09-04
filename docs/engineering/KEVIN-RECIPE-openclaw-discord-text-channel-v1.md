# KEVIN RECIPE - OpenClaw Discord TEXT channel v1 (NO LOGIN until token)

Authority: FREE/SAFE prep. No invent credential. No live patch until gate TOKEN_PRESENT.
Companion PLAN: docs/engineering/PLAN-kevin-discord-text-remote-2026-09-04.md
Docs: https://docs.openclaw.ai/channels/discord.md

## Goal

Enable Kevin-owned OpenClaw Discord text to fixed:main after Matt places a Kevin-local bot credential.

## Layout

- Patch template: scratch/kevin-discord-text-v0/openclaw-discord.patch.json5 (SecretRef only)
- Gate: control-plane/staging/kevin-discord-text-token-gate-v1.ps1
- Secrets prefer: C:\Users\hessm\.openclaw\.env key DISCORD_BOT_TOKEN
- Alternate: C:\Users\hessm\.openclaw\credentials\kevin-discord\DISCORD_BOT_TOKEN
- Construct-only library scratch remains no-login.

## Steps (Kevin)

1. Run gate script. If READY_FOR_OWNER_TOKEN — stop.
2. Confirm Discord Developer Portal intents already enabled by Matt (Message Content + Server Members).
3. Fill local patch with Matt User ID + Server ID + channel id/name (not committed with secrets).
4. Prefer first dmPolicy pairing, then tighten to allowlist Matt-only.
5. openclaw config patch --file <patch> --dry-run then apply (only when TOKEN_PRESENT).
6. Add discord:MATT_USER_ID to commands.ownerAllowFrom (keep telegram owner).
7. Restart gateway without killing Reader 19001 / without widening Desktop tools.
8. Matt DMs bot — pairing approve — then #kevin-chat prove KEVIN_DISCORD_TEXT_OK.
9. Teach /reset for Discord channel sessions.

## Hard no

- No credential in git, MEMORY, HQ, receipts, chat durable storage.
- No separate forever CoS bot as end-state.
- No voice/paid realtime in this recipe.
- No Chat tool policy widen.
