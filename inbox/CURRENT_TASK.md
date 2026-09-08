# CURRENT_TASK

> **LAYER / READER / DAILY LOOP:** Do not replace or truncate this file. Write `reports/STATUS.md` and `reports/daily-YYYY-MM-DD.md` only. This file is the Extreme Autonomy Flywheel execution contract.

**Updated:** 2026-09-08 15:10 MT  
**Status:** Core platform is operational and Benchmark is 30/30. The active program is **Extreme Autonomy Flywheel v3 execution**. Proven Skill Invocation v1 remains the production-skill milestone. Maintenance v1.3.53 **is installed** (Support hash `EF32D990…`). Supervisor **v1.8.12 is on disk** (Support hash `F17F4B0A…` at 15:03:37). The typed apply receipt is **not** published: Maintenance status `ERROR` / "The property 'idempotent' cannot be found on this object." Continuation is still `version=1.8.11` `CONTROLLER_ERROR` from 14:30 — that is stale versus the file hash, not a live v1.8.12 crash. Keep `install_autonomy_controller_v1812` queued so the already-applied path can publish `ALREADY_APPLIED_PROVEN`. The owner outcome is still the first fresh invoke of `west-motor-parts-chase-board-pack@1` on WorkInstance `owner-west-motor-parts-chase-fresh-8-v1`.

Fresh correlated HESS-PC runtime evidence outranks prose. Canonical handover remains `AI-HANDOVER.md`. Local/free Ollama remains the default unless a task-specific eval proves a different model is needed. Exact-five desktop policy remains intentional. Do not reset continuation history, work items, mission leases, Forge history, qualification history, or failure evidence.

**Architecture:** `docs/engineering/KEVIN-AUTONOMY-EXECUTION-PLAN-v3.md`  
**Current production-skill milestone:** `docs/engineering/KEVIN-PROVEN-SKILL-INVOCATION-v1.md`  
**Current typed crossing:** `docs/engineering/KEVIN-MAINTENANCE-V1353-SUPERVISOR-V1812.md` (runner installed; v1.8.12 file hash live; typed receipt pending). Source prevention: `docs/engineering/KEVIN-MAINTENANCE-V1354-IDEMPOTENT-RECEIPT.md` (do not install v1.3.54 in front of the v1812 receipt).

## Owner strategic directive - maximum bounded autonomy

Kevin shall continuously reduce dependence on Bess, Grok Build/GrokBot, or another outside engineer for routine diagnosis, repair, coding, research, skill construction and execution.

Permanent loop:

`SENSE -> REFLECT -> SELECT -> PLAN -> RESOLVE CAPABILITY -> ACT -> VERIFY -> LEARN -> RESUME`

Every outside-engineer intervention should leave behind a Kevin-owned diagnostic, test, failure-family entry, repair recipe, reusable skill, invocation path or automation so the same intervention class trends toward zero.

Standing growth doctrine: **Self-heal. Self-maintain. Self-improve. Resume the owner objective.** Do not weaken truth, safety, authority, rollback, independent verification, idempotency or evidence requirements to create activity.

Target maturity is **T4 for routine bounded work**: Kevin detects the need, resolves/builds the capability, completes and verifies the owner outcome, learns from it, resumes interrupted work and continues without outside engineering. T4 does not mean unrestricted authority.

## Current live platform truth

- Maintenance v1.3.53 is installed/proven. Support `2026-09-08T15:03:37-06:00` hashes workspace `kevin-maintenance-runner.ps1` as `EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50`. Do not repeat the v1.3.53 runner install.
- Supervisor **file identity is v1.8.12**. Support hashes workspace `kevin-supervisor.ps1` as `F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB`. File hash is identity, not a typed apply receipt.
- Maintenance latest at 15:03:23 is `ERROR` / "The property 'idempotent' cannot be found on this object. Verify that the property exists." Failure family: v1.3.53 `Set-StrictMode -Version 2.0` plus first-apply `return [ordered]@{changed=$true;...}` with **no `idempotent` key**, then `$status=if([bool]$result.idempotent)`. The copy/selftest/Benchmark completed; the publisher crashed. The inner install catch did **not** roll the files back.
- Next cycle of the same queued id should take the already-applied path (`idempotent=$true`) and can publish `ALREADY_APPLIED_PROVEN` without a runner replacement. Keep `install_autonomy_controller_v1812` id `grok-install-v1812-20260908-2050` in the live slot. Do **not** replace it with `replace_pinned_component` for v1.3.54 until that receipt exists.
- Continuation `2026-09-08T14:30:27-06:00` still publishes `version=1.8.11` `status=CONTROLLER_ERROR` `failure_sha256=5DD94CED…`. That snapshot **predates** the 15:03 file hash. Do not treat it as a live v1.8.12 scheduler crash.
- Engineering `2026-09-08T15:05:57-06:00` still reports `kevin-supervisor-v1` `last_status=error` `consecutive_errors=8` and request `grok-flywheel-status-20260908-2050` `DUPLICATE_IGNORED`. The other five lanes are `ok`. UI Bridge heartbeat remains fresh (~3.9s). This turn queues a new `action_status` id `grok-flywheel-status-20260908-2110`.
- Cause of the 14:30 crash (now repaired on disk): v1.8.11 invoked the worker with `$ErrorActionPreference='Stop'` and `& powershell @workerArgs 2>&1`. Worker stderr/`throw` became a terminating NativeCommandError. v1.8.12 wraps that invoke with Continue + try/catch and maps failure to `BLOCKED_INVOCATION_RUNTIME` without crashing the scheduler. Worker pin `16C49542…` is unchanged.
- Fresh Benchmark remains PASS 30/30, critical 0 (Engineering `2026-09-08T15:04:29-06:00`).
- Support's legacy aggregate `cron.ok=false` still publishes `Config warnings:` on the machine. Do not treat that field as lane failure. Supervisor `NO_ELIGIBLE_MISSION` in Support's stale cycle field is not the live continuation.
- 27 composite skills are PROVEN; latest proven is `west-motor-parts-chase-board-pack@1`. Exact-five desktop policy remains intentional. Do not recreate those skills. Do not widen the worker allowlist until the first proof.
- WorkInstance `owner-west-motor-parts-chase-fresh-8-v1` is OPEN/GREEN/`blocked=false` with fictional 8-vehicle inputs and `required_skill_key=west-motor-parts-chase-board-pack@1`. The existing 1 burned turn at 09:31 stays inside the typical 3-turn budget; do not reset history. Do not send it to tool-less `fixed:main`.
- A workspace-reader/daily layer truncated this file at 15:05 MT into a one-layer "Stop." note. That is not the flywheel contract. Restored this turn. Layer agents must not write `inbox/CURRENT_TASK.md`.
- Live Maintenance slot remains GREEN `install_autonomy_controller_v1812` `grok-install-v1812-20260908-2050`. Do **not** repeat `replace_pinned_component` for the v1.3.53 runner.

## Source-side this turn — not yet an owner outcome

- Support hash `F17F4B0A…` is **not** `ALREADY_APPLIED_PROVEN` / "Supervisor v1.8.12 worker-native fail-closed applied/verified." PASS still requires a real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt.
- HQ / Command treat Support runner hash `EF32D990…` as v1.3.53 installed, Supervisor hash `F17F4B0A…` as v1.8.12 **file identity**, and must label 14:30 `CONTROLLER_ERROR` as stale versus that identity. Maintenance ERROR mentioning `idempotent` is the receipt-publisher defect, not a rollback. `ROUTED_TO_PROVEN_SKILL_INVOCATION` remains the routing receipt, not the owner outcome. `BLOCKED_INVOCATION_RUNTIME` after a fresh v1.8.12 continuation is fail-closed diagnostic, not PASS.
- Maintenance v1.3.54 source is the failure-family repair (StrictMode-safe `Get-InstallStatus` + `idempotent=$false` on first apply). Queueing or merging v1.3.54 is not HESS-PC installation. Do not install it in front of the v1812 typed receipt.
- Do not recreate already-PROVEN skills. Do not widen the invocation worker allowlist past `west-motor-parts-chase-board-pack@1` until this first fresh invocation proves the path.
- Do not expand desktop tools. Exact-five remains the production tool surface.

## Immediate execution gates


## Highest-priority execution sequence

The highest-priority execution sequence, and the current live platform repair targets, are:

### 1. Proven Skill Invocation v1 — first fresh 8-vehicle owner outcome — NOW

Supervisor v1.8.12 is on disk (`F17F4B0A…`). The remaining machine proof for this rung is a typed apply receipt (`ALREADY_APPLIED_PROVEN` or `APPLIED_PREAUTHORIZED_PROVEN`) plus a fresh continuation `version=1.8.12` that is not the 14:30 crash snapshot. Keep `install_autonomy_controller_v1812` queued. After that receipt, Supervisor must select `owner-west-motor-parts-chase-fresh-8-v1` and invoke `west-motor-parts-chase-board-pack@1` on the already-bound fictional 8-vehicle dataset.

Required output fields: priority, stock number, part/need, vendor/source, ordered date, ETA, blocker, owner, next action, completion state.

PASS requires a real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt. No customer PII, credentials, purchases, public posting or live financial effects. A model turn, a queue write, CI, or HQ label is not PASS.

### 2. Capability-aware Supervisor execution — NEXT

A due WorkInstance with an exact PROVEN skill requirement must be selected and routed automatically through the invocation lane. Supervisor must not treat lane-local idle as global idle when invocation-ready or Skill-Lab-ready work exists.

Resolution order:

1. existing PROVEN skill -> invoke;
2. reviewed primitive composition;
3. missing capability -> research/build -> Skill Lab;
4. authority-blocked -> smallest scoped owner grant;
5. true impossibility -> evidence-bearing escalation.

### 3. Repeatable invocation of the existing 27 PROVEN skills — NEXT

After the first fresh invocation is independently proven, bind other due owner-value WorkInstances to exact existing PROVEN skill keys. Do not recreate those skills. Do not invent new Engineering Relay verbs. Do not widen the worker allowlist in front of the first PASS.

### 4. Structural renewable work

Recurring responsibilities create distinct due WorkInstances. Historical completions remain proof and do not permanently consume a standing responsibility.

Never solve `WAITING_ITEM_BUDGETS` by deleting or resetting valid history.

### 5. Incident/Reflection automatic resume

Every incident carries the interrupted WorkInstance/objective identity. After independently proven repair, automatically return that objective to eligible execution. A repair that forgets the original objective is incomplete.

### 6. Missing-capability acquisition loop

`gap -> research -> candidate -> isolated build -> positive/negative/regression tests -> Skill Lab -> proof -> registry -> invocation -> resume original objective`

This loop is the primary mechanism for reducing Bess/Grok intervention over time.

## Do not

- Repeat Maintenance v1.3.51 / v1.3.52 / v1.3.53 runner installation or Supervisor v1.8.11 installation. v1.8.12 **file hash is live**; wait for the typed apply receipt, not another copy.
- Queue `replace_pinned_component` for Maintenance v1.3.54 in front of the v1812 typed receipt.
- Treat Support supervisor hash `F17F4B0A…` as `ALREADY_APPLIED_PROVEN`.
- Treat continuation `CONTROLLER_ERROR` from 14:30 as a live v1.8.12 crash.
- Reset histories or work budgets.
- Recreate already-PROVEN skills.
- Retry disproven Forge migration work.
- Invent new Engineering Relay verbs.
- Claim HESS-PC installation from a GitHub source change.
- Treat a queued request, CI pass, HQ label, routing receipt, or model turn as an owner outcome.
- Send `owner-west-motor-parts-chase-fresh-8-v1` to tool-less `fixed:main`.
- Widen desktop tools past the exact-five policy.
- Truncate this file. The growth panel and the next agent both need the headings below. Layer/reader/daily agents write `reports/STATUS.md` and `reports/daily-YYYY-MM-DD.md` only.

## Authority expansion policy

Expand autonomy primarily by broadening safe reversible work inside GREEN, not by erasing boundaries.

GREEN already covers this next leap: research, source, tests, Skill Lab, proven-skill invocation, reversible local artifacts, and self-repair. Do **not** solve the current idle by declaring Yellow work Green.

### GREEN-A - autonomous read/observe
Public web research, repo/files/log inspection, diagnostics, screenshots/snapshots of Kevin-owned surfaces, benchmarks and tests.

### GREEN-B - autonomous reversible local work
Approved roots/worktrees, code changes, tests, local artifacts, documents/spreadsheets, local prototypes, isolated dependency work, quarantine downloads, bounded subagents, Skill Lab staging/evaluation, backups and proven noncritical runbooks.

### GREEN-C - autonomous proven self-improvement
Known reversible repairs, regression tests, lessons/failure taxonomy, invocation of PROVEN skills, low-risk typed promotion through existing rollback/Benchmark gates and isolated candidate-skill construction.

### DELEGATED YELLOW - scoped consequential grants
Kevin may prepare autonomously. Execution requires a current narrowly scoped owner grant for external sends/calls/posts, account changes, system-wide/elevated installs, user-data changes outside approved roots, bookings, orders, checkout and purchases. Grants should be limited by action class, recipient/merchant/publisher, amount/scope, count/frequency, expiry, idempotency and receipt requirements.

Pizza orders, Amazon checkout, voice calls, and public posting remain Delegated Yellow. The bottleneck is not the GREEN/YELLOW line. The bottleneck was that proven skills were not callable; that runtime is now installed and then crashed. First owner outcome still has to be independently proven after the fail-closed wrap.

Never self-authorize arbitrary shell, credential access/exfiltration, safety/audit weakening, unbounded financial authority, automatic permission expansion or judge/benchmark weakening.

## Capability waves after the invocation/renewable-work core

1. **Self-reliance:** invocation, work supply, incident repair/resume, independent QA/reflection.
2. **Self-learning:** Kevin-originated procedures -> Skill Lab -> proof -> repeated fresh invocation.
3. **Web/computer fluency:** managed browser, Windows computer use, files/apps, reusable GUI composites, prompt-injection negative tests.
4. **Communications:** HQ direct chat/mobile, Telegram/email workflows, scoped voice calling.
5. **Apps/media/gaming:** autonomous app builds, image generation, qualified software downloads/installs, Minecraft player adapter and cooperative skills.
6. **Transactions/errands:** research/cart preparation in GREEN; checkout/order only under Delegated Yellow with duplicate-effect protection.

## Owner-value skill portfolio

1. Dealer Recon - parts chase, reconditioning, lot readiness, transport and vehicle research.
2. Vehicle Diagnostics - evidence-backed symptom/test/service-information/parts workflows.
3. Home & Garage - maintenance, inventory, garden and project workflows.
4. Appliance Repair - diagnostics, parts, market/pricing and owner-business workflows.
5. Creator/App Factory - research, drafts, software, images and QA loops.
6. Research Analyst - multi-source research, freshness, contradictions, provenance/confidence.
7. Computer Operator - browser/Windows routines and GUI composites.
8. Communications - HQ chat, Telegram/email, then scoped voice.
9. Gaming - Minecraft as long-horizon perception/planning/recovery/collaboration benchmark.
10. Errands/Commerce - GREEN research/preparation, Delegated-Yellow consequential execution.

## Required autonomy metrics

Track and trend:

- verified owner outcomes / 24h and / 7d;
- fresh PROVEN-skill invocations;
- distinct skills repeatedly proven on new inputs;
- self-repair success rate and median recovery time;
- Bess/Grok interventions / 7d;
- percentage of failures resolved without outside engineering;
- objectives automatically resumed after repair;
- autonomously selected work vs manually injected work;
- productive vs blocked/idle/churn time;
- GREEN vs Delegated-Yellow effects and why Yellow was needed;
- maturity T0-T4/T5 by capability lane.

## Stop / escalation rules

- Do not claim source CI as HESS-PC runtime proof.
- Do not claim a queue write or successful model turn as an owner outcome.
- Do not reset valid history/budgets simply to create eligible work.
- Do not manufacture Skill Lab/Forge churn to appear active.
- Do not hard-code a healthy display over stale/bad truth.
- Do not widen authority merely to pass a benchmark or produce activity.
- Do not let Kevin silently redefine the benchmark/verifier/authority/audit system that judges Kevin.
- For uncertain external effects, do not automatically retry without an idempotency/receipt decision.
- When technology is ready but authority is blocked, prepare everything possible and surface the smallest scoped Delegated-Yellow grant Matt would need to give.

## Continuation contract

After every substantive transition, publish source/evidence so the canonical handover can advance. Keep repository/source truth separate from HESS-PC runtime truth. Local-only changes are unfinished.
