# OPTEST PLAYCARD — Home Realms companion (2026-09-05)

**Status:** JOIN_OK path known. Locomotion = **WIRED_NOT_PROVEN** until Matt sees Kevin walk.
**Identity:** kevinsk8erkid only. Never hessmodee bot login.
**Owner process:** Kevin-local Node stay on HESS-PC (not CoS mid-game puppeteering).

## Launch (Kevin-owned)

```bat
scratch\kevin-minecraft-stack-spike-v0\kevin-stay-chase.cmd
```

Alt: `rejoin-companion.cmd` · Fast (no smokes): `kevin-stay-chase-fast.cmd`

Logs: `_rejoin-companion.log` and `logs\companion-authchase-*.log`

## Expect in logs

- `KEVIN_REALMS_JOIN_OK`
- `[rejoin-companion] auth chase loop on` with serializer ok
- `[auth-chase] authInput.chase` (or `.near`) with **real self coords** (beds ~-223 area if still there) — not invented 0,0 forever
- NO `SizeOf error for undefined : Cannot read properties of undefined (reading 'x')`
- NO `createPacketBuffer` crash (`physicsEnabled` must stay false)

## Troubleshooting

See `docs/engineering/RUNBOOK-minecraft-realms-companion-troubleshooting-v1.md` § auth_input / frozen avatar.
LESSON: `docs/engineering/LESSON-BEDROCK-REALMS-LOCOMOTION-2026-09-05.md`

## Hard nos

- Never kill Chat / Reader / Operator gateway PIDs
- Never invent Windows password
- Never claim FOLLOW_OK / visible-move without Matt eyes (screenshot)

## Matt next step

1. Confirm Kevin avatar actually walks/follows (screenshot).
2. If still frozen: paste latest `[auth-chase]` lines + your view.