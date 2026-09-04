# CURRENT_TASK

**Updated:** 2026-09-04 09:50 MT
**Role:** current execution contract only. `AI-HANDOVER.md` remains the one human canonical handover.
**Cold-start:** `docs/engineering/KEVIN-TURNOVER-LATEST.md` CURRENT @ 09:43 MT.

## Latest applied (2026-09-04 ~09:00-09:50 MT)

- **PASS:** P0.1 Desktop LIVE on HESS-PC (PR#77). Exact 4 tools on fixed:main. openclaw.json after SHA256 4126AFE64EF809B9A4747D70B9868F0FAB94F554F213C88B0DA832FBF8C5E794. Backup `reports/engineering/backups/p01-desktop-20260904-0809`. Benchmark 30/30. **NOT owner-gated.** Do NOT widen tools or rewrite Desktop config.

- **PASS:** Merged to main PR#74 (routing a5a55c2c56f2), PR#75 (undying auth e05399c6dd50), PR#76 (leases lib 15a098ddd10d), PR#77 (Desktop apply 7bd4e1d0897f).
- **PASS:** YELLOW Superv v1.8.9+selector v1.2 was live; lease wire bumped live Superv to v1.8.10 with mission-lease heartbeats. Skill Lab wired. SelfTests PASS (MISSION-LEASE WIRE).
- **PASS:** After #74, Supervisor sees owner-value/Skill Lab demand (WAITING_ITEM_BUDGETS, eligible_count=1) — no longer IDLE_NO_ELIGIBLE_DEMAND.
- **Residual:** WAITING_ITEM_BUDGETS / MIN_REPEAT deferral on appliance-repair prove; budget-unlock/Forge M1 typed applies still refused; do not touch openclaw.json.


## Owner objective

Operate with maximum bounded autonomy under standing green/yellow auth.

Build Kevin into a truthful, persistent, useful local AI coworker/operator that can self-heal, self-maintain, self-improve, learn and produce owner value 24/7 whenever its qualified runtime is available, while preserving evidence, rollback and authority boundaries.

Current owner-value domains include dealership vehicle work/reconditioning, vehicle diagnosis and repair research, Cache Valley Appliance Repair planning, creator/business development, organization, and future bounded computer/game assistance.

## Operating loop

`OBSERVE -> DIAGNOSE -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> LEARN -> CONTINUE`

When no higher-priority direct owner mission is active, select the highest-value due GREEN work Kevin can actually execute. Treat blocked owner work as work: identify and pursue the smallest safe missing prerequisite rather than pretending to be busy or falsely reporting idle.


## Standing Auth (UNDYING 2026-09-04)

Matt's standing undying authorization (~08:51 MT America/Boise): do **not** wait for per-step permission on ANY green or yellow Kevin work. Authorized without ask: installs, training, access, learning, upgrades, tools, abilities, Desktop four-tool production crossing apply, typed Maintenance/Supervisor packages (selector v1.2 + Superv v1.8.9), Forge M1, budget-unlock, skill proves, teach-and-transfer, free/safe north-star software. **Still ask:** RED zone, purchasing, trading. No inventing Windows password; no publishing secrets. Supersedes day-build/overnight ask-loops for green/yellow; does not remove safety invariants. Canonical card: `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`.


## 2026-09-04 Grok engineering shift directive

Grok is authorized by Matt to take the engineering reins for several hours and push Kevin hard within the existing bounded authority model. Work from fresh HESS-PC evidence, not assumptions. Repair first, then build, then prove. Do not create a second handover/status narrative.

**Mandatory continuity rule:** every direct HESS-PC change Grok makes must be mapped back into durable Kevin evidence so the next engineer can reconstruct exactly what happened. `AI-HANDOVER.md` remains the one canonical human handover; update its source inputs/evidence rather than creating `GROK-HANDOVER`, `SHIFT-NOTES`, or another competing current-status file.

For each direct HESS-PC change, record enough evidence to reconstruct and reverse it:

- local timestamp in America/Boise and actor;
- mission/component and owner value;
- exact local file path, service, scheduled task, config, plugin or application touched;
- before state/version/hash where available;
- exact change/action performed, with secrets/credentials redacted;
- after state/version/hash where available;
- test performed and actual observed postcondition;
- rollback/backout method and backup/checkpoint location;
- repository parity path/commit/PR when the local change has a source counterpart, or an explicit reason it is intentionally local-only;
- remaining blocker/risk and next safe step.

A local production change that is not represented in durable evidence is **UNKNOWN on handback** and must not be treated as trusted merely because an AI says it happened. Repository/CI proof is not live-machine proof.

### Required end-of-shift reconciliation before Grok hands back

1. Refresh/publish Support and Engineering snapshots and verify their timestamps are current.
2. Re-run or verify fresh Benchmark **PASS 30/30, critical 0**.
3. Verify HQ truth/current-state gates and Pages deployment after any HQ change.
4. Report exact scheduler health, active workers, Supervisor selection, Skill Lab queue/proven count, and any live mission lease/checkpoint state.
5. Report the exact effective tool inventory visible to `fixed:main`; do not infer it from source files.
6. Reconcile every HESS-PC change against repository source and durable receipts; identify any drift explicitly.
7. Update this execution contract only for material priority/state changes and let the canonical handover generator reconcile `AI-HANDOVER.md`.
8. State the next safe engineering move and any item that still requires Matt/owner approval.

Never store secrets, tokens, passwords, seed phrases, API keys or private credentials in the repository or handover.

## Resolved / proven in the 2026-09-04 max repair pass

These are **not open blockers unless fresher machine evidence regresses them**:

1. **Benchmark baseline:** HESS-PC evidence remains PASS 30/30, critical 0.
2. **Engineering Relay intake:** root cause was contract mismatch. The live Relay reads only `inbox/engineering/request.json`; this is codified in `inbox/engineering/README.md` and canonical requests are being consumed successfully.
3. **Dealer Vehicle Recon:** composite skill is PROVEN and replayable through GREEN `create_spreadsheet` + `create_text`.
4. **Vehicle Diagnostic Research Pack:** composite skill completed successfully and is PROVEN/replayable. Fresh Engineering evidence raised the proven composite count to **11**.
5. **HQ source architecture:** production wrapper was reduced from six overlays to four; duplicate owner-refinement and decorative polling layers were retired/deleted; duplicate hidden handover UI was removed; service-worker cache generation was advanced; `docs/HQ-TRUTH-CONTRACT.md` defines source ownership, freshness and truthful WORKING/BLOCKED/IDLE semantics.
6. **HQ regression gate:** CI enforces the four-layer truth-first architecture, five owner views, mobile access, stale-evidence protection and no duplicate handover layer.
7. **Handover consolidation:** `README.md` and `KEVIN-START-HERE.md` are pointers, not competing status documents. `AI-HANDOVER.md` is the only human current handover; machine receipts remain evidence, not second narrative authorities.
8. **Production Crossing v2 candidate:** a YELLOW source-only contract and tests exist for exactly two protected future operations: install the four-tool Kevin Desktop v0.1 surface, and retire only the legacy `KevinNightForge` scheduled task. CI proves the candidate validator; it has ZERO production effect and grants no new authority.
9. **HQ cross-lane truth repair:** owner Command must count Skill Lab running/ready/blocked work in global state, not only Supervisor/dashboard workers. A fail-closed source repair + regression assertion was launched during this shift; Grok must verify the resulting HQ gate/Pages deployment before treating it as complete.

## Current P0 blockers Î“Ã¶Â£â”œâ”‚â•¬Ã´â”œâŒâ”¬â•â•¬Ã´â”œÃ§â”¬Ã‘ pursue in this order

### P0.1 — FIXED LIVE (2026-09-04): Desktop exact-4 on fixed:main (NOT owner-gated)

Desktop is **LIVE** on HESS-PC via PR #77. Effective inventory is exactly:

- kevin_system_status
- kevin_desktop_find_folder
- kevin_desktop_open_folder
- kevin_app_launch

Evidence: Benchmark 30/30 critical 0; openclaw.json after SHA256 4126AFE64EF809B9A4747D70B9868F0FAB94F554F213C88B0DA832FBF8C5E794; backup 
`reports/engineering/backups/p01-desktop-20260904-0809.

**Do not** treat Desktop as owner-gated or HOLD. **Do not** widen tools or rewrite Desktop/openclaw.json config.

### P0.2 Î“Ã¶Â£â”œâ”‚â•¬Ã´â”œâŒâ”¬â•â•¬Ã´â”œÃ§â”¬Ã‘ capability-aware work routing and Work Supply -> Supervisor

Integrate supplied owner demand into live selection without inventing work and without routing every task through an agent that lacks the needed tool. Dispatch to the qualified worker/lane or deterministic executor that owns the typed capability. Preserve completed occurrence history and bounded retry/cooldown.

### P0.3 — leases/checkpoints (library + live Superv/Skill Lab wire PASS 2026-09-04)

`WORKING` requires a live lease plus evidence-producing execution. Long jobs need checkpoint/resume and orphan recovery so real work survives restarts and can continue without fake busy status.

### P0.4 Î“Ã¶Â£â”œâ”‚â•¬Ã´â”œâŒâ”¬â•â•¬Ã´â”œÃ§â”¬Ã‘ authoritative evidence freshness

Prevent older telemetry writers from overwriting newer authoritative assessments. Separate controller telemetry from authoritative state where necessary and enforce monotonic/event-aware publication.

### P0.5 Î“Ã¶Â£â”œâ”‚â•¬Ã´â”œâŒâ”¬â•â•¬Ã´â”œÃ§â”¬Ã‘ global blocked-vs-idle truth

HQ and control-plane status must aggregate all relevant execution lanes. Supervisor `NO_ELIGIBLE_MISSION` is only Supervisor truth; it must not erase active/ready/blocked Skill Lab or other owner work. `TRUE IDLE` is valid only when no active execution, eligible owner work, blocked owner backlog, or due maintenance/growth work exists across the governed system.

### P0.6 Î“Ã¶Â£â”œâ”‚â•¬Ã´â”œâŒâ”¬â•â•¬Ã´â”œÃ§â”¬Ã‘ continuous-growth live crossing

After tool routing/supply/leases are healthy, install/enable recurring self-heal, self-maintenance, blocked-work recovery, knowledge-integrity, capability-growth and owner-value scans through already-qualified scheduling/control surfaces. Prove multiple scheduled windows with real leases/checkpoints and no false WORKING state.

### P0.7 Î“Ã¶Â£â”œâ”‚â•¬Ã´â”œâŒâ”¬â•â•¬Ã´â”œÃ§â”¬Ã‘ exact retirement of legacy KevinNightForge

Do not delete/disable arbitrary scheduled tasks. Use the YELLOW Production Crossing v2 contract to design a live exact-target retirement wrapper for `KevinNightForge`: verify modern replacement schedulers first, disable-first observation, Benchmark 30/30, then remove only the exact legacy task with rollback proof.

## GREEN development lane

Keep growing useful replayable skills from already-PROVEN primitives. Prefer owner-value composites over synthetic activity. A skill becomes PROVEN only after semantic execution/replay evidence is registered.

Dealer Vehicle Recon and Vehicle Diagnostic Research are now proven. Next owner-value wave should prioritize:

1. Cache Valley Appliance Repair launch/readiness pack;
2. creator monetization/research pipeline;
3. home/garage organization pack;
4. crypto research/paper-trading pack with **no live trade authority**;
5. additional bounded dealership workflows that reduce Matt's real work friction.

## YELLOW development lane

YELLOW means build, test, simulate, harden and prepare protected production crossings without silently applying them. Every candidate must have exact scope, owner value, acceptance criteria, negative tests, rollback, bounded retries, evidence plan and explicit production authority boundary.

No candidate/CI/source artifact may be described as installed, available or autonomous production capability without fresh HESS-PC proof.

## Truth / authority invariants

- Fresh correlated HESS-PC evidence outranks checkpoint prose.
- Never report model turns, schedules, source code or CI alone as owner outcome proof.
- Never weaken permission, credential, financial, purchase, external-send, kill-switch or safety boundaries in order to move faster.
- Engineering Relay stays typed GREEN; no arbitrary shell/code.
- Protected production change requires the appropriate separately-qualified crossing plus owner/reviewer approval.
- Keep one outside AI writer on shared Kevin state at a time; Kevin's qualified local schedulers may continue normally.
- No direct HESS-PC change may disappear into chat history; record it with before/after evidence and rollback.

## Definition of progress

Count progress only when one of these occurs:

- a real defect is repaired and the independent postcondition passes;
- a blocked owner prerequisite is materially reduced;
- a reusable skill becomes semantically PROVEN;
- a YELLOW candidate closes a specific production-safety gap with tests/rollback and no unauthorized production effect;
- a truth/continuity defect is removed so future operators cannot be misled;
- a local production change is reconciled to durable evidence with tested postcondition and rollback.

Do not generate churn merely to look active.

## GREEN owner-value composite wave (2026-09-04 ~09:19-09:34 MT)

- tomorrow-field-work-command-pack@1 PROVEN @ 09:24:35 MT; proof `9DAD2E7920820A937FE84F5240FAF60902EA9CDA26A1D690B0FB41622402E5DC`; receipt `reports/engineering/RECEIPT-tomorrow-field-20260904-0924.md`
- equipment-tool-control-pack@1 PROVEN @ 09:32:35 MT; proof `327B135CE2FBDAFE3674E55DB441269FE72BEB01F7D72618A9FA72FF1E7BDA3A`; receipt `reports/engineering/RECEIPT-equipment-tool-20260904-0932.md`
- proven_count **18** (registry `reports/capabilities/composite-skills.json`)

## Continuity invariant

Do not weaken authority boundaries, evidence requirements, or rollback readiness while executing standing auth.
