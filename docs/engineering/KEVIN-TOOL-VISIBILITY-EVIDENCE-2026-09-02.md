# Fixed:main tool visibility — fresh evidence and repair boundary

Reconciled 2026-09-02 after the owner created a fresh Kevin session following the context/compaction repair.

## Current finding

The earlier public main-canary receipt was not sufficient to prove that the fixed:main tool inventory was actually empty because the reviewed parser collapsed missing/unsupported inventory metadata to an empty list.

That ambiguity is now resolved for the fresh owner session by direct OpenClaw `/context detail` evidence. In that session OpenClaw reported:

- Tool list (system prompt text): 0 chars / 0 tools
- Tool schemas (JSON): 0 chars / 0 tools
- Tools: `(none)`

Therefore the current fresh fixed:main owner chat was **genuinely tool-empty at the model context boundary**. A normal text reply from that session proves conversation transport/model response, but it does not prove useful local tool execution.

This is now a P0 capability gap because Matt's current objective is for Kevin to perform useful authorized GREEN work, diagnose/repair himself, learn procedures, and progressively eliminate routine dependence on Bess/Grok/Matt.

## Historical policy context

Production Chat had previously been intentionally narrowed to a tool-free or nearly tool-free posture while Reader/action capabilities were isolated behind separate governed paths. That historical design explains why tool absence may be policy rather than a model defect; it does not make the present tool-empty state sufficient for the new autonomy objective.

Do not jump from "tools are empty" to "give Kevin full coding/exec authority." The correct repair is a narrow, explicit, auditable GREEN tool surface that is sufficient for useful work while retaining protected boundaries.

## Current OpenClaw upstream policy model

Current official OpenClaw documentation says:

- `/context detail` reports the actual tool list and tool-schema contribution placed in the current model context.
- `tools.profile` creates the base tool allowlist before `allow`/`deny` filtering.
- `minimal` contains only `session_status`; `coding` contains broad filesystem/runtime/web/session/memory/cron/goal/Skill Workshop capabilities and is therefore too broad to adopt blindly for Kevin.
- `deny` wins, and a non-empty `allow` blocks everything not explicitly allowed.
- tool availability can be further restricted by global policy, provider policy, per-agent policy, agent+provider policy, sandbox policy, channel/sender policy, and plugin availability.
- `tools.catalog` is a read-only runtime catalog for an agent, while `tools.effective` is the session-scoped runtime-effective inventory and requires a session key; the Gateway derives trusted context server-side.
- `openclaw config get <path> --json` reads the redacted config snapshot; secrets are not printed.

Primary references:
- https://docs.openclaw.ai/concepts/context
- https://docs.openclaw.ai/gateway/config-tools
- https://docs.openclaw.ai/tools/multi-agent-sandbox-tools
- https://docs.openclaw.ai/gateway/sandbox-vs-tool-policy-vs-elevated
- https://docs.openclaw.ai/gateway/protocol
- https://docs.openclaw.ai/cli/config

## Diagnostic target — fixed input, metadata only

Before any tool-policy mutation, Kevin needs a governed read-only diagnostic that uses fixed paths/agent identity and publishes only bounded sanitized metadata.

It should determine, for `main` only:
1. root `tools.profile` state;
2. root `tools.allow`, `tools.alsoAllow`, and `tools.deny` presence/count/hash;
3. per-main `agents.entries.main.tools.*` state;
4. provider-specific root and per-main policy layers for the resolved provider/model;
5. sandbox/channel/sender policy layers that can further restrict the current owner session;
6. `tools.catalog` support/result classification when supported by the installed runtime;
7. `tools.effective` support/result classification for a fixed correlated fresh main session key when supported;
8. explicit distinction among `UNKNOWN`, `INVALID`, `REPORTED_EMPTY`, and `REPORTED_NONEMPTY`.

The public receipt should not publish config bodies, tokens, credentials, private messages, arbitrary paths or arbitrary command output. Tool names may be reduced to count + deterministic hash if needed; known required Kevin tool membership can be emitted as booleans.

## Initial repair philosophy

Do not set `tools.profile=full` or enable broad host exec merely to make the tool count nonzero.

A first useful production-chat tool surface should be the smallest set that lets Kevin inspect state, manage durable goals/tasks/memory, invoke already-governed typed Kevin mechanisms, and verify outcomes. Any host/runtime/file mutation capability must stay behind existing typed/preconditioned mechanisms or a separately proven narrow primitive.

The repair candidate should prefer one of these patterns after exact installed-schema confirmation:

- a narrow per-main `tools.profile` plus `alsoAllow` for specifically proven tools; or
- a non-empty per-main `allow` containing only the explicitly approved tool IDs.

Never combine `allow` and `alsoAllow` in the same scope; current OpenClaw validation rejects that combination.

Protected tools/actions remain denied unless separately authorized and proven: arbitrary `exec`/`process`, unrestricted `write`/`edit`/`apply_patch`, arbitrary browser submission, arbitrary message/send, subagent spawning, authority/permission editing, credential access, purchases, money movement, live trades, or owner-representing external sends.

## Production-change acceptance

A tool-policy repair is not complete because a config write validated. Require:
1. exact pre-change config SHA and backup;
2. fixed path/schema lookup and redacted current-value diagnosis;
3. dry-run of the minimum policy change;
4. config validation;
5. semantic JSON diff proving only expected leaves + benign metadata changed;
6. rollback on any mismatch;
7. Gateway reload/restart only if the installed version requires it;
8. a **new fixed:main owner session**;
9. `/context detail` or `tools.effective` proving the exact intended effective inventory, not merely catalog presence;
10. one correlated useful allowed tool action with independent semantic postcondition;
11. forbidden-tool negative tests proving the protected surface stayed unavailable;
12. fresh Benchmark 30/30 and Support proof;
13. durable lesson and transfer evidence so Kevin can detect/repair future tool-policy drift.

## Separate Dashboard truth defect

Fresh `reports/dashboard-state.json` currently labels Kevin's brain context as `8K` and tools as `false`. Repository source `workspace/helper_dashboard_state.py` contains those values as hard-coded constants rather than deriving them from current runtime evidence.

Because the published Dashboard currently reports schema 5 while the repository helper source emits schema 3, the repository copy is not proven byte-identical to the live publisher. Treat this as a **truth/observability defect requiring source-provenance recovery before deployment**, not as permission to overwrite the live dashboard helper.

The direct `/context detail` evidence (16,384 context ceiling and zero tools) outranks those hard-coded HQ labels.

## Responsibility-transfer state

Main useful tool execution remains below T4. The next transfer target is not merely "show Kevin tools"; it is a Kevin-owned loop that can detect effective inventory drift, select the safe repair only when exact preconditions match, verify a real useful tool outcome, preserve negative boundaries, and recover/rollback without routine Bess/Grok/Matt intervention.
