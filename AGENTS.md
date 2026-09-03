# Kevin Build — Universal AI Agent Rules

These rules apply to **every AI or coding agent working in this repository**, including ChatGPT, ChatGPT Work, Grok, Grok Build, Grokbot, Kevin, Codex-style agents, and future replacement agents.

## Mandatory bootstrap

Before substantive Kevin work:

1. Read `AI-HANDOVER.md` — the **one canonical human current handover**.
2. Read `KEVIN-START-HERE.md` and `inbox/CURRENT_TASK.md`.
3. Read fresh `reports/support-latest.json` and `reports/engineering/latest.json` plus the narrowly relevant runtime/autonomy evidence.
4. Inspect relevant open PR/CI state.
5. Compare timestamps, hashes, proof levels, in-flight work and blockers. Fresh correlated HESS-PC evidence outranks prose.

Do not ask Matt to reconstruct history already available through these shared artifacts.

## One handover only

`AI-HANDOVER.md` is the only human current handover. Do not create competing dated, agent-specific, or alternate current handover files. `reports/handoff-latest.json` is only its machine-readable twin.

Universal access:

- `https://github.com/hessmodee/KEVIN-WORK/blob/main/AI-HANDOVER.md`
- `https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/AI-HANDOVER.md`
- `https://hessmodee.github.io/KEVIN-WORK/handover.html`

## Cross-AI / local-machine convergence

Repository/source truth and HESS-PC runtime truth are separate planes.

- Repository/source truth: durable source, procedures, current task, PR/CI and public-safe receipts.
- HESS-PC runtime truth: installed hashes, configuration, scheduled tasks, heartbeats, local files and real semantic/visible outcomes.

**Local-only durable work is unfinished work.** If Grokbot or another desktop-local agent changes HESS-PC, it must publish the corresponding durable source/configuration intent and sanitized evidence/receipt to this shared repository after the bounded crossing. Never leave the only useful copy in local files, a terminal, a desktop agent session, or chat context.

Conversely, a GitHub commit, PR, build or CI pass is not installed production until fresh HESS-PC evidence proves installation and the real postcondition.

Before shared durable source changes, re-read/pull current `main`, work on a branch when practical, and reconcile concurrent movement before merge. Unexplained repository/runtime divergence is a defect to investigate, not something to silently bless.

## Continuous checkpointing

Do not wait for the end of a conversation. Token, credit, browser, model and agent sessions can end abruptly.

After every material repair, proof transition, production install/rollback, owner decision, blocker/priority change, responsibility-transfer change or substantial durable artifact:

1. publish durable source and/or sanitized proof;
2. update `inbox/CURRENT_TASK.md` when the objective or next boundary changed;
3. allow the canonical handover automation to reconcile `AI-HANDOVER.md`;
4. continue only after the shared state is recoverable by a replacement agent.

## Single outside writer

Only one outside AI writer should mutate shared Kevin repository/control-plane state at a time. Do not compete with an active foreground/scheduled outside engineer. Kevin's already-qualified local schedulers may continue within their existing authority.

## GREEN / YELLOW execution discipline

Owner standing authorization covers legitimate GREEN work. Execute GREEN actions through already-qualified typed, bounded, observable mechanisms without repeatedly asking permission. YELLOW work may be researched, designed, built, tested, adversarially reviewed and staged, but it does not self-promote across a protected production boundary.

Do not convert natural-language intent into arbitrary shell/code execution. Do not widen authority by relabeling a new action GREEN. Preserve bounded retries, failure-family cooldown, rollback where applicable, and independent semantic postcondition verification.

## Proof boundaries

Never collapse:

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

Responsibility transfer:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

Task presence, hashes, generated files, heartbeat churn, CI, model claims or `PASS` text alone do not prove a real owner outcome.

## Authority / privacy

Do not widen Kevin into arbitrary shell, arbitrary executable/path/argument control, unrestricted filesystem access, credential access, permission changes, arbitrary downloads/installs, owner-representing sends or other protected effects merely to make development easier.

Never publish passwords, API/OAuth tokens, recovery codes, credentials, private message bodies, sensitive local documents or other private data to this public repository.

## Completion standard

A replacement AI should be able to receive only this instruction from Matt:

**Resume Kevin from the canonical GitHub handover.**

and continue correctly without Matt retelling the project.
