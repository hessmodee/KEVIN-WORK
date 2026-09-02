# Fixed:main tool visibility — fresh evidence and repair boundary

Reconciled 2026-09-02 after the owner created a fresh Kevin session following the context/compaction repair and after version-qualified research of installed OpenClaw `2026.7.1-2` (`0790d9f`).

## Current finding

The fresh owner session's direct OpenClaw `/context detail` reported:

- Tool list (system prompt text): 0 chars / 0 tools
- Tool schemas (JSON): 0 chars / 0 tools
- Tools: `(none)`

Therefore current fresh fixed:main owner chat is **genuinely tool-empty at the model context boundary**. A normal text reply proves chat transport/model response but not useful local execution.

Historical production Chat was intentionally tool-free or nearly tool-free while Reader/action capabilities were isolated behind separate governed paths. Tool absence can therefore be policy, not a model defect. The new autonomy objective requires a useful owner-intent/control surface, but does **not** justify broad coding/exec/file/browser/messaging authority.

## Installed-version policy model — 2026.7.1-2

The installed version matters because current OpenClaw docs increasingly use newer schema names.

For `2026.7.1-2`:
- per-agent configuration uses `agents.list[].tools.*` naming; newer builds/docs may show `agents.entries.*.tools.*`;
- `tools.profile` establishes a base allowlist before allow/deny filtering;
- `tools.allow`/`tools.deny` apply globally and deny wins;
- provider-specific policy can further restrict tools;
- `agents.list[].tools.profile/allow/deny/byProvider` can further restrict the main agent;
- sandbox tool policy is another restriction layer when applicable;
- sender/channel/plugin/model support can also affect the final model-visible set;
- an explicit non-empty allowlist behaves as allow-only for that scope;
- `allow` and `alsoAllow` must not be combined in the same scope.

The exact-version documentation exposes a fixed read-only diagnostic:

`openclaw sandbox explain --agent main --json`

It reports effective sandbox/tool-policy context and is suitable for a sanitized fixed-input diagnostic wrapper. It must not be mistaken for a complete proof of model-visible tools if additional provider/channel/plugin filtering remains.

### Known 2026.7.1-2 defects that affect acceptance

Upstream issue `openclaw/openclaw#111570` reports `agents.list[*].tools` hot-reload can leave Telegram/channel workers on stale policy until a full Gateway restart even when fresh CLI turns see the new policy. Therefore after any policy mutation Kevin must separately prove:
1. config accepted;
2. fresh main session policy;
3. owner-channel policy after the required reload/restart path.

Upstream issue `openclaw/openclaw#114065` reports agent-scoped allowlists can leak a built-in tool such as `session_status` into the provider-visible set. Therefore a positive allowed-tool proof is insufficient. Every production tool-policy crossing must include explicit forbidden-tool negatives.

Current upstream docs also reiterate that deny wins, profiles are base sets, and a broad `coding` profile includes filesystem/runtime/web/session/memory/cron/goal surfaces. That profile is too broad to adopt blindly for Kevin.

Research references:
- `https://docs.openclaw.ai/gateway/config-tools`
- `https://docs.openclaw.ai/tools/multi-agent-sandbox-tools`
- `https://docs.openclaw.ai/gateway/sandbox-vs-tool-policy-vs-elevated`
- `https://github.com/openclaw/openclaw/issues/111570`
- `https://github.com/openclaw/openclaw/issues/114065`
- Fossies `2026.7.1-2` vs newer docs diffs for exact-version `agents.list[]` naming and sandbox-explain behavior.

## Diagnostic target — fixed input, metadata only

Before any tool-policy mutation, Kevin needs a governed read-only diagnostic for `main` only. It should use fixed paths/agent identity and publish bounded sanitized metadata.

Required observations:
1. root `tools.profile` state;
2. root `tools.allow`, `tools.alsoAllow`, `tools.deny` presence/count/hash;
3. per-main `agents.list[]` entry identity and `tools.profile/allow/alsoAllow/deny` presence/count/hash;
4. provider-specific root + per-main policy for resolved `ollama-chat-16k/qwen2.5:14b`;
5. sandbox policy and `openclaw sandbox explain --agent main --json` classification;
6. channel/sender/plugin restrictions when relevant to the owner Control UI path;
7. runtime tool-catalog/effective inventory if those RPCs exist in the installed build;
8. direct fresh `/context detail` tool count/schema count;
9. explicit distinction among `UNKNOWN`, `INVALID`, `REPORTED_EMPTY`, and `REPORTED_NONEMPTY`.

Public evidence must not publish config bodies, tokens, credentials, private messages, arbitrary paths, or arbitrary command output. Tool lists may be represented as count + deterministic hash plus booleans for a small policy-owned required/protected set.

## Initial target surface

Do **not** optimize for the largest tool catalog. Optimize for the smallest useful owner-intent/control interface.

A first useful main surface should let Kevin:
- inspect safe state needed to understand owner requests;
- read governed workspace/goal state where authorized;
- create/update durable owner goals/tasks/plans or submit intent to already-governed control-plane mechanisms;
- inspect execution/result status;
- preserve handoff/memory where the existing typed boundary permits it.

Consequential execution should remain behind existing typed/preconditioned mechanisms rather than giving main arbitrary host control.

Protected surfaces remain unavailable unless separately authorized and proven: arbitrary `exec`/`process`, unrestricted `write`/`edit`/`apply_patch`, arbitrary browser submit, arbitrary-recipient messaging, subagent spawning, permissions/authority editing, credential access, purchases, money movement, live trades, or owner-representing third-party sends.

## Production-change acceptance

A tool-policy repair is not complete because config validation passes. Require:
1. exact pre-change config SHA and verified byte backup;
2. fixed redacted diagnosis of all relevant policy layers;
3. dry-run of the minimum exact change;
4. full config validation;
5. semantic JSON diff proving only expected leaves + benign metadata changed;
6. exact rollback on mismatch;
7. correct reload/restart behavior for `2026.7.1-2` rather than assuming hot reload reaches channel workers;
8. a **new fixed:main owner session**;
9. `/context detail` and/or runtime-effective evidence proving intended inventory;
10. one correlated useful allowed action with independent semantic postcondition;
11. explicit protected-tool negative tests, including built-in leakage checks;
12. owner-channel proof after restart/reload when channel worker caching is relevant;
13. fresh Benchmark30/30 and Support proof;
14. durable lesson and transfer evidence so Kevin detects/repairs future policy drift himself.

## Separate Dashboard truth defect

Fresh dashboard/HQ telemetry labels Kevin's brain context as `8K` while direct owner evidence proves a 16,384-token ceiling. An older repository source `workspace/helper_dashboard_state.py` contains hard-coded context/tool values, but live Dashboard emits schema5 while that helper emits schema3. The repository helper is therefore not proven byte-identical to the live publisher.

Treat this as a truth/observability defect requiring live publisher provenance recovery before deployment. Do not overwrite the live helper with the older source merely to change the number.

## Responsibility-transfer state

Main useful tool execution remains below T4. The target is not merely "show Kevin tools". The target is a Kevin-owned loop that can detect effective inventory drift, diagnose the policy layer, choose only the approved narrow repair, verify allowed + forbidden behavior, preserve evidence, and rollback/recover without routine Bess/Grok/Matt intervention.
