# LESSON — Aider requires Python < 3.13 (2026-09-04)

## Symptom
`pip install aider-chat` on default HESS-PC Python 3.13 failed:
- user pip: missing `setuptools.build_meta` / build isolation
- venv 3.13: recent `aider-chat` versions require `Requires-Python <3.13`; only ancient 0.16.x visible and those cannot resolve `aiohttp` wheels

## Fix
Use existing Python 3.12 to create scratch venv, then `pip install aider-chat>=0.80`:
`C:\Users\hessm\AppData\Local\Programs\Python\Python312\python.exe -m venv scratch\aider-ollama-demo\.venv`

## Self-repair
Prefer `py -3.12` for Aider. Keep default 3.13 for other tooling. Never point Aider at production Chat/Desktop.
