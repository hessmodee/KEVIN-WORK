# kevin-minecraft-stack-spike-v0

**Updated:** 2026-09-05 ~09:55 MT
**Status:** P0 IMPORT_OK. P1 bridge scaffold. P2 JOIN_OK createClient wire + stay companion entry. Realms createBot join-compat still NOT proven live.
**Marker (when smoke passes on machine):** `KEVIN_MC_STACK_SPIKE_IMPORT_OK`

## Purpose

Isolated spike of **torzodmc/mineflayer-for-bedrock** (package name **bedrockflayer**) so we can evaluate high-level follow/combat/guard APIs **without** mutating `scratch/kevin-minecraft-bedrock-v0` JOIN_OK gym lockfile / NetherNet overlay.

## What is here

| Path | Role |
| --- | --- |
| `vendor/mineflayer-for-bedrock-main/` | GitHub main zip extract |
| `install-deps.cmd` | Vendor-only dependency install |
| `smoke-require.cmd` / `smoke-bridge.cmd` | Import + dry inject |
| `smoke-companion-wire.cmd` | Fake packets + NEG unit smoke |
| `bridge/` | Client-injection + companion wire |
| `rejoin-companion.cmd` | Stay + companion live entry (preflight MC UI) |
| `READY_FOR_LIVE_INJECT.md` | Owner close step when UWP blocks |
| `BRIDGE-DESIGN.md` | Inject design |
| `skills/` | Hostile-only / follow-Matt / guard whitelist scaffolds |

## Realms / NetherNet (critical)

Live join uses gym **NetherNet overlay** `bedrock-protocol.createClient` (protocol **2169** / **1.26.45**) via `bridge/join-ok-client-factory.js`, then injects into bedrockflayer. Do **not** point vendor createBot host/port at Realms.

Identity: **kevinsk8erkid only**. Never hessmodee.

## Operator next steps

1. Anytime: `smoke-companion-wire.cmd` (fake/NEG).
2. If Minecraft.Windows open: leave UWP alone → `READY_FOR_LIVE_INJECT`.
3. When UI closed: `rejoin-companion.cmd` (Matt joins as hessmodee).
4. Do **not** claim FOLLOW/COMBAT/GUARD OK without receipts.

## Non-claims

- Combat/follow/guard autopilot **not** proven live.
- JOIN_COMPAT_OK **not** claimed.
- JOIN_OK gym lockfile untouched by design.
