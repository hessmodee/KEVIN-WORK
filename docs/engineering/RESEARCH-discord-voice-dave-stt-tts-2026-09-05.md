# RESEARCH Discord voice DAVE + local STT/TTS 2026-09-05

## DAVE
Discord mandates DAVE E2EE. Use @discordjs/voice >=0.19.2 with @snazzah/davey. Node >=22.12 (HESS-PC 24.19 OK). Upstream receive decrypt may be flaky (discord.js issues 11419/11445); keep TEXT as P0.

## Pattern refs
broca-machina / OpenJarvis: receive -> STT -> brain -> TTS -> speak. Prefer dedicated Discord application (one gateway per credential). If text+voice share one credential, run a single process only.

## Local free media
- STT: faster-whisper (CPU int8 base)
- TTS: piper local OR edge-tts free network
- ffmpeg required (HESS-PC: winget Gyan.FFmpeg 9.0.1 installed 2026-09-05)
- Paid realtime TTS = RED without owner auth

## Companion map
follow/come->GoalFollow; stop->clear pathfinder; guard->hostile-only; say->queueChat kevinsk8erkid; status->honest wired report (never fake FOLLOW_OK).
