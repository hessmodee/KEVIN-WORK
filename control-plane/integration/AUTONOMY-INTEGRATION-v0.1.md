# Kevin Autonomy Integration Candidate v0.1

Status: CANDIDATE_ONLY
Authority: GREEN_ONLY_TESTING
Production promotion: OWNER_RESERVED

## Purpose

Prove that Kevin's isolated autonomy controls can operate as one bounded control-plane chain without creating arbitrary shell authority, broadening permissions, silently blessing trust-anchor drift, sending external owner-representing communications, moving money, or promoting novel code to production.

## Required chain

1. Mission admission
2. Work-conserving mission selection
3. Typed work-order validation
4. Preconditions and governance-health gate
5. Tool/resource budget adjudication
6. Typed GREEN actuator decision
7. Independent postcondition verification
8. Evidence-backed maintenance receipt
9. Semantic HandoffEnvelope
10. Durable checkpoint/resume
11. Failure-family accounting and postmortem
12. Knowledge admission with provenance/freshness

## Hard invariants

- One heavy 14B-primary worker at a time unless separately proven safe.
- Unknown authority fields fail closed.
- No arbitrary remote shell/code execution contract.
- No RED authority or permission widening.
- Novel YELLOW code remains candidate-only until owner-approved production promotion.
- Every mutable GREEN test must define precondition, postcondition, evidence, idempotency key, and rollback path before execution.
- Technical success is not semantic success.
- After three materially distinct failures in one family, cool/block that family and continue an independent eligible mission.
- Stale or unsupported evidence cannot satisfy a consequential postcondition.
- Ops Floor/avatar are out of scope except real telemetry defects.

## Integration proof plan

### Phase A: pure deterministic replay
Use synthetic mission/telemetry fixtures to exercise the full chain with no host mutation. Required cases include valid GREEN pass, replay rejection, stale precondition, governance drift, exhausted budget, duplicate/no-progress work, mission-local cooldown rotation, shared-pipeline cooldown, failed postcondition with rollback requirement, semantic handoff failure, checkpoint restart, three-failure cooling, and stale/unverified knowledge rejection.

### Phase B: reversible local GREEN test
Only after Phase A passes, exercise one already-declared reversible local maintenance action using the typed actuator boundary. Capture before-state, independent after-state, receipt evidence, and rollback proof. Failure must restore the before-state or produce an explicit BLOCKED/NEEDS_REVIEW result; it must never widen authority to force success.

### Phase C: restart/resume proof
Interrupt the candidate mission after a verified checkpoint, restart, and prove that already-verified stages are not repeated and budgets/idempotency/failure-family state remain authoritative.

## Promotion gate

This candidate is not production-ready unless all of the following are independently demonstrated:

- deterministic integration matrix passes;
- static authority-boundary scan passes;
- one-heavy-worker invariant passes;
- reversible GREEN host test passes including rollback proof;
- checkpoint/restart proof passes;
- no unresolved trust-anchor drift is auto-approved;
- Benchmark/governance regression remains acceptable on the actual host;
- owner explicitly approves production promotion.

## Component provenance

The integration candidate is intended to consume or adapt the already-isolated control families for Desired State/Self-Heal, scoped cooldown scheduling, typed work-order admission, GREEN receipts/postconditions, HandoffEnvelope, checkpoint/resume, Tool Budget Governor, postmortems, and Knowledge provenance. Each component retains its stricter local authority boundary when integrated; integration may not broaden it.