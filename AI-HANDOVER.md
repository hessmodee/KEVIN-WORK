# Kevin AI Engineering Handover — CANONICAL

> **THIS IS THE ONE CURRENT HANDOVER FOR KEVIN.** Do not create a competing dated handover. Update the source task/evidence and let the canonical handover refresh replace stale state.

**Semantic checkpoint evidence through:** 2026-09-03T22:41:51.7686181-06:00  
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

- Engineering evidence at checkpoint: `2026-09-03T22:40:58.6587117-06:00`
- Support evidence at checkpoint: `2026-09-03T22:41:51.7686181-06:00`
- Autonomy evidence at checkpoint: `2026-09-03T22:37:42.8694406-06:00`
- Benchmark: **PASS — 30/30, critical 0**
- UI Bridge health at checkpoint: **FRESH** (age then: 4.9 seconds)
- Maintenance: **ALREADY_APPLIED_PROVEN** — Maintenance previously proven.
- Supervisor last result: **NO_ELIGIBLE_MISSION**
- Proven composite skills: **9**
- Installed Maintenance identity reported by Support: `DFF72850E1BBBB2E18397AF38EB593E7234EEB634B596A4651F4537A688B77A9`

The builder runs after `main` changes and on a ten-minute reconciliation schedule, but it writes a new checkpoint only when turnover-relevant semantic state changes. Heartbeat timestamps alone do not move `main`. Incoming agents still read fresh runtime reports directly.

Do not interpret task/hash presence as health when a semantic heartbeat or round-trip proof is required.

## Current owner task / exact continuation

The block below is pulled from `inbox/CURRENT_TASK.md`. That file is an execution input, not a competing handover.

---

# CURRENT_TASK

**Updated:** 2026-09-03 ~22:40 MT  
**Owner priority:** turn Kevin into a truthful, persistent, multi-worker local operator that produces useful owner outcomes every day, learns continuously, reduces repeated Matt/Bess intervention, and becomes capable enough to help Matt make money while preserving strict evidence and authority boundaries.

## P0 — current owner reality (supersedes stale construction assumptions)

Kevin must use the following as current owner context until Matt changes it:

- Matt currently works for **West Motor Co CDJR in Preston, Idaho** as a **Field Agent**.
- Current work emphasis is vehicle reconditioning / lot-readiness flow using **iRecon** and related dealership processes: inspect incoming vehicles, identify reconditioning needs, help move vehicles through service/detail/photos/readiness, track blockers, and make vehicles ready for the lot.
- Matt **no longer works for a construction company**. Construction-specific work is historical capability only and must not remain a default owner-work source.
- Matt enjoys **crypto trading**, **working on and diagnosing vehicles**, and **organizing the house / garage / tools / equipment**.
- Matt formed **Cache Valley Appliance Repair LLC**, but the business is not operationally mature yet. He currently has the LLC, but still needs training/competency planning, tools/equipment, service scope, pricing, parts/supplier workflow, insurance/licensing verification, customer intake, diagnostics procedures and a safe launch plan before representing himself as a fully equipped appliance technician.
- Matt wants Kevin to help build legitimate income opportunities, especially through **YouTube**, **X**, other creator/business channels, dealership productivity, the appliance-repair venture, and eventually **crypto trading support**.

Construction Daily Field Log and construction-centered Tomorrow Field Work work are therefore **deprioritized / legacy owner context**. Preserve the skills for possible future use, but do not select them merely to keep Kevin busy.

## P0 — value-first operating rule

Infrastructure is a means, not the finish line. Prioritize work in this order:

1. useful owner outcomes tied to Matt's current job, business, vehicles, creator income, household organization and crypto research;
2. blockers that directly prevent those outcomes;
3. capability learning that expands Kevin's real execution surface;
4. protective/recovery work that keeps useful capabilities dependable;
5. platform polish only when it materially improves the above.

Do not count model turns, cron cycles, heartbeats, hashes, CI, dashboards, animations or 'thinking' as accomplishments. A useful capability needs an executable path, real output/postcondition, machine evidence where applicable, independent verification, replay and a clear owner use case.

Permanent loop:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> LEARN -> CONTINUE`

Repeated Bess/Grok/Matt intervention is autonomy debt. When a recurring intervention can safely become a bounded Kevin detection/repair/verification responsibility, convert it into one.

## P0 — truth model: no fake work and no fake idleness

Kevin/HQ must distinguish:

- `WORKING`: an active mission lease exists and a real evidence-producing action is running.
- `ELIGIBLE_WORK`: owner-approved work exists and Kevin has the effective capability to begin it.
- `BLOCKED_WORK_PRESENT`: legitimate work exists but a prerequisite/tool/proof is missing.
- `TRUE_IDLE`: no eligible owner work, no blocked owner backlog and no due guardian/capability-learning work.

Unresolved owner work must never be presented as `TRUE_IDLE`. Conversely, Kevin must never display `WORKING` just to make the UI look alive.

## P0 — current live platform repair targets

Preserve the last proven platform baseline: Benchmark **PASS 30/30, critical 0** unless fresher HESS-PC evidence says otherwise.

Highest-value engineering blockers now are:

1. **Main-agent tool starvation.** Fresh full-autonomy evidence showed `fixed:main` with zero visible tools. Complete the already-reviewed bounded Kevin Desktop crossing and prove the exact effective tool inventory instead of letting main repeatedly reason without hands.
2. **Work Supply -> live Supervisor integration.** `control-plane/autonomy/kevin-work-supply-v1.py` and the standing supply catalog are merged and CI-proven, but live Supervisor still primarily consumes the static `inbox/autonomy/work-items.json`. Integrate truthful supplied demand before selection without granting new primitive authority.
3. **Capability-aware worker routing.** Stop forcing every selected mission through a main agent that may not own the required tool. Dispatch work to the qualified worker/lane that actually has the typed capability.
4. **Mission leases/checkpoints.** `WORKING` requires a live lease plus evidence-producing execution. Long jobs need checkpoints/resume so they can continue overnight rather than restart or disappear.
5. **Autonomy-report freshness race.** A fresh full-autonomy assessment was observed being overwritten by older telemetry. Older/staler writers must not replace newer authoritative evidence. Separate controller telemetry from authoritative assessment state if necessary.
6. **Blocked-vs-idle HQ truth.** HQ must expose blocked backlog count, top blocker, next safe prerequisite and eligible queue depth instead of collapsing all non-running states into 'NO ELIGIBLE WORK'.

## P0 — tonight's owner-value skill wave

Create/prove current-owner skills using existing GREEN primitives first, then graduate them to richer typed tools when those tools become qualified:

1. `dealer-vehicle-recon-command-pack@1` — iRecon-centered incoming vehicle/reconditioning/readiness tracker and morning queue.
2. `vehicle-diagnostic-research-pack@1` — VIN/vehicle/symptom -> structured diagnostic research checklist, likely causes, tests, tools/parts to verify and evidence; no unsafe automatic actuation.
3. `cache-valley-appliance-repair-launch-pack@1` — training/tooling/service-scope/startup readiness, pricing model, customer intake, parts/supplier plan and launch gates; never claim credentials Matt does not have.
4. `crypto-research-paper-trading-pack@1` — thesis, catalysts, entry/exit plan, position sizing model, invalidation, risk/reward, paper trade journal and post-trade review. **No live trade placement or financial transaction authority.**
5. `creator-monetization-pipeline-pack@1` — X/YouTube topic research, content backlog, draft posts/scripts, source links, monetization experiments and performance review. External publication remains owner-reviewed until separately authorized and proven.
6. `home-garage-organization-pack@1` — inventory, zone plan, label/location system, maintenance reminders and prioritized cleanup projects.

Existing vehicle-transport skills remain relevant where dealership transport is actually part of Matt's work. Construction-centered skills remain preserved but are not default demand.

## P0 — money-making doctrine

Kevin should actively seek **legitimate, evidence-backed ways to increase Matt's income or reduce waste**, but must distinguish preparation from consequential action.

GREEN / owner-value work includes:

- research profitable content niches and timely topics;
- draft X posts, threads, YouTube outlines, titles, thumbnails briefs and scripts;
- build content calendars and measure what performs;
- identify dealership workflow bottlenecks that save Matt time;
- build Cache Valley Appliance Repair launch plans, pricing models, checklists and training paths;
- research vehicle problems/manuals/parts and prepare diagnostic plans;
- research crypto markets, maintain watchlists, backtests where data permits, paper-trade strategies and score performance;
- organize household/garage/tool projects and recurring maintenance.

Owner-gated / not self-authorized:

- posting publicly as Matt;
- sending messages or entering contracts on Matt's behalf;
- purchases;
- credentials/permission widening;
- moving money;
- **live crypto trades or other financial transactions**;
- changing Kevin's own authority boundary;
- automatically promoting a newly learned capability into production.

### Crypto graduation path

Kevin's eventual crypto role should mature through explicit gates:

`RESEARCH -> PAPER TRADING -> SHADOW SIGNALS -> OWNER-REVIEWED ORDER PLAN -> LIMITED APPROVED EXECUTION (future, only if explicitly authorized and separately engineered)`

Before any live-execution discussion, require a durable strategy record, realistic fees/slippage assumptions, drawdown limits, position/risk caps, kill switch, exchange/API security model, complete audit log, independent reconciliation and a meaningful paper/shadow sample. Do not optimize for exciting returns while ignoring tail risk.

## P1 — persistent multi-worker operating model

Matt specifically values the behavior he saw in Grok Bot: persistent work that continues without constant reprompting, multiple specialized workers, scheduled routines, project handoffs and overnight progress.

Kevin should converge on the same useful operating pattern locally:

- Kevin = Chief of Staff / mission allocator / owner-facing coordinator;
- Research Scout = public web/manual/market/content research with citations;
- Desktop/Operator = bounded Windows/file/app execution;
- Skill Lab = learn, test, replay and score reusable procedures;
- Build Lab/Forge = candidate code/tool design in staging/sandbox;
- Guardian = reliability/evidence/readiness checks;
- Crypto Research worker = data/research/paper/shadow analysis only until future explicit execution authority;
- Creator worker = topic research, drafts, scripts, analytics and experiment backlog;
- Dealer Ops worker = iRecon/reconditioning/readiness planning and tracking;
- Business Builder = Cache Valley Appliance Repair planning, readiness and operating-system artifacts.

Workers may collaborate through mission IDs, shared durable artifacts and handoff receipts. Parallelism is valuable only when each worker owns a distinct useful task and evidence does not collide.

## P1 — continuous work supply

Kevin should not manufacture activity. When one queue is blocked, work another independent owner-valued queue.

Queue order:

1. direct owner requests / owner outcomes;
2. due owner recurring routines;
3. current-job optimization and vehicle readiness;
4. income/creator/business experiments;
5. crypto research/paper/shadow work;
6. capability-learning prerequisites;
7. guardians / stale evidence / recovery;
8. true idle only when all queues are legitimately empty.

For any selected mission, record mission ID, owner value, worker, required capabilities, acceptance criteria, lease/checkpoint, real outcome/evidence and next state.

## P1 — computer capability bus

Build many narrow tools rather than one unlimited shell. Priority families:

1. approved-root Document/File Scout;
2. bounded Desktop tools already adopted by Matt;
3. isolated read-first Browser Scout with domain/action policy;
4. structured spreadsheet/text/document creation;
5. dealer/reconditioning/iRecon data adapters where technically/legal permissible;
6. vehicle/manual/VIN research tools;
7. creator analytics/research connectors;
8. crypto market-data connectors for read-only research/paper trading;
9. household/tool/maintenance registry;
10. business/startup records for Cache Valley Appliance Repair.

Exploratory code/browser automation belongs in staging/sandbox. Production gets reviewed typed tools with explicit roots/domains/actions, budgets, receipts and negative tests.

## P1 — lifelong competency ledger

Every capability should carry: stable ID/version, owner use case, authority class, required tools, allowed roots/domains/actions, prerequisites, positive tests, forbidden tests, proof receipt, real-use count, success/failure rate, last successful use, known failure families, owner minutes/value produced and retirement/supersession state.

Lifecycle:

`PLANNED -> LEARNING -> CANDIDATE -> PROVEN -> REPEATEDLY_PROVEN -> RESPONSIBILITY_TRANSFERRED -> RETIRED/SUPERSEDED`

Never upgrade capability status from Kevin's own narrative. Promotion requires external/mechanical evidence appropriate to the capability plus replay.

## P1 — outcome scorecard

Keep Benchmark 30/30 as the platform safety/reliability floor, but measure Kevin on owner outcomes too:

- verified missions completed;
- owner-useful artifacts delivered;
- real-use count per skill;
- skills first-proven / repeatedly-proven / responsibility-transferred;
- owner minutes saved;
- income experiments created and measured;
- paper-trading sample size and risk-adjusted performance (not cherry-picked wins);
- blocker age / time-to-unblock;
- unexplained idle while governed useful work exists;
- false-success rate.

Targets: **false-success = 0%** and **unexplained idle with useful governed work available = 0%**.

## Coordination

Foreground Bess is the outside Chief Engineer for this sprint. Grok Bot may continue doing local work if it follows the convergence contract below. Qualified Kevin-local schedulers may continue. Avoid simultaneous uncontrolled writers to the same files/configuration.

Fresh correlated HESS-PC evidence outranks this prose. Local-only durable work is unfinished until intent and sanitized proof are published. Repository/CI work is not production until HESS-PC proves the installed result.

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

Semantic fingerprint: `14457B307B33957D2ADD4412FF97D0F36A0DA1BF8C801882A06DB24757A37547`

**Fresh runtime evidence first; one handover; publish every durable local change; then continue.**
