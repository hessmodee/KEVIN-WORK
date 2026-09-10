# LESSON — PowerShell proof pin vs Python rehash (2026-09-10)

**Family:** `invocation-worker-fail-closed-v1` (OPEN until first PASS)  
**Machine:** HESS-PC / OpenClaw workspace  
**Not PASS.** Follows `LESSON-invocation-registry-catalog-contract-2026-09-09.md`.

## Discriminating evidence

- Catalog repair ran at 12:53 MT: live invocation `75D6031E…`, builder `93A8A881…`, `reason=REGISTRY_CONTRACT_REPAIRED`, `repair exit=0`.
- Continuation 13:23 MT is still `BLOCKED_INVOCATION_RUNTIME` / `failure_sha256=68845506…`. Engineering 13:27 MT Action Era `ready=0`.
- Worker v1.1 is applied. Supervisor v1.8.12 must not be recopied. 68845506 still means the worker threw (python exit non-zero), not a missing script.
- Skill Lab proves skills in PowerShell and stores `manifest_sha256 = HO(manifest)` (ConvertTo-Json canonicalization). Invocation v1.1.1 then required `sha256_obj(parsed_manifest) == entry["manifest_sha256"]` using Python `json.dumps(sort_keys=True)`. Those hashes are different functions. After the catalog gate opened, stage can fail closed on `PRESERVED_PROOF_MANIFEST_MISMATCH` for every Skill Lab proof.
- Windows PowerShell 5.1 may also persist `/Date(ticks)/` timestamps. v1.1.1 `valid_timestamp` rejected them (`len` / `fromisoformat`).

## Rule

Do not re-hash a Skill Lab proof body with a second canonicalizer. The identity pin is the stored `manifest_sha256` / `proof_sha256` pair. Bind the **operations sequence** from the preserved proof JSON; do not demand Python `sha256_obj(manifest)` equal PowerShell `HO(manifest)`.

Kevin must publish the python reason-code. Public `68845506` is only `SHA256("INVOCATION_WORKER_FAILED exit=1")` and cannot teach the next repair.

## Kevin self-repair

1. Confirm catalog python is live (`75D6031E…` or later `471E5051…`). Do not recopy Supervisor. Do not send the 8-vehicle job to `fixed:main`.
2. Run `tools/Repair-Kevin-InvocationRegistryContract-v1.ps1` then `tools/Diagnose-Kevin-InvocationStage-v1.ps1` (GitHubBridge v1.3 does both). Diagnose uses an isolated queue and uploads `reports/invocations/latest-public-reject.json` with the reason-code only.
3. If reason is `PRESERVED_PROOF_MANIFEST_MISMATCH` or a `/Date()` timestamp reject, invocation v1.1.2 is the repair (`471E5051…`).
4. Let Supervisor select the same WorkInstance. Keep the 09:31 burned turn.
5. PASS remains workbook + note + DONE + hashes + immutable receipt.

## Durable artifacts

- `control-plane/autonomy/kevin-proven-skill-invocation-v1.1.2.py` (`471E5051…`)
- `tools/Diagnose-Kevin-InvocationStage-v1.ps1`
- `omen/pull-inbox.ps1` v1.3
- Tests: PowerShell pin trusted; mismatched stored pin still refuses; `/Date()` accepted; catalog sibling Notepad still stages
