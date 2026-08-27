# Current task

## Stability hold while Matt is away

Keep the proven unattended stack healthy and collect evidence. Do **not** promote or self-authorize new production capabilities.

- Keep KevinTick, KevinGitHubBridge, and KevinNightForge running on their normal schedules.
- Keep Chat v2 and the frozen Reader boundary unchanged.
- Candidate Forge remains **UNHOOKED / PAUSED** until the Ollama candidate-generation crash is repaired and manually re-proven.
- Continue deterministic health, sanitizer, plugin, model-regression, telemetry, and HQ evidence collection.
- Record failures clearly; distinguish infrastructure timeout/crash from model-quality failure.
- Do not modify production `openclaw.json`, Reader permissions/config, Telegram bindings, secrets, or Windows-wide permissions.
- Proposals and candidate designs are welcome; production promotion is not.

## Next human development session

1. Prove the real System Reader E2E question with exactly one `kevin_system_status` call.
2. Build Candidate Forge v3 on the proven 8K Qwen lane with smaller context packets and bounded output.
3. Manually prove candidate generation, compile/test isolation, and candidate-vs-control scoring before any hourly hook.
4. Expand Reader one typed tool at a time: weather, board, self-check.
5. Then begin curated local Knowledge retrieval, followed by narrow typed Operator actions.
