# Fixed-main Qwen pin — context overflow (2026-09-01)

Consumer: fixed-main acceptance gate.
Author: GrokBot foreground. Status: RESEARCH + negative canary evidence.

## Experiments

### A) Pin main → `ollama-chat/qwen2.5:14b`
- Config sha before pin `6FC7A112…` → after `082C9AAB…` (then reserve change → `48AB7142…`).
- Manifest `main-canary-qwen-pin-20260902-210731` → REJECT semantic_contract.
- Session `95d26c5c-14fe-4ae0-b8fd-15c73862b001`: provider `ollama-chat`, modelId `qwen2.5:14b`.
- Assistant text length 127 = OpenClaw context-overflow banner (not compliance prose).

### B) Lower `compaction.reserveTokensFloor` 20000 → 2048
- Still overflow. Session `20e11f3f-cd5a-46be-bc9b-e96915676e83`. Hypothesis tag `main-qwen-reserve2048-20260901`.
- Conclusion: overflow is real prompt vs 8192 cap, not only the absurd reserve floor (floor fix still correct).

## Budget
- Production workspace bootstrap markdown ≈ 20.7KB (~5k+ tokens) + skills-prompts ≈ 11KB + OpenClaw system.
- Lab workspaces ≈ 672 bytes total (why lab Qwen works).
- Provider `ollama-chat` hard-caps `contextTokens/num_ctx=8192`. `ollama-chat-16k` exists but owner invariant forbids unattended 16k.

## Prior llama path (for contrast)
- Session `b4c2e9a3-…`: provider `ollama` / `llama3.1:8b`, len 145, tool-call-shaped JSON containing the token, not exact.

## Decision needed (not taken)
1. Approve production main on `ollama-chat-16k/qwen2.5:14b` for one bounded canary + keep if proven, or
2. Slim always-injected bootstrap (AGENTS/SOUL/TOOLS/skills) so Qwen fits in 8k without weakening exact canary semantics, or
3. Minimal-bootstrap canary agent (proves response discipline off main; does **not** alone satisfy fixed:main production prerequisite).

Exact acceptance unchanged. No output stripping. No Supervisor install until main prerequisite genuinely satisfied.
