# KEVIN-WORK

Workspace pack for Kevin on HESS-PC. No secrets.

## Current gate (Stage 2)

OpenClaw logs:

> Assistant reply looks like a tool call, but no structured tool invocation was emitted
> pattern: json_tool_call, toolName: exec, registeredTool: true

Tool policy is already open. The local model is printing tool JSON as text.

## Dead end — do not wait on this

`agents.defaults.models["ollama/llama3.1:8b"].params.extra_body.tool_choice = "required"` **never reaches Ollama** when `api: "ollama"`.

OpenClaw source (2026.7.x):

- `createOpenAICompletionsExtraBodyWrapper` returns immediately unless `model.api === "openai-completions"`.
- Native `buildOllamaChatRequest` only forwards option keys (`num_ctx`, `temperature`, …) and top-level `format` / `keep_alive` / `truncate` / `shift` / `think`.
- `tool_choice` is in neither whitelist.

See `omen/DEAD-END.md`.

## Real next steps (in order)

### A. Isolate Ollama — no OpenClaw

```powershell
.\\omen\\ollama-tool-test.ps1
```

- **PASS** (`message.tool_calls` is a non-empty array) → the model can structure tools. OpenClaw’s catalog/prompt is the gate. Continue to B. **Do not pull a new model.**
- **FAIL** (only `message.content` with JSON/XML) → repeat with `qwen2.5:14b`. If both fail, current models cannot work and a 12 GB tool-oriented pull is allowed (`gemma4:e4b` or `qwen3.5:9b`).

### B. Lean the tool surface

```powershell
node .\\omen\\apply-lean.js
openclaw config validate
openclaw gateway restart
```

Then Telegram `/new`.

This sets `experimental.localModelLean: true`, `temperature: 0`, `num_ctx: 8192`. Those keys actually go on the Ollama wire. `extra_body` does not.

### C. Disk proofs

Write prompt:

```
Write the file reports/tool-write-test.txt containing exactly OK-WRITE and nothing else. Do not describe the write. Do it.
```

```powershell
Get-Content C:\\Users\\hessm\\.openclaw\\workspace\\reports\\tool-write-test.txt
```

Exec prompt:

```
Run this exact command and nothing else: python C:\\Users\\hessm\\.openclaw\\workspace\\helper_append_daily_note.py "lean-unlock-proof"
```

Tail the daily note. Chat claims do not count.

## Hard rules

- Ollama `baseUrl` is `http://127.0.0.1:11434` — no `/v1`
- `api: "ollama"`
- Never OpenClaw-write MEMORY.md or daily notes (it replaces). Append via helper.
- Default stays local. Cloud only with explicit spend approval.
- Do not mention outside agent names in Kevin prompts.
