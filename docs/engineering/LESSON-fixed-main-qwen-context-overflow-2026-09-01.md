# Lesson: fixed:main exact canary PROVEN via 16k (2026-09-01)

## Outcome
`run_main_agent_canary` → **OMEN_PROVEN** exact `KEVIN_MAIN_AGENT_CANARY_OK` on `ollama-chat-16k/qwen2.5:14b` (hypothesis `main-qwen-16k-20260901`, then clean re-run after R04 rebaseline).

## Cause chain Kevin must remember
1. Unpinned main inherited llama3.1:8b.
2. 8k Qwen pin overflowed even with lean bootstrap + empty skills + reserveTokensFloor 2048.
3. HESS-PC now has **32GB RAM** (Corsair CMK32GX4M2E3200C16). Bounded 16k is feasible; VRAM still limits dual 14B.
4. Production config hash changed intentionally → Benchmark R04 failed until `reports/benchmark-v1/baseline.json` `hashes.production_config` rebaselined to `30A60E3D…`.

## Standing owned policy
- Main model: `ollama-chat-16k/qwen2.5:14b`
- `main.skills=[]`; lean AGENTS/TOOLS/MEMORY; full docs under `docs/engineering/`
- `reserveTokensFloor=2048`
- After intentional openclaw.json changes: rebaseline `baseline.hashes.production_config` to the new sha256 and require Benchmark 30/30 before calling maintenance APPLY clean
- Never strip canary output to fake PASS