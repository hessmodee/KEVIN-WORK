"use strict";
/**
 * Hostile-only attack skill (scaffold).
 * Prefers injected bot.attack; falls back to JOIN_OK client.queue inventory_transaction shape.
 * NEVER attacks players / hessmodee / kevinsk8erkid. NOT live-proven.
 */
const path = require("path");
const bridge = require(path.join(__dirname, "..", "..", "bridge"));
const NAME = "combat-attack-hostile-only";
const HOSTILE = new Set([
  "zombie","skeleton","spider","creeper","enderman","witch","slime","phantom",
  "drowned","husk","stray","blaze","ghast","magma_cube","silverfish","endermite",
  "guardian","pillager","vindicator","ravager","hoglin","warden","bogged",
  "cave_spider","wither_skeleton","zombie_villager",
]);

function isHostileEntity(entity) {
  if (!entity) return false;
  if (entity.type === "player") return false;
  const n = String(entity.name || entity.type || entity.username || "").toLowerCase().replace(/^minecraft:/, "");
  if (n === "hessmodee" || n === "kevinsk8erkid") return false;
  return HOSTILE.has(n) || (entity.metadata && entity.metadata.hostile === true);
}

async function run(ctx = {}) {
  const { bot, client, entity } = ctx;
  if (!entity) return { ok: false, status: "NOT_PROVEN", skill: NAME, reason: "NO_ENTITY" };
  if (!isHostileEntity(entity)) {
    return { ok: false, status: "DENIED", skill: NAME, reason: "NOT_HOSTILE_OR_FRIENDLY" };
  }
  if (bot && typeof bot.attack === "function") {
    return bridge.attackHostileOnly(bot, entity);
  }
  if (client && entity.id != null) {
    return bridge.queueAttackRuntime(client, entity.id, ctx.playerPos, ctx.heldItem);
  }
  return { ok: false, status: "NOT_PROVEN", skill: NAME, reason: "NO_BOT_OR_CLIENT" };
}

module.exports = { name: NAME, status: "SCAFFOLD_NOT_PROVEN", isHostileEntity, HOSTILE, run };
