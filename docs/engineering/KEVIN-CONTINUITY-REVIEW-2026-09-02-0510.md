# Kevin continuity and retry-history review

Evidence checkpoint: 2026-09-02T05:10:31Z (2026-09-01 23:10 MDT).
Consumer: foreground engineer and next canonical Chief Engineer pass.
Scope: read-only source/receipt review and continuity reconciliation; no runtime mutation, request, budget reset, trust-anchor promotion, or T-level promotion.

## Correlated current truth

- [Support](https://github.com/hessmodee/KEVIN-WORK/blob/b764d65bacd19f2b740b9f6421a7a7f8284a30f1/reports/support-latest.json) at 23:10:29 MDT observes Supervisor v1.8.8 hash F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138 and its one existing five-minute scheduler healthy. The legacy Support.supervisor cycle449 timestamp is 21:32 and is not the current controller result.
- [Continuation](https://github.com/hessmodee/KEVIN-WORK/blob/b764d65bacd19f2b740b9f6421a7a7f8284a30f1/reports/autonomy-continuation-latest.json) at 23:09:17 MDT reports IDLE_NO_ELIGIBLE_DEMAND, eligible_count=0, outcome_proven=false, tool_calls=null. Current seven-item inventory contains four COMPLETE and three BLOCKED items. This idle decision is consistent with that inventory; it is not evidence that the master-plan backlog is finished.
- [Main canary](https://github.com/hessmodee/KEVIN-WORK/blob/b764d65bacd19f2b740b9f6421a7a7f8284a30f1/reports/main-agent-canary-omen.json) at 23:02:44 MDT is OMEN_PROVEN: fixed:main, Gateway probe true, exact case-sensitive final reply true, complete correlated transcript, zero tool calls, resolved ollama-chat-16k/qwen2.5:14b. Prompt-reported visible tool count is zero; useful typed action execution is not proved by this no-tool test.
- The earlier /no_think failure resolved llama3.1:8b according to the foreground model-identity note; do not repeat the stale claim that it disproved Qwen. Foreground notes also document an 8K overflow hypothesis. The passing 16K receipt is observation, not an authorization/source-provenance record.
- Current Maintenance manifest main-canary-reaffirm-16k-20260902-2300 has a matching ALREADY_APPLIED_PROVEN receipt at 23:09:10 MDT and expires 2026-09-02T11:01:17.9839979Z. Do not replace or rerun it merely to create activity.
- Maintenance scheduler summary still reports five errors, last scheduled run 22:44:24 MDT, next scheduled opportunity about 23:44 MDT. The newer successful receipt does not prove scheduled intake has recovered; the lagging scheduler summary does not prove the newer canary failed.
- Independent Engineering at 23:10:05 MDT reports UI heartbeat age3.9s and Benchmark PASS30/30 critical0 at23:07:03. Its old expired snapshot request is terminal, not a new UI outage.
- Forge latest evaluation remains iteration391 at07:06:41. No new Forge churn is observed.

## Confirmed retry-history preservation defect; NOT REPAIRED

Source: [qualified v1.8.8](https://github.com/hessmodee/KEVIN-WORK/blob/b764d65bacd19f2b740b9f6421a7a7f8284a30f1/control-plane/autonomy/kevin-supervisor-v1.8.8.ps1).
The installed Supervisor hash matches this qualified version; review is source inspection plus correlated receipts, not a newly executed Windows regression test.

1. Get-ItemFingerprint includes next_action and completion_evidence prose as well as operational fields.
2. Get-ItemBudget returns turns=0 immediately when the item fingerprint differs. It does not validate a materially changed evidence epoch or preserve the old epoch's exhausted budget.
3. Record-ItemAttempt removes the prior row with the same item ID and replaces it. History is one row per ID, not an append-only per-item/per-family attempt ledger.
4. At [22:14 MDT](https://github.com/hessmodee/KEVIN-WORK/blob/85e1593c7a098a0c07d61b4c825b92d19603968c/reports/autonomy-continuation-latest.json), staging fingerprint 2BFEF3F4341FA85EE7415CB8097334615FB80A1EC5E51E35D2522141FDBD25F6 had three non-outcome turns. Current receipt instead contains C61984ED7DEF5FD8CB6BED423A2F9CCEF43C0B1039B394B1BF927541A0D2AAF8 with one turn at22:24:16 and omits the prior epoch.
5. This proves history replacement and a new fingerprint budget, not that an unsafe action happened. The additional turn has no proven outcome and UNKNOWN tool telemetry. Do not infer zero tool use or assert exactly which cached queue revision was consumed.

Before any controller promotion, retain all historical epochs and failure-family budgets; require an explicit validated material-evidence transition to reopen a budget. Prose edits, timestamp/request-ID changes, A->B->A fingerprints, alternating items, restarts, missing/corrupt state, and completed-item replay must not erase prior attempts. Charge attempts before effects; preserve WIP and fail-closed behavior. Add executable negative regressions and exact-source CI before a typed, reversible production crossing. Do not manually reset current history or reopen completed items.

## Completion claims and provenance limits

Foreground marked HQ chat and trajectory reliability COMPLETE. Preserve those closures and do not fabricate another owner conversation or synthetic trial. The current repository tree does not contain the referenced:
- reports/engineering/PROOF-matt-kevin-control-ui-roundtrip-2026-09-01.md
- reports/trajectory/gate-result-control-ui-owner-roundtrip-v1.json
- reports/trajectory/gate-result-false-done-fixture-v1.json

These are foreground-recorded completion claims pending independently retrievable sanitized evidence. A local owner roundtrip may be genuine without proving restart/replay/deduplication or two independent trials. No T promotion is granted.

Support observes Maintenance FF9C5FDF217B0ED5F38A8566BD54D8A654CB8DFEF0093654DDBC23DC9A1BF956 and Benchmark 4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964; desired pins remain different. Canary runner identifies 1.3.43+modelid. Publish exact sanitized source/qualification/authorization/transaction provenance before promoting trust anchors. Do not blindly restore the old pins or bless the observed ones. Autonomy's drift_count4 remains unresolved.

## CI classification

[Selector run33590422621](https://github.com/hessmodee/KEVIN-WORK/actions/runs/33590422621) compiled and passed semantic failure-family selftests, then correctly excluded all completed/blocked work. Its final test hardcodes eligible_count>=1 against mutable live inventory and failed after the two foreground closures. Repair with immutable positive/negative fixtures plus truthful current-inventory validation; never reopen completed work or weaken admission to satisfy the assertion.
Other old-controller workflow failures are not by themselves a v1.8.8 runtime failure. The qualified v1.8.8 CI run33577588115 passed its existing coverage, but that does not disprove the newly identified cross-fingerprint history gap.

## Next boundary and ownership

Foreground/local engineering retains priority over production/proof work; check a fresh manifest/receipt and any hold before acting. This reconciliation does not reserve a second crossing or enqueue work. Main exact-response retries and controller reinstall are not the next task. First preserve/recover durable attempt provenance and publish the missing bounded tool/outcome/source receipts. Then qualify any matching fix; require actual useful typed execution, independent verification, durable result/lesson, restart/replay and another correct scheduled selection for T2->T3. Do not count check-only or successful model turns as that proof.

Work selection remains T2; all other transfer levels unchanged. No routine Bess responsibility is retired by this review.
