# Kevin Chat Handoff Protocol v1

Purpose: make ChatGPT context-window transitions, deleted-chat recovery, new-model turnover, and engineering handoff **fast, deterministic, evidence-first, and low-friction for Matt**.

## Why `AI-HANDOVER.md` alone is not enough

`AI-HANDOVER.md` is the canonical narrative turnover sheet, but a narrative file can be stale, can grow large, and cannot by itself prove what is live on the Omen at the moment a new chat begins. A clean transition therefore needs four layers:

1. **Stable entrypoint** — `KEVIN-START-HERE.md` tells every new AI exactly what to read and in what order.
2. **Narrative state** — `AI-HANDOVER.md` explains the current engineering truth, proof levels, decisions, blockers, and exact next boundary.
3. **Execution contract** — `inbox/CURRENT_TASK.md` captures the owner's current goals and priority order independently of chat history.
4. **Fresh evidence** — Support, Dashboard, control-plane, Engineering Relay, autonomy, Skill Lab, Maintenance, Benchmark, PR/CI, and receipts determine what is actually current.

A fifth optional layer, `reports/handoff-latest.json`, provides a compact machine-readable checkpoint to accelerate reconstruction; it never overrides fresher source evidence.

## Trigger conditions

Perform a handoff checkpoint when any of these occurs:

- the current ChatGPT conversation is getting long or close to a context limit;
- Matt says he is starting a new Kevin chat;
- a model/session is being replaced;
- substantive capability proof changes (for example CI-PROVEN -> INSTALLED or OMEN-PROVEN);
- a production promotion/rollback occurs;
- a new owner authority boundary or credential checkpoint is established;
- a major blocker/root cause is isolated;
- a scheduled executor/automation topology changes;
- important chat history is deleted or unavailable.

Do **not** wait for a catastrophic context failure if a clean checkpoint can be written beforehand.

## Outgoing AI procedure

Before turnover, the outgoing AI should:

1. Read the newest trustworthy evidence relevant to active P0/P1 work.
2. Reconcile `AI-HANDOVER.md` so current truth replaces stale/contradictory statements instead of accumulating append-only history.
3. Confirm `inbox/CURRENT_TASK.md` still represents Matt's latest objective.
4. Refresh `reports/handoff-latest.json` if that artifact is in use.
5. Record exact identities where relevant: SHA256, Git commit, branch, PR number/head, workflow run/result, request ID, idempotency key, receipt, installed identity, timestamp, Benchmark result, and proof level.
6. Explicitly separate:
   - proven production truth;
   - current in-flight work;
   - CI/candidate-only work;
   - blocked/cooled failure families;
   - owner-local checkpoints;
   - next safe action.
7. Preserve privacy: no passwords, tokens, OAuth secrets, chat IDs, private message bodies, recovery codes, or sensitive Omen data in public handoff artifacts.
8. Do not create a second scheduled steering loop merely for handoff continuity. The single canonical Chief Engineer executor remains the scheduled writer unless the owner explicitly changes that topology.

## Incoming AI procedure

A fresh AI must not rely on a copied chat summary as authoritative truth. It must:

1. Read `KEVIN-START-HERE.md`.
2. Read `AI-HANDOVER.md`.
3. Read `inbox/CURRENT_TASK.md`.
4. Read the applicable owner authorization/doctrine.
5. Inspect fresh live evidence and open PR/CI state.
6. Classify each important capability using the proof ladder.
7. Identify stale evidence, duplicate/expired requests, current in-flight work, and cooled failure families.
8. Avoid overwriting fresh outstanding requests/manifests/active work.
9. Continue from the highest-value safe next action instead of restarting research or redesign from scratch.

### Required proof ladder

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

The incoming AI must not infer higher proof from lower proof.

## Matt's minimal new-chat action

Matt should not need a giant copy/paste prompt. In a new conversation inside the Kevin Build Project, the preferred bootstrap is simply:

**Resume Kevin Build from the GitHub handoff.**

or

**Continue Kevin from the handoff.**

The new AI should then reconstruct context itself using the startup protocol. Matt only needs to supply information if a current owner preference/decision is genuinely absent from the durable project artifacts.

## First response from a replacement AI

After reconstruction, the new AI should give Matt a short orientation, not a giant recap. It should answer five things:

1. What Kevin is trying to accomplish right now.
2. What has actually reached production/proven status.
3. What is currently in flight.
4. What is blocked/cooling and why.
5. What action the AI is taking next.

If repository prose conflicts with fresher telemetry, say so and use the fresher independently supported evidence.

## `reports/handoff-latest.json` recommended schema

This compact checkpoint is an accelerator, not an authority source. Suggested fields:

- `schema`
- `kind`
- `generated_at`
- `current_sprint`
- `start_here_path`
- `handover_path`
- `current_task_path`
- `owner_authorization_path`
- `proof_ladder`
- `production_proven[]`
- `p0[]` with `name`, `proof_level`, `next_boundary`, `blocker`
- `in_flight[]` with exact request/branch/PR identifiers when public-safe
- `cooled[]`
- `owner_checkpoints[]`
- `latest_evidence_paths[]`
- `privacy` flags confirming no secrets/private bodies

The file should stay compact. Detailed narrative belongs in `AI-HANDOVER.md`.

## Scheduled automation continuity

Scheduled tasks survive independently of chat history, but a deleted chat or user action can disable them. Therefore after a significant chat deletion/migration or unexplained loss of momentum, explicitly inspect automation state.

Current operating pattern should prefer:

- one canonical scheduled **Chief Engineer** that may steer/mutate Kevin;
- read-only scorecard/report tasks as needed;
- old/overlapping steering loops disabled.

Do not assume an automation is enabled merely because its prompt still exists.

## Failure recovery

If a new AI cannot access GitHub/connected tools:

1. Tell Matt exactly which durable files are needed.
2. Ask for the minimum missing artifact, ideally `KEVIN-START-HERE.md` plus `AI-HANDOVER.md`, rather than the entire old chat.
3. Do not reconstruct specific hashes/proof claims from memory.
4. Resume evidence-first work once access is restored.

If the handover itself appears stale:

1. Treat it as a hypothesis.
2. Inspect fresh telemetry/PR/CI/control-plane state.
3. Correct the handover after reconciling current truth.

## Success criterion

A handoff is successful when a new AI can enter a new chat, recover Kevin's mission/current proof/blockers/in-flight work, avoid duplicate or conflicting actions, and continue useful engineering **without Matt having to retell the project**.
