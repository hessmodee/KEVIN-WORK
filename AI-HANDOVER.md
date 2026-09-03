# Kevin AI Engineering Handover

## Current HQ repair checkpoint — 2026-09-03T00:28:23.414Z

[Review](docs/engineering/KEVIN-HQ-REPAIR-REVIEW-2026-09-03.md) · [proof receipt](reports/engineering/hq-repair-20260903.json) · PR40/41/42 merged and deployed. Regional news publication is restored (16 stories, all categories, errors0); ticker no longer repeats the historical Reader E2E objective. HQ now separates fresh Supervisor selection from the old full audit, reports actual Benchmark degradation, and rejects stale/terminal worker activity. Served code matches tested bytes; the obsolete v1 asset-validation gate was repaired and passed.

Kevin completed `kevin-hq-newswire-worker-truth@1` at 2026-09-02T18:24:19.9591679-06:00; **seven** reported proven composites. Proof SHA256 `843AA39B242CD8BA05311A3243B3031AAF91501F63AFCC4EA41A64373C3D7989`. This is GREEN lesson delivery/T2, not mastery or a new T4/T5 transfer. Foreground publication-refresh and teaching requests are archived and retired.

Remaining P0: Benchmark29/30, sole R04; fixed:main effective tool access still unproved/owner-reported empty; Windows UI Bridge heartbeat still stale. Both newly uploaded files are exact older Maintenance v1.3.43/v1.3.32 sources, not installed `3CFC...B0D6E`. Obtain the current unsuffixed local Maintenance script before extending its typed path. An additional47 control-branch PowerShell blobs had no match. Installed autonomy bridge44EA... and actuator6C2D... sources are now hash-matched; refresh returned SUCCESS/AUTONOMY_UNCHANGED, which does not rerun the full audit. Preserve the16K chat repair, trust pins and three-attempt failure budget. No duplicate Reader canary or arbitrary alias substitution.

Reconciled 2026-09-02T23:46:21.872Z during Matt-directed foreground convergence work.

**Canonical shared handover:** this is the cross-AI engineering handover for Bess/ChatGPT, Grok Build, Grok Bot, Kevin-facing engineering automation, and future replacement engineers. Enter through `KEVIN-START-HERE.md`. Fresh correlated HESS-PC/OpenClaw evidence outranks this prose. Reconcile this file and `inbox/CURRENT_TASK.md` after every substantive repair, proof transition, blocker, owner decision, production crossing, rollback, or responsibility-transfer change so Matt never has to reconstruct the project from chat history.

Standing owner direction is codified in `docs/engineering/OWNER-CONTINUOUS-AUTONOMY-DIRECTIVE-2026-09-02.md` and `control-plane/OWNER-AUTHORIZATION-v1.md`.

## North star and operating doctrine

Kevin must progressively own:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> LEARN -> CONTINUE`

The goal is a persistent local Chief of Staff/system worker that performs useful authorized work, continuously learns and improves, repairs itself, develops GREEN capability, matures YELLOW candidates, and reduces routine dependence on Bess, Grok, and Matt's keyboard.

Idle-without-reason is a defect. Busywork/spin is also a defect. A blocked or cooled family is not permission to stop the whole program; Kevin should advance another independent useful authorized lane within WIP/resource bounds.

Technical proof and responsibility transfer remain separate:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

Every outside repair is incomplete until its detector, procedure, verifier, rollback, negative tests, lesson, and next autonomous invocation path are transferred into Kevin.

## Owner work zone

Matt explicitly authorizes aggressive work in GREEN and YELLOW development zones.

- Legitimately GREEN work may proceed through existing proven/typed contracts without repeated permission requests.
- YELLOW capabilities should be researched, designed, simulated, staged, tested, proven, documented, and prepared instead of being ignored.
- A YELLOW production effect still requires an exact bounded reversible contract for that effect.

This does not authorize arbitrary shell/remote code, money movement, purchases, live trading, credential acquisition, permission widening, safety weakening, secret/private-body publication, destructive non-Kevin user-data changes, or unapproved owner-representing/third-party sends.

## Current fixed:main truth — context/compaction repair is functionally restored

Matt reproduced the fixed:main OpenClaw auto-compaction/context failure and performed two narrow validated repairs on 2026-09-02.

Known-good owner-observed configuration:
- model `ollama-chat-16k/qwen2.5:14b`;
- provider/model context `16384`;
- Ollama `num_ctx=16384` verified live through `/api/ps`;
- `agents.defaults.compaction.reserveTokensFloor=2048`;
- `agents.defaults.compaction.reserveTokens=2048`;
- `agents.defaults.compaction.keepRecentTokens=4000`;
- post-hardening `openclaw.json` SHA256 `23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5`.

Repair #1 added explicit `reserveTokens=2048`. Pre-repair SHA was `215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84`; post-repair-1 SHA was `DDC2A7227087C20CD761493F4A8B15189FAA9A12730EC22DED54EDE1A700C602`. The exact semantic config diff was only the intended reserve leaf plus OpenClaw metadata timestamp. Rollback exists at `~/.openclaw/backups/main-context-repair-20260902-131022/openclaw.json.before`.

Repair #2 added `keepRecentTokens=4000`, preserved reserve/floor at2048, validated cleanly, and produced the current `23DA...A93A5` config. Rollback exists at `~/.openclaw/backups/compaction-tail-repair-20260902-132325/openclaw.json.before`.

Functional proof after repair:
- fresh owner session returned exact `KEVIN_OWNER_CHAT_OK`;
- normal owner conversation succeeded;
- `/context detail` showed approximately 8.3k / 16,384 context rather than fresh-session overflow;
- manual `/compact` completed successfully rather than looping/failing.

Therefore the immediate owner-chat context blocker is repaired. The old 09:00 rejected canary predates this repair and must not be treated as a post-repair failure. The repair is still below T4 because diagnosis and terminal execution required Bess/Matt.

Durable lesson: `docs/engineering/LESSON-fixed-main-qwen-context-overflow-2026-09-01.md`.

## P0 live blocker — Benchmark R04 intentional drift

Support at 17:39 MDT (Benchmark result at 17:02 MDT) reports:
- governance `ok=true`;
- listed Supervisor, Support, HQ pulse, and Maintenance Intake schedulers report zero consecutive errors; this is scheduler evidence, not end-to-end capability proof;
- Maintenance `NO_MANIFEST`;
- Benchmark **29/30, critical1**, with exactly one failed regression: R04 `Production config frozen`;
- Benchmark scheduler reports eight consecutive errors while R04 remains open.

This is expected stale-baseline drift after the intentional validated `openclaw.json` repair. Do not revert the good compaction settings merely to satisfy the old frozen hash and do not weaken/skip R04.

Required crossing: a narrow governed production-config baseline reconciliation that:
1. verifies exact current config SHA `23DA...A93A5`;
2. verifies the current baseline identity and expected old production-config anchor;
3. changes only the fixed R04 production-config anchor;
4. preserves every other baseline field/anchor exactly;
5. keeps an exact rollback copy;
6. runs fresh Benchmark and requires 30/30 critical0;
7. publishes fresh Support evidence;
8. rolls back if any invariant fails.

The inspected published Maintenance v1.3.44 / Intake v1.2.6 do not currently establish a general R04 production-config baseline operation. Historical Forge/Supervisor migrations are not substitutes. The installed Maintenance runner SHA `3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E` is an unpublished/unqualified local identity relative to the published runner; do not overwrite it merely to gain a feature until exact source/provenance or a safe equivalent migration is proven.

## R04 candidate repair and remaining production gate

PR39 is merged as `e57bf5b013bbbbad98a4c34b0e933c8d2912bfe5`. The candidate previously accepted missing Benchmark rows, failed to compare the baseline runner anchor, and could omit empty-container changes from its non-target fingerprint. It now validates all 30 distinct R01-R30 rows, strict verdict/count types, exact prior config and runner anchors, and complete non-target structure including literal keys. The real PowerShell predicate tests were extended too.

CI run `33696303871` passed for `a087abb1ef4030ea54f276b877daf3a6d8df2ad8`: 23 tests on Linux/Windows Python3.12/3.13 plus Windows PowerShell5.1 parser/self-tests. This is **CI-PROVEN CANDIDATE, NOT INSTALLED**. It does not close live R04.

Next production qualification must establish exact local baseline/config layout, fresh precondition evidence, transaction race/rollback behavior and a registered execution path. Version-pinned OpenClaw models distinguish required `contextWindow`, optional `contextTokens` and `params`; do not infer the installed values from the provider alias. Recover the exact local `kevin-maintenance-runner.ps1` with SHA `3CFC...B0D6E` before extending it; no supported generic source-export or R04 invocation operation has been established in the current bridge. Broad owner authorization does not create a missing technical connection.

## Fixed:main effective tools — genuine empty fresh-session inventory, not permission for broad tools

Fresh owner `/context detail` after the context repair reported:
- tool list 0 chars / 0 tools;
- tool schemas 0 chars / 0 tools;
- `Tools: (none)`.

That is real current-session evidence. Historical production Chat was intentionally tool-free/nearly-tool-free while Reader/action capabilities were isolated behind governed paths. The new autonomy objective requires a useful owner-intent/control surface, but **not** broad host authority.

Version-qualified OpenClaw `2026.7.1-2` findings:
- this installed version uses `agents.list[].tools.*` naming; newer docs often show `agents.entries.*`;
- tool resolution is layered: profile, global allow/deny, provider, per-agent, agent+provider, sandbox/channel/sender/plugin/model support; deny wins;
- `openclaw sandbox explain --agent main --json` exists in 2026.7.1-2 as a fixed read-only diagnostic surface;
- upstream issue #111570 reports 2026.7.1-2 channel workers may retain stale `agents.list[*].tools` policy after hot reload until a full Gateway restart, so CLI/fresh-session proof and channel proof must be distinguished;
- upstream issue #114065 reports agent-scoped allowlists in 2026.7.1-2 can leak built-in tool visibility, so protected-tool negative tests are mandatory after any policy change.

Do not set `tools.profile=coding`, broad `exec`, filesystem mutation, browser-submit, messaging, subagent spawn, or other protected surfaces merely to make tool count nonzero.

The desired first production-chat capability is the smallest surface that lets Kevin inspect safe state and create/update durable owner goals/tasks or invoke already-governed typed mechanisms while actual consequential execution stays behind the established control plane.

Before any mutation, obtain exact-current fixed read-only evidence for root/per-agent/provider/sandbox/channel/sender/plugin layers and prove the real session-effective inventory. Production acceptance requires exact config backup/hash, dry-run, semantic diff, validation, appropriate reload/restart for 2026.7.1-2, fresh session inventory, one allowed useful action, forbidden-tool negatives, Benchmark30/30, Support proof, and rollback.

Detailed record: `docs/engineering/KEVIN-TOOL-VISIBILITY-EVIDENCE-2026-09-02.md`.

## Context-repair autonomy debt — candidate is merged, not installed

PR37 `Candidate: fixed-main self-repair contract v1` was squash-merged into `main` at commit:

`0906b6f90e5e303f5e9dbda16dbf8f0b941135b1`

The merged-head proof run `33678067290` passed on Linux/Windows with Python3.12/3.13. The candidate includes deterministic/fail-closed configuration classification, exact compaction-contract checks, semantic leaf-diff verification, malformed-policy negatives, and authored tool-policy classification. It remains **candidate-only/uninstalled** and has no filesystem/network/process/OpenClaw mutation or authority expansion surface.

Do not refer to PR37 as open/unmerged. Any later branch-only commits that were not part of the merged PR are not production truth unless separately reviewed/merged.

Next transfer step:
1. qualify candidate field/layout assumptions against installed 2026.7.1-2;
2. build a fixed Windows/OpenClaw wrapper with exact config SHA, backup, dry-run, config validation, semantic diff and rollback;
3. bind the known repair only to exact preconditions;
4. include the governed R04 closeout;
5. prove fresh main reply, compaction and protected tool boundary;
6. seed/reproduce the failure in a safe test path and demonstrate Kevin selecting/executing/verifying the recovery without owner/Bess/Grok terminal relay.

Failure family remains `fixed_main_context_overflow_compaction_budget`; do not rename it to reset attempts.

## Current runtime/control-plane facts to preserve

Latest trustworthy known component identities:
- Supervisor v1.8.8: `F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138`;
- Maintenance runner: `3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E`;
- Forge: `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A`;
- Benchmark runner: `4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964`.

The governed work-order intake can run fixed GREEN verbs including Benchmark, Support, reconcile, typed Maintenance, autonomy telemetry, and OS Awareness. Prefer those remote paths over Matt acting as PowerShell transport.

Supervisor currently reports `NO_ELIGIBLE_MISSION`; autonomy has retained benchmark-not-pass/failure-budget evidence. This is not proof that Kevin's north star is complete. Work selection remains autonomy debt. Do not manufacture Forge rotation merely to look active; instead populate/recognize genuinely useful authorized work and prove scheduled selection/execution.

## Low-hanging truth/reliability debt

### HQ/dashboard context truth
An older repository helper hard-codes `8K` and `tools=false`, while owner `/context detail` proves the current main context ceiling is 16,384 and tool inventory is currently empty. The live dashboard publisher emits schema5 while the older repo helper emits schema3, so source provenance must be recovered before deployment. Do not overwrite the live publisher with the unproven helper. Fix the publisher once exact source identity is known so HQ derives context/tool truth from runtime evidence rather than constants.

### UI Bridge
The task is present and the installed hash still matches the known identity, but the Engineering snapshot reports a materially stale heartbeat. Hash/task presence is not live health. Existing typed restart ends by requiring Benchmark30/30; therefore close R04 first or prove a separate restart contract whose acceptance can complete without manufacturing a known Benchmark failure.

### Skill Lab replay preservation and lesson delivery
PR36 was merged at `354e74383f93182d2b92ea6ac0f6897d230c46cb` on 2026-09-02 23:27 UTC. Do not reopen/rebase completed source work. Production runner replacement still requires exact installed identity and the normal typed postconditions.

Engineering at 17:37 MDT reports five proven composites, including `kevin-context-recovery-teachback@1` at 17:32 MDT with proof `AA8ED5EE558A6A9A469FE804B57E3EEF7BD5472496043D50DCF2E31B43F4831C`. This establishes creation of the earlier lesson/drill files, not learner mastery or self-repair independence.

PR38 main-policy diagnostics merged at `7907d40b326c903e9307b5b1dd0044230971098b`; candidate collector still needs a registered read-only runtime path. It preserves PowerShell array cardinality and does not claim full effective tool resolution.

## Work-conserving backlog while P0 is blocked/cooling

Use independent WIP for:
- Maintenance/self-repair ownership and exact installed-source provenance recovery;
- durable retry/history preservation and work-selection correctness;
- GREEN Skill Lab composites, replay preservation, regression testing, and real-world reuse;
- YELLOW candidate research/design/staging with a named downstream consumer;
- private Matt<->Kevin communication, mobile HQ, Telegram diagnosis/replacement;
- memory/handoff/restart-replay/postmortems;
- Reader and bounded research/browser evidence lanes;
- lawful owner-value/economic-output workflows using already-proven capabilities.

Default WIP: 1 production/proof + 1 staging/eval + 1 research/design. Heartbeats, cycle counts, renamed requests, model turns, candidate generation and uninstalled code are not owner outcomes.

## Multi-writer coordination lesson

During this foreground convergence pass, the scheduled ChatGPT Chief Engineer concurrently updated `CURRENT_TASK.md` with stale/nonexistent PR37 branch information after PR37 had been merged. The scheduled process was temporarily paused to prevent further handover collisions.

Operational rule going forward:
- a foreground human-directed engineering session that intends to mutate the shared repo/handover should first pause the scheduled ChatGPT Chief Engineer;
- HESS-PC/Kevin local schedulers continue running;
- foreground session reconciles handover/current task and records any in-flight manifests/requests;
- only after the foreground mutation/proof crossing is complete should the scheduled Chief Engineer be re-enabled;
- never allow two outside AI writers to treat themselves as the canonical handover editor simultaneously.

`KEVIN-START-HERE.md` should preserve this coordination rule.

## Safety/truth boundary

No arbitrary shell/remote-code transport, self-granted authority, secret/private-body publication, silent trust-anchor blessing, safety/verification weakening, purchases/trades/money movement, credential acquisition, permission widening, or unauthorized owner-representing third-party sends.

Matt's broad direction to push GREEN/YELLOW development is not permission to fabricate evidence or bypass a protected boundary. Use an existing governed remote path when available; when it does not exist, build/prove the narrow path instead of offloading avoidable troubleshooting to Matt.

## Exact next execution order

1. Close R04 through a narrow exact-current governed baseline reconciliation and restore Benchmark30/30 without touching the known-good compaction settings.
2. Perform version-qualified fixed:main tool-policy diagnosis using fixed read-only surfaces; design the smallest owner-intent/control tool surface and prove allowed + forbidden behavior.
3. Qualify/extend the merged fixed-main self-repair candidate into an installable typed wrapper and prove the full self-repair chain.
4. After Benchmark is green, repair/prove the stale UI Bridge and fix HQ context/tool truth once live publisher provenance is recovered.
5. Qualify already-merged PR36/PR38 against installed source; continue GREEN Skill Lab reliability/replay and tool-policy diagnosis without duplicating completed source work.
6. Prove unattended scheduled selection of one real useful GREEN objective, semantic outcome, durable lesson, restart/replay, and a correct subsequent decision.
7. Continue owner communications/mobile/Telegram, memory, Reader, browser/research and business-value lanes within WIP when higher-priority families are blocked.
8. Reconcile this handover after each substantive transition.


## Foreground closeout 2026-09-02T23:53:36.643Z

Kevin completed `kevin-r04-evidence-and-tool-curriculum@1` at 2026-09-02T17:50:04.0975506-06:00; Engineering 2026-09-02T17:51:45.7063360-06:00 reports six proven composites. Proof SHA256 `C2DFEC282C5188AF5C3DAD31905F762CB9BF6E26D631099A36F51D7A3A52E53F`. Both create_text lessons were executed and verified by the existing local pipeline. This establishes delivered artifacts, not learner mastery or independent self-repair. The consumed request is archived/retired. See `reports/engineering/r04-tool-teachback-20260902.json`.

The existing hourly Kevin Chief Engineer was re-enabled after this foreground crossing with the updated checkpoint; no second scheduled engineer was created. Live R04/source/transport and main-tool-access gaps remain open. Required missing source: the exact installed `kevin-maintenance-runner.ps1`, SHA `3CFC...B0D6E`; all104 published PowerShell blobs were checked without a match.
