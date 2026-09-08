# LESSON — HQ stable shell (2026-09-08)

## Defect Matt saw

Kevin HQ on GitHub Pages was flashing between two chrome sets (COMMAND vs LIVE) and the ops-floor window was bouncing up and down. Kevin’s owl flipped X-eyes / READY every second. PowerShell windows also popped on HESS-PC and stole focus.

## Root cause (not a health flip)

Five independent painters were fighting the same ops-floor DOM on different clocks:

| Painter | Clock | What it did |
|---|---|---|
| `hq-core-v7.html` | 15s | COMMAND/WORK LOG chrome inside the iframe |
| `hq-owner-console-v10.js` | 10s | LIVE/OPS/SKILLS chrome from the parent; remounted `#main` |
| `ops-v11.js` | 30s **and every resize** | Destroyed and rebuilt every worker node |
| `ops-live-truth-v2.js` | **1s paint / 8s fetch** | Dashboard >180s ⇒ `mode-disconnected` X-eyes |
| `ops-truth-patch-v1.js` | 2.5s + MutationObserver | Restored ARMED/READY over the X-eyes |

Plus a height loop: embed `ResizeObserver` posted `kevin-ops-height` → parent resized the iframe → `resize` fired `ops-v11.load()` → workers remounted → height changed → repeat. That is the bounce.

Dashboard at 4–5 minutes is not offline. V11’s offline window is 15 minutes. The 180-second live-truth overlay was lying.

PowerShell flashes are a second plane: Task Scheduler jobs launching visible `powershell.exe`, and Grokbot `remote_shell` opening a console whenever it touches HESS-PC.

## Repair

1. Embed loads **only** `ops-v11.js`. Retired overlays stay as HTML comments for historical proof jobs.
2. `ops-v11` updates workers in place. Resize no longer remounts unless size actually changed by ≥12px. Owl SVG is replaced only when mode changes. X-eyes remain 15-minute true offline.
3. V10 never remounts the ops iframe; nav buttons toggle class; telemetry chart is reused; LIVE/SKILLS/SYSTEM patch in place. HQ is UNVERIFIED only when dashboard **and** engineering **and** support are all older than 15 minutes.
4. Service worker cache bumped to `kevin-hq-shell-v8`. Index force-updates the worker.
5. `tools/kevin-run-hidden.vbs` + `tools/kevin-silent-scheduler-hygiene-v1.ps1` wrap Kevin/OpenClaw scheduled tasks. Does not disable jobs. Does not claim Grokbot remote_shell is fixed.

## Verify

- Sit on HQ 60 seconds. Tabs must not swap COMMAND ↔ LIVE. Ops iframe must not remount. Owl must not X-eyes on a 5-minute dashboard.
- Hard refresh once after Pages deploy (`Ctrl+Shift+R`) so the v8 worker claims.
- Handover.html and Talk-to-Kevin (`127.0.0.1:18789`) still load.
- After hygiene runs on HESS-PC: Kevin scheduled tasks are Hidden / wscript-wrapped. Grokbot remote_shell popups still need Grokbot to launch hidden — that is not this script.

## Do not

- Do not treat Support `cron.ok=false` “Config warnings:” as lane death.
- Do not hard-code healthy over CONTROLLER_ERROR.
- Do not force `owner-west-motor-parts-chase-fresh-8-v1`.
- Do not reset continuation history.
