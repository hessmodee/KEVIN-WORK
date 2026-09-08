# Maintenance v1.3.52 — Supervisor v1.8.11 + invocation worker

**Status:** Maintenance v1.3.52 **and Supervisor v1.8.11 are installed** on HESS-PC. Support `2026-09-08T10:45:34-06:00` hashes supervisor `685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79` and maintenance runner `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24`. Typed receipt for `grok-install-v1811-20260908-1625` is `ALREADY_APPLIED_PROVEN` / "Supervisor v1.8.11 and invocation worker applied/verified." Continuation publishes `version=1.8.11`. Benchmark 30/30. This is not an owner outcome.  
**Authority delta:** NONE. GREEN-C typed self-improvement through existing rollback/Benchmark gates.  
**Live slot:** `inbox/maintenance/manifest.json` returned to GREEN `run_main_agent_canary` id `grok-main-canary-20260908-1652` so intake does not keep re-entering the proven v1811 install. Queueing is not installation.


## Why this exists

Installed Supervisor v1.8.10 could not invoke a PROVEN skill. A `required_skill_key` WorkInstance on v1.8.10 is sent to tool-less `fixed:main`. Maintenance v1.3.52 exists so the already-reviewed `install_autonomy_controller_v1811` operation can copy Supervisor v1.8.11 and the invocation worker through the typed, reversible path.

That op:

- intercepts `install_autonomy_controller_v1811` (parent 1.3.51 still cannot);
- copies Supervisor v1.8.11, selector v1.2 if needed, the canonical invocation worker, and the two Python files;
- refuses extra properties, preserves histories, requires Benchmark 30/30, and rolls back on failure.

`replace_pinned_component` still rejects alias `supervisor`. That is why the install used the v1811 verb instead of a generic replace.

The install is now independently proven. The remaining gap is the first fresh owner outcome, not another controller install.


## Pins (LF Git blobs / Windows Get-FileHash)

| Identity | SHA-256 |
|---|---|
| Installed Maintenance v1.3.52 (Support 2026-09-08T10:45:34-06:00) | `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24` |
| Parent of v1.3.52 / retired installed 1.3.51 | `2D7F65C97A2934E7C34FEFF86BD317E84D0E73D6CABD9AC1D99DF0FF32448EAD` |
| Supervisor previous (v1.8.10) | `BDA265ACCB929EC5129B2F38AC76FE276625A604052304FC32C917700BCB532E` |
| Supervisor installed (v1.8.11) | `685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79` |
| Selector v1.2 (unchanged) | `52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A` |
| Canonical invocation worker | `16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332` |
| Request builder | `8E1CDB6911A4F087099788C1DAD9E5A425686B63A6FED471E49D9478688ACCF9` |
| Invocation v1 python | `63FA334B85F895894481DF59314326F6F0F4B0785553B8FDD33DFBFC0E88147C` |
| Forge v4.0 baseline (must not change) | `433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A` |

LF Git blob of the installed v1.3.52 runner is `C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24`. Recompute on Windows Get-FileHash if those bytes change.


## Two-step ladder — current position

1. **Merge v1.3.52 source to `main`.** DONE (PR 157).
2. **Install the runner** with `replace_pinned_component` / `target_alias=maintenance_runner`. DONE: Support hash `C5ECCE66…` and typed `ALREADY_APPLIED_PROVEN` for `grok-install-maint-v1352-20260908-1555`.
3. **Install Supervisor v1.8.11 + invocation worker** via `install_autonomy_controller_v1811`. DONE: Support supervisor hash `685B34F3…`, continuation `version=1.8.11`, typed `ALREADY_APPLIED_PROVEN` for `grok-install-v1811-20260908-1625`, Benchmark 30/30.
4. **NOW:** first fresh owner outcome. WorkInstance `owner-west-motor-parts-chase-fresh-8-v1` is unblocked. Installed v1.8.11 must route `west-motor-parts-chase-board-pack@1` to the invocation worker. A stage/routing receipt is still not an owner outcome.

Do not treat this GitHub unblock write as the workbook, note, hashes, or invocation receipt.


## WorkInstance hold — released

`owner-west-motor-parts-chase-fresh-8-v1` is OPEN/GREEN with fictional 8-vehicle `owner_inputs` and `blocked=false`. Invocation runtime is independently effective (Supervisor v1.8.11 + worker). Keep the existing 1 burned turn. Unblock is not PASS. PASS still requires a real workbook + companion operating note + correlated DONE records + output hashes + immutable invocation receipt.

## Not this queue write

- No Engineering Relay verb invention.
- No Skill Lab replay of `west-motor-parts-chase-board-pack@1`.
- No history/budget reset.
- No claim that this GitHub source is the owner outcome.
- No send of this WorkInstance to tool-less `fixed:main`.
- No worker-allowlist widening past `west-motor-parts-chase-board-pack@1` until the first fresh invocation is independently proven.
