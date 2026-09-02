# Fixed-main hypothesis — 2026-09-01

Consumer: fixed-main acceptance gate (`run_main_agent_canary` / exact `KEVIN_MAIN_AGENT_CANARY_OK`).
Author: GrokBot foreground takeover. Status: RESEARCH — not a canary grant.

## Evidence (fresh)

- Public canary `reports/main-agent-canary-public.json` at 2026-09-01T19:15:10-06:00: state REJECT, failure_stage semantic_contract, final_length 145, contains expected, not exact, tool_calls 0, visible_tool_count 8, visible_kevin_tool_count 0, qwen_soft_no_think true, gateway_probe_ok true, agent fixed:main, runner 1.3.43.
- Correlated local session `agents/main/sessions/b4c2e9a3-d2fd-45c7-8e52-814575128617.jsonl` (metadata only): provider ollama, assistant modelId **llama3.1:8b**, assistant content_len 145, contains token, not exact. Matches public output_sha256 prefix.
- Config: `openclaw.json` agents.list id=main has no model override; agents.defaults.model.primary = `ollama/llama3.1:8b`; tools.profile=coding with broad deny; Reader tools.allow retains kevin_* separately.
- Canary implementation in `kevin-maintenance-runner.ps1` Run-MainAgentCanary hardcodes message ending in `/no_think` and always `--agent main`. Therefore the "/no_think on Qwen" experiment never resolved Qwen — it ran on llama.

## Hypotheses

1. **H1 CONFIRMED (model identity):** Exact semantic failure is explained by resolved model llama3.1:8b under long AGENTS.md/SOUL.md bootstrap expanding the token into a 145-char prose line. `/no_think` is a no-op / noise on this path.
2. **H2 CONFIRMED (tool surface):** Zero Kevin-prefixed tools because Chat/main exposes coding builtins after deny, not Reader kevin_* registration. Separately, models catalog marks supportsTools=false for both llama3.1:8b and qwen2.5:14b.

## Failure family

`response-behavior/wrong-resolved-model`. Record `/no_think` as **negative evidence on llama path**, not as a Qwen disproof.

## Next material experiment (NOT RUN in this note)

Do **not** rename v1.3.43. Qualify a maintenance-runner change that:

1. Records resolved `modelId` / provider in the **public** canary receipt (from transcript model_change / assistant message model — no raw text).
2. Either (A) pins agent `main` (or defaults) to the intended Kevin brain `ollama-chat/qwen2.5:14b` via an exact typed config crossing with hash proofs, **or** (B) introduces a dedicated minimal-bootstrap canary agent used only by the canary, without weakening exact semantics.
3. Removes the false claim that `/no_think` proves a Qwen hypothesis unless modelId is qwen.
4. Keeps exact case-sensitive final reply acceptance; no stripping; no blind downgrade.
5. Separately decide (design, not auto-expand) whether main **should** see any kevin_* tools; do not add tools only to green a test.

## UI Bridge (parallel, done)

- SelfTest PASS.
- Scheduled RunLoop had LastTaskResult 0xC0000005; heartbeat stale.
- Typed `restart_ui_bridge` APPLIED_PREAUTHORIZED_PROVEN at ~21:04 MDT; fresh READY heartbeat.