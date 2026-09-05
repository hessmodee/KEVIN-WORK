# API inventory (static) — bedrockflayer 0.1.0 vendor

**Updated:** 2026-09-05 ~09:33 MT

## module.exports
- createBot, BedrockBot, Registry, version
- GoalBlock, GoalNear, GoalXZ, GoalFollow, GoalInvert, goals
- autoEat, collectBlock, guard (opt-in loadPlugin)

## Built-in plugins (auto)
chat, health, entities, world, physics, controls, inventory, windows, digging, placing, combat, crafting, vehicles, sleep, time, scoreboard, sound, creative, resource_pack, pathfinder

## Notable methods
- bot.pathfinder.goto(goal) / stop()
- bot.attack(entity), bot.swingArm()
- bot.guard.enable()/disable() after loadPlugin(guard); whitelist for friendly fire
- dig/place/craft/auto_eat present as plugins

## Smoke
`smoke-require.js` checks import + export presence only.
