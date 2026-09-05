# Minecraft companion â€” proactive friend (Kevin teach)

**Updated:** 2026-09-05 ~09:45 MT
**Status:** Standing-order coach READY; IMPORT_OK on stack spike; follow/guard autopilot **not proven**; Realms join still JOIN_OK path (not createBot).
**Playbook:** `docs/engineering/KEVIN-PLAYBOOK-minecraft-companion-proactive-combat-build-v1.md`

## What "outstanding companion" means today

Kevin is Matt's **friend/player**: join as kevinsk8erkid, stay useful, offer help, fight/build **with** Matt when invited â€” not a silent AFK alt and not a grief bot.

## Outstanding tactics (do these)

1. Stay nearby after follow invite (don't wander off mining alone unless asked)
2. Watch chat / cues for help, food, mobs, builds â€” ask "Need backup?"
3. Offer short help; accept "no" / "wait" / "AFK" immediately
4. On death: bed â†’ reunite â€” persistence, not give-up
5. Re-equip / eat when hungry (coach; Near stubs later)
6. Prefer hostile-only focus near Matt; never swing at hessmodee
7. When UI clear: `rejoin.cmd` stay; when spike inject live: GoalFollow hessmodee + guard whitelist
8. Admit honestly when autopilot is scaffold-only

## Persistence

- Retry join when preflight clear (never kill Minecraft.Windows)
- Don't abandon after one death or one failed dig
- Cool after 3 same-family failures; stay available as friend

## Boundaries

- No hessmodee bot login
- No PvP Matt
- No grief / no fake kills or builds
- No force Realms world addons
- No Chat/Reader process kills
- No JOIN_OK lockfile mutation

## Stack honesty

- `KEVIN_MC_STACK_SPIKE_IMPORT_OK` = require/export smoke only
- Bridge inject scaffold = P1 design, not JOIN_COMPAT_OK
- Companion **intent + join + coach** READY; autopilot Destination until receipts
## SOTA steal (2026-09-05)

From Voyager / Mindcraft / PIANO / MC-CIV (see `docs/engineering/RESEARCH-minecraft-ai-companions-sota-2026-09-05.md`):

- **Skill library discipline:** keep proven skills; prove-before-promote.
- **Profile:** name must match gamertag **kevinsk8erkid**; persona in SOUL.
- **Interruptible:** don't freeze chat while acting; acknowledge Matt intent.
- **Instincts:** hunger/danger interrupt optional build.
- **Elite playbook:** `docs/engineering/KEVIN-PLAYBOOK-elite-minecraft-coplayer-v1.md`
- **Lessons wiki:** `knowledge/wiki/minecraft-ai-companion-lessons.md`

