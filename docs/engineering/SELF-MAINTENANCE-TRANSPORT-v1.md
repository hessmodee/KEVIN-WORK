# Kevin Self-Maintenance Transport v1

Status: CANDIDATE ONLY. No production authority is granted by this document.

## Problem being solved

Kevin can already stage and validate maintenance through GitHub, but Maintenance v1.1d is scheduled with `-CheckOnly`. A legacy executable maintenance package therefore requires one local `-ApplyOnce` invocation. The existing Engineering Relay, Work Order Intake, and Autonomy Actuator intentionally cannot supply arbitrary PowerShell arguments, edit automation argv, or execute a maintenance package. That is a sound safety boundary, but it creates a one-time bootstrap dependency on the owner keyboard.

The target architecture removes that dependency permanently without creating arbitrary remote code execution.

## Evidence from the installed control plane

The recovered exact Work Order Intake reads `control-plane/orders/CURRENT.json` from branch `kevin-control-plane-v1`. Its installed allowlist contains `dispatch_mission`, `run_reconcile`, `run_benchmark`, `run_support_bridge`, and `refresh_autonomy_telemetry`; it has no maintenance verb. The exact Autonomy Actuator implementation of `enable_expected_automation` only enables an already-known automation by ID. It does not create a job or alter argv.

Maintenance v1.3 therefore adds self-maintenance at the maintenance layer rather than widening the generic relay.

## Permanent authority model

Remote work orders may add exactly one convenience verb: `run_typed_maintenance` with exact target `kevin-maintenance-v1`. The order contains no command, argv, executable, path, URL, task definition, or embedded manifest. The local Intake maps that verb to one fixed command: the locally installed `kevin-maintenance-runner.ps1 -CheckOnly`.

The maintenance runner independently retrieves `inbox/maintenance/manifest.json` and validates it. Schema-3 self-maintenance manifests are GREEN, owner-preauthorized, zero-authority-delta, zero-production-effect, expiry-bounded, replay/failure-budgeted, and hash pinned.

Allowed replacement aliases are fixed in local code:

- `maintenance_runner` -> local Kevin Maintenance Runner; source root only `control-plane/maintenance/`
- `work_order_intake` -> local Kevin Work Order Intake; source root only `control-plane/intake/`
- `skill_lab_runner` -> local Kevin Skill Lab; source root only `control-plane/skill-lab/`

UI Bridge remains a separate exact `restart_ui_bridge` operation for task `Kevin UI Bridge v0.3` with pinned bridge hash and fresh READY-heartbeat postcondition.

A manifest cannot choose a local target path. A source path valid for one alias is invalid for every other alias. Before bytes replace a target, Kevin verifies the exact current SHA256, fetches only from that alias's repository root, verifies exact source/after SHA256, parses PowerShell, runs the candidate's fixed self-test, backs up the old target, atomically replaces it, reruns fixed self-test, and requires a fresh Benchmark 30/30 critical=0. Failure rolls back.

This allows the maintenance runner to upgrade itself. That is deliberate: otherwise every future maintenance-runner upgrade recreates the same bootstrap paradox. Self-upgrade is not self-authorization because the local executable identity, repository source root, exact before hash, exact after hash, owner policy, and operation type remain fixed and independently validated before mutation.

## External watchdog

A second layer must live outside the OpenClaw scheduler so the scheduler cannot be its own only watchdog. The candidate Windows watchdog uses only these exact OpenClaw CLI operations:

1. `gateway status --require-rpc --json`
2. on failure only, `gateway restart --wait 30s --json`
3. post-restart, the same RPC health probe.

It has a three-attempt failure budget and a 15-minute cooldown. It consumes no GitHub payload and accepts no caller command/argv/path. Windows Task Scheduler should use `MultipleInstances=IgnoreNew`, `StartWhenAvailable`, and bounded restart settings. Microsoft documents `IgnoreNew` specifically to prevent overlapping task instances and supports restart-count/restart-interval settings.

## Remote administration research conclusions

OpenClaw command automations are a legitimate deterministic local execution surface: exact argv command jobs execute inside the Gateway scheduler, and mutation of those jobs requires `operator.admin`. This supports our fixed local reconciler design; it does not justify giving a model generic exec.

OpenClaw recommends keeping the Gateway loopback-only. If remote operator access is later needed, use loopback + Tailscale Serve or an SSH tunnel rather than public exposure. Do not use Funnel solely to solve maintenance transport. Do not add a GitHub self-hosted runner to the public KEVIN-WORK repository: public-repo workflow input would create a much broader remote-code trust boundary than Kevin needs.

## Required proof sequence before promotion

1. Python policy adversarial tests pass.
2. Windows PowerShell 5.1 parser + self-tests pass for Maintenance v1.3, Intake v1.2.1, and watchdog v1.
3. Static scan proves no Invoke-Expression, dynamic ScriptBlock, caller command/argv/path, arbitrary scheduled-task name, or arbitrary remote source root.
4. Maintenance self-upgrade fixture proves exact before -> exact after -> self-test -> fresh Benchmark, plus rollback on postcondition failure.
5. Intake fixture proves all five old verbs remain valid and `run_typed_maintenance` maps only to the fixed maintenance runner with `-CheckOnly`.
6. Replay, expired order, unknown field, wrong target, YELLOW/RED, command/argv injection, and source-root-crossing tests fail closed.
7. Watchdog failure/recovery fixtures prove bounded restart and cooldown.
8. Omen live proof after the one-time legacy bootstrap: new Maintenance exact hash, Skill Lab v1.0.3 recovery, UI Bridge fresh heartbeat, Intake upgrade, fresh Benchmark 30/30 critical=0.
9. Only after all evidence exists may the old keyboard-dependent bootstrap be declared retired.
