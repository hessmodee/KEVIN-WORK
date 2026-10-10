# LESSON — Bedrock Realms locomotion / auth_input chase (2026-09-05)

Status: **WIRED_NOT_PROVEN** until Matt confirms visible walk (screenshot). Logs+serializer smoke alone ≠ FOLLOW_OK.

Identity: bot gamertag `kevinsk8erkid` only. Never `hessmodee`.

## What failed (receipts)

1. **Fake near:** `crudeChase` via `move_player` faked local coords → logs said near while avatar frozen at beds. Local mirror ≠ server avatar.
2. **physicsEnabled crash:** `physicsEnabled:true` → `createPacketBuffer` undefined on `player_auth_input`. Stay died.
3. **Wrong auth_input shape (1.26.45):** old packet used `move_vector:{x,y}`, missing `interact_rotation` / `raw_move_vector` / `camera_orientation` → live error `SizeOf error for undefined : Cannot read properties of undefined (reading 'x')`. Serializer expects **vec2f = {x,z}**.
4. **GoalFollow first:** pathfinder without chunks cannot prove locomotion.
5. **CoS mid-game puppeteering:** diagnosing in CoS is fine; the durable stick must be Kevin's local Node stay process.

## Root causes

| Symptom | Cause | Fix |
|--------|--------|-----|
| Idle avatar, logs claim near | Client `move_player` ignored for walking (server-auth movement) | Send `player_auth_input` ~20Hz (50ms) |
| SizeOf … reading 'x' | `{x,y}` move vectors / missing vec2f fields on 1.26.45 | Prismarine #724 shape: `{x,z}` + full field set |
| Crash on physics | Serializer/inject fragility on NetherNet client | `physicsEnabled:false` forever on Realms inject |
| Oversell | Teach without movement proof | Matt-visible walk before FOLLOW_OK |

Community: PrismarineJS bedrock-protocol discussion **#724** (and #523/#652) — must use `player_auth_input`, seed pos from server, small predicted steps only, increment tick.

## Protocol recipe (1.26.45 / protocol 2169) — gym-validated

```js
client.queue('player_auth_input', {
  pitch: 0,                 // degrees
  yaw: 90,                  // degrees
  head_yaw: 90,             // degrees
  position: { x, y, z },  // from server move_player / start_game; predict small steps only
  move_vector: { x: 0, z: 0.4 },           // vec2f — NOT {x,y}
  analogue_move_vector: { x: 0, z: 0.4 },
  raw_move_vector: { x: 0, z: 0.4 },
  input_data: ['up', 'sprinting'],         // 1.26.45 option(array of InputData)
  // older InputFlag form (#724): { _value: 0n, up: true } — fallback only
  input_mode: 'touch',      // or 2
  play_mode: 0,             // normal
  interaction_model: 1,     // crosshair
  interact_rotation: { x: 0, z: 90 },
  tick: tick++,             // BigInt, incrementing
  delta: { x, y, z },
  transaction_presence: false,
  item_stack_request_presence: false,
  block_action_presence: false,
  vehicle_rotation_presence: false,
  predicted_vehicle_presence: false,
  camera_orientation: { x: 0, y: 0, z: 0 },
})
```

Spawn helpers (once): `request_chunk_radius`, `tick_sync`, `set_local_player_as_initialized`. Periodic `tick_sync` ~1s.

Code: `scratch/kevin-minecraft-stack-spike-v0/bridge/raw-auth-chase.js`  
Wire: `companion-wire.js` `crudeChaseMatt` → `authInputChaseTick`  
Stay: `rejoin-companion.js` with `physicsEnabled:false` + `startAuthChaseLoop` (50ms)

## Ownership rule

**Kevin owns the stick.** Durable controller = Node stay on HESS-PC:

```
scratch\kevin-minecraft-stack-spike-v0\kevin-stay-chase.cmd
```

(or `rejoin-companion.cmd`). CoS may patch/restart/teach — not replace Kevin mid-game.

## Negatives

- NEG: never trust local position mirror as movement proof
- NEG: never `physicsEnabled:true` on Realms inject without fresh serializer prove
- NEG: never invent position; never login as hessmodee
- NEG: never claim FOLLOW_OK / visible-move without Matt proof
- NEG: never kill Chat/Reader/Operator gateway PIDs

## Proof bar

- Logs: `KEVIN_REALMS_JOIN_OK` + `[auth-chase] authInput.chase` with real self coords (not stuck inventing 0,0)
- Serializer OK (no SizeOf crash)
- **Visible move = Matt screenshot / eye** → only then FOLLOW_OK
## Companion path addendum (2026-09-05 ~17:18 MT)

`rejoin-companion` JOIN_OK then ~4s later `packet_violation_warning` → Signal disconnect → Client closed. Process kept auth-chase/heartbeats on a **dead** client (zombie ghost). Matt saw leave / not in game.

Likely stay-killers on companion path (vs gym-only stay):
- Early `player_auth_input` spam before session settled (SizeOf / schema)
- GoalFollow pathfinder noise
- Do not claim in-world from companion logs alone

**Fix order:** prove durable gym `rejoin.cmd` stay (heartbeats, no violation) so Matt sees kevinsk8erkid; only then reintroduce delayed auth-input chase. On client close: stop intervals and exit/reconnect — never zombie.

