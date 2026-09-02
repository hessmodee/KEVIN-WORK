# Lesson: fixed:main Qwen context overflow + compaction hardening

Updated: 2026-09-02
Failure family: `fixed_main_context_overflow_compaction_budget`
Status: symptom repaired and owner-observed; autonomy transfer still incomplete until Kevin owns detection + repair + verification.

## Proven/observed outcome

Historical `run_main_agent_canary` reached **OMEN_PROVEN** exact `KEVIN_MAIN_AGENT_CANARY_OK` on `ollama-chat-16k/qwen2.5:14b` after the original 16k migration.

On 2026-09-02, the main owner chat later reproduced OpenClaw's context/auto-compaction failure. The repair was deliberately narrow and validated in two steps:

1. Add `agents.defaults.compaction.reserveTokens=2048` while preserving `reserveTokensFloor=2048`.
2. Add `agents.defaults.compaction.keepRecentTokens=4000` while preserving the 16k main provider/model context contract.

Owner terminal evidence reported the final validated configuration SHA256:

`23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5`

After the repair:
- a fresh Kevin owner chat produced a normal reply;
- `/context detail` showed the fixed:main session below the 16,384-token ceiling;
- manual `/compact` completed successfully instead of reproducing the prior recovery failure;
- OpenClaw config validation returned valid/no warnings during both mutations.

Latest Support after the intentional config change showed Benchmark **29/30**, with only R04 `Production config frozen`. Treat this as an expected stale baseline after an intentional validated config mutation, not as evidence that the compaction repair itself failed. Restore 30/30 through the governed production-config rebaseline path; do not revert the good config merely to match the stale hash.

## Cause chain Kevin must remember

1. An unpinned main historically inherited llama3.1:8b.
2. An 8k Qwen pin overflowed even with lean bootstrap + empty skills + `reserveTokensFloor=2048`.
3. HESS-PC has 32GB RAM; bounded 16k Qwen is feasible, while resource limits still matter.
4. The 16k main model alone did not eliminate all compaction edge cases: the 2026-09-02 failure showed that reserve/tail behavior also needed an explicit bounded policy.
5. Intentional `openclaw.json` mutations change the production-config SHA and therefore make Benchmark R04 fail until the fixed baseline is intentionally re-established.

## Standing known-good policy for this failure family

- Main model: `ollama-chat-16k/qwen2.5:14b`
- Provider/model context: 16384
- Ollama `num_ctx`: 16384
- main skills: empty unless a separately proven context-budget change says otherwise
- `agents.defaults.compaction.reserveTokensFloor=2048`
- `agents.defaults.compaction.reserveTokens=2048`
- `agents.defaults.compaction.keepRecentTokens=4000`
- preserve lean bootstrap/context discipline
- after an intentional validated `openclaw.json` change, rebaseline `reports/benchmark-v1/baseline.json` `hashes.production_config` only through the governed baseline path and require fresh Benchmark 30/30
- never strip canary output or weaken R04 to manufacture a pass

## Detection procedure Kevin should own

When fixed:main shows an auto-compaction recovery banner, context-length error, repeated turn failure, or sudden inability to compact:

1. Preserve the failing session/evidence before destructive reset.
2. Verify current main model reference, provider context, `num_ctx`, `reserveTokensFloor`, `reserveTokens`, and `keepRecentTokens` using fixed read-only configuration queries.
3. Verify `openclaw config validate --json` is clean.
4. Measure the actual session/context state; do not infer effective context merely from a provider name containing `16k`.
5. Classify whether the problem is configuration drift, oversized bootstrap/session state, model/runtime behavior, or a different failure family.
6. Only apply this known repair automatically when the exact preconditions match. Otherwise collect evidence and form a new bounded hypothesis.

## Known repair procedure to transfer into a typed Kevin path

For the exact preconditioned case where main is the known 16k Qwen contract, `reserveTokensFloor=2048`, and the explicit reserve/tail settings are missing or drifted:

1. back up `~/.openclaw/openclaw.json` and verify its SHA;
2. dry-run each single OpenClaw config mutation;
3. apply `reserveTokens=2048`, validate, and verify the semantic leaf diff;
4. apply `keepRecentTokens=4000`, validate, and verify the semantic leaf diff;
5. prove no unrelated semantic config change except expected metadata timestamps;
6. start/use a fresh fixed:main session and require a normal model turn;
7. prove compaction succeeds on a representative bounded session;
8. rebaseline R04 only after the config is intentionally accepted;
9. require fresh Benchmark 30/30 and Support health;
10. preserve rollback hashes and the reusable lesson.

## Negative/rollback requirements

The future typed repair must refuse to mutate when:
- the main model/provider is not the expected contract;
- provider context or `num_ctx` differs unexpectedly;
- existing reserve values contain an unknown non-target value;
- config validation fails;
- the pre-change hash changes between precheck and mutation;
- the change would modify unrelated semantic leaves;
- rollback backup cannot be verified.

On failed postcondition, restore the exact verified pre-change configuration and revalidate.

## Responsibility-transfer debt

The 2026-09-02 repair still required outside diagnosis and owner terminal execution, so it is not SELF-RELIANT. The next transfer target is a fixed-input detector + typed repair/rebaseline verifier that Kevin can select, execute, verify, and learn from without Matt/Bess/Grok at the keyboard.

Do not mark this lane T4/T5 until Kevin independently demonstrates recurrence detection, bounded repair, semantic verification, R04 handling, restart/replay, and a subsequent correct decision.