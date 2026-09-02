# CURRENT_TASK

## 2026-09-02 — Owner continuous-autonomy recovery campaign

Owner direction: continue useful authorized Kevin Build work without waiting for Matt when an existing proven remote/governed path can perform it. Codified in `docs/engineering/OWNER-CONTINUOUS-AUTONOMY-DIRECTIVE-2026-09-02.md`. The old `write-proof / stop` instruction is retired by this newer owner objective.

### P0 — Preserve and close fixed:main context/compaction repair

Known owner-observed repair state:
- main model remains `ollama-chat-16k/qwen2.5:14b` with configured context/`num_ctx` 16384;
- `agents.defaults.compaction.reserveTokensFloor=2048`;
- `agents.defaults.compaction.reserveTokens=2048` was added through OpenClaw config set + validation;
- `agents.defaults.compaction.keepRecentTokens=4000` was added through OpenClaw config set + validation;
- current post-hardening config SHA256 reported by owner terminal: `23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5`;
- fresh Kevin chat answered normally and manual `/compact` completed successfully after the repair;
- latest Support evidence then showed Benchmark 29/30 with only critical R04 `Production config frozen`, which is expected drift after the intentional validated config mutation.

Next: restore Benchmark 30/30 using the existing governed baseline contract. Do not fake R04, weaken Benchmark, or restore an older config merely to satisfy the old hash. Preserve the intentional compaction settings. Require fresh Benchmark and Support proof after any baseline crossing.

### P1 — Teach Kevin the repair so Bess/Grok/Matt are not required next time

Convert the context overflow/compaction incident into Kevin-owned autonomy debt retirement:
1. durable failure-family lesson and detection signature;
2. bounded read-only detector for effective model/context/compaction values and config identity;
3. safe preconditioned recovery procedure for the known configuration case;
4. semantic verification: new fixed:main turn, compaction behavior, config validation, and Benchmark;
5. rollback and negative fixtures;
6. a typed/governed path that Kevin can select and execute on a future recurrence;
7. record the remaining outside-engineer step and move it up T0-T5 only when proven.

Do not overwrite the currently installed Maintenance runner with a public source merely to add this feature: latest evidence says the installed runner has an unpublished local identity. Preserve it until exact installed-source/provenance is recovered or an equivalent safe migration is proven.

### P2 — Work-conserving continuous improvement

If P0/P1 is blocked or cooling, do another independent useful authorized lane rather than idle/spin:
- Maintenance/self-repair ownership and autonomous work selection;
- GREEN skill development, replay, regression tests, and real-world reuse;
- YELLOW research/design/staging/testing within explicit boundaries;
- direct owner<->Kevin communication, mobile Kevin HQ, and Telegram repair/replacement;
- memory/handoff/restart-replay reliability;
- lawful owner-value/economic-output workflows using proven capabilities.

Default WIP remains 1 production/proof + 1 staging/eval + 1 research/design. A heartbeat/cycle/renamed request is not progress.

### Shared handover requirement

All Bess/ChatGPT, Grok Build, Grok Bot, and replacement engineering sessions must enter through `KEVIN-START-HERE.md`, read `AI-HANDOVER.md`, verify fresh evidence, and reconcile the shared handover after substantive changes. Do not make Matt reconstruct this work from chat history.
