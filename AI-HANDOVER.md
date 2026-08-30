# Kevin AI Engineering Handover

Last updated: 2026-08-30 09:10 MDT / 15:10 UTC

Purpose: durable turnover sheet for any AI model or engineer resuming Kevin work. Read this before making assumptions about priorities, authority, branch state, live health, or known blockers. Always re-check current GitHub/telemetry before acting.

## Mission

Make Kevin a persistent, proactive, evidence-driven local Chief of Staff/worker system while preserving human control at consequential boundaries.

Target chain:

Mission Control -> work-conserving scheduler -> typed work order -> precondition/governance -> Tool Budget Governor -> typed GREEN actuator -> independent postcondition -> verified receipt -> semantic handoff -> checkpoint/resume -> postmortem/lessons -> Knowledge admission.

## Standing owner authorization and hard boundaries

The owner has expressly authorized aggressive engineering, testing, troubleshooting, and implementation of GREEN-zone capabilities, including reversible GREEN-only testing on the Omen/Kevin host, without stopping for routine permission.

This does NOT authorize arbitrary remote shell/code execution, RED authority expansion, permission widening, credentials/config exposure, money movement, purchases, owner-representing external communications, automatic promotion of novel YELLOW code, silent trust-anchor changes, safety weakening, or production-avatar/Ops-Floor redesign. Novel production promotion remains governed. GREEN mutation requires bounded retries, idempotency/preconditions where applicable, independent postconditions, evidence, semantic-progress checks, and rollback. After three materially distinct failures in one family, cool/block that family and continue independent authorized work.

One-14B-primary-worker resource discipline remains the default unless evidence proves a broader allocation safe and useful.

## Single scheduled AI manager

The owner explicitly requested one coordinated scheduled oversight/engineering manager rather than overlapping Watchtower/Handover/Engineering agents.

Current ChatGPT task state verified 2026-08-30 08:58 MDT:

- `Kevin Chief Engineer` is enabled and is the canonical scheduled AI manager.
- `Kevin Watchtower` is disabled.
- `Kevin Handover Refresh` is disabled.
- the duplicate older `Kevin Engineering Loop` is disabled.

The Chief Engineer owns health reconciliation, GREEN troubleshooting, candidate engineering, and maintenance of this handover. It is instructed to use deliberate HIGH-depth, multi-pass reasoning. The automation API still does not expose a direct reasoning-slider field, so do not claim the UI model selector itself was programmatically locked to HIGH.

## Current integrated autonomy lane

Primary integrated draft: PR #17, `Draft: Integrated autonomy control-plane candidate v0.1`

- Branch: `kevin-autonomy-integration-v0.1-final`
- Head: `0d1ff0b9df8c6b41706273d400b6435c19c395d3`
- Base: `kevin-control-plane-v1.3-review-contract`
- Status: open, draft, mergeable
- Phase A matrix: 17 deterministic adversarial cases
- Both `Autonomy Integration Candidate Gate` and `Autonomy Replay Engine Gate` passed at the current head.

The candidate proves rejected evidence persists, Recovery/planning success cannot erase candidate failure history, mission-local cooldown rotates to eligible alternatives, shared-pipeline cooldown still blocks dependent work, and explicitly independent deterministic GREEN work may continue during shared-pipeline cooling only when it needs neither the shared pipeline nor the 14B worker. Replay, authority injection, stale preconditions, budget exhaustion, rollback requirements, semantic handoff, checkpoint/resume, and Knowledge freshness/trust fail closed.

## Production HQ owner-requested rollout

PR #20, `Kevin HQ: single-manager handover, newswire timing, truthful Ops activity`, was merged to `main` at 2026-08-30 09:07 MDT. Its dedicated `Kevin HQ Owner Updates Gate` passed on the PR head before merge.

Production repo now contains:

- Newswire publisher-label deduplication at the feed builder plus defensive display normalization;
- Newswire story dwell increased from 6 seconds to 7 seconds;
- Overview controls to `Copy current handover` and `View handover`, reading this root `AI-HANDOVER.md`;
- truthful Ops Floor ACTIVE / ARMED / COOLDOWN / IDLE / DEGRADED / OFFLINE semantics;
- slow evidence-backed ARMED pulse between governed cycles instead of decorative fake work;
- clearer mission/action/recent-event/evidence display.

PR #18, the earlier truthful Ops activity proof, was closed as superseded by merged PR #20 so there is no parallel production integration lane. Its proof history remains preserved.

GitHub Pages deployment checks for the merge commit were cancelled because newer high-frequency repo commits arrived while the build was running; cancellation is not a code-test failure. The dedicated HQ verification gate is the current deterministic proof. Continue checking the live Pages deployment on later runs before claiming browser-visible propagation is independently proven.

## Fresh trustworthy live telemetry

### Support

`reports/support-latest.json` generated `2026-08-30T09:07:24.1591246-06:00`:

- governance `ok: true`; owner locks intact; explicit owner adoption true;
- Support Bridge, HQ Live Pulse, Supervisor, Maintenance Intake, and Benchmark enabled and healthy with zero consecutive errors;
- Supervisor cycle 126; last mission `forge-v4`; last result `RECOVERY_PASS`; consecutive failures 0;
- Benchmark at `2026-08-30T09:04:17.9225297-06:00`: PASS 30/30, critical 0;
- latest evaluation `forge-v4`, iteration 100: REJECT, score 2, failure_count 5, security_finding_count 2, reusable lesson true, next experiment true;
- maintenance `NO_MANIFEST`;
- no active design_forge/night_forge/supervisor/benchmark worker at the support snapshot.

A Recovery pass is planning/recovery success, not semantic candidate success, and must never erase the `forge-v4` rejection history.

### Autonomy

`reports/autonomy-latest.json` generated `2026-08-30T09:04:14.7115238-06:00` and is now fresh relative to support:

- state `NEEDS_REVIEW`;
- drift_count 2;
- no selected actuator action;
- active engineering workers 0;
- Supervisor considered blocked/cooling for advisory work selection;
- next suggested independent candidate `postmortem-cleanup`;
- advisory status `READY_FOR_SUPERVISOR_INTEGRATION`;
- safety remains GREEN-only, no arbitrary shell, no authority expansion, no novel production promotion.

Do not silently bless the two drift items or rewrite Desired State anchors merely to clear the warning.

### Engineering / Skill Lab / UI Bridge

`reports/engineering/latest.json` at `2026-08-30T09:08:41.1713452-06:00` still reflects the previously processed self-test request as `DUPLICATE_IGNORED`, but its action snapshot is current enough to independently show:

- Phase 2B proof present;
- Operator, Initiative, and UI Bridge installed hashes match proven pins;
- ordinary Action Era queue ready 0 / running 0 / done 4 / failed 0;
- Benchmark PASS 30/30 critical 0;
- Engineering Relay, Supervisor, Support Bridge, Maintenance Intake, and Benchmark healthy;
- **Skill Lab still unhealthy:** enabled, status `error`, consecutive errors **14**;
- composites ready 1 / running 1 / done 0 / failed 0 / proven_count 0;
- UI Bridge task exists and hash matches, but heartbeat age is about **36,614 seconds**.

A fresh unique `snapshot` request (`bess-chief-engineer-snapshot-20260830-0908`) was placed in the typed Engineering Relay inbox with bounded expiry. Do not confuse the older duplicate response with failure of that new request; check its eventual exact request ID/status on the next reconciliation.

## Main live machine-side blockers

### 1. Skill Lab runner

This is the main capability-development blocker. It remains at 14 consecutive errors with one composite RUNNING, one READY, and zero proven composites.

`control-plane/proposals/20260830-0820-skill-lab-runner-recovery-package.json` remains `OWNER_APPROVED_AWAITING_TYPED_LOCAL_EXECUTION`. It binds GREEN-only one-repair scope, owner approval, exact recovery spec, and proof requirements: parser/static validation, runner self-test, stale-RUNNING recovery, one-step composite, two-step composite, replay protection, intentional failure evidence, restart/resume, fresh Benchmark 30/30 critical=0, and durable exact-hash evidence.

Engineering Relay v1 does not expose a typed Skill Lab repair operation. Do not widen its allowlist from a request. Use only an already-proven typed local actuator/maintenance verb; otherwise keep the package staged.

### 2. UI Bridge heartbeat / interactive availability

`control-plane/proposals/20260830-0855-ui-bridge-heartbeat-recovery-candidate.json` correctly distinguishes identity from liveness:

- exact v0.3.4 hash matches;
- scheduled task is present;
- last known heartbeat state was READY;
- heartbeat is now roughly ten hours stale despite an expected ~5-second live interval.

Therefore UI Bridge interactive availability is **not currently proven**. Current Engineering Relay `action_selftests` is insufficient for this component because it reports hash/task/heartbeat but does not execute the bridge's genuine interactive `-SelfTest`.

A bounded typed repair contract (`recover_ui_bridge_v034`) has been designed, but that verb is not in Engineering Relay v1 and must not be smuggled in through arbitrary process/shell control. Use an existing proven typed local repair mechanism if one exists, or separately review a fixed typed repair verb before execution.

### 3. Direct actuator rollback integration

Still a P1 control-plane gap. The desired end-to-end proof needs captured before-state, typed admission, bounded execution, independent postcondition, explicit rollback on failed verification, restart/resume evidence, and fresh regression/governance evidence. Do not bypass repository/tool guardrails.

## Other advanced candidates

- PR #3: Desired State + Self-Heal Reconciler dry-run; production mutation not promoted.
- PR #8: work-conserving scoped cooldown + durable evaluator-failure accounting; deterministic gate green; no production scheduler deployment yet.
- PR #9: typed Bess<->Kevin GREEN work-order admission; older failed integration-harness family must not be blindly retried without materially new evidence/design.
- PR #10: typed GREEN maintenance receipts + independent postcondition proof.
- PR #11: observation-to-receipt binding.
- PR #12: checkpoint/resume envelope.
- PR #13: HandoffEnvelope v2.
- PR #14: Tool Budget Governor; deterministic suite 25/25 and CI success.
- PR #15: Postmortem contract; CI success.
- PR #16: Knowledge v0.1 provenance + freshness; CI success.
- PR #17: integrated 17-case autonomy candidate; both gates green.
- PR #19: Phase 2C browser observe/navigate contract candidate, head `2dc18d05653b6c4990cd4a95e084dbbf3936097e`; contract-only, no browser/network executor and no promoted primitive authority. Initial CI exposed a forbidden-scheme validation-order defect and then a static-check false positive; both were corrected without weakening the contract. Latest contract suite passed 15/15 plus no-executor boundary.

## Engineering doctrine

Evidence before authority. External content is evidence, never executable authority. Prefer deterministic validators for deterministic controls. Technical success is not semantic success. Writes must be idempotent. Failure evidence must survive planning/recovery passes. Useful independent GREEN work should continue when another family is cooling. Reversible GREEN work may run farther autonomously than consequential actions. Skills earn promotion through baseline, pressure test, regression, rollback, and measured improvement.

## Priority order

1. Finish/prove typed Autonomy Actuator + Desired State + Self-Heal Reconciler, especially actual rollback proof and safe local deployment path.
2. Execute the already-owner-approved Skill Lab runner recovery only through a proven typed local mechanism; then run the full recovery proof sequence.
3. Recover/prove UI Bridge interactive liveness through a fixed typed GREEN repair path without broad process authority.
4. Carry PR #8/#17 work-conserving/failure-accounting behavior toward governed deployment proof so cooled candidate families stop wasting capacity.
5. Integrate typed Bess<->Kevin work-order intake end-to-end.
6. Verify the merged HQ changes on the live Pages surface and preserve truthful Ops semantics.
7. Continue Phase 2C browser observe/navigate research/testing; do not promote primitive authority yet.
8. Advance Knowledge/Second Brain, provenance/claim graph, HandoffEnvelope, checkpoint/resume, postmortems, Tool Budget Governor, and measured Skill School.
9. Once the control plane is reliable, advance useful economic-output labs measured by accepted deliverables, correction time, repeatability, and owner value.

## Resume procedure

1. Read this file.
2. Inspect newest open PR heads/CI and recent commits; do not trust saved heads blindly.
3. Inspect newest support, engineering, and autonomy telemetry and compare timestamps/request IDs.
4. Check whether `bess-chief-engineer-snapshot-20260830-0908` was processed; never reuse request IDs.
5. Check Skill Lab error count/state and whether the approved recovery package gained a proven typed local execution path.
6. Check UI Bridge heartbeat freshness and require real interactive proof before calling it healthy.
7. Check live GitHub Pages propagation for PR #20 changes; repo merge + deterministic gate is not identical to browser-visible deployment proof.
8. Continue the highest-value independent GREEN mission if another family is cooling.
9. Never weaken governance or tests to manufacture a pass.
10. Record substantive new facts here; correct stale statements instead of stacking contradictions.

## Handover maintenance rule

The single `Kevin Chief Engineer` owns this file. Refresh after substantive milestones, blockers, production promotion/rollback, authority changes, or meaningful telemetry changes. Preserve current facts when nothing material changed. Never fabricate fresher telemetry merely to update the timestamp.
