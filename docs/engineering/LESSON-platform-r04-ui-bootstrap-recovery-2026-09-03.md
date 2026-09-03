# Platform R04 + UI Bridge bootstrap recovery — 2026-09-03

## Incident

Matt's validated fixed:main repair intentionally changed `openclaw.json` to SHA256 `23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5`, preserving the 16K Qwen context and compaction values `reserveTokensFloor=2048`, `reserveTokens=2048`, `keepRecentTokens=4000`. Benchmark correctly remained 29/30 because R04 still pinned the prior production-config SHA `215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84`.

The Windows UI Bridge was independently unhealthy: the installed bridge hash remained `5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42` and its scheduled task existed, but the heartbeat was stale and one existing typed restart failed to produce a continuing READY heartbeat.

## Exact evidence recovered

The owner-run read-only collector supplied the exact installed sources and bounded metadata. Installed Maintenance is SHA256 `3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E`; Benchmark is `4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964`; the baseline collected at SHA256 `1396897473D874154FF24DB933D4B4FB643298652FC3C0C05097971DC2336B30` contains the old R04 production-config anchor and the current Supervisor/Forge anchors.

This closes the earlier source-provenance blocker. Do not ask Matt for the old suffixed Maintenance backups again.

## Bootstrap constraint

The exact installed Maintenance runner does **not** expose an R04 baseline-reconciliation operation. Its `replace_pinned_component` path requires final Benchmark 30/30 and rolls a component replacement back when Benchmark is red. Its `restart_ui_bridge` path also finishes through the whole-platform 30/30 gate. Therefore R04 creates a real bootstrap dependency: the current governed remote bridge can execute fixed jobs, but it cannot invoke the already-CI-proven R04 candidate or replace itself while R04 is red.

This is a missing technical execution path, not missing owner authorization. Never solve it by weakening R04, restoring the older config, making a self-test mutate production, adding arbitrary remote command execution, or resetting retry history.

## Bounded bootstrap procedure

`tools/Repair-Kevin-Platform-20260903.ps1` is a one-time, exact-state bootstrap. It has no caller-selected command/path and defaults to `-CheckOnly`.

It must fail closed unless all collected identities still match. It then fetches the merged PR39 R04 candidate from exact commit `e57bf5b013bbbbad98a4c34b0e933c8d2912bfe5`, requires exact Git blob `3a3289d1ab4cb4d92062638cda01a3548b7e6cd2`, parses it, runs its self-test and check-only preflight, and only under `-Apply` lets that candidate change the one fixed baseline leaf. The PR39 candidate owns backup, semantic non-target fingerprinting, fresh Benchmark execution, 30/30 acceptance, and exact rollback.

After R04 is 30/30, the bootstrap verifies the UI Bridge task against the previously proven Action Era contract: `powershell.exe`, exact installed UI Bridge path, `-RunLoop`, Interactive logon, Limited run level. It first tests sustained heartbeat. If startup still fails or the task definition differs, it exports the prior task XML, installs only the known-good narrow task definition, and requires two advancing heartbeat observations. If task repair fails, it restores the prior XML when available.

Finally it exercises the already-allowlisted GREEN `ui_notepad_write` request and requires the bridge's typed DONE result plus output and screenshot evidence. It refuses to run that interactive proof if Notepad is already open in the owner session.

## Acceptance

Do not claim recovery from one fresh timestamp. Acceptance is all of:

- repaired fixed:main config remains the exact collected identity until R04 crossing;
- R04 candidate reports `R04_REBASELINE_APPLIED_PROVEN`;
- fresh Benchmark is PASS 30/30, critical 0;
- UI task has the narrow interactive RunLoop contract;
- UI heartbeat advances across separate observations and remains fresh;
- one unique Notepad request is `ROUND_TRIP_PROVEN` with file and screenshot hashes;
- no broad shell/tool/authority expansion occurs;
- repair/rollback evidence is retained.

## Transfer requirement — eliminate this bootstrap next time

The one-time bootstrap is T0/T1 engineering debt, not Kevin mastery. After the platform is green, use the existing now-unblocked typed Maintenance replacement path to qualify a Maintenance revision based on the recovered exact installed source. That revision should add two narrow fixed operations:

1. governed production-config R04 reconciliation bound to exact known-good config/baseline/Benchmark preconditions, using the already-proven one-leaf/rollback logic;
2. UI Bridge task-definition recovery bound to the known UI hash/task name, with sustained heartbeat and typed functional verification separated from the unrelated platform gate.

Kevin must then be tested on a safe seeded recurrence: detect the failure family, select the bounded operation without Bess supplying the work-item ID, verify semantic postconditions, retain attempt history, record the lesson, survive restart/replay, and make the next correct scheduled decision. Only that evidence justifies T3/T4 responsibility promotion.
