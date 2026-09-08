# LESSON — Maintenance StrictMode missing `idempotent` on first-apply receipt

**Date:** 2026-09-08  
**Failure family:** `maintenance-strictmode-missing-idempotent-receipt`  
**Layer:** execution / persistence (publisher), not capability, not authority  
**Owner objective interrupted:** first fresh invoke of `west-motor-parts-chase-board-pack@1` on `owner-west-motor-parts-chase-fresh-8-v1`

## What happened

Maintenance v1.3.53 copied Supervisor v1.8.12 onto HESS-PC. Support hashed `kevin-supervisor.ps1` as `F17F4B0A…`. The wrapper then did `$status=if([bool]$result.idempotent)` under `Set-StrictMode -Version 2.0`. The first-apply result was `[ordered]@{changed=$true; ...}` with no `idempotent` key. StrictMode turned that into ERROR: "The property 'idempotent' cannot be found on this object." Save-State never published `APPLIED_PREAUTHORIZED_PROVEN`. The inner install catch did not roll the files back because the throw happened in the caller after a successful return.

## Discriminating test

- If rollback had run, Support would still hash supervisor `685B34F3…` (v1.8.11).
- Observed: Support hashes `F17F4B0A…` (v1.8.12) and Maintenance ERROR names `idempotent`.
- Therefore: copy succeeded; publisher failed.

## Repair recipe

1. Every install result must include `idempotent` on both `changed=$true` and `changed=$false` paths.
2. Never read `$result.idempotent` as a property under StrictMode. Use `Get-InstallStatus` / IDictionary key access.
3. Selftest must reproduce the StrictMode throw on an omitted key and assert both receipt statuses.
4. Keep the live `install_autonomy_controller_v1812` slot queued so the already-applied path (`idempotent=$true`) can publish the missing receipt without a runner replacement.

## Prevention

- Contract test `tests/test_maintenance_v1354_contract.py` requires `idempotent=$false` on the first-apply return and forbids `$status=if([bool]$result.idempotent)`.
- Source runner: `control-plane/maintenance/kevin-maintenance-runner-v1.3.54.ps1`.
- Do not install v1.3.54 in front of the v1812 typed receipt.
- Do not treat a file hash as a typed apply receipt.
- Do not treat a continuation snapshot that predates the file hash as the live controller identity.

## Resume

Original objective is unchanged: independently prove v1.8.12 with a typed receipt and a fresh continuation, then invoke the 8-vehicle parts-chase skill. A repair that forgets that objective is incomplete.
