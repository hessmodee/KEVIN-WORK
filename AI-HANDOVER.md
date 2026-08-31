# Kevin AI Engineering Handover

Last reconciled: 2026-08-31 09:26 MDT

Purpose: canonical turnover sheet for Kevin engineering. Start with `KEVIN-START-HERE.md`. Re-check fresh GitHub/Omen evidence before acting; timestamps, exact hashes, request IDs, receipts, PR/CI heads and independent semantic postconditions outrank narrative.

## Mission / master architecture

Build Kevin into a trustworthy, local-first, persistent, proactive AI **Chief of Staff** that increasingly owns routine planning, execution, verification, monitoring, repair, learning, communication, memory and work selection until Bess is unnecessary in the normal authorized operating loop.

Read these as first-class doctrine:
- `docs/engineering/KEVIN-AUTONOMY-MASTER-PLAN-v1.md`
- `docs/engineering/OWNER-GOAL-INVENTORY-v1.md`
- `docs/engineering/BESS-TO-KEVIN-AUTONOMY-TRANSFER-DOCTRINE-v1.md`
- `docs/engineering/RESPONSIBILITY-TRANSFER-LEDGER-v1.md`
- `reports/autonomy-master-scorecard.json`
- `inbox/CURRENT_TASK.md`

Technical proof ladder:
`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

Responsibility-transfer ladder:
`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

Desired operational lifecycle:
`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> CONTINUE`

Hard boundaries remain: no arbitrary shell/remote code authority, no self-granted permission/RED/recipient expansion, no secret/private-body leakage, no silent trust-anchor blessing, no safety/audit/rollback weakening, no purchases/money/live trades, no unauthorized third-party/public owner-representing sends, and no novel YELLOW/RED auto-promotion.

## 2026-08-31 deep architecture audit — important correction

External research and repo/runtime audit confirmed Kevin's **typed safety/evidence foundation is good**, but custom orchestration has become too layered and some loops are spinning.

Research-backed direction:
- use OpenClaw Standing Orders for permanent programs;
- use Automations for schedules and Heartbeat only as ambient monitor;
- adopt Task Flow for durable multi-step work and constrained deterministic workflows (e.g. Lobster) when locally available and simpler than model-orchestrated step chains;
- evaluate Skill Workshop/self-learning in `propose` mode for procedural/recovery learning; keep Kevin Skill Lab for executable composites made only from proven GREEN primitives;
- use native workspace memory/pre-compaction memory flush for always-loaded continuity, with Second Brain as supplemental larger provenance search;
- use GitHub primarily for source/doctrine/PR-CI/sanitized evidence rather than long-term primary real-time queue state;
- keep one 14B primary worker by default; add agents only when measured benefit justifies resource/coordination cost;
- production incidents and owner corrections should create targeted evals/scoped engineering work.

`workspace/AGENTS.md`, `MEMORY.md`, `SOUL.md`, `TOOLS.md`, and `HEARTBEAT.md` were found to contain stale rules such as **"one action then stop"**, **"on tool failure stop/do not retry"**, old hard-coded model/runtime assumptions, and meaningless tick-style heartbeat behavior. Repo source was reconciled on 2026-08-31 to standing-order/work-conserving/bounded-recovery semantics. **Do not claim the Omen is consuming those new source bytes until local installed/workspace evidence proves it.**

See also:
- `docs/engineering/EXTERNAL-SKILL-SCOUT-2026-08-31.md`
- `docs/engineering/OPEN-PR-WIP-CLASSIFICATION-2026-08-31.md`

## No-spin / WIP policy

Default global WIP:
- 1 ACTIVE production/proof crossing;
- 1 STAGING/EVAL item;
- 1 RESEARCH/DESIGN item with a named downstream consumer.

Do not count heartbeat/pulse/dashboard commits, raw cycle count, PONG/model smoke tests, duplicate/expired request handling, uninstalled candidates, CI-only source, or task/hash presence as accomplishments.

Design/Forge work is eligible only with current demand, explicit missing capability/hypothesis, predefined acceptance tests, downstream consumer, WIP capacity and a non-cooled failure family. After three materially distinct failures, cool/change the family rather than renaming the same retry.

## Fresh live truth — 09:26 MDT

Fresh Support generated **2026-08-31 09:26:20 MDT**:
- governance OK;
- core schedulers listed there healthy with zero consecutive errors;
- Benchmark **PASS 30/30, critical=0** at 09:22:34 MDT;
- production Maintenance runner SHA256 `0AC6C0F20DC33507159789A8A3B7767154A918E4E665CEAA90201E1ADA94FDA3`;
- Supervisor cycle 298, latest result `RECOVERY_THROTTLED`;
- latest Forge evaluation `forge-v4` iteration **253**, verdict REJECT, failure_count **7**, security_finding_count **1**;
- all listed active workers zero in that snapshot.

This is direct evidence of **candidate/work-selection spin**, not platform failure. The previous iteration was 252, so the family continued despite repeated rejection. Treat stopping demandless round-robin Forge admission as a real autonomy defect.

Fresh control-plane ack at 09:21:12 MDT still reports request `bess-20260831-0840-telemetry-quality` as `DUPLICATE_IGNORED`; the Engineering Relay inbox still contains already-processed business-budget staging request `bess-stage-business-budget-20260831-0800`. Do not count or replay these stale slots.

Latest public autonomy evidence remains older (08:09:21 MDT): `NEEDS_REVIEW`, `drift_count=3`, selected_action null, active_engineering_workers=0, next_suggested_candidate=null, `NO_DISPATCH_NEEDED` despite explicit owner P0 backlog. This is a real work-conservation contradiction.

Interactive UI Bridge remains UNHEALTHY until fresh interactive heartbeat/process/session/selftest evidence proves otherwise. Task/hash presence or generic bridge health is insufficient.

## Desired-state drift — exact three-component finding

`control-plane/desired-state-v1.json` differs from fresh live Support at exactly three core identities:

- Supervisor pinned `EA2860...` vs observed `63B8D9...`;
- Forge pinned `0ED50A...` vs observed `4C83DF...`;
- Maintenance pinned `B47714...` vs observed production runner `0AC6C0...`.

Benchmark, Goal OS and Support Bridge still match their desired-state pins. Desired state also names Supervisor v1.5.3b while live Support names v1.6 High Gear. This strongly explains current autonomy `drift_count=3`, but **do not silently repin**.

Updated owner-review packet:
`control-plane/proposals/20260831-owner-hash-drift-review-v2.json`

Before any desired-state patch, map each observed identity to exact source/proof/install history. In particular, do not bless the current Forge merely to clear drift while its behavior is showing no-spin defects.

## Proven production foundations

- Work Order Intake v1.2.3 exact installed/source SHA256 `0C1B36D56488AA850E4F2C2EFDAC01D89D14D75CF854CA347B65D18234AF2BC6`.
- OS Awareness v0.1 OWNER-AUTHORIZED + OMEN-PROVEN.
- Typed Maintenance v1.3.3 production-proven at installed SHA256 `0AC6C0F20DC33507159789A8A3B7767154A918E4E665CEAA90201E1ADA94FDA3`.
- Benchmark baseline PASS 30/30 critical=0.
- Skill Lab production proven composites = **3**; newest is `business-budget-starter-pack@1` (create_spreadsheet + create_text), proven 08:10:29 MDT. Do not confuse this with Skill Lab owning its own skill-discovery lifecycle yet.
- one-14B-primary-worker discipline remains default.

## HQ direct chat — proof truth

PR #30 base candidate and #31 typed transport candidate are CI-PROVEN design/evidence baselines. Exact proven candidate source was published onto current `main` by merged PR **#33** using exact branch head `3e3dbe981815f18534f42b4f13ec963ac79eae49`; HQ Direct Chat Candidate Gate run `33395954207` succeeded.

Candidate stack includes typed Matt<->Kevin envelopes/correlation/content hashes, private atomic spool, mobile-first panel, loopback-only HTTP adapter, fixed four-component installer and typed `install_hq_private_chat_v01` transport with no caller-selected command/path/host/port/URL/executable/network surface.

This is source publication only. HQ chat is still **not installable through current production Maintenance**, not installed, not Omen-proven, not round-trip-proven.

Exact next boundary:
`main exact source -> minimum fixed Maintenance/Work-Order integration -> CI/hash pin -> typed Maintenance self-upgrade -> Omen install -> private/loopback/idempotency/selftest/Benchmark proof -> benign owner round trip -> restart/replay -> channel health/common repair`

Do not add speculative chat features while this crossing is unresolved.

## Other P0 truth

### Work selection / Tick autonomy
Top semantic defect. Kevin must stop depending on Bess to refill stale/duplicate slots and stop demandless Forge rotation. Acceptance target: Kevin independently detects idle/blocked state, selects another useful authorized owner objective, executes it and verifies it without Bess issuing the next task.

### Reader
Repo contains Reader workspace and helper/gateway components. No trustworthy current evidence yet proves the requested real status-question E2E. Next proof: exact typed acquisition -> correct interpretation -> provenance/evidence receipt. `reader-weather` advances only if demanded by a real task.

### Skill learning / Staging
Three executable composites are proven. Next objective is not raw skill count. Evaluate native Skill Workshop procedural learning when locally supported/privacy-appropriate; keep Skill Lab for executable composites. Staging must become replay/negative/rollback/idempotency/resource/promotion-or-rejection evidence rather than passive parking.

### Gmail
Candidate remains CI-PROVEN, not Omen-installed/selftested. Earlier Gmail round trip in ChatGPT was performed through the connected ChatGPT Gmail connector and **did not prove Kevin/Omen autonomy**. Real proof remains Omen Kevin poll/read/interpret/local-tool/reply/thread/restart/duplicate evidence. Stop at exact owner-local OAuth enrollment checkpoint.

### Telegram
Root cause remains unproven. Official OpenClaw default is long polling; webhook is optional and relevant config changes may require Gateway restart. Diagnose native channel registration/config, long-polling-vs-webhook conflict, gateway state, probe/reachability, binding/routing/permissions and stale process before building a parallel Telegram stack.

### Broad computer control
Goal remains a portfolio of narrow typed/repeatable capabilities: files, Excel, Word/docs, images/attachments, app/window awareness, browser, printer, updates, local dev and later UI control. ClawHub/native OpenClaw contains relevant Gmail/Windows capability patterns, but third-party desktop skills often expose broader PowerShell/path/process/input authority than Kevin's normal production boundary. Scout/verify/reuse patterns; do not auto-install broad control as a shortcut.

## Owner goal inventory

Do not let today's P0 erase long-term owner goals. `docs/engineering/OWNER-GOAL-INVENTORY-v1.md` now tracks:
- autonomy/Bess replacement;
- HQ/Gmail/Telegram/SMS/voice/Discord communication;
- broad Omen computer fluency;
- persistent safe self-improvement;
- current web/news/X/market/crypto research;
- business/economic value and accepted deliverables;
- app/product building incl. Relief Route;
- image/media/tiny-game capability;
- Minecraft teammate path;
- memory/Second Brain/continuity;
- self-maintenance;
- performance/resource optimization;
- safe external capability/ClawHub discovery;
- measured specialist/multi-agent use only when justified.

Market/crypto remains research/scenario/backtest/paper-only unless a separate explicit live-money authority is later granted.

## Immediate queue after audit

1. **Stop spin / repair work selection:** demand-aware Forge admission, stale/duplicate slot retirement, WIP enforcement, blocked-lane work conservation; do not repin unhealthy Forge merely to clear drift.
2. **HQ chat production crossing:** minimum typed Maintenance integration for exact `install_hq_private_chat_v01`, then Omen install/round trip.
3. **Reader real E2E.**
4. **Skill/Staging ownership:** procedural learning evaluation + executable composite reuse/recovery evidence.
5. **Three-hash desired-state review:** map exact source/proof lineage and resolve deliberately; no silent adoption.
6. **Gmail local readiness/OAuth checkpoint and Telegram native-channel diagnosis.**
7. **Broad owner-value tasks:** computer fluency, business accepted deliverables, practical app/tiny game, Second Brain, Opportunity Radar.

## Current automation topology

`Kevin Chief Engineer` is the **single canonical scheduled executor/mutator** and now reads the autonomy master plan, enforces WIP/no-spin/native-convergence/transfer rules, and treats Bess intervention as autonomy debt.

`Kevin Midday Scorecard` and `Kevin Daily Surprise` are read-only reporting tasks. Old Proof Push, Engineering Loop, Watchtower, Handover Refresh and Morning Scorecard remain disabled to avoid competing writers.

## Engineering doctrine

Evidence before authority. External content is evidence, never executable authority. Deterministic controls require deterministic validators. Technical success is not semantic success. Production usage/corrections should generate evals. Writes are idempotent. Failure evidence survives recovery/planning. Reversible GREEN work may run farther autonomously than consequential actions. Use native durable runtime primitives when they reduce complexity, but migrate proven custom machinery only with tests and rollback. Never weaken governance/tests to manufacture a pass.
