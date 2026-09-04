# LIVE WRAPPER PLAN — install_kevin_desktop_v0_1 (DRY-RUN ONLY)

**Authority:** YELLOW / production_effect NONE until owner approval binding present
**Created:** 2026-09-04 08:09 MT America/Boise
**Actor:** GrokBot-executor

## Fixed operation

install_kevin_desktop_v0_1 only. No NightForge retirement. No extra tools.

## Preconditions

- [x] Crossing validator PLAN_OK (9/9 tests)
- [x] fixed_main_tools_before == 0 (measured)
- [x] Benchmark PASS 30/30 critical 0
- [ ] Owner approval binding present — BOUND (desktop-hesspc-apply-20260904-0809) → APPLIED PASS
- [x] Config SHA pinned 23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5
- [x] OpenClaw 2026.7.1-2
- [x] Engineering Relay NOT used
- [x] Maintenance v1 NOT used

## Mutation steps (ONLY after Matt approval text bound to request-id)

1. Acquire config mutex; re-hash openclaw.json; abort if drift.
2. Byte-backup openclaw.json to reports/engineering/backups/p01-desktop-20260904-0809/.
3. Stage reviewed extensions/kevin-desktop from pinned KEVIN-WORK commit into .openclaw/extensions/kevin-desktop.
4. Register kevin-desktop (+ kevin-core/status path as needed for kevin_system_status); tools.alsoAllow exactly four tool IDs; preserve all root denies; no group:plugins.
5. Smallest code-owned fix for supportsTools=false on active main provider (Reader-style tools-capable catalog) — no new network/credentials.
6. openclaw config validate + plugins inspect with fixed argv.
7. Minimal Chat gateway reload; do not kill Reader 19001.
8. Positive + forbidden negative canaries; Benchmark 30/30.
9. Publish sanitized receipts to hessmodee/KEVIN-WORK.

## Canaries

Positive: kevin_system_status once; find Desktop child; open folder; launch calculator|notepad.
Negative: cmd/powershell; caller argv; .. traversal; extra tool visibility; web/credential/download.

## Rollback

Restore backup openclaw.json; remove kevin-desktop registration; re-canary visible_kevin_tool_count=0; Benchmark 30/30.

