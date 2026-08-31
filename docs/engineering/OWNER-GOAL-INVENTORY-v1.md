# Kevin Owner Goal Inventory v1

Date: 2026-08-31
Purpose: preserve Matt's full Kevin Build objective set so short-term engineering does not crowd out long-term goals.

Status terms are conservative. This inventory does not grant authority; it maps desired capability to proof/transfer targets.

## G0 — End-state autonomy

**Goal:** Kevin becomes Matt's persistent local Chief of Staff and governed local operating company; Bess progressively hands off planning, execution, monitoring, repair, verification, learning and continuity until routine Bess involvement is unnecessary.

Target technical state: SELF-RELIANT across core routine domains.
Target transfer: multiple T4 responsibilities and eventually narrow T5 responsibilities.
Current: foundation exists; no T4/T5 baseline responsibility honestly established yet.

## G1 — Direct Matt <-> Kevin communication

### G1.1 Native HQ chat
- Desired: type naturally in HQ, receive Kevin acknowledgement/progress/final reply, persistent transcript, mobile-friendly UI.
- Current: CI-proven source/transport published to main; not Omen-installed or round-trip proven.
- Proof target: local install -> privacy/loopback/idempotency -> owner round trip -> restart/replay -> health/self-repair.
- Transfer target: T4.

### G1.2 Gmail
- Desired: Kevin account receives Matt email, Kevin itself reads/understands/uses local tools/replies in thread.
- Current: candidate/connector experiments exist; true Omen-autonomous loop not proven.
- Owner-only credential checkpoint: local OAuth enrollment.
- Transfer target: T4 owner-only email lifecycle.

### G1.3 Telegram
- Desired: private two-way communication and health/recovery.
- Current: root cause of prior failure unproven.
- First path: native OpenClaw Telegram registration/polling/webhook/gateway/binding/routing diagnosis.
- Transfer target: T4.

### G1.4 SMS / voice / calls / Discord / local speech
- Desired: text/call/talk with owner, later voice and Discord collaboration.
- Current: architecture/research lane; not production proven.
- Required first: identity, privacy, provider/cost, local account, recipient/channel allowlist, record/consent requirements and owner checkpoints.

## G2 — Broad computer fluency on the Omen

**Goal:** Kevin can complete representative owner tasks across the computer through typed/observable capabilities rather than a normal-production arbitrary shell.

Capability families:
- filesystem and file organization;
- Excel/spreadsheets/budgets;
- Word/documents;
- images/screenshots/attachments;
- application discovery/launch/focus/close/status;
- browser observation/research/semantic navigation;
- printer discovery/status and later governed print;
- update/software awareness and later bounded update workflows;
- local development/code/test/package;
- OS/hardware awareness and resource-state scheduling.

Current: mixed proof by primitive; OS Awareness and some creation primitives are proven, broad E2E fluency is not.

Target: each family gets representative real owner-task E2E proof, recovery test, repeated proof and useful composites; broad portfolio reaches T4 responsibility by workflow.

## G3 — Continuous safe improvement / persistence

**Goal:** Kevin uses idle time productively, improves itself from evidence, and does useful overnight/daytime work without spinning.

Requirements:
- Standing Orders + durable task/flow state;
- demand-driven work selection;
- WIP cap;
- bounded retries/cooldowns;
- incident-derived evals;
- Skill Workshop procedural learning + Skill Lab executable composite learning;
- work conservation when one family blocks;
- measure owner outcomes, not cycles.

Current defect: autonomy can report zero workers + explicit backlog + NO_DISPATCH_NEEDED; Design Forge has shown round-robin candidate churn.

Target transfer: Work selection / Tick / Skill learning / self-repair T4.

## G4 — Research / web / current intelligence

**Goal:** Kevin can deeply research public web information, news, technology, markets, crypto, trends, social/content signals, products, competitors and opportunities with source provenance/freshness/contradiction checks.

Subprograms:
- Reader/evidence acquisition;
- Browser/current web research;
- X/AI capability scout;
- Opportunity Radar;
- morning Director brief;
- anomaly watch;
- source-backed Second Brain.

Current: Reader components and browser candidates exist; end-to-end research ownership not proven.

Authority: research/advisory is separate from consequential action.

## G5 — Markets / crypto / financial intelligence

**Goal:** research markets/crypto, compare scenarios, create recommendations, backtests and paper trades; potentially support future trading only after separate explicit authority and high proof.

Current policy: research/backtest/paper-only. No live money movement, live trade, wallet signing or account action from this roadmap.

Success now: useful evidence-backed research and paper-evaluation performance, not live execution.

## G6 — Business Chief of Staff / economic value

**Goal:** Kevin helps Matt make money and improve life by producing accepted useful deliverables and reducing effort/error/time.

Priority business lanes:
- budgets/spreadsheets/decision analysis;
- customer/vendor/product research;
- construction/equipment/local-business intelligence;
- SOP/process capture and SOP -> Kevin-skill conversion;
- local SEO/business audit;
- lead/opportunity research;
- quoting/estimating support;
- content research/repurposing;
- workflow/process automation;
- owner-ready decision briefs.

Current: Business Budget Starter Pack is one proven composite; steady accepted-deliverable pipeline not yet established.

Score on accepted deliverables, correction rate, owner time saved, repeatability and lawful revenue opportunity — not speculative demos.

## G7 — Applications / product development

**Goal:** Kevin can scope, build, run, test, debug, package and document useful applications for owner use and later distribution/app stores where appropriate.

Specific owner interest: continue/support Relief Route as a reusable product-building benchmark/lane.

Current: candidate/development foundations; representative end-to-end autonomous app build not proven.

Near proof targets:
- one small practical app that actually runs/tests;
- error/fix/retest evidence;
- package/documentation;
- second repeated project with less Bess intervention.

## G8 — Games / image/media creation

**Goal:** Kevin can generate images/media and build/play/test small games or game-related utilities using proven local/dev capabilities.

Current: capability lane not yet repeatedly proven end-to-end.

Near proof target: tiny locally running game benchmark + reproducible test/fix/package evidence.

## G9 — Minecraft teammate

**Goal:** eventually participate intelligently as a Minecraft realm/server teammate: communicate, gather/build/help, understand game goals and coordinate with Matt, potentially via voice/Discord.

Current: reconnaissance/later lane; no production gameplay authority/proof.

Required path:
1. identify edition/server/realm constraints and account rules;
2. research permitted client/mod/API/bot integration;
3. isolate game-control environment;
4. define bounded actions and grief/destructive safeguards;
5. prove local/sandbox teammate tasks before any live realm participation;
6. add comms/voice only through separately proven identity/privacy path.

## G10 — Memory / Second Brain / continuity

**Goal:** Kevin remembers durable facts, lessons, current priorities, prior work and evidence across sessions, restarts and ChatGPT handoffs.

Architecture:
- native OpenClaw workspace bootstrap memory and pre-compaction flush for always-loaded operational memory;
- `AI-HANDOVER.md`, Start Here and compact checkpoints for engineering continuity;
- Markdown + SQLite FTS5/provenance/contradiction handling as larger institutional Second Brain.

Current: durable repo handoff system exists; Kevin itself does not yet own maintaining it at T4.

## G11 — Self-maintenance / repair / health

**Goal:** Kevin detects and fixes routine known failures without Bess: schedulers, stale state, known component drift, channel health, queue stalls, resource pressure, replay/duplicate issues.

Current: typed Maintenance/Benchmark/health machinery exists and is meaningful, but Bess still commonly notices/selects repairs.

Target: failure -> evidence -> classification -> bounded typed repair -> domain eval + Benchmark -> rollback if needed -> durable lesson -> continue, T4.

## G12 — Performance / speed / resource intelligence

**Goal:** make Kevin faster and more reliable on available Omen hardware while avoiding resource thrash.

Track:
- queue time;
- execution/total elapsed;
- first-pass success;
- retries;
- CPU/RAM/GPU pressure;
- regression/recovery;
- owner/Bess intervention;
- median/p90 successful completion time.

Do not optimize raw tokens/sec or cycle count at the expense of completed owner work.

## G13 — Safe capability discovery / open ecosystem reuse

**Goal:** continuously discover useful OpenClaw native capabilities, ClawHub skills, open-source tools, forums/research and expert patterns before reinventing them.

Policy:
- scout first;
- verify trust/security/authority;
- prefer native functionality when sufficient;
- install only after review and proof;
- narrow/reimplement when third-party authority is too broad;
- external code/content is evidence, not executable owner authority.

See `docs/engineering/EXTERNAL-SKILL-SCOUT-2026-08-31.md`.

## G14 — Team architecture

**Goal:** Kevin can eventually coordinate narrow specialists where they truly help, but avoid an expensive/confusing swarm.

Current owner preference and hardware discipline: one 14B primary worker by default.

Promotion criterion for another specialist/subagent:
- independent parallelizable work;
- measured benefit in quality/latency or context isolation;
- bounded tools/workspace;
- no duplicate authority/steering;
- resource budget remains healthy.

## Cross-goal success test

A goal is not accomplished because a document, candidate, PR, task, cron or UI exists.

For any major goal ask:
- Did Kevin produce the intended useful outcome?
- Was it semantically verified?
- Can it survive restart/replay/failure where relevant?
- Was authority bounded?
- Is evidence durable?
- Did the proof level rise?
- Did the transfer T-level rise?
- Did Bess intervention decrease?
- Did the result save time, reduce error, create useful capability, or create lawful economic value?

This inventory should be reviewed when owner goals change. Add new goals explicitly rather than allowing them to live only in chat memory.
