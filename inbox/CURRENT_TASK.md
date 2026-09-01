# Current task — Native autonomy continuation + T3 proof

Updated: 2026-09-01 08:18 MDT

## Objective

Restore continuous, useful, demand-driven Kevin autonomy after retiring the legacy demandless Forge loop. Kevin must wake, refresh evidence, select an eligible UNSATISFIED GREEN objective, execute through proven typed paths, verify semantic outcomes, record them, learn reusable corrections, and continue without Bess supplying the immediate task identity.

## Proven production state

- Supervisor v1.7.1 is installed at SHA256 `47A0A1D0E3F744E972E2F2239F100CA2B009ABD3928D0281E4587A364B7C27AC`.
- Forge v4 is installed at SHA256 `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A`.
- Maintenance v1.3.19 is installed/proven at SHA256 `7422A70B75FC8BCA069CA00DBDD1967318159F87B3E84C202A8932474611BB21`.
- Fresh Benchmark remains PASS 30/30, critical=0 after the coordinated Supervisor + Benchmark-anchor repair.
- No Forge evaluation has been produced after iteration 391 at 2026-09-01 07:06 MDT.
- Supervisor v1.7+ intentionally retires legacy mission/Forge admission. The replacement governed wake/admission path is the active gap.

## Active production crossing

Maintenance v1.3.20 is CI-PROVEN at SHA256 `737F40049FEA0C16EB8DC17FAA8DBCEE0DE2E7E1CCF7D5DCD353F63EF23DE1AD` and is being installed through `replace_pinned_component`.

v1.3.20 adds one fixed typed operation: `ensure_autonomy_continuation_automation`.

Its production contract is intentionally narrow:
- fixed OpenClaw automation name: `Kevin Autonomy Continuation v1`;
- fixed 5-minute cadence;
- fixed `main` session;
- fixed `systemEvent` payload, not a shell/command payload;
- fixed immediate wake after creation/readback;
- no caller-supplied command, path, prompt, recipient, script, authority, or executable body;
- duplicate detection and exact readback validation;
- fresh Benchmark after the change.

Do not start another production crossing until this one is terminal and fresh Support/Benchmark evidence is clean.

## Continuation behavior

On each governed continuation wake Kevin must:
1. refresh trusted evidence and current WIP;
2. reject already-satisfied/stale/duplicate outcomes before scoring work;
3. respect GREEN authority, WIP, dependencies, cooldowns, failure-family budgets and owner checkpoints;
4. use deterministic work selection rather than Forge rotation or task-name invention;
5. choose the highest eligible objective without a caller supplying its task id;
6. execute only through an existing proven typed action path;
7. verify semantic postconditions, not file presence, process exit, heartbeat, candidate count or PASS text alone;
8. record outcome, evidence, proof level, failure family and intervention count;
9. immediately consider another independent eligible GREEN objective when capacity exists;
10. if nothing useful is eligible, record the exact blocker and remain quiet rather than manufacture work.

## T2 -> T3 acceptance

Do not award T3 merely for installing the continuation Automation or waking the model.

Work selection moves to T3 only when Kevin independently:
- notices the production crossing is stable/idle;
- selects an eligible UNSATISFIED GREEN objective without Bess injecting its identity;
- executes it through a valid typed/proven path;
- verifies its semantic acceptance criteria;
- records the outcome;
- then continues or selects the next eligible work.

The stale `write-proof` event remains explicitly invalid evidence because its acceptance outcome already existed.

## Current useful backlog

The deterministic registry currently contains real ready work, including owner communications and staging trajectory reliability. Their presence does not grant T3 and Bess must not choose one for the continuation proof. Kevin's governed selector owns that choice after production WIP clears.

## Architecture target

`Standing Orders -> native Automation wake -> deterministic eligibility/WIP/failure-family policy -> durable Task Flow -> Qwen reasoning when judgment is needed -> typed GREEN primitive/composite -> semantic verifier -> trajectory/outcome evidence -> governed Skill Workshop proposal -> next eligible work`

Heartbeat watches. Automations wake. Task Flow remembers. Deterministic code decides eligibility. Qwen reasons. Typed tools act. Semantic evaluators decide success. Skill Workshop learns procedures. HQ tells the truth.

## Boundaries

No arbitrary shell/remote code, permission expansion, secret leakage, purchases/money movement/live trades, unauthorized external sends, trust-anchor weakening, safety/audit weakening or novel YELLOW/RED auto-promotion. Natural-language intent is never executable shell. Require bounded retries, idempotency, evidence and rollback.
