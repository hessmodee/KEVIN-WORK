# Kevin AI Engineering Handover

Last reconciled: 2026-09-01 05:13 MDT

Start with `KEVIN-START-HERE.md`, then read fresh `inbox/CURRENT_TASK.md`, `inbox/autonomy/work-items.json`, `inbox/autonomy/state.json`, `reports/support-latest.json`, `reports/engineering/latest.json`, `reports/autonomy-latest.json`, `reports/runtime-convergence-omen.json`, `reports/runtime-capabilities-omen.json`, `reports/owner-outcomes-latest.json`, and current Maintenance/control-plane receipts. Fresh timestamps, request IDs, hashes and independent semantic postconditions outrank this narrative.

## North star

Build Kevin into a trustworthy local-first Chief of Staff that increasingly owns NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> CONTINUE for authorized GREEN work, with Bess removed from routine operation. Technical proof and transfer maturity remain separate:

`DESIGNED -> CI-PROVEN -> INSTALLABLE -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT`

Hard boundaries remain: no arbitrary shell/remote code authority, self-granted authority, silent trust-anchor blessing, secret/private-body leakage, safety weakening, purchases/money/live trades, unauthorized public/third-party owner sends, or novel YELLOW/RED auto-promotion.

## Fresh live truth — 05:10 MDT

Fresh Support generated 05:10:04 MDT reports:
- governance OK;
- Benchmark PASS 30/30 critical=0 at 05:06:49 MDT;
- observed Maintenance runner SHA256 `2DBE9FD6A93779CCB26C6BA5A13EBE94EEA56F0BFB3052C58E08B65F2526F8AF`;
- Maintenance Intake has six consecutive errors and is in long error backoff; latest Maintenance result at 05:09:14 is `ERROR: operation not allowlisted`;
- legacy Supervisor v1.6 remains installed at SHA256 `63B8D9C27625E0FB6AFE62165BE376E7ED7EB416E5DA15BB47C206BBF4AE4989`;
- legacy Forge remains installed at SHA256 `4C83DF29E765D61F2B26D2029FE6C2C7ED68DA90E5A7A457A82BE769029E22CA` and continued demandless work through iteration 380 at 05:08:52 MDT, REJECT with 8 failures and 1 security finding;
- active workers were zero in that snapshot.

The failed manifest `migrate-supervisor-forge-demand-gate-20260901-0317` was valid only for Maintenance v1.3.16, which is present and CI-proven on `main` but is not installed on the Omen. Feeding that operation to the older live runner caused the repeated allowlist errors.

At 05:12 MDT the single canonical writer replaced that guaranteed-failure slot with fixed GREEN `replace_pinned_component` manifest `install-maintenance-v1315-prereq-20260901-0512`:
- target alias: `maintenance_runner` only;
- expected current SHA256: `2DBE9FD6A93779CCB26C6BA5A13EBE94EEA56F0BFB3052C58E08B65F2526F8AF`;
- source/after SHA256: CI-qualified Maintenance v1.3.15 `F6C283AEFDC069AF528480AA59E0D1649AFEF251E638B901E18ACBCCBE282A2C`;
- source path fixed to `control-plane/maintenance/kevin-maintenance-runner-v1.3.15.ps1`;
- authority delta NONE; production effect NONE.

Do not claim this prerequisite INSTALLED until fresh Omen Maintenance + Support evidence proves the exact after hash and Benchmark remains clean. The next scheduled Maintenance attempt is delayed by existing error backoff.

## Why v1.3.15 first

`tools/generate-maintenance-v1316-supervisor-forge-demand-gate.py` deterministically builds v1.3.16 from exact v1.3.15 SHA256 `F6C283AEFDC069AF528480AA59E0D1649AFEF251E638B901E18ACBCCBE282A2C`. The v1.3.16 proof gate is CI-proven and publishes the exact candidate to main. v1.3.16 adds the fixed `migrate_supervisor_forge_demand_gated_v17` operation and rejects caller-selected Supervisor/Forge paths, hashes, args, command, host, and port.

The safe chain is therefore:
1. converge live Maintenance `2DBE9...` -> exact CI-qualified v1.3.15 through existing `replace_pinned_component`;
2. after terminal Omen proof, converge v1.3.15 -> exact CI-proven v1.3.16 through the same typed component-replacement authority using an independently recovered exact v1.3.16 source SHA;
3. only after v1.3.16 is Omen-proven, submit the fixed zero-parameter `migrate_supervisor_forge_demand_gated_v17` operation;
4. require exact Supervisor v1.7 + Forge v4 identities, fresh Benchmark 30/30, and behavioral no-spin proof before any convergence success claim.

Do not bypass the chain, broaden allowlists, or silently bless desired-state/hash drift.

## Supervisor / Forge root cause and target

The exact legacy Supervisor v1.6 source lineage proves the core admission defect: when normal missions cool, its Recovery -> Experiment path can manufacture a new runnable Forge mission with `blocked=false`, bypassing the modern deterministic work selector. This is why a BLOCKED Forge family continues to produce evaluations.

The qualified v1.3.16 migration is a coordinated compatibility repair. Its fixed Supervisor v1.7 candidate retires legacy candidate dispatch before the old Forge path, emits `SUPERVISOR IDLE NO_ELIGIBLE_MISSION`, returns fail-closed, and leaves governed selector/Task Flow admission as the owner of durable work. It stages Forge v4 only through the fixed known source and uses coordinated backup/rollback and Benchmark postconditions.

Acceptance remains behavioral, not hash-only:
- blocked Forge produces zero new evaluations across at least two scheduled Supervisor opportunities;
- cooled/blocked work stays blocked;
- no Recovery path manufactures replacement Forge demand;
- Kevin advances another eligible GREEN owner objective instead;
- Benchmark remains PASS 30/30 critical=0;
- exact installed identities and rollback evidence are recorded.

## Other lanes

Reader real E2E is BLOCKED after the first manifest expired and the bounded reissue exhausted the Maintenance failure budget. Do not create a renamed retry without materially new evidence.

Skill Workshop config writes are BLOCKED/COOLED after both JSON-value and materially different raw-string dry-run hypotheses failed closed. Only read-only installed CLI-contract diagnosis may reopen it.

HQ direct chat remains READY behind the active control-plane crossing. The existing exact CI-proven candidate is already on `main`; do not redesign it. Success requires typed install -> Omen selftest/privacy/idempotency -> truthful READY -> genuine Matt->Kevin->Matt correlated round trip -> restart/replay without duplicate -> channel health/recovery.

Staging trajectory reliability is READY and may use the staging/eval WIP slot if it has a concrete reusable trajectory and downstream consumer. Do not manufacture trivial evaluation activity.

Skill Lab has three production-proven composites; this is capability inventory, not owner-accepted outcome proof.

## Runtime doctrine / native runtime

Autonomy OS v2 five-file workspace doctrine is Omen identity-proven. Native audit proves Task Flow CLI and Skill Workshop are present, main-agent skills check and gateway deep probe succeed, Lobster is not registered, and OpenClaw version remains UNKNOWN. Do not claim unavailable version-specific features.

## Continuity / no-spin

Single canonical scheduled Chief Engineer is the only scheduled writer for mutable Kevin execution state. Never overwrite a fresh unconsumed/running item. Duplicate/expired receipt churn, heartbeat/dashboard commits, raw Forge cycles, CI-only candidates and PONG/model smoke are not accomplishments.

When one lane blocks, advance another useful authorized standing program. Repeated manual Bess intervention is autonomy debt and should become an observable typed Kevin capability where safely possible.
