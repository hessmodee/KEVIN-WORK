# Kevin Value Skill Acceleration v1

**Date:** 2026-09-03  
**Mission:** turn Kevin from a healthy autonomous platform into an owner-useful local worker that repeatedly performs real work, protects Matt from avoidable misses, and learns new bounded responsibilities without depending on unrestricted host authority.

## 1. Value definition

A Kevin capability is valuable only when it has a real owner use case, an executable path, a verifiable postcondition, a durable receipt, a replay path and a safe failure/escalation behavior.

Infrastructure metrics are supporting evidence, not owner outcomes.

## 2. Architecture pattern selected

Current local-agent ecosystems repeatedly converge on the same useful separation:

- a local/private model or agent loop for interpretation and planning;
- small typed tools for real-world action;
- project/profile-specific capability scoping;
- durable structured memory plus searchable evidence;
- declarative tool-sequence constraints and approval boundaries;
- sandboxed execution for generated or exploratory code;
- browser automation in a separate constrained session/profile;
- deterministic workflow/scheduler logic for recurring jobs;
- skills/procedures loaded only when relevant;
- independent verification and replay artifacts.

Kevin should adopt these patterns without importing third-party unrestricted authority.

## 3. Capability bus rule

Prefer twenty narrow, composable tools over one generic shell.

Every production tool must have:

- stable tool ID;
- typed input schema;
- bounded target/root/domain/action set;
- explicit authority class;
- deterministic input validation;
- public-safe output contract where applicable;
- positive tests;
- forbidden negative tests;
- audit receipt;
- bounded retry/failure family;
- rollback or safe no-op behavior when mutation is possible.

No caller-selected executable, shell string, arbitrary path, generic credential access or unrestricted browser/session control should be smuggled in through a supposedly convenient tool.

## 4. Skill lifecycle

Use the following maturity ladder:

`PLANNED -> LEARNING -> CANDIDATE -> PROVEN -> REPEATEDLY_PROVEN -> RESPONSIBILITY_TRANSFERRED -> RETIRED/SUPERSEDED`

A skill ledger entry should include:

- id/version/name;
- owner problem solved;
- prerequisites;
- tool dependencies;
- allowed roots/domains/actions;
- authority class;
- positive acceptance suite;
- forbidden negative suite;
- proof receipt/hash;
- real-use count;
- success/failure counts;
- last successful use;
- known failure families;
- estimated owner minutes saved;
- current maturity;
- superseding skill/version when retired.

## 5. Value-first skill curriculum

### Tier A — immediately useful / lowest authority

1. Tomorrow Field Work Command Pack
2. Equipment and Tool Control Pack
3. Vehicle Transport Mission Pack
4. Construction Daily Field Log Pack
5. Business Budget Starter Pack
6. End-of-Day Handover / Tomorrow Gate

These can compose already-proven file/spreadsheet primitives and create useful owner artifacts immediately.

### Tier B — read/understand approved owner data

1. Approved-root File Scout
2. Spreadsheet/CSV Query
3. PDF/manual evidence extractor
4. Job-note summarizer
5. VIN/unit/part-number exact lookup across approved local records
6. document compare / changed-requirement detector

Start read-only. Mutation remains through separate proven creation/update tools.

### Tier C — bounded local computer fluency

1. system health/status
2. find direct approved Desktop folder
3. open approved Desktop folder
4. launch reviewed allowlisted app
5. inspect a bounded app/window postcondition
6. later add typed open-file operations for explicitly approved roots/extensions

Generic mouse/keyboard and arbitrary process execution remain outside the Tier C primitive set.

### Tier D — research and browser work

1. public Research Scout with citations
2. read/extract browser session
3. domain-scoped navigation/search
4. deterministic form preparation without submit
5. explicit-owner-gated submit/send only if separately adopted later

Use isolated browser state/profile where possible. Treat browser cookies and authenticated profiles as high-trust resources.

### Tier E — protective operations

1. Tomorrow Readiness Guardian
2. Equipment Location Contradiction Detector
3. Maintenance Due Guardian
4. Computer Health Guardian
5. Local/Repository Drift Guardian
6. Failed-Work Disappearance Detector
7. Owner Instruction Conflict Detector

A guardian surfaces evidence, impact, next safe action and escalation boundary. It does not expand authority merely because it runs autonomously.

## 6. Skill selection policy

The Supervisor should choose the highest-owner-value eligible work item.

Score candidate work using at least:

`owner impact + recurrence + time saved + protective value + prerequisite leverage - risk - uncertainty - resource cost`

If the highest-value item is blocked, execute its safe prerequisite or the next independent owner-valued item. Never manufacture tasks just to keep a worker non-idle.

## 7. Learning loop

For every new responsibility:

`notice -> classify -> gather evidence -> plan -> execute -> verify -> recover -> record -> extract lesson -> create/revise procedure -> replay second representative case -> promote responsibility`

Repeated Bess/Grok/Matt repair or setup work becomes autonomy debt. The correct close condition is not "Bess fixed it again"; it is "Kevin can detect, safely repair or escalate, verify and record this family without routine Bess help."

## 8. Sandbox policy

Exploratory code, downloaded/community tools, generated scripts and broad browser experiments belong in an isolated sandbox with controlled mounts and no production secrets.

Production Kevin receives only the small reviewed primitives that survive qualification.

## 9. Memory policy

Separate memory into:

- always-visible owner policy / mission / authority blocks;
- current project/task working memory;
- structured asset/job registries;
- searchable long-term evidence/archive;
- skill competency ledger;
- failure-family / recovery lessons.

Do not stuff every skill, every old log and every policy into every prompt. Load only what the current task needs.

## 10. HQ measurement

HQ should make owner value visible. Prefer:

- PROVEN skills;
- REPEATEDLY_PROVEN skills;
- RESPONSIBILITY_TRANSFERRED count;
- real uses in last 7/30 days;
- successful-use rate;
- last successful use;
- owner minutes/hours saved;
- protective catches;
- unresolved blockers;
- next eligible upgrade;
- autonomy debt outstanding.

Raw cycles, model turns, heartbeats and commit counts belong in diagnostics, not the owner success headline.

## 11. Near-term finish line

The near-term finish line is not "Kevin has many components." It is:

- Matt can talk naturally to Kevin;
- Kevin can choose and execute a useful bounded skill;
- Kevin can read the approved information needed to do real work;
- Kevin can create useful work products;
- Kevin can perform several safe computer actions;
- Kevin can research when required;
- Kevin notices common readiness/problems before Matt has to ask;
- Kevin verifies what he did;
- Kevin learns/replays the trajectory;
- protected boundaries remain closed.

That is the standard for calling Kevin an autonomous local worker rather than an autonomous infrastructure project.
