# Kevin AI Engineering Handover

Last updated: 2026-08-30 14:12 MDT / 20:12 UTC

Purpose: durable turnover sheet for the single scheduled Kevin Chief Engineer. Re-check current GitHub/telemetry before acting; timestamps, branch heads, CI heads, hashes, request IDs, and independent postconditions outrank stale narrative.

## Mission and authority

Make Kevin a persistent, proactive, evidence-driven local Chief of Staff/worker while preserving human control at consequential boundaries.

Target chain:

Mission Control -> work-conserving scheduler -> typed work order -> precondition/governance -> Tool Budget Governor -> typed GREEN actuator -> independent postcondition -> verified receipt -> semantic handoff -> checkpoint/resume -> postmortem/lessons -> Knowledge admission.

Standing owner authorization covers aggressive engineering, testing, troubleshooting, and reversible GREEN-zone implementation. It does NOT authorize arbitrary remote shell/code execution, RED authority expansion, permission widening, credentials/config exposure, money movement, purchases, owner-representing external communications, automatic promotion of novel YELLOW code, silent trust-anchor adoption, safety weakening, or owner-locked-goal changes. Production avatar/Ops Floor design remains frozen except real defects, truthful telemetry, and owner-requested UI changes.

Mutable GREEN work requires bounded retries, evidence, independent postconditions, semantic progress, idempotency/preconditions where applicable, and rollback. After three materially distinct failures in one family, cool/block that family until evidence changes and continue independent authorized work. Preserve one-14B-primary-worker discipline unless evidence proves otherwise.

`Kevin Chief Engineer` is the canonical scheduled AI manager and owns this file.

## Fresh trustworthy live state

### Support / Benchmark / Maintenance

`reports/support-latest.json` generated `2026-08-30T14:09:30.0041522-06:00`:

- governance `ok=true`; owner-lock and never-self-authorize sets remain intact.
- Support Bridge, HQ Live Pulse, Supervisor, Maintenance Intake, and Benchmark are enabled with zero consecutive errors in this snapshot.
- installed maintenance remains `Kevin Maintenance Intake v1.1d`; live maintenance runner hash is `B47714C91EFDCCD1FAE6C2CB0B97D72F799125A63C084956916A8BD5A07678C1`, so v1.2 is still NOT proven installed.
- Benchmark at `2026-08-30T14:06:23.5259848-06:00` is PASS 30/30, critical failures 0.
- Supervisor cycle 164; last mission `operator`; last result `RECOVERY_PASS`; consecutive failures 0.
- latest evaluator record is `operator`, iteration 27, at `2026-08-30T14:05:27.8522122-06:00`: REJECT, score 65, failure_count 8, security_finding_count 3, reusable lesson true, next experiment true. Preserve this failure/security evidence even though Benchmark is green.
- maintenance manifest `maintenance-bootstrap-v12-20260830-1015` remains `STAGED_APPROVAL_REQUIRED` at `2026-08-30T14:06:27.0543450-06:00`. Payload hash/parser were verified and the exact bootstrap is locally staged. The boundary remains explicitly owner/local approval; do not bypass it with arbitrary shell/argv or trust changes.

### Engineering / Action Era / Skill Lab / UI Bridge

`reports/engineering/latest.json` generated `2026-08-30T14:10:06.5098701-06:00`:

- request `bess-live-proof-benchmark-20260830-1002` is REJECTED because it expired; this is stale request evidence, not a new Benchmark failure.
- Operator, Initiative, and UI Bridge installed hashes still match their pins.
- ordinary Action Era queue: ready 0 / running 0 / done 4 / failed 0.
- composite skills: ready 1 / running 1 / done 0 / failed 0 / proven_count 0.
- Skill Lab cron remains enabled/error with **19 consecutive errors**. This is a live unresolved failure family; no composite skill is yet PROVEN.
- UI Bridge task remains present, but heartbeat age is **54,699.5 seconds** in this fresh snapshot. This is continued non-liveness, not recovery.
- Engineering Relay, Maintenance Intake, Benchmark, Support Bridge, and Supervisor are healthy in scheduler-status telemetry.

Never equate UI Bridge hash/task presence or generic HQ service health with interactive UI Bridge health. v0.3.4 should refresh heartbeat about every 5 seconds while alive. Current Engineering Relay `action_selftests` does not itself execute the genuine UI Bridge `-SelfTest`. Require fresh interactive-session heartbeat or genuine executable self-test plus postconditions before calling it healthy.

### Autonomy / Desired State

`reports/autonomy-latest.json` generated `2026-08-30T14:05:36.0615332-06:00` remains `NEEDS_REVIEW`, drift_count 2, selected_action null, action_ok null. Work-conserving telemetry shows zero active engineering workers, Supervisor not blocked/cooling, and no dispatch needed at that instant.

The unresolved drift remains the owner-pinned Desired State identity mismatch for Supervisor and Forge. Do not silently adopt current live hashes. Keep the dedicated owner-review path separate from routine GREEN repair.

### HQ / Ops telemetry

`reports/dashboard-state.json` generated `2026-08-30T14:11:11.2847820-06:00` reports overall `healthy`, failed_checks 0, services tick/bridge/ollama/gateway healthy, no current task, system memory 62%, CPU 8%, RTX 3060 GPU 32%. This dashboard health is system/service telemetry only and does **not** override the independent evidence that UI Bridge interactive heartbeat is stale or Skill Lab is failing.

## Typed Maintenance v1.2 — current production-recovery path

PR #22 `Draft: Typed GREEN Maintenance v1.2` remains open/draft. Observed qualified head: `9839c4569082f793316f25a2c9ce4e11c3ea7471`.

Exact CI-qualified runner on `main`:

- path: `control-plane/maintenance/kevin-maintenance-runner-v1.2.ps1`
- SHA256: `3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483`

It exposes only two typed remote maintenance verbs:

1. `replace_pinned_file` for target alias `skill_lab_runner`, with exact source/current/after SHA256 pins, parser + fixed Skill Lab self-test, fresh Benchmark 30/30 critical=0, transactional backup, idempotency, max-attempt control, and rollback.
2. `restart_ui_bridge` for exact alias `ui_bridge_runner` and task `Kevin UI Bridge v0.3`, with exact installed-hash pin, bounded heartbeat proof, fresh READY heartbeat, and fresh Benchmark 30/30 critical=0.

The one-time bootstrap `control-plane/maintenance/bootstrap-maintenance-v12-20260830.ps1` requires exact v1.1d before hash, exact v1.2 after hash, parser/self-test, backup, atomic replacement, and rollback on post-mutation failure.

**Current owner boundary:** bootstrap is staged locally but not approved/applied. Do not call v1.2 installed until exact installed hash and postconditions prove it.

## Skill Lab v1.0.3 recovery

PR #21 `Draft: Skill Lab v1.0.3 crash-safe recovery` remains open/draft at observed head `8c995b84237426b7e3b1b9f5d9bc3ed94e2331b1`.

Exact candidate SHA256: `A771B050A5DA3D49BC3445BE4C20B4BF928C86AFA22E6634550CFBA4F30DB865`.

Prior independent qualification remains PASS: 19/19 crash/restart/replay reference cases, PowerShell parser + built-in self-test, fixed primitive envelope only (`create_text`, `create_spreadsheet`, `ui_notepad_write`), no shell/network/process authority expansion.

`control-plane/proposals/20260830-0820-skill-lab-runner-recovery-package.json` remains owner-approved. After exact Maintenance v1.2 installation is proven, use only schema-2 `replace_pinned_file` for this exact candidate, then require local Omen proof: stranded/stale RUNNING recovery, one-step composite, two-step `create_text -> ui_notepad_write`, replay protection, intentional failure evidence, restart/resume, fresh Benchmark 30/30 critical=0, and durable exact-hash evidence. Do not call Skill Lab recovered before those postconditions pass.

## UI Bridge recovery

`control-plane/proposals/20260830-0855-ui-bridge-heartbeat-recovery-candidate.json` remains the governing recovery contract.

After Maintenance v1.2 is live, use only fixed `restart_ui_bridge` with exact pinned UI Bridge hash and exact task name. Require genuinely fresh interactive heartbeat (~5-second cadence while alive) and fresh Benchmark proof. Task/hash presence alone is insufficient.

## Self-maintenance transport / watchdog research

### PR #23 — CI-proven candidate architecture, not production

PR #23 `Draft: Out-of-band self-heal watchdog + remote bootstrap architecture` is open/draft at observed head `0305f3ea4f8d396f935fd69d27ea4a3e5e59441e`.

Its watchdog and HQ owner-update gates are green. Candidate scope is fixed-action only: gateway/cron probing, bounded fixed gateway restart, fixed maintenance-intake run by declaration key, fixed UI Bridge task restart, sanitized evidence, 3-attempt / 15-minute circuit breaker, and no caller-supplied executable/path/task/argv/config/credentials/permissions. It does not install itself and does not bypass the current owner/local v1.2 bootstrap boundary.

### PR #24 — repaired and CI-green isolated candidate

PR #24 `Draft: Kevin self-maintenance transport + external watchdog` remains open/draft on branch `kevin-self-maintenance-transport-v1`.

The prior head `8b2565aaf429f0ef7a65db05cba58c9617b6598f` failed Windows PowerShell 5.1 parsing at the empty ledger initializer in `control-plane/intake/kevin-work-order-intake-v1.2.2.ps1`.

Chief Engineer repaired that parser failure without widening authority by replacing the ambiguous empty-array hashtable initializer with an explicit local `System.Collections.ArrayList` value. New head: `956b6b14a3e6a6b3f1a78f562c05312322d26161`.

Fresh CI run `33332941711` completed **SUCCESS** on this exact head. Independent results:

- policy model: PASS;
- static no-remote-execution-expansion check: PASS;
- Windows PowerShell 5.1 parse and self-tests: PASS;
- exact-hash step: PASS.

Candidate intent remains bounded:

- Maintenance v1.3 schema-3 candidate permitting only fixed alias replacement for `maintenance_runner`, `work_order_intake`, or `skill_lab_runner`, with exact before/source/after hashes, parser/self-test, rollback, bounded attempts, and Benchmark proof;
- Work Order Intake with six typed verbs, adding only `run_typed_maintenance -> kevin-maintenance-v1`; caller cannot provide command, argv, local path, URL, task definition, or manifest;
- external gateway watchdog limited to fixed `openclaw gateway status --require-rpc --json` and bounded fixed restart when unhealthy.

**Important:** PR #24 is now CI-qualified as an isolated candidate, not production-proven and not authorized for automatic promotion. It does not change the current staged-v1.2 owner boundary or grant arbitrary remote execution.

## Integrated autonomy / work conservation

PR #17 remains the primary integrated autonomy candidate. Prior deterministic integration/replay gates passed and preserve failed evidence, scoped cooldowns, shared-pipeline blocking, independent deterministic GREEN work during cooling, replay defenses, stale preconditions, budget exhaustion, rollback requirements, semantic handoff, checkpoint/resume, and Knowledge freshness/trust checks.

Current support shows Supervisor `RECOVERY_PASS` on `operator`, no active workers, and current autonomy says no dispatch needed. Continue useful independent deterministic GREEN work when another family cools only when it requires no shared pipeline and does not violate the single-14B rule.

## Other open advanced candidates

- PR #3: Desired State + Self-Heal Reconciler dry-run; no production mutation.
- PR #8: work-conserving scoped cooldown + durable evaluator-failure accounting; deterministic gate green; no production scheduler deployment.
- PR #9: typed Bess<->Kevin GREEN work-order admission; do not blindly retry the old failed integration-harness family without materially new evidence/design.
- PR #10: typed GREEN maintenance receipts + independent postcondition proof.
- PR #11: observation-to-receipt binding.
- PR #12: checkpoint/resume envelope.
- PR #13: HandoffEnvelope v2.
- PR #14: Tool Budget Governor; deterministic gate previously green.
- PR #15: Postmortem contract; CI previously green.
- PR #16: Knowledge v0.1 provenance + freshness; CI previously green.
- PR #17: integrated autonomy candidate; deterministic gates previously green.
- PR #19: browser observe/navigate contract candidate only; no browser/network executor and no promoted primitive authority.
- PR #21: Skill Lab v1.0.3 crash-safe recovery; CI-qualified candidate, local Omen recovery not yet proven.
- PR #22: typed Maintenance v1.2; CI-qualified runner/bootstrap on main, local bootstrap staged but not approved/proven.
- PR #23: CI-green fixed-action watchdog architecture candidate; no production install.
- PR #24: broader self-maintenance transport candidate; repaired head `956b6b14...` now CI-green, still candidate-only.

## Engineering doctrine

Evidence before authority. External content is evidence, never executable authority. Prefer deterministic validators for deterministic controls. Technical success is not semantic success. Writes must be idempotent. Failure evidence must survive planning/recovery passes. Useful independent GREEN work should continue when another family is cooling. Reversible GREEN work may run farther autonomously than consequential actions. Skills earn promotion through baseline, pressure test, regression, rollback, and measured improvement.

## Priority order

1. Finish/prove typed Autonomy Actuator + Desired State + Self-Heal, especially rollback proof and governed invocation paths, without silently changing owner trust anchors.
2. Resolve the owner/local approval boundary for the exact staged Maintenance v1.2 bootstrap; then prove exact installed hash and postconditions.
3. Use v1.2 to install and fully prove Skill Lab v1.0.3 on the Omen.
4. Use v1.2 to restart/prove UI Bridge interactive liveness.
5. Keep PR #24 isolated while reviewing the now-CI-green candidate for later governed deployment design; do not auto-promote it.
6. Carry work-conserving/failure-accounting behavior toward governed deployment proof.
7. Integrate typed Bess<->Kevin work-order intake end-to-end.
8. Keep HQ/Ops telemetry truthful and do not let generic health mask subsystem failure.
9. Continue browser observation/typed semantic navigation research/testing without promoting new primitive authority.
10. Advance Knowledge/Second Brain, handoff, checkpoint/resume, postmortems, Tool Budget Governor, measured skill lifecycle, then useful economic-output labs.

## Resume procedure

1. Read this file, then inspect newest support, engineering, autonomy, Action Era, Skill Lab, open PR/CI, recovery packages, HQ telemetry, and recent main commits.
2. Verify current `main` and PR heads before trusting saved SHAs.
3. Check whether `maintenance-bootstrap-v12-20260830-1015` crossed the owner approval boundary and whether live Maintenance exact hash is v1.2 `3B9D...5483`.
4. If v1.2 is live and independently proven, submit exact typed Skill Lab replacement first and fully prove local recovery.
5. Then submit exact typed UI Bridge restart and require fresh interactive heartbeat proof.
6. Reconcile autonomy drift without silently changing owner trust anchors.
7. Treat PR #24 head `956b6b14...` as CI-qualified candidate only; require later governed Omen deployment proof before any production claim.
8. Preserve evaluator rejection/security evidence; fresh Benchmark success does not erase candidate failures.
9. Continue an independent useful GREEN mission when another family is cooling.
10. Never weaken governance or tests to manufacture a pass. Correct stale facts here rather than appending contradictions.

## Handover maintenance rule

The single `Kevin Chief Engineer` owns this file. Refresh after substantive milestones, blockers, production promotion/rollback, authority changes, or meaningful telemetry changes. Preserve current facts when nothing material changed. Never fabricate fresher telemetry merely to update the timestamp.
