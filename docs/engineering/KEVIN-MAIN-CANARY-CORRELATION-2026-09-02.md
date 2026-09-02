# Main-canary correlation boundary — September 2, 2026

Reviewed checkpoint `51d4bcf7ff68e86978ad08190a377a8bf5d2b501` at15:26 UTC. Consumer: existing main-agent qualification and Reader closure; evidence/continuity only, no new production request.

## Current result

At09:17 MDT September2 Benchmark is PASS30/30 critical0, corroborated by Support09:20 and Engineering09:22; all listed core schedulers have errors0. R05/R11 are no longer current failures. The newer fixed-main canary at09:00:25 is REJECT/semantic_contract despite healthy Gateway and agent exit0. It reports a non-exact127-character reply and incomplete/uncorrelated transcript (zero user messages, one assistant); overall tool_calls=null. The partial transcript's zero must not be described as a proven zero-call turn.

Sources: [Support](https://github.com/hessmodee/KEVIN-WORK/blob/51d4bcf7ff68e86978ad08190a377a8bf5d2b501/reports/support-latest.json), [Engineering](https://github.com/hessmodee/KEVIN-WORK/blob/51d4bcf7ff68e86978ad08190a377a8bf5d2b501/reports/engineering/latest.json), [main canary](https://github.com/hessmodee/KEVIN-WORK/blob/51d4bcf7ff68e86978ad08190a377a8bf5d2b501/reports/main-agent-canary-omen.json). Support and Engineering corroborate the same Benchmark execution, not two distinct Benchmark trials. Unchanged Benchmark source hash does not prove the repair mechanism, approved config identity or absence of local trust changes; provenance remains unresolved and desired-state anchors are not blessed.

## Failed-request evidence, not permission to retry

The typed request `main-canary-morning-reaffirm-20260902-0857` was staged in49b1c58d7acc146b19bf667670078d363f3ec65a. Its operation is run_main_agent_canary; no caller-selected prompt or session. It was [archived](https://github.com/hessmodee/KEVIN-WORK/blob/51d4bcf7ff68e86978ad08190a377a8bf5d2b501/inbox/maintenance/archive/main-canary-morning-reaffirm-20260902-0857.json) and removed in a0102328e28dc6f6dbc415b6454255f3a5469e28. Fresh Maintenance09:19 reports NO_MANIFEST/errors0. Do not restore it.

Four published receipts at08:59:27,08:59:42,08:59:57 and09:00:25 all report semantic_contract, transcript complete=false, user_messages0/assistant_messages1 and top-level tool_calls=null. Their transcript hashes differ. Preserve all four revisions:

- 5549300880dd1c499c519807d27c94af85a93c22
- edb29e2f6c248c578c2a1cd8088a24162b76b3a4
- a6fb2f1f9e885f56b51f5f7d82f6539928d7c7a9
- 29918d21fa23b9c2263b3ddc63dccd7e4dad5a93

These are observed receipt revisions, not proof of four materially distinct repair attempts, four independent requests, or a complete retry ledger. No budget is replenished or silently rewritten. Existing benchmark_not_pass attempts3 remain recorded even though platform health now passes. The same model/provider labels are reported (qwen2.5:14b/ollama-chat-16k); labels alone do not prove unchanged complete runtime/config identity.

## Narrow diagnosis and qualification limits

The published [Maintenancev1.3.44 source](https://github.com/hessmodee/KEVIN-WORK/blob/51d4bcf7ff68e86978ad08190a377a8bf5d2b501/control-plane/maintenance/kevin-maintenance-runner-v1.3.44.ps1), blob2e80d7f528a230f74e3bd8d7a16193911d50405b, requires a matching session header, exactly one matching user message, an assistant terminal record and an accepted stop reason before transcript completeness. Thus user_messages0 cannot qualify a complete turn under that source contract. The receipt does not say why that event is missing or whether the selected transcript is the correct one.

Installed Maintenance SHA256 is 3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E; its patched source and exact transaction lineage remain unpublished. Do not attribute the reviewed source byte-for-byte to Omen. Do not infer that a partial transcript proving zero observed calls proves no calls elsewhere. Effective tool inventory remains UNKNOWN, separately from tool-use evidence. Earlier September1 exact-reply/complete-zero-call proof remains historical, not current acceptance.

[Existing transcript tests](https://github.com/hessmodee/KEVIN-WORK/blob/51d4bcf7ff68e86978ad08190a377a8bf5d2b501/tools/test-canary-transcript.ps1) cover identity, prompt mismatch, exact output, tool counting and path escape; they do not establish the installed runtime's current request/session recording. No model/provider behavior diagnosis or upstream version compatibility is claimed by this source-only review.

Before another main canary, obtain materially new fixed read-only evidence of installed source/version and exact request/session/transcript correlation. Determine whether missing user events arise from the invocation, returned session identity, transcript selection, recording or parser contract; none is yet established as root cause. Preserve fail-closed acceptance; no Gateway repair, model switch, tool-policy widening, correlation bypass, renamed retry or budget reset on this evidence. Reader's08:28 receipt still reports2/2; obtain existing typed terminal receipt and exact patched-source/negative-test evidence before FULL COMPLETE, not another canary solely to refresh the label.

## Reader, state and ownership

[Reader receipt](https://github.com/hessmodee/KEVIN-WORK/blob/51d4bcf7ff68e86978ad08190a377a8bf5d2b501/reports/reader-canary-omen.json) at08:28:45 again reports2/2, one status-tool call per trial, six categories and semantic/privacy flags true. Source/proof limitations from [prior review](https://github.com/hessmodee/KEVIN-WORK/blob/51d4bcf7ff68e86978ad08190a377a8bf5d2b501/docs/engineering/KEVIN-READER-BENCHMARK-BOUNDARY-2026-09-02.md) persist. Benchmark recovery removes the currently observed R05/R11 health blocker, but does not by itself prove APPLIED_PREAUTHORIZED_PROVEN for that Reader request or full correct sensor interpretation. The referenced predicate-fix proof file remains absent in the reviewed tree. Preserve OMEN_PROVEN-but-blocked inventory and its three attempts; do not update prose there merely to trigger fingerprint/budget churn.

CURRENT_TASK and canonical continuity must stop instructing recovery of now-passing R05/R11 or treating the previous main-canary pass as current. This is continuity correction, not a dispatch. Foreground work retains priority if a new lock/request appears. No active Maintenance manifest or repository lock was found; zero workers is not proof that the foreground session has ended. No second crossing is created.

Continuation09:20 remains IDLE_NO_ELIGIBLE_DEMAND/eligible0/outcome_proven=false/tool telemetry UNKNOWN. Four COMPLETE closures remain preserved; no new Forge evaluation beyond391. Autonomy09:17 is NEEDS_REVIEW/drift1; do not call this full desired-state convergence. Scope of the missing-isolation hold is unchanged; OK-WRITE is already satisfied.

Latest selector CI33641424007 and Autonomy OS CI33641423894 passed on482fa5fc0e94c4e7c83158205f38e6bc54ff2d91. Older Supervisor proof workflows still fail. No CI, runtime repair, policy change, test weakening, new retry or promotion was performed here. Journal candidate remains uninstalled; authenticated migration, fixed integration and hard process supervision remain outstanding. Work selection staysT2 and ReaderT1; no Bess responsibility retired.
