"use strict";
/**
 * Guard Matt — whitelist hessmodee; hostile-only; never PvP Matt.
 * STUB/SCAFFOLD — NOT live-proven. Never emit KEVIN_MC_GUARD_OK.
 */
const NAME = "guard-matt";
function notProven(action, extra) {
  console.log("[kevin-mc-stub]", NAME, action, "NOT_PROVEN");
  return Object.assign({ ok: false, status: "NOT_PROVEN", action, skill: NAME }, extra || {});
}
async function run(ctx = {}) {
  const bot = ctx.bot;
  if (!bot) return notProven("run", { reason: "NO_BOT" });
  if (!bot.guard) {
    if (ctx.guardPlugin && typeof bot.loadPlugin === "function") {
      try { bot.loadPlugin(ctx.guardPlugin); } catch (e) {
        return notProven("loadPlugin", { reason: String(e && e.message || e) });
      }
    }
  }
  if (!bot.guard) return notProven("run", { reason: "NO_GUARD_PLUGIN" });
  bot.guard.options.targetPlayers = false;
  const wl = new Set([...(bot.guard.options.whitelist || []), "hessmodee", "HESSMODEE"]);
  bot.guard.options.whitelist = Array.from(wl);
  if (ctx.enable === true) {
    bot.guard.enable();
    return { ok: false, status: "WIRED_NOT_PROVEN", skill: NAME, enabled: true, whitelist: bot.guard.options.whitelist };
  }
  return { ok: false, status: "WIRED_NOT_PROVEN", skill: NAME, enabled: false, whitelist: bot.guard.options.whitelist };
}
module.exports = { name: NAME, status: "SCAFFOLD_NOT_PROVEN", run, notProven };
