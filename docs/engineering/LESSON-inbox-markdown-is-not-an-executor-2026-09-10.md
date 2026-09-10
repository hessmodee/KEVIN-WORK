# LESSON — inbox markdown is not an executor

**Date:** 2026-09-10  
**Authority:** GREEN  
**Family:** `INBOX_MARKDOWN_NOT_AN_EXECUTOR`  
**Not PASS.**

## Failure

PR 175 merged at 13:38Z with `tools/Repair-Kevin-InvocationRegistryContract-v1.ps1` and versioned invocation/builder python. `inbox/FROM_GROK.md` told GREEN agents to fetch and run that script. Five hours later HESS-PC still published `BLOCKED_INVOCATION_RUNTIME` / `failure_sha256=68845506` and Action Era `ready=0`.

## Root cause

Three existing executors, none of which run FROM_GROK:

1. **GitHubBridge** (`omen/install-bridge.ps1` → `pull-inbox.ps1` every 15 minutes) copies only `FROM_GROK.md`, `CURRENT_TASK.md`, `HEARTBEAT.md`, `SOUL.md`, `apply-lean.js`. It does not copy `tools/` and it does not execute PowerShell recipes inside markdown.
2. **Engineering Relay** fetches `inbox/engineering/request.json` via `gh api` and allowlists `snapshot|benchmark|action_selftests|action_status|stage_composite_skill` only. There is no `run_script` verb. Do not invent one.
3. **Chat `fixed:main` exact-five** is `kevin_system_status`, folder find/open/list, and `kevin_app_launch`. It cannot exec PowerShell. Dashboard Chat Fast is additionally `tools=false`.

HEARTBEAT.md is intentionally empty so OpenClaw skips a competing model loop. Do not put repair checklists there.

## Repair

`omen/pull-inbox.ps1` v1.2 is a deterministic executor. It pulls the repair script and runs it when live invocation/builder hashes are not `75D6031E…` / `93A8A881…`. The live scheduled task still points at the old `pull-inbox.ps1` until that file is overwritten once (Grokbot paste in FROM_GROK, or re-run `omen/install-bridge.ps1`). After that overwrite, the 15-minute puller self-updates.

## Kevin next time

- If a GREEN repair sits in `tools/` and continuation is still `68845506`, check whether a scheduled PowerShell actually calls it. Markdown is not a call.
- Do not wait for Chat to "see FROM_GROK and run it."
- Do not recopy Supervisor to paper over a missing executor.
- Do not occupy a Maintenance slot for a hash-checked copy that GitHubBridge can run.

## Evidence

- Continuation `generated_at=2026-09-10T12:33:00-06:00` still `68845506…`
- Engineering `ready=0` / `done=67`
- No `reports/invocations/` on GitHub main
- Bridge file list in `omen/install-bridge.ps1` (pre-v1.2)
