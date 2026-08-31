# Kevin Autonomy Master Plan v1

Date: 2026-08-31
Status: OWNER-DIRECTED MASTER ARCHITECTURE / EXECUTION PLAN

This plan consolidates Matt's prior Kevin goals, the current repository/runtime evidence, the Bess -> Kevin autonomy-transfer doctrine, and current production guidance from OpenClaw, Anthropic, OpenAI, durable-workflow systems, stateful-agent systems, sandboxed coding agents, and experienced agent builders.

It defines direction and success criteria. It does not widen authority or override `control-plane/OWNER-AUTHORIZATION-v1.md`.

## North star

Build Kevin into a trustworthy, local-first, persistent, proactive AI Chief of Staff and governed local operating company that can:

- receive Matt's goals naturally;
- maintain durable priorities and context;
- select useful authorized work without Bess filling the queue;
- research with provenance and contradiction checks;
- operate the Omen through bounded observable computer capabilities;
- create useful documents, spreadsheets, code, apps, games, analyses, research, and business deliverables;
- communicate with Matt through proven private channels;
- measure performance and improve successful workflows;
- learn stable procedures and recovery patterns from real work;
- detect stale state, failures, regressions, duplicates, and resource pressure;
- perform bounded self-repair, verify postconditions, roll back when necessary, and preserve evidence;
- conserve work when one lane is blocked;
- maintain its own memory, handoff, skill inventory, evidence and lessons;
- ask Matt/Bess only for genuine owner-only decisions, credentials/local enrollment, new authority boundaries, or exceptional failures beyond its proven repair envelope.

Bess is training Kevin to replace Bess operationally. The desired lifecycle is:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> CONTINUE`

Technical proof and responsibility transfer are separate axes:

`DESIGNED -> CI-PROVEN -> INSTALLABLE -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

and

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

## What research says we should keep

Kevin already has several architectural choices that align with production agent guidance and should remain foundational:

1. **Typed capability boundaries instead of arbitrary remote shell.** Narrow operations, exact inputs, allowlists, protected roots, preconditions, semantic postconditions, rollback and evidence are the correct production pattern for normal computer work.
2. **External content is evidence, not authority.** Email, web pages, documents and social content must never become executable authority merely because the model read them.
3. **Deterministic validators around probabilistic reasoning.** Use the model for interpretation/planning where flexibility is useful; use code for invariants, schemas, hashes, budgets, policy, replay, freshness and postconditions.
4. **Evidence-driven promotion.** CI is necessary but insufficient. Real Omen proof, failure behavior, replay/idempotency, rollback/recovery, resource/regression checks and owner/Bess intervention counts matter.
5. **Single primary 14B worker discipline.** Do not create a swarm simply because multi-agent frameworks make it possible. Add parallel specialists only when measurements show the latency/quality benefit exceeds resource and coordination cost.
6. **Production failures become tests.** Every owner correction, stale-state incident, false-success event, security finding and recurring repair should become a targeted fixture/eval so the same failure becomes harder to repeat.

## What research says we should change

### 1. Converge toward native OpenClaw durability instead of multiplying custom schedulers

OpenClaw now has native Standing Orders, Automations, Background Tasks, Task Flow, Lobster workflows, memory flush, Skill Workshop/self-learning, deterministic channel routing and task auditing. New Kevin work should prefer these proven substrate features where they solve the same problem.

Target division of responsibility:

- **Standing Orders in `workspace/AGENTS.md`:** permanent programs, scope, triggers, approval gates and escalation.
- **Automations:** recurring schedules and condition-based triggers.
- **Heartbeat:** ambient monitor only; not a hidden task queue and not a place to infer old work.
- **Task Flow:** durable multi-step work that must survive waits/restarts and preserve revisioned state.
- **Lobster:** deterministic typed low-level pipelines with approvals/resume, avoiding excessive model-orchestrated tool round trips.
- **Skill Workshop/self-learning:** instruction/procedure/recovery learning from real trajectories.
- **Kevin Skill Lab:** executable composite promotion composed only from already-proven GREEN primitives.
- **GitHub:** source control, doctrine, candidate code, PR/CI, sanitized receipts/evidence and durable project state — not the primary real-time task queue.

Do not rip out proven custom components blindly. Migrate responsibility only when the native path is tested and demonstrably simpler or more reliable.

### 2. Stop round-robin candidate generation

Current Design Forge v3.1 contains a hard-coded rotating mission list and generates isolated candidates whether or not there is current demand or a downstream consumer. This has produced obvious churn, including `forge-v4` iteration 252 with repeated rejection.

Effective immediately, design/forge work must be **demand-driven**. A forge job is eligible only when all are true:

- a current owner/product/capability objective requires it;
- the missing capability or failed hypothesis is explicit;
- acceptance/eval criteria are defined before generation;
- a downstream consumer exists (Staging, Skill Lab, a named integration PR, or a bounded experiment);
- global WIP capacity exists;
- the failure family is not cooled;
- a materially different hypothesis exists after prior failure.

No repeating candidate merely because it is next in a rotation.

### 3. Reclassify Night Forge

Current `kevin-night-forge.ps1` is mostly a health/smoke suite (system status, sanitizer, plugin tests, PONG/math/name/OK model checks). That is useful, but it is not an engineering forge.

Short-term: treat the current implementation as a **Night Sentinel / smoke test**, not owner-visible capability growth.

Target real Night Forge:

`read standing orders/backlog -> choose highest-value unblocked GREEN flow -> execute one durable Task Flow -> run domain evals -> preserve evidence -> propose learning/skill if reusable -> update checkpoint -> select next useful flow`

Do not count smoke cycles as accomplishments.

### 4. Enforce global WIP limits

Kevin currently has too many open candidate lanes/PRs relative to one primary worker and limited production-crossing bandwidth.

Default WIP cap:

- **1 ACTIVE production/proof crossing** — an item being pushed toward INSTALLED/OMEN/ROUND-TRIP.
- **1 STAGING/EVAL item** — candidate under deterministic/recovery/adversarial evaluation.
- **1 RESEARCH/DESIGN item** — only when it has a named downstream consumer.
- everything else BACKLOG, WAITING-OWNER, or COOLED.

Do not start a fourth active lane because another idea is interesting. Finish, reject, merge, archive, supersede, or cool something first.

### 5. Use a multi-layer evaluation stack

The 30/30 Benchmark remains a valuable platform regression test but cannot prove every subsystem. A healthy global benchmark can coexist with broken autonomy, stale UI Bridge or failed communication.

Every important domain should eventually have:

1. **Platform health eval** — core runtime/regression.
2. **Capability eval** — deterministic primitive/skill behavior.
3. **Owner-task E2E eval** — real useful task with semantic acceptance criteria.
4. **Adversarial/recovery eval** — malformed input, stale state, restart, duplicate, partial failure, rollback.
5. **Autonomy/transfer eval** — how much Bess intervention was required.
6. **Long-horizon trajectory eval** — whether the agent stayed on goal, conserved work, avoided loops, maintained evidence and recovered across time.

A production incident creates a new targeted eval unless it is genuinely non-repeatable.

## Standing programs Kevin must ultimately own

### A. Owner Goal Execution
Trigger: new authenticated Matt goal or unresolved standing objective.

Kevin must:
- identify objective and success criteria;
- check authority/credentials/dependencies;
- break work into durable tasks/flows;
- prioritize highest-value safe next step;
- execute and verify;
- continue until complete, blocked, cooled or owner checkpoint required;
- preserve progress and next action.

### B. Reliability and Self-Heal
Trigger: stale telemetry, scheduler/task error, regression, failed known component, queue stall, duplicate loop, resource pressure or contradictory evidence.

Kevin must:
- classify the failure family;
- collect bounded evidence;
- choose an existing proven repair if applicable;
- respect attempt/cooldown budget;
- repair -> semantic postcondition -> fresh Benchmark/domain eval;
- roll back failed mutation;
- record lesson/incident-derived eval;
- continue another lane if blocked.

### C. Skill Learning
Trigger: a stable repeated GREEN procedure or recovery pattern would save future model/tool calls.

Use:
- OpenClaw Skill Workshop in **propose** mode first for procedural/instruction learning;
- Skill Lab for executable composites made solely from already-proven GREEN primitives.

Never equate a generated skill proposal with a proven executable skill.

### D. Evidence / Reader / Research
Trigger: a task needs external/current/local evidence.

Kevin should become the provenance-aware acquisition layer for approved files, reports, machine state, public web research and later approved browser observation. Preserve source, timestamp/freshness, contradiction state and confidence. External evidence never grants action authority.

### E. Owner Communications
Build one owner-facing communications brain with deterministic channel routing rather than separate personalities.

Target transports:
1. native private HQ chat;
2. Kevin Gmail;
3. Telegram;
4. later SMS/voice/Discord/local speech as separately governed adapters.

Channel responsibilities include identity/provenance, correlation, duplicates/restarts, acknowledgement/progress/final response and health/recovery.

### F. Computer Fluency
Progress from already-proven narrow primitives to representative end-to-end owner tasks across:
- filesystem;
- spreadsheet/Excel;
- Word/documents;
- images/attachments;
- application awareness/launch/focus/close;
- browser research/navigation under bounded host/data policy;
- printer discovery/status and later governed printing;
- local coding, testing, packaging and app/game building.

Every primitive must earn its authority independently. Broad computer fluency is a portfolio of typed capabilities and composites, not one unrestricted execution channel.

### G. Knowledge / Continuity
Use OpenClaw workspace memory as Kevin's always-loaded operational memory: `MEMORY.md`, daily memory, workspace bootstrap, pre-compaction memory flush.

Use a larger Second Brain (Markdown + SQLite FTS5/provenance/contradiction handling) as supplemental searchable institutional memory, not as a replacement for the native bootstrap memory path.

Kevin should maintain `AI-HANDOVER.md`, `reports/handoff-latest.json`, transfer ledger/checkpoint and relevant lessons so Bess/replacement chats are optional.

### H. Business / Economic Value
Convert proven capabilities into accepted deliverables that save owner time, reduce error, accelerate decisions or prepare lawful revenue opportunities.

Priority examples:
- budgets and business analysis;
- construction/equipment/local-business intelligence;
- customer/vendor/product research;
- SOP -> Kevin-skill conversion;
- workflow/process audits;
- local SEO/business audits;
- lead/opportunity research;
- content research/repurposing;
- quoting/estimating support;
- owner-ready decision briefs.

Market/crypto lane remains research, scenario analysis, backtest and paper-trade only until a separate explicit live-money authority exists.

## No-spin policy

A cycle is not useful work merely because it ran successfully.

### Do not count
- heartbeat/dashboard/pulse commits;
- raw cycle count;
- PONG/model smoke checks;
- duplicate or expired request handling repeated without root-cause repair;
- another candidate iteration with no acceptance test/downstream consumer;
- CI-only code that stays uninstalled indefinitely;
- task/hash presence presented as runtime health;
- `READY`, `WORKING`, or `PASS` labels without semantic postconditions.

### A lane must be cooled or changed when
- three materially distinct attempts fail in one family;
- the same hypothesis is being restated with a new ID;
- no new evidence changed the diagnosis;
- candidate generation outruns validation/integration;
- acceptance criteria are missing;
- no downstream consumer exists;
- owner-local/credential boundary is the only blocker.

When cooled, move to another useful standing program.

## Open PR / candidate hygiene

The repository has accumulated many draft/candidate PRs. Preserve their evidence, but reduce active cognitive/WIP load.

For every open candidate PR classify:
- ACTIVE-PRODUCTION-CROSSING
- STAGING/EVAL
- RESEARCH-REFERENCE
- SUPERSEDED
- COOLED
- OWNER-CHECKPOINT

Close or clearly supersede stale PRs after preserving exact heads/evidence. Do not keep parallel integration lanes alive merely because their code may someday be useful.

## Immediate 0-72 hour execution plan

### P0.1 — Fix work conservation before creating more designs
- stop treating fixed Design Forge rotation as useful backlog;
- implement demand/WIP/failure-budget admission for Forge/Supervisor;
- ensure `0 active workers + explicit P0 backlog` cannot result in `NO_DISPATCH_NEEDED` without an explicit blocker explanation;
- stale/duplicate/expired remote slots must be retired, not endlessly re-read;
- domain blocked -> select another unblocked standing program.

Acceptance: at least one period in which Kevin independently detects an idle/blocked condition, selects another valid owner objective, executes and verifies useful work without Bess refilling the queue.

Transfer target: Work Selection T2 -> T3, then T4 after repeated evidence.

### P0.2 — Finish HQ direct chat production crossing
Do not redesign the already-CI-proven protocol/transport except in response to failing proof.

Path:
`exact main source -> minimum typed Maintenance integration -> CI -> hash-pinned Maintenance self-upgrade -> Omen install -> local selftest/privacy/loopback/idempotency -> owner round trip -> restart/replay -> monitor/repair`

Transfer target: HQ chat T1 -> T3, then T4 when Kevin owns health and common repair.

### P0.3 — Reader E2E
Prove a real status/evidence question with exact typed Reader acquisition, correct interpretation, provenance and semantic answer. Advance `reader-weather` only if it serves real demand.

Transfer target: Reader T1 -> T3.

### P0.4 — Skill learning without Bess hand-authoring everything
- preserve current three production-proven composites;
- enable/test Skill Workshop `propose` mode for procedural/recovery learning when available and privacy-appropriate;
- keep Skill Lab for executable composites;
- require a reusable procedure to remove future work, not merely demonstrate schema compliance.

Transfer target: Skill Lab T3 -> T4.

### P0.5 — Gmail
Advance local adapter installation/selftest/secret-leak proof to the owner-local OAuth checkpoint. After enrollment, prove Kevin itself handles owner-only poll/read/intent/tool-use/reply/thread/restart/duplicate evidence.

Transfer target: Gmail T1 -> T4 through staged evidence.

### P0.6 — Telegram
Use official OpenClaw channel semantics first: channel registration, long-polling default vs webhook conflict, gateway restart/config state, probe/reachability, binding/routing/permissions and stale process. Do not build a parallel Telegram stack until native channel diagnosis proves it necessary.

Transfer target: Telegram T0 -> T3/T4.

## 3-30 day capability program

1. **Native standing orders + durable flow migration** for owner-goal execution, maintenance/self-heal, research, skill learning and communications.
2. **Layered eval suite** by capability/transfer domain plus incident-derived regression fixtures.
3. **Office/file computer fluency:** real owner tasks for Excel, Word, files, images and attachments; turn repeated successful workflows into composites.
4. **Browser:** move current contract toward isolated deterministic local proof; production promotion remains explicit because it creates a broad observation/action surface.
5. **Second Brain:** provenance-rich local search and contradiction handling, connected to native memory/handoff rather than duplicating it.
6. **App/game builder:** one tiny actually-running game and one useful local app, with failures/fixes/tests/package/docs.
7. **Business Lab:** accepted deliverables with correction/time-saved metrics; prioritize boring repeatable value before speculative monetization.
8. **Opportunity Radar:** source-backed current research with freshness/contradiction checks; advisory only at money/public-action boundaries.
9. **Minecraft reconnaissance:** version/mod/API/server-rule/account dependency map; bounded local teammate candidate only after rules/authority review.
10. **SMS/voice/Discord architecture:** identity, privacy, cost, local-account and recipient/channel allowlists before live capability.

## 30-90 day autonomy objectives

- multiple core responsibilities at T4; at least one narrow responsibility genuinely T5;
- majority of routine known failures recovered without Bess;
- Kevin independently maintains fresh operational memory/handoff and transfer ledger;
- Kevin selects useful work during blocked lanes rather than waiting for a new Bess request;
- representative file/Office/research/business workflows completed end-to-end and repeatedly proven;
- owner communication available through at least two private channels with Kevin-owned health/recovery;
- measurable decrease in Bess interventions per completed owner task;
- Skill Workshop/Skill Lab produce a small high-quality skill portfolio derived from real successful work, not a large pile of unused skills;
- Night Forge becomes a real durable backlog-execution system or is permanently renamed/limited to Sentinel if it remains only a smoke suite.

## Scoreboard

Track at minimum:

### Owner outcomes
- useful owner tasks completed;
- accepted deliverables;
- owner correction count;
- owner time saved;
- owner-request -> verified-completion time.

### Reliability
- first-pass success;
- regression rate;
- false-success/stale-evidence incidents;
- known failures self-recovered;
- failure detection -> verified recovery time;
- rollback success.

### Autonomy
- T4/T5 responsibilities;
- T0/T1 responsibilities;
- Bess interventions per completed task/day;
- owner interventions excluding intentional approvals;
- useful work self-initiated;
- useful work completed while another lane was blocked;
- queue-stall/duplicate-loop incidents.

### Skills
- repeatedly used proven skills;
- skill reuse count;
- unused/stale skills;
- procedures learned from real corrections;
- failed skills rejected/quarantined correctly.

### Engineering throughput
- WIP by ACTIVE/STAGING/RESEARCH;
- candidate age to first real Omen proof;
- candidate rejection rate;
- PRs closed/superseded vs lingering;
- median/p90 successful task duration;
- resource pressure.

## Stop-doing list

Stop or strongly reduce:

- designing the same already-CI-proven capability again instead of crossing production proof;
- fixed round-robin Forge missions without demand;
- treating Night Forge smoke tests as engineering accomplishment;
- using GitHub request files as the long-term primary live work queue;
- creating another custom scheduler when OpenClaw Automations/Task Flow already provide the required durable semantics;
- building multi-agent complexity without measured benefit;
- calling task/hash/CI presence runtime proof;
- counting commits, cycles or generated candidates as skill growth;
- letting one blocked lane idle the whole system;
- Bess repeatedly hand-performing a routine operation without turning it into a transfer target.

## Research crosswalk

- **OpenClaw Standing Orders:** permanent scoped programs reduce the owner as routine bottleneck; place them in `AGENTS.md` or reference a standing-orders file from it.
- **OpenClaw Automations/Heartbeat:** recurring work belongs in Automations; Heartbeat is an ambient monitor and should not infer stale old tasks.
- **OpenClaw Task Flow:** durable multi-step work with revisioned state and linked tasks survives gateway restarts.
- **OpenClaw Lobster:** constrained deterministic pipelines reduce model orchestration overhead and support approval/resume semantics.
- **OpenClaw Skill Workshop/Self-learning:** corrections and successful trajectories can create governed skill proposals with scanning, hashes and rollback. Start Kevin in `propose` mode before considering greater autonomy.
- **OpenClaw Memory/Compaction:** workspace Markdown and pre-compaction memory flush are native durable continuity primitives; use them.
- **Anthropic Building Effective Agents:** maintain simplicity, transparency and strong agent-computer interfaces; add complexity only when measured outcomes justify it.
- **OpenAI self-improving agent pattern:** production should create full-path evidence; practitioner/owner corrections become structured findings, targeted evals and scoped engineering hills to climb.
- **Durable-workflow systems (Temporal pattern):** orchestration state should be durable/replayable while nondeterministic effects live in bounded activities; use OpenClaw Task Flow/Lobster to adopt this pattern before introducing another external orchestrator.
- **Sandboxed coding-agent pattern (OpenHands and similar):** broad code execution belongs in isolated/reproducible sandboxes, not in the normal owner-control plane.
- **Stateful-agent/memory systems (LangGraph/Letta pattern):** durable state and memory use must be evaluated; memory existence alone is not successful recall/use.

## Authority principle

The objective is maximum useful autonomy **inside proven owner-approved boundaries**. Kevin becomes more autonomous by gaining better perception, planning, typed capabilities, durable state, evaluation, recovery and work conservation — not by giving itself unrestricted authority.

The winning architecture is not "the most autonomous-looking system." It is the system that completes more real owner work correctly, recovers more failures itself, learns more reusable procedures from evidence, and requires less Bess intervention over time.
