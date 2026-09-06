# OP-TEST PLAYCARD — Minecraft companion tonight (2026-09-05)

**Status:** PREFLIGHT=GO (safe smokes). Live FOLLOW/COMBAT not proven until receipts.
**Machine:** HESS-PC · Spike: scratch\kevin-minecraft-stack-spike-v0
**Identities:** Kevin bot = kevinsk8erkid only · Matt Xbox = hessmodee · NEVER bot-login hessmodee

## Phone vs not-phone

| Mode | What you do |
| --- | --- |
| At PC (preferred) | Run cmds below in a workspace terminal; watch _rejoin-companion.log |
| Phone only | Confirm ports + that MC UI closed; you still must close Minecraft UWP on Omen and start rejoin-companion.cmd on PC. Live join cannot start from phone alone. |

## Exact order

1. Optional safe check: scratch\kevin-minecraft-stack-spike-v0\preflight-home-optest.cmd — expect HOME_OPTEST_PREFLIGHT=GO
2. Close Minecraft UI (owner). Do NOT taskkill Chat 18789 / Reader 19001 / Operator 19101. Prefer normal Close. If mid-session and away: CLOSE_REQUIRED / BLOCKED_MC_UI
3. Start: scratch\kevin-minecraft-stack-spike-v0\rejoin-companion.cmd — expect smokes OK then stay+companion inject / KEVIN_REALMS_JOIN_OK. Exit 2 = close UWP and rerun
4. Xbox as hessmodee — join same Realm
5. Expected: Kevin as kevinsk8erkid; GoalFollow when Matt visible; hostile-only + guard whitelist Matt; heartbeat ~30s. No PvP/grief
6. Stop: Ctrl+C in rejoin-companion terminal. Do not kill Chat/Reader
7. Receipts: FOLLOW_OK / COMBAT_OK only with live spawn+entity proof. Unit SMOKE_OK markers are not live prove

## Residual risks

- packet_violation_warning after JOIN_OK — soft residual on stay=1
- Auth caches aging overnight — owner device-code if auth fails
- JOIN_COMPAT_OK not claimed — inject path only
- Never force-kill UWP unless clearly orphaned AND Matt says safe

## Alt gym stay (no companion inject)

scratch\kevin-minecraft-bedrock-v0\rejoin.cmd after preflight-stay clear
