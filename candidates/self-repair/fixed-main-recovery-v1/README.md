# Fixed:main recovery candidate v1

Status: **CANDIDATE ONLY — NO PRODUCTION EFFECT**
Authority delta: **NONE**
Consumer: current P1 autonomy-debt retirement for fixed:main context/compaction and tool-policy drift.

## Why this exists

The 2026-09-02 owner repair proved a narrow known-good fixed:main configuration:

- `ollama-chat-16k/qwen2.5:14b`
- provider/model `contextTokens=16384`
- Ollama `params.num_ctx=16384`
- `agents.defaults.compaction.reserveTokensFloor=2048`
- `agents.defaults.compaction.reserveTokens=2048`
- `agents.defaults.compaction.keepRecentTokens=4000`

A fresh main session replied normally and manual compaction succeeded, but the repair still required outside diagnosis/owner terminal execution. The same fresh `/context detail` also proved the session's effective tool inventory was empty.

This package turns the repeated reasoning into deterministic candidate code that Kevin can later consume through a governed typed repair. It does **not** edit a config, run OpenClaw, rebaseline Benchmark, restart Gateway, or grant tools.

## Contract

`contract.py` provides pure functions only:

1. classify a supplied OpenClaw JSON object against the known fixed:main contract;
2. decide whether the exact known compaction repair is safe to propose;
3. produce only the two known `config set` intents when the corresponding values are absent;
4. reject unknown/non-target values rather than overwriting them;
5. calculate semantic leaf differences while ignoring only benign OpenClaw metadata touch fields;
6. prove a before/after diff contains no unrelated semantic mutation;
7. classify root/per-main tool policy surfaces without claiming runtime-effective inventory.

The code intentionally does not accept a caller-selected filesystem path or command.

## Required future live wrapper

Before this candidate can become an installed Kevin repair path, a Windows/OpenClaw wrapper must hard-code the active config location and:

- verify pre-change SHA256 and an exact backup;
- use redacted/fixed `openclaw config get` and `config.schema.lookup` where applicable;
- dry-run each config mutation;
- run full config validation;
- verify semantic leaf diff;
- rollback exact bytes on any mismatch;
- prove a new fixed:main turn and successful `sessions.compact` or equivalent current compaction path;
- reconcile Benchmark R04 through the fixed governed baseline contract;
- require fresh Benchmark 30/30 and Support evidence.

For tool-policy work, the live wrapper must additionally inspect `tools.catalog`/`tools.effective` where supported, prove the exact session-effective inventory, and run allowed + forbidden negative tests. This candidate does **not** authorize a tool grant.

## Failure-budget rule

Do not rename this candidate or failure family to reset retries. The family is:

`fixed_main_context_overflow_compaction_budget`

Unknown model/provider/context/reserve values are a new diagnostic condition, not permission to force the known repair.
