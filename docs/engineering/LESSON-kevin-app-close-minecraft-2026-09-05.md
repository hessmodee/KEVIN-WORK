# LESSON — Kevin owns app open/use/close (Minecraft Realms stay) — 2026-09-05

## Problem
Matt was required to close Minecraft.Windows UWP before Realms stay/companion inject. That blocked phone/remote rock-and-roll.

## Fix
- `kevin-app-close.ps1`: CloseMainWindow → UIA WindowPattern.Close → taskkill (no /F) → audited Stop-Process -Force.
- Bugfix: taskkill used automatic `$PID` instead of `$procId`.
- Typed `kevin_app_close` on kevin-desktop (minecraft gated by `KEVIN_ALLOW_CLOSE_MC=1`).
- `rejoin-companion.cmd` auto-closes MC then runs `node rejoin-companion.js` inject (not gym rejoin.cmd alone).

## Prove
- Parent: Minecraft.Windows pid ~118148 → KEVIN_APP_CLOSE_OK
- CalculatorApp open→use→close → KEVIN_CALC_OPEN_USE_CLOSE_OK
- MC status after: already gone → KEVIN_APP_CLOSE_MC_OK

## NEG
- Never invent Windows password / Autologon secret in chat/git
- Never hessmodee bot login
- Never casually kill Chat/Reader
- No silent Force without AUDITED_FORCE line
