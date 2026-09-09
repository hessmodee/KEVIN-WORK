# LESSON — Invocation worker NativeCommandError (2026-09-08)

**Family:** `invocation-worker-fail-closed-v1` (OPEN)  
**Machine:** HESS-PC / OpenClaw workspace  
**Not PASS.** This lesson is the diagnosis. The 8-vehicle owner outcome remains unproven.

## Discriminating evidence

- Supervisor v1.8.12 independently proven: Support hash `F17F4B0A…`, typed `ALREADY_APPLIED_PROVEN` for `grok-install-v1812-20260908-2050`.
- Continuation `version=1.8.12` `status=BLOCKED_INVOCATION_RUNTIME` `selected_id=owner-west-motor-parts-chase-fresh-8-v1` `failure_sha256=68845506…` `eligible_count=7` `outcome_proven=false`. One burned turn at 09:31 kept.
- Missing-worker path does not set `failure`. `68845506` therefore means the worker script ran or threw.
- Live worker (`16C49542…`) uses `$ErrorActionPreference='Stop'` and native `& $py`. PowerShell wraps native stderr as `NativeCommandError`, which is terminating under Stop even when `LASTEXITCODE` is 0.
- v1.8.12 already Continue-wraps the nested `& powershell @workerArgs` and maps nonzero to `INVOCATION_WORKER_FAILED` without rethrow. Recopying Supervisor does not fix the inner native python throw.

## Rule

Do not treat `BLOCKED_INVOCATION_RUNTIME` + a failure hash as a missing worker. Do not send the WorkInstance to tool-less `fixed:main` or Skill Lab replay of an already-PROVEN skill. Smallest repair is a Continue + `ProcessStartInfo` `CreateNoWindow` wrap of native python (`worker-v1.1`, hash `7E1129B7…`) copied onto the live ControlPlane filename **after** the v1812 slot expires, because v1.3.53 still requires live worker `16C49542…` for that slot.

## Durable artifacts

- Source wrap: `control-plane/autonomy/kevin-proven-skill-invoke-worker-v1.1.ps1`
- Typed promotion runner (source only): `control-plane/maintenance/kevin-maintenance-runner-v1.3.55.ps1`
- Crossing: `docs/engineering/KEVIN-MAINTENANCE-V1355-INVOCATION-WORKER-V11.md`
- Family remains OPEN until a fresh `ROUTED_TO_PROVEN_SKILL_INVOCATION` or typed worker receipt on the same WorkInstance. PASS still requires workbook + note + hashes + immutable receipt.
