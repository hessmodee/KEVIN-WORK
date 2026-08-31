# Bess -> Kevin Autonomy Transfer Doctrine v1

Owner directive: 2026-08-31

## North-star objective

The engineering goal is to make Kevin progressively less dependent on Bess/ChatGPT for routine operation, engineering, diagnosis, repair, proof, communication, planning, and useful work.

**Bess is training Kevin to replace Bess operationally.**

Success means that responsibilities which currently require Bess are deliberately transferred to Kevin as Kevin proves that he can perform them safely, correctly, repeatedly, observably, and within owner-authorized boundaries.

The target is not merely "Kevin can execute a command." The target is a self-reliant lifecycle:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> CONTINUE`

Kevin should eventually require Bess only for genuinely new capability research, owner-reserved decisions, new authority boundaries, unavoidable private/local enrollment, or exceptional failures beyond his proven repair envelope. Even those categories should shrink as new typed capabilities are deliberately designed and proven.

This doctrine does **not** authorize Kevin to grant himself authority. Greater autonomy must come from better proven capability inside existing owner-approved boundaries, not from removing governance.

## Responsibility-transfer maturity ladder

Every important Kevin capability/responsibility should be tracked against this ladder independently from the ordinary technical proof ladder.

### T0 — BESS-DEPENDENT
Bess performs or manually coordinates the work. Kevin may have little or no usable capability.

### T1 — BESS-BUILT / KEVIN-TESTED
Bess designs or prepares the capability; Kevin can exercise an isolated candidate or deterministic test, but cannot reliably own the real workflow.

### T2 — BESS-DISPATCHED / KEVIN-EXECUTED
Kevin can perform the real bounded operation through a typed/proven mechanism after Bess explicitly creates the request, stages the package, or selects the work.

### T3 — KEVIN-RUN / BESS-VERIFIED
Kevin can initiate or schedule the routine workflow and produce evidence, but Bess still routinely checks correctness, diagnoses common failures, or selects recovery.

### T4 — KEVIN-OWNED / EXCEPTION-ESCALATED
Kevin independently initiates appropriate work, executes it, verifies semantic success, detects common failures/staleness/duplicates, performs bounded proven recovery, maintains evidence/handoff state, and continues useful work. Bess is normally unnecessary and is invoked only for exceptional cases or new capability boundaries.

### T5 — SELF-RELIANT / BESS-NOT-REQUIRED
The responsibility no longer operationally depends on Bess. Kevin owns the normal lifecycle end-to-end, including work conservation, monitoring, maintenance, replay/idempotency, rollback/recovery, proof freshness, and durable lessons. Owner interaction occurs only where the owner is intentionally part of the product or authority model.

T5 does not mean unrestricted authority. A capability can be fully self-reliant inside a narrow GREEN envelope while correctly stopping at owner confirmation for consequential actions.

## Technical proof and transfer maturity are separate

Use both axes.

Technical proof ladder:

`DESIGNED -> CI-PROVEN -> INSTALLABLE -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

Responsibility transfer ladder:

`T0 -> T1 -> T2 -> T3 -> T4 -> T5`

Examples:
- A component can be OMEN-PROVEN but still T2 if Bess must manually dispatch every use.
- A scheduled health check can be T4 even if it has no external round-trip concept.
- A communication channel is not T4 merely because Kevin can send one message; Kevin must also notice messages, correlate threads, handle duplicates/restarts, verify delivery/reply state, and recover common failures.

## Transfer test

Before promoting a responsibility, answer these questions with evidence:

1. **Notice:** Can Kevin detect when this work should happen without Bess noticing first?
2. **Understand:** Can Kevin classify the state/request correctly from trusted inputs?
3. **Plan:** Can Kevin select a safe next action from a bounded typed catalog without Bess choosing it each time?
4. **Execute:** Can Kevin perform the operation through proven mechanisms?
5. **Verify:** Can Kevin independently verify semantic success rather than trusting exit code/activity?
6. **Recover:** Can Kevin detect and repair/retry the common bounded failure families without Bess?
7. **Conserve work:** If blocked, can Kevin move to another useful authorized objective rather than idle/spin?
8. **Remember:** Can Kevin record durable state, evidence, lessons, checkpoints, and handoff information?
9. **Avoid regressions:** Are replay, idempotency, rollback, privacy, resource, and Benchmark invariants preserved?
10. **Escalate correctly:** Does Kevin ask Bess/owner only for a genuinely new boundary or exhausted exception, with exact evidence and next checkpoint?

If any routine answer is "Bess does that," the transfer is incomplete.

## Bess behavior rule

Bess must actively try to eliminate recurring Bess work.

Whenever Bess performs a repeated useful action for Kevin, Bess should ask:

> Can this exact recurring responsibility be encoded as an observable, typed, testable, reversible Kevin capability or composite skill?

Preferred sequence:

`Bess performs once -> instrument -> specify -> candidate -> adversarial tests -> typed boundary -> Omen proof -> repeated proof -> hand responsibility to Kevin -> Bess stops doing routine version`

Do not preserve a manual Bess workflow merely because it works. Repeated manual intervention is technical debt and a transfer candidate.

## Kevin behavior rule

Kevin should preferentially learn responsibilities that reduce future dependence on Bess, including:

- self-status and stale-evidence detection;
- work selection/work conservation;
- scheduler/task health;
- Benchmark/regression verification;
- bounded self-maintenance and rollback;
- common failure classification and repair;
- Reader/research/info acquisition;
- durable handoff/checkpoint/resume;
- Skill Lab generation/evaluation/promotion of existing GREEN primitives;
- owner communication through proven private channels;
- computer/app/file/browser/Office workflows;
- performance measurement and bottleneck diagnosis;
- capability inventory and proof freshness;
- secure credential/checkpoint awareness without exposing secrets;
- postmortems and reusable lessons.

## Promotion rule

A responsibility may move upward only on evidence. Required evidence should include, as applicable:

- exact installed identity/hash;
- fresh successful run receipt;
- semantic postcondition;
- replay/idempotency test;
- intentional failure / negative fixture;
- recovery or rollback evidence;
- repeated success over time;
- owner-intervention count;
- Bess-intervention count;
- stale/duplicate/error detection;
- resource/regression result;
- proof freshness timestamp.

Never promote based on aspiration, file presence, scheduled-task existence, CI alone, or dashboard "healthy" labels.

## Demotion rule

Transfer maturity must be demoted when evidence shows Kevin again depends on Bess for routine operation, verification, or recovery. A stale heartbeat, silent failure, repeated duplicate loop, false success, or manual recurring repair is evidence that a claimed transfer is incomplete.

## Responsibility Transfer Ledger

Maintain `docs/engineering/RESPONSIBILITY-TRANSFER-LEDGER-v1.md` as the human-readable ledger and `reports/responsibility-transfer-latest.json` as the compact public-safe machine-readable checkpoint.

For each domain track:

- current transfer level T0-T5;
- technical proof level;
- what Bess still does;
- what Kevin already owns;
- exact evidence;
- next transfer step;
- owner/local checkpoint if any;
- date of last evidence review.

The most important progress metric is not commit count. It is **responsibilities retired from Bess and transferred to Kevin.**

## Scoreboard metrics

Track over time:

- number of T4/T5 responsibilities;
- number of T0/T1 responsibilities;
- Bess interventions per day/week;
- owner interventions per workflow;
- percentage of routine failures recovered by Kevin without Bess;
- percentage of useful work self-initiated by Kevin;
- useful work completed while another lane is blocked;
- repeated-proven GREEN skills/composites;
- time from detected failure to verified recovery;
- time from owner request to verified completion;
- false-success / stale-evidence incidents;
- manual Bess actions converted into typed Kevin mechanisms.

The desired trend is clear:

**Kevin capability, ownership, and self-reliance go up. Bess intervention goes down.**

## Priority transfer targets

Current high-value transfer targets include:

1. Owner communications: HQ direct chat -> Gmail -> Telegram.
2. Work selection: Tick/autonomy identifies useful backlog and dispatches safely without Bess babysitting stale orders.
3. Maintenance: common scheduler/task/component failures are detected, diagnosed, repaired, benchmarked, rolled back when needed, and recorded by Kevin.
4. Reader/research: Kevin independently acquires approved evidence and answers owner/work questions with provenance.
5. Skill growth: Kevin identifies repeated GREEN sequences, creates candidates, validates them in Staging/Skill Lab, and promotes only proven composites without Bess hand-building each manifest.
6. Handoff/continuity: Kevin keeps `AI-HANDOVER.md`, compact checkpoints, lessons, and current task truth fresh enough that replacement ChatGPT assistance is optional rather than essential.
7. Computer fluency: Kevin owns routine file, browser, Office, spreadsheet, document, image/attachment, app-awareness, development, and business-support workflows.
8. Performance: Kevin measures his own bottlenecks and safely optimizes successful work.

## End state

The end-state architecture is not "Bess operating Kevin remotely." It is:

**Matt gives Kevin goals and communicates naturally. Kevin plans and completes authorized work, learns from outcomes, maintains himself, proves his results, recovers common failures, and asks for help only when a genuinely new boundary is reached.**

At that point Bess is not part of Kevin's normal operating loop.
