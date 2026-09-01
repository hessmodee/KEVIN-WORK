# Kevin Attention Lifecycle + Incident Learning v1

Adopted: 2026-08-31

Purpose: prevent historical failures, already-reviewed drift, stale queue slots, and cooled experiments from masquerading as current owner attention. This doctrine also turns real production failures into bounded recovery knowledge instead of retry churn.

## 1. Attention means a current unresolved predicate

An HQ Attention item MUST describe a condition that is true now and still requires action now.

A historical event is evidence, not automatically an active alert.

Every attention rule must define:
- current predicate;
- authoritative/fresh source(s);
- opened condition;
- resolved condition;
- reopen condition;
- severity;
- owner or Kevin action;
- staleness behavior.

If the evidence needed to evaluate the predicate is stale, report **STALE/RECONCILE EVIDENCE** rather than replaying the old incident as though it is current.

## 2. Desired-state drift is recomputed, not inherited

HQ must compare the current desired-state identities against the current observed Support identities.

A cached `drift_count` is corroborating evidence only. If its count disagrees with the current desired/support comparison, HQ reports a telemetry reconciliation defect rather than an owner-review request.

A mismatch that has already been deliberately reviewed and quarantined is **KNOWN DRIFT**. It stays visible in its engineering lane but must not repeatedly ask the owner to review the same decision unless:
- the observed identity changes again;
- the trust decision expires or is revoked;
- new evidence materially changes the risk;
- the mismatch expands to another component.

Known drift must never be silently repinned merely to make a dashboard green.

## 3. Failure-family circuit breaker

The failure budget is semantic, not request-ID based.

After three materially distinct failed hypotheses in one failure family:
- mark the family BLOCKED/COOLED;
- reject new execution for that family at admission time;
- do not reset the budget by renaming a request, iteration, candidate, or mission;
- allow only read-only diagnosis or materially new evidence gathering;
- reopen only when the new evidence changes the hypothesis or dependency state.

A timer firing is never sufficient demand.

## 4. Forge admission contract

Design Forge work is eligible only when ALL are true:
- a current owner objective or downstream consumer exists;
- an explicit missing capability/hypothesis is named;
- acceptance tests are defined before execution;
- WIP capacity exists;
- the failure family is not blocked/cooled;
- a demand record/token is current and exactly-once consumable.

If any condition is false, Forge returns/records `IDLE_NO_ELIGIBLE_DEMAND` and performs no model experiment.

A BLOCKED Forge family producing a new evaluation is a current high-severity orchestration defect.

## 5. Work conservation

When one lane blocks, Kevin must look for another eligible GREEN owner objective rather than spin, idle falsely, or repeatedly revisit the blocked family.

Durable orchestration target:

`Standing Orders / owner events -> deterministic eligibility + WIP + cooldown -> durable Task Flow -> Qwen reasoning when needed -> typed primitive -> semantic verifier -> trajectory/outcome evidence -> learning proposal -> next eligible work`

Heartbeat observes. Automations schedule. Task Flow remembers durable multi-step state. Deterministic code decides admission. Qwen reasons. Typed tools act. Semantic postconditions decide success.

## 6. Incident-to-eval rule

Every meaningful production incident, owner correction, false-success report, stale-alert bug, repeated failure family, privacy boundary failure, or recovery defect must produce a regression fixture/eval when technically practical.

For alert defects, include at least:
- active incident fixture -> alert MUST appear;
- resolved historical incident fixture -> alert MUST disappear;
- blocked/quarantined known-drift fixture -> owner-review alert MUST NOT recur;
- stale evidence fixture -> reconciliation/staleness alert, not false current incident;
- reopened incident fixture -> alert MUST reappear.

A fix is not durable until the regression test targets the exact production component/bytes actually loaded or executed.

## 7. Learning policy

Successful recovery procedures may be proposed to Skill Workshop in proposal-first mode. Proposals remain scanner/policy/approval governed and cannot create new primitive authority.

Kevin Skill Lab remains the path for executable composites made only from already-proven GREEN primitives.

No learned procedure may weaken governance, tests, audit, rollback, privacy, authority boundaries, or failure budgets.

## 8. Publication and single-source rule

A CI test must validate the exact production artifact it claims to repair. Shadow copies, generated candidates, or similarly named legacy files do not prove the live component is fixed.

For HQ Truth, `docs/index.html` is the loading authority. Any Attention gate must assert that the tested file is the file actually referenced there.

Publication should be atomic and path-scoped so unrelated high-frequency telemetry commits cannot create false CI failures or race away a validated repair.

## 9. What counts as progress

Counts:
- proof-level transition;
- transfer-level promotion that retires a routine Bess action;
- accepted useful owner outcome;
- verified recovery;
- incident-derived eval added;
- measured performance/reliability improvement;
- blocked-family circuit breaker correctly preventing repeated work.

Does not count:
- raw Forge/Supervisor iteration count;
- heartbeat/dashboard churn;
- duplicate or expired request handling;
- PONG/model smoke checks;
- uninstalled candidates;
- CI-only code with no production path;
- historical failure replay presented as current Attention.

## 10. Success criterion

Kevin is improving when the system increasingly does this without Bess:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> CONTINUE`

and when resolved problems stay resolved because their predicates, circuit breakers, regression tests, and learning artifacts prevent the same failure mode from silently returning.
