# Maintenance v1.3.52 — Supervisor v1.8.11 + invocation worker

**Status:** source candidate. Not HESS-PC installed.  
**Authority delta:** NONE. GREEN-C typed self-improvement through existing rollback/Benchmark gates.  
**Does not** change `inbox/maintenance/manifest.json`.

## Why this exists

HESS-PC still runs Maintenance **v1.3.51** (`2D7F65C97A…`) and Supervisor **v1.8.10** (`BDA265AC…`). Proven Skill Invocation v1 is on `main` as source only. Live 1.3.51 can install v1.8.10 again (idempotent) and can `replace_pinned_component` for allowlisted aliases. It cannot:

- install Supervisor v1.8.11 (`replace_pinned_component` rejects alias `supervisor`);
- copy `ControlPlane\kevin-proven-skill-invoke-worker-v1.ps1`;
- call a verb named `install_autonomy_controller_v1811`.

Until a newer runner is itself installed, a v1811 manifest would ERROR `operation not allowlisted`.

## Pins (LF Git blobs / Windows Get-FileHash)

| Identity | SHA-256 |
|---|---|
| Candidate Maintenance v1.3.52 (LF Git blob) | `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24` |
| Installed Maintenance v1.3.51 (current) | `2D7F65C97A2934E7C34FEFF86BD317E84D0E73D6CABD9AC1D99DF0FF32448EAD` |
| Parent of v1.3.52 | same v1.3.51 hash |
| Supervisor expected-current (v1.8.10) | `BDA265ACCB929EC5129B2F38AC76FE276625A604052304FC32C917700BCB532E` |
| Supervisor expected-after (v1.8.11) | `685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79` |
| Selector v1.2 (unchanged) | `52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A` |
| Canonical invocation worker | `16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332` |
| Request builder | `8E1CDB6911A4F087099788C1DAD9E5A425686B63A6FED471E49D9478688ACCF9` |
| Invocation v1 python | `63FA334B85F895894481DF59314326F6F0F4B0785553B8FDD33DFBFC0E88147C` |
| Forge v4.0 baseline (must not change) | `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A` |

Recompute the v1.3.52 runner hash on Windows after this file is on `main` if bytes change. Current LF Git blob is `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24`. Use that hash as `expected_after_sha256` for the Maintenance-runner crossing.

## Two-step ladder — do not skip

This PR only lands source. Live canary `matt-fresh-main-canary-20260908-0716` stays.

1. **Merge this source to `main`.** Maintenance v1.3.51 can then fetch `control-plane/maintenance/kevin-maintenance-runner-v1.3.52.ps1` from GitHub `main`.
2. **Install the runner** with `replace_pinned_component` / `target_alias=maintenance_runner`:
   - `source_path`: `control-plane/maintenance/kevin-maintenance-runner-v1.3.52.ps1`
   - `expected_current_sha256`: `2D7F65C97A2934E7C34FEFF86BD317E84D0E73D6CABD9AC1D99DF0FF32448EAD`
   - `source_sha256` = `expected_after_sha256` = SHA-256 of the v1.3.52 runner
   - Self-test marker remains `KEVIN MAINTENANCE v1.3.3 SELFTEST PASS`
3. **Only after Support proves the new Maintenance hash**, queue a second GREEN manifest `operation: install_autonomy_controller_v1811` with no extra properties. That op copies Supervisor v1.8.11, selector v1.2 (if needed), the canonical worker, and the two Python files; rewrites the Benchmark supervisor pin; requires selftest markers `proven_skill_before_skill_lab=true invocation_not_main=true`; requires fresh Benchmark 30/30; rolls back on failure; preserves continuation history / work-items / leases.

Do not put step 3 on `inbox/maintenance/manifest.json` while v1.3.51 is still the installed runner.

## WorkInstance hold

`owner-west-motor-parts-chase-fresh-8-v1` stays OPEN/GREEN with fictional 8-vehicle `owner_inputs`, but `blocked=true` until invocation runtime is independently effective. Installed v1.8.10 does not read `required_skill_key` and would send `capability-reuse` work to tool-less `fixed:main`. Unblock only after a fresh continuation receipt shows `ROUTED_TO_PROVEN_SKILL_INVOCATION` is possible (worker present, Supervisor v1.8.11 installed). A stage receipt is still not an owner outcome.

## Not this PR

- No live Maintenance manifest mutation.
- No Engineering Relay verb invention.
- No Skill Lab replay of `west-motor-parts-chase-board-pack@1`.
- No history/budget reset.
- No claim that this GitHub source is HESS-PC installation.
