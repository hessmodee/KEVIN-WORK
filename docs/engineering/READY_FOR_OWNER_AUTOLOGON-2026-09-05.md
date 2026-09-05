# READY_FOR_OWNER_AUTOLOGON (partial) — 2026-09-05

**Status:** PLAN + OWNER PACKET ONLY. Do **not** set password from agents/chat/git.
**Machine:** HESS-PC (Omen)
**Goal:** Unattended restart → interactive session → Kevin resume without Matt typing password each reboot.

## Hard constraints (RED)

- NEVER invent/type Matt's Windows password in chat, git, MEMORY, receipts, or scripts committed to repo.
- Autologon stores secret in LSA via **Sysinternals Autologon** (or equivalent Owner-run tool) — OWNER runs it locally.
- Agents may prepare scripts that **read nothing** and **write no password**.

## Recommended approach

1. Owner downloads Sysinternals **Autologon** from Microsoft.
2. Owner runs Autologon.exe interactively; enters username/domain/password once in the GUI.
3. Autologon writes LSA secret; enables `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon` AutoAdminLogon=1 (password NOT in clear registry when using Autologon LSA path).
4. Verify: reboot once while Owner present; confirm desktop session without prompt.
5. Disable anytime: Autologon → Disable, or set AutoAdminLogon=0.

## Agent-owned pieces (safe)

| Artifact | Purpose |
| --- | --- |
| `tools/kevin-unattended-restart.ps1` (candidate) | `shutdown /r /t 30` + wait-for-session checklist; no password |
| `docs/engineering/KEVIN-RESUME-AFTER-REBOOT-CHECKLIST-v1.md` | ports, gateways, companion preflight |
| This packet | Owner steps only |

## Do not

- Commit `DefaultPassword` registry values
- Echo password into transcripts
- Use scheduled task with embedded password in repo

## Acceptance

- [ ] Owner confirms Autologon enabled via Sysinternals GUI
- [ ] One supervised reboot proves session
- [ ] Kevin resume checklist green (Chat/Reader/Operator listen; no MC orphan unless intended)

Marker: `READY_FOR_OWNER_AUTOLOGON`
