# LESSON — Chat gateway Keeper treated Reader as Chat (2026-09-15)

**Family:** `CHAT_GATEWAY_DOWN_READER_FALSE_POSITIVE`  
**Zone:** GREEN self-heal  
**Actor this occurrence:** `GROK_BUILD_ACTED` (teach-and-transfer into Tick + Keeper)  
**Wean target:** `kevin_owned` — next occurrence Tick starts `KevinGatewayKeeper`; Keeper starts `gateway.vbs` only when **18789** is down.

## Symptom

Matt cannot talk to Kevin. Conversations happen with Grok Build / Grokbot instead. `reports/self-check.md` FAIL gateway 18789. Dashboard `services.gateway: unhealthy`. Live Chat painted tool-free.

## Root cause

`kevin-gateway-keeper.ps1` detected Chat with regex `openclaw.*gateway`. Reader also runs `openclaw ... gateway --port 19001`, so Keeper believed Chat was up and never started `gateway.vbs`. Chat `:18789` stayed down for days. The old interactive scheduled task `OpenClaw Gateway` is correctly Disabled; Keeper is the plant clock.

## Fix (codified)

1. Keeper now requires listen on `127.0.0.1:18789` (or node cmdline `--port 18789`).
2. Tick mirrors Reader-ensure: if 18789 is down, `Start-ScheduledTask KevinGatewayKeeper`.
3. Do not re-enable the old `OpenClaw Gateway` task.

## Proof

Keeper log `CHAT_GATEWAY_DOWN listen=false procs=0 starting gateway.vbs` then a node process `gateway --port 18789`. TCP connect 127.0.0.1:18789 succeeds.

## NEG

Never treat port 19001 as Chat. Never label this helper repair as `KEVIN_ACTED`. Next downtime must be Tick-owned.

## Pointers

- Keeper: `kevin-gateway-keeper.ps1`
- Tick: `kevin-tick.ps1`
- Auth: `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-15.md`
