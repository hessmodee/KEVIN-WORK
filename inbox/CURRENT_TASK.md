# CURRENT_TASK

**Updated:** 2026-09-03 ~21:05 MT  
**Owner priority:** restore the platform gate, UI Bridge and then advance Kevin-owned autonomy with minimum Matt intervention.

## P0 — one unavoidable local bootstrap crossing

Exact HESS-PC source/config evidence is now recovered from Matt's read-only collector. The prior request for the unsuffixed Maintenance source is CLOSED.

Current exact facts:

- installed Maintenance SHA256 `3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E`;
- current validated fixed:main config SHA256 `23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5`;
- collected Benchmark baseline SHA256 `1396897473D874154FF24DB933D4B4FB643298652FC3C0C05097971DC2336B30`;
- baseline still pins old production config `215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84`;
- Benchmark runner SHA256 `4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964`;
- UI Bridge SHA256 `5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42`;
- fresh Support remains 29/30, critical1, sole R04 `Production config frozen`;
- UI task exists but persistent READY heartbeat remains unproved/unhealthy.

Preserve the repaired fixed:main model/context/compaction settings. Do not weaken R04, revert config, reset attempts or repeat the previous unchanged UI restart.

### Qualified crossing

PR44 was merged to main as `e2c716caeaffbff60d9f5a5ec9bef559a306528a` and passed Windows PowerShell 5.1 on the PR and after merge (post-merge run `33709967151` SUCCESS).

Use only:

`tools/Repair-Kevin-Platform-20260903.ps1`

Procedure:

1. Run it with `-CheckOnly` on HESS-PC.
2. If it reports `KEVIN_PLATFORM_BOOTSTRAP_READY`, run the same exact file with `-Apply`.
3. The script itself pins/validates the collected identities, reuses merged PR39 R04 one-leaf reconciliation, requires fresh Benchmark 30/30 or rollback, verifies/repairs only the known UI Bridge InteractiveToken `-RunLoop` task, requires sustained heartbeat, and runs one typed GREEN Notepad round-trip proof.
4. If Notepad is already open, close it before the `-Apply` proof or let the script fail closed without disturbing it.

Success marker:

`KEVIN_PLATFORM_BOOTSTRAP_APPLIED_PROVEN benchmark=30/30 ui=sustained ui_notepad=ROUND_TRIP_PROVEN`

Receipt:

`reports/maintenance/platform-repair-20260903-latest.json`

Why Matt is needed for this one step: the exact installed Maintenance bridge has no R04 operation, and its component-replacement path itself requires Benchmark 30/30, so it cannot remotely install the missing operation while R04 is red. Engineering Relay and Work Order Intake also expose only fixed allowlisted jobs, not arbitrary PowerShell. This is the current technical bootstrap boundary, not a permission boundary.

## Work Bess already completed directly

- Used the existing Maintenance bridge to refresh `publish_runtime_capabilities` instead of sending Matt to PowerShell.
- Fresh runtime-capabilities evidence shows config valid, Gateway deep probe OK, Task Flow CLI available, root tool policy present, no main/default tool path, and no claim of per-turn tool availability without real-turn proof.
- Retired the consumed Maintenance manifest and auxiliary control-plane order.
- Merged/tested the one-time bootstrap and durable lesson.
- Reconciled `AI-HANDOVER.md` so future agents know the exact state.

## Next actions immediately after P0 success

1. Read fresh `reports/support-latest.json`, `reports/engineering/latest.json`, the bootstrap receipt and UI heartbeat/results. Require fresh 30/30/critical0 + continuing heartbeat + typed UI evidence before claiming recovery.
2. Refresh the genuine autonomy assessment through its qualified path; a publication refresh is not a new assessment.
3. Convert R04/UI recovery from this outside bootstrap into narrow Kevin-owned Maintenance operations based on the now-recovered exact source; prove recurrence/replay and preserve bounded attempt history.
4. Diagnose fixed:main effective tool layers and expose only the smallest useful governed owner-intent/control surface. Require an allowed useful real action plus forbidden-action negatives; no broad `exec`/filesystem/browser/session authority.
5. Run the unattended owner-value autonomy test: Kevin must select useful work without a Bess-supplied item ID, execute through a governed mechanism, verify semantics, record/learn, survive restart/replay and make the next correct scheduled decision.
6. Continue independent useful lanes within WIP: HQ/mobile private communication, Telegram repair/replacement, memory/handoff/replay, GREEN skills, Reader and lawful economic-output work.

## Responsibility truth

Current platform repair procedure is Bess-built and not yet Kevin-owned. Existing eight composite deliveries are real but do not establish T4/T5. Promote only after Kevin independently detects, selects, executes, verifies, recovers and handles recurrence.

## Coordination

`AI-HANDOVER.md` is canonical. Fresh runtime evidence outranks this file. The sole scheduled ChatGPT `Kevin Chief Engineer` stays paused while this foreground session is actively mutating shared state; HESS-PC local schedulers stay running. Re-enable the scheduled Chief Engineer when the foreground crossing is handed back / waiting only on the unavoidable Matt bootstrap step.
