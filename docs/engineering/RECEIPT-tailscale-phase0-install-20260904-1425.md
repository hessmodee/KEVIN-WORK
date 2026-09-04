# RECEIPT - Tailscale client Phase 0 install 2026-09-04 ~14:25 MT

Actor: Grok Bot. GREEN+YELLOW. No owner login. No Funnel. No Chat/Reader kill.

## Evidence
- Package: Tailscale.Tailscale **1.102.3** via winget (present; matches PLAN target).
- Binary: `C:\Program Files\Tailscale\tailscale.exe` version 1.102.3 (commit 9329c367...)
- Service: Tailscale Running / Automatic
- `tailscale status`: Logged out. `tailscale ip -4`: NeedsLogin.
- Did **not** run `tailscale up`. No auth key invented.
- Chat: 127.0.0.1:18789 LISTENING (loopback). Reader 19001 UP.
- PLAN SHA256: B7057EC631A821C49EE25B7110AB40BA1128B76DAA7781DE1334088F07AE890A

## Status
**READY_FOR_OWNER_LOGIN**

## Owner next
1. Omen: Tailscale tray or `tailscale up` (prefer `--unattended` for always-on HQ) - free personal account.
2. Phone: same Tailscale account; wait Connected.
3. Then: `tailscale serve --bg localhost:18789` (NOT Funnel). Bookmark Serve URL.