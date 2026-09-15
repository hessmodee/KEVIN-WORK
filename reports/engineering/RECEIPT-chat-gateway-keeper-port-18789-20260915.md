# RECEIPT — Chat gateway 18789 restored (2026-09-15)

**Zone:** GREEN self-heal  
**Actor:** GROK_BUILD_ACTED (teach-and-transfer; not KEVIN_ACTED)  
**Wean:** Tick + KevinGatewayKeeper own the next occurrence

## Before

- `127.0.0.1:18789` not listening
- Reader `127.0.0.1:19001` listening (node 11720, `gateway --port 19001`)
- `KevinGatewayKeeper` last boot 2026-09-11; regex treated Reader as Chat
- Self-check FAIL gateway 18789
- Live Chat unreachable; Matt talking to outside engineers

## Change

- `kevin-gateway-keeper.ps1`: Chat = listen `:18789` or cmdline `--port 18789`
- `kevin-tick.ps1`: if 18789 down, `Start-ScheduledTask KevinGatewayKeeper`
- Did not re-enable scheduled task `OpenClaw Gateway` (Disabled by design)

## After

- Node `gateway --port 18789` (pid 20800)
- TCP `127.0.0.1:18789` Listen + connect OK
- Keeper log: `CHAT_GATEWAY_DOWN listen=false procs=0 starting gateway.vbs`

## Rollback

Restore `kevin-gateway-keeper.ps1.bak-pre-chat-port-20260915` and `kevin-tick.ps1.bak-pre-chat-ensure-20260915`.

## Lesson

`docs/engineering/LESSON-chat-gateway-keeper-reader-false-positive-2026-09-15.md`
