# HQ stable shell + silent scheduler (2026-09-08)

Matt: HQ was flashing because five UI painters fought each other, not because Kevin was flipping healthy/dead. PowerShell popups are a separate HESS-PC launcher problem.

Shipped on GitHub (source): one ops painter, no height-bounce loop, 15-minute offline window, v8 service worker.

Not yet on the machine until Grokbot/HESS-PC applies `tools/kevin-silent-scheduler-hygiene-v1.ps1` (GREEN/YELLOW, reversible, does not disable jobs).

Grokbot `remote_shell` consoles are not Task Scheduler jobs. Those stop only when Grokbot itself launches hidden.

Do not overwrite `inbox/maintenance/manifest.json` (live canary) or force the 8-vehicle invocation from this note.
