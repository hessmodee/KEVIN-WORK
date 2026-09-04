# OWNER APPROVAL PACKET — install_kevin_desktop_v0_1

**When:** 2026-09-04 08:09 MT (America/Boise)
**Machine:** HESS-PC
**Crossing:** candidates/maintenance/production-crossing-v2
**Request type:** install_kevin_desktop_v0_1 ONLY
**Status:** READY_FOR_OWNER_APPLY — NOT APPLIED

## One-message ask for Matt

Please reply exactly:

APPROVE install_kevin_desktop_v0_1 on HESS-PC Chat fixed:main; bind request-id desktop-hesspc-apply-20260904-0809; expected tools exactly kevin_system_status, kevin_desktop_find_folder, kevin_desktop_open_folder, kevin_app_launch; preserve all root protected denies; Benchmark must remain 30/30 critical 0; rollback required.

Anything else (extra tools, NightForge delete, network/credential widening) is out of scope.

## Why blocked now

- Production Crossing v2 validator dry-run: PASS (production_effect=CANDIDATE_ONLY, authority_delta=NONE).
- Owner approval binding for live apply: MISSING.
- Engineering Relay: not used (stays GREEN typed).
- Maintenance v1: not used.

## Measured before-state (sanitized)

| Item | Value |
|------|-------|
| Chat config SHA256 | 23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5 |
| tools.profile | coding |
| tools.allow / alsoAllow | ABSENT |
| plugins.entries | ollama only |
| kevin-desktop installed | NO |
| fixed:main visible_tool_count | 0 |
| fixed:main visible_kevin_tool_count | 0 |
| has_kevin_system_status | false |
| Benchmark | PASS 30/30 critical 0 @ 2026-09-04 07:57 MT |
| OpenClaw | 2026.7.1-2 |
| Ports | Chat 18789 / Reader 19001 (do not kill) |

## Exact target after apply (if approved)

1. kevin_system_status
2. kevin_desktop_find_folder
3. kevin_desktop_open_folder
4. kevin_app_launch

Zero extras. Root protected denies remain.

## Receipts

- reports/engineering/RECEIPT-p01-desktop-crossing-before-state-20260904-0809.json
- reports/engineering/RECEIPT-p01-desktop-crossing-dryrun-20260904-0809.json
- reports/engineering/PROOF-p01-desktop-crossing-dryrun-20260904-0809.md

## HQ side-check

Pages built at https://hessmodee.github.io/KEVIN-WORK/ — Skill Lab counts in global Command: OPEN. Local proven composites: 11.
