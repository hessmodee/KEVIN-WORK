# COMPAT — bedrockflayer vs NetherNet Realms JOIN_OK

**Updated:** 2026-09-05 ~09:45 MT
**JOIN_OK gym:** `scratch/kevin-minecraft-bedrock-v0` (protocol **2169** / **1.26.45**, identity SDP, kevinsk8erkid)
**IMPORT_OK:** yes (smoke-require). **JOIN via createBot:** NO — still needs injection.

## Risk matrix

| Topic | bedrockflayer (vendor) | Our JOIN_OK | Risk |
| --- | --- | --- | --- |
| Transport | `createClient(host,port)` RakNet/UDP | NetherNet WebRTC/SDP overlay | **HIGH** — createBot cannot join Realms as-is |
| Auth | offline flag or Xbox via bedrock-protocol | prismarine-auth + profilesFolder + identity overlay | **HIGH** if defaults diverge |
| Protocol pin | `version` optional; deps `bedrock-protocol ^3.0.0` | Pin 1.26.45 / 2169 | **MED** — need exact version match |
| Identity | username option | kevinsk8erkid only; never hessmodee | **POLICY** — enforce in wrapper |
| Physics / PlayerAuthInput | physicsEnabled default true; examples often false | Stay soft-violation known | **MED** — bridge defaults physicsEnabled false |
| High-level API | GoalFollow, combat, guard, dig/place, auto_eat | Coach + scaffold skills | API OK; join is the gap |

## Bridge (scaffold)

See `BRIDGE-DESIGN.md` + `bridge/create-bot-injected.js`:

- Inject JOIN_OK client into `createBot` via one-shot createClient monkey-patch (spike-local).
- Do **not** install spike deps into gym; do **not** mutate gym lockfile.
- `smoke-bridge.cmd` = dry inject only.

## Gap for Realms join

Overlay / client injection required — **do not** break JOIN_OK. Live `KEVIN_MC_STACK_JOIN_COMPAT_OK` not claimed.

## Fallback order

mineflayer-for-bedrock -> MineToring -> prismarine-bedrock + ported pathfinder -> deepen stubs.
