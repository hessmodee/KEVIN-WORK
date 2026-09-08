# Kevin AI Engineering Handover — CANONICAL

> **THIS IS THE ONE CURRENT HANDOVER FOR KEVIN.** Do not create a competing dated handover. Update the source task/evidence and let the canonical handover refresh replace stale state.

**Semantic checkpoint evidence through:** 2026-09-08T11:17:53.1330414-06:00  
**Canonical repository:** `hessmodee/KEVIN-WORK` / `main`  
**Machine twin:** `reports/handoff-latest.json` (not a second authority)

## Universal access

Any replacement AI — ChatGPT, ChatGPT Work, Grok, Grok Build, Grokbot, Kevin, or another agent — should be given or should fetch **this exact file first**:

- GitHub: https://github.com/hessmodee/KEVIN-WORK/blob/main/AI-HANDOVER.md
- Raw text: https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/AI-HANDOVER.md
- Kevin HQ: https://hessmodee.github.io/KEVIN-WORK/handover.html

If an agent cannot access one route, use another. Matt should never need to reconstruct the build from chat history.

## Absolute continuity rules

1. `AI-HANDOVER.md` is the **only human current handover**. Do not create competing dated, agent-specific or parallel current-state handovers.
2. Fresh correlated HESS-PC/OpenClaw evidence outranks this checkpoint. Always inspect `reports/support-latest.json`, `reports/engineering/latest.json`, and applicable runtime/autonomy receipts after opening it.
3. Every AI must read `AI-HANDOVER.md` and `inbox/CURRENT_TASK.md` before substantive Kevin work.
4. Every material durable change must be committed/pushed to `hessmodee/KEVIN-WORK` or represented by a sanitized published runtime receipt before being called complete. **Local-only work is unfinished work.**
5. A desktop-local agent such as Grokbot may test locally, but it may not leave the only copy of source, configuration intent, repair logic or proof on HESS-PC.
6. Before editing shared state, re-read/pull current `main`; use a branch for source changes; reconcile before merge; never overwrite newer active work.
7. Checkpoint after every substantive proof transition or material repair, not only at the end of a conversation.
8. Never publish passwords, tokens, OAuth material, private message bodies, credentials, recovery codes or sensitive local data to this public repository.

## Automatic semantic snapshot

- Engineering evidence at checkpoint: `2026-09-08T11:17:53.1330414-06:00`
- Support evidence at checkpoint: `2026-09-08T11:03:34.5911970-06:00`
- Autonomy evidence at checkpoint: `2026-09-08T11:15:09.8906788-06:00`
- Benchmark: **PASS — 30/30, critical 0**
- UI Bridge health at checkpoint: **FRESH** (age then: 2.5 seconds)
- Maintenance: **ALREADY_APPLIED_PROVEN** — Maintenance previously proven.
- Supervisor last result: **NO_ELIGIBLE_MISSION**
- Proven composite skills: **27**
- Installed Maintenance identity reported by Support: `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24`

The builder runs after `main` changes and on a ten-minute reconciliation schedule, but it writes a new checkpoint only when turnover-relevant semantic state changes. Heartbeat timestamps alone do not move `main`. Incoming agents still read fresh runtime reports directly.

Do not interpret task/hash presence as health when a semantic heartbeat or round-trip proof is required.

## Current owner task / exact continuation

The block below is pulled from `inbox/CURRENT_TASK.md`. That file is an execution input, not a competing handover.

---

# CURRENT_TASK

**Updated:** 2026-09-08 11:16 MT  
**Status:** Core platform is operational and Benchmark is 30/30. The active program is **Extreme Autonomy Flywheel v3 execution**. Proven Skill Invocation v1 remains the production-skill milestone. Maintenance v1.3.52 **and Supervisor v1.8.11 are installed** on HESS-PC. The immediate gate is the first fresh owner outcome: invoke `west-motor-parts-chase-board-pack@1` on WorkInstance `owner-west-motor-parts-chase-fresh-8-v1`. A routing/stage receipt is not yet that outcome.

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

- Maintenance v1.3.52 is installed/proven. Support hashes workspace `kevin-maintenance-runner.ps1` as `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24`. Do not repeat the runner install.
- Supervisor **v1.8.11 is installed**. Support `2026-09-08T10:45:34-06:00` hashes workspace `kevin-supervisor.ps1` as `685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79`. Continuation `2026-09-08T10:46:10-06:00` publishes `version=1.8.11`. Typed Maintenance receipt for `grok-install-v1811-20260908-1625` is `ALREADY_APPLIED_PROVEN` / "Supervisor v1.8.11 and invocation worker applied/verified." That is independent install proof of the controller and worker, not an owner outcome.
- Support file hash and typed apply receipt are different signals. Both now agree on v1.3.52 + v1.8.11.
- Fresh Benchmark remains PASS 30/30, critical 0 (Support/Engineering `2026-09-08T10:45:17-06:00`).
- All six canonical scheduler lanes are `last_status=ok`, `consecutive_errors=0`, including `kevin-maintenance-intake-v1`. An earlier intake error after the v1811 apply recovered. Live Maintenance slot is returned to a GREEN `run_main_agent_canary` so intake stops re-entering the proven v1811 install path.
- Support's legacy aggregate `cron.ok=false` still publishes `Config warnings:` on the machine. Do not treat that field as lane failure. Supervisor `NO_ELIGIBLE_MISSION` is lane-idle, not true idle, while the 8-vehicle job was held.
- UI Bridge heartbeat remains fresh (~2.7s).
- 27 composite skills are PROVEN; latest proven is `west-motor-parts-chase-board-pack@1`. Exact-five desktop policy remains intentional. The bottleneck was that proven skills were not callable. The invocation worker is now installed, so they are — after the first fresh invocation proves the path, bind other due owner-value jobs to existing PROVEN keys. Do not recreate those skills. Do not widen the worker allowlist until that first proof.
- Continuation last published `WAITING_ITEM_BUDGETS` with `history_skipped=1` while the 8-vehicle job was held `blocked=true` (1 burned turn at 09:31). That was hold-idle, not true idle.
- Engineering request `grok-flywheel-status-20260908-1625` was seen (`DUPLICATE_IGNORED` at `2026-09-08T10:45:39-06:00`). Fresh request `grok-flywheel-status-20260908-1652` is queued.
- WorkInstance `owner-west-motor-parts-chase-fresh-8-v1` is now OPEN/GREEN/`blocked=false` with fictional 8-vehicle inputs and `required_skill_key=west-motor-parts-chase-board-pack@1`. The existing 1 burned turn stays inside the typical 3-turn budget; do not reset history. Installed v1.8.11 must route it to the invocation worker, not tool-less `fixed:main`.

## Source-side this turn — not yet an owner outcome

- Unblocking the 8-vehicle job is not the workbook. PASS still requires a real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt.
- HQ / Command treat Supervisor hash `685B34F3…` or continuation `version=1.8.11` as invocation-runtime-installed. `ROUTED_TO_PROVEN_SKILL_INVOCATION` remains the routing receipt, not the owner outcome.
- Do not recreate already-PROVEN skills. Do not widen the invocation worker allowlist past `west-motor-parts-chase-board-pack@1` until this first fresh invocation proves the path.
- Do not expand desktop tools. Exact-five remains the production tool surface.

## Immediate execution gates

## Highest-priority execution sequence

The highest-priority execution sequence, and the current live platform repair targets, are:

### 1. Proven Skill Invocation v1 — first fresh 8-vehicle owner outcome — NOW

Supervisor v1.8.11 must independently select `owner-west-motor-parts-chase-fresh-8-v1` and invoke `west-motor-parts-chase-board-pack@1` on the already-bound fictional 8-vehicle dataset.

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

- Repeat Maintenance v1.3.51 / v1.3.52 runner installation or Supervisor v1.8.11 installation.
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

---

## Cross-AI local-work convergence contract

The shared GitHub repository is the rendezvous point between agents that can see different environments. Local runtime and GitHub source are two different truth planes:

- **Repository/source truth:** reviewed source, procedures, current task, PR/CI, public-safe receipts.
- **HESS-PC runtime truth:** installed hashes, scheduled tasks, live heartbeats, configuration state, UI outcomes and other machine-local evidence.

No agent may silently treat one plane as the other. When Grokbot changes HESS-PC, it must publish the corresponding source/evidence checkpoint. When a remote agent changes GitHub, it must not claim the production machine changed until HESS-PC independently reports the installed result.

## Incoming-agent bootstrap

1. Read this file.
2. Read `KEVIN-START-HERE.md`, root `AGENTS.md`, and `inbox/CURRENT_TASK.md`.
3. Read fresh `reports/support-latest.json` and `reports/engineering/latest.json`; inspect relevant open PR/CI.
4. Compare timestamps, hashes, proof levels and in-flight requests. Treat stale prose as stale.
5. Continue the highest-value safe next action; do not restart the project or ask Matt to relay information already present in shared state.
6. After a substantive change, publish the execution input/evidence so the automatic handover can produce the next semantic checkpoint.

## Proof and authority

Technical proof ladder:

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

Responsibility transfer:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

Never infer a higher state from a lower one. Never widen authority merely to make turnover easier.

## Generator integrity

This handover is generated by `.github/scripts/build-canonical-handover.py` and refreshed by `.github/workflows/canonical-handover.yml`.

Semantic fingerprint: `9716E2A11E8F7EFDA5A4CE1E3A0877F64867D1D031925AC05EB03AB65BAC393A`

**Fresh runtime evidence first; one handover; publish every durable local change; then continue.**
