# Kevin Production Crossing v2 — YELLOW Candidate

Status: **YELLOW CANDIDATE ONLY — ZERO PRODUCTION EFFECT**  
Authority delta: **NONE**

This candidate closes a specific architectural gap discovered during the 2026-09-04 max repair pass: Maintenance v1 correctly refuses all production effects and therefore cannot install the already-qualified Kevin Desktop plugin or retire the legacy `KevinNightForge` Windows Scheduled Task.

The candidate intentionally supports exactly two request types:

1. `install_kevin_desktop_v0_1`
2. `install_kevin_desktop_list_folder_v0_2` (exact-4 → exact-5; list_folder only)
3. `retire_legacy_kevin_night_forge`

It is a pure validator/planner. It cannot run commands, write files, edit OpenClaw configuration, launch processes, access the network, mutate Windows Scheduled Tasks, install plugins or self-approve.

## Desktop crossing invariant

For `install_kevin_desktop_v0_1`, the only accepted target inventory for `fixed:main` is exactly the four tools in `docs/engineering/KEVIN-DESKTOP-TYPED-CROSSING-CONTRACT-2026-09-03.md`.

For `install_kevin_desktop_list_folder_v0_2`, the target inventory is exactly those four plus `kevin_desktop_list_folder` (five total), pinned to `docs/engineering/KEVIN-DESKTOP-LIST-FOLDER-CROSSING-CONTRACT-2026-09-04.md`, and requires the live before-state to already be exact-4. A fresh Benchmark 30/30 critical 0 precondition and rollback requirement are mandatory.

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
