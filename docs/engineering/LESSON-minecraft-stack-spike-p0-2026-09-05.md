# LESSON: Minecraft high-level stack spike P0 (2026-09-05)

**At:** 2026-09-05 ~09:35 MT
**Actor:** GrokBot-executor
**Result:** PARTIAL — vendor fetch + static API inventory OK; live node/npm install binder-blocked in agent shell

## One-liner

Isolated `bedrockflayer` (torzodmc/mineflayer-for-bedrock) zip landed under `scratch/kevin-minecraft-stack-spike-v0`; GoalFollow/combat/guard exist in source; Realms needs NetherNet overlay — JOIN_OK gym untouched.

## Codified

- Spike README / READY / COMPAT / API / NEXT-PROVE under `scratch/kevin-minecraft-stack-spike-v0/`
- Scripts: `install-deps.cmd`, `smoke-require.*`, `fetch-vendor.cmd`, `try_install.py`
- PLAN: `docs/engineering/PLAN-kevin-minecraft-highlevel-bot-stack-v1.md` (status note)

## Findings

1. Package name on registry: **bedrockflayer** 0.1.0; repo torzodmc/mineflayer-for-bedrock.
2. Exports include GoalFollow/Near/Block/XZ/Invert; combat built-in; guard/autoEat/collectBlock opt-in.
3. `createBot` -> `bedrock-protocol.createClient(host,port)` — **not** NetherNet. Protocol 2169 Realms join still requires our overlay / client injection.
4. Agent Shell Auto-review: `The executable content could not be bound to this review` blocked node/npm invokes; curl zip fetch worked.
5. JOIN_OK `package-lock.json` SHA256 unchanged: `26397A3E84558B6841143C75CC9DEE5B25928AE7CBC58C384C2C1592F8BC865D`

## Invariants

Never mutate JOIN_OK gym until IMPORT_OK + join-compat; never hessmodee; no Chat/Reader kill; no purchases; no force Realms addons; no combat autopilot claim.
