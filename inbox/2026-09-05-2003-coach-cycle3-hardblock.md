# COACH CYCLE3 - same NetherNet modal + capability hard-block (~2026-09-05 20:04 MT)

## Observe (read-only)
- Shot: `scratch\kevin-minecraft-gdk-client-v0\logs\mc-coach-20260905-200126.png`
- Still **Multiplayer Connection Failed** (NetherNet). Overlay now Kevin Canonical Handover tab.
- Network: xboxlive.com:443 OK, minecraft.net:443 OK.
- No new `kevin_play_go*.log` / walk logs since ~19:35 MT.
- Same modal across coach cycles 1–3 (~19:51 → 19:54 → 20:01 MT).

## What CoS did (coach-only)
- Wrote inbox + CURRENT_TASK; pushed to GitHub `hessmodee/KEVIN-WORK` inbox (bridge path).
- Prompted Grok Bot + Kevin HQ text.
- `openclaw agent --agent main` with P0 task:
  - qwen2.5:14b timed out (provider)
  - llama3.1:8b responded but `kevin_app_launch(app=cmd)` **validation FAIL** — allowlist is only notepad/calculator/paint/explorer

## Kevin capability fact (live Chat)
- tools.allow exact-5 desktop only; **no exec**, **no Minecraft UI**, `kevin_app_launch` refuses cmd/powershell/Minecraft.
- TOOLS.md: Play-with-Matt / Minecraft is **Not a Chat tool**.
- Desktop UI Phase2 click/type **not** on live Chat allowlist.
- Therefore Kevin **cannot alone** click Reconnect or run `kevin_play_go.cmd` through OpenClaw Chat right now.

## Deepen steps Kevin would run IF Matt unlocks exec/UI OR runs them himself
1. Minecraft: **Show details** → copy NetherNet code; then **Back to menu**
2. Close Minecraft via UI (Quit/X) — never taskkill
3. Optional: Xbox privacy multiplayer Allow; confirm Windows Firewall Minecraft on Private
4. Relaunch as **kevinsk8erkid**
5. `cd scratch\kevin-minecraft-gdk-client-v0` → `kevin_play_go.cmd`
6. In-world → `kevin_gdk_move.cmd 5` → expect `WALK_KEYBOARD_OK`
7. Never ViGEm mid-session

## Escalation
TRUE HARD-BLOCK needing **Matt**: authorize CoS puppeteering OR temporarily widen Kevin tools / enable Desktop UI for this Realms restore / Matt clicks+runs cmds himself.