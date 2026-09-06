# Kevin AI Engineering Handover — CANONICAL

> **THIS IS THE ONE CURRENT HANDOVER FOR KEVIN.** Do not create a competing dated handover. Update the source task/evidence and let the canonical handover refresh replace stale state.

**Semantic checkpoint evidence through:** 2026-09-06T14:57:44.8122170-06:00  
**Canonical repository:** `hessmodee/KEVIN-WORK` / `main`  
**Machine twin:** `reports/handoff-latest.json` (not a second authority)

## Universal access

Any replacement AI — ChatGPT, ChatGPT Work, Grok, Grok Build, Grokbot, Kevin, or another agent — should be given or should fetch **this exact file first**:

- GitHub: https://github.com/hessmodee/KEVIN-WORK/blob/main/AI-HANDOVER.md
- Raw text: https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/AI-HANDOVER.md
- Kevin HQ: https://hessmodee.github.io/KEVIN-WORK/handover.html

If an agent cannot access one route, use another. Matt should never need to reconstruct the build from chat history.

## Absolute continuity rules

1. `AI-HANDOVER.md` is the **only human current handover**. Do not create competing dated, agent-specific or parallel current-state handovers.
2. Fresh correlated HESS-PC/OpenClaw evidence outranks this checkpoint. Always inspect `reports/support-latest.json`, `reports/engineering/latest.json`, and applicable runtime/autonomy receipts after opening it.
3. Every AI must read `AI-HANDOVER.md` and `inbox/CURRENT_TASK.md` before substantive Kevin work.
4. Every material durable change must be committed/pushed to `hessmodee/KEVIN-WORK` or represented by a sanitized published runtime receipt before being called complete. **Local-only work is unfinished work.**
5. A desktop-local agent such as Grokbot may test locally, but it may not leave the only copy of source, configuration intent, repair logic or proof on HESS-PC.
6. Before editing shared state, re-read/pull current `main`; use a branch for source changes; reconcile before merge; never overwrite newer active work.
7. Checkpoint after every substantive proof transition or material repair, not only at the end of a conversation.
8. Never publish passwords, tokens, OAuth material, private message bodies, credentials, recovery codes or sensitive local data to this public repository.

## Automatic semantic snapshot

- Engineering evidence at checkpoint: `2026-09-06T14:57:44.8122170-06:00`
- Support evidence at checkpoint: `2026-09-06T14:44:10.9754072-06:00`
- Autonomy evidence at checkpoint: `2026-09-06T14:54:31.0781311-06:00`
- Benchmark: **FAIL_CRITICAL_REGRESSION — 29/30, critical 1**
- UI Bridge health at checkpoint: **STALE** (age then: 134923.9 seconds)
- Maintenance: **ERROR** — manifest expired
- Supervisor last result: **NO_ELIGIBLE_MISSION**
- Proven composite skills: **27**
- Installed Maintenance identity reported by Support: `715E40DF0CFDC94FC8D470A83273467A6B10CC6CB9A2956E3A94FADC69B9646B`

The builder runs after `main` changes and on a ten-minute reconciliation schedule, but it writes a new checkpoint only when turnover-relevant semantic state changes. Heartbeat timestamps alone do not move `main`. Incoming agents still read fresh runtime reports directly.

Do not interpret task/hash presence as health when a semantic heartbeat or round-trip proof is required.

## Current owner task / exact continuation

The block below is pulled from `inbox/CURRENT_TASK.md`. That file is an execution input, not a competing handover.

---

# CURRENT_TASK

**Updated:** 2026-09-06 14:58 MT
**Status:** recovery SAFE STOP preserved production; exact config drift diagnosis required before R04 repair

Owner directed Bess to resume Kevin repair after Grok credits exhausted. Canonical handover remains `AI-HANDOVER.md`.

## Proven this session
- Owner returned the private `Kevin-Evidence-20260906-141701-b9b2d9` archive. Native Ollama isolation PASS for both `llama3.1:8b` and `qwen2.5:14b`.
- Current production config SHA is `29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA`; current sanitized metadata still proves exact-five Desktop tools, 15 protected global denies, repaired local Qwen 16k model contract, and 2048/2048/4000 compaction contract.
- PR89 proves exact-five was intentional and reached fresh Benchmark 30/30 on 2026-09-04 with config SHA `DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4`. Never regress to exact-four.
- Benchmark remains exactly 29/30 critical1, R04 only. UI Bridge task remains Disabled/stale. Supervisor remains `NO_ELIGIBLE_MISSION`; 27 composite skills are proven.
- PR135 merged recovery bootstrap `tools/Repair-Kevin-Recovery-20260906-v2.ps1` as `0024db4cdfa142924c1fff25e70895f8b2760a7b`, Windows PowerShell 5.1 tested.
- Owner ran the exact recovery `-CheckOnly`. It correctly SAFE STOPPED: `current config differs semantically from proven exact-five config beyond touch metadata`. The Apply guard did not run because CheckOnly exited nonzero. No baseline, config, UI task, or other production state was changed by that attempt.
- Therefore `29383...` contains at least one semantic JSON difference from `DBF596...` beyond only `meta.lastTouchedAt` / `meta.lastTouchedVersion`. Do not rebaseline R04 and do not restore DBF596 blindly until the exact delta is classified.
- PR136 merged read-only redacted diagnostic `tools/Diagnose-Kevin-Config-Drift-20260906.ps1` as `952b9b31b1b595c76741ad1adda33ec6aa477ab8`. Windows PowerShell 5.1 parser, secret-redaction self-test, and read-only authority-boundary checks passed. It performs no writes, restarts, network calls, config changes, or task changes.

## Exact next step
Owner runs the merged `tools/Diagnose-Kevin-Config-Drift-20260906.ps1` once on HESS-PC and returns its console output from `KEVIN_CONFIG_DRIFT_DIAG_READY` through `VERDICT|...`.

The diagnostic pins current `29383...` and trusted `DBF596...`, finds the trusted bytes only in bounded local OpenClaw/Maintenance backup locations, recursively compares semantic JSON paths, and reports changed paths with type + short hashes. Only tightly bounded known non-secret operational values may be shown; sensitive/unknown values remain hashed/redacted. This is diagnosis only.

## Decision after the diff
- If drift is truly benign generated metadata: narrowly qualify those exact paths and rerun recovery CheckOnly; never broaden ignores generically.
- If drift is an intentional later feature/config change: establish its local/repository provenance and prove its semantics, then preserve it and qualify the current config before R04 rebaseline.
- If drift is unproven, unsafe, or accidental: restore only the affected semantics from a trusted proven state through a rollback-backed repair; do not blindly bless current bytes.
- Only after config provenance is settled: repair R04 to fresh 30/30, repair/prove UI Bridge, fresh exact-five owner-intent tool/negative canaries, correct stale HQ four-tool truth, then restore eligible GREEN work selection and owner-value execution.

## Preserved constraints
Local/free Ollama default. Exact-five is intentional. Keep failure history. No blind R04 blessing, no obsolete September 3 repair script, no arbitrary shell/tool widening, no silent public sends/purchases/trades, and no false claim that GitHub source changed production before HESS-PC proves it. Fresh correlated runtime evidence outranks prose.

---

## Cross-AI local-work convergence contract

The shared GitHub repository is the rendezvous point between agents that can see different environments. Local runtime and GitHub source are two different truth planes:

- **Repository/source truth:** reviewed source, procedures, current task, PR/CI, public-safe receipts.
- **HESS-PC runtime truth:** installed hashes, scheduled tasks, live heartbeats, configuration state, UI outcomes and other machine-local evidence.

No agent may silently treat one plane as the other. When Grokbot changes HESS-PC, it must publish the corresponding source/evidence checkpoint. When a remote agent changes GitHub, it must not claim the production machine changed until HESS-PC independently reports the installed result.

## Incoming-agent bootstrap

1. Read this file.
2. Read `KEVIN-START-HERE.md`, root `AGENTS.md`, and `inbox/CURRENT_TASK.md`.
3. Read fresh `reports/support-latest.json` and `reports/engineering/latest.json`; inspect relevant open PR/CI.
4. Compare timestamps, hashes, proof levels and in-flight requests. Treat stale prose as stale.
5. Continue the highest-value safe next action; do not restart the project or ask Matt to relay information already present in shared state.
6. After a substantive change, publish the execution input/evidence so the automatic handover can produce the next semantic checkpoint.

## Proof and authority

Technical proof ladder:

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

Responsibility transfer:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

Never infer a higher state from a lower one. Never widen authority merely to make turnover easier.

## Generator integrity

This handover is generated by `.github/scripts/build-canonical-handover.py` and refreshed by `.github/workflows/canonical-handover.yml`.

Semantic fingerprint: `3D9B7052D6B7C4C227F94850426F17EA4D869E0844038176F735338F26954F06`

**Fresh runtime evidence first; one handover; publish every durable local change; then continue.**
