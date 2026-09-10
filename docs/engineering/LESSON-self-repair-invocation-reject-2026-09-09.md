# LESSON — Kevin self-repairs invocation rejects without Bess SSH (2026-09-09)

**Authority:** GREEN-C. Recipe only. Not PASS. Does not recopy Supervisor v1.8.12. Does not widen desktop tools.

## Why this lesson exists

Worker v1.1 is applied. Continuation still publishes `BLOCKED_INVOCATION_RUNTIME` with public `failure_sha256=68845506…`. Public continuation hashes only `INVOCATION_WORKER_FAILED exit=N`. The real reason (`BUILDER_REJECTED` / `STAGE_REJECTED` / `RECONCILE_REJECTED` plus a code) lives on HESS-PC under `reports/invocations/`.

Kevin can read that himself.

## Recipe

1. Confirm Support `maintenance.status` is `APPLIED_PREAUTHORIZED_PROVEN` or `ALREADY_APPLIED_PROVEN` for `install_invocation_worker_v11`. If the worker is missing, stop and wait Maintenance. Do not call `fixed:main`.
2. If this workspace has `tools/Publish-Kevin-InvocationReject-Public-v1.ps1`, run it **once**. If missing, fetch it from GitHub the same way GitHubBridge pulls inbox files, write it under `tools/`, then run once.
3. Read `reports/invocations/latest-public-reject.json`. Classify:

| family | meaning | Kevin repair |
|---|---|---|
| BUILDER_REJECTED | work-items / vehicles / id shape | Fix `inbox/autonomy/work-items.json` owner_inputs.vehicles to eight complete fictional rows. Do not invent live customer data |
| STAGE_REJECTED + JSON_MISSING_OR_UNSAFE / PROVEN_SKILL_NOT_FOUND | registry or proof file missing | Restore `reports/capabilities/composite-skills.json` and `reports/action-era/skills/done/<result_file>` from the already-PROVEN pack. Do not recreate the skill |
| STAGE_REJECTED + INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST | sticky RequestId `invoke-<work-id>` | Hash the old run file into a lesson, quarantine only that run file, do not wipe continuation history |
| RECONCILE_REJECTED / status RUNNING | Action Era has not finished the two GREEN primitives | Wait the Action Era worker. Staging is progress |
| PYTHON_NOT_AVAILABLE | python missing on PATH for hidden process | Escalate with evidence. Do not install packages ad hoc |

4. Write a one-page lesson with the reason code. Resume the same WorkInstance. Keep the 09:31 burned turn.
5. PASS remains workbook + note + DONE + hashes + receipt. This recipe is not PASS.

## Hard nos

Do not reset budgets. Do not send this WorkInstance to tool-less `fixed:main`. Do not invent a new Engineering Relay verb. Do not treat a published reject JSON as an owner outcome.
