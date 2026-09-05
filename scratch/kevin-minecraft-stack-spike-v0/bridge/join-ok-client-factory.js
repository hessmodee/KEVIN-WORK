"use strict";
/**
 * Thin adapter: obtain a JOIN_OK-style Realms client using the gym's installed
 * bedrock-protocol (read-only require) WITHOUT mutating gym package-lock.
 *
 * Default: DO NOT auto-connect from spike. Export helpers + document env.
 * Live prove still uses scratch/kevin-minecraft-bedrock-v0/rejoin.cmd.
 */
const fs = require("fs");
const path = require("path");
const { GYM_ROOT, KEVIN_TAG, assertBotIdentity } = require("./paths");

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
 * Resolve bedrock-protocol from gym node_modules if present, else vendor.
 * Does not install anything.
 */
function resolveBedrockProtocol() {
  const gymNm = path.join(GYM_ROOT, "node_modules", "bedrock-protocol");
  if (fs.existsSync(gymNm)) {
    return require(gymNm);
  }
  const { VENDOR_MAIN } = require("./paths");
  return require(require.resolve("bedrock-protocol", { paths: [VENDOR_MAIN] }));
}

/**
 * Build createClient options matching JOIN_OK realms-join.js (no connect).
 */
function realmsClientOptions(overrides = {}) {
  const username = assertBotIdentity(overrides.username || KEVIN_TAG);
  const CACHE = process.env.KEVIN_MC_AUTH_CACHE
    || path.resolve(GYM_ROOT, "..", "..", "credentials", "kevin-minecraft");
  const REALM_PICK = process.env.KEVIN_REALM_NAME_HINT || "HESSMODEE";
  const VERSION = process.env.KEVIN_MC_VERSION || "1.26.45";
  return {
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
    ...overrides,
    username, // re-assert after spread
  };
}

/**
 * Create Realms client (LIVE side effect). Guarded by env KEVIN_SPIKE_ALLOW_LIVE_JOIN=1.
 * Prefer gym rejoin.cmd for play; this is for bridge integration experiments only.
 */
function createJoinOkClient(overrides = {}) {
  if (!/^(1|true|yes)$/i.test(String(process.env.KEVIN_SPIKE_ALLOW_LIVE_JOIN || ""))) {
    throw new Error("LIVE_JOIN_BLOCKED_SET_KEVIN_SPIKE_ALLOW_LIVE_JOIN");
  }
  const bedrock = resolveBedrockProtocol();
  return bedrock.createClient(realmsClientOptions(overrides));
}

module.exports = {
  gymPackageLockPath,
  hashNote,
  resolveBedrockProtocol,
  realmsClientOptions,
  createJoinOkClient,
};
