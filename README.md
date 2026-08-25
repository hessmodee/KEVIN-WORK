# KEVIN-WORK

Workspace pack for Kevin on HESS-PC. No secrets.

## Current gate (Stage 2)

OpenClaw logs:

> Assistant reply looks like a tool call, but no structured tool invocation was emitted
> pattern: json_tool_call, toolName: exec, registeredTool: true

Tool policy is already open. The local model is printing tool JSON as text. Official OpenClaw guidance: force `tool_choice: required` on the existing model, then prove write and exec **on disk**.

Do **not** pull a new model until that fails.

## Apply on HESS-PC

In PowerShell:

```powershell
# Uses Node so slash keys and arrays stay intact.
# Do not use: openclaw config set tools.allow '[...]' --strict-json

node .\omen\apply-tool-choice.js
openclaw config validate
openclaw gateway restart
```

Then Telegram `/new`.

### Write proof

Send Kevin:

```
Write the file reports/tool-write-test.txt containing exactly OK-WRITE and nothing else. Do not describe the write. Do it.
```

Verify:

```powershell
Get-Content C:\Users\hessm\.openclaw\workspace\reports\tool-write-test.txt
```

### Exec proof

Send Kevin:

```
Run this exact command and nothing else: python C:\Users\hessm\.openclaw\workspace\helper_append_daily_note.py "tool-choice-required-proof"
```

Tail the daily note. Chat claims do not count.

If both fail, run the Ollama-native `/api/chat` tools test in `omen/ollama-tool-test.ps1` **before** installing another model.

## Hard rules

- Ollama `baseUrl` is `http://127.0.0.1:11434` — no `/v1`
- `api: "ollama"`
- Never OpenClaw-write MEMORY.md or daily notes (it replaces). Append via helper.
- After proofs pass, relax `tool_choice` or every Telegram "thanks" will force a tool.
- Default stays local. Cloud only with explicit spend approval.
