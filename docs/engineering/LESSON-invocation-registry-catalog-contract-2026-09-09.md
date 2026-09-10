# LESSON — Invocation rejected Skill Lab's whole catalog (2026-09-09)

**Family:** `invocation-worker-fail-closed-v1` (OPEN until first PASS)  
**Machine:** HESS-PC / OpenClaw workspace  
**Not PASS.** This is the root-cause repair for `BLOCKED_INVOCATION_RUNTIME` + `failure_sha256=68845506…` after worker v1.1 was independently applied.

## Discriminating evidence

- Worker v1.1 is applied (`ALREADY_APPLIED_PROVEN` for `grok-install-worker-v11-20260909-1910`). Supervisor v1.8.12 is independently proven (`F17F4B0A…`) and must not be recopied.
- Continuation still publishes `INVOCATION_WORKER_FAILED exit=1`. That hash means the worker ran and threw. It does not name the python reason.
- Engineering queues stay `ready=0 / running=0 / done=66 / failed=1`. Stage never wrote the two GREEN orders.
- Skill Lab's proven catalog is the same file the invoker reads: `reports/capabilities/composite-skills.json`. Skill Lab allows `create_text`, `create_spreadsheet`, **and** `ui_notepad_write`. Several of the 27 PROVEN skills are 1-step create_text or Notepad recovery packs.
- Invocation v1.1.0 `validate_registry()` required **every** catalog entry to use only `create_text` + `create_spreadsheet`, and required `primitive_steps` to be a JSON array. PowerShell `ConvertTo-Json` serializes a 1-element array as a string.
- Either mismatch rejects the whole catalog with `SKILL_REGISTRY_UNAUTHORIZED_PRIMITIVE` or `SKILL_REGISTRY_INVALID_PRIMITIVES` before `west-motor-parts-chase-board-pack@1` is even selected. Worker v1.1 then throws `STAGE_REJECTED` → exit 1 → public `68845506`.

## Rule

Do not treat a Skill Lab catalog as an invocation-v1 allowlist. Catalog validation must accept Skill Lab's three GREEN primitives and coerce a 1-step `primitive_steps` string to a list. The **selected** skill still has to be `create_text` + `create_spreadsheet` only.

A second landmine: the request builder put `date.today()` in the operating note. Supervisor's RequestId is sticky (`invoke-<work-id>`). After the first successful stage, the next calendar day would raise `INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST`. The note is now deterministic.

## Kevin self-repair

1. Confirm worker v1.1 is applied. Do not recopy Supervisor. Do not send this job to `fixed:main`.
2. Run `tools/Repair-Kevin-InvocationRegistryContract-v1.ps1` once (fetch from GitHub if missing).
3. That copies invocation v1.1.1 + builder v1.0.1 and quarantines sticky run files for `invoke-owner-west-motor-parts-chase-fresh-8-v1`. It does not reset continuation history.
4. Let Supervisor select the same WorkInstance. If stage succeeds, wait Action Era to finish `create_spreadsheet` + `create_text`.
5. PASS remains workbook + note + DONE + hashes + immutable receipt.

## Durable artifacts

- `control-plane/autonomy/kevin-proven-skill-invocation-v1.py` (v1.1.1, catalog vs lane split)
- `control-plane/autonomy/kevin-proven-skill-request-builder-v1.py` (v1.0.1, deterministic note)
- `tools/Repair-Kevin-InvocationRegistryContract-v1.ps1`
- Tests: sibling Notepad catalog still stages; target Notepad still refuses; builder hash is stable
