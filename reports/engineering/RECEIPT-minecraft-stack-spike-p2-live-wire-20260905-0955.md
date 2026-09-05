# RECEIPT: Minecraft stack spike P2 live-wire stay companion (2026-09-05 ~09:55 MT)

**Machine:** HESS-PC
**Branch:** grok/minecraft-stack-spike-p2-live-wire-20260905
**Identity:** kevinsk8erkid only

## Outcomes

| Check | Result |
| --- | --- |
| JOIN_OK gym lock SHA256 | 26397A3E84558B6841143C75CC9DEE5B25928AE7CBC58C384C2C1592F8BC865D UNCHANGED |
| Minecraft.Windows | RUNNING (pid observed) — **not killed** |
| Live stay+companion | **BLOCKED** → `READY_FOR_LIVE_INJECT` |
| Fake companion wire smoke | run `smoke-companion-wire.cmd` (unit; no Realms) |
| FOLLOW_OK / COMBAT_OK / GUARD_OK / JOIN_COMPAT_OK | **NOT claimed** |

## Scripts added

- `scratch/kevin-minecraft-stack-spike-v0/rejoin-companion.cmd`
- `scratch/kevin-minecraft-stack-spike-v0/smoke-companion-wire.cmd`
- Bridge: `createJoinOkClient` + `enableStayCompanion`

## Matt play steps (companion behaviors)

1. Close Minecraft UWP when ready (Kevin will not kill it).
2. Run `scratch\kevin-minecraft-stack-spike-v0\rejoin-companion.cmd`.
3. Join Realm as **hessmodee**.
4. Expect Kevin as **kevinsk8erkid**: stay near / GoalFollow when entity seen, hostile-only guard, autoEat if safe — **admit not proven until receipts**.
5. No PvP, no grief, no hessmodee bot login.

## Markers

- `READY_FOR_LIVE_INJECT` (this session)
- Prior: `KEVIN_MC_STACK_SPIKE_IMPORT_OK`, `KEVIN_MC_STACK_BRIDGE_SMOKE_OK`
