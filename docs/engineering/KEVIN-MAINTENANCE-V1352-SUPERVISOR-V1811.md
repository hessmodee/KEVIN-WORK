# Maintenance v1.3.52 — Supervisor v1.8.11 + invocation worker

**Status:** Maintenance v1.3.52 is installed on HESS-PC. Support 2026-09-08T10:00:18-06:00 hashes workspace `kevin-maintenance-runner.ps1` as `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24`. Typed receipt for `grok-install-maint-v1352-20260908-1555` is `ALREADY_APPLIED_PROVEN`. Supervisor remains v1.8.10 (`BDA265AC…`) until `install_autonomy_controller_v1811` independently proves the crossing.  
**Authority delta:** NONE. GREEN-C typed self-improvement through existing rollback/Benchmark gates.  
**Live slot:** `inbox/maintenance/manifest.json` is now `operation: install_autonomy_controller_v1811` id `grok-install-v1811-20260908-1625` with no extra properties. Queueing is not installation.


## Why this exists

HESS-PC still runs Supervisor **v1.8.10** (`BDA265AC…`). Maintenance **v1.3.52** (`C5ECCE66…`) is now the installed runner, so it can:

- intercept `install_autonomy_controller_v1811` (parent 1.3.51 still cannot);
- copy Supervisor v1.8.11, selector v1.2 if needed, the canonical invocation worker, and the two Python files;
- refuse extra properties, preserve histories, require Benchmark 30/30, and roll back on failure.

`replace_pinned_component` still rejects alias `supervisor`. That is why the live slot uses the v1811 verb instead of a generic replace.

Until `install_autonomy_controller_v1811` independently proves the crossing, Supervisor v1.8.11 and the invocation worker remain source-only.



## Pins (LF Git blobs / Windows Get-FileHash)

| Identity | SHA-256 |
|---|---|
| Installed Maintenance v1.3.52 (Support 2026-09-08T10:00:18-06:00) | `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24` |
| Parent of v1.3.52 / retired installed 1.3.51 | `2D7F65C97A2934E7C34FEFF86BD317E84D0E73D6CABD9AC1D99DF0FF32448EAD` |
| Supervisor expected-current (v1.8.10) | `BDA265ACCB929EC5129B2F38AC76FE276625A604052304FC32C917700BCB532E` |
| Supervisor expected-after (v1.8.11) | `685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79` |
| Selector v1.2 (unchanged) | `52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A` |
| Canonical invocation worker | `16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332` |
| Request builder | `8E1CDB6911A4F087099788C1DAD9E5A425686B63A6FED471E49D9478688ACCF9` |
| Invocation v1 python | `63FA334B85F895894481DF59314326F6F0F4B0785553B8FDD33DFBFC0E88147C` |
| Forge v4.0 baseline (must not change) | `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A` |

LF Git blob of the installed v1.3.52 runner is `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24`. Recompute on Windows Get-FileHash if those bytes change.


## Two-step ladder — current position

1. **Merge v1.3.52 source to `main`.** DONE (PR 157).
2. **Install the runner** with `replace_pinned_component` / `target_alias=maintenance_runner`. DONE on HESS-PC: Support hash `C5ECCE66…` and typed `ALREADY_APPLIED_PROVEN` for `grok-install-maint-v1352-20260908-1555`. Archived that replace manifest.
3. **NOW:** live GREEN manifest `operation: install_autonomy_controller_v1811` with no extra properties. That op copies Supervisor v1.8.11, selector v1.2 (if needed), the canonical worker, and the two Python files; rewrites the Benchmark supervisor pin; requires selftest markers `proven_skill_before_skill_lab=true invocation_not_main=true`; requires fresh Benchmark 30/30; rolls back on failure; preserves continuation history / work-items / leases.

Do not treat this GitHub queue write as HESS-PC installation of Supervisor v1.8.11.


## WorkInstance hold

`owner-west-motor-parts-chase-fresh-8-v1` stays OPEN/GREEN with fictional 8-vehicle `owner_inputs`, but `blocked=true` until invocation runtime is independently effective. Installed v1.8.10 does not read `required_skill_key` and would send `capability-reuse` work to tool-less `fixed:main`. Unblock only after a fresh continuation receipt shows `ROUTED_TO_PROVEN_SKILL_INVOCATION` is possible (worker present, Supervisor v1.8.11 installed). A stage receipt is still not an owner outcome.

## Not this queue write

- No Engineering Relay verb invention.
- No Skill Lab replay of `west-motor-parts-chase-board-pack@1`.
- No history/budget reset.
- No unblock of `owner-west-motor-parts-chase-fresh-8-v1` in front of installed v1.8.10.
- No claim that this GitHub source is HESS-PC installation of Supervisor v1.8.11.

