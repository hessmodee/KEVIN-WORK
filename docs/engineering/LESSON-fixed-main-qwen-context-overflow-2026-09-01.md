# Lesson: fixed:main Qwen context overflow → 16k pin (2026-09-01)

Failure family resolved for exact canary: `response-behavior/context-overflow` on 8k.

## Hardware
HESS-PC has **32GB RAM** (Corsair CMK32GX4M2E3200C16 2x16). See `NOTE-hess-pc-32gb-ram-2026-09-01.md`.

## Root cause chain
1. Main had no model override → inherited llama3.1:8b (wrong brain).
2. Pin to `ollama-chat/qwen2.5:14b` (8k) → correct model, but OpenClaw system+bootstrap exceeded 8192 → overflow banner.
3. Lean AGENTS/TOOLS/MEMORY + `skills=[]` + `reserveTokensFloor=2048` still overflowed on 8k.
4. Pin to `ollama-chat-16k/qwen2.5:14b` → **OMEN_PROVEN** exact `KEVIN_MAIN_AGENT_CANARY_OK` (session correlated, transcript complete, 0 tool calls).

## Standing policy Kevin owns
- Main primary model: `ollama-chat-16k/qwen2.5:14b` until a proven leaner path exists.
- Keep always-injected bootstrap lean; full standing orders in `docs/engineering/KEVIN-AGENTS-FULL-v1.md`.
- `main.skills=[]` unless budgeted.
- `reserveTokensFloor=2048` on local ctx.
- Never fake canary PASS by stripping output.
- Do not run multiple Qwen 14B workloads casually; VRAM is still the tight constraint.

## Teach-and-transfer
This lesson is the durable ownership handoff so Kevin (not Bess) maintains the context/model policy next time.