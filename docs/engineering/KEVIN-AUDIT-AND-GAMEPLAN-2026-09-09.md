# Kevin state audit and game plan — 2026-09-09 20:20 MT

**Authority:** GREEN-A/C. Observation, doctrine, HQ truth, and a reversible self-repair recipe. Not PASS. Not a desktop-tool widen. Not a Yellow grant.

**Fresh machine evidence used**

| Source | Stamp | Fact |
|---|---|---|
| Support | `2026-09-09T20:19:03-06:00` | Runner `3E11C429…`, Supervisor `F17F4B0A…`, Benchmark PASS 30/30, maintenance slot `ALREADY_APPLIED_PROVEN` for `grok-install-worker-v11-20260909-1910` |
| Continuation | `2026-09-09T20:25:13-06:00` | `BLOCKED_INVOCATION_RUNTIME` on `owner-west-motor-parts-chase-fresh-8-v1`, `failure_sha256=68845506…`, `eligible_count=7`, `outcome_proven=false` |
| Engineering | `2026-09-09T20:24:36-06:00` | Six lanes `ok` / `consecutive_errors=0`, UI Bridge 0.9s, proven skills 27, request `grok-status-20260909-1910` = `DUPLICATE_IGNORED`, queues ready 0 / running 0 / done 66 / failed 1 |
| Board / self-check | 20:20 MT | Host HESS-PC healthy, GitHubBridge pull+publish PASS, Ollama + gateway PASS |
| Main canary | `2026-09-08T10:59:37-06:00` | `OMEN_PROVEN`, visible tools 5, `has_kevin_system_status=true` — **stale vs 1800s HQ freshness** |
| Tool policy diagnosis | `2026-09-06T18:39:27-06:00` | exact-5 allow / alsoAllow; protected denies for exec/process/write/edit/web remain |

## 1. Where Kevin is (truth, not theater)

Kevin is **not crashed**. Kevin is **not idle**. Kevin is **not degraded as a platform**.

Kevin is **fail-closed on the first fresh proven-skill invoke**.

- Platform floor is healthy: Benchmark 30/30 critical 0, six scheduler lanes ok, UI Bridge fresh, Support hashes pinned.
- Maintenance v1.3.55 is independently proven. Invocation worker v1.1 is independently applied (`ALREADY_APPLIED_PROVEN` at 20:15 MT). Supervisor v1.8.12 is independently proven and must not be recopied.
- Supervisor keeps selecting `owner-west-motor-parts-chase-fresh-8-v1` and publishing `BLOCKED_INVOCATION_RUNTIME`. Public continuation only hashes `INVOCATION_WORKER_FAILED exit=N`, so `68845506…` staying put means the **exit code class did not change**, not that Supervisor stopped running. Generated_at moved to 20:25. The 09:31 burned turn stays.
- HQ Pages ops-v11 previously painted that fail-closed as **DEGRADED**. That is a label bug. Owner console v10 already called it **BLOCKED**. This turn fixes ops-v11.
- Tools UNVERIFIED on HQ is the stale 2026-09-08 canary against an 1800s freshness window. It is not proof that Calculator launch disappeared. Do not widen tools to clear a stale badge.

## 2. Where we are going

Target maturity remains **T4 for routine bounded work**: detect need → resolve/build capability → complete and verify owner outcome → learn → resume interrupted work. T4 is not unrestricted authority.

North star loop: `SENSE → REFLECT → SELECT → PLAN → RESOLVE CAPABILITY → ACT → VERIFY → LEARN → RESUME`

Finn / Henry / Hermes copied as shape, not as swarm:

1. One employee, one workflow, then scale. Kevin's one workflow is `west-motor-parts-chase-board-pack@1` on fictional 8-vehicle inputs.
2. Org chart already exists: Supervisor = Henry; invocation worker / Skill Lab / Maintenance = specialists.
3. Manager checks the worker. Typed receipts + Benchmark 30/30 are that manager. A chat turn is not QA.
4. Hermes observe → reflect → compress → integrate maps onto Kevin Skill Lab + lessons + invocation. Do not import ClawHub / PCClaw / Night Forge.
5. Mission Control already exists (HQ + WorkInstances). Keep it honest. Do not truncate `CURRENT_TASK`.

## 3. Objectives not yet accomplished

| # | Objective | Status | What "done" actually is |
|---|---|---|---|
| 1 | First fresh proven-skill PASS | **Open** | Workbook + operating note + DONE records + output hashes + immutable invocation receipt on `owner-west-motor-parts-chase-fresh-8-v1`. Queue write / CI / HQ label / fail-closed receipt / model turn ≠ PASS |
| 2 | Repeatable invoke of the other 26 PROVEN skills | Blocked on #1 | Bind due WorkInstances to existing keys. Do not recreate skills. Do not widen allowlist first |
| 3 | Capability-aware Supervisor routing | Partially live | Exact PROVEN key already routes to invocation before Skill Lab / fixed:main. Remaining gap is worker completing |
| 4 | Incident resume | Contract live, not proven | After independently proven repair, same WorkInstance must resume. 09:31 turn stays |
| 5 | Owner-UX console hygiene v1.7 | Source ready, apply is local | VBS SW_HIDE wrap. Parallel, not a substitute for #1 |
| 6 | HQ truth hygiene | **This turn (source)** | BLOCKED ≠ DEGRADED. Stale canary ≠ broken tools |
| 7 | Chat honesty / receipt rule | Doctrine live, Chat still lies | Never claim app/desktop state without a same-turn tool receipt |
| 8 | Computer use beyond launch | **Candidate only** | Calculator UIA crossing is scratch-proven and Chat-off. Notepad/type/click are not live Chat tools |
| 9 | Communications / errands / Minecraft player | Later waves | Delegated Yellow stays prepare-only |
| 10 | T4 self-repair without Bess/Grok | Growing | Each outside intervention must leave a Kevin-owned recipe. This turn leaves the invocation-reject publisher |

## 4. The desktop disconnect — root cause, not a slogan

Owner report: "the only thing I can get him to do is open a calculator. He cannot use the calculator or open or use any other app. He hallucinates about other things."

That report is **correct as lived experience** and **incorrect as a diagnosis that tools are missing because Kevin is broken**.

Three stacked causes:

1. **Policy, not accident.** Live Chat `fixed:main` is exact-five on purpose: `kevin_system_status`, `kevin_desktop_find_folder`, `kevin_desktop_open_folder`, `kevin_desktop_list_folder`, `kevin_app_launch`. Launch allowlist is calculator / notepad / paint / explorer. Protected global denies still cover exec, process, write, edit, apply_patch, web, skill_workshop.
2. **Launch ≠ operate.** `kevin_app_launch` can start Calculator. It cannot click `7 + 5 =`, type into Notepad, or save a file. Focus / click / type live in `kevin_ui_*`, which is a refuse-by-default candidate. Scratch marker `KEVIN_DESKTOP_UI_CALC_V0_OK` exists. Phase 3 Chat crossing is forbidden until the first proven-skill PASS plus the typed crossing packet. Green Operator `ui_notepad_write` is a different surface (Action Era UI Bridge), not Chat.
3. **Hallucination is 16k overflow + missing receipts.** Long Chat sessions overflow the 16k qwen context, gateway returns text with zero tool_calls, and the model invents success. Never describe desktop/app/process state without a tool result this turn. Operator tip: `/reset` or `/new`, then re-ask. Do not widen tools to silence a liar.

Widening Chat tools tonight would violate the standing contract, skip the proof bar, and still not produce the 8-vehicle workbook.

## 5. Sure game plan (ordered rungs — do not skip)

### Now

1. Keep worker v1.1 applied. Do not reinstall v1.3.55. Do not recopy v1.8.12. Do not overwrite GitHub ControlPlane pin `16C49542…` from source until HESS-PC live hash is independently published as `7E1129B7…`.
2. HQ ops-v11 maps `BLOCKED_INVOCATION_RUNTIME` → BLOCKED, not DEGRADED. CONTROLLER_ERROR stays degraded.
3. GREEN self-repair recipe: `tools/Publish-Kevin-InvocationReject-Public-v1.ps1`. A GREEN agent on HESS-PC may run it once and publish only reason codes to `reports/invocations/latest-public-reject.json`.
4. Fresh `action_status` id `grok-status-20260909-2020`. Do not reuse 1910 / 1850 / 1651 / 0455.
5. Resume the same WorkInstance. Keep the 09:31 burned turn. Do not reset budgets.

Likely live reject families:

- `BUILDER_REJECTED` / `WORK_ITEM_NOT_UNIQUE` / `OWNER_INPUTS_INVALID` / `VEHICLE_COUNT_MUST_BE_8` — work-items shape.
- `STAGE_REJECTED` / `JSON_MISSING_OR_UNSAFE` / `PROVEN_SKILL_NOT_FOUND` / `PRESERVED_PROOF_*` — registry or proof-root missing at `reports/capabilities/composite-skills.json` and `reports/action-era/skills/done`.
- `INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST` — Supervisor always sends RequestId `invoke-<work-id>`. Inspect `reports/invocations/runs/invoke-owner-west-motor-parts-chase-fresh-8-v1.json`. Do not delete history; quarantine only a corrupt run file after hashing it into a lesson.
- `RECONCILE_REJECTED` — stage happened, Action Era has not finished `create_spreadsheet` + `create_text`. That is progress. Wait the Action Era worker; do not send the job to `fixed:main`.

### Next after first PASS

6. Bind other due owner-value WorkInstances to existing PROVEN keys.
7. Only then Skill Lab for Kevin-originated procedures.
8. Phase 3 Calculator UIA crossing packet. Still calculator-only. Still refuse-by-default until Chat proof bar.
9. After Calculator operate is independently proven, one app at a time: notepad type, then explorer, then paint. Never generic CUA. Never `kevin_shell`.
10. Console hygiene v1.7 local apply if flashing remains.

### Later waves

Self-learning compression, managed browser, HQ chat/mobile, scoped voice, Minecraft companion, GREEN cart prep / Delegated-Yellow checkout.

## 6. How Kevin fixes this class himself

1. Read continuation status + Support maintenance slot + Engineering lanes. Do not trust HQ paint over those three files.
2. If status is `BLOCKED_INVOCATION_RUNTIME` and worker is applied, run `Publish-Kevin-InvocationReject-Public-v1.ps1` once.
3. Classify the reason code. Repair the named missing file or schema, not the Supervisor binary.
4. Write a lesson with the reason code. Do not reset history to create a clean retry.
5. Let Supervisor select the same WorkInstance. Verify artifacts. Only then say PASS.

## 7. Hard nos that remain true

- No ClawHub, PCClaw, Night Forge re-enable, OpenClaw self-upgrade, or allowlist widen before first PASS.
- No Yellow relabeled Green.
- No history or budget reset. 09:31 turn stays.
- No claim that this audit, this HQ patch, this queue write, or this chat answer is the 8-vehicle outcome.
