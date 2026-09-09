# LESSON — HQ bounce + PowerShell flash (2026-09-08)

## Failure family
`owner-ux-console-flash-v1` and `hq-dom-remount-bounce-v1`

## What the owner saw
Kevin HQ bounced up and down. PowerShell windows flashed every few seconds, stole focus, and interrupted typing. Some consoles stayed open.

## Root causes (independent, both real)

1. **HQ content bounce.** `hq-owner-console-v10.js` refreshed every 10s and `replaceWith`'d the main shell. That resets iframe scroll. Ops floor `load()` on raw `resize` rebuilt topology. PowerShell pop-ups caused resize/focus, which retriggered the floor, which changed height, which bounced the parent window. Retired competing V8 overlays and a ResizeObserver height loop were already identified historically; the remaining live fight was refresh-remount + resize-rebuild + z-order steal.

2. **PowerShell focus steal.** `-WindowStyle Hidden` still allocates a console before the flag is applied. Task Scheduler "Hidden" only hides the MMC list entry. Official OpenClaw Windows fix is `wscript.exe` + `WshShell.Run(..., 0, False)` (SW_HIDE), or `conhost.exe --headless`. Watchdog v1.6 only prepended `-WindowStyle Hidden` on four named tasks. UI Bridge `-RunLoop` is the console that stays open indefinitely. Six OpenClaw cron lanes (2–10 min) plus nested `powershell -File worker` from Supervisor add the "every few seconds" cadence.

## Repair (source, GREEN)
- HQ: skip DOM rewrite when the truth signature is unchanged; restore scroll; refresh 30s; treat `BLOCKED_INVOCATION_RUNTIME` as blocked, not ready.
- Ops floor: debounce resize; do not rebuild workers unless layout actually changed (already in live v11); fetch continuation and stop showing stale Support `NO_ELIGIBLE_MISSION`.
- Command Center: silent snapshot poll, persist tabs, no `router.invalidate()` remount, ops-floor motion tied to live truth.
- Console hygiene v1.7: VBS SW_HIDE wrapper for Kevin/OpenClaw PowerShell scheduled tasks, including UI Bridge. Do not switch UI Bridge to "run whether logged on or not" (that drops InteractiveToken).

## Do not
- Recopy Supervisor v1.8.12 or install Maintenance v1.3.54 for this.
- Blindly upgrade OpenClaw (Finn: most self-upgrades break the install).
- Install PCClaw / unvetted ClawHub skills.
- Treat GitHub Pages HQ fix as HESS-PC console-hygiene apply. Scheduled-task wrap still has to run on the machine.
- Claim the 8-vehicle invoke is PASS.

## Finn / Henry mapping
Henry = Mission Control + cheap local workers + frontier chief of staff. Kevin already has HQ + Supervisor + Skill Lab + Ollama. The remaining gap is invocability of one proven skill and owner UX, not more tools.
