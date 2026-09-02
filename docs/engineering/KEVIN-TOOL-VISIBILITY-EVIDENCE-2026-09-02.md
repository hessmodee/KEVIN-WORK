# Tool visibility is not tool-use evidence

Read-only classification, 2026-09-02 13:10 UTC. Repository checkpoint: `9ad8f87cccb195e6db655bd729b0a47053115e23`. Named consumer: the fixed main-agent evidence/semantic acceptance boundary, before any tool-policy repair or governed controller qualification.

## Finding

The current public canary reports zero visible tools, but does not publish whether its inventory field existed, was empty, was malformed, or was unsupported by its parser. Consequently, **effective tool visibility is UNKNOWN from this receipt**, not established as empty or disabled. This does not change the separately proven zero tool calls in that canary's complete correlated transcript.

Reviewed repository Maintenance v1.3.43, blob `404ba03ed0eb61d8d4b91e5213219b7b4daa003d`: `Get-ReaderVisibleToolNames` reads only `result.meta.systemPromptReport.tools.entries`. A missing/null result returns an empty list; entries without usable names are silently skipped. `Run-MainAgentCanary` then publishes list count, hash of joined names, Kevin-name count and a Boolean membership test, without a presence/validity discriminator. Its self-test explicitly requires a missing inventory to return an empty list. The helper is byte-identical in repository v1.3.44, blob `2e80d7f528a230f74e3bd8d7a16193911d50405b`.

| Input condition in reviewed source | Published interpretation | Safe conclusion |
|---|---|---|
| Recognized path absent/null | zero, empty-list hash, false membership | inventory not observed |
| Explicit empty recognized array | same outputs | reported inventory empty, only if presence/type is separately retained |
| Nonempty entries with no usable names | same outputs | malformed/unsupported inventory, not proven empty |
| Valid recognized named entries | count/names-derived metadata | reported inventory observed; actual execution remains separate |

This is a source-derived finding, not a new executed PowerShell test or an Omen repair. The installed Maintenance hash remains `FF9C5FDF217B0ED5F38A8566BD54D8A654CB8DFEF0093654DDBC23DC9A1BF956`, labeled locally `1.3.43+modelid`; its complete modified-source provenance is unresolved. Do not assume the reviewed repository file is byte-identical to that runtime, or assert which input condition produced the latest zero.

## What remains proved

The September 1 23:02:44 MDT canary receipt, blob `508ef5ca367c386cf5fd992def41770c252d3909`, establishes healthy Gateway transport, a real fixed-main turn, exact expected reply, and zero tool calls from a complete correlated transcript. It deliberately requests no tool calls. That proves neither unavailable tools nor useful tool execution. Do not rerun this satisfied test to discover availability.

Fresh Support at September 2 07:04:59 MDT and Engineering at 07:04:46 show healthy schedulers, NO_MANIFEST, Benchmark 30/30 critical zero and a fresh 0.5-second UI heartbeat. Continuation at 07:05:09 is legitimate idle with zero eligible items, outcome false and tool-use telemetry UNKNOWN. No new runtime incident is inferred.

## Qualification target, not new execution authority

Current official OpenClaw documentation distinguishes the agent catalog (`tools.catalog`) from session-effective inventory (`tools.effective`, read-only, requiring a session key). Effective inventory derives trusted context server-side and can report incomplete/warm-MCP notices. A catalog or context estimate is not a record of actual execution. [Gateway protocol](https://docs.openclaw.ai/gateway/protocol), [Context reports](https://docs.openclaw.ai/concepts/context).

These are current upstream capabilities, **not proven supported by the installed Omen version**, which the older capability receipt records as UNKNOWN. No probe was enqueued and no endpoint was invoked on Omen. A future qualified fixed diagnostic must first verify installed version/source/support; accept no caller-selected command, endpoint, agent/session, path or private body; reuse current authentication without expanding permissions; emit only bounded sanitized metadata.

Its acceptance must distinguish inventory `UNKNOWN`, `INVALID`, `REPORTED_EMPTY` and `REPORTED_NONEMPTY`; retain recognized-source presence/type and correlation; treat unsupported versions as UNKNOWN; reject malformed or contradictory evidence. For session-effective probes preserve truncation/incomplete-catalog notices. Neither missing metadata nor catalog presence grants tool authority. Actual-use acceptance still requires a correlated real permitted tool action and an independent useful semantic postcondition.

This is the immediate main-agent evidence gate, while authenticated history migration and fixed Supervisor integration remain unresolved. The journal candidate retains its existing CI proof; no new journal candidate or retry was created. No live budget, tool policy, runtime code, completed work, trust anchor, Maintenance manifest or isolation hold changed. Work-selection responsibility remains T2.
