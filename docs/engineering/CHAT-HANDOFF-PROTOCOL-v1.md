# Kevin Cross-AI Handover Protocol v2

Purpose: guarantee that Matt can replace ChatGPT, ChatGPT Work, Grok, Grok Build, Grokbot, Kevin, or another engineering agent without rebuilding Kevin's state from chat history.

## One handover, permanently

There is exactly **one human current handover**:

`AI-HANDOVER.md`

Do not create a new dated/current handover when an agent changes. Historical engineering/audit documents may exist as evidence, but they must never compete with `AI-HANDOVER.md` as the current turnover surface.

`reports/handoff-latest.json` is only the machine-readable twin of the same checkpoint. It is not an independent authority.

Universal public access:

- GitHub: `https://github.com/hessmodee/KEVIN-WORK/blob/main/AI-HANDOVER.md`
- Raw text: `https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/AI-HANDOVER.md`
- Kevin HQ: `https://hessmodee.github.io/KEVIN-WORK/handover.html`

## Automatic refresh

`.github/scripts/build-canonical-handover.py` rebuilds the handover from the current execution contract and published runtime evidence.

`.github/workflows/canonical-handover.yml` runs:

- after changes land on `main`;
- every ten minutes as a reconciliation backstop;
- on manual dispatch;
- as a pull-request validation gate for the handover machinery itself.

The workflow writes only the canonical `AI-HANDOVER.md` and its machine twin, uses bounded retry on concurrent `main` movement, and does not create churn when source evidence is unchanged.

Fresh correlated HESS-PC/OpenClaw evidence always outranks generated prose.

## Mandatory material-change checkpoint

Because model sessions, credits, token windows, browsers and apps can end without warning, **checkpoint continuously instead of waiting for an end-of-chat handoff**.

After every material repair, proof transition, production install/rollback, owner decision, blocker change, task-priority change, responsibility-transfer change, or substantial new source artifact:

1. publish the durable source/receipt to `hessmodee/KEVIN-WORK`;
2. update `inbox/CURRENT_TASK.md` when the execution objective/next boundary changed;
3. allow the canonical handover workflow to reconcile the shared handover;
4. never leave the only useful explanation in chat context.

## Local Grokbot / HESS-PC convergence rule

A local desktop agent can see machine state that a remote agent cannot. A remote agent can see repository/connector state that the local agent may not have pulled. Neither plane is sufficient alone.

**Repository/source truth** includes reviewed source, procedures, PR/CI, owner execution contract and public-safe receipts.

**HESS-PC runtime truth** includes installed hashes, configuration state, scheduled tasks, heartbeats, local files and visible/semantic outcomes.

The convergence contract is mandatory:

1. Before substantive source work, read/pull current `main` and `AI-HANDOVER.md`.
2. Develop durable source on a repository branch whenever practical.
3. If testing requires a direct local production/runtime change, publish the corresponding source and a sanitized result/receipt immediately after the bounded crossing.
4. **Local-only durable work is not complete.** No AI may say a repair/capability is complete while its only copy exists on HESS-PC or only in its chat/session.
5. Do not publish secrets, credentials, private message bodies, recovery codes or sensitive local content merely to achieve convergence.
6. A remote repository change is not an installed production change until fresh HESS-PC evidence proves installation/postconditions.
7. An unexplained local/runtime hash or behavior that differs from repository source is drift to reconcile, not something another agent may silently bless.

This prevents a Grokbot-only build from becoming invisible to Bess and prevents a Bess-only GitHub build from being mistaken for something already installed on HESS-PC.

## Incoming AI procedure

A replacement AI should not ask Matt for a project recap until it has attempted the durable bootstrap itself:

1. Read `AI-HANDOVER.md`.
2. Read `KEVIN-START-HERE.md` and `inbox/CURRENT_TASK.md`.
3. Read fresh `reports/support-latest.json` and `reports/engineering/latest.json` plus relevant autonomy/runtime receipts.
4. Inspect relevant open PR/CI state.
5. Compare timestamps, hashes, request IDs, proof levels, branch heads and in-flight work.
6. Identify the highest-value safe next action and continue from there.
7. Do not recreate old fixes, reuse expired requests, overwrite another writer's active work or infer production from CI.

Matt's minimal instruction should be enough:

**Resume Kevin from the canonical GitHub handover.**

## Single-writer coordination

Only one outside AI writer should mutate shared Kevin repository/control-plane state at a time. A foreground Bess/Grok/ChatGPT engineering session should pause the scheduled outside `Kevin Chief Engineer` before shared mutations, leave Kevin's HESS-PC schedulers running, reconcile the crossing, and re-enable the scheduled Chief Engineer afterward.

This rule does not prevent Kevin's own qualified local schedulers from running.

## Proof boundaries

Technical proof:

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

Responsibility transfer:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

A handover must preserve these distinctions. CI success is not production installation; task/hash presence is not semantic health; an agent's statement is not postcondition evidence.

## Privacy boundary

The repository is publicly accessible so replacement agents can reach it. Therefore public continuity artifacts must contain sanitized engineering state only. Never include passwords, API/OAuth tokens, recovery codes, private email/message bodies, credential material, private local documents, or other sensitive content.

## Failure mode

If the automatic handover workflow is failing, continuity itself becomes a P0 infrastructure defect. Repair it before relying on chat context. The previous valid `AI-HANDOVER.md` remains the fallback, with fresh runtime evidence used to correct stale claims.

## Success criterion

At any arbitrary moment — including an abrupt model/session/token/credit cutoff — a new agent can open one public file, reconstruct Kevin's current mission and proof boundaries, inspect fresh machine evidence, see what remains next, and continue without Matt retelling the project.
