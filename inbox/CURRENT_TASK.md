# CURRENT_TASK

**Updated:** 2026-09-03 ~22:00 MT  
**Owner priority:** close R04 with the exact installed Benchmark contract, then finish UI/autonomy repairs remotely with minimum Matt intervention.

## P0 — corrected one-time R04 bootstrap v2

Exact HESS-PC source/config evidence is recovered. Preserve:
- Maintenance `3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E`
- validated fixed:main config `23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5`
- baseline bytes `1396897473D874154FF24DB933D4B4FB643298652FC3C0C05097971DC2336B30`
- old baseline production-config anchor `215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84`
- Benchmark `4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964`
- UI Bridge `5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42`

Fresh runtime before this crossing remains Benchmark 29/30 critical1 sole R04 and stale UI heartbeat. Do not revert the good 16K/compaction config, weaken R04, reset attempts, or repeat the old blind UI restart.

### First bootstrap attempt: fail-closed, no production mutation

The PR44/v1 tool rejected both Matt's `-CheckOnly` and later `-Apply` at preflight with `R04 baseline Benchmark runner anchor mismatch`. No baseline/config mutation occurred. Root cause: PR39's candidate assumed `hashes.benchmark_runner`, but the exact installed Benchmark v1.1c does not consume that field. Do **not** run the PR44/v1 bootstrap again and do not ask Matt to restore anything.

### Corrected crossing

PR45 `Fix R04 bootstrap for installed Benchmark v1.1c` is merged to main as:

`41ba61bb0381923ec369c7770dd3effa6f2ed660`

Use only the merged current:

`tools/Repair-Kevin-Platform-20260903.ps1`

The v2 tool is R04-only. It self-preflights the exact installed Benchmark source/baseline contract, exact bytes/hashes and exact 29/30 sole-R04 condition, makes an exact backup, changes only `hashes.production_config`, preserves all non-target semantics, runs a fresh Benchmark requiring 30/30 critical0, and restores the old baseline on any failure. It does not add arbitrary shell/authority.

Windows PowerShell 5.1 push CI `33713308495` passed after repairing a parser typo found by the first branch CI. PR-triggered Windows PowerShell gate also passed before merge.

If fresh Benchmark is still 29/30 and there is no v2 APPLIED_PROVEN receipt, Matt's one remaining local step is to run the exact merged v2 with `-Apply` once. No separate `-CheckOnly` is required; Apply performs the same fail-closed preflight first.

Expected success:

`KEVIN_R04_BOOTSTRAP_V2_APPLIED_PROVEN benchmark=30/30 critical=0 target=hashes.production_config`

Receipt:

`reports/maintenance/r04-production-config-rebaseline-latest.json`

## Immediately after R04 succeeds — Bess/Chief Engineer should do this remotely

1. Read fresh Support, Engineering and R04 receipt; require actual fresh 30/30/critical0.
2. Use existing typed Maintenance to restart/repair UI Bridge rather than sending Matt another PowerShell task.
3. Require multiple advancing READY/WORKING heartbeats and then a unique typed GREEN `ui_notepad_write` result with output/screenshot evidence.
4. Extend/upgrade Maintenance through its now-unblocked typed replacement path to encode narrow Kevin-owned R04 and UI-task recovery operations with source pins, rollback and recurrence tests.
5. Refresh the genuine full autonomy assessment.
6. Diagnose fixed:main effective tool policy; expose only the smallest governed intent/control surface and require positive + forbidden-action real-turn proof.
7. Prove unattended useful work selection without Bess supplying a work-item ID, including semantic verification, lesson, restart/replay and next correct decision.
8. Continue private HQ/mobile communication, Telegram repair/replacement, memory/handoff, GREEN replay, Reader and lawful economic-output lanes within WIP.

## Coordination

`AI-HANDOVER.md` is canonical and contains full rationale/evidence. Fresh runtime evidence outranks prose. Keep only one outside AI writer. The scheduled ChatGPT Chief Engineer is paused during this foreground mutation and should be re-enabled once the handoff is reconciled while waiting only on Matt's v2 invocation; it must not invent a remote R04 path or compete with a live foreground engineer.
