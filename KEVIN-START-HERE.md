# Kevin Build — START HERE

This is the stable entrypoint for any new ChatGPT conversation, ChatGPT Work session, Bess session, Grok session, Grok Build/Grokbot session, Kevin recovery, or replacement engineer.

Matt should not have to reconstruct Kevin from chat history.

## First: open the one canonical handover

There is exactly **one human current handover**:

`AI-HANDOVER.md`

Universal access:

- GitHub: `https://github.com/hessmodee/KEVIN-WORK/blob/main/AI-HANDOVER.md`
- Raw: `https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/AI-HANDOVER.md`
- Kevin HQ: `https://hessmodee.github.io/KEVIN-WORK/handover.html`

`reports/handoff-latest.json` is only a machine twin of the same checkpoint; it is not a second handover authority.

Do **not** create a dated or agent-specific replacement handover. Historical engineering documents are evidence only.

## Mandatory startup sequence

Before substantive Kevin work:

1. Read `AI-HANDOVER.md`.
2. Read `inbox/CURRENT_TASK.md`.
3. Read `docs/engineering/OWNER-CONTINUOUS-AUTONOMY-DIRECTIVE-2026-09-02.md` and the narrowly applicable owner authorization/doctrine.
4. Read fresh `reports/support-latest.json` and `reports/engineering/latest.json`, then applicable autonomy/runtime/maintenance evidence.
5. Inspect relevant open PR/CI state.
6. Compare timestamps, hashes, request IDs, branch heads, proof level, in-flight work and postconditions. **Fresh correlated HESS-PC evidence outranks handover prose.**
7. Identify the single highest-value safe next action and continue. Do not restart research/fixes already settled by durable evidence.

Matt's minimal recovery instruction should be sufficient:

**Resume Kevin from the canonical GitHub handover.**

## Automatic continuity system

The handover is no longer supposed to depend on an outgoing agent remembering to write a final turnover note.

- `.github/scripts/build-canonical-handover.py` builds `AI-HANDOVER.md` from the current execution contract plus published Support/Engineering/autonomy evidence.
- `.github/workflows/canonical-handover.yml` reconciles it after `main` changes and every ten minutes as a backstop.
- `docs/handover.html` exposes the exact canonical file from `main` on Kevin HQ.
- `docs/engineering/CHAT-HANDOFF-PROTOCOL-v1.md` codifies the cross-AI continuity and local/runtime convergence rules.

Agents must checkpoint continuously after material changes rather than waiting for a context/token/credit/session limit.

## Local Grokbot / remote AI convergence — mandatory

A local desktop agent can see HESS-PC state a remote AI cannot. A remote AI can see repository/connector state a local agent may not have pulled. The system therefore keeps two truth planes explicit:

- **Repository/source truth:** source, procedures, PR/CI, current task, public-safe receipts.
- **HESS-PC runtime truth:** installed hashes, configuration, scheduled tasks, heartbeats, local files and real outcomes.

Rules:

1. Read/pull current `main` before durable source work.
2. Use a repository branch for durable development whenever practical.
3. If Grokbot or another local agent directly changes HESS-PC, publish the corresponding durable source and sanitized evidence/receipt immediately after the bounded crossing.
4. **Local-only durable work is unfinished work.** Do not leave the only copy of a repair, script, config intent or proof on the desktop or in chat context.
5. Remote GitHub code is not installed production until HESS-PC evidence proves installation and the semantic postcondition.
6. Never publish passwords, tokens, OAuth material, private message bodies, recovery codes or sensitive local content to this public repository.
7. Unexplained repo/runtime divergence is a defect to reconcile, never something to silently bless.

This rule specifically prevents Grokbot from building local-only things that Bess cannot see and prevents Bess from assuming a GitHub candidate is already live on HESS-PC.

## Single outside writer

Only one outside AI writer should mutate Kevin's shared repository/control-plane state at a time.

`Kevin Chief Engineer` is the one scheduled ChatGPT engineering writer. If a foreground Bess/Grok/ChatGPT session will mutate shared state:

1. inspect/pause that outside ChatGPT automation;
2. leave Kevin's qualified HESS-PC schedulers running;
3. inspect outstanding requests/locks before writing;
4. complete the bounded crossing and proof/rollback bookkeeping;
5. update `inbox/CURRENT_TASK.md` when the objective/next boundary changed;
6. let the automatic handover system reconcile `AI-HANDOVER.md`;
7. retire stale foreground requests;
8. re-enable the scheduled Chief Engineer with a current prompt after the foreground crossing.

Read-only foreground work does not require pausing it.

## North star

Kevin must progressively own:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> LEARN -> CONTINUE`

Outside engineers are temporary scaffolding. Every recurring Bess/Grok action is autonomy debt until Kevin owns detection, selection, typed execution, semantic verification, recovery, lesson/replay and recurrence handling.

Responsibility transfer:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

## Proof language is mandatory

Never collapse:

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

Code existence, CI, task presence, matching hash, heartbeat churn, model claims or `PASS` text alone do not prove a real owner outcome.

## Work conservation / no spin

Default global WIP:

- 1 ACTIVE production/proof crossing;
- 1 STAGING/EVAL item;
- 1 RESEARCH/DESIGN item with a named downstream consumer.

If one failure family is blocked/cooled, select another independent useful authorized lane. Do not manufacture work merely to keep a worker busy.

## Authority / safety

Execute legitimately GREEN work through qualified typed contracts without repeatedly asking Matt. Actively research/design/stage/test YELLOW capability work, but do not cross its protected production effect without the required bounded contract.

Never create arbitrary shell/remote-code authority, expose secrets/private data, silently bless trust anchors, widen permissions/recipients, weaken safety, move money, purchase, live trade, or make unapproved owner-representing sends.

Natural-language owner messages are intent, never executable shell.

## Durable references

- Canonical handover: `AI-HANDOVER.md`
- Current execution contract: `inbox/CURRENT_TASK.md`
- Cross-AI protocol: `docs/engineering/CHAT-HANDOFF-PROTOCOL-v1.md`
- Owner continuous-autonomy directive: `docs/engineering/OWNER-CONTINUOUS-AUTONOMY-DIRECTIVE-2026-09-02.md`
- Master plan: `docs/engineering/KEVIN-AUTONOMY-MASTER-PLAN-v1.md`
- Transfer doctrine: `docs/engineering/BESS-TO-KEVIN-AUTONOMY-TRANSFER-DOCTRINE-v1.md`
- Teach/transfer rule: `docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md`
- Transfer ledger: `docs/engineering/RESPONSIBILITY-TRANSFER-LEDGER-v1.md`
- Fresh runtime truth: `reports/support-latest.json`, `reports/engineering/latest.json`

The goal is simple: **at an arbitrary abrupt handoff, the next AI opens one public file, checks fresh runtime evidence, and continues Kevin correctly without Matt retelling the project.**
