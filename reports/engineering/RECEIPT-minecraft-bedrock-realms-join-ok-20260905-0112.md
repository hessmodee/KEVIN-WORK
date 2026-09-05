# RECEIPT - Bedrock Realms JOIN_OK (NetherNet / protocol 2169)

**Time:** 2026-09-05 ~01:12 MT (UTC 07:12)
**Host:** HESS-PC
**Outcome:** KEVIN_REALMS_JOIN_OK = **yes** (real)
**Identity:** kevinsk8erkid (never hessmodee bot identity)
**Realm:** HESSMODEE's Realm (Hall of Heroes)
**Transport:** nethernet / NETHERNET_JSONRPC (signal-westus2)
**Version:** 1.26.45 / protocol **2169** (matched UWP 1.26.4501)
**Auth:** AUTH_CACHE_OK (existing profilesFolder; no device-code this run)

## Evidence (sanitized)

- Marker line: KEVIN_REALMS_JOIN_OK
- Spawn log: [realms] spawn (bed at house expected)
- Packets: request_network_settings client_protocol 2169 -> resource_packs_info -> start_game -> set_spawn_position -> play_status / initialized
- Soft residual: late packet_violation_warning on close after spawn (non-blocking)
- Client auto-closed ~2s after prove marker (prove script default) - not still in-world after prove

## Log pointer

Local (may contain secrets - do not git-add):

scratch/kevin-minecraft-bedrock-v0/_realms-join-nethernet12-2169.log

## Play loop (standing)

wait house bed -> follow Matt -> chat -> invited build/mine -> fail-closed

## Rejoin next session

scratch/kevin-minecraft-bedrock-v0/rejoin.cmd

## Safety

- No secrets in this receipt
- Chat 18789 / Reader 19001 untouched
- No hessmodee bot credentials used
