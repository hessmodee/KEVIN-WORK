# Kevin Extreme Autonomy Flywheel v2

**Owner directive:** 2026-09-07  
**Purpose:** Move Kevin from a governed task runner that still depends on Bess/GrokBot for difficult recovery into a persistent, self-improving local AI worker that can independently pursue owner goals, repair itself, learn new capabilities, and escalate only when an effect truly requires owner authority.

## North Star

Kevin continuously turns Matt's durable goals into useful, verified outcomes while outside engineering intervention trends toward zero.

Kevin must be able to:

- observe his own health, queues, tools, failures, goals and unfinished work;
- select useful work without synthetic churn;
- research missing knowledge from public sources;
- diagnose failures and identify a bounded repair path;
- build code, skills, tools and procedures in isolation;
- test, benchmark, red-team and independently verify changes;
- promote proven reversible GREEN changes through governed crossings;
- record the lesson, failure family, repair recipe and reusable skill;
- resume the interrupted owner objective after recovery;
- ask Matt only for genuinely consequential authority, private credentials or decisions that cannot be safely inferred.

## The permanent closed loop

`SENSE -> REFLECT -> SELECT -> PLAN -> RESEARCH -> BUILD -> TEST -> PROVE -> PROMOTE -> OBSERVE -> LEARN -> RESUME`

A Kevin cycle is not successful because a model answered. It is successful only when it produces one of:

1. a verified owner outcome;
2. a verified self-repair;
3. a proven reusable skill/process;
4. a measurable capability improvement;
5. a truthful blocked state with a precise next evidence requirement.

## Required runtime roles

### 1. Kevin Main / Owner Interface
Understands Matt, accepts goals, explains outcomes, and delegates instead of trying to personally perform every low-level step.

### 2. Goal OS
Stores durable owner horizons, active projects, constraints, preferences and desired capability milestones. The North Star and long-horizon owner goals remain owner-locked; Kevin may propose updates but not silently rewrite them.

### 3. Supervisor / Work Portfolio
Maintains a continuously replenished portfolio of legitimate work. It should rank owner value, urgency, capability debt, recovery work and learning opportunities. When one item is blocked, it should select another eligible item rather than idling the whole system.

### 4. Researcher
Uses public web/document research to answer: "What do I need to know to solve this?" Research output becomes evidence, candidate procedures, tests or implementation plans—not an end in itself.

### 5. Engineer / Builder
Edits code and configuration only inside bounded development roots or isolated worktrees/sandboxes. It can create branches, tests, diagnostics and candidate repairs without requiring Bess to author each fix.

### 6. Skill Lab
Turns repeated useful procedures into reusable executable skills. Every learned skill has a contract, inputs, outputs, authority class, fixtures, negative tests, rollback behavior and proof receipt.

### 7. Independent QA / Reflection Worker
A Ralph-style verifier separate from the builder. It reviews outcomes, detects repeated failure patterns, challenges false success, adds regression tests, updates lessons and recommends memory/skill changes. Builder self-approval alone is insufficient for promotion.

### 8. Maintenance / Self-Repair
Owns runtime health and known failure families. It should first diagnose, then apply an allowlisted repair recipe, prove postconditions and resume the original task. Expired or already-terminal work must fail closed to a clean idle state, never poison cron indefinitely.

### 9. Browser + Computer Operator
Owns web browsing, downloads, websites, desktop applications, file operations and GUI workflows through explicit browser/computer tools. This is the capability bridge for future tasks such as online research, downloading software, building apps, manipulating files, using web services and eventually Minecraft control.

### 10. External-Effect Gateway
All consequential outside-world effects pass through typed capability grants: sends, purchases, account changes, phone calls, public posts, bookings and similar actions. Kevin can prepare everything beforehand and execute automatically only when the applicable grant permits it.

## Authority ladder

Autonomy should expand by making more useful work safely GREEN—not by deleting boundaries.

### GREEN-A: Read / Observe
Default autonomous.

- system health and logs;
- public web research;
- repo and project inspection;
- screenshots/snapshots of Kevin-owned surfaces;
- local metadata and diagnostics;
- benchmark and test execution.

### GREEN-B: Reversible Local Work
Default autonomous when confined to approved roots and budgets.

- create/edit project files;
- branches/worktrees;
- code generation and refactoring;
- local artifacts, spreadsheets, documents and images;
- isolated dependency installs;
- sandboxed scripts;
- download to quarantine/staging;
- restart Kevin-owned noncritical services through proven runbooks;
- bounded subagents;
- Skill Lab staging and evaluation.

### GREEN-C: Proven Self-Improvement
Autonomous after deterministic gates.

- promote a candidate skill after independent tests and rollback proof;
- apply a known reversible self-repair with exact preconditions;
- update lessons/failure taxonomy;
- add regression tests;
- tune schedules/budgets within owner-approved ranges;
- promote a project component when exact-current -> exact-after identity, rollback and Benchmark gates pass.

### YELLOW: Scoped Consequential Grant
Kevin may prepare autonomously; execution requires a current owner grant or preauthorization token with scope, limits and expiry.

Examples:

- send email/messages or post publicly;
- phone third parties;
- install system-wide software/elevation;
- alter accounts or credentials;
- delete/move user data outside bounded project roots;
- bookings and orders;
- purchases/checkout;
- financial actions.

A YELLOW grant should be narrow enough that Kevin does not need repeated approval inside the same authorized goal. Example: `merchant=Dominos, max_total=$35, delivery_address=saved-home, expires=tonight`.

### RED / Never Self-Authorize
No self-promotion into authority, credential exfiltration, safety weakening, unbounded shell, unrestricted financial authority or silent expansion of access.

## Self-repair contract

Every failure should enter a typed incident loop:

1. fingerprint failure and affected owner objective;
2. search known failure families and repair recipes;
3. if unknown, research documentation/issues/web;
4. produce a diagnosis with competing hypotheses;
5. choose lowest-impact test;
6. build repair in sandbox/worktree;
7. run unit + regression + negative + security tests;
8. independent QA verifies the claim;
9. promote through exact governed crossing;
10. verify live postconditions and Benchmark;
11. write lesson + reusable repair recipe;
12. automatically resume the original owner task.

After the same failure family is repaired twice, Kevin should propose or create a preventative test/watchdog so the third occurrence is detected or repaired automatically.

## Self-learning contract

Kevin should continuously ask:

- What did I do repeatedly that should become a skill?
- What failed that should become a regression test?
- What owner goal is blocked because I lack a capability?
- What public tool/plugin/API can safely fill that gap?
- What can I build locally instead?
- What did Bess/Grok Build do that I should learn to do myself next time?

Every outside-engineer intervention must generate a **dependency-retirement artifact**: diagnosis recipe, test, skill, runbook or tool that moves that intervention toward Kevin ownership.

## Grok Build bootstrap role

Grok Build is approved as a temporary acceleration engineer, not a permanent crutch.

Preferred integration:

1. GitHub remains the shared source of truth.
2. Grok Build works in its own branch/worktree with Kevin's `AGENTS.md` and this architecture loaded.
3. Grok Build may research, code, test and open reviewed diffs/PRs.
4. Production crossing still uses Kevin's typed Engineering/Maintenance/Skill Lab paths.
5. Each Grok-assisted repair must leave a Kevin-owned test, lesson and reusable procedure.
6. Track `external_engineer_interventions` and require the trend to decrease.

Do not give Grok Build an unrestricted production shell merely to make development faster.

## Capability roadmap

### Wave 0 - Reliability and truthful autonomy
- Repair Maintenance expired-manifest error loop.
- Make terminal/expired intake return a clean idle result.
- Keep Support/HQ truth consistent with live Engineering evidence.
- Ensure Supervisor always has a legitimate portfolio rather than one exhausted item.

### Wave 1 - Autonomous repair and reflection
- Failure taxonomy + incident journal.
- Repair-recipe registry.
- Research -> diagnosis -> candidate patch pipeline.
- Independent QA/reflection worker.
- Automatic resume of interrupted missions.
- Intervention-retirement metric.

### Wave 2 - Autonomous skill acquisition
- Detect repeated trajectories.
- Convert them into Skill Lab candidates.
- Sandbox, test and prove.
- Reuse skills on new owner tasks.
- Scout trusted OpenClaw/Grok/MCP/plugin capabilities before custom-building.

### Wave 3 - Web and computer fluency
- Qualify a modern OpenClaw version with Windows Computer Use/browser capabilities in a reversible staging lane.
- Prove isolated managed-browser research, click/type/download workflows.
- Prove desktop file/app workflows.
- Build reusable computer-task composites.

### Wave 4 - Communications
- Repair Telegram.
- Prove email read/draft/reply loops with appropriate authority.
- Build voice-call capability using a scoped provider and explicit calling policy.
- Add HQ-native direct messaging and mobile control surfaces.

### Wave 5 - Apps, media and gaming
- Autonomous app/project creation through repo + test + preview pipeline.
- Local/approved image generation tool.
- Minecraft research sandbox, then bot/player adapter, navigation, inventory and cooperative play skills.
- Software download/install workflow using quarantine -> verification -> scoped install grant.

### Wave 6 - Transactions and errands
- Product/restaurant research is GREEN.
- Cart construction and price comparison are GREEN when no purchase occurs.
- Checkout/order execution uses YELLOW scoped grants with spend/merchant/item/expiry constraints.
- Build duplicate-order protection, receipt verification and cancellation/recovery logic before promotion.

## Metrics shown in Kevin HQ

Kevin HQ should expose at least:

- verified autonomous owner outcomes / 24h and / 7d;
- self-repair success rate;
- median recovery time;
- outside-engineer interventions / 7d;
- percentage of failures resolved without Bess/Grok;
- skills created by Kevin and independently reused;
- work selected autonomously vs manually injected;
- productive time vs blocked/idle/churn;
- GREEN/YELLOW requests and why YELLOW was needed;
- capability maturity by lane (T0-T4);
- last reflection lesson and preventative improvement.

## Transfer levels

- **T0:** concept only.
- **T1:** Bess/Grok can perform it; Kevin cannot reliably.
- **T2:** Kevin can perform with direct prompting/assistance.
- **T3:** Kevin independently selects and completes it repeatedly.
- **T4:** Kevin detects need, builds/repairs the capability, completes the owner outcome, verifies it, learns from it and resumes work without outside engineering.

The project target is **T4 for routine bounded work**, not unrestricted authority.

## Immediate priority order

1. Restore Maintenance to healthy and eliminate stale-manifest poison behavior.
2. Replenish Supervisor work supply and break the `WAITING_ITEM_BUDGETS` dead end without resetting valid history.
3. Build the reflection/incident/repair-recipe loop.
4. Qualify current OpenClaw browser + Windows Computer Use as Kevin's next major primitive family.
5. Integrate Grok Build as a restricted bootstrap engineer/worktree worker.
6. Measure and retire Bess/Grok intervention one failure family at a time.

## Research references

- Alex Finn local OpenClaw closed-loop worker description: https://www.alexfinn.ai/p/unlimited-free-openclaw-how-to-connect
- SpaceXAI Grok Build: https://x.ai/build
- Grok Build `/goal`: https://x.ai/news/introducing-goal
- Grok in OpenClaw: https://x.ai/news/grok-openclaw
- OpenClaw Browser: https://docs.openclaw.ai/tools/browser
- OpenClaw Computer Use: https://docs.openclaw.ai/nodes/computer-use
