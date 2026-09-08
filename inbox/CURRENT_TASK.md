# CURRENT_TASK

**Updated:** 2026-09-08 14:35 MT  
**Status:** Core platform is operational and Benchmark is 30/30. The active program is **Extreme Autonomy Flywheel v3 execution**. Proven Skill Invocation v1 remains the production-skill milestone. Maintenance v1.3.52 **and Supervisor v1.8.11 are installed** on HESS-PC. Installed v1.8.11 then **crashed the scheduler** (`CONTROLLER_ERROR`, `consecutive_errors=7`) when it tried to invoke the worker. Supervisor v1.8.12 + Maintenance v1.3.53 source is on `main` (PR 163). The immediate gate is the typed `replace_pinned_component` of the Maintenance runner so HESS-PC can then run `install_autonomy_controller_v1812`. Queueing is not installation. The owner outcome is still the first fresh invoke of `west-motor-parts-chase-board-pack@1` on WorkInstance `owner-west-motor-parts-chase-fresh-8-v1`.

Fresh correlated HESS-PC runtime evidence outranks prose. Canonical handover remains `AI-HANDOVER.md`. Local/free Ollama remains the default unless a task-specific eval proves a different model is needed. Exact-five desktop policy remains intentional. Do not reset continuation history, work items, mission leases, Forge history, qualification history, or failure evidence.

**Architecture:** `docs/engineering/KEVIN-AUTONOMY-EXECUTION-PLAN-v3.md`  
**Current production-skill milestone:** `docs/engineering/KEVIN-PROVEN-SKILL-INVOCATION-v1.md`  
**Current typed crossing:** `docs/engineering/KEVIN-MAINTENANCE-V1353-SUPERVISOR-V1812.md` (source on `main`, runner install queued). Installed crossing remains `docs/engineering/KEVIN-MAINTENANCE-V1352-SUPERVISOR-V1811.md`.

## Owner strategic directive - maximum bounded autonomy

Kevin shall continuously reduce dependence on Bess, Grok Build/GrokBot, or another outside engineer for routine diagnosis, repair, coding, research, skill construction and execution.

Permanent loop:

`SENSE -> REFLECT -> SELECT -> PLAN -> RESOLVE CAPABILITY -> ACT -> VERIFY -> LEARN -> RESUME`

Every outside-engineer intervention should leave behind a Kevin-owned diagnostic, test, failure-family entry, repair recipe, reusable skill, invocation path or automation so the same intervention class trends toward zero.

Standing growth doctrine: **Self-heal. Self-maintain. Self-improve. Resume the owner objective.** Do not weaken truth, safety, authority, rollback, independent verification, idempotency or evidence requirements to create activity.

Target maturity is **T4 for routine bounded work**: Kevin detects the need, resolves/builds the capability, completes and verifies the owner outcome, learns from it, resumes interrupted work and continues without outside engineering. T4 does not mean unrestricted authority.

## Current live platform truth

- Maintenance v1.3.52 is installed/proven. Support hashes workspace `kevin-maintenance-runner.ps1` as `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24`. Do not repeat the v1.3.52 runner install. v1.3.53 source is on `main` (PR 163). The queued GREEN crossing is `replace_pinned_component` / `maintenance_runner` id `grok-install-maint-v1353-20260908-2035`. Queueing is not installation.
- Supervisor **v1.8.11 is installed**. Support hashes workspace `kevin-supervisor.ps1` as `685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79`. Continuation `2026-09-08T13:30:23-06:00` publishes `version=1.8.11` **and `status=CONTROLLER_ERROR`** `failure_sha256=5DD94CED5A2AFB4AF3A0A9521DC8F9306236B23B01882C52A80E482AE00BE37F`. That is a scheduler crash, not idle, not an owner outcome.
- Engineering `2026-09-08T13:55:56-06:00` reports `kevin-supervisor-v1` `last_status=error` `consecutive_errors=7`. The other five lanes are `ok`. UI Bridge heartbeat remains fresh (~2.4s).
- Cause: v1.8.11 invokes the worker with `$ErrorActionPreference='Stop'` and `& powershell @workerArgs 2>&1`. Worker stderr/`throw` becomes a terminating NativeCommandError. The catch publishes `CONTROLLER_ERROR` and rethrows.
- Source repair is on `main` (PR 163, not installed): Supervisor v1.8.12 `F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB` wraps that invoke with Continue + try/catch and maps failure to `BLOCKED_INVOCATION_RUNTIME` without crashing the scheduler. Maintenance v1.3.53 `EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50` adds `install_autonomy_controller_v1812`. Worker pin `16C49542…` is unchanged.
- Fresh Benchmark remains PASS 30/30, critical 0 (Engineering `2026-09-08T13:48:19-06:00`).
- Support's legacy aggregate `cron.ok=false` still publishes `Config warnings:` on the machine. Do not treat that field as lane failure. Supervisor `NO_ELIGIBLE_MISSION` in Support's stale cycle field is not the live continuation.
- 27 composite skills are PROVEN; latest proven is `west-motor-parts-chase-board-pack@1`. Exact-five desktop policy remains intentional. Do not recreate those skills. Do not widen the worker allowlist until the first proof.
- WorkInstance `owner-west-motor-parts-chase-fresh-8-v1` is OPEN/GREEN/`blocked=false` with fictional 8-vehicle inputs and `required_skill_key=west-motor-parts-chase-board-pack@1`. The existing 1 burned turn at 09:31 stays inside the typical 3-turn budget; do not reset history. Do not send it to tool-less `fixed:main`.
- Stale GitHub Action "Supervisor v1.8.2 Default-Agent Proof" failed on the PR 160 squash because `inbox/autonomy/work-items.json` was in that obsolete workflow's path filter. That email is not a production supervisor failure. This turn unhooks that path.
- Engineering request `grok-flywheel-status-20260908-1652` is `DUPLICATE_IGNORED`. Do not invent a new Relay verb. A fresh `action_status` needs a new id after this source lands.
- Live Maintenance slot is GREEN `replace_pinned_component` / `maintenance_runner` `grok-install-maint-v1353-20260908-2035`. Do **not** queue `install_autonomy_controller_v1812` until Support hashes the runner `EF32D990…` and a typed apply receipt exists.

## Source-side this turn — not yet an owner outcome

- Landing Supervisor v1.8.12 source is not HESS-PC installation and not the workbook. PASS still requires a real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt.
- HQ / Command treat Supervisor hash `685B34F3…` or continuation `version=1.8.11` as invocation-runtime-installed, and must also label `CONTROLLER_ERROR` as a scheduler crash rather than ready/idle. `ROUTED_TO_PROVEN_SKILL_INVOCATION` remains the routing receipt, not the owner outcome. `BLOCKED_INVOCATION_RUNTIME` after v1.8.12 is fail-closed diagnostic, not PASS.
- Do not recreate already-PROVEN skills. Do not widen the invocation worker allowlist past `west-motor-parts-chase-board-pack@1` until this first fresh invocation proves the path.
- Do not expand desktop tools. Exact-five remains the production tool surface.
- Queueing the v1.3.53 runner install is not HESS-PC proof. Install fetches from `main`. Do not queue `install_autonomy_controller_v1812` in this PR.

## Immediate execution gates

## Highest-priority execution sequence

The highest-priority execution sequence, and the current live platform repair targets, are:

### 1. Proven Skill Invocation v1 — first fresh 8-vehicle owner outcome — NOW

Supervisor v1.8.11 selected the unblocked WorkInstance and then crashed (`CONTROLLER_ERROR`) instead of fail-closing. Source Supervisor v1.8.12 must be installed so the worker native error becomes `BLOCKED_INVOCATION_RUNTIME` or a routing receipt. Then v1.8.12 must independently select `owner-west-motor-parts-chase-fresh-8-v1` and invoke `west-motor-parts-chase-board-pack@1` on the already-bound fictional 8-vehicle dataset.

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

- Repeat Maintenance v1.3.51 / v1.3.52 runner installation or Supervisor v1.8.11 installation. v1.3.53 runner install is queued this turn; v1.8.12 install waits for the runner hash.
- Reset histories or work budgets.
- Recreate already-PROVEN skills.
- Retry disproven Forge migration work.
- Invent new Engineering Relay verbs.
- Claim HESS-PC installation from a GitHub source change.
- Treat a queued request, CI pass, HQ label, routing receipt, or model turn as an owner outcome.
- Send `owner-west-motor-parts-chase-fresh-8-v1` to tool-less `fixed:main`.
- Widen desktop tools past the exact-five policy.
- Truncate this file. The growth panel and the next agent both need the headings below.

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

Pizza orders, Amazon checkout, voice calls, and public posting remain Delegated Yellow. The bottleneck is not the GREEN/YELLOW line. The bottleneck was that proven skills were not callable; that runtime is now installed. First owner outcome still has to be independently proven.

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
