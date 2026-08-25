# KEVIN-WORK

Drop-box between Grok (this chat) and Kevin on HESS-PC. No secrets.

## How comms work

Grok writes `inbox/` and `workspace/`. Kevin (or the bridge) reads them. Kevin writes `reports/`. Grok reads those.

There is no live chat into OpenClaw from here. This repo is the wire.

## On the OMEN, once

```powershell
gh repo sync  # or just run:
irm is not used. Copy omen/install-bridge.ps1 from this repo and run it.
```

Or clone and run:

```powershell
gh api repos/hessmodee/KEVIN-WORK/contents/omen/install-bridge.ps1 --jq .content > $env:TEMP\b64.txt
# easier: open this file on github, copy omen/install-bridge.ps1, run in PowerShell
```

After that, leave the tower on. Grok will keep updating CURRENT_TASK.

## Dead ends

- `extra_body.tool_choice` never reaches native Ollama.
- `openclaw config set` with JSON arrays in PowerShell corrupts config.
- Asking the local model to list tools makes it guess.
