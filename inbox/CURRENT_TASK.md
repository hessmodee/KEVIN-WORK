# Current task — Kevin autonomy convergence

Updated: 2026-08-31 21:42 MDT

Run the **Autonomy Convergence + Real-Outcome Sprint** under the installed five-file Autonomy OS v2 doctrine, permanent GREEN standing authorization, autonomy master plan, transfer doctrine, real-world owner-outcome protocol, `docs/engineering/ATTENTION-LIFECYCLE-AND-INCIDENT-LEARNING-v1.md`, and `inbox/autonomy/work-items.json` + `state.json`.

## North star

Move useful work upward on two separate ladders:

`DESIGNED -> CI-PROVEN -> INSTALLABLE -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT`

Never count dashboard/heartbeat churn, duplicate/expired receipt handling, raw Forge iterations, CI-only candidates, task/hash presence or PONG/model smoke as owner-value accomplishment.

## Live baseline

Autonomy OS v2 five-file workspace policy is OMEN identity-proven in `reports/runtime-convergence-omen.json`. Native runtime audit proves Task Flow CLI and Skill Workshop are available, gateway deep probe succeeds, Lobster is not registered, and installed OpenClaw version remains UNKNOWN.

Fresh Support at 21:38:13 MDT reports governance OK and Benchmark PASS 30/30 critical=0. Maintenance Intake scheduler is healthy again, but the last terminal Maintenance result still reflects the Reader canary failure-budget state until a newer manifest is consumed. Observed Maintenance runner SHA256 remains `2CA0EA73E5F43EB1FA7F004288193EE18C450029C403C9A80BE7D3931565E629`.

Legacy Supervisor v1.6 High Gear produced `forge-v4` iteration **333 REJECT** at 21:38:05 MDT with 7 failures and 2 security findings even though the modern Forge production work item is explicitly BLOCKED. This is active orchestration bypass, not useful progress.

Engineering Relay's expired snapshot slot was retired and a fresh GREEN snapshot completed successfully. HQ Truth production source has been repaired to evaluate current predicates rather than historical events, and the exact file actually loaded by HQ is now the CI-gated target.

## 2026-08-31 HQ Attention / Forge admission incident — ACTIVE ROOT-CAUSE REPAIR

Do not revive the old Attention labels `Repeated Forge rejection is not progress` or `Desired-state drift needs review` as unconditional historical warnings.

Current truth rules:
- Attention means a **current unresolved predicate**.
- Desired-state drift is recomputed from current `control-plane/desired-state-v1.json` versus current Support identities.
- The only current desired/live core mismatch is Forge; that mismatch is deliberately held because the replacement remains untrusted/blocked. Treat it as **KNOWN DRIFT**, not a repeated owner-review request, unless the identity/risk/decision materially changes.
- Cached `reports/autonomy-latest.json` drift counts are corroborating telemetry only. If they disagree with current desired/support comparison, report a reconciliation/staleness defect instead of asking the owner to review the same decision again.
- A blocked Forge family producing a fresh evaluation is a real high-severity orchestration defect and must remain visible until production admission is fixed.

Exact Supervisor root cause is now proven from reconstructed installed bytes. The original High Gear installer reproduces the live Supervisor SHA256 `63B8D9C27625E0FB6AFE62165BE376E7ED7EB416E5DA15BB47C206BBF4AE4989`. In those exact bytes, when normal missions are cooling the Supervisor invokes `Get-RecoveryExperiment`, and a READY recovery experiment is converted into a new mission choice with `blocked = false` under `RECOVERY_TO_EXPERIMENT`. The High Gear acceptance proof itself required a new Recovery experiment dispatch and a new evaluation. This predates the modern deterministic work selector and allows the legacy Supervisor to bypass `inbox/autonomy/work-items.json` BLOCKED/failure-budget state.

The deterministic selector is not the defect: `control-plane/autonomy/kevin-work-selector-v1.py` already rejects explicit BLOCKED items, dependency blocks, cooldowns, and exhausted three-attempt failure families. The defect is **admission-path bypass** by the installed legacy Supervisor/Recovery bridge.

Permanent repair target:
1. every Forge dispatch, including Recovery-to-Experiment, must pass the deterministic current-demand admission gate;
2. explicit BLOCKED, dependency-not-ready, cooled/exhausted family, stale/missing admission evidence, or missing bounded demand token -> `IDLE_NO_ELIGIBLE_DEMAND` and zero Forge dispatch;
3. Recovery must never set `blocked=false` to override a policy block;
4. when Forge is ineligible, Kevin must advance another eligible GREEN owner objective rather than manufacture an experiment;
5. any future reopen requires materially new evidence plus a fresh bounded demand identity; no request-id/iteration rename resets a failure family;
6. prove at least two scheduled Supervisor cycles with blocked Forge and **zero new Forge evaluations**, then prove useful work conservation on another eligible objective before calling the incident resolved.

Do not disable Benchmark, weaken R03, silently repin Forge, or clear the Attention item merely to make HQ green.

## P0-A — Reader real repeated canary — BLOCKED pending materially new evidence

The first fixed Reader manifest `reader-status-canary-20260831-2024` expired at 21:00 without terminal Reader evidence. The bounded reissue `reader-status-canary-20260831-2119` subsequently exhausted the Maintenance failure budget. Treat this as an execution/runtime-path blocker until materially new evidence changes the cause; do not create another renamed Reader retry.

Acceptance remains:
1. two real isolated `kevin-reader` turns;
2. exactly one visible/called tool `kevin_system_status` per trial;
3. semantic coverage of RAM, CPU, GPU, disk free space, Ollama and gateway;
4. privacy gate passes and public receipt is metadata/output-hash-only;
5. 2/2 required for `REPEATEDLY_PROVEN`;
6. fresh Benchmark remains 30/30 critical=0;
7. record technical/outcome evidence separately from transfer maturity because Bess/canonical Chief Engineer selected and dispatched the canary.

## P0-B — Skill Workshop guardrails — BLOCKED/COOLED

Do not retry configuration writes. Both the JSON-value hypothesis and the materially different fixed raw-string `--dry-run` hypothesis failed closed against the installed Omen CLI while Benchmark remained clean. Allowed next work is read-only installed CLI-contract diagnosis that materially changes the hypothesis. No renamed retry.

## P0-C — HQ direct Matt <-> Kevin chat — READY after production lane is safe

Use the existing CI-proven typed package already on `main`; do not redesign it.

Success path:
`exact candidate -> typed install -> Omen selftest/privacy/loopback/idempotency -> Benchmark/domain proof -> truthful READY -> real Matt message -> correlated Kevin reply -> restart/replay no duplicate -> common health/recovery proof`.

Do not call it working before the genuine Omen Matt->Kevin->Matt round trip.

## P0-D — Forge / work-selection convergence — production family BLOCKED; admission repair now highest-value platform fix

After three materially distinct migration failures, do not retry Forge production mutation until materially new evidence identifies the actual integrity dependency and installed Supervisor admission path.

Known evidence:
- R03 references Forge + Goal OS + file/hash semantics;
- current Forge SHA occurs zero times literally in Benchmark;
- `reports/forge-r03-contract.json` proves no literal 64-character SHA anchor in R03 and identifies structural baseline/spec/scorecard/policy/Goal-OS references;
- the exact installed Supervisor admission bypass is now identified as described above;
- `reports/goal-os-forge-anchor.json` remains a NOT_RUN placeholder until the fixed read-only diagnosis is consumed;
- legacy Supervisor continues demandless Forge execution.

Target behavior remains demand-driven Forge v4.0: no valid demand -> `IDLE_NO_ELIGIBLE_DEMAND`; valid bounded demand -> exactly-once consume/archive; cooled families stay cooled.

Work-selection transfer stays below T3 until Kevin itself notices idle/blocked state, selects another eligible owner objective, executes, verifies and continues without Bess injecting the immediate request.

## P0-E — Native Task Flow admission controller

Use native Task Flow as durable workflow state where installed runtime proves it fits. Standing Orders define owner intent; deterministic eligibility/WIP/cooldown/dependency logic selects safe work; Qwen reasons only when useful; typed tools act; semantic verifiers decide success; outcomes/trajectories feed proposal-first learning.

Do not build another queue database unless native Task Flow is proven insufficient. The legacy Supervisor must converge toward this admission model rather than running a competing Recovery queue that can manufacture its own demand.

## HQ / deployment reliability

The public HQ static shell and runtime telemetry have different change cadences. Runtime telemetry commits must not be treated as static-site feature releases. Prefer a GitHub Pages custom Actions deployment that triggers only on static HQ assets (`docs/*.html`, `docs/*.js`, styles/assets) while HQ continues fetching fresh runtime JSON directly. This prevents high-frequency telemetry commits from queuing thousands of unnecessary Pages builds and delaying visible static repairs.

Until the Pages publishing source is switched from branch-driven deploys to the custom workflow, treat a queued Pages deployment as delivery lag, not evidence that the tested source repair failed.

## P1 after current crossings

In dependency order: Gmail Omen readiness/OAuth checkpoint; Telegram native-channel diagnosis and owner round trip; Staging real trajectory replay/negative/rollback/idempotency evidence; broad computer fluency; Second Brain; Relief Route/business deliverables; Opportunity Radar/current research; game/Minecraft/Discord/voice lanes when prerequisites exist.

## WIP / no-spin

Maximum default:
- 1 ACTIVE production/proof crossing;
- 1 ACTIVE staging/eval item;
- 1 ACTIVE research/design item with named downstream consumer.

Forge mutation, Reader retry and Workshop mutation families are blocked/cooling. The permitted research slot is the read-only Forge/Goal-OS/Supervisor admission diagnosis and fixed admission design. HQ chat is READY but should not be mixed into a risky control-plane repair crossing.

At every decision ask:
1. What useful GREEN owner work can Kevin safely advance now?
2. What recurring Bess action can Kevin take over next?
3. What evidence would prove responsibility transfer rather than merely component operation?

## Always preserve boundaries

Natural-language owner intent is never arbitrary executable shell. Require typed authority, bounded retries, semantic success, independent postconditions, idempotency, evidence and rollback. Never expose credentials/private message bodies/runtime secrets in the public repo/HQ. Never silently bless trust drift, weaken safety/audit, self-grant authority, move money, purchase, live trade, perform unauthorized public/third-party owner sends, or auto-promote novel YELLOW/RED authority.
