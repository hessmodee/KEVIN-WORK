# LESSON - Tick owns outcome_proven sync + console hygiene detect (2026-09-11)
**Actor teach:** GROKBOT_ACTED → Kevin Tick-owned forever
**Grant:** OWNER-STANDING-GRANT-GREEN-YELLOW-v1 (GREEN)

## Entrypoint
`tools/Kevin-Tick-Owned-Repairs-v1.ps1` (called from `kevin-tick.ps1` every Tick)

## Owns
1. `INVOKE_POST_PROVEN_PUBLIC_CONTINUATION_SYNC` via Refresh-Kevin-PublicOutcomeProven-v1.ps1 -Publish
2. `CONSOLE_HYGIENE_DETECT_VBS_WRAP` via Detect-Kevin-ConsoleHygiene-v1.ps1 → reports/console-hygiene-latest.json

## Does not
Hand-invoke, declare PASS, disable Tick/GitHubBridge/UI Bridge, overwrite pin 16C49542, enable Night Forge.

## Receipt
reports/tick-owned-repairs-latest.json
