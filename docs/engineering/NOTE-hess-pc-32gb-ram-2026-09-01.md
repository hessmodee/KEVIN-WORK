# Hardware note: HESS-PC 32GB RAM (2026-09-01)

Owner reported RAM upgrade from 16GB to 32GB. Verified on machine:
- 2x16GB Corsair `CMK32GX4M2E3200C16` (total 32GB visible ~31.9GB)
- Implication: bounded `ollama-chat-16k` for main is more feasible than under 16GB system RAM pressure; VRAM (RTX 3060 12GB) remains the tighter constraint for Qwen 14B + large ctx.
- Still do not run multiple Qwen 14B workloads casually.