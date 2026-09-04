# LESSON - Prefer OpenClaw native Discord channel over CoS forever-proxy (2026-09-04)

## Symptom / choice

Matt wants phone remote TEXT to Kevin Chat. Temptation: stand up a separate discord.js CoS bot as forever proxy.

## Teaching

Destination faculty is Kevin-owned OpenClaw `channels.discord` bound to fixed:main (same stack as Telegram). Scratch discord.js is construct-only learning — not the production channel. Forever CoS proxy violates teach-and-transfer and blinds Kevin when CoS is offline.

## Evidence

- Live openclaw.json had telegram channel only; no channels.discord; no Discord credential on disk.
- OpenClaw docs: SecretRef env id DISCORD_BOT_TOKEN; dmPolicy pairing/allowlist; guild allowlist; DMs map to agent:main:main when session.dmScope=main.
- Scratch kevin-discord-text-v0: DISCORDJS_SCRATCH_OK without login.

## Rule

Stop at READY_FOR_OWNER_TOKEN until Kevin-local credential exists. Never invent or git-store the bot credential. Voice/headset later (local STT/TTS); paid realtime stays RED.

## Pointer

PLAN: docs/engineering/PLAN-kevin-discord-text-remote-2026-09-04.md
