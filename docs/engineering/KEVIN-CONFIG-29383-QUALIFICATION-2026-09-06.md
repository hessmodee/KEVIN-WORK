# Kevin production config `29383...` qualification — 2026-09-06

## Decision

Preserve and newly qualify the exact current production config SHA256:

`29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA`

Do **not** revert to the September 4 exact-five config `DBF596...` merely to satisfy Benchmark R04. The predecessor remains required as provenance/evidence, but the current bytes are the recovery target after independent requalification.

This is a new qualification decision, not a claim that every post-September-4 leaf has complete historical authorship provenance.

## Why v2 safe-stopped

`Repair-Kevin-Recovery-20260906-v2.ps1 -CheckOnly` correctly refused to re-anchor R04 because the current config was not semantically identical to `DBF596...` after excluding only OpenClaw touch metadata. No production mutation occurred.

The follow-up read-only/redacted drift diagnostic found exactly 19 semantic leaf differences: 7 agent-runtime, 11 model-runtime, and 1 path conservatively classified sensitive because it contains `contextTokens`. There were no tool-policy, gateway, plugin, channel, credential, or arbitrary-authority changes in that diff.

## Sanitized reviewed drift

The changes are concentrated in local model behavior and resilience:

- `agents.defaults.models[ollama-chat-16k/qwen2.5:14b]`: `num_ctx=12288`, `temperature=0` added.
- `agents.defaults.models[ollama-chat-16k/llama3.1:8b]`: `num_ctx=12288`, `temperature=0` added.
- main identity emoji changed; this is cosmetic and not an authority surface.
- main model fallback added: `ollama-chat-16k/llama3.1:8b`.
- main `models` empty object added.
- legacy `ollama-chat` Llama tool compatibility changed `supportsTools=false -> true`.
- legacy `ollama-chat.timeoutSeconds=600` added.
- Qwen `ollama-chat-16k` `keep_alive` changed `30m -> 10m`.
- second `ollama-chat-16k` model added: `llama3.1:8b`, text-only, `contextTokens=12288`, `num_ctx=12288`, `temperature=0`, `keep_alive=10m`, `supportsTools=true`.
- `ollama-chat-16k.timeoutSeconds=900` added.

The provider-level Qwen contract remains `contextTokens=16384` and `params.num_ctx=16384`; the 12,288-token agent-default overrides are a separate bounded runtime cap and are not treated as a replacement for the proven 16K provider/model contract.

## Independent evidence used to accept the current state

1. Exact current bytes are pinned to `29383...`; any later config edit invalidates recovery preflight.
2. The September 4 predecessor `DBF596...` is still required to exist as exact bytes in bounded OpenClaw/Maintenance backup locations.
3. Current tool policy remains exact-five only:
   - `kevin_system_status`
   - `kevin_desktop_find_folder`
   - `kevin_desktop_open_folder`
   - `kevin_desktop_list_folder`
   - `kevin_app_launch`
4. All 15 protected global denies remain exact and ordered; no `agents.defaults.tools` widening is permitted.
5. Main remains Qwen primary on `ollama-chat-16k`, with exactly one Llama fallback.
6. Compaction remains `reserveTokensFloor=2048`, `reserveTokens=2048`, `keepRecentTokens=4000`.
7. Native Ollama isolation receipt is fresh and PASS for exactly `llama3.1:8b` and `qwen2.5:14b`; the diagnostic never executes model-returned tools.
8. A later fresh fixed-main canary is `OMEN_PROVEN`, exits zero, returns the exact expected reply, has a complete correlated transcript on `ollama-chat-16k/qwen2.5:14b`, and exposes exactly five Kevin tools.
9. OpenClaw config validation must exit zero and must not change the config SHA.
10. Benchmark must still be exactly 29/30, critical1, with R04 as the sole failure before any re-anchor.

## External contract check

Current OpenClaw Ollama documentation supports explicit native `api: ollama`, provider `timeoutSeconds`, model `params.keep_alive`, `contextTokens`, and `params.num_ctx`. It also says `compat.supportsTools: false` should be used when a model/server reliably fails tool schemas; both required Kevin models independently passed the strict native tool-call isolation proof before this qualification.

References:
- https://docs.openclaw.ai/providers/ollama
- https://docs.openclaw.ai/gateway/config-tools
- https://docs.openclaw.ai/gateway/local-models

## Recovery implication

R04 may now be re-anchored from `DBF596...` to exact `29383...` **only** through Recovery v3 and only after every qualification check above passes on HESS-PC.

Recovery v3 does not introduce a generic semantic-ignore list. It cryptographically pins the current and predecessor config files, validates the reviewed current runtime semantics, requires fresh model/runtime proof, changes only `baseline.hashes.production_config`, and requires a fresh Benchmark 30/30. Failure rolls that baseline leaf back exactly.

After R04 proves green, Recovery v3 backs up/rebuilds only `Kevin UI Bridge v0.3` as Interactive/Limited, requires sustained same-session heartbeat, and runs the existing GREEN Notepad round-trip proof. A UI failure after proven R04 repair is recorded as partial recovery; it does not undo a successfully qualified R04 re-anchor.

## Teach-and-transfer lesson

A frozen production hash is a trust anchor, not a demand to revert every later validated improvement. When an intentional or newly requalified config evolution changes the hash:

1. preserve the previous proven bytes;
2. determine exact semantic drift;
3. independently requalify the new state when historical provenance is incomplete;
4. refuse authority widening;
5. re-anchor only the frozen config leaf;
6. require fresh full regression proof;
7. record the new known-good state and failure lesson.

This exact failure family should become a typed Maintenance recovery path after the platform is green so Kevin no longer needs an external chief engineer to escape an R04 self-repair deadlock.