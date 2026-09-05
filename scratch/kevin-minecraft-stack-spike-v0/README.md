# kevin-minecraft-stack-spike-v0

**Updated:** 2026-09-05 ~09:45 MT
**Status:** P0 IMPORT_OK. P1 bridge scaffolded (inject client). Realms createBot join still NOT proven.
**Marker (when smoke passes on machine):** `KEVIN_MC_STACK_SPIKE_IMPORT_OK`

## Purpose

Isolated spike of **torzodmc/mineflayer-for-bedrock** (package name **bedrockflayer**) so we can evaluate high-level follow/combat/guard APIs **without** mutating `scratch/kevin-minecraft-bedrock-v0` JOIN_OK gym lockfile / NetherNet overlay.

## What is here

| Path | Role |
| --- | --- |
| `vendor/mineflayer-for-bedrock-main/` | GitHub main zip extract (tip ~1f41d63, 2026-05-17) |
| `install-deps.cmd` | Vendor-only dependency install |
| `smoke-require.cmd` / `smoke-require.js` | Import-only smoke (no Realms connect) |
| `fetch-vendor.cmd` | Re-download upstream zip |
| `try_install.py` | Same install via Python subprocess |
| `COMPAT-REALMS-NETHERNET.md` | Protocol/overlay risk notes |
| `READY_FOR_STACK_SPIKE.md` | Gate file |
| `bridge/` | Client-injection adapters (spike-only) |
| `BRIDGE-DESIGN.md` | P1 join-compat design |
| `smoke-bridge.*` | Dry inject smoke |
| `skills/` | Hostile-only / follow-Matt / guard whitelist scaffolds |

## API surface (static read of vendor source)

Exports from `index.js`:

- `createBot`, `BedrockBot`, `Registry`, `version`
- Goals: `GoalBlock`, `GoalNear`, `GoalXZ`, `GoalFollow`, `GoalInvert` (+ `goals` map)
- Opt-in plugins: `autoEat`, `collectBlock`, `guard`
- Built-in auto-loaded: chat, health, entities, world, physics, controls, inventory, windows, digging, placing, **combat**, crafting, vehicles, sleep, time, scoreboard, sound, creative, resource_pack, **pathfinder**

Source shows `bot.attack(entity)`, `bot.guard.enable()` after loadPlugin(guard), `bot.pathfinder.goto(new GoalFollow(entity, range))`.

## Realms / NetherNet (critical)

**createBot always calls `bedrock-protocol.createClient({host,port,...})`** — LAN/BDS UDP path.

Our JOIN_OK path is **NetherNet + identity SDP + protocol 2169 / 1.26.45** via overlay in bedrock-v0. This spike stack does **not** know NetherNet, Realms discovery, or our identity overlay.

**Do not** point createBot at Realms. Next prove needs client injection into BedrockBot **or** keep join in JOIN_OK gym and port pathfinder/combat patterns onto that client.

Identity: **kevinsk8erkid only**. Never hessmodee.

## Agent binder note (2026-09-05)

Cursor agent Shell Auto-review: `The executable content could not be bound to this review` for any invoke of the JS node or npm (even with working_directory + approval retry). Vendor zip fetched with curl; operator runs `install-deps.cmd`.

## Operator next steps (when Matt in Realm)

1. DONE: `install-deps.cmd` + `smoke-require.cmd` -> `KEVIN_MC_STACK_SPIKE_IMPORT_OK`.
2. Confirm gym `package-lock.json` hash unchanged.
3. Run `smoke-bridge.cmd` (dry inject).
4. If Minecraft.Windows UI closed: `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd` stay.
5. Live inject JOIN_OK client via `bridge/createBotFromClient` — only then chase FOLLOW_OK.
6. Do **not** claim combat/follow autopilot without receipts.

## Non-claims

- Combat/follow/guard autopilot **not** proven.
- Realms join via bedrockflayer createBot **not** proven (injection scaffold only).
- JOIN_OK gym lockfile untouched by design.
