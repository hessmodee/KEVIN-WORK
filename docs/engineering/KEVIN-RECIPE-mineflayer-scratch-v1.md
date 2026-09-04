# KEVIN RECIPE - Mineflayer plus flying-squid (SCRATCH only) v1

Authority: FREE/SAFE local. No Chat tools. No Desktop install. No openclaw.json or Supervisor path edits.
Companion PLAN: docs/engineering/PLAN-kevin-north-star-max-2026-09-04.md (P2).

## Goal

Prove Kevin can join a local offline Minecraft world as a bot player, send a chat marker, then stop. No paid server. No Microsoft login. No LLM loaded during v0 unless Chat 14B is idle.

## Layout

- Scratch: scratch/kevin-minecraft-v0
- Packages: mineflayer, mineflayer-pathfinder, flying-squid
- Marker: KEVIN_MC_V0_OK
- Port: 25565 localhost only. Do not bind Chat 18789, Reader 19001, or Ollama 11434.

## How Kevin runs (after install)

1. Start the local JS server from the scratch folder (offline-mode, max a few players).
2. Start the bot with host localhost, username KevinBot, auth offline.
3. On spawn, send chat KEVIN_MC_V0_OK, wait one second, quit.
4. Stop the server.
5. Write a receipt under reports/engineering with timestamp, package versions, and that Chat/Reader ports were not touched.

## Hard no

- Do not point this recipe at Chat workspace, Desktop production trees, secrets, or NightForge.
- Do not connect to a public or paid server.
- Do not store Microsoft credentials.
- Do not add a Minecraft tool to Chat.
- Tear down after proof. No always-on server unless Matt asks.

## LLM brain (later, not v0)

If Chat is holding Qwen 2.5 14B, use llama3.1:8b or skip the brain. Movement stays pathfinder-deterministic. High-level goals only from the model.
