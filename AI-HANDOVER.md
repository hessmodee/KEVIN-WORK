# Kevin AI Engineering Handover

Last reconciled: 2026-09-01 18:12 MDT

Start with `KEVIN-START-HERE.md`, then read fresh `inbox/CURRENT_TASK.md`, `inbox/autonomy/work-items.json`, `inbox/autonomy/state.json`, `reports/support-latest.json`, `reports/engineering/latest.json`, `reports/autonomy-latest.json`, `reports/runtime-convergence-omen.json`, `reports/runtime-capabilities-omen.json`, `reports/owner-outcomes-latest.json`, `reports/main-agent-canary-omen.json`, and current Maintenance/control-plane receipts. Fresh timestamps, request IDs, hashes and independent semantic postconditions outrank this narrative.

## North star

Build Kevin into a trustworthy local-first Chief of Staff that increasingly owns NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> CONTINUE for authorized GREEN work, with Bess removed from routine operation. Technical proof and transfer maturity remain separate:

`DESIGNED -> CI-PROVEN -> INSTALLABLE -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT`

Hard boundaries remain: no arbitrary shell/remote code authority, self-granted authority, silent trust-anchor blessing, secret/private-body leakage, safety weakening, purchases/money/live trades, unauthorized public/third-party owner sends, or novel YELLOW/RED auto-promotion.

## Fresh live truth — 18:12 MDT

Fresh Support generated 18:05:04 MDT reports:
- governance OK;
- Benchmark PASS 30/30 critical=0 at 18:04:57 MDT;
- Supervisor SHA256 `47A0A1D0E3F744E972E2F2239F100CA2B009ABD3928D0281E4587A364B7C27AC`, zero consecutive failures, current result `NO_ELIGIBLE_MISSION`;
- Forge v4 SHA256 `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A`;
- latest Forge evaluation remains iteration 391 from 07:06 MDT, so there is still no renewed Forge churn;
- all listed core schedulers, including Maintenance Intake, have zero consecutive errors;
- latest Maintenance result for `main-agent-canary-v1339-20260901-1802` is `APPLY_FAILED` because the main-agent canary semantic contract rejected;
- active engineering workers were zero in the snapshot.

Fresh fixed main-agent canary generated 18:09:41 MDT materially changes the blocker:
- `gateway_probe_ok=true`;
- fixed main agent executed with exit code 0 and overall CLI status `ok`;
- canary made zero tool calls;
- canary state is `REJECT` at `failure_stage=semantic_contract` because `exact_expected_reply=false`;
- prompt-visible tool surface count is eight, but visible Kevin tool count is zero and `kevin_system_status` is absent.

Therefore the old `gateway_probe` failure is retired. Do not diagnose Gateway transport as broken from stale receipts and do not downgrade OpenClaw on that retired evidence. The active boundary is main-agent semantic-contract/tool-policy alignment.

Fresh Engineering generated 18:08:12 MDT reports all listed schedulers healthy with zero consecutive errors and Benchmark 30/30. Its stale Engineering Relay request `diagnose-recovery-task-20260901-1541` remains REJECTED because `system_diagnostics` is not allowlisted. Its UI Bridge heartbeat age is about 16,696 seconds, so task/hash presence must not be treated as live UI proof.

Autonomy checkpoint generated 17:20:09 MDT remains `NEEDS_REVIEW`, drift_count=3, zero active engineering workers and `NO_DISPATCH_NEEDED`. That is older than the current canary but still demonstrates that no T3 autonomy proof exists.

## Current P0 — main-agent semantic-contract / tool-policy alignment

The fixed main-agent runtime path now crosses Gateway transport and executes a real main-agent turn. The remaining failure is semantic, not transport.

The current boundary is therefore:
1. classify why the fixed main-agent turn did not return the exact expected semantic reply;
2. distinguish an over-constrained/incorrect canary expectation from missing main-agent tool/policy exposure;
3. use read-only installed runtime/help/schema/config-validation evidence before any write;
4. if repair is truly required, use only a narrow typed GREEN operation with exact preconditions, rollback and Benchmark postcondition;
5. rerun the fixed main-agent canary only after materially changed evidence and require Gateway probe OK, agent exit 0, exact semantic reply, zero canary tool calls and fresh Benchmark 30/30;
6. do not treat the absence of `kevin_system_status` as Reader proof; this is main-agent canary/tool-surface evidence only.

## Work inventory / WIP

Authoritative `inbox/autonomy/state.json` has production=0, staging=0, research=0 active WIP.

READY:
- production: `hq-direct-chat-real-roundtrip`;
- staging: `staging-trajectory-reliability-v1`.

BLOCKED:
- Forge convergence family remains BLOCKED for further migration retries; preserve observation/read-only diagnosis unless materially new evidence opens it;
- Reader E2E remains BLOCKED after exhausted execution-path attempts;
- Skill Workshop config writes remain BLOCKED/COOLED until read-only installed CLI/schema/version evidence materially changes the hypothesis.

Gateway transport failure classification is now COMPLETE. Do not manufacture activity in blocked families. A blocked lane must not stop independent useful GREEN work.

## Runtime doctrine / native runtime

Autonomy OS v2 five-file workspace doctrine is Omen identity-proven. `reports/runtime-capabilities-omen.json` is an older checkpoint relative to current Support/canary: it proves Task Flow CLI present with one flow, Skill Workshop CLI present, main-agent skills check OK at that checkpoint, and Lobster not registered, but OpenClaw version remains UNKNOWN. Its historical Gateway deep-probe success is now corroborated by the fresh canary `gateway_probe_ok=true`, while actual per-turn semantic/tool behavior is governed by the newer canary evidence.

## HQ direct chat

Direct Matt <-> Kevin communication remains the next owner-value crossing after fixed-main-agent semantic proof. Prefer native OpenClaw Control UI/WebChat first. Keep public GitHub Pages HQ read-only and sanitized. The existing `candidates/communications/hq-direct-chat` bundle remains fallback/private-adapter material and should not be redesigned merely because source exists.

Success requires genuine Matt -> Kevin -> Matt correlated round trip, session continuity, restart/replay/idempotency, health/recovery evidence, and no private message bodies/secrets committed publicly.

## Continuity / no-spin

Single canonical scheduled Chief Engineer is the only scheduled writer for mutable Kevin execution state. Never overwrite a fresh unconsumed/running item. Duplicate/expired receipt churn, heartbeat/dashboard commits, raw Forge cycles, CI-only candidates and model smoke are not accomplishments.

When one lane blocks, advance another useful authorized standing program. Repeated Bess intervention is autonomy debt and should become an observable typed Kevin capability where safely possible. Work selection remains T2 until Kevin independently notices available work, selects it, executes it, semantically verifies the outcome, records the result and continues; repeated unrelated examples are required before T4.
