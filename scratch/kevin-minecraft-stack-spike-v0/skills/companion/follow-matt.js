"use strict";
/**
 * Companion GoalFollow Matt (hessmodee) scaffold.
 * Uses bridge.findMattEntity + GoalFollow when pathfinder present.
 * NOT live-proven — do not emit KEVIN_MC_FOLLOW_OK.
 */
const path = require("path");
const bridge = require(path.join(__dirname, "..", "..", "bridge"));
const NAME = "companion-follow-matt";

async function run(ctx = {}) {
  const bot = ctx.bot;
  if (!bot) return { ok: false, status: "NOT_PROVEN", skill: NAME, reason: "NO_BOT" };
  return Object.assign({ skill: NAME }, bridge.followMatt(bot, { range: ctx.range != null ? ctx.range : 3 }));
}

module.exports = { name: NAME, status: "SCAFFOLD_NOT_PROVEN", run, findMattEntity: bridge.findMattEntity };
