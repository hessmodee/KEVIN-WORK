# Kevin AI Engineering Handover — CANONICAL

> **THIS IS THE ONE CURRENT HANDOVER FOR KEVIN.** Do not create a competing dated handover. Update the source task/evidence and let the canonical handover refresh replace stale state.

**Semantic checkpoint evidence through:** 2026-09-06T15:11:45.0544089-06:00  
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

- Engineering evidence at checkpoint: `2026-09-06T15:11:45.0544089-06:00`
- Support evidence at checkpoint: `2026-09-06T15:02:10.9902731-06:00`
- Autonomy evidence at checkpoint: `2026-09-06T15:09:30.7362884-06:00`
- Benchmark: **FAIL_CRITICAL_REGRESSION — 29/30, critical 1**
- UI Bridge health at checkpoint: **STALE** (age then: 135764.1 seconds)
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

**Updated:** 2026-09-06 15:14 MT
**Status:** current config independently qualified; exact Recovery v3 HESS-PC crossing is next

Owner directed Bess to resume Kevin repair after Grok credits exhausted. Canonical handover remains `AI-HANDOVER.md`; fresh correlated runtime evidence outranks prose.

## Proven this session
- Owner returned private `Kevin-Evidence-20260906-141701-b9b2d9`. Native Ollama isolation is PASS for exactly `llama3.1:8b` and `qwen2.5:14b`; no model-returned tool was executed by the diagnostic.
- Current production config SHA is `29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA`. Exact-five Desktop policy and all 15 protected global denies remain intact. Main remains `ollama-chat-16k/qwen2.5:14b`; compaction remains 2048/2048/4000.
- PR89/live receipt proves the September 4 exact-five predecessor `DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4` reached fresh Benchmark 30/30. Never regress to exact-four.
- Benchmark remains exactly 29/30 critical1, R04 only. UI Bridge scheduled task remains Disabled/stale. Supervisor remains `NO_ELIGIBLE_MISSION`; 27 composite skills are proven.
- Recovery v2 correctly SAFE STOPPED before mutation because current `29383...` was not semantically identical to `DBF596...`. Apply did not run; production stayed unchanged.
- PR136 read-only diagnostic then proved exactly 19 semantic differences: 7 AGENT_RUNTIME, 11 MODEL_RUNTIME, 1 conservative SENSITIVE_PATH classification for `contextTokens`; no tool-policy/gateway/plugin widening.
- Reviewed drift is bounded local-model/runtime evolution: two 12,288-token agent model caps at temperature 0; Qwen remains provider/model 16K; exact Llama 8B fallback; local tool compatibility enabled after strict isolation PASS; 600/900s provider timeouts; Qwen keep-alive 30m -> 10m; Llama 12,288-token text-only catalog entry with 10m keep-alive; main empty models object; one cosmetic identity emoji change.
- Current OpenClaw documentation supports native Ollama `api: ollama`, provider timeouts, `keep_alive`, `contextTokens`/`num_ctx`, and says `supportsTools:false` is for models/servers that reliably fail tool schemas. Both Kevin models independently passed the strict native tool-call isolation proof.
- A later current fixed-main canary is `OMEN_PROVEN`, exits zero, exact expected reply, complete correlated transcript on `ollama-chat-16k/qwen2.5:14b`, exactly five visible Kevin tools.
- Historical authorship provenance is incomplete for every one of the 19 leaves. Do not invent it. Instead the exact current bytes have now been independently accepted as a new known-good candidate under the evidence below.
- PR137 merged as `313ff4d00d476f732d4576f6ec3bda1e1dae360e`. It adds `tools/Repair-Kevin-Recovery-20260906-v3.ps1` plus `docs/engineering/KEVIN-CONFIG-29383-QUALIFICATION-2026-09-06.md`. Final head passed Windows PowerShell 5.1 parser, deterministic positive/negative qualification self-test, and bounded-authority/evidence-gate checks.

## Exact next step
Owner runs merged `tools/Repair-Kevin-Recovery-20260906-v3.ps1` on HESS-PC with `-CheckOnly` first. Apply only if CheckOnly exits zero and prints `KEVIN_RECOVERY_V3_READY ... current_config=QUALIFIED_LOCAL_MODEL_EVOLUTION ...`.

Recovery v3 is fail-closed and adopts no generic semantic ignore list. Before R04 it requires:
1. exact current config SHA `29383...` and exact predecessor `DBF596...` bytes;
2. exact-five tools + 15 denies + no defaults tool widening;
3. exact Qwen primary/Llama fallback and reviewed 12K/16K runtime contract;
4. exact compaction/loopback posture;
5. fresh dual-model isolation PASS with no tool execution;
6. a later fresh fixed-main OMEN_PROVEN Qwen/exact-five canary;
7. `openclaw config validate` exit zero with config SHA unchanged;
8. exact 29/30 critical1 R04-only benchmark state;
9. unchanged non-R04 baseline/source identities.

If all pass, Apply changes only `baseline.hashes.production_config` from `DBF596...` to exact `29383...`, keeps an exact rollback copy, and requires fresh Benchmark 30/30. It then backs up/rebuilds only `Kevin UI Bridge v0.3` as Interactive/Limited, requires sustained same-session heartbeat, and runs the existing GREEN Notepad round-trip. If UI fails after R04 proves green, v3 records `PARTIAL_R04_PROVEN_UI_FAILED` and leaves the proven green Benchmark state for typed follow-up.

## After successful Recovery v3
1. Ingest the v3 recovery receipt plus fresh Benchmark/Support/Engineering/UI truth and publish sanitized proof.
2. Add a typed Maintenance R04 gate-repair operation so this self-repair deadlock cannot recur; exact preconditions, one-leaf re-anchor, post-30/30, rollback, no shell widening.
3. Repair UI watchdog semantics to recover a Disabled task definition rather than blindly starting a disabled task.
4. Run fresh real owner-intent exact-five canaries plus forbidden-tool negatives; repair HQ/support obsolete four-tool truth.
5. Restore one real eligible GREEN owner-value mission and prove Supervisor selection -> execution -> verification -> recording -> learning -> continuation.
6. Resume Kevin v2 / Business Lab only after platform truth is green; optimize measurable Matt value and declining external-chief-engineer dependence rather than infrastructure churn.

## Preserved constraints
Local/free Ollama default. Exact-five is intentional. Keep failure history. No blind R04 blessing, no rollback to exact-four, no obsolete September 3 repair script, no arbitrary shell/tool widening, no silent public sends/purchases/trades, and no false claim that GitHub source has changed production before HESS-PC proves the crossing.

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

Semantic fingerprint: `4DE61F105398667709CBA4CDF332D623FF8A6080B57B61A0F454AE9DD9D21827`

**Fresh runtime evidence first; one handover; publish every durable local change; then continue.**
