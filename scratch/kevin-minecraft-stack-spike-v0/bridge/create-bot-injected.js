"use strict";
/**
 * Inject an already-created bedrock-protocol client (JOIN_OK NetherNet Realms,
 * protocol 2169 / 1.26.45) into bedrockflayer createBot WITHOUT host/port createClient.
 *
 * Does NOT mutate JOIN_OK package-lock. Vendor is spike-local only.
 * Live join-compat NOT proven until spawn+plugins wired on Realms client with receipts.
 */
const { VENDOR_MAIN, assertBotIdentity, KEVIN_TAG } = require("./paths");

function loadVendor() {
  try {
    return require(VENDOR_MAIN);
  } catch (err) {
    const msg = err && err.message ? err.message : String(err);
    throw new Error("SPIKE_VENDOR_REQUIRE_FAIL: " + msg + " (run install-deps.cmd)");
  }
}

/**
 * @param {object} client - bedrock-protocol client from JOIN_OK realms-join / createJoinOkClient
 * @param {object} [options]
 * @returns {object} BedrockBot
 */
function createBotFromClient(client, options = {}) {
  if (!client) throw new Error("INJECT_CLIENT_REQUIRED");
  const username = assertBotIdentity(options.username || KEVIN_TAG);
  const vendor = loadVendor();
  const bedrock = require(require.resolve("bedrock-protocol", { paths: [VENDOR_MAIN] }));
  const origCreateClient = bedrock.createClient;
  let restored = false;
  const restore = () => {
    if (!restored) {
      bedrock.createClient = origCreateClient;
      restored = true;
    }
  };
  bedrock.createClient = function injectCreateClient() {
    restore();
    return client;
  };
  let bot;
  try {
    bot = vendor.createBot({
      host: "nethernet-injected",
      port: 0,
      username,
      version: options.version || process.env.KEVIN_MC_VERSION || "1.26.45",
      offline: false,
      skipPing: true,
      physicsEnabled: options.physicsEnabled === true, // default false for Realms soft-violation
      logErrors: options.logErrors !== false,
      hideErrors: !!options.hideErrors,
      conLog: options.conLog,
      loadInternalPlugins: options.loadInternalPlugins !== false,
    });
  } finally {
    restore();
  }

  const alreadySpawned = !!(options.alreadySpawned || client.entity || client.startGameData);
  if (alreadySpawned) {
    process.nextTick(() => {
      try {
        if (client.startGameData && typeof bot._onStartGame === "function") {
          bot._onStartGame(client.startGameData);
        }
        bot.emit("connect");
        bot.emit("spawn");
      } catch (e) {
        bot.emit("error", e);
      }
    });
  }

  bot._kevinInjected = true;
  bot._kevinBridge = "createBotFromClient";
  bot._kevinClient = client;
  return bot;
}

/**
 * Convenience: live JOIN_OK createClient (gym NetherNet) then inject.
 * Requires KEVIN_SPIKE_ALLOW_LIVE_JOIN=1. Does not wait for spawn — caller should.
 */
function createBotFromJoinOkClient(overrides = {}, botOptions = {}) {
  const { createJoinOkClient } = require("./join-ok-client-factory");
  const client = createJoinOkClient(overrides);
  return { client, bot: createBotFromClient(client, botOptions) };
}

/**
 * Optional: load guard + autoEat plugins + Matt whitelist defaults (hostile-only).
 * Does not enable guard/autoEat unless opts say so. Not live-proven.
 */
function attachCompanionDefaults(bot, opts = {}) {
  const vendor = loadVendor();
  if (!bot.guard && vendor.guard) {
    bot.loadPlugin(vendor.guard);
  }
  if (!bot.autoEat && vendor.autoEat && opts.loadAutoEat === true) {
    try {
      bot.loadPlugin(vendor.autoEat);
    } catch (e) {
      // soft — autoEat optional
    }
  }
  if (bot.guard && bot.guard.options) {
    bot.guard.options.targetPlayers = false;
    const wl = new Set([...(bot.guard.options.whitelist || []), "hessmodee", "HESSMODEE"]);
    if (opts.extraWhitelist) opts.extraWhitelist.forEach((n) => wl.add(String(n)));
    bot.guard.options.whitelist = Array.from(wl);
  }
  return bot;
}

module.exports = {
  createBotFromClient,
  createBotFromJoinOkClient,
  attachCompanionDefaults,
  loadVendor,
};

