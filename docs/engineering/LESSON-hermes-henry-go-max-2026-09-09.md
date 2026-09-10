# LESSON — Hermes / Henry / OpenClaw applied to Kevin go-max (2026-09-09)

**Authority:** GREEN-A/C. Observation and doctrine only. No new desktop tools, no ClawHub, no PCClaw, no OpenClaw self-upgrade, no Yellow relabeled Green.

**Trigger:** Owner asked to deeply research current Kevin state and current best practice from Hermes, Alex Finn / Henry, and OpenClaw, then execute the next bounded step.

Fresh HESS-PC evidence used: Support `2026-09-09T18:46:03-06:00`, Engineering `2026-09-09T18:46:30-06:00`, continuation `2026-09-09T18:45:12-06:00`.

## Current Kevin state (machine, not chat)

| Signal | Live value | Meaning |
|---|---|---|
| Benchmark | PASS 30/30, critical 0 at 18:38:57 MT | Platform healthy |
| Six cron lanes | all `ok`, `consecutive_errors=0` | Scheduler is not the bottleneck |
| UI Bridge | heartbeat 1.4s FRESH | HQ can see truth |
| Maintenance runner | `EF32D990…` v1.3.53 | Do not reinstall |
| Supervisor | `F17F4B0A…` v1.8.12 proven | Do not recopy |
| Forge | `433534B9…` v4.0 | Must not change |
| Maintenance slot | `EXPIRED_IDLE` `grok-install-v1812-20260908-2050` | Queue window is open |
| Continuation | `BLOCKED_INVOCATION_RUNTIME` selected `owner-west-motor-parts-chase-fresh-8-v1` `eligible_count=7` `failure_sha256=68845506…` turn 1 at 09:31 | Worker ran/threw; not missing; not PASS |
| Proven skills | 27, latest `west-motor-parts-chase-board-pack@1` | Do not recreate |
| Night Forge | Disabled | Leave disabled |
| Support `cron.ok=false` / `NO_ELIGIBLE_MISSION` | stale parser / cycle fields | Not live work |

The bottleneck is not GREEN vs Yellow, not tools, not models, not a swarm. The bottleneck is the first fresh PROVEN-skill invoke still fail-closed on the worker NativeCommandError path.

## What Finn / Henry actually does (copy the shape, not the swarm)

Sources: Finn OpenClaw 2.0 video (2026-08-31), Mission Control / org-chart posts, ClawPilled interview, `$20k OpenClaw` local-model talk.

1. **Org chart, not swarm.** Finn is CEO. Henry (Opus) is chief of staff / orchestrator. Ralph manages. Charlie executes. Finn talks only to Henry. Kevin already has this: Supervisor is Henry; Skill Lab / invocation worker / Maintenance are specialists. Do not spawn five extra subagents to look busy.
2. **Start with one employee.** Finn: rushing five subagents at once is a massive mistake. Scale only after one workflow is proven. Kevin's one workflow is `west-motor-parts-chase-board-pack@1` on the 8-vehicle WorkInstance.
3. **Hybrid brain/muscle.** Frontier model decides; local models do 24/7 dirty work. Kevin already defaults to local/free Ollama and keeps exact-five desktop. Do not add cloud tools to "go max."
4. **Manager checks the worker.** Charlie coding 8 hours alone produced bugs; Ralph checking every 10 minutes produced a clean game. Kevin's typed receipts + Benchmark 30/30 are that manager. A model turn is not QA.
5. **Mission Control exists so the agent can be proactive.** Finn's task board is why Henry takes work off his plate. Kevin HQ / Command / WorkInstances are that board. Filling `HEARTBEAT.md` is the wrong OpenClaw copy — it burns a model call and already truncated `CURRENT_TASK`. Keep HEARTBEAT empty; standing work is Supervisor / Skill Lab / Maintenance.
6. **Slow hardware scale.** Finn has a Mac Studio unplugged because he has no workflow for it. Do not add Night Forge, PCClaw, or extra models to create activity.
7. **Do not tell the agent to upgrade itself.** Finn: most OpenClaw updates break the install; OpenClaw 2.0 went silent when he asked Henry to self-upgrade. Kevin's typed Maintenance ladder is the correct answer.

## What Hermes actually does (copy the loop, not the runtime)

Sources: Nous Research `hermes-agent` (v0.21.1, 2026-09-07, ~244k stars), Arun Baby 2026-09-02, Better Stack / Farfield architecture notes.

Hermes loop: **observe → reflect → compress → integrate.**

| Hermes | Kevin already | Do not copy |
|---|---|---|
| Skill file after ~15 similar tasks (name, triggers, steps, confidence) | Skill Lab + lessons + failure families | Auto-write weak skills from one fail-closed turn |
| Skills self-improve on reuse; prune/merge | 27 PROVEN composites; widen allowlist only after first PASS | ClawHub import (`hermes claw migrate`) |
| Persistent `memory.md` / `user.md` + FTS5 session search | `AI-HANDOVER.md`, lessons, WorkInstance history | Stuffing HEARTBEAT / truncating CURRENT_TASK |
| Context compress at ~50–75%, protect first/last turns | Typed receipts; burned 09:31 turn kept | Reset history/budgets to look idle-free |
| Cron + kanban dispatcher | Six scheduler lanes + WorkInstances | Night Forge re-enable |
| Isolated subagents for parallel workstreams | GREEN-B bounded subagents | Unrestricted swarm / God Mode shell |
| Local models for jobs nobody is waiting on | Ollama default | Frontier for every heartbeat |
| Weak models create weak skills; skill proliferation without curation | Exact allowlist `west-motor-parts-chase-board-pack@1` until first PASS | Marketplace skills |

Failure modes to refuse: weak-model skill writing, skill-library noise, lossy MEMORY.md compression, OpenClaw God Mode, ClawHavoc (341–1,100+ malicious ClawHub skills; AMOS infostealers; Unit 42 still finding bypasses after VirusTotal).

## What "go max" means for Kevin tonight

It does **not** mean more tools, more models, ClawHub, PCClaw, Astra, Hermes-as-runtime, OpenClaw 2.0, Yellow-as-Green, or a swarm.

It means the Finn/Hermes move that actually compounds: **one proven skill, on fresh inputs, independently verified, then compress into repeatable invocation, then resume.**

Ordered rungs (do not skip):

1. Queue `replace_pinned_component` Maintenance v1.3.53 `EF32D990…` → v1.3.55 `3E11C429…` now that v1812 is `EXPIRED_IDLE`.
2. Wait typed `APPLIED_PREAUTHORIZED_PROVEN` / `ALREADY_APPLIED_PROVEN` + Support hash `3E11C429…`. Benchmark stays 30/30. Supervisor stays `F17F4B0A…`.
3. Queue `install_invocation_worker_v11` live worker `16C49542…` → `7E1129B7…`. GitHub ControlPlane pin stays `16C49542…` until that apply.
4. Resume **the same** WorkInstance `owner-west-motor-parts-chase-fresh-8-v1`. Keep the 09:31 burned turn.
5. **PASS** = real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt on fictional 8-vehicle data. A queue write, CI, HQ label, fail-closed receipt, or model turn is not PASS.
6. After first PASS: bind other due WorkInstances to the existing 27 PROVEN keys (Hermes integrate). Only then Kevin-originated skills via Skill Lab (Hermes compress). Yellow stays prepare-only.

Parallel GREEN, not a substitute: console hygiene v1.7 on HESS-PC; keep HQ honest about `BLOCKED_INVOCATION_RUNTIME`; Yellow grant cards remain prepare; Night Forge stays Disabled; HEARTBEAT.md stays empty.

This lesson is not that proof.
