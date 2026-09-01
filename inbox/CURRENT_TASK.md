# Current task — Autonomy continuation proof

Updated: 2026-09-01 07:26 MDT

## Objective

Prove Kevin can safely continue useful GREEN work without Bess choosing the immediate task.

The previous `write-proof` task was stale: `reports/tool-write-test.txt` already contained `OK-WRITE` from 2026-08-25. Do not count re-selecting or re-writing an already-satisfied outcome as progress.

## Active production incident

Supervisor v1.7 + Forge v4 are installed and Benchmark remains 30/30, but scheduled Supervisor invocations are currently failing because the migrated Supervisor retained the old Forge v3.7 startup hash pin. A typed v1.3.18 Maintenance repair is being crossed. Until fresh Support proves Supervisor healthy, treat the production WIP slot as occupied and do not start another production crossing.

Required closeout before this incident is resolved:
1. exact Maintenance v1.3.18 identity is OMEN-PROVEN;
2. typed `repair_supervisor_v171_forge_pin` applies Supervisor v1.7.1 while Forge remains v4;
3. fresh Benchmark remains PASS 30/30 critical=0;
4. at least two natural scheduled Supervisor opportunities finish successfully with zero new Forge evaluations after iteration 391;
5. no recovery path manufactures Forge demand.

## Kevin continuation rule

Once the production incident is stable, Kevin—not Bess—must choose the next eligible objective.

Before selecting any work item:
1. refresh trusted evidence;
2. reject any item whose acceptance outcome is already satisfied (`ALREADY_SATISFIED` / stale work);
3. respect GREEN authority, WIP, dependencies, cooldown, semantic failure-family budget, duplicate suppression and owner checkpoints;
4. run the deterministic work selector against current standing programs, work items, WIP state and failure-family state;
5. choose the highest eligible item without a caller supplying the task id;
6. execute only through its existing typed/proven action path;
7. verify semantic postconditions rather than file/task presence;
8. record outcome, evidence, failure family and proof level;
9. immediately consider the next eligible work instead of idling or manufacturing Forge work.

A completed task must never be selected merely because its instruction still exists somewhere. Task identity, acceptance state and evidence freshness must agree.

## T2 -> T3 acceptance

Work selection may move to T3 only when Kevin independently notices that the current incident is stable/idle, selects another eligible GREEN owner objective, executes it, verifies it, records it, and continues without Bess injecting that immediate task identity.

Do not award T3 for the stale `write-proof` action.

## Architecture target

Standing Orders hold durable owner intent. Deterministic policy decides eligibility. Native Task Flow should become the durable multi-step work ledger. Qwen reasons only where judgment is useful. Typed GREEN primitives act. Semantic verifiers decide success. Skill Workshop captures reusable procedures proposal-first. HQ reports current truth. Kevin continues until useful authorized work is exhausted or a true exception requires Matt.

## Boundaries

No arbitrary shell/remote code, permission expansion, secret leakage, purchases/money movement/live trades, unauthorized external sends, trust-anchor weakening, safety/audit weakening or novel YELLOW/RED auto-promotion. Natural-language owner intent is not executable shell. Require bounded retries, idempotency, evidence and rollback.
