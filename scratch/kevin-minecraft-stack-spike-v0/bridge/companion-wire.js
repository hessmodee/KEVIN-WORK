"use strict";
/**
 * Wire companion GoalFollow + hostile-only guard + safe autoEat onto an injected bot.
 * SCAFFOLD / WIRED_NOT_PROVEN — does not claim FOLLOW_OK / COMBAT_OK / GUARD_OK / EAT_OK
 * until spawn+entity receipts prove live behavior.
 *
 * NEG enforced: never attack players, never hessmodee login, no grief.
 */
const { findMattEntity, isMattName } = require("./find-matt");
const { attachCompanionDefaults, loadVendor } = require("./create-bot-injected");
const { assertBotIdentity, KEVIN_TAG, MATT_TAGS } = require("./paths");
const rawAuth = require("./raw-auth-chase");

const PLAYER_DENY = new Set(["player", "hessmodee", "kevinsk8erkid"]);

function followMatt(bot, opts = {}) {
  if (!bot) return { ok: false, status: "NOT_PROVEN", reason: "NO_BOT" };
  const range = opts.range != null ? opts.range : 3;
  const matt = findMattEntity(bot, opts);
  if (!matt) {
    return {
      ok: false,
      status: "NOT_PROVEN",
      reason: "MATT_NOT_FOUND",
      hint: "hessmodee / display variants not in bot.players yet",
      namesTried: opts.names || MATT_TAGS,
    };
  }
  const vendor = loadVendor();
  const GoalFollow = vendor.GoalFollow;
  if (!bot.pathfinder || !GoalFollow) {
    return { ok: false, status: "NOT_PROVEN", reason: "NO_PATHFINDER_OR_GOALFOLLOW" };
  }
  try {
    const goal = new GoalFollow(matt, range);
    // bedrockflayer uses goto(goal); setGoal is Mineflayer-only and missing here.
    if (typeof bot.pathfinder.goto === "function") {
      Promise.resolve(bot.pathfinder.goto(goal)).catch(function (err) {
        try { console.error("[followMatt] goto fail", err && err.message || err); } catch (e2) {}
      });
      return {
        ok: false,
        status: "WIRED_NOT_PROVEN",
        action: "GoalFollow.goto",
        target: "hessmodee",
        range,
        entityPresent: true,
      };
    }
    if (typeof bot.pathfinder.setGoal === "function") {
      bot.pathfinder.setGoal(goal, true);
      return {
        ok: false,
        status: "WIRED_NOT_PROVEN",
        action: "GoalFollow.setGoal",
        target: "hessmodee",
        range,
        entityPresent: true,
      };
    }
    return { ok: false, status: "NOT_PROVEN", reason: "PATHFINDER_NO_GOTO_OR_SETGOAL" };
  } catch (e) {
    return { ok: false, status: "NOT_PROVEN", reason: String(e && e.message || e) };
  }
}


function crudeChaseMatt(bot, opts = {}) {
  // Prefer Realms-safe player_auth_input on the live gym client.
  const client = opts.client || (bot && (bot._kevinClient || bot.client));
  if (client && bot) {
    return rawAuth.authInputChaseTick(bot, client, opts);
  }
  return { ok: false, status: "NOT_PROVEN", reason: "NO_CLIENT_FOR_AUTH_INPUT" };
}

function enableHostileGuard(bot, opts = {}) {
  if (!bot) return { ok: false, status: "NOT_PROVEN", reason: "NO_BOT" };
  attachCompanionDefaults(bot, opts);
  if (!bot.guard) return { ok: false, status: "NOT_PROVEN", reason: "NO_GUARD_PLUGIN" };
  bot.guard.options.targetPlayers = false;
  if (opts.enable === true) {
    bot.guard.enable();
    return {
      ok: false,
      status: "WIRED_NOT_PROVEN",
      action: "guard.enable",
      targetPlayers: false,
      whitelist: bot.guard.options.whitelist,
    };
  }
  return {
    ok: false,
    status: "WIRED_NOT_PROVEN",
    action: "guard.configured",
    enabled: false,
    targetPlayers: false,
    whitelist: bot.guard.options.whitelist,
  };
}

function enableAutoEatIfSafe(bot, opts = {}) {
  if (!bot) return { ok: false, status: "NOT_PROVEN", reason: "NO_BOT" };
  const vendor = loadVendor();
  if (!bot.autoEat && vendor.autoEat) {
    try { bot.loadPlugin(vendor.autoEat); } catch (e) {
      return { ok: false, status: "NOT_PROVEN", reason: "AUTOEAT_LOAD_FAIL:" + String(e && e.message || e) };
    }
  }
  if (!bot.autoEat) return { ok: false, status: "NOT_PROVEN", reason: "NO_AUTOEAT_PLUGIN" };
  // Safe defaults: no banned grief foods; startAt conservative.
  if (bot.autoEat.options) {
    bot.autoEat.options.startAt = opts.startAt != null ? opts.startAt : 14;
    bot.autoEat.options.minHealth = opts.minHealth != null ? opts.minHealth : 4;
    const banned = new Set([...(bot.autoEat.options.bannedFood || []), "pufferfish", "spider_eye", "rotten_flesh"]);
    bot.autoEat.options.bannedFood = Array.from(banned);
  }
  if (opts.enable === false) {
    try { bot.autoEat.disable(); } catch (e) {}
    return { ok: false, status: "WIRED_NOT_PROVEN", action: "autoEat.disabled" };
  }
  try {
    bot.autoEat.enable();
    return { ok: false, status: "WIRED_NOT_PROVEN", action: "autoEat.enable", startAt: bot.autoEat.options && bot.autoEat.options.startAt };
  } catch (e) {
    return { ok: false, status: "NOT_PROVEN", reason: String(e && e.message || e) };
  }
}

function attackHostileOnly(bot, entity) {
  if (!entity) return { ok: false, status: "NOT_PROVEN", reason: "NO_ENTITY" };
  const name = String(entity.username || entity.name || entity.type || "").toLowerCase().replace(/^minecraft:/, "");
  // NEG first: never attack players / Matt even if combat plugin missing.
  if (entity.type === "player" || PLAYER_DENY.has(name) || isMattName(name)) {
    return { ok: false, status: "DENIED", reason: "NO_FRIENDLY_FIRE_OR_PVP", neg: "NEG-minecraft-companion-fake-kills-builds-grief-or-pvp-matt-v1" };
  }
  if (!bot || !bot.attack) return { ok: false, status: "NOT_PROVEN", reason: "NO_ATTACK" };
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
 * On spawn (or alreadySpawned): configure follow + hostile guard + autoEat.
 * Returns honest statuses — never emits FOLLOW_OK / COMBAT_OK / GUARD_OK.
 */
function enableStayCompanion(bot, opts = {}) {
  assertBotIdentity(opts.username || KEVIN_TAG);
  if (!bot) return { ok: false, status: "NOT_PROVEN", reason: "NO_BOT" };
  attachCompanionDefaults(bot, Object.assign({}, opts, { loadAutoEat: opts.enableAutoEat === true || opts.loadAutoEat === true }));
  const follow = followMatt(bot, opts);
  const guard = enableHostileGuard(bot, Object.assign({}, opts, { enable: opts.enableGuard !== false }));
  const eat = enableAutoEatIfSafe(bot, Object.assign({}, opts, { enable: opts.enableAutoEat !== false }));
  return {
    ok: false,
    status: "WIRED_NOT_PROVEN",
    action: "enableStayCompanion",
    identity: KEVIN_TAG,
    follow,
    guard,
    autoEat: eat,
    claims: {
      FOLLOW_OK: false,
      COMBAT_OK: false,
      GUARD_OK: false,
      EAT_OK: false,
      JOIN_COMPAT_OK: false,
    },
    note: "Do not claim FOLLOW/COMBAT/GUARD live until spawn+entity receipts prove.",
  };
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
    assertBotIdentity(sourceName || KEVIN_TAG);
    client.queue("text", {
      type: "chat",
      needs_translation: false,
      source_name: sourceName || "kevinsk8erkid",
      xuid: "",
      platform_chat_id: "",
      filtered_message: "",
      message: String(message || ""),
      category: "authored",
      has_filtered_message: false,
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
  // NOT live-proven on Realms NetherNet. Caller must already NEG-filter entity.
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
  crudeChaseMatt,
  startAuthChaseLoop: rawAuth.startAuthChaseLoop,
  ensureSerializer: rawAuth.ensureSerializer,
  syncSelfFromStartGame: rawAuth.syncSelfFromStartGame,
  enableHostileGuard,
  enableAutoEatIfSafe,
  enableStayCompanion,
  attackHostileOnly,
  queueChat,
  queueAttackRuntime,
};


