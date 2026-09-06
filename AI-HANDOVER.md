# Kevin AI Engineering Handover — CANONICAL

> **THIS IS THE ONE CURRENT HANDOVER FOR KEVIN.** Do not create a competing dated handover. Update the source task/evidence and let the canonical handover refresh replace stale state.

**Semantic checkpoint evidence through:** 2026-09-06T14:47:44.9782938-06:00  
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

- Engineering evidence at checkpoint: `2026-09-06T14:47:44.9782938-06:00`
- Support evidence at checkpoint: `2026-09-06T14:44:10.9754072-06:00`
- Autonomy evidence at checkpoint: `2026-09-06T14:44:31.0006490-06:00`
- Benchmark: **FAIL_CRITICAL_REGRESSION — 29/30, critical 1**
- UI Bridge health at checkpoint: **STALE** (age then: 134324.1 seconds)
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

**Updated:** 2026-09-06 14:48 MT
**Status:** exact recovery evidence qualified; one fail-closed HESS-PC apply remains

Owner directed Bess to resume Kevin repair after Grok credits exhausted. Canonical handover remains `AI-HANDOVER.md`.

## Proven this session
- Owner returned the private `Kevin-Evidence-20260906-141701-b9b2d9` collector archive. Collection completed read-only with no collection errors.
- Native Ollama isolation is now PASS for both required local models: `llama3.1:8b` and `qwen2.5:14b`; no model-proposed tool was executed by the diagnostic. The previous Ollama receipt blocker is closed.
- Installed production config SHA is `29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA`. Current policy metadata proves exact-five Desktop tools, 15 protected global denies, the repaired `ollama-chat-16k/qwen2.5:14b` 16k contract, and compaction `reserveTokensFloor=2048`, `reserveTokens=2048`, `keepRecentTokens=4000`.
- PR89/live crossing provenance proves exact-five was intentional and reached fresh Benchmark 30/30 on 2026-09-04. The corresponding proven production config SHA is `DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4`; the installed baseline still pins that SHA. Do not regress to exact-four.
- Installed Benchmark identity is `4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964`; current failure is still exactly 29/30, critical R04 only.
- Installed Maintenance identity is `715E40DF0CFDC94FC8D470A83273467A6B10CC6CB9A2956E3A94FADC69B9646B`. Source review proves a recovery deadlock: relevant mutation/restart paths require final Benchmark 30/30, so R04 causes those repairs to roll back before they can repair the gate itself.
- `Kevin UI Bridge v0.3` is present but Disabled; collector observed Interactive logon + Limited run level, last run 2026-09-05 01:20:19 MT, and stale heartbeat. This requires task-definition recovery, not another unchanged restart attempt.
- Engineering/support/supervisor schedulers remain alive enough to publish status. Action queues are empty, 27 composite skills are proven, and Supervisor reports `NO_ELIGIBLE_MISSION`; after platform recovery, work-supply/admission must be restored and proven with real GREEN owner-value work.
- PR135 merged to `main` as commit `0024db4cdfa142924c1fff25e70895f8b2760a7b`. Final recovery candidate is `tools/Repair-Kevin-Recovery-20260906-v2.ps1`. Final PR head passed Windows PowerShell 5.1 parser, deterministic self-test, and authority-boundary checks. The superseded condensed draft was removed and never ran on HESS-PC.

## Exact next step
Owner runs the merged `tools/Repair-Kevin-Recovery-20260906-v2.ps1` on HESS-PC. Run `-CheckOnly` first; apply only if it prints `KEVIN_RECOVERY_V2_READY`.

The script is fail-closed. It will not re-anchor R04 merely because policy metadata looks healthy. It must first find the exact previously proven `DBF596...` config bytes in bounded local OpenClaw backup locations and prove the current `29383...` config is semantically identical except `meta.lastTouchedAt` / `meta.lastTouchedVersion`. It also requires exact current component identities, exact R04-only 29/30 failure, exact-five policy, protected denies, local 16k model/compaction contract, and unchanged non-R04 trust anchors.

If qualified, Apply changes only `baseline.hashes.production_config` with exact rollback and requires fresh Benchmark 30/30. It then backs up/rebuilds only the known Interactive/Limited UI Bridge task, requires sustained same-session heartbeat, and performs a GREEN Notepad round-trip. If UI fails after R04 succeeds, the receipt records `PARTIAL_R04_PROVEN_UI_FAILED` and leaves the now-green Benchmark state for typed follow-up.

## After a successful local apply
1. Read fresh Support/Engineering/Benchmark/UI receipts and publish the local recovery receipt/sanitized proof.
2. Use now-green typed Maintenance to install/prove a UI watchdog that can recover the actual disabled-task failure family rather than blindly start a disabled task.
3. Run fresh main-agent owner-intent canaries for the exact-five tools plus forbidden-tool negatives; repair HQ/support truth that still reports an obsolete four-tool inventory.
4. Restore Supervisor work supply/admission with one real eligible GREEN owner-value mission; prove selection, execution, verification, recording, learning, and continuation instead of synthetic Forge churn.
5. Teach the recovery deadlock lesson into Maintenance: an exact qualified gate-repair operation must be able to repair the failing trust leaf, with post-repair 30/30, without widening general shell authority.
6. Resume the broader Kevin v2 roadmap and Business Lab only after platform truth is green; prioritize measurable owner outcomes and lower Bess intervention over more infrastructure for its own sake.

## Preserved constraints
Local/free Ollama default; no paid inference fallback. Exact-five is intentional. Keep failure history. No blind R04 blessing, no obsolete September 3 repair script, no arbitrary shell/tool widening, no silent public sends/purchases/trades, and no false claim that GitHub source has changed production before HESS-PC proves the crossing. Fresh correlated runtime evidence outranks this task prose.

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

Semantic fingerprint: `49677B68C6360B81926A687A2E024C99C3F21CC98B5BCCFFF31C9F1A42203BA1`

**Fresh runtime evidence first; one handover; publish every durable local change; then continue.**
