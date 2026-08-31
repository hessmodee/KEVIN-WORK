# Kevin Real-World Owner Outcome Protocol v1

Date: 2026-08-31
Status: OWNER-DIRECTED MEASUREMENT CONTRACT

## Purpose

Kevin Build must optimize real owner outcomes, not commits, cycles, candidates, synthetic skill count, or green dashboards.

A **real-world owner outcome** is a useful owner-requested or standing-goal result completed through Kevin's actual operating path and evaluated against explicit acceptance criteria.

This protocol complements, but does not replace, the technical proof ladder and T0-T5 responsibility-transfer ladder.

## What counts as an owner outcome

An outcome may be counted only when all applicable conditions are true:

1. It maps to a real owner goal, request, standing program, maintenance need, or useful business/computer workflow.
2. Acceptance criteria were stated before completion or can be objectively reconstructed from the owner's request.
3. Kevin executed the real workflow, not merely a unit test or candidate simulation.
4. The semantic result was verified independently enough for the task's consequence level.
5. The result did not rely on fabricated/stale evidence.
6. Consequential steps stayed inside existing authority and approval boundaries.
7. The trace records Bess and owner interventions honestly.
8. A generated artifact is not counted until the artifact itself is validated; owner acceptance is recorded separately.

Examples: a correct owner budget workbook generated and accepted; a real Reader research answer with provenance; a private Matt->Kevin->Matt communication round trip; a known failure Kevin notices and repairs itself; a useful application feature that actually runs and passes its E2E test.

## What does NOT count

- raw Supervisor/Forge/Heartbeat cycle counts;
- dashboard/pulse commits;
- PONG/model sanity checks;
- CI-only candidates;
- an installed component without a semantic postcondition;
- Skill Lab promotion without subsequent useful execution;
- duplicate/expired request handling;
- task/hash presence without runtime proof;
- a benchmark pass that is unrelated to the claimed capability;
- generated files that were never opened/validated or whose contents fail the owner task;
- activity invented to keep Kevin busy.

## Required outcome record

Each completed attempt should capture, when applicable:

- `outcome_id`
- `owner_goal_id` or standing program
- short task/result description
- `started_at`, `completed_at`, elapsed seconds
- acceptance criteria
- result: PASS / PARTIAL / FAIL / BLOCKED
- useful deliverable or semantic postcondition
- exact proof/evidence references
- technical proof level
- responsibility-transfer level
- first-pass success yes/no
- retry count and failure families
- Bess interventions
- owner interventions excluding intentional approvals
- owner checkpoint/approval if any
- owner acceptance: accepted / rejected / not-yet-reviewed / not-applicable
- resource pressure when meaningful
- incident-derived eval or lesson when a repeatable failure occurred
- reusable skill/procedure candidate only when the real trajectory clears the reuse bar

## Daily decision metrics

Kevin and Chief Engineer should track:

1. verified owner outcomes completed today;
2. owner-accepted outcomes completed today;
3. median/p90 request-to-verified-completion time when sample size permits;
4. first-pass success rate;
5. Bess interventions per verified outcome;
6. owner interventions per outcome excluding intentional approvals;
7. known-failure self-recovery rate;
8. useful work selected while another lane was blocked;
9. repeatedly used proven skills, not merely total skill count;
10. false-success/stale-evidence incidents;
11. failures converted into targeted regression/eval fixtures;
12. T-level promotions that retire a recurring Bess action.

## Skill usefulness gate

A new Skill Lab composite or Skill Workshop proposal is valuable only when it is linked to a real repeated workflow or recovery pattern and is likely to remove future model/tool steps, improve accuracy, reduce latency, or reduce Bess intervention.

A synthetic promotion may prove the Skill Lab runtime, but it does not prove business or owner value.

After promotion, measure reuse. A skill with no real use is inventory, not impact.

## Production-improvement loop

Use this loop for repeatable failures/corrections:

`real owner task -> full trace/evidence -> correction/failure classification -> recurring actionable pattern -> targeted eval -> scoped candidate change -> deterministic/adversarial + regression eval -> typed production crossing -> repeated real task -> measured improvement`

Do not create an engineering task from every one-off failure. Group repeated or high-consequence patterns first.

## Long-running autonomy test

Kevin is progressing toward real autonomy only if, over time, it can:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> CONTINUE`

on real owner work while Bess interventions decline.

At least one regular evaluation window should measure trajectories across multiple tasks/blocks rather than evaluating only final outputs. Watch for semantic loops: the same plan can become invalid even when individual tool calls remain syntactically correct.

## Current 2026-08-31 truth boundary

Kevin has genuine platform/component proofs and three production-proven Skill Lab composites, including `business-budget-starter-pack@1`. That demonstrates executable capability and Skill Lab health.

It does **not** by itself establish a new owner-accepted real-world outcome for today. The next level of proof is to execute useful owner tasks through those capabilities, validate the resulting deliverables, record interventions/timing, and measure reuse.

## Research alignment

This protocol intentionally follows convergent production patterns:

- OpenAI: production traces and practitioner corrections become reviewed findings, targeted evals and scoped engineering changes.
- Anthropic: long-running harnesses use explicit requirements/progress artifacts and self-verification before completion.
- OpenClaw: Standing Orders define persistent programs; Tasks provide an activity ledger; Task Flow provides durable multi-step state; Skill Workshop learns only sufficiently reusable procedures through a governed lifecycle.
- Durable workflow systems: execution state and retries are persisted rather than inferred from conversational memory.
- Agent observability systems: quality, latency, failures and traces are measured by workflow/use case, not only by model call.

## Authority

Measurement never widens authority. Owner outcomes must remain inside `control-plane/OWNER-AUTHORIZATION-v1.md` and any narrower applicable authorization.
