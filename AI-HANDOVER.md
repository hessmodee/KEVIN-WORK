# Kevin AI Engineering Handover

Reconciled 2026-09-02 after Matt completed the fixed:main context/compaction repair and explicitly directed all assisting engineers to keep Kevin moving, self-improving, self-repairing, work-conserving, and progressively independent of Bess/Grok/Matt.

**Canonical shared handover:** this file is the cross-AI engineering handover for Bess/ChatGPT, Grok Build, Grok Bot, and future replacement engineers. Enter through `KEVIN-START-HERE.md`. Read fresh runtime receipts before acting; fresh correlated evidence outranks this prose. After any substantive repair/proof/blocker/owner decision/production crossing/responsibility-transfer change, reconcile this file and the current task so Matt does not have to reconstruct the project from chat history.

Standing owner direction is codified in `docs/engineering/OWNER-CONTINUOUS-AUTONOMY-DIRECTIVE-2026-09-02.md`.

## North star

Kevin must independently:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> LEARN -> CONTINUE`

The objective is a persistent local Chief of Staff/system worker that does useful authorized work, continuously improves its own reliability/capability, learns from each repair, and progressively eliminates routine dependence on Bess, Grok Build, Grok Bot, and owner keyboard relay.

Idle-without-reason is a defect; spinning/busywork is also a defect. If one failure family is blocked or cooling, Kevin should select another independent useful authorized lane. Technical proof and T0-T5 responsibility transfer remain separate.

## Owner work zone

Matt has explicitly directed aggressive work in the GREEN and YELLOW development zones.

- Legitimately GREEN actions may proceed through existing proven/typed contracts without repeated permission requests.
- YELLOW capabilities should be researched, designed, simulated, staged, tested, proven, documented, and prepared rather than ignored.
- A YELLOW production effect still requires a bounded explicit reversible contract for that exact effect. This does not silently authorize money movement, purchases, live trading, credential acquisition, permission widening, safety weakening, arbitrary shell/remote code, or unapproved third-party/owner-representing sends.

The goal is maximum capability development inside real boundaries, not artificial caution and not artificial authority expansion.

## Current fixed:main truth — context/compaction repair

The owner reproduced the fixed:main OpenClaw auto-compaction/context failure on 2026-09-02 and completed two narrow validated configuration repairs.

Known preconditions preserved:
- main model: `ollama-chat-16k/qwen2.5:14b`
- configured provider/model context: 16384
- Ollama `num_ctx`: 16384
- `agents.defaults.compaction.reserveTokensFloor=2048`

Repair #1:
- added `agents.defaults.compaction.reserveTokens=2048`
- dry-run passed
- OpenClaw config validation passed with no warnings
- exact semantic diff from the pre-repair config was only the new reserveTokens leaf plus OpenClaw metadata timestamp
- pre-repair config SHA256: `215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84`
- post-repair-1 config SHA256: `DDC2A7227087C20CD761493F4A8B15189FAA9A12730EC22DED54EDE1A700C602`
- rollback backup: `~/.openclaw/backups/main-context-repair-20260902-131022/openclaw.json.before`

Repair #2:
- added `agents.defaults.compaction.keepRecentTokens=4000`
- preserved reserveTokens/reserveTokensFloor at 2048
- dry-run and full validation passed
- post-hardening config SHA256: `23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5`
- rollback backup: `~/.openclaw/backups/compaction-tail-repair-20260902-132325/openclaw.json.before`

Observed functional proof after the repairs:
- a fresh Kevin owner chat answered a direct identity question normally;
- `/context detail` showed the new session operating below the 16,384-token ceiling;
- manual `/compact` completed successfully rather than reproducing the earlier recovery failure.

This proves the immediate symptom is repaired enough to continue testing. It does **not** yet prove Kevin-owned self-repair or a complete causal model. Preserve the exact failure family and transfer the repair into Kevin's own detector/recovery path.

Durable teach-back was updated in `docs/engineering/LESSON-fixed-main-qwen-context-overflow-2026-09-01.md`.

## Current live health / expected R04 drift

Fresh Support at `2026-09-02T13:25:19-06:00` reported:
- governance OK;
- Support, HQ pulse, Supervisor and Maintenance intake scheduled jobs healthy;
- Maintenance `NO_MANIFEST`;
- Supervisor last result `NO_ELIGIBLE_MISSION`;
- Benchmark latest `29/30`, critical failures 1;
- only failing check: R04 `Production config frozen`.

The R04 failure is expected after the intentional validated `openclaw.json` mutation. The correct next action is to re-establish the production-config baseline through the governed baseline path and then require fresh Benchmark 30/30. **Do not revert the known-good compaction settings merely to match the old baseline, and do not weaken/skip R04.**

The old handover's 10:10 claim of Benchmark 30/30 is stale relative to this post-repair Support snapshot.

## Shared/current owner execution contract

`inbox/CURRENT_TASK.md` has been reconciled. The prior `write-proof / stop` instruction is retired by Matt's newer continuous-autonomy directive.

Current order:
1. close the intentional R04 baseline drift without undoing the context repair;
2. teach/transfer this failure family into a Kevin-owned detector + bounded recovery + semantic verifier;
3. if blocked/cooling, continue another useful authorized lane rather than idle;
4. prioritize Maintenance/self-repair ownership, autonomous work selection, skill development/replay, owner<->Kevin communication, mobile HQ, Telegram repair/replacement, memory/restart-replay, and lawful owner-value/economic-output workflows.

Default WIP remains 1 production/proof + 1 staging/eval + 1 research/design with a named consumer.

## Teach-and-transfer obligation

Outside repairs are incomplete until Kevin can own the next occurrence. For every meaningful Bess/Grok repair leave:
- failure family/capability gap;
- detection signal;
- bounded diagnosis;
- repair/avoidance procedure;
- preconditions/rollback;
- tests/evals/negative fixtures;
- exact proof/receipt/hash;
- durable lesson;
- remaining outside-engineer step to retire next.

Repeated Bess/Grok/Matt intervention is autonomy debt. Move each lane honestly through:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

The context repair is currently below T4 because diagnosis and owner terminal execution were still required.

## Existing runtime/control-plane facts to preserve

- Supervisor v1.8.8 remains the latest known installed Supervisor identity: `F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138`.
- Installed Maintenance runner latest observed identity: `3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E`.
- Published `control-plane/maintenance/kevin-maintenance-runner-v1.3.44.ps1` is **not proven equivalent** to that installed local runner. Do not overwrite the installed runner merely to gain a feature until exact source/provenance or a safe equivalent migration is proven.
- Latest known Forge identity remains `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A`.
- Latest known Benchmark runner identity remains `4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964`.
- The repository's governed work-order intake can run fixed GREEN verbs such as Benchmark, Support, reconcile, typed Maintenance, autonomy telemetry and OS Awareness; use established remote paths before asking Matt to type commands.
- Runtime convergence evidence from 10:34 MDT recorded local workspace policy hashes. Re-check fresh convergence before any exact-current runtime-policy replacement; do not assume repository source equals current installed bootstrap.

## Context-repair autonomy debt — required next engineering shape

Build/prove a fixed-input, fail-closed context-health capability that can:
1. detect the known auto-compaction/context failure family from protected metadata and/or explicit health signals;
2. read fixed main provider/model/context, `num_ctx`, `reserveTokensFloor`, `reserveTokens`, `keepRecentTokens`, config identity and validation state without exposing private config content;
3. distinguish known exact-precondition drift from unknown context causes;
4. when exact preconditions match, apply only the known bounded repair with backup, hash-CAS, dry-run, semantic-diff verification and rollback;
5. preserve the failed session/evidence before destructive reset;
6. prove a fresh normal fixed:main turn and successful compaction behavior;
7. re-establish R04 through the governed baseline path after intentional config acceptance;
8. require Benchmark 30/30 and fresh Support evidence;
9. record a reusable lesson/attempt family and avoid retry-budget reset by renaming;
10. later demonstrate Kevin independently noticing/selecting/executing/verifying this path.

Negative fixtures must reject unexpected model/context values, unknown reserve values, stale pre-change hashes, unrelated semantic config diffs, failed validation, missing rollback, and attempts to weaken Benchmark.

## Work-conserving campaign while P0/P1 is blocked

Useful independent lanes include:
- Maintenance self-ownership and exact installed-source/provenance recovery;
- Supervisor selector/work-conservation truth and anti-idle behavior;
- GREEN Skill Lab composite development and real-world replay;
- YELLOW candidate research/staging with named consumers and no protected crossing;
- mobile Kevin HQ and direct two-way owner chat;
- Telegram diagnosis/repair or a better supported private channel;
- durable memory, handoff, restart/replay, and postmortem learning;
- lawful economic-output labs and owner-value workflows using already-proven capabilities.

Do not resurrect cooled Forge rotation without demand. Do not treat worker count, heartbeat churn, cycle numbers, candidate creation, or renamed requests as accomplishments.

## Existing broader engineering debt

Preserve these prior findings unless newer evidence supersedes them:
- history/retry continuity remains a real autonomy debt; do not reset attempts through changing prose/fingerprints;
- Reader had meaningful proof but was not fully self-reliant; avoid reruns merely to refresh labels;
- owner chat/mobile, communications, Gmail/Telegram, memory, self-maintenance, Skill Lab, browser research, and business-value workflows remain master-scorecard lanes;
- CI-proven candidates are not installed proof;
- exact owner round-trip/restart/replay evidence must exist before claiming communication self-reliance;
- external skill/coding experiments such as local Ollama/Aider remain isolated research unless actually installed and proven.

## Safety/truth boundary

No arbitrary shell/remote-code transport, self-granted authority, secret/private-body publication, silent trust-anchor blessing, safety/verification weakening, purchases/trades/money movement, credential acquisition, permission widening, or unauthorized owner-representing third-party sends.

Do not confuse Matt's broad permission to push GREEN/YELLOW development with permission to fabricate evidence or bypass a real protected boundary. Use direct remote execution when an existing proven path exists; when it does not, build/prove the narrow path rather than offloading avoidable troubleshooting to Matt.

## What the next engineer should do immediately

1. Read `KEVIN-START-HERE.md`, the owner continuous-autonomy directive, this handover, and `inbox/CURRENT_TASK.md`.
2. Fetch fresh Support/Benchmark/Maintenance/control-plane/autonomy evidence and compare timestamps.
3. If R04 is still the sole regression, use or construct the narrow governed baseline-reconciliation path; preserve compaction settings and require fresh 30/30.
4. In parallel only within WIP, turn the context repair into a fixed-input detector/recovery candidate and regression fixtures; do not overwrite the unknown installed Maintenance patch.
5. When blocked, continue another useful authorized lane instead of stopping the program.
6. Reconcile this handover after the next substantive transition.
