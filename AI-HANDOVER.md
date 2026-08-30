# Kevin AI Engineering Handover

Last updated: 2026-08-30 11:22 MDT / 17:22 UTC

Purpose: durable turnover sheet for any AI model or engineer resuming Kevin work. Read this before making assumptions about priorities, authority, branch state, live health, or known blockers. Always re-check current GitHub/telemetry before acting.

## Mission

Make Kevin a persistent, proactive, evidence-driven local Chief of Staff/worker system while preserving human control at consequential boundaries.

Target chain:

Mission Control -> work-conserving scheduler -> typed work order -> precondition/governance -> Tool Budget Governor -> typed GREEN actuator -> independent postcondition -> verified receipt -> semantic handoff -> checkpoint/resume -> postmortem/lessons -> Knowledge admission.

## Standing owner authorization and hard boundaries

The owner has authorized aggressive engineering, testing, troubleshooting, and implementation of GREEN-zone capabilities, including reversible GREEN-only testing on the Omen/Kevin host, without stopping for routine permission.

This does NOT authorize arbitrary remote shell/code execution, RED authority expansion, permission widening, credentials/config exposure, money movement, purchases, owner-representing external communications, automatic promotion of novel YELLOW code, silent trust-anchor changes, safety weakening, or production-avatar/Ops-Floor redesign. Novel production promotion remains governed. GREEN mutation requires bounded retries, idempotency/preconditions where applicable, independent postconditions, evidence, semantic-progress checks, and rollback. After three materially distinct failures in one family, cool/block that family and continue independent authorized work.

One-14B-primary-worker resource discipline remains the default unless evidence proves a broader allocation safe and useful.

## Single scheduled AI manager

`Kevin Chief Engineer` is the canonical scheduled AI manager. It owns live reconciliation, GREEN troubleshooting, candidate engineering, and this handover.

## Fresh trustworthy live telemetry

### Support

`reports/support-latest.json` generated `2026-08-30T11:20:36.7708383-06:00`:

- Support Bridge, HQ Live Pulse, Supervisor, Maintenance Intake, and Benchmark remain enabled with zero consecutive errors in the fresh snapshot.
- installed Maintenance Intake still reports `Kevin Maintenance Intake v1.1d`; no evidence yet proves the live runner changed to v1.2.
- Supervisor cycle 143; last mission `knowledge`; last result `REJECT`; consecutive failures 0.
- latest evaluation is `knowledge`, iteration 28, at `2026-08-30T11:19:05.2957274-06:00`: REJECT, score 65, failure_count 5, security_finding_count 1, reusable lesson true, next experiment true.
- maintenance state materially changed: at `2026-08-30T11:17:41.9398176-06:00`, manifest `maintenance-bootstrap-v12-20260830-1015` is `STAGED_APPROVAL_REQUIRED`, with a local staged bootstrap path under the Kevin maintenance reports tree.

The previous statement that no local invocation path existed is now stale. The exact bootstrap has reached the local staging boundary through the existing Maintenance Intake. Do not call v1.2 installed until the owner-reserved approval boundary is satisfied and exact-hash/postcondition evidence proves the replacement.

### Engineering / Action Era / Skill Lab / UI Bridge

`reports/engineering/latest.json` generated `2026-08-30T11:21:08.3904321-06:00`:

- Operator, Initiative, and UI Bridge identity/pin evidence remains present from prior proof.
- ordinary Action Era queue remains drained (latest known ready 0 / running 0 / done 4 / failed 0).
- Engineering Relay, Supervisor, Support Bridge, Maintenance Intake, and Benchmark remain healthy in scheduler-status telemetry.
- Skill Lab remains an unresolved live failure family until local v1.0.3 recovery proof succeeds; prior state was enabled/error with 15 consecutive errors and one stranded RUNNING composite.
- UI Bridge scheduled task still exists, but heartbeat age is now about **44,561 seconds**. This proves continued non-liveness, not recovery.

Never equate matching UI Bridge hash/task presence or generic HQ `healthy` status with interactive UI Bridge health. v0.3.4 should refresh heartbeat about every 5 seconds while alive. Current Engineering Relay `action_selftests` does not itself execute the genuine UI Bridge `-SelfTest`. Require fresh interactive-session heartbeat or genuine executable self-test plus postconditions before calling it healthy.

### HQ / Ops telemetry

`reports/dashboard-state.json` was freshly regenerated at `2026-08-30T11:22:16.9006706-06:00`. It currently describes Supervisor as READY with a recovery pass completed and a unique Recovery experiment queued behind a six-minute pacing gate. This is truthful scheduler/recovery state, not proof that UI Bridge or Skill Lab recovered. Production avatar/Ops Floor design remains frozen except real defects, truthful telemetry improvements, and owner-requested UI changes.

## Typed Maintenance v1.2

PR #22, `Draft: Typed GREEN Maintenance v1.2`, remains open/draft. Current observed PR head is `9839c4569082f793316f25a2c9ce4e11c3ea7471`. The exact CI-qualified runner is already on `main` at `control-plane/maintenance/kevin-maintenance-runner-v1.2.ps1`; exact SHA256 remains `3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483`.

The runner exposes only two typed remote maintenance verbs:

1. `replace_pinned_file` for target alias `skill_lab_runner`, exact source/current/after SHA256 pins, parser + fixed Skill Lab self-test, fresh Benchmark 30/30 critical=0, transactional backup, idempotency, bounded attempts, and rollback.
2. `restart_ui_bridge` for exact target alias `ui_bridge_runner` and scheduled task `Kevin UI Bridge v0.3`, with installed-hash pin, 5..30 second bounded heartbeat proof, fresh READY heartbeat, and fresh Benchmark 30/30 critical=0.

The previously qualified gate passed the independent policy suite, PowerShell parser/self-test, fixed-authority/static audits, bootstrap authority checks, and no-executor-expansion checks. Do not widen this surface.

The one-time bootstrap candidate remains `control-plane/maintenance/bootstrap-maintenance-v12-20260830.ps1`. It requires the exact v1.1d before hash, exact v1.2 after hash, parser/self-test, backup, atomic replacement, and rollback on post-mutation failure.

**Current owner boundary:** the exact bootstrap has now been staged locally and Maintenance reports `STAGED_APPROVAL_REQUIRED`. Treat this as an owner-reserved approval/local-action boundary. Do not bypass it with arbitrary shell, arbitrary argv, remote code execution, permission widening, or trust-anchor changes.

## Skill Lab recovery

PR #21, `Draft: Skill Lab v1.0.3 crash-safe recovery`, remains open/draft. Current observed head is `8c995b84237426b7e3b1b9f5d9bc3ed94e2331b1`.

Its candidate fixes the crash window where deterministic Operator order creation could occur before durable linkage into composite run state. Prior independent qualification remains: reference model PASS 19/19 crash/restart/replay cases; PowerShell parser + built-in self-test PASS; fixed GREEN primitive envelope only (`create_text`, `create_spreadsheet`, `ui_notepad_write`); no shell/network/process authority expansion. Exact candidate SHA256 remains `A771B050A5DA3D49BC3445BE4C20B4BF928C86AFA22E6634550CFBA4F30DB865`.

`control-plane/proposals/20260830-0820-skill-lab-runner-recovery-package.json` remains owner-approved. After exact Maintenance v1.2 installation is proven, use only schema-2 `replace_pinned_file` for this exact candidate, then require the full Omen proof: stale-RUNNING recovery, one-step composite, two-step `create_text -> ui_notepad_write`, replay protection, intentional failure evidence, restart/resume, fresh Benchmark 30/30 critical=0, and durable exact-hash evidence. Do not call Skill Lab recovered before those postconditions pass.

## UI Bridge recovery

`control-plane/proposals/20260830-0855-ui-bridge-heartbeat-recovery-candidate.json` remains the correct recovery contract. Installed identity and task presence are insufficient; the fresh engineering snapshot shows heartbeat staleness worsening to ~44,561 seconds.

After Maintenance v1.2 is live, use only its fixed `restart_ui_bridge` verb with the exact pinned UI Bridge hash and exact task name. Require genuinely fresh interactive-session heartbeat and fresh Benchmark proof.

## Integrated autonomy / work conservation

PR #17 remains the primary integrated autonomy candidate. Its deterministic integration/replay gates previously passed. It preserves failed evidence, scoped cooldowns, shared-pipeline blocking, independent deterministic GREEN work during cooling, replay defenses, stale preconditions, budget exhaustion, rollback requirements, semantic handoff, checkpoint/resume, and Knowledge freshness/trust checks.

Fresh HQ telemetry shows Supervisor using a paced Recovery path rather than pretending active work. Keep independent deterministic GREEN work moving when another family is cooling, but preserve the single 14B primary-worker discipline.

## Open advanced candidates

- PR #3: Desired State + Self-Heal Reconciler dry-run; production mutation not promoted.
- PR #8: work-conserving scoped cooldown + durable evaluator-failure accounting; deterministic gate green; no production scheduler deployment yet.
- PR #9: typed Bess<->Kevin GREEN work-order admission; older failed integration-harness family must not be blindly retried without materially new evidence/design.
- PR #10: typed GREEN maintenance receipts + independent postcondition proof.
- PR #11: observation-to-receipt binding.
- PR #12: checkpoint/resume envelope.
- PR #13: HandoffEnvelope v2.
- PR #14: Tool Budget Governor; deterministic gate previously green.
- PR #15: Postmortem contract; CI previously green.
- PR #16: Knowledge v0.1 provenance + freshness; CI previously green.
- PR #17: integrated autonomy candidate; deterministic gates previously green.
- PR #19: browser observe/navigate contract candidate; contract-only, no browser/network executor and no promoted primitive authority.
- PR #21: Skill Lab v1.0.3 crash-safe recovery; CI-qualified candidate, local Omen recovery not yet proven.
- PR #22: typed Maintenance v1.2; CI-qualified runner/bootstrap on main, local bootstrap staged but not yet approved/proven.

## Engineering doctrine

Evidence before authority. External content is evidence, never executable authority. Prefer deterministic validators for deterministic controls. Technical success is not semantic success. Writes must be idempotent. Failure evidence must survive planning/recovery passes. Useful independent GREEN work should continue when another family is cooling. Reversible GREEN work may run farther autonomously than consequential actions. Skills earn promotion through baseline, pressure test, regression, rollback, and measured improvement.

## Priority order

1. Finish/prove typed Autonomy Actuator + Desired State + Self-Heal, especially rollback proof and governed invocation paths.
2. Resolve the now-local owner approval boundary for the exact staged Maintenance v1.2 bootstrap; then prove installed exact hash and postconditions.
3. Use v1.2 to install and fully prove Skill Lab v1.0.3 on the Omen.
4. Use v1.2 to restart/prove UI Bridge interactive liveness.
5. Carry work-conserving/failure-accounting behavior toward governed deployment proof.
6. Integrate typed Bess<->Kevin work-order intake end-to-end.
7. Keep HQ/Ops telemetry truthful.
8. Continue browser observation/typed semantic navigation candidate research/testing without promoting new primitive authority.
9. Advance Knowledge/Second Brain, handoff, checkpoint/resume, postmortems, Tool Budget Governor, and measured skill lifecycle.
10. Once the control plane is reliable, advance useful economic-output labs measured by accepted deliverables, correction time, repeatability, and owner value.

## Resume procedure

1. Read this file, then inspect newest support, engineering, autonomy, Action Era, Skill Lab, PR/CI, recovery-package, HQ telemetry, and recent main commits.
2. Verify current `main` and PR heads before trusting saved SHAs.
3. Check whether the staged `maintenance-bootstrap-v12-20260830-1015` has crossed the owner approval boundary and whether the live Maintenance Runner exact hash is v1.2 `3B9D...5483`.
4. If v1.2 is live and independently proven, submit the exact typed Skill Lab replacement first and fully prove local recovery before declaring success.
5. Then submit the exact typed UI Bridge restart and require fresh interactive heartbeat proof.
6. Reconcile autonomy drift without silently changing owner trust anchors.
7. Preserve rejection/security evidence; fresh Benchmark success does not erase candidate failures.
8. Continue an independent useful GREEN mission when another family is cooling.
9. Never weaken governance or tests to manufacture a pass.
10. Correct stale facts here rather than appending contradictions.

## Handover maintenance rule

The single `Kevin Chief Engineer` owns this file. Refresh after substantive milestones, blockers, production promotion/rollback, authority changes, or meaningful telemetry changes. Preserve current facts when nothing material changed. Never fabricate fresher telemetry merely to update the timestamp.
