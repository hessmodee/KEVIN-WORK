# LESSON - NetherNet Realms JOIN_OK (protocol 2169 / 1.26.45) - 2026-09-05

**When:** 2026-09-05 ~01:12 MT (America/Denver)
**Marker:** `KEVIN_REALMS_JOIN_OK` (real)
**Identity:** kevinsk8erkid on HESSMODEE Realm - never hessmodee bot login
**Log pointer:** `scratch/kevin-minecraft-bedrock-v0/_realms-join-nethernet12-2169.log`

## What broke previously

Realms 26.10+ uses NetherNet / NETHERNET_JSONRPC. Plain RakNet join timed out (NETHERNET_GATE). Client protocol 2168 was rejected vs Realm 2169.

## What worked

1. AUTH_CACHE_OK as kevinsk8erkid (profilesFolder warm).
2. NetherNet overlay wired into bedrock-protocol (signal WestUS2 JSON-RPC).
3. Version 1.26.45 / protocol 2169 matched UWP 1.26.4501.
4. Spawn + chat marker KEVIN_REALMS_JOIN_OK observed ~01:12 MT.
5. Soft residual: late packet_violation_warning on close after spawn - non-blocking for JOIN_OK proof.

## Play loop

wait bed -> follow Matt -> chat -> invited build

## Do not

- Claim JOIN_OK without marker
- Commit raw join logs

- Never use hessmodee bot identity
- No reconnect loops after uninvite

## Rejoin

Use rejoin.cmd in scratch/kevin-minecraft-bedrock-v0 (stay mode).
