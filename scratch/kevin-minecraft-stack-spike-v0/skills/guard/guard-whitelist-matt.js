"use strict";
/**
 * Guard whitelist Matt (hessmodee); hostile-only; targetPlayers=false.
 * NOT live-proven — do not emit KEVIN_MC_GUARD_OK.
 */
const path = require("path");
const bridge = require(path.join(__dirname, "..", "..", "bridge"));
const NAME = "guard-whitelist-matt";

async function run(ctx = {}) {
  const bot = ctx.bot;
  if (!bot) return { ok: false, status: "NOT_PROVEN", skill: NAME, reason: "NO_BOT" };
  return Object.assign({ skill: NAME }, bridge.enableHostileGuard(bot, {
    enable: ctx.enable === true,
    extraWhitelist: ctx.extraWhitelist,
  }));
}

module.exports = { name: NAME, status: "SCAFFOLD_NOT_PROVEN", run };
