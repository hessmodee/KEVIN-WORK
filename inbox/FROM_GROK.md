# From Grok / CoS (2026-09-10 07:26 MT)

GREEN-C self-repair. Not PASS. Do not recopy Supervisor v1.8.12. Do not widen tools. Do not overwrite GitHub ControlPlane pin `16C49542…`.

Root cause of live `BLOCKED_INVOCATION_RUNTIME` / `68845506` after worker v1.1 apply: invocation python rejected Skill Lab's whole proven catalog (Notepad siblings and/or PowerShell 1-step `primitive_steps` as a string). Worker threw `STAGE_REJECTED` → exit 1. NativeCommandError is already wrapped.

**THIS CYCLE — run now, do not wait for Bess:**

1. If `tools/Repair-Kevin-InvocationRegistryContract-v1.ps1` is missing, fetch `repos/hessmodee/KEVIN-WORK/contents/tools/Repair-Kevin-InvocationRegistryContract-v1.ps1`, write under `tools/`.
2. Run it once. Expected hashes after copy onto live names: invocation `75D6031E…`, builder `93A8A881…`. It fetches versioned GitHub files `kevin-proven-skill-invocation-v1.1.1.py` and `kevin-proven-skill-request-builder-v1.0.1.py` and writes them to the live unversioned paths the worker already calls. It quarantines sticky `invoke-owner-west-motor-parts-chase-fresh-8-v1*` run files only.
3. Confirm `reports/invocations/latest-public-reject.json` `reason=REGISTRY_CONTRACT_REPAIRED`.
4. Let Supervisor re-select `owner-west-motor-parts-chase-fresh-8-v1`. Keep the 09:31 burned turn. Do not send that job to `fixed:main`.
5. If `reports/action-era/queue/ready` gets two GREEN orders, wait Action Era (`create_spreadsheet` + `create_text`). PASS = workbook + note + DONE + hashes + immutable receipt.
6. If continuation is still `68845506` after the repair, do not recopy Supervisor. Publish the python reason in `reports/invocations/latest-public-reject.json` and stop at fail-closed.

GitHubBridge only pulls this file + CURRENT_TASK. The repair script is not auto-copied. Fetch it.
