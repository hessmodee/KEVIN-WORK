"use strict";
/**
 * Companion follow Matt (Xbox hessmodee) — GoalFollow scaffold.
 * Find-by-name; prefers bot.pathfinder + GoalFollow from stack-spike bridge/vendor.
 * STUB/SCAFFOLD — NOT live-proven. Never emit KEVIN_MC_FOLLOW_OK.
 */
const NAME = "companion-follow";
const MATT_NAMES = ["hessmodee"];
function notProven(action, extra) {
  console.log("[kevin-mc-stub]", NAME, action, "NOT_PROVEN");
  return Object.assign({ ok: false, status: "NOT_PROVEN", action, skill: NAME }, extra || {});
}
function findMatt(bot) {
  if (!bot) return null;
  const players = bot.players || {};
  for (const key of Object.keys(players)) {
    const p = players[key];
    const uname = String((p && (p.username || p.name)) || key).toLowerCase();
    if (uname === "hessmodee" || uname.includes("hessmodee")) return p.entity || p;
  }
  const entities = bot.entities || {};
  for (const id of Object.keys(entities)) {
    const e = entities[id];
    const uname = String((e && (e.username || e.name || e.displayName)) || "").toLowerCase();
    if (uname === "hessmodee" || uname.includes("hessmodee")) return e;
  }
  return null;
}
async function run(ctx = {}) {
  const bot = ctx.bot;
  if (!bot) return notProven("run", { reason: "NO_BOT", target: "hessmodee" });
  const matt = findMatt(bot);
  if (!matt) return notProven("run", { reason: "MATT_NOT_FOUND", target: "hessmodee" });
  const range = ctx.range != null ? ctx.range : 3;
  if (bot.pathfinder && ctx.GoalFollow) {
    try {
      bot.pathfinder.setGoal(new ctx.GoalFollow(matt, range), true);
      return { ok: false, status: "WIRED_NOT_PROVEN", skill: NAME, via: "GoalFollow", target: "hessmodee", range };
    } catch (e) {
      return notProven("GoalFollow", { reason: String(e && e.message || e) });
    }
  }
  if (bot.pathfinder && bot.pathfinder.goto && ctx.GoalNear && matt.position) {
    try {
      // Fire-and-forget intent only — still NOT_PROVEN
      bot.pathfinder.goto(new ctx.GoalNear(matt.position.x, matt.position.y, matt.position.z, range));
      return { ok: false, status: "WIRED_NOT_PROVEN", skill: NAME, via: "GoalNear", target: "hessmodee", range };
    } catch (e) {
      return notProven("GoalNear", { reason: String(e && e.message || e) });
    }
  }
  return notProven("run", {
    reason: "NO_PATHFINDER",
    hint: "Inject JOIN_OK client via stack-spike bridge/createBotFromClient first",
    mattSeen: true,
  });
}
module.exports = { name: NAME, status: "SCAFFOLD_NOT_PROVEN", MATT_NAMES, findMatt, run, notProven };
