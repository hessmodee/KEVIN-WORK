# Lesson: fixed:main Qwen context overflow (2026-09-01)

Failure family: `response-behavior/context-overflow` (after wrong-resolved-model was fixed by pinning Qwen).

## What broke
- Pinning `main` to `ollama-chat/qwen2.5:14b` made the resolved model correct.
- Canary still REJECTED: assistant returned OpenClaw context-overflow banner (127 chars), not `KEVIN_MAIN_AGENT_CANARY_OK`.
- `ollama-chat` caps `num_ctx` at 8192. Production bootstrap (AGENTS/SOUL/TOOLS/…) plus skills prompts exceed that budget.
- Lowering `reserveTokensFloor` 20000→2048 was necessary but not sufficient.
- Setting `main.skills = []` is under test to cut skill-prompt injection (lab agents already use empty skills).

## How Kevin detects next time
- Canary/public receipt: `final_length` ~127 and/or correlated transcript text is the overflow banner; `resolved_model_id` may still be qwen.
- Isolated main session assistant message starts with `Context overflow:`.

## How Kevin repairs / avoids
1. Keep `agents.defaults.compaction.reserveTokensFloor` compatible with context (2048 for 8k; never 20000 on 8k).
2. Keep `main.skills` empty unless a skill is proven and budgeted.
3. Do not move production main to `ollama-chat-16k` without owner approval (VRAM/latency).
4. Prefer slim always-injected bootstrap over silent 16k; deep docs live under `docs/engineering/` and are read on demand.
5. Exact canary semantics stay hard — never strip/coerce overflow text into a fake PASS.

## Teach-back status
Written for Kevin ownership. Next: finish 8k fit or owner-approved 16k, then prove exact canary, then Kevin's own maintenance path should re-run canary without Chief of Staff invention.