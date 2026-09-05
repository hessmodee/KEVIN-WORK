"use strict";
/**
 * Focus hostile near Matt — selection helper for guard/combat.
 * STUB/SCAFFOLD — NOT live-proven.
 */
const NAME = "guard-focus-hostile";
const attackMod = require("../combat/attack-stub");
function notProven(action, extra) {
  console.log("[kevin-mc-stub]", NAME, action, "NOT_PROVEN");
  return Object.assign({ ok: false, status: "NOT_PROVEN", action, skill: NAME }, extra || {});
}
function pickNearestHostile(bot, originEntity, range) {
  if (!bot || !bot.entities) return null;
  const origin = (originEntity && originEntity.position) || (bot.entity && bot.entity.position);
  if (!origin) return null;
  let best = null;
  let bestDist = range != null ? range : 16;
  for (const id of Object.keys(bot.entities)) {
    const e = bot.entities[id];
    if (!e || !e.position) continue;
    if (!attackMod.isHostile(e)) continue;
    const dx = e.position.x - origin.x;
    const dy = e.position.y - origin.y;
    const dz = e.position.z - origin.z;
    const d = Math.sqrt(dx * dx + dy * dy + dz * dz);
    if (d <= bestDist) { bestDist = d; best = e; }
  }
  return best;
}
async function run(ctx = {}) {
  const bot = ctx.bot;
  if (!bot) return notProven("run", { reason: "NO_BOT" });
  const matt = ctx.mattEntity || null;
  const target = pickNearestHostile(bot, matt || bot.entity, ctx.range != null ? ctx.range : 16);
  if (!target) return notProven("run", { reason: "NO_HOSTILE_IN_RANGE" });
  return { ok: false, status: "WIRED_NOT_PROVEN", skill: NAME, targetName: target.name || target.type, via: "pickNearestHostile" };
}
module.exports = { name: NAME, status: "SCAFFOLD_NOT_PROVEN", pickNearestHostile, run, notProven };
