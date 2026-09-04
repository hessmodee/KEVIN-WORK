# Kevin Production Crossing v2 — YELLOW Candidate

Status: **YELLOW CANDIDATE ONLY — ZERO PRODUCTION EFFECT**  
Authority delta: **NONE**

This candidate closes a specific architectural gap discovered during the 2026-09-04 max repair pass: Maintenance v1 correctly refuses all production effects and therefore cannot install the already-qualified Kevin Desktop plugin or retire the legacy `KevinNightForge` Windows Scheduled Task.

The candidate intentionally supports exactly two request types:

1. `install_kevin_desktop_v0_1`
2. `retire_legacy_kevin_night_forge`

It is a pure validator/planner. It cannot run commands, write files, edit OpenClaw configuration, launch processes, access the network, mutate Windows Scheduled Tasks, install plugins or self-approve.

## Desktop crossing invariant

The only accepted target inventory for `fixed:main` is exactly:

- `kevin_system_status`
- `kevin_desktop_find_folder`
- `kevin_desktop_open_folder`
- `kevin_app_launch`

Any extra, missing or reordered tool is rejected. The source contract is pinned to `docs/engineering/KEVIN-DESKTOP-TYPED-CROSSING-CONTRACT-2026-09-03.md`. A fresh Benchmark 30/30 critical 0 precondition and rollback requirement are mandatory.

## Legacy task retirement invariant

The only scheduled task name this candidate recognizes is `KevinNightForge`. It requires already-proven replacement scheduling, fresh Benchmark 30/30 and rollback. A future live wrapper must disable first, observe, verify no semantic regression, and only then remove the exact task.

## Promotion bar

A later Windows/OpenClaw live wrapper may be considered only after:

- exact installed config/schema/plugin identity is captured;
- exact before-state hashes/checkpoints are pinned;
- owner approval is explicit and bound to the request;
- mutation verbs remain code-owned and target-fixed;
- positive and forbidden negative tests pass on HESS-PC;
- postcondition evidence proves the exact effective tool/task state;
- rollback is tested;
- fresh Benchmark remains 30/30 critical 0;
- sanitized Support/Engineering evidence is published.

This file is not permission to apply either change.
