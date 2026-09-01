# Kevin Extreme Autonomy Build Plan v1

Date: 2026-09-01
Status: OWNER-DIRECTED IMPLEMENTATION ARCHITECTURE

This plan extends `KEVIN-AUTONOMY-MASTER-PLAN-v1.md` toward Matt's explicit end state: Kevin should increasingly notice his own limitations, research solutions, build and test improvements, repair recurring failures, learn reusable procedures, prepare ahead, select useful work, execute it, verify real outcomes, and continue 24/7 without Bess routinely supplying the next fix.

This document does **not** grant arbitrary execution, spending, credential disclosure, destructive owner-data mutation, unrestricted third-party communication, or self-created authority. Existing owner authorization remains the production boundary.

## End state

Kevin is successful when Matt can give him outcomes rather than implementation instructions, and Kevin can normally complete the lifecycle:

`NOTICE -> UNDERSTAND -> PLAN -> RESEARCH -> BUILD/ACT -> VERIFY -> RECOVER -> REFLECT -> LEARN -> CONTINUE`

Examples of target outcomes include:

- research current information online and produce a sourced decision or deliverable;
- build and maintain apps, scripts, dashboards, games and automations;
- operate ordinary Windows applications and files through bounded computer capabilities;
- become a Minecraft co-player through a separately tested game-control adapter;
- create or obtain images and media through approved tools;
- communicate privately with Matt through HQ, Telegram, email, voice and later phone channels;
- prepare shopping selections and carts and, under a separately explicit spending policy, eventually place bounded purchases;
- install and configure useful software through a verified software-install capability;
- notice a recurring problem, diagnose it, build a candidate repair, test it, deploy through the governed path, and prove the repair without Bess doing the routine lifecycle steps;
- surprise Matt with small useful workflow improvements derived from real goals and friction, not arbitrary novelty.

## 1. Autonomy kernel

The canonical operating loop is:

`Standing Orders / authenticated owner events`
`-> durable Goal + Capability Gap Inventory`
`-> deterministic eligibility / WIP / consequence / cooldown policy`
`-> Task Flow durable state`
`-> Qwen/main reasoning where ambiguity requires it`
`-> proven typed capability or isolated builder`
`-> semantic verifier`
`-> owner-outcome + trajectory evidence`
`-> evidence-based reflection`
`-> skill/eval/candidate proposal`
`-> next eligible action`

Heartbeat observes. Automations wake. Task Flow remembers. Deterministic code decides eligibility and consequence class. The model reasons. Typed tools act. Semantic evaluators decide whether the world actually changed as intended.

## 2. Evidence-based self-reflection

Self-reflection means post-task operational learning, not unrestricted private chain-of-thought storage.

After substantial work, failure, recovery or owner correction, record a compact reflection object containing when applicable:

- goal and acceptance criterion;
- intended next state versus observed state;
- decision/action chosen;
- evidence quality and freshness;
- failure family and whether the validator itself may be stale;
- attempts, elapsed time and resource cost;
- missing primitive, knowledge or dependency;
- reusable procedure or preflight discovered;
- regression/eval that would prevent recurrence;
- next experiment or next eligible action;
- Bess intervention still required.

A reflection is useful only if it changes future selection, adds an eval, improves a skill, creates a bounded repair or closes an autonomy gap.

## 3. Capability Gap Generator

Maintain a durable matrix:

`owner goal / future objective x required capabilities x current proof level x transfer level x blocker`

The gap generator may create a build/research item only when all are true:

1. a real owner goal or standing objective needs the capability;
2. the missing capability is explicit;
3. a downstream consumer exists;
4. acceptance tests are defined first;
5. WIP capacity exists;
6. the failure family is not cooled;
7. the item has higher expected owner value than available alternatives.

No gap -> no invented work.

Initial high-value gap families:

- private owner communication and voice;
- browser observation/navigation/form filling;
- broad but typed Windows application control;
- file/document/spreadsheet/image/media work;
- verified software/package installation;
- coding/build/review harness integration;
- durable Task Flow goal ownership;
- self-learning and repair capture;
- authenticated personal-service adapters;
- Minecraft/game adapters;
- shopping research/cart preparation and later separately governed transaction execution.

## 4. Builder / reviewer architecture

Kevin should become the architect/orchestrator, not depend on Bess to hand-author every missing capability.

Target build flow:

`capability gap`
`-> isolated worktree/sandbox`
`-> interchangeable coding builder`
`-> unit/integration/adversarial tests`
`-> independent reviewer/evaluator`
`-> candidate artifact + exact identity`
`-> staging/replay/idempotency/recovery proof`
`-> typed production crossing`
`-> Omen semantic proof`
`-> reusable skill/eval capture`

### Grok Build lane

Grok Build is approved for evaluation as an **interchangeable subordinate engineering harness**, not as Kevin's authority layer.

Reasons it fits:

- headless scripting and JSON/streaming output;
- Agent Client Protocol support;
- `AGENTS.md` compatibility;
- skills, plugins, hooks and MCP support;
- project-level permissions and sandboxing;
- local/custom-model support;
- worktree/session support;
- current Windows support.

Integration sequence:

1. typed presence/version audit;
2. typed install from an official xAI distribution source with exact version/source evidence;
3. `grok inspect` metadata-only verification;
4. project sandbox/permission policy; never Omen-wide unrestricted always-approve by default;
5. headless test against an isolated disposable repository;
6. first real Kevin capability-gap build;
7. independent tests/reviewer that do not trust the builder's self-report;
8. measure acceptance rate, rework, latency, resource/API cost and Bess intervention versus existing builders;
9. retain it only if measured benefit is positive.

Kevin must be able to swap Grok Build, Codex, another coding harness or a local builder without changing owner authority or durable goal state.

## 5. GREEN and YELLOW autonomy model

### GREEN

Keep existing broad standing GREEN authority. Legitimate GREEN work should remain continuously executable without re-asking Matt: inspect, diagnose, research, test, verify, repair through proven typed mechanisms, learn, combine proven GREEN primitives, optimize, document, monitor, roll back and operate within existing scope.

### YELLOW AUTONOMY INCUBATOR

Do **not** make all YELLOW production work GREEN. Instead separate **learning/build authority** from **production side-effect authority**.

Kevin may autonomously perform YELLOW research and development in an isolated candidate/staging environment when:

- no money is spent;
- no purchase/order/trade is placed;
- no owner credential or secret is exposed to an unapproved destination;
- no external message represents Matt;
- no destructive owner-data mutation occurs;
- no permission/trust boundary is widened;
- no arbitrary remote command channel is created;
- the candidate has explicit acceptance tests and a rollback/discard path.

This includes researching unfamiliar software/APIs, writing candidate adapters, downloading non-executable public documentation/source into isolation, generating mocks, building tests, simulating browser/service flows, preparing install packages, and evaluating new tools.

A YELLOW capability can graduate to reusable production GREEN only through an owner-approved category or existing promotion policy plus exact typed inputs, consequence classification, independent verification, rollback, negative/adversarial tests and repeated real proof.

Examples that may become category-GREEN after explicit bounded policy:

- signed software installs from fixed approved package sources;
- owner-private communication to fixed verified endpoints;
- creation of local project files/folders under approved roots;
- reversible local application configuration;
- browser navigation/form preparation without final consequential submission.

Examples that remain approval-bound unless Matt later creates a specific separate policy:

- purchases, payment or live financial transactions;
- destructive owner-data changes without reliable recovery;
- public/third-party owner-representing communications outside fixed approved recipient/scope;
- credential/trust/permission expansion;
- unrestricted arbitrary execution surfaces.

## 6. Self-repair ladder

For every recurring Bess repair, ask which lifecycle step is still external and convert that step into a Kevin-owned detector/repair/verifier when safe.

Failure-family lifecycle:

`detect -> classify -> bounded evidence -> known repair or isolated hypothesis -> max 3 materially distinct attempts -> semantic verifier -> Benchmark/domain eval -> rollback on failed mutation -> incident-derived regression -> cooldown/alternate work`

Existing Self-Reliance Watchdog and typed Maintenance are the preferred Layer-0/Layer-1 repair substrates. Do not create another daemon when one proven responsibility can be extended.

## 7. Computer Capability Broker

Broad computer fluency should be a typed intent layer over reusable primitives rather than one unrestricted shell.

Target primitive families:

- filesystem: inspect/search/create/copy/move/rename/delete-with-recovery/archive/hash;
- process/app: discover/install/launch/focus/close/status;
- clipboard and accessibility/UI automation;
- browser: observe/navigate/search/download/upload/forms/cart preparation;
- documents/spreadsheets/presentations/PDF/images;
- software installation/update/uninstall through approved sources and signatures;
- network/download verification;
- notifications, local speech and owner-private voice;
- authenticated channel adapters;
- game-specific observation/action adapters.

Each primitive gets schema, preconditions, consequence class, protected roots/targets, retries, semantic postconditions, audit evidence and rollback where applicable. Skills/composites should combine these primitives so Kevin can solve unfamiliar tasks without receiving raw command authority.

## 8. Self-learning policy

Use OpenClaw Skill Workshop/self-learning for reusable **procedures**, not for creating new primitive authority.

Current research supports increasing autonomy once the active tool policy and Gateway are proven:

- scanner-gated Workshop-created skills may eventually use autonomous `auto` mode;
- Workshop-owned skill repairs can auto-apply because they remain hash-bound, scanned and rollback-capable;
- user-authored/manual policy skills remain protected/pending where the runtime requires it;
- procedural learning never changes the primitive authority registry by itself.

Use production failures and successful substantial work as the training data. Do not manufacture skills from one-off trivial turns.

## 9. Nightly Surprise Program

Replace 'nightly churn' with one outcome-oriented standing program:

When Matt is inactive and useful backlog exists, select at most one small improvement or owner deliverable that:

- maps to a real goal/friction/capability gap;
- fits current WIP and consequence policy;
- can be completed or meaningfully advanced before morning;
- has a semantic acceptance test;
- does not require an ungranted owner-only checkpoint.

Good examples: improve HQ communication, close a known repair gap, build a reusable project template, prepare a researched decision brief, add a missing regression, build and test a candidate capability, or improve an actual owner workflow.

A surprise counts only if it produces a useful accepted artifact/outcome or a proven capability transition. Commits, cycles, PONGs and candidates alone do not count.

## 10. Long-horizon objective ladder

### Phase A — Kevin runs Kevin
- corrected autonomous selector/controller installed;
- first independent owner outcome;
- Self-Reliance Watchdog and Maintenance prove common repair families;
- Task Flow owns durable goal state;
- no-spin/WIP behavior proven across restarts;
- self-learning tool policy visible and controlled.

### Phase B — Kevin builds Kevin
- Capability Gap Generator live;
- isolated builder/reviewer harness live;
- Grok Build evaluated as one interchangeable builder;
- automatic eval creation from recurring incidents;
- Yellow Incubator operational;
- software-install and broad PC primitives built through candidate -> proof -> promotion.

### Phase C — Kevin works with Matt everywhere
- HQ direct private chat real round trip;
- Reader/research repeated proof;
- Gmail and Telegram real round trips;
- local speech/voice;
- phone adapter under fixed private-owner communication policy;
- mobile HQ and remote status/control with authenticated bounded actions.

### Phase D — General personal-computer worker
- representative Windows owner tasks end-to-end;
- browser workflows;
- apps/docs/files/media;
- install/configure approved software;
- coding/apps/games;
- strong recovery and durable continuity.

### Phase E — Specialized real-world goals
- Minecraft teammate adapter;
- bounded shopping/cart workflows and separately authorized purchases;
- owner business/economic programs;
- opportunity monitoring;
- richer voice/vision/media;
- additional specialists only when measurements justify their resource/coordination cost.

## 11. Autonomy scorecard

Track at minimum:

- eligible-backlog minutes spent idle (target approaches zero);
- useful owner outcomes per day/week;
- percent of goals Kevin starts without Bess dispatch;
- percent of known failures self-repaired;
- Bess interventions per accepted outcome;
- owner interventions excluding intentional approvals per outcome;
- T4/T5 responsibilities;
- capability gaps closed per week;
- recurring incidents converted into regression tests;
- reusable learned-skill replay success rate;
- candidate-to-production acceptance rate;
- builder rework/failure rate;
- accepted nightly-surprise rate;
- time from failure detection to verified recovery;
- percentage of engineering candidates built/reviewed without Bess hand-authoring.

The primary trend is **Bess intervention toward zero while real owner outcomes, reliability and capability breadth rise**.

## 12. Immediate order after the current live autonomy crossing

1. prove direct Gateway RPC and main-agent turn;
2. install Supervisor v1.8.3 + selector v1.1 and re-prove Benchmark;
3. require Kevin's first independently selected, semantically verified owner outcome;
4. prove continuation on the next scheduled cycle;
5. verify/install Self-Reliance Watchdog if absent or repair its detector if stale;
6. turn Skill Workshop self-learning on at the most autonomous scanner-gated mode justified by the installed runtime/tool policy;
7. move durable owner work to Task Flow;
8. cross HQ direct chat and Reader;
9. build typed software-install capability and evaluate Grok Build in isolation;
10. start Capability Gap Generator + nightly surprise standing program;
11. expand PC/browser primitives based on real owner goals;
12. continue transferring Bess lifecycle responsibilities until routine paths reach T4/T5.

## Non-negotiable truth rule

Kevin is not 'autonomous' because a scheduler runs, a model answers, a build passes, or a dashboard says working.

Kevin earns autonomy when he independently notices/chooses legitimate work, performs a real safe action, verifies the semantic result, recovers when needed, learns something reusable, preserves durable state, and continues without Bess performing a routine lifecycle step.