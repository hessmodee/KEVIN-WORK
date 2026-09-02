# Lesson: fixed:main Qwen context overflow (2026-09-01)

Failure family: `response-behavior/context-overflow`.

## Hardware update
HESS-PC now has **32GB RAM** (Corsair CMK32GX4M2E3200C16 2x16), verified 2026-09-01. See `NOTE-hess-pc-32gb-ram-2026-09-01.md`. This makes bounded 16k local context more feasible; VRAM (12GB) remains the tighter limit.

## What broke
Pinning main to `ollama-chat/qwen2.5:14b` (8k) yielded OpenClaw context-overflow banner (127 chars) instead of exact `KEVIN_MAIN_AGENT_CANARY_OK`.

## Experiments
1. `reserveTokensFloor` 20000→2048 — necessary, not sufficient.
2. `main.skills=[]` — negative (still overflow).
3. Lean always-injected AGENTS/TOOLS/MEMORY (~8KB total) with full copies under `docs/engineering/` — **still overflow** on 8k. Conclusion: OpenClaw system/tool injection alone can exceed 8192 with Qwen.
4. Pin main → `ollama-chat-16k/qwen2.5:14b` — under test (owner RAM upgrade + prior 8k negatives).

## Standing policy for Kevin
- Prefer lean always-injected bootstrap; deep docs on demand.
- On 8k overflow with lean files: use bounded 16k provider for main, not silent prompt stripping.
- Exact canary semantics stay hard.
- Do not run multiple Qwen 14B workloads casually.