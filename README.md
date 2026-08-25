# KEVIN-WORK

Workspace pack for Kevin on HESS-PC. No secrets. Never commit tokens.

## How to send results back

Do **not** paste API keys, PATs, Telegram tokens, or gateway tokens into chat.

Paste only the JSON printed by `omen/run-unlock.ps1` into Kevin HQ → Unlock.

## One script

```powershell
.\\omen\\run-unlock.ps1
```

It:

1. Hits Ollama `/api/chat` with tools on `llama3.1:8b` (then `qwen2.5:14b` if llama fails)
2. Applies `localModelLean` + `temperature 0` + `num_ctx 8192`
3. Validates config and restarts the gateway
4. Prints a JSON report — that JSON is the only payload HQ needs

### Verdict

- **PASS** (`toolCallCount` > 0) → model can structure tools. Telegram `/new`, then disk-prove write/exec. Do not pull a new model.
- **FAIL** on both installed models → then a 12 GB tool-oriented pull is allowed (`gemma4:e4b` or `qwen3.5:9b`).

## Dead end

`extra_body.tool_choice` never reaches native Ollama. See `omen/DEAD-END.md`.

## Hard rules

- Ollama `baseUrl` is `http://127.0.0.1:11434` — no `/v1`
- `api: "ollama"`
- Never OpenClaw-write MEMORY.md or daily notes (it replaces). Append via helper.
- Default stays local. Cloud only with explicit spend approval.
- Excel, Word, Minecraft, mail, images, music wait until write+exec proofs pass.
