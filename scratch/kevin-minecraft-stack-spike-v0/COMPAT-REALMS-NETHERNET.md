# COMPAT — bedrockflayer vs NetherNet Realms JOIN_OK

**Updated:** 2026-09-05 ~09:33 MT
**JOIN_OK gym:** `scratch/kevin-minecraft-bedrock-v0` (protocol **2169** / **1.26.45**, identity SDP, kevinsk8erkid)

## Risk matrix

| Topic | bedrockflayer (vendor) | Our JOIN_OK | Risk |
| --- | --- | --- | --- |
| Transport | `createClient(host,port)` RakNet/UDP | NetherNet WebRTC/SDP overlay | **HIGH** — createBot cannot join Realms as-is |
| Auth | offline flag or Xbox via bedrock-protocol | prismarine-auth + profilesFolder + identity overlay | **HIGH** if defaults diverge |
| Protocol pin | `version` optional; deps `bedrock-protocol ^3.0.0` | Pin 1.26.45 / 2169 | **MED** — need exact version match |
| Identity | username option | kevinsk8erkid only; never hessmodee | **POLICY** — enforce in wrapper |
| Physics / PlayerAuthInput | physicsEnabled default true; examples often false | Stay soft-violation known | **MED** |
| High-level API | GoalFollow, combat, guard, dig/place, auto_eat | Coach stubs only today | API OK; join is the gap |

## Gap for Realms join

Likely need our overlay (or client injection) — **do not** break JOIN_OK. Do not install this into bedrock-v0 until P0+P1 markers land.

## Fallback order

mineflayer-for-bedrock -> MineToring -> prismarine-bedrock + ported pathfinder -> deepen stubs.
