# LESSON: list_folder exact-5 crossing + session-0 Chat recycle (2026-09-04)

**At:** 2026-09-04 ~14:22–14:55 MT
**Actor:** Grok Bot executor
**Result:** LIVE exact-5 on fixed:main; Benchmark PASS 30/30; Chat natural Desktop list PASS

## Teach
1. Staging plugin 0.2.0 + exact-5 `alsoAllow`/`main.tools.allow` is not LIVE until Chat gateway cold-loads the new tool surface. `configReload.hotReloadStatus=active` does not reload plugin tool registration.
2. Orphan Chat on 18789 started by KevinGatewayKeeper (system-start / session-0) cannot be killed from interactive Cursor shell (`Access Denied` on PID). Do not invent Windows password. Documented path: End+Run `KevinGatewayKeeper` after a one-shot flag that invokes existing `scratch/reload-chat-gateway.ps1`, then restore keeper script. Preserve Reader 19001.
3. Models often pass `name=Desktop` when asked to list Desktop. Normalize empty/whitespace/`name==root` to omit name before `listFolder`.
4. After intentional openclaw.json widen, R04 `Production config frozen` fails until `reports/benchmark-v1/baseline.json` `hashes.production_config` is rebaselined to the AFTER hash (same pattern as Superv pin refresh). Do not weaken denies.
5. Autonomy: local COMPLETE does not unstick selector — publish `inbox/autonomy/work-items.json` via gh contents API; never wipe `continuation-state.json`.

## Evidence
- Config AFTER SHA256 `DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4`
- Isolated canary proof `54F3F9AC3489C0A29F12EFEDBEE7E1AD521DD2F5715EB1F4CBBD464D6550541E`
- Chat prove session `agent:main:chat-prove-list-desktop-20260904b` tool `kevin_desktop_list_folder` failures=0 + real basenames
- Bench PASS 30/30 critical 0 after R04 rebaseline backup `reports/maintenance/backups/pin-refresh-r04-listfolder-20260904-144226`
- work-items publish commit `e93d8205346b1fcb6a045ed90810250e49afdcd2`
