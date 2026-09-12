# LESSON - console focus-steal / VBS wrap (2026-09-11)
**Actor:** GROKBOT_ACTED (not KEVIN_ACTED)

## Rule
Scheduled tasks that launch powershell/pwsh/cmd must execute via `wscript.exe` + `tools/kevin-hidden-run.vbs` (SW_HIDE). `-WindowStyle Hidden` alone is NOT sufficient proof of no focus-steal.

## Repair
`tools/Repair-Kevin-ConsoleHygiene-v1.7.ps1` wraps Known Kevin/OpenClaw single-action tasks. Multi-action skips. Password-logon principals often return Access Denied without elevation/credential — convert to Interactive + VBS or grant password.

## Tick detect
Next Tick/self-check should flag any Kevin* task whose Action Execute is powershell/pwsh/cmd without kevin-hidden-run.vbs.

## This cycle
changed=3 failures=6. Still unwrapped active: KevinTick, KevinGitHubBridge, KevinGatewayKeeper, Kevin UI Bridge Watchdog v1, KevinBootRecovery. NightForge left Disabled unwrapped.
