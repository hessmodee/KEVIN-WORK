# KEVIN RECIPE — Aider + local Ollama (SCRATCH only) v1

Authority: FREE/SAFE local. No Chat tools. No Desktop install. No openclaw.json / Supervisor path edits.

## Installed (2026-09-04 America/Boise)
- Scratch repo: `C:\Users\hessm\.openclaw\workspace\scratch\aider-ollama-demo`
- Venv Python: 3.12.10 (NOT default 3.13 — aider requires `<3.13`)
- Package: `aider-chat==0.86.2` inside `.venv`
- Binary: `C:\Users\hessm\.openclaw\workspace\scratch\aider-ollama-demo\.venv\Scripts\aider.exe`
- Ollama: pre-existing 0.33.1; models `llama3.1:8b`, `qwen2.5:14b`

## How Kevin runs (scratch only)
```powershell
cd "C:\Users\hessm\.openclaw\workspace\scratch\aider-ollama-demo"
.\.venv\Scripts\aider.exe --model ollama_chat/llama3.1:8b
# or
.\.venv\Scripts\aider.exe --model ollama_chat/qwen2.5:14b
```

Ensure Ollama is running. Optional: ` = "http://127.0.0.1:11434"`

## Hard no
- Do not open Aider against Chat workspace, Desktop production trees, secrets, or NightForge.
- Do not edit `openclaw.json` / Supervisor install paths from this recipe.
- No purchases / trades / RED.

## LESSON
See `docs/engineering/LESSON-aider-requires-python-lt-313-2026-09-04.md`.
