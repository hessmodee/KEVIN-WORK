"use strict";
/**
 * Thin adapter: obtain a JOIN_OK-style Realms client using the gym's installed
 * bedrock-protocol (NetherNet overlay + protocol 2169) WITHOUT mutating gym package-lock.
 *
 * Live connect gated by KEVIN_SPIKE_ALLOW_LIVE_JOIN=1.
 * Prefer gym rejoin.cmd / spike rejoin-companion.cmd for play.
 */
const fs = require("fs");
const path = require("path");
const { EventEmitter } = require("events");
const { GYM_ROOT, KEVIN_TAG, assertBotIdentity, VENDOR_MAIN } = require("./paths");

function gymPackageLockPath() {
  return path.join(GYM_ROOT, "package-lock.json");
}

function hashNote() {
  return {
    gymRoot: GYM_ROOT,
    lockPath: gymPackageLockPath(),
    lockExists: fs.existsSync(gymPackageLockPath()),
    policy: "NEVER mutate JOIN_OK package-lock from spike bridge",
  };
}

/**
 * Resolve bedrock-protocol from gym node_modules (NetherNet overlay) if present, else vendor.
 * Does not install anything.
 */
function resolveBedrockProtocol() {
  const gymNm = path.join(GYM_ROOT, "node_modules", "bedrock-protocol");
  if (fs.existsSync(gymNm)) {
    return require(gymNm);
  }
  return require(require.resolve("bedrock-protocol", { paths: [VENDOR_MAIN] }));
}

function gymBedrockProtocolRoot() {
  const gymNm = path.join(GYM_ROOT, "node_modules", "bedrock-protocol");
  if (fs.existsSync(gymNm)) return gymNm;
  try {
    return path.dirname(require.resolve("bedrock-protocol", { paths: [VENDOR_MAIN] }));
  } catch (e) {
    return null;
  }
}

function assertNethernetReady() {
  const root = gymBedrockProtocolRoot();
  if (!root) throw new Error("BEDROCK_PROTOCOL_MISSING");
  const nethernet = path.join(root, "src", "nethernet.js");
  if (!fs.existsSync(nethernet)) {
    throw new Error("NETHERNET_SRC_MISSING_NEED_GYM_OVERLAY");
  }
  return { root, nethernet, ok: true };
}

/**
 * Build createClient options matching JOIN_OK realms-join.js (no connect).
 * Protocol path: NetherNet Realms + version 1.26.45 / 2169.
 */
function realmsClientOptions(overrides = {}) {
  const username = assertBotIdentity(overrides.username || KEVIN_TAG);
  const CACHE = process.env.KEVIN_MC_AUTH_CACHE
    || path.resolve(GYM_ROOT, "..", "..", "credentials", "kevin-minecraft");
  const REALM_PICK = process.env.KEVIN_REALM_NAME_HINT || "HESSMODEE";
  const VERSION = process.env.KEVIN_MC_VERSION || "1.26.45";
  const base = {
    username,
    profilesFolder: CACHE,
    version: VERSION,
    skipPing: true,
    connectTimeout: Number(process.env.KEVIN_MC_CONNECT_TIMEOUT || 120000),
    realms: {
      pickRealm(realms) {
        if (!Array.isArray(realms) || realms.length === 0) throw new Error("NO_REALMS_VISIBLE");
        const hint = REALM_PICK.toLowerCase();
        const hit = realms.find((r) => {
          const name = String(r.name || r.remoteSubscriptionId || "").toLowerCase();
          return name.includes(hint) || name.includes("hessmodee");
        });
        return hit || realms[0];
      },
    },
  };
  const merged = Object.assign({}, base, overrides);
  merged.username = assertBotIdentity(merged.username || username);
  if (merged.realms == null) merged.realms = base.realms;
  return merged;
}

function cacheLooksWarm(dir) {
  if (!fs.existsSync(dir)) return false;
  try {
    const names = fs.readdirSync(dir).filter((n) => n !== "README.md" && n !== ".gitignore" && !n.startsWith("."));
    return names.length > 0;
  } catch (e) {
    return false;
  }
}

/**
 * Create Realms client (LIVE side effect). Guarded by env KEVIN_SPIKE_ALLOW_LIVE_JOIN=1.
 * Uses gym NetherNet overlay createClient (same as JOIN_OK realms-join.js).
 */
function createJoinOkClient(overrides = {}) {
  if (!/^(1|true|yes)$/i.test(String(process.env.KEVIN_SPIKE_ALLOW_LIVE_JOIN || ""))) {
    throw new Error("LIVE_JOIN_BLOCKED_SET_KEVIN_SPIKE_ALLOW_LIVE_JOIN");
  }
  assertBotIdentity(overrides.username || KEVIN_TAG);
  assertNethernetReady();
  const opts = realmsClientOptions(overrides);
  if (!cacheLooksWarm(opts.profilesFolder)) {
    const err = new Error("FAIL_CLOSED_NO_TOKEN");
    err.code = "READY_FOR_OWNER_DEVICE_CODE";
    throw err;
  }
  const bedrock = resolveBedrockProtocol();
  return bedrock.createClient(opts);
}

/**
 * Promise that resolves when client emits spawn (or start_game), rejects on error/timeout.
 * Used by rejoin-companion stay path.
 */
function waitForClientSpawn(client, timeoutMs) {
  const ms = timeoutMs != null ? timeoutMs : Number(process.env.KEVIN_REALMS_JOIN_TIMEOUT_MS || 180000);
  return new Promise((resolve, reject) => {
    if (!client) return reject(new Error("NO_CLIENT"));
    let settled = false;
    const timer = setTimeout(() => {
      if (settled) return;
      settled = true;
      cleanup();
      reject(new Error("REALMS_JOIN_TIMEOUT"));
    }, ms);
    function cleanup() {
      clearTimeout(timer);
      try { client.removeListener("spawn", onSpawn); } catch (e) {}
      try { client.removeListener("start_game", onStartGame); } catch (e) {}
      try { client.removeListener("error", onError); } catch (e) {}
      try { client.removeListener("kick", onKick); } catch (e) {}
      try { client.removeListener("close", onClose); } catch (e) {}
    }
    function onSpawn() {
      if (settled) return;
      settled = true;
      cleanup();
      resolve({ event: "spawn", client });
    }
    function onStartGame(pkt) {
      try { client.startGameData = pkt || client.startGameData; } catch (e) {}
      // Some stacks spawn after start_game; wait for spawn unless already entity-bound.
      if (client.entity) onSpawn();
    }
    function onError(err) {
      if (settled) return;
      settled = true;
      cleanup();
      reject(err || new Error("CLIENT_ERROR"));
    }
    function onKick(reason) {
      if (settled) return;
      settled = true;
      cleanup();
      reject(new Error("KICKED:" + String(reason || "").slice(0, 160)));
    }
    function onClose() {
      if (settled) return;
      settled = true;
      cleanup();
      reject(new Error("CLIENT_CLOSED_BEFORE_SPAWN"));
    }
    client.on("spawn", onSpawn);
    client.on("start_game", onStartGame);
    client.on("error", onError);
    client.on("kick", onKick);
    client.on("close", onClose);
    if (client.entity || client.startGameData) {
      process.nextTick(onSpawn);
    }
  });
}

/**
 * Fake client for unit tests only (EventEmitter + queue). Not a Realms connection.
 */
function createFakeJoinOkClient(overrides = {}) {
  const fake = new EventEmitter();
  fake.queue = function fakeQueue() { return Promise.resolve(); };
  fake.startGameData = overrides.startGameData || {
    runtime_entity_id: 1,
    entity_id: 1,
    player_position: { x: 0, y: 64, z: 0 },
    rotation: { x: 0, z: 0 },
    player_gamemode: 0,
    dimension: "overworld",
    difficulty: 1,
    engine: "1.26.45",
    world_name: "fake-unit",
    spawn_position: { x: 0, y: 64, z: 0 },
  };
  fake.entity = overrides.entity || {
    position: { x: 0, y: 64, z: 0 },
    yaw: 0,
    pitch: 0,
    runtime_id: 1,
  };
  fake.close = function () { fake.emit("close"); };
  return fake;
}

module.exports = {
  gymPackageLockPath,
  hashNote,
  resolveBedrockProtocol,
  gymBedrockProtocolRoot,
  assertNethernetReady,
  realmsClientOptions,
  cacheLooksWarm,
  createJoinOkClient,
  waitForClientSpawn,
  createFakeJoinOkClient,
};
