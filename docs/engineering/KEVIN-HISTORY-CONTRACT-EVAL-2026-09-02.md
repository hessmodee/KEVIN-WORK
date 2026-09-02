# Supervisor retry-history contract evaluation

Consumer: next governed controller qualification. Lane: isolated STAGING/EVAL, not a production crossing. Fixtures are synthetic test inputs only and are never dispatched to Kevin or counted as owner outcomes.

## Current evidence and scope

Repository checkpoint: `9e5e1a0a16fb9fb4a5358fc112969811c10acbf1`. Support at September 2 02:07 MDT and Engineering at 02:12 show Benchmark 30/30, critical=0, healthy schedulers, and a fresh UI heartbeat. Continuation at 02:09 remains `IDLE_NO_ELIGIBLE_DEMAND`, outcome_proven=false and tool telemetry UNKNOWN. Current inventory has no eligible work; completed items and blocked families stay unchanged.

The isolation-dependent hold remains in force. The passing exact-response canary is not rerun. This evaluation does not change runtime source, the current manifest, work items, retry budgets, desired-state pins, schedules or authority.

## Demonstrated acceptance blind spot

The existing `tools/test-supervisor-durable-budgets.ps1` explicitly expects changing a fingerprint to return zero turns (`changed item cannot reopen`). That proves an old behavior, not the owner's stricter requirement that materially unchanged evidence cannot reopen exhausted work. Merely passing that older test does not establish preserved history across evidence epochs.

The new test extracts only eight named functions from the actual v1.8.8 PowerShell AST. It does not dot-source the full controller, call OpenClaw, create an agent turn or contact the Omen. All state writes are under a unique temporary fixture directory. Baseline characterization is restricted to exact SHA-256 `F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138`.

Fourteen independent cases cover same-fingerprint exhaustion, bare fingerprint change, prose-only change, A->B->A replay, alternating items, reload after reservation before any effect, unrelated edits, corrupt JSON, missing established state, absent bootstrap authorization, empty established history, malformed history time, duplicate IDs and negative counts.

Default mode is `RequireConformance`: any contract violation fails. `CharacterizeBaseline` is a separate, hash-locked negative-control mode: it succeeds only if the exact expected known-bad behavior is reproduced and the unaffected cases still pass. The workflow also requires strict mode to reject the baseline. A green characterization workflow therefore means **the defect was reproduced**, never that the runtime was repaired or qualified. Unexpected exceptions, missing functions, parse errors, source changes and unexpected case outcomes fail the workflow.

## Deliberately not claimed

This is not a controller implementation or production acceptance suite. It does not yet prove family alias aggregation, validated evidence reopening, legacy-history recovery, a durable first-install marker, atomic crash recovery, actual process termination at every write boundary, effect deduplication, independent semantic outcomes, completed-item admission or actual tool execution. Those remain required before promotion. Reloading fixture state is not a real machine restart test.

Missing state is not authority to create a new budget. A future first-install/migration design needs an explicit validated bootstrap/lineage receipt and recovery of historical attempts. The baseline's one-row-per-item file cannot reconstruct already overwritten epochs on its own. Source/receipt history must be recovered conservatively; absence or ambiguity must block affected families instead of fabricating zero history.

## Next implementation boundary

Preserve append-only attempts/evidence epochs tied to stable item and canonical failure-family identities. Prose, timestamps, renamed requests and alternating IDs cannot reset exhaustion. Charge before effects; retain unresolved in-progress reservations; replay must not repeat effects. Reopening requires validated materially new evidence tied to exact implementation/input identities, never a caller-supplied boolean or new hash alone. Do not trim history to make validation pass. Keep a bounded materialized index without deleting audit history.

Any candidate must pass strict regression contracts and the additional missing cases, then cross only an existing typed authorized transaction with exact before/after hashes, rollback, independent postconditions, privacy verification and fresh Benchmark 30/30 critical=0. No T-level change or retired Bess responsibility is implied by this evaluation.

Validation status at preparation: source inspected; no local PowerShell runtime is available. Windows PowerShell 5.1 and PowerShell 7 results must be read from the exact branch CI run before claiming CI characterization proof.
