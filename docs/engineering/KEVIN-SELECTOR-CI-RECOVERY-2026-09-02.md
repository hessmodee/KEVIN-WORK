# Selector CI regression recovery — 2026-09-02

Consumer: next governed controller qualification. Scope: one CI/evaluation repair; no production crossing.
Runtime checkpoint: c1db5883788cdede2975c8c891e4df605c5f9414 at00:08 MDT. Code commit: dc368d0ab86fe5dae0af960cd0a0d3f2cf7a949c.
CI: https://github.com/hessmodee/KEVIN-WORK/actions/runs/33597815086 — SUCCESS.

## Demonstrated failure and correction

Old selector CI required eligible_count>=1 against the mutable owner inventory, so correct exclusion of four COMPLETE and three BLOCKED items caused failure. This was a test-harness defect, not permission to reopen owner work.

The replacement retains unchanged production selector source and original semantic failure-family selftest, adds13 isolated tests, and compares current inventory against an independent admission oracle at one shared current timestamp. Fixed fixtures cover eligible work (must select), empty and closed/blocked inventory (must idle), completed high-value work vs ready alternative, scoped WIP, family renaming/prose changes, GREEN/owner/duplicate/dependency/cooldown/budget/consumer gates, read-only diagnosis, deterministic priority/ties, malformed registry and input immutability. Meta-negative checks reject both fabricated idle and fabricated eligible results.

Fixtures are synthetic TEST INPUTS ONLY. They are never inserted into inbox, dispatched to Kevin, or counted as owner outcomes/trajectory trials. No acceptance rule, authority, production code, queue, manifest, retry budget, scheduler or trust anchor was changed. Workflow remains contents:read with5-minute timeout. The change can be reverted independently of runtime files.

Local Python compilation, original selector selftest and all13 tests passed; the same steps passed GitHub CI at the exact code commit above. The current-inventory oracle found zero eligible items, consistent with the authoritative inventory. Other legacy Supervisor CI failures are not repaired by this scoped change.

## Fresh operational evidence

- Support00:07:34 and independent Engineering00:08:10 both show scheduled Maintenance Intake ok/0 errors. Latest receipt at00:04:19 is ALREADY_APPLIED_PROVEN for the same main-canary-reaffirm-16k-20260902-2300 manifest. Scheduled recovery is now observed; this run did not dispatch it.
- Benchmark PASS30/30 critical0 at00:07:01; independent UI heartbeat1s. Main exact-response canary remains the previously proven23:02 receipt; no repeat was sent.
- Autonomy00:03 reports HEALTHY/drift_count0. Repository desired pins still differ from observed Supervisor/Maintenance/Benchmark identities; local desired-state/source/authorization provenance remains unverified. Do not call the identity mismatch fixed or silently bless current hashes.
- Supervisorv1.8.8 remains installed at F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138 and reports legitimate IDLE_NO_ELIGIBLE_DEMAND at00:04. No new owner outcome or actual tool-use proof.
- The cross-fingerprint runtime history defect documented in KEVIN-CONTINUITY-REVIEW-2026-09-02-0510.md remains unresolved. These selector tests do NOT test/fix the PowerShell runtime's history replacement; do not conflate the layers.
- Foreground-recorded chat and trajectory COMPLETE closures remain closed, with their referenced proof files still absent from the reviewed tree. No fake owner messages or repeated synthetic production trials.

## Continuation boundary

CI/evaluation slot is complete. Next controller work needs a candidate that preserves all historical item/family evidence epochs and fails closed on missing/corrupt state, with negative tests for prose edits, A->B->A, alternation, restart, crash charging and complete-item replay. Production still requires exact qualified current/after sources, typed authorization, bounded operation, rollback, independent semantic postconditions and fresh Benchmark. Actual useful tool execution and durable owner outcomes remain separate requirements.

All transfer levels unchanged, including work-selection T2. No runtime repair claim, no T4/T5 promotion and no retired Bess responsibility.
