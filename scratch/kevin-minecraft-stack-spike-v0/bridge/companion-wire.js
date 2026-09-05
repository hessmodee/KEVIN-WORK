"use strict";
/**
 * Wire companion GoalFollow + hostile-only guard onto an injected bot.
 * SCAFFOLD ONLY — does not claim FOLLOW_OK / COMBAT_OK / GUARD_OK.
 */
const { findMattEntity } = require("./find-matt");
const { attachCompanionDefaults, loadVendor } = require("./create-bot-injected");

function followMatt(bot, opts = {}) {
  if (!bot) return { ok: false, status: "NOT_PROVEN", reason: "NO_BOT" };
  const range = opts.range != null ? opts.range : 3;
  const matt = findMattEntity(bot, opts);
  if (!matt) {
    return { ok: false, status: "NOT_PROVEN", reason: "MATT_NOT_FOUND", hint: "hessmodee not in bot.players yet" };
  }
  const vendor = loadVendor();
  const GoalFollow = vendor.GoalFollow;
  if (!bot.pathfinder || !GoalFollow) {
    return { ok: false, status: "NOT_PROVEN", reason: "NO_PATHFINDER_OR_GOALFOLLOW" };
  }
  try {
    bot.pathfinder.setGoal(new GoalFollow(matt, range), true);
    return { ok: false, status: "WIRED_NOT_PROVEN", action: "GoalFollow", target: "hessmodee", range };
  } catch (e) {
    return { ok: false, status: "NOT_PROVEN", reason: String(e && e.message || e) };
  }
}

function enableHostileGuard(bot, opts = {}) {
  if (!bot) return { ok: false, status: "NOT_PROVEN", reason: "NO_BOT" };
  attachCompanionDefaults(bot, opts);
  if (!bot.guard) return { ok: false, status: "NOT_PROVEN", reason: "NO_GUARD_PLUGIN" };
  bot.guard.options.targetPlayers = false;
  if (opts.enable === true) {
    bot.guard.enable();
    return { ok: false, status: "WIRED_NOT_PROVEN", action: "guard.enable", whitelist: bot.guard.options.whitelist };
  }
  return { ok: false, status: "WIRED_NOT_PROVEN", action: "guard.configured", enabled: false, whitelist: bot.guard.options.whitelist };
}

function attackHostileOnly(bot, entity) {
  if (!bot || !bot.attack) return { ok: false, status: "NOT_PROVEN", reason: "NO_ATTACK" };
  if (!entity) return { ok: false, status: "NOT_PROVEN", reason: "NO_ENTITY" };
  const name = String(entity.username || entity.name || entity.type || "").toLowerCase();
  if (name === "hessmodee" || name === "kevinsk8erkid" || entity.type === "player") {
    return { ok: false, status: "DENIED", reason: "NO_FRIENDLY_FIRE_OR_PVP" };
  }
  if (bot.guard && typeof bot.guard.isHostile === "function" && !bot.guard.isHostile(entity)) {
    return { ok: false, status: "DENIED", reason: "NOT_HOSTILE" };
  }
  try {
    const swung = bot.attack(entity, true);
    return { ok: false, status: "WIRED_NOT_PROVEN", action: "attack", swung: !!swung };
  } catch (e) {
    return { ok: false, status: "NOT_PROVEN", reason: String(e && e.message || e) };
  }
}

/**
 * Packet-level helpers mirroring what JOIN_OK client already supports (queue).
 * Used when BedrockBot plugins are not attached yet.
 */
function queueChat(client, message, sourceName) {
  if (!client || typeof client.queue !== "function") {
    return { ok: false, status: "NOT_PROVEN", reason: "NO_CLIENT_QUEUE" };
  }
  try {
    client.queue("text", {
      type: "chat",
      needs_translation: false,
      source_name: sourceName || "kevinsk8erkid",
      xuid: "",
      platform_chat_id: "",
      filtered_message: "",
      message: String(message || ""),
    });
    return { ok: true, status: "QUEUED", packet: "text" };
  } catch (e) {
    return { ok: false, status: "NOT_PROVEN", reason: String(e && e.message || e) };
  }
}

function queueAttackRuntime(client, entityRuntimeId, playerPos, heldItem) {
  if (!client || typeof client.queue !== "function") {
    return { ok: false, status: "NOT_PROVEN", reason: "NO_CLIENT_QUEUE" };
  }
  // Shape matches bedrockflayer combat plugin (inventory_transaction type 3).
  // NOT live-proven on Realms NetherNet.
  try {
    client.queue("inventory_transaction", {
      transaction: {
        transaction_type: 3,
        actions: [],
        transaction_data: {
          entity_runtime_id: entityRuntimeId,
          action_type: 1,
          hotbar_slot: 0,
          held_item: heldItem || { network_id: 0 },
          player_pos: playerPos || { x: 0, y: 0, z: 0 },
          click_pos: playerPos || { x: 0, y: 0, z: 0 },
        },
      },
    });
    return { ok: false, status: "WIRED_NOT_PROVEN", packet: "inventory_transaction" };
  } catch (e) {
    return { ok: false, status: "NOT_PROVEN", reason: String(e && e.message || e) };
  }
}

module.exports = {
  followMatt,
  enableHostileGuard,
  attackHostileOnly,
  queueChat,
  queueAttackRuntime,
};
