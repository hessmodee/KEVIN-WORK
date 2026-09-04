# PLAN - Kevin Tailscale remote HQ Talk (phone at work)

Date: 2026-09-04 ~13:35 MT (America/Denver)
Author: Grok Bot (HESS-PC inventory + Tailscale free-plan research)
Audience: Matt / Davy / Kevin / Cursor slack agents
Auth: UNDYING GREEN+YELLOW docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md
Charter: docs/engineering/KEVIN-SUPER-AI-NORTH-STAR-CHARTER-v1.md
Teach-and-transfer: docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md
Handover: AI-HANDOVER.md only (no GROK-HANDOVER). Cold-start: docs/engineering/KEVIN-TURNOVER-LATEST.md. Execution contract: inbox/CURRENT_TASK.md.

Owner ask (Matt ~13:35 MT): Discord + Tailscale so phone at work can reach Kevin HQ Talk on HESS-PC (Omen). Prefer free personal Tailscale. Do NOT expose gateway port to the public internet (no raw port-forward / open ngrok without auth).

## 0. Live inventory (verified 2026-09-04 ~13:40 MT)

- Machine: HESS-PC (Omen), Windows 11.
- Tailscale client: **NOT installed** (missing Program Files\Tailscale, not on PATH, winget list empty, no Tailscale uninstall key).
- winget package available: `Tailscale.Tailscale` **1.102.3** (WiX MSI amd64; free personal plan; BSD-3-Clause). Offline distribution supported.
- HQ Talk / Chat gateway: **LISTENING on 127.0.0.1:18789 only** (loopback). Confirmed via netstat. Not on 0.0.0.0 / LAN / WAN.
- Reader 19001 / Operator 19101: leave UP. Do not kill Chat/Reader. Do not widen Desktop tools in this beat.
- Login/auth for Tailscale requires Matt at keyboard or browser (`request_box_help` via parent). Do not invent credentials or auth keys.

## 1. Goal / non-goals

**Goal:** Private mesh path so Matt's phone (cellular/work Wi-Fi) can reach HQ Talk on Omen without opening the gateway to the public internet.

**Non-goals / hard no:**
- Port-forward 18789 on home router.
- Unauthenticated ngrok / Cloudflare Tunnel Funnel / any WAN listener.
- Killing or rebinding Chat/Reader as part of install.
- Widening Desktop tool inventory.
- Storing Tailscale auth keys or account passwords in repo.

## 2. Architecture (Kevin-owned long-term)

```
Phone (Tailscale app)  --tailnet-->  Omen/HESS-PC (Tailscale client)
                                         |
                                         +-- Tailscale Serve OR bind-aware path
                                         +-- HQ Talk still locally on 127.0.0.1:18789
```

Fail closed: if Tailscale is offline / logged out / ACL denies, phone cannot reach Talk. That is correct.

### 2.1 Why raw `http://100.x.y.z:18789` will NOT work today

Services bound to `127.0.0.1` are unreachable via Tailscale IP in TUN mode. Live dock is loopback-only. Therefore:

| Option | What it does | WAN exposure | Owner effort | Recommend |
|--------|--------------|--------------|--------------|-----------|
| A. `tailscale serve` proxy to `http://127.0.0.1:18789` | Tailnet-only HTTPS (or HTTP) front door; Chat stays on loopback | None (Serve is tailnet-only; do **not** enable Funnel) | After both devices joined: one CLI on Omen | **P0 preferred** |
| B. Rebind Talk to Tailscale IP / dual-bind | Direct `http://100.x.y.z:18789` or MagicDNS name | None if ACL tight; risk if someone later binds 0.0.0.0 | Config change + prove Chat still local | P1 later |
| C. Small authenticated reverse proxy on tailnet IP | Extra auth layer in front of loopback | None if bound to tailnet only | Build + maintain | P2 if Serve insufficient |
| D. Router port-forward / public ngrok | Opens WAN | **YES — forbidden** | — | **NO** |

Default path: **Option A (Tailscale Serve)** after owner login. Keeps Chat on 127.0.0.1; Kevin-owned; fail closed when offline.

### 2.2 MagicDNS

Enable MagicDNS in admin console (DNS → Enable MagicDNS). Phone then uses a stable name like `http://hess-pc` or HTTPS Serve URL `https://hess-pc.<tailnet>.ts.net` instead of remembering `100.x.y.z`.

### 2.3 ACLs (phone + Omen only)

Tighten default open policy so only Matt's phone and Omen talk to each other for HQ. Example shape (edit in admin.tailscale.com → Access Controls; adjust hostnames/tags after devices appear):

```json
{
  "tagOwners": {
    "tag:omen": ["autogroup:admin"],
    "tag:phone": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:phone"],
      "dst": ["tag:omen:443", "tag:omen:80"]
    },
    {
      "action": "accept",
      "src": ["tag:omen"],
      "dst": ["tag:phone:*"]
    }
  ]
}
```

Notes:
- Prefer tags over bare user wildcards once devices are tagged.
- Serve HTTPS uses 443 on the node; do not open 18789 in ACL unless Option B is chosen later.
- Fail closed: if Omen offline or Tailscale down, phone gets no path — expected.

## 3. Phased execution

### Phase 0 — Client install only (SAFE, no login) — THIS BEAT

1. Silent install Tailscale client via winget/MSI with no GUI launch:
   - `winget install --id Tailscale.Tailscale --exact --silent --accept-package-agreements --accept-source-agreements --override "/qn TS_NOLAUNCH=1"`
   - Or equivalent msiexec `/qn TS_NOLAUNCH=1` from pkgs.tailscale.com stable MSI.
2. Verify `tailscale.exe` present under Program Files; service exists; **do not** run `tailscale up`.
3. Stop at **READY_FOR_OWNER_LOGIN**.

### Phase 1 — Owner login (Matt at keyboard / browser) — BLOCKED on human

1. On Omen: open Tailscale tray **or** run `tailscale up` (optionally `--unattended` so it survives reboot/sign-out for always-on HQ).
2. Complete browser SSO for free personal account (same account = same tailnet).
3. On phone: install Tailscale from App Store / Play Store; log in with **same** account.
4. Confirm both show connected in admin console / `tailscale status`.
5. Note Omen Tailscale IPv4 (`tailscale ip -4`) and MagicDNS name.

Parent must use `request_box_help` / owner-at-keyboard pattern. Agents must not invent auth keys or passwords. Auth-key path is optional later for unattended re-join; still owner-generated in admin console, never committed.

### Phase 2 — Expose Talk on tailnet without WAN (after login)

Preferred:

```text
tailscale serve --bg localhost:18789
```

(or interactive `tailscale serve` flow; enable HTTPS certs in admin if prompted). Phone opens the Serve URL shown by `tailscale serve status` (tailnet-only).

Alternative interim (only if Talk is later dual-bound and ACL allows 18789):

```text
http://<omen-tailscale-ip>:18789
http://<magicdns-name>:18789
```

Do **not** enable Tailscale Funnel for this port.

### Phase 3 — HQ Pages + Talk UX

- Short term: Matt bookmarks Serve URL / MagicDNS URL on phone browser.
- Medium: HQ Pages link or Talk dock target points at Tailscale URL when remote; local dock stays `http://127.0.0.1:18789`.
- Long-term Kevin-owned: document Serve command in boot/recovery so path survives reboot (with `--unattended` Tailscale).

## 4. Owner phone steps (Matt checklist)

1. Install **Tailscale** on phone (iOS/Android official app).
2. Sign in with the **same** Tailscale account used on Omen (free personal).
3. Wait until phone shows Connected and Omen appears in the app device list.
4. Open the Serve URL from Phase 2 (preferred) **or** `http://<omen-magicdns>:18789` only if Talk was rebound (not default today).
5. If it fails: check Tailscale Connected on both ends; confirm ACL; confirm Chat still listening on 127.0.0.1:18789; confirm Serve still active. Do not open the home router.

## 5. Safety / rollback

- Install is reversible: Settings → Apps → Tailscale → Uninstall, or `winget uninstall Tailscale.Tailscale`.
- No change to openclaw.json / Desktop allowlist in this PLAN.
- No WAN listener added by Phase 0–2 if Funnel stays off.
- Secrets: never commit auth keys, SSO cookies, or admin URLs with tokens.

## 6. Success criteria

- [ ] Tailscale client installed on Omen; status READY_FOR_OWNER_LOGIN or Connected.
- [ ] Phone on same tailnet.
- [ ] Matt reaches HQ Talk from phone browser over Tailscale only.
- [ ] 18789 still not listening on public/WAN interfaces.
- [ ] Chat 18789 + Reader 19001 remain UP through the work.
- [ ] LESSON + MEMORY + CURRENT_TASK updated; sanitized PLAN PR opened if clean.

## 7. Status snapshot (this beat)

- Inventory update 2026-09-04 ~14:25 MT: Tailscale.Tailscale **1.102.3 installed** (winget + `C:\Program Files\Tailscale\tailscale.exe`); service Tailscale Running/Automatic; `tailscale status` = **Logged out / NeedsLogin**.
- Chat still **127.0.0.1:18789** only; Reader 19001 UP. No Funnel / no WAN expose. Did **not** run `tailscale up`.
- Status: **READY_FOR_OWNER_LOGIN**.
- Owner action required: Phase 1 login on Omen + phone (same free personal account), then Phase 2 `tailscale serve --bg localhost:18789` (not Funnel; prefer Serve over raw 100.x:18789).
