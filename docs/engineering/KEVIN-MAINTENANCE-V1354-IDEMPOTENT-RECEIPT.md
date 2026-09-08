# Maintenance v1.3.54 — StrictMode idempotent receipt

**Status:** SOURCE ONLY. Do not install this runner in front of the live `install_autonomy_controller_v1812` typed receipt. Support already hashes Supervisor as `F17F4B0A…` (v1.8.12 file identity). The first-apply publisher crashed; the already-applied path on v1.3.53 can still publish `ALREADY_APPLIED_PROVEN`. v1.3.54 is the failure-family prevention so the next `changed=$true` install cannot repeat this ERROR.

**Authority delta:** NONE. GREEN-C typed self-improvement through existing rollback/Benchmark gates.

**Pins (LF Git blobs / Windows Get-FileHash)**

| Identity | SHA-256 |
|---|---|
| Parent Maintenance v1.3.53 (installed) | `EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50` |
| Maintenance v1.3.54 (this source, not installed) | `CD035301E8711E18E4AB03A3556F1197CCF0AB20E109287EDBBDBF277BD5CAE7` |
| Supervisor v1.8.12 | `F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB` |
| Canonical invocation worker (unchanged) | `16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332` |

## Discriminating evidence

Support `2026-09-08T15:03:37-06:00` hashes supervisor `F17F4B0A…` and runner `EF32D990…`. Maintenance at 15:03:23 is `ERROR` / "The property 'idempotent' cannot be found on this object." Continuation 14:30 is still `CONTROLLER_ERROR` / v1.8.11 and predates the copy.

Two hypotheses:

1. The v1.8.12 copy failed and rolled back; the Support hash is wrong.
2. The copy/selftest/Benchmark succeeded; `Set-StrictMode -Version 2.0` then threw on `$result.idempotent` because the first-apply ordered hashtable omitted the key; the inner rollback catch did not run.

The Support hash matching the v1.8.12 pin discriminates for (2).

## Repair

- First-apply return includes `idempotent=$false`.
- Replay return already includes `idempotent=$true`.
- Status is `Get-InstallStatus`, which reads IDictionary keys and never uses StrictMode property access on a missing name.
- Selftest reproduces the StrictMode throw on the omitted key and asserts both receipt statuses.

Does not change Supervisor, worker, selector, desktop exact-five, invocation allowlist, histories, or Engineering Relay verbs.

## Install order — do not skip

1. Keep live `install_autonomy_controller_v1812` queued until a typed `ALREADY_APPLIED_PROVEN` / `APPLIED_PREAUTHORIZED_PROVEN` receipt exists for that id.
2. Merge this source to `main`. That is not installation.
3. Only then queue `replace_pinned_component` / `target_alias=maintenance_runner` for v1.3.54 (`expected_current=EF32D990…`, `expected_after=CD035301…`).
4. First owner outcome remains the 8-vehicle invoke. This runner is not PASS.

## Not this source write

- No Engineering Relay verb invention.
- No Skill Lab replay of `west-motor-parts-chase-board-pack@1`.
- No history/budget reset.
- No claim that this GitHub source is HESS-PC installation or an owner outcome.
- No send of the 8-vehicle WorkInstance to tool-less `fixed:main`.
