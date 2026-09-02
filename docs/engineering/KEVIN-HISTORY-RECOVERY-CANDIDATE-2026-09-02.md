# Read-only attempt-history recovery candidate

Consumer: next governed Supervisor history-preservation/migration qualification. Scope: one completed isolated staging/evaluation item; no production crossing. Technical state: CI-PROVEN read-only recovery candidate, not installed or runtime-repaired. Work-selection transfer remains T2.

## Why recovery precedes installation

The v1.8.8 history file has already overwritten a staging fingerprint. A replacement that only stops future resets cannot recover those old records by reading that file. This candidate reconciles exact-byte, previously published public receipts into a review proposal. It has no runtime integration, network or execution mechanism, automatic bootstrap, permission change, budget reset, or migration write.

Inputs are the receipts at `85e1593c7a098a0c07d61b4c825b92d19603968c` (September 1 22:14 MDT) and `bed003fa48c83eb8c78169786777ba753115581f` (September 2 03:09 MDT). Fixtures retain their exact original UTF-8 text and expected Git blob identities; replay verifies those identities and supplies SHA-256 input digests. Digests prove byte integrity, not trusted publisher identity or authorization.

## Reconciliation contract

- Preserve observations under item plus fingerprint; repeated snapshots do not add attempts.
- Retain the maximum observed count per fingerprint and all source references. A->B->A counter/time regressions remain visible and explicitly flagged.
- Do not assume that sums of counters across fingerprints are exact lifetime totals: a reservation may appear under multiple fingerprints. Report those sums separately. The observed lower bound uses the largest counter plus distinct later attempt timestamps beyond that counter's last turn.
- Never infer a failure-family mapping from prose or an item rename. Optional reviewed mappings produce advisory sums only, not certified disjoint family-attempt totals or eligibility.
- Reject absent/empty/error history, duplicate JSON keys or snapshot IDs, bad lineage, invalid/future timestamps, corrupt input, invalid count types and mismatching source digests. No invalid input becomes a zero budget.
- Return `REQUIRES_VALIDATED_MIGRATION`, `history_complete=false`, `remaining_budget=null`, `reopen_authorized=false` and authority NONE on every successful reconciliation.
- Omit arbitrary receipt fields from output. No private body, prompt, tool output or caller-provided prose is copied into the proposal.

The two reviewed receipts preserve HQ's observed three turns and staging's earlier three-turn fingerprint plus a later one-turn fingerprint. Staging's observed lower bound is four turns, not the one shown in the latest row. This is attempt evidence, not successful work or proof of unsafe execution. Missing tool telemetry remains UNKNOWN.

## Tests and limits

Eighteen local unit tests pass, including exact published Git blob verification, repeated-snapshot deduplication, order independence, A->B->A, same-reservation cross-fingerprint duplication, corruption, missing state, bad counts/timestamps, source conflicts, family ambiguity, privacy and input immutability. [CI run33613649441](https://github.com/hessmodee/KEVIN-WORK/actions/runs/33613649441) passed those same 18 tests on Linux and Windows at exact [candidate commit e51132024dfd8b762506f4b0c66a03eafcd8d53f](https://github.com/hessmodee/KEVIN-WORK/tree/e51132024dfd8b762506f4b0c66a03eafcd8d53f). Independently read logs for jobs100194405092 and100194405322 show exact receipt replay and all489 tracked files byte-identical before/after evaluation at09:21 UTC September2. Local combined selector/recovery tests also pass31/31; this is separate from the unchanged failing runtime-history acceptance gate.

The [recovered review proposal](history-recovery-proposal-20260902.json) is reproducible by the fixed offline fixture replay. It retains the missing staging epoch and source digests; both items still have unknown canonical family mappings, incomplete history and no authorized remaining budget. Proposal is for review only, not a migration manifest.

This does not repair the installed controller or satisfy its strict 14-case runtime acceptance gate. Its output is not a complete migration seed: unobserved epochs and canonical family assignments remain unresolved. It does not prove process-restart durability, atomic reservations, effect deduplication, replay recovery, useful tools or owner outcomes. Those belong to the next integrated candidate and existing typed production transaction. No completed item is reopened and no blocked family budget is changed.

Current production checkpoint remains healthy (Support03:07/Engineering03:12, Benchmark30/30 critical0). The current manifest, isolation-dependent hold, desired-state pins and single native Supervisor scheduler are preserved. No new canary or model turn is requested.

Evaluation attempt history: run33613460730 passed Linux unit tests and exact evidence replay, then failed the original whole-tree `git diff` check because existing repository CRLF blobs differ from Git's normalized checkout/index expectations. Windows was cancelled by matrix fail-fast, so no Windows pass was claimed. The corrected check records every tracked file's actual checkout bytes before evaluation and compares every tracked path/hash afterward, without filtering files or ignoring whitespace. It rejects deletion or byte changes and avoids dumping unrelated file contents. Matrix fail-fast is disabled so each platform returns its own result. No candidate acceptance test or production file is changed by this harness correction.
