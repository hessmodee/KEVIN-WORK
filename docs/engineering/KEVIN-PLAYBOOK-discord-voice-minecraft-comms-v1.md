# KEVIN-PLAYBOOK Discord voice+text Minecraft comms v1

Date: 2026-09-05 MT
Scratch: scratch/kevin-discord-voice-v0
Extends text PLAN READY_FOR_OWNER_TOKEN. Identity kevinsk8erkid only.

## Dual-path tonight
- TEXT prefix !k follow|stop|guard|come|status|say — READY when owner credential present
- VOICE join/STT/TTS — scaffold READY; may show READY_FOR_STT_TTS_INSTALL

## Stack
Node 24.19, discord.js14, @discordjs/voice^0.19.2 + davey, opus/sodium, ffmpeg, faster-whisper + piper/edge-tts stubs.

## Pattern
VC audio -> STT -> intent router -> companion bridge (GoalFollow/guard/chat) -> TTS speak.

## NEG
No secrets in git; session-only audio; VC allowlist required; no Chat/Reader kill; no paid TTS without auth; never hessmodee.
