# LESSON: Tailscale remote HQ — loopback Talk needs Serve, not WAN (2026-09-04)

**At:** 2026-09-04 ~13:35–13:45 MT (America/Denver)
**Actor:** GrokBot-executor
**Result:** PLAN + inventory PASS; client install attempted separately; auth deferred to owner

## Owner ask
Matt (~13:35 MT): Discord + Tailscale so phone at work can reach Kevin HQ Talk. Prefer free personal Tailscale. Do not expose 18789 publicly.

## Verified inventory
- Tailscale **not** installed on HESS-PC (Program Files missing, winget empty, no PATH).
- winget offers `Tailscale.Tailscale` 1.102.3 (free personal MSI).
- Chat/Talk dock **LISTENING 127.0.0.1:18789 only** — loopback. Raw `http://100.x.y.z:18789` will fail until Serve or rebind.

## Teach
1. **Loopback ≠ tailnet.** TUN Tailscale does not forward to 127.0.0.1. Prefer `tailscale serve` (tailnet-only) over rebinding Chat to 0.0.0.0.
2. **Never Funnel / port-forward / naked ngrok for 18789.** Fail closed when Tailscale offline.
3. **Install ≠ login.** Silent MSI/winget with `TS_NOLAUNCH` is GREEN. `tailscale up` / browser SSO needs Matt (`request_box_help`). Do not invent auth keys.
4. **ACLs:** phone + Omen only after join; Serve on 443/80 preferred over opening 18789 in ACL.
5. **Do not kill Chat/Reader** for remote access work. Desktop tools stay exact-4.

## Durable refs
- PLAN: `docs/engineering/PLAN-kevin-tailscale-remote-hq-2026-09-04.md`
- Auth card: `docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md`

## Next
Owner login same tailnet on Omen + phone → `tailscale serve --bg localhost:18789` → bookmark Serve URL on phone.
