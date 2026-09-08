# RUNBOOK — Minecraft Realms companion troubleshooting v1

**Updated:** 2026-09-05 ~17:20 MT  
**Identity:** kevinsk8erkid on HESSMODEE's Realm  
**Never:** kill Chat 18789 / Reader 19001; mutate JOIN_OK package-lock; bot-login hessmodee.

## Quick triage

| Symptom | Likely | First action |
| --- | --- | --- |
| Cannot rejoin / preflight blocked | BLOCKED_MC_UI | Ask Matt to close Minecraft.Windows UWP; wait CLEAR; `rejoin.cmd` |
| Join fails version | outdated_client | Match protocol **2169** / UWP **1.26.45x**; update client or overlay |
| Auth / whoami wrong | IdentityNotAllowed | Use kevinsk8erkid cache only; never hessmodee |
| Soft close warning | packet_violation | Often residual on disconnect; cool; rejoin; don't thrash |
| Bot spins / no progress | pathfinder stuck | Cancel goal; re-goal; if body not live, admit coach-only |
| Frozen at beds / SizeOf reading 'x' | Wrong `player_auth_input` shape or move_player-only chase | See locomotion section below; restart Kevin stay |
| physicsEnabled crash createPacketBuffer | bedrockflayer physics on Realms inject | Keep physicsEnabled:false; use raw-auth-chase.js |

| Matt damaged by Kevin | friendly fire | Immediate stop; whitelist deny; apologize; diagnose |

## BLOCKED_MC_UI

- Cause: Minecraft.Windows holds Realm session / device slot.
- Do **not** kill UWP from Kevin automation unless Matt explicitly asks (prefer ask Matt).
- Wait for Matt to close MC → preflight CLEAR → `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd`.
- Stay mode preferred for play sessions.

## outdated_client

- JOIN_OK proven on protocol **2169** (1.26.45 family).
- If Realm/protocol drifts, update Bedrock client + overlay recipe before inventing forks.
- Pointer: `docs/engineering/RECIPE-nethernet-realms-overlay-v2.md`, LESSON nethernet JOIN_OK.

## IdentityNotAllowed / wrong identity

- Only **kevinsk8erkid**.
- If auth cache points wrong account: stop; fix cache; never fall back to hessmodee.
- Matt Xbox = partner only.

## packet_violation / soft residual

- Observed soft `packet_violation_warning` on close after JOIN_OK sessions — not automatic "ban forever."
- Cool retries; don't tight-loop reconnect.
- Capture log pointer locally; no secrets in public MEMORY.

## pathfinder stuck (when body exists)

- Cancel current Goal*; clear state machine to Idle/Look.
- Re-acquire hessmodee position; smaller GoalFollow radius.
- If still stuck: Retreat to bed; chat Matt; cool.
- If FOLLOW not receipt-proven: do not claim pathfinder failure as if autopilot was live — say scaffold/coach.

## friendly-fire prevent

- Hard deny target = hessmodee, pets, named, pen animals, iron golems, villagers (unless Matt explicit).
- Hostile-only filter before any attack packet.
- On incident: stop combat mode → Guard/Idle → record LESSON.
- NEG: companion fake-kills / PvP Matt eval.

## Bridge / IMPORT / smoke

- IMPORT_OK ≠ live follow.
- Prefer `scratch/kevin-minecraft-stack-spike-v0/smoke-bridge.cmd` before claiming inject.
- Never copy spike mutations into JOIN_OK lockfile.

## LLM / Voyager loop issues

- Prefer local Ollama/Qwen.
- If someone suggests paid GPT-4 Voyager cloud: mark RED; need owner purchasing auth.
- No Fabric-on-Realms "fix" for skill library.

## Recovery ladder (standing)

1. Diagnose with evidence  
2. Different approach  
3. Third approach  
4. Cool + honest blocker + stay friend available  

## Related

- Elite playbook: `docs/engineering/KEVIN-PLAYBOOK-elite-minecraft-coplayer-v1.md`
- Research: `docs/engineering/RESEARCH-minecraft-ai-companions-sota-2026-09-05.md`

## auth_input / frozen avatar (2026-09-05)

1. Confirm stay is Kevin-local: `scratch\kevin-minecraft-stack-spike-v0\kevin-stay-chase.cmd` (not CoS puppeteering).
2. Kill **only** `node rejoin-companion.js` / realms-join companion PIDs — never Chat/Reader/Operator.
3. Ensure `physicsEnabled:false` in `rejoin-companion.js`.
4. Ensure `bridge/raw-auth-chase.js` uses #724 / 1.26.45 shape: yaw degrees, move vectors `{x,z}`, full fields, 50ms loop.
5. Expect logs: `KEVIN_REALMS_JOIN_OK`, `[auth-chase] authInput.chase` with real self coords, no SizeOf crash.
6. Visible walk still needs Matt eyes — do not claim FOLLOW_OK from logs alone.
7. LESSON: `docs/engineering/LESSON-BEDROCK-REALMS-LOCOMOTION-2026-09-05.md`
