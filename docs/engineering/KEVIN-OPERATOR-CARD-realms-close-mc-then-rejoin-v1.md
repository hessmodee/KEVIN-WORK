# KEVIN OPERATOR CARD — Realms close-MC-then-rejoin v1

**Updated:** 2026-09-05 ~17:20 MT
**Authority:** UNDYING GREEN+YELLOW teach. No live join while Minecraft.Windows UI mid-session.
**Identity:** Kevin = **kevinsk8erkid** only. Matt Xbox = **hessmodee**. Never hessmodee bot login.

## One-command play path (after UI clear)

When Matt wants Kevin in the Realm and the human Minecraft client is **not** running:

```bat
scratch\kevin-minecraft-bedrock-v0\rejoin.cmd
```

That single command: preflight-stay → `KEVIN_REALMS_STAY=1` → `realms-join.js` (expect `KEVIN_REALMS_JOIN_OK` + ~30s heartbeat).

## Before that command (human closes UI)

1. **Matt/human** closes Minecraft UWP normally (Quit / Alt+F4).  
2. **Kevin NEVER** `taskkill` / Stop-Process `Minecraft.Windows.exe`. Preflight exists so we refuse, not fight the human client.  
3. Optional status (no join): `scratch\kevin-minecraft-bedrock-v0\status-play-ready.cmd`  
   - Prints READY_FOR_PLAY row + preflight marker.  
   - Exit 0 = clear to rejoin; exit 2 = still BLOCKED_MC_UI.

## Fail-closed markers

| Marker | Meaning |
| --- | --- |
| `KEVIN_REALMS_STAY_PREFLIGHT_OK` | No Minecraft.Windows.exe — rejoin path clear |
| `KEVIN_REALMS_STAY_PREFLIGHT_BLOCKED_MC_UI` | UI mid-session — **do not** rejoin/stay smoke |
| `KEVIN_REALMS_JOIN_OK` | Protocol join proven (NetherNet / 2169 / 1.26.45) |

## Hard nos

- No kill Minecraft.Windows.  
- No rejoin while preflight blocked.  
- No hessmodee; no invent passwords; no purchases.  
- Do not stop Chat 18789 / Reader 19001 / Operator 19101.

## Pointers

- Checklist: `docs/engineering/KEVIN-CHECKLIST-READY-FOR-PLAY-realms-2026-09-05.md`  
- Playbook: `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md`  
- Preflight LESSON: `docs/engineering/LESSON-realms-stay-preflight-mc-ui-2026-09-05.md`

## Companion stay + chase (Kevin-owned)

For follow/chase after JOIN_OK (physics OFF, auth_input loop):

```bat
scratch\kevin-minecraft-stack-spike-v0\kevin-stay-chase.cmd
```

Alias: `rejoin-companion.cmd`. Identity kevinsk8erkid. Log: `_rejoin-companion.log`.
See LESSON-BEDROCK-REALMS-LOCOMOTION-2026-09-05.md. Visible move needs Matt confirm.
