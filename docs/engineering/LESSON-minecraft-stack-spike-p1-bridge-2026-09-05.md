# LESSON: Minecraft stack spike P1 bridge inject (2026-09-05)

**At:** 2026-09-05 ~09:45 MT
**Actor:** GrokBot-executor
**Result:** SCAFFOLD — IMPORT_OK retained; client-injection bridge + skill deepen landed; live JOIN_COMPAT not proven; MC UI may still block rejoin

## One-liner

Spike keeps JOIN_OK NetherNet join as source of truth and scaffolds `createBotFromClient` to inject that client into bedrockflayer without mutating the gym lockfile.

## Codified

- `scratch/kevin-minecraft-stack-spike-v0/bridge/*`
- `BRIDGE-DESIGN.md`, `smoke-bridge.*`, spike `skills/*`
- Deepened gym stubs: combat hostile-only, companion follow Matt, guard whitelist
- Playbook/wiki/SOUL outstanding-companion standing orders

## Findings

1. Vendor `_connect` always calls `bedrock.createClient` — one-shot monkey-patch is the thinnest inject without forking vendor.
2. JOIN_OK proven packet today: `text` chat via `client.queue`. Attack path scaffolds `inventory_transaction` (not Realms-proven).
3. Physics default false on inject to reduce PlayerAuthInput soft-violations.
4. Minecraft.Windows still running can yield BLOCKED_MC_UI — never kill UWP; wait then rejoin.cmd.

## Invariants

Never hessmodee bot login; no Chat/Reader kill; no purchases; no force Realms addons; no FOLLOW/COMBAT/GUARD OK without live receipts; never mutate JOIN_OK lockfile.
