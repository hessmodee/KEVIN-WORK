"use strict";
/**
 * Combat attack — hostile-only scaffold.
 * Packet shape mirrors bedrockflayer combat (inventory_transaction type 3) when ctx.client.queue exists.
 * STUB/SCAFFOLD — NOT live-proven. Never emit KEVIN_MC_COMBAT_OK.
 */
const NAME = "combat-attack";
const HOSTILE = new Set([
  "zombie","skeleton","spider","creeper","enderman","witch","slime","phantom",
  "drowned","husk","stray","blaze","ghast","magma_cube","pillager","ravager",
  "cave_spider","wither_skeleton","zombie_villager","warden","bogged","hoglin",
]);
function notProven(action, extra) {
  console.log("[kevin-mc-stub]", NAME, action, "NOT_PROVEN");
  return Object.assign({ ok: false, status: "NOT_PROVEN", action, skill: NAME }, extra || {});
}
function isHostile(entity) {
  if (!entity) return false;
  if (entity.type === "player") return false;
  const n = String(entity.name || entity.type || entity.username || "").toLowerCase().replace(/^minecraft:/, "");
  if (n === "hessmodee" || n === "kevinsk8erkid") return false;
  return HOSTILE.has(n);
}
async function run(ctx = {}) {
  const entity = ctx.entity;
  if (!entity) return notProven("run", { reason: "NO_ENTITY" });
  if (!isHostile(entity)) return { ok: false, status: "DENIED", skill: NAME, reason: "NOT_HOSTILE_OR_FRIENDLY" };
  if (ctx.bot && typeof ctx.bot.attack === "function") {
    try {
      ctx.bot.attack(entity, true);
      return { ok: false, status: "WIRED_NOT_PROVEN", skill: NAME, via: "bot.attack" };
    } catch (e) {
      return notProven("bot.attack", { reason: String(e && e.message || e) });
    }
  }
  if (ctx.client && typeof ctx.client.queue === "function" && entity.id != null) {
    try {
      ctx.client.queue("inventory_transaction", {
        transaction: {
          transaction_type: 3,
          actions: [],
          transaction_data: {
            entity_runtime_id: entity.id,
            action_type: 1,
            hotbar_slot: ctx.hotbarSlot || 0,
            held_item: ctx.heldItem || { network_id: 0 },
            player_pos: ctx.playerPos || { x: 0, y: 0, z: 0 },
            click_pos: entity.position || ctx.playerPos || { x: 0, y: 0, z: 0 },
          },
        },
      });
      return { ok: false, status: "WIRED_NOT_PROVEN", skill: NAME, via: "client.queue:inventory_transaction" };
    } catch (e) {
      return notProven("queue", { reason: String(e && e.message || e) });
    }
  }
  return notProven("run", { reason: "NO_BOT_OR_CLIENT", hint: "Need injected bot or JOIN_OK client" });
}
module.exports = { name: NAME, status: "SCAFFOLD_NOT_PROVEN", HOSTILE, isHostile, run, notProven };
