# Lesson: fixed:main Qwen context overflow (2026-09-01)

Failure family: `response-behavior/context-overflow` (after wrong-resolved-model fixed by pinning Qwen).

## What broke
- Pin `main` → `ollama-chat/qwen2.5:14b` fixed model identity.
- Canaries still REJECTED with OpenClaw context-overflow banner (127 chars).
- Provider `ollama-chat` caps `num_ctx` at 8192.
- Production always-injected bootstrap was too large (~AGENTS 12KB + TOOLS 4.7KB + SOUL 4KB + MEMORY 5.8KB + system).

## Experiments (negative / partial)
1. `reserveTokensFloor` 20000→2048 — necessary, not sufficient.
2. `main.skills = []` — negative; overflow remained (hypothesis `main-qwen-skills-empty-20260901`).
3. Lean always-injected AGENTS/TOOLS/MEMORY with full copies under `docs/engineering/` — under test.

## How Kevin detects
- Canary `final_length` ~127 / transcript assistant starts with `Context overflow:`.
- `resolved_model_id` may still show `qwen2.5:14b`.

## How Kevin repairs / avoids (standing)
1. Keep `reserveTokensFloor` compatible with context (2048 on 8k).
2. Keep `main.skills` empty unless budgeted and proven.
3. Keep always-injected `AGENTS.md` / `TOOLS.md` / `MEMORY.md` lean; put detail in `docs/engineering/*` and read on demand.
4. Do not move production main to `ollama-chat-16k` without owner approval.
5. Never strip overflow text into a fake canary PASS.

## Ownership
Kevin must maintain the context budget himself. Chief of Staff teach-back lives in this lesson + Teach-and-Transfer rule.
