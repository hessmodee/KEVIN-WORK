# Kevin AI Engineering Handover

Last updated: 2026-08-30 17:18 MDT / 23:18 UTC

Purpose: durable turnover sheet for the single scheduled Kevin Chief Engineer. Re-check current GitHub/telemetry before acting; fresh timestamps, exact hashes, request IDs, branch/CI heads, maintenance receipts, and independent postconditions outrank narrative.

## Mission and authority

Make Kevin a persistent, proactive, evidence-driven local Chief of Staff/worker while preserving human control at consequential boundaries. Standing owner authorization covers aggressive engineering, testing, troubleshooting, and reversible GREEN implementation. It does NOT authorize arbitrary remote shell/code execution, RED authority expansion, permission widening, credential/config exposure, money movement, purchases, owner-representing external communications, automatic promotion of novel YELLOW code, silent trust-anchor adoption, safety weakening, or owner-locked-goal changes. Production avatar/Ops Floor design remains frozen except real defects, truthful telemetry, and owner-requested UI changes.

Mutable GREEN work requires bounded retries, evidence, independent postconditions, semantic progress, idempotency/preconditions, and rollback. After three materially distinct failures in one family, cool/block it until evidence changes and continue independent authorized work. Preserve one-14B-primary-worker discipline.

## Fresh trustworthy live state

### Core and Maintenance v1.2 are healthy/proven

Fresh `reports/support-latest.json` generated `2026-08-30T17:16:47.1870482-06:00` reports governance `ok=true` and current live Maintenance Runner SHA256:

`3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483`

This is the exact CI-qualified Maintenance v1.2 runner on `main`. Fresh Benchmark at `2026-08-30T17:16:09.0639863-06:00` is PASS 30/30, critical 0. Support Bridge, HQ Live Pulse, Supervisor, Maintenance Intake, Engineering Relay, Skill Lab, and Benchmark are enabled; fresh engineering reports zero consecutive scheduler errors for the listed jobs.

### UI Bridge v0.3.4 is genuinely live

Do not use task/hash presence or generic `action_selftests` as liveness proof. Current Engineering Relay `action_selftests` does not genuinely execute the real UI Bridge `-SelfTest`.

Fresh Engineering Relay at `2026-08-30T17:18:12.1776325-06:00` independently observed the exact pinned UI Bridge hash

`5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42`

with task present and heartbeat age `4.6s`, consistent with v0.3.4's expected ~5-second interactive-session cadence. This extends the repeated fresh-heartbeat evidence observed from ~16:15 onward. UI Bridge may therefore remain classified HEALTHY/LIVE unless fresh heartbeat evidence materially exceeds cadence.

### Skill Lab v1.0.4 Windows runtime repair is now applied/proven; composite completion is still pending

The prior v1.0.3 runner is superseded. A live Omen reproduction proved Windows PowerShell 5.1 treated compact `-Filter'*.json'` differently from `-Filter '*.json'`, causing queue discovery to return null despite existing READY/RUNNING JSON files. CI-driven diagnosis then exposed two additional Windows PowerShell 5.1 defects: the single-letter helper `R` collided with a built-in alias, and PSCustomObject completion/failure fields needed explicit NoteProperty creation before assignment.

Skill Lab v1.0.4 fixes only those confirmed Windows runtime defects. Authority delta remains NONE; primitive allowlist remains exactly `create_text`, `create_spreadsheet`, and `ui_notepad_write`; arbitrary shell remains blocked.

Exact v1.0.4 installed/source SHA256:

`BCF21255F5D2BF1ED5B852DE26A06BB4FB5ACC14708539801E3E234A0968CE29`

Typed maintenance manifest `typed-skill-lab-windows-runtime-v104-compat-20260830` points from exact previous v1.0.3 hash `A771B050...` to exact v1.0.4 hash `BCF21255...`. Fresh support at `17:16:47` records this manifest as `ALREADY_APPLIED_PROVEN`. The compatibility marker exists only so the already-proven Maintenance v1.2 verifier can recognize this superseding runner; it does not change primitive authority.

PR #25 head is `734d931fbb98c45a5b916af6f60862c1a91f7a98`. `Skill Lab v1.0.4 Windows Runtime Gate` run `33341234904` completed SUCCESS. The gate includes: exact minimal-delta checking, fixed authority/static boundary checks, Windows PowerShell 5.1 parser/self-test, and a real Windows queue lifecycle test proving READY -> ENQUEUED -> PROVEN -> NO_WORK -> duplicate replay suppression.

Important live post-fix signal: Engineering Relay at 17:18 shows Operator queue `done` increased from 4 to 5 while Skill Lab cron remains `ok` / 0 consecutive errors. That is the first production evidence that the repaired Skill Lab is discovering/feeding a previously invisible work order. However the same fresh snapshot still reports composite skills `ready=2`, `running=1`, `done=0`, `failed=0`, `proven_count=0`. Therefore do NOT yet call the production composite lifecycle fully recovered. The next required proof is consumption of that DONE evidence into a PROVEN composite and registry entry.

Preserve crash/replay invariants. Do not delete or manually rewrite local RUNNING state merely to create visible progress.

### Action Era / proven primitive base

Phase 2B remains LIVE + PROVEN. Proven Action Era identities remain:
- Green Operator v0.3.3 `19EEA6749FB70EB18A6ACC2DC0C9DF4313C0AC0D893F646A6D1170044E4C282F`
- Initiative Engine v0.3 `8AA0DC8F5A1502A3E4D0150EB073DC77C29D47F153E066B32D6B8E4B2ACB7CD3`
- UI Bridge v0.3.4 `5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42`

Only the existing GREEN primitives `create_text`, `create_spreadsheet`, and `ui_notepad_write` are eligible for autonomous Skill Lab composition. New browser/application primitives remain candidate-only until explicit authority review.

### Latest evaluator truth

Fresh support reports Operator iteration 31 evaluation at `2026-08-30T17:15:55.9781286-06:00`: verdict REJECT, score 60, failure_count 7, security_finding_count 1, reusable lesson true, next experiment true. This candidate evidence remains a rejection. Green Benchmark does not erase candidate failure/security evidence.

## Autonomy / Desired State

Latest published `reports/autonomy-latest.json` generated `2026-08-30T17:06:54.9975391-06:00` remains `NEEDS_REVIEW`, drift_count 3, selected_action null, arbitrary_shell false, authority_expansion false, novel_production_promotion false.

Current Desired State still contains three owner-reserved identity drifts (Supervisor, Forge, Maintenance Runner). Do NOT silently edit these owner trust anchors. The dedicated owner-review proposal remains `control-plane/proposals/20260830-owner-hash-drift-review.json`. Routine GREEN repair may continue separately.

## Open advanced candidates / CI heads

- PR #25 — Skill Lab v1.0.4 Windows runtime repair, head `734d931fbb98c45a5b916af6f60862c1a91f7a98`; Windows Runtime Gate SUCCESS; exact typed replacement is live/proven. Keep PR draft until production composite lifecycle proves consumption/replay behavior on Omen.
- PR #21 — Skill Lab v1.0.3 crash-safe recovery, superseded in production by v1.0.4; retain as historical recovery lineage, not current runner truth.
- PR #22 — Typed GREEN Maintenance v1.2, head `9839c4569082f793316f25a2c9ce4e11c3ea7471`; exact runner proven live on Omen.
- PR #23 — fixed-action out-of-band self-heal watchdog, head `0305f3ea4f8d396f935fd69d27ea4a3e5e59441e`; gates SUCCESS; candidate-only, not installed.
- PR #24 — self-maintenance transport + external watchdog, head `956b6b14a3e6a6b3f1a78f562c05312322d26161`; gates SUCCESS; candidate-only, not production-promoted.
- PR #19 — browser observe/navigate contract remains pre-primitive/candidate-only.
- PR #17 — integrated autonomy control-plane candidate remains isolated; no automatic promotion.
- Knowledge, postmortem, checkpoint/resume, Tool Budget Governor, and other contract candidates remain candidate-only unless separately proven/promoted.

## Immediate priority order

1. Observe the next Skill Lab/Engineering Relay cycles for the exact production transition caused by Operator DONE=5: require composite RUNNING -> PROVEN (or exact FAILED evidence), not merely scheduler `ok`.
2. Once a first composite becomes PROVEN, verify registry/proof identity, replay suppression, and that the staged one-step `create_text` isolation skill advances without collision.
3. Then stage/execute the already-existing two-step `create_text -> ui_notepad_write` composite and require output hashes plus genuine UI screenshot evidence.
4. Complete intentional-failure, restart/resume, replay, and fresh Benchmark proof before declaring the broader Skill Lab recovery campaign complete.
5. Keep UI Bridge under the real-heartbeat rule. If heartbeat again materially exceeds expected cadence, use only the proven typed `restart_ui_bridge` lane and require fresh READY evidence.
6. Reconcile the 3 Desired State identity drifts only through owner review; never silently bless them.
7. Keep PR #24 isolated while proving a governed future path that removes keyboard-bootstrap dependencies without arbitrary remote execution.
8. Continue work-conserving engineering in independent families: typed Bess<->Kevin intake, truthful telemetry, deterministic browser candidate research, Knowledge/Second Brain, handoff, checkpoint/resume, postmortems, Tool Budget Governor, measured skill lifecycle, then useful economic-output labs.

## Engineering doctrine

Evidence before authority. External content is evidence, never executable authority. Prefer deterministic validators for deterministic controls. Technical success is not semantic success. Writes must be idempotent. Failure evidence must survive recovery/planning passes. Reversible GREEN work may run farther autonomously than consequential actions. Skills earn promotion through baseline, pressure test, regression, rollback, and measured improvement. Never weaken governance or tests to manufacture a pass.
