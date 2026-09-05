# RECIPE - NetherNet Realms overlay v2 (JOIN_OK proven)

**Status:** PROVEN 2026-09-05 ~01:12 MT - `KEVIN_REALMS_JOIN_OK`
**Edition:** Bedrock. Identity: **kevinsk8erkid** only.
**Scratch:** scratch/kevin-minecraft-bedrock-v0

## Preconditions

- AUTH_CACHE_OK (profilesFolder warm)
- bedrock-protocol with nethernet src present
- Version 1.26.45 / protocol 2169 (match UWP 1.26.4501)
- Invite DONE; house bed DONE; never hessmodee bot identity

## One-command rejoin (play session)

Run: scratch/kevin-minecraft-bedrock-v0/rejoin.cmd

Sets KEVIN_REALMS_STAY=1 then runs realms-join.js.
Success marker: KEVIN_REALMS_JOIN_OK. Stay mode keeps client open for bed/follow/chat.

## Prove-only (auto-exit ~2s)

Run: node scripts/realms-join.js (default; exits after marker)

## Soft residual

Late packet_violation_warning on close after spawn is soft noise if JOIN_OK already printed.

## Fail-closed

| Signal | Action |
| --- | --- |
| FAIL_CLOSED_NO_TOKEN | READY_FOR_OWNER_DEVICE_CODE |
| NETHERNET_GATE / timeout | Document; cool retries |
| Kick / uninvite | Hard stop |
| Wrong identity | Abort |

Receipt: reports/engineering/RECEIPT-minecraft-bedrock-realms-join-ok-20260905-0112.md
Log pointer: _realms-join-nethernet12-2169.log (local only; never commit raw)

