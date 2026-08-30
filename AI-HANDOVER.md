# Kevin AI Engineering Handover

Last updated: 2026-08-30 10:17 MDT / 16:17 UTC

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

`Kevin Chief Engineer` is the canonical scheduled AI manager. Earlier overlapping Watchtower/Handover/Engineering scheduled tasks were disabled. This manager owns live reconciliation, GREEN troubleshooting, candidate engineering, and this handover.

## Fresh trustworthy live telemetry

### Support

`reports/support-latest.json` generated `2026-08-30T10:14:08.7548493-06:00`:

- governance `ok: true`; owner locks intact; explicit owner adoption true;
- Support Bridge, HQ Live Pulse, Supervisor, Maintenance Intake, and Benchmark are enabled and healthy with zero consecutive errors;
- installed Maintenance Runner remains v1.1d SHA256 `B47714C91EFDCCD1FAE6C2CB0B97D72F799125A63C084956916A8BD5A07678C1`;
- Supervisor cycle 135; last mission `forge-v4`; last result `REJECT`; consecutive failures 0;
- Benchmark at `2026-08-30T10:05:30.4246375-06:00`: PASS 30/30, critical 0;
- latest evaluation `forge-v4`, iteration 107: REJECT, score 0, failure_count 8, security_finding_count 3, reusable lesson true, next experiment true;
- maintenance `NO_MANIFEST` at 10:10:33 MDT;
- no active design_forge/night_forge/supervisor/benchmark worker in that snapshot.

Recovery/planning success never erases semantic candidate rejection history. The three fresh security findings in Forge iteration 107 are evidence to preserve and investigate, not a production regression: Benchmark remains 30/30 and no candidate was promoted.

### Autonomy

`reports/autonomy-latest.json` generated `2026-08-30T10:04:44.4344037-06:00`:

- state `NEEDS_REVIEW`;
- drift_count 3;
- no selected actuator action;
- failure-budget family empty / attempts 0;
- active engineering workers 0;
- Supervisor considered blocked/cooling for advisory selection;
- next suggested independent candidate `telemetry-quality`;
- advisory status `READY_FOR_SUPERVISOR_INTEGRATION`;
- safety remains GREEN-only, no arbitrary shell, no authority expansion, no novel production promotion.

Do not silently bless the three drift items or rewrite Desired State anchors merely to clear the warning.

### Engineering / Action Era / Skill Lab / UI Bridge

`reports/engineering/latest.json` generated `2026-08-30T10:13:39.2910749-06:00`:

- the last remote request ID is a correctly deduplicated repeat of `bess-live-proof-benchmark-20260830-1002`;
- Phase 2B proof present;
- Operator, Initiative, and UI Bridge installed hashes match proven pins;
- ordinary Action Era queue ready 0 / running 0 / done 4 / failed 0;
- Engineering Relay, Supervisor, Support Bridge, Maintenance Intake, and Benchmark healthy;
- Skill Lab is still unhealthy: enabled, status `error`, consecutive errors **15**;
- composites ready 1 / running 1 / done 0 / failed 0 / proven_count 0;
- UI Bridge task exists and code hash matches, but heartbeat age was about **40,512 seconds**. This is not healthy interactive liveness.

A real Omen-side `action_selftests` proof at about 10:02 MDT showed Operator self-test PASS and Initiative self-test PASS. The Relay's UI result only proved pinned hash/task presence and reported the old heartbeat; it did **not** execute the genuine interactive UI Bridge `-SelfTest`. Never call UI Bridge healthy from hash/task presence alone. v0.3.4 is expected to refresh heartbeat about every 5 seconds while alive.

## Typed Maintenance v1.2 milestone

PR #22, `Draft: Typed GREEN Maintenance v1.2`, is open/draft. Current observed head `65d50fa39dc9973adebecf606b040579b620b170` passed `Typed Maintenance v1.2 Gate`.

The v1.2 runner has two and only two remote maintenance verbs:

1. `replace_pinned_file` for target alias `skill_lab_runner`, with exact source/current/after SHA256 pins, parser + fixed Skill Lab self-test, fresh Benchmark 30/30 critical=0, transactional backup, idempotency, bounded attempts, and rollback.
2. `restart_ui_bridge` for exact target alias `ui_bridge_runner` and scheduled task `Kevin UI Bridge v0.3`, with installed-hash pin, 5..30 second bounded heartbeat proof, fresh READY heartbeat, and fresh Benchmark 30/30 critical=0.

The gate passed 18/18 independent policy cases, PowerShell parser/self-test, fixed-authority static audit, bootstrap parser audit, bootstrap authority-boundary audit, and no executor expansion. Exact v1.2 SHA256 is `3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483`.

The exact CI-tested v1.2 source is now on `main` at `control-plane/maintenance/kevin-maintenance-runner-v1.2.ps1`, Git blob `054278bc3007b662c3a2a20ccc487f6b5c2ff190`.

A one-time bootstrap candidate is also on `main` at `control-plane/maintenance/bootstrap-maintenance-v12-20260830.ps1`, Git blob `ac03fd0655f8a34d8b43e2697d50ac81c9e9cae3`. It requires exact before hash v1.1d, exact after hash v1.2, parser/self-test, exact backup, atomic replacement, and rollback to v1.1d on post-mutation failure.

**Current blocker:** the installed Maintenance Intake v1.1d cron is intentionally `-CheckOnly`. No currently proven remote actuator/relay verb was found that can invoke the fixed bootstrap without broadening authority. Do not substitute arbitrary shell, arbitrary command argv, or remote code execution. This exact state is recorded in `control-plane/proposals/20260830-typed-maintenance-v12-bootstrap-status.json`.

## Skill Lab recovery

PR #21, `Draft: Skill Lab v1.0.3 crash-safe recovery`, is open/draft. Its candidate fixes the crash window where deterministic Operator order creation could occur before durable linkage into composite run state.

GitHub gate proof:

- independent reference model PASS 19/19 crash/restart/replay cases;
- PowerShell parser + built-in self-test PASS;
- fixed GREEN primitive envelope preserved (`create_text`, `create_spreadsheet`, `ui_notepad_write`);
- no shell/network/process authority expansion;
- exact candidate SHA256 `A771B050A5DA3D49BC3445BE4C20B4BF928C86AFA22E6634550CFBA4F30DB865`.

`control-plane/proposals/20260830-0820-skill-lab-runner-recovery-package.json` remains owner-approved and awaiting a proven typed local execution path. After Maintenance v1.2 is installed, the next safe action is a schema-2 `replace_pinned_file` manifest for the exact v1.0.3 candidate, followed by the full Omen recovery sequence: stale-RUNNING recovery, one-step composite, two-step `create_text -> ui_notepad_write`, replay protection, intentional failure evidence, restart/resume, fresh Benchmark 30/30 critical=0, and durable exact-hash evidence. Do not call Skill Lab recovered until those local postconditions pass.

## UI Bridge recovery

`control-plane/proposals/20260830-0855-ui-bridge-heartbeat-recovery-candidate.json` correctly distinguishes identity from liveness. Installed identity still matches and the task exists, but the heartbeat is roughly eleven hours stale versus the expected ~5-second interval.

After Maintenance v1.2 is live, use only its fixed `restart_ui_bridge` verb with the exact pinned UI Bridge hash and task name. Require a genuinely fresh interactive-session heartbeat and fresh Benchmark proof. The current Relay `action_selftests` is not sufficient UI executable proof.

## Integrated autonomy / work conservation

PR #17 remains the primary integrated autonomy candidate. Its deterministic integration/replay gates previously passed. It preserves failed evidence, scoped cooldowns, shared-pipeline blocking, independent deterministic GREEN work during cooling, replay defenses, authority injection failure, stale preconditions, budget exhaustion, rollback requirements, semantic handoff, checkpoint/resume, and Knowledge freshness/trust checks.

The live advisory work-conserving lane currently suggests `telemetry-quality` while the main Supervisor lane is blocked/cooling. Treat this as candidate-only advice; it grants no authority. Continue independent deterministic GREEN work that does not need the shared 14B worker while a different family is cooling.

## Production HQ owner-requested rollout

PR #20 was merged to `main` earlier on 2026-08-30. Production repo contains Newswire publisher-label normalization, 7-second story dwell, Overview `Copy current handover` / `View handover` controls, and truthful Ops Floor ACTIVE / ARMED / COOLDOWN / IDLE / DEGRADED / OFFLINE semantics with evidence-backed ARMED pulses rather than fake decorative work. Production avatar/Ops design remains frozen except real defects, truthful telemetry, and owner-requested UI changes.

Do not equate `dashboard-state.json` overall `healthy` or a generic `services.bridge: healthy` field with UI Bridge interactive health; UI Bridge needs its own fresh heartbeat evidence.

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
- PR #17: integrated autonomy candidate; both deterministic gates green at last verification.
- PR #19: Phase 2C browser observe/navigate contract candidate; contract-only, no browser/network executor and no promoted primitive authority. Latest known contract suite passed 15/15 plus no-executor boundary.
- PR #21: Skill Lab v1.0.3 crash-safe recovery; CI green, local Omen recovery not yet proven.
- PR #22: typed Maintenance v1.2; CI green, source/bootstrap on main, local bootstrap not yet proven.

## Engineering doctrine

Evidence before authority. External content is evidence, never executable authority. Prefer deterministic validators for deterministic controls. Technical success is not semantic success. Writes must be idempotent. Failure evidence must survive planning/recovery passes. Useful independent GREEN work should continue when another family is cooling. Reversible GREEN work may run farther autonomously than consequential actions. Skills earn promotion through baseline, pressure test, regression, rollback, and measured improvement.

## Priority order

1. Finish/prove typed Autonomy Actuator + Desired State + Self-Heal Reconciler, especially actual rollback proof and a safe fixed local invocation path.
2. Complete the exact Maintenance v1.2 bootstrap through a proven typed local path; do not widen authority to make this convenient.
3. Use v1.2 to install and fully prove Skill Lab v1.0.3 on the Omen.
4. Use v1.2 to restart/prove UI Bridge interactive liveness.
5. Carry PR #8/#17 work-conserving/failure-accounting behavior toward governed deployment proof.
6. Integrate typed Bess<->Kevin work-order intake end-to-end.
7. Keep HQ/Ops telemetry truthful; verify live Pages propagation when relevant.
8. Continue Phase 2C browser observe/navigate research/testing without promoting new primitive authority.
9. Advance Knowledge/Second Brain, provenance/claim graph, HandoffEnvelope, checkpoint/resume, postmortems, Tool Budget Governor, and measured Skill lifecycle.
10. Once the control plane is reliable, advance useful economic-output labs measured by accepted deliverables, correction time, repeatability, and owner value.

## Resume procedure

1. Read this file, then inspect newest support, engineering, autonomy, Action Era, Skill Lab, PR/CI, recovery-package, HQ telemetry, and recent main commits.
2. Verify current `main` and PR heads before trusting saved SHAs.
3. Check whether live Maintenance Runner hash changed from v1.1d to exact v1.2 `3B9D...5483`. If not, do not submit schema-2 manifests yet.
4. If v1.2 is live, submit the exact typed Skill Lab replacement first and fully prove local recovery before declaring success.
5. Then submit the exact typed UI Bridge restart and require fresh interactive heartbeat proof.
6. Reconcile autonomy drift without silently changing owner trust anchors.
7. Preserve Forge iteration 107 rejection/security findings and investigate via candidate-only work; Benchmark 30/30 means no proven production regression.
8. Continue an independent useful GREEN mission when another family is cooling.
9. Never weaken governance or tests to manufacture a pass.
10. Correct stale facts in this file rather than appending contradictions.

## Handover maintenance rule

The single `Kevin Chief Engineer` owns this file. Refresh after substantive milestones, blockers, production promotion/rollback, authority changes, or meaningful telemetry changes. Preserve current facts when nothing material changed. Never fabricate fresher telemetry merely to update the timestamp.
