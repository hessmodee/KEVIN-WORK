# CURRENT_TASK

**Updated:** 2026-09-08 09:40 MT  
**Status:** Core platform is operational and Benchmark is 30/30. The active program is **Extreme Autonomy Flywheel v3 execution**. Proven Skill Invocation v1 and Supervisor v1.8.11 remain source-only. The immediate gate is the typed Maintenance v1.3.52 crossing so HESS-PC can install Supervisor v1.8.11 plus `kevin_proven_skill_invoke`. GitHub source is not machine proof.

Fresh correlated HESS-PC runtime evidence outranks prose. Canonical handover remains `AI-HANDOVER.md`. Local/free Ollama remains the default unless a task-specific eval proves a different model is needed. Exact-five desktop policy remains intentional. Do not reset continuation history, work items, mission leases, Forge history, qualification history, or failure evidence.

**Architecture:** `docs/engineering/KEVIN-AUTONOMY-EXECUTION-PLAN-v3.md`  
**Current production-skill milestone:** `docs/engineering/KEVIN-PROVEN-SKILL-INVOCATION-v1.md`  
**Current typed crossing:** `docs/engineering/KEVIN-MAINTENANCE-V1352-SUPERVISOR-V1811.md`

## Owner strategic directive - maximum bounded autonomy

Kevin shall continuously reduce dependence on Bess, Grok Build/GrokBot, or another outside engineer for routine diagnosis, repair, coding, research, skill construction and execution.

Permanent loop:

`SENSE -> REFLECT -> SELECT -> PLAN -> RESOLVE CAPABILITY -> ACT -> VERIFY -> LEARN -> RESUME`

Every outside-engineer intervention should leave behind a Kevin-owned diagnostic, test, failure-family entry, repair recipe, reusable skill, invocation path or automation so the same intervention class trends toward zero.

Standing growth doctrine: **Self-heal. Self-maintain. Self-improve. Resume the owner objective.** Do not weaken truth, safety, authority, rollback, independent verification, idempotency or evidence requirements to create activity.

Target maturity is **T4 for routine bounded work**: Kevin detects the need, resolves/builds the capability, completes and verifies the owner outcome, learns from it, resumes interrupted work and continues without outside engineering. T4 does not mean unrestricted authority.

## Current live platform truth

- Maintenance v1.3.51 is already installed/proven on HESS-PC. Support reports installed Maintenance hash `2D7F65C97A2934E7C34FEFF86BD317E84D0E73D6CABD9AC1D99DF0FF32448EAD` and status `ALREADY_APPLIED_PROVEN`. Do not repeat the retired v1.3.50 -> v1.3.51 installation mission.
- Supervisor **installed** identity remains v1.8.10 / hash `BDA265ACCB929EC5129B2F38AC76FE276625A604052304FC32C917700BCB532E`. Supervisor **v1.8.11 is source-only** until Maintenance v1.3.52 is installed and `install_autonomy_controller_v1811` independently proves the crossing.
- Fresh Benchmark remains PASS 30/30, critical 0 (Engineering 2026-09-08T09:27:44-06:00).
- Fresh Engineering telemetry reports the six canonical scheduler lanes enabled, `last_status=ok`, `consecutive_errors=0`.
- Support's legacy aggregate `cron.ok=false` still publishes `Config warnings:` on the machine. Source now separates that warning from scheduler health (`kevin-support-cron-truth-v1.py` + HQ adapter). Do not treat the Support field as lane failure, and do not claim the HESS-PC Support publisher is repaired until a fresh snapshot proves it.
- UI Bridge heartbeat remains fresh in current Engineering evidence.
- 27 composite skills are PROVEN; latest proven is `west-motor-parts-chase-board-pack@1`.
- Supervisor last published result remains `NO_ELIGIBLE_MISSION` / continuation `WAITING_ITEM_BUDGETS`. That is Supervisor-lane idle, not global true idle.
- Engineering request `grok-flywheel-status-20260908-1505` was seen (`DUPLICATE_IGNORED` on the latest snapshot). A processed `action_status` is observation, not invocation proof.
- Live Maintenance manifest remains `run_main_agent_canary` `matt-fresh-main-canary-20260908-0716`. Do not replace it with v1811 while v1.3.51 is the installed runner.
- WorkInstance `owner-west-motor-parts-chase-fresh-8-v1` is OPEN/GREEN with fictional 8-vehicle inputs, held `blocked=true` so installed v1.8.10 cannot charge tool-less `fixed:main`. Unblock only after invocation runtime is independently effective.

## Source-side this turn — not yet HESS-PC proven

- Maintenance v1.3.52 is a thin v1.3.51 wrapper that adds only `install_autonomy_controller_v1811`. It pins Supervisor `BDA265AC…` -> `685B34F3…`, copies the canonical invocation worker `16C49542…`, and preserves Benchmark 30/30 / histories.
- Ladder: merge this source -> `replace_pinned_component` maintenance_runner 1.3.51 -> 1.3.52 -> then `install_autonomy_controller_v1811`. Do not skip a rung.
- Supervisor v1.8.11 routes exact `required_skill_key` to the invocation worker before Skill Lab / fixed:main, and publishes `BLOCKED_INVOCATION_RUNTIME` instead of fake idle when the worker is missing.
- HQ no longer treats Support `cron.ok=false` warning-only parses as scheduler failure, and treats skill-bound work as BLOCKED until invocation runtime is independently effective.

## Immediate execution gates

## Highest-priority execution sequence

The highest-priority execution sequence, and the current live platform repair targets, are:

### 1. Typed Maintenance v1.3.52 then HESS-PC Proven Skill Invocation runtime qualification — NOW

Land Maintenance v1.3.52 on `main`, install that runner through `replace_pinned_component`, then run `install_autonomy_controller_v1811`. Prove the typed runtime capability `kevin_proven_skill_invoke` is independently effective on HESS-PC. Source CI is not machine proof. Qualification must show the runtime worker consumes the staged GREEN work orders, uses only the invocation allowlist, and publishes correlated DONE/FAILED evidence.

### 2. First fresh production-skill acceptance test — NEXT

Unblock and invoke `west-motor-parts-chase-board-pack@1` using the already-bound fictional 8-vehicle dataset on WorkInstance `owner-west-motor-parts-chase-fresh-8-v1`.

Required output fields: priority, stock number, part/need, vendor/source, ordered date, ETA, blocker, owner, next action, completion state.

PASS requires a real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt. No customer PII, credentials, purchases, public posting or live financial effects.

### 3. Capability-aware Supervisor execution — NEXT

A due WorkInstance with an exact PROVEN skill requirement must be selected and routed automatically through the invocation lane. Supervisor must not treat lane-local idle as global idle when invocation-ready or Skill-Lab-ready work exists.

Resolution order:

1. existing PROVEN skill -> invoke;
2. reviewed primitive composition;
3. missing capability -> research/build -> Skill Lab;
4. authority-blocked -> smallest scoped owner grant;
5. true impossibility -> evidence-bearing escalation.

### 4. Structural renewable work

Recurring responsibilities create distinct due WorkInstances. Historical completions remain proof and do not permanently consume a standing responsibility.

Never solve `WAITING_ITEM_BUDGETS` by deleting or resetting valid history.

### 5. Incident/Reflection automatic resume

Every incident carries the interrupted WorkInstance/objective identity. After independently proven repair, automatically return that objective to eligible execution. A repair that forgets the original objective is incomplete.

### 6. Missing-capability acquisition loop

`gap -> research -> candidate -> isolated build -> positive/negative/regression tests -> Skill Lab -> proof -> registry -> invocation -> resume original objective`

This loop is the primary mechanism for reducing Bess/Grok intervention over time.

## Do not

- Repeat Maintenance v1.3.51 installation.
- Queue `install_autonomy_controller_v1811` while v1.3.51 is still the installed runner.
- Reset histories or work budgets.
- Recreate already-PROVEN skills.
- Retry disproven Forge migration work.
- Invent new Engineering Relay verbs.
- Claim HESS-PC installation from this GitHub source change.
- Treat a queued request, CI pass, or HQ label as an owner outcome.
- Unblock `owner-west-motor-parts-chase-fresh-8-v1` in front of installed v1.8.10.

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

Pizza orders, Amazon checkout, voice calls, and public posting remain Delegated Yellow. The bottleneck is not the GREEN/YELLOW line. The bottleneck is that proven skills are not yet callable on HESS-PC.

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
