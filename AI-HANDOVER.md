# Kevin AI Engineering Handover — CANONICAL

> **THIS IS THE ONE CURRENT HANDOVER FOR KEVIN.** Do not create a competing dated handover. Update the source task/evidence and let the canonical handover refresh replace stale state.

**Semantic checkpoint evidence through:** 2026-09-06T15:33:45.1313741-06:00  
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

- Engineering evidence at checkpoint: `2026-09-06T15:33:45.1313741-06:00`
- Support evidence at checkpoint: `2026-09-06T15:20:11.0360574-06:00`
- Autonomy evidence at checkpoint: `2026-09-06T15:29:30.8625926-06:00`
- Benchmark: **PASS — 30/30, critical 0**
- UI Bridge health at checkpoint: **FRESH** (age then: 3.3 seconds)
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

**Updated:** 2026-09-06 15:30 MT
**Status:** Recovery v3 false-stop diagnosed; merged Recovery v4 CheckOnly crossing is next

Owner directed Bess to resume Kevin repair after Grok credits exhausted. Canonical handover remains `AI-HANDOVER.md`; fresh correlated runtime evidence outranks prose.

## Proven this session
- Current production config SHA remains `29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA`. Exact-five Desktop policy and all 15 protected global denies remain intact. Main remains `ollama-chat-16k/qwen2.5:14b`; compaction remains 2048/2048/4000.
- Native Ollama isolation remains PASS for exactly `llama3.1:8b` and `qwen2.5:14b`, with no model-returned tool executed. Published fixed-main canary remains `OMEN_PROVEN`, exact reply, Qwen on `ollama-chat-16k`, exactly five Kevin tools.
- PR89/live receipt proves predecessor config `DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4` reached fresh 30/30 on September 4. Current Benchmark remains 29/30 critical1, R04 only; UI task is present but Disabled/stale.
- PR137 Recovery v3 independently qualified the current `29383...` local-model evolution and passed Windows PowerShell 5.1 qualification gates.
- Owner ran exact SHA-verified v3 `-CheckOnly`. It SAFE STOPPED with `Fresh main-agent canary receipt missing` at qualification preflight. Owner then manually ran v3 `-Apply`; it stopped at the identical preflight line. Because failure occurred before `Repair-R04`, neither invocation changed the Benchmark baseline/R04 anchor, production config, UI scheduled task, or other recovery target.
- Root cause: v3 incorrectly assumed a canary durably published to the repository was also retained at `~/.openclaw/workspace/reports/main-agent-canary-omen.json`. Publication and local retention are separate durability domains.
- The published proof is immutable and real: commit `131f3afd51413f228be64ef660a8e51d9be96a0e`, path `reports/main-agent-canary-omen.json`, Git blob `ec76565f225fdcb880ab0bbad6a58b5d555e2de0`.
- PR138 merged Recovery v4 as `cf517c690ab25a716f97f75734b7ad74995c3d7f`. v4 is a narrow wrapper around exact v3 SHA256 `DAC43A78079A5FA4BDF5E212E265EEBE37950CA4F72E604F50833C86DE3A7D7F`; it does not replace v3's R04, rollback, Benchmark, UI, or Notepad proof logic.
- v4 downloadable wrapper SHA256 is `82CC32E5984199A95B5849FFEF9B18B3709992281CAE6E6C175848E261DC8C02`.
- v4 evidence capsule SHA256 is `EEC855AA7B3677335477634C2D60B2573D75B27ECAA8CCEF96E248CD9949838A`. Capsule links exact config `29383...`, source commit `131f3...`, source blob `ec765...`, exact-five tool-name hash, output hash, Qwen transcript hash/provider/model, and timestamp.
- PR138 CI PASS: Windows PowerShell 5.1 parse, deterministic wrapper self-test, exact downloadable byte identities, Git-lineage reconstruction from commit/blob, and bounded-authority gate. No network, config-set, scheduler mutation, arbitrary shell, or authority expansion exists in v4 wrapper.
- v4 local-evidence precedence is fail-closed: a real local canary always outranks fallback. If a local canary exists but is stale, contradictory, or predates current isolation, v4 refuses to use the published capsule.
- Only when local canary is absent does v4 transiently stage the SHA-pinned published canary at the path exact v3 expects. It removes the staged evidence only when its bytes remain unchanged; concurrent/newer evidence is preserved.

## Exact next step
Owner places these three files together in Downloads:
1. existing SHA-verified `Repair-Kevin-Recovery-20260906-v3.ps1`;
2. `Repair-Kevin-Recovery-20260906-v4.ps1` SHA256 `82CC32...`;
3. `Kevin-Recovery-Main-Canary-20260906.json` SHA256 `EEC855...`.

Owner runs **v4 CheckOnly only**. Do not provide or run Apply in the same command block. Required success markers are:
- underlying `KEVIN_RECOVERY_V3_READY ...`;
- wrapper `KEVIN_RECOVERY_V4_READY ...`;
- if fallback was staged, `KEVIN_RECOVERY_V4_STAGED_CANARY_CLEANUP verified=true`.

Return the complete CheckOnly output to Bess. Apply is authorized/present in v4 but must not be instructed until the returned READY evidence is reviewed.

## Why v4 is not a weakened gate
The local dual-model isolation receipt remains required and fresh. The fixed-main canary content, timestamp, exact-five surface, output hash, transcript hash, Qwen route, source commit/blob, capsule bytes, current config bytes, and exact v3 engine bytes are all pinned. Fallback is allowed only for absence, never contradiction. Exact v3 still performs every existing config/source/R04 precondition before a production write can occur.

## After successful v4 CheckOnly / Apply
1. Review CheckOnly; then run v4 Apply separately.
2. Require fresh Benchmark 30/30 and sustained UI/Notepad proof or preserve controlled partial R04-green result.
3. Ingest recovery receipt plus fresh Support/Engineering/UI truth.
4. Add typed Maintenance R04 re-anchor operation and durable proof-source semantics so Kevin owns this recurrence.
5. Repair UI watchdog disabled-task semantics, run fresh exact-five owner-intent/negative canaries, and correct stale HQ four-tool truth.
6. Restore one real eligible GREEN owner-value mission and prove selection -> execution -> verification -> recording -> learning -> continuation.

## Preserved constraints
Local/free Ollama default. Exact-five is intentional. Keep failure history. No blind R04 blessing, no rollback to exact-four, no obsolete September 3 repair script, no arbitrary shell/tool widening, no silent public sends/purchases/trades. Published evidence and local evidence are different durability domains; fallback evidence never overrides contradictory local evidence.

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

Semantic fingerprint: `26DBA6C63BE8B3690FF2B524DFE316AF78EF9ABBAA55FF77DDF530398EF66714`

**Fresh runtime evidence first; one handover; publish every durable local change; then continue.**
