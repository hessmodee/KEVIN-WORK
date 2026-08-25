# KEVIN-WORK

Workspace pack for Kevin on HESS-PC. No secrets. Never commit tokens.

## How this chat reaches the OMEN

There is no remote desktop into HESS-PC from Grok Build. GitHub is the bridge.

1. Run `omen/run-unlock.ps1` on the tower.
2. It tests Ollama, applies lean, and uploads `reports/ollama-isolate-latest.json`.
3. That JSON is the only payload needed. Paste it into Kevin HQ → Unlock if `gh` cannot upload.

Do **not** paste API keys, PATs, Telegram tokens, or gateway tokens.
Do **not** open RDP, AnyDesk, ngrok, or the OpenClaw gateway to the internet for this chat.

## 24/7

Kevin on the OMEN (OpenClaw + Telegram + local model) is the persistent process.
This chat is not. Morning surprise / new skills wait until write and exec land on disk.
Then heartbeat = one real file per tick. Not unbounded overnight self-rewrites.

## Dead end

`extra_body.tool_choice` never reaches native Ollama. See `omen/DEAD-END.md`.

## Hard rules

- Ollama `baseUrl` is `http://127.0.0.1:11434` — no `/v1`
- `api: "ollama"`
- Never OpenClaw-write MEMORY.md or daily notes (it replaces). Append via helper.
- Default stays local. Cloud only with explicit spend approval.
- Excel, Word, Minecraft, mail, images, music wait until write+exec proofs pass.
