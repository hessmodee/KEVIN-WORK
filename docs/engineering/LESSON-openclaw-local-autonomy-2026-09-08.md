# LESSON — OpenClaw local autonomy applied to Kevin (2026-09-08)

**Authority:** GREEN-C. Observation and doctrine only. No new desktop tools, no ClawHub installs, no PCClaw, no self-upgrade.

**Trigger:** Extreme Autonomy Flywheel asked for deepest available OpenClaw / local-agent research (Alex Finn, Reddit r/OpenClaw, GitHub issues, ClawHub security) while HESS-PC sat on the first fresh invoke of `west-motor-parts-chase-board-pack@1`.

## What the community is actually failing at

| Failure family | Evidence | Kevin mapping |
|---|---|---|
| Blind self-upgrade | Alex Finn: 70%+ of OpenClaw updates break the install; he told the agent "upgrade yourself" to 2.0 and it went silent. Reddit: four releases in ten days; ClawStat.us called 9.2 "skip." GitHub: 2026.8.1 upgrade crash loops, LaunchAgent death, keys replaced with `__OPENCLAW_REDACTED__`. | Kevin's typed Maintenance ladder is the correct answer. Do **not** let Kevin `openclaw update` itself. Do **not** bundle unrelated repairs (v1.3.54 StrictMode publisher is not the worker gate). |
| Marketplace skill supply chain | ClawHavoc: hundreds of malicious ClawHub skills (infostealers, reverse shells, prompt injection). Cisco / Unit 42 / Snyk. Skills are SKILL.md — markdown can be the payload. | Exact invocation allowlist stays `west-motor-parts-chase-board-pack@1` until first PASS. 27 PROVEN skills already exist. Do not install unvetted ClawHub/PCClaw skills. Build Kevin-owned SKILL.md from proven work. |
| Heartbeat / context bloat | Finn: isolate HEARTBEAT.md from the main session. OpenClaw 2.0 "accidental" refactor wiped memory/automation. Layer agents truncated Kevin `CURRENT_TASK.md` at 15:05 MT into a one-line "Stop." | Layer/reader/daily write `reports/STATUS.md` and `reports/daily-YYYY-MM-DD.md` only. Never truncate `inbox/CURRENT_TASK.md`. Keep HEARTBEAT/SOUL/MEMORY lean. |
| Host on a local device, not a VPS | Finn: local machine is the employee in the office. VPS cannot airdrop/files/Windows GUI. | HESS-PC + local/free Ollama remains the default. Exact-five desktop is intentional, not a missing-tools problem. |
| Orchestrator + cheap local + frontier for hard | Finn: Opus as brain, specialized models as muscle; Qwen local for research. Hermes users left OpenClaw because updates were unreliable. | Kevin already: Supervisor (deterministic) + Ollama default + proven-skill worker rather than tool-less `fixed:main`. Do not send the 8-vehicle job to the main agent. |
| Windows Scheduled Task / Session 0 | Community: PATH, python/node, interactive desktop differ in Session 0. PowerShell StrictMode + `$ErrorActionPreference='Stop'` + native stderr is a repeating crash family. | v1.8.11 crashed the scheduler (`CONTROLLER_ERROR` 14:30). v1.8.12 wrapped the parent (Continue + try/catch) and is now independently proven. The child worker still uses Stop + native python — same family, next rung. |
| Public payload hides the reason | Kevin-specific. `Get-PublicContinuation` hashes `failure` but does not publish `reason`. GitHub then cannot distinguish `PROVEN_SKILL_INVOCATION_WORKER_NOT_INSTALLED` vs `INVOCATION_WORKER_FAILED`. | Next supervisor source should allowlist public `reason` when it matches `^[A-Z][A-Z0-9_]{2,80}$`. Do not wait for that to recopy v1.8.12. |

## What Kevin already got right

- Local device, not a VPS.
- Typed install ladder with SHA-256 pins, rollback, Benchmark 30/30, already-applied receipts. Finn's "let the agent upgrade itself" is what broke OpenClaw.
- Skills as Kevin-owned composites through Skill Lab, not ClawHub.
- Exact-five desktop; pizza/Amazon/voice/public posting stay Delegated Yellow.
- Fail-closed statuses (`BLOCKED_INVOCATION_RUNTIME`) instead of fake idle.
- Heartbeat isolation after the 15:05 truncation incident.

## What "go max" does **not** mean

It does not mean more tools, more models, PCClaw, ClawHub, Astra, Hermes, or Yellow work relabeled Green. Community "max" setups that did those things are the ones in crash loops this week.

It means: one existing PROVEN skill, on fresh fictional inputs, independently verified, then repeat. Then renewable work. Then self-repair that resumes the original objective.

## Bound next action

Live HESS-PC (2026-09-08 15:57 MT): v1.8.12 independently proven; continuation `BLOCKED_INVOCATION_RUNTIME` on `owner-west-motor-parts-chase-fresh-8-v1`; failure `68845506…`; scheduler `consecutive_errors=0`.

1. Diagnose the worker (ran/threw vs missing) from private `reason` / worker output. Public `failure_sha256` implies a `failure` key, which the missing-worker path does not set.
2. Smallest GREEN worker repair (python Continue wrap + explicit reject). Do not widen the allowlist.
3. Resume the same 8-vehicle WorkInstance. Keep the 1 burned 09:31 turn.
4. PASS = workbook + operating note + DONE records + hashes + immutable invocation receipt.

This lesson is not that proof.
