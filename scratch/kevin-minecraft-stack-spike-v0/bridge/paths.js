"use strict";
const fs = require("fs");
const path = require("path");
const SPIKE_ROOT = path.resolve(__dirname, "..");
const VENDOR_MAIN = process.env.KEVIN_MC_SPIKE_VENDOR || path.join(SPIKE_ROOT, "vendor", "mineflayer-for-bedrock-main");
function resolveGymRoot() {
  if (process.env.KEVIN_MC_BEDROCK_GYM) return process.env.KEVIN_MC_BEDROCK_GYM;
  const candidates = [
    // Prefer the real JOIN_OK gym on HESS-PC workspace (not worktree-local empty twin).
    "C:/Users/hessm/.openclaw/workspace/scratch/kevin-minecraft-bedrock-v0",
    path.resolve(SPIKE_ROOT, "..", "..", "..", "scratch", "kevin-minecraft-bedrock-v0"),
    path.resolve(SPIKE_ROOT, "..", "kevin-minecraft-bedrock-v0"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(path.join(c, "package.json")) && fs.existsSync(path.join(c, "package-lock.json"))) {
      return c;
    }
  }
  for (const c of candidates) {
    if (fs.existsSync(path.join(c, "package.json"))) return c;
  }
  return candidates[0];
}
const GYM_ROOT = resolveGymRoot();
const KEVIN_TAG = "kevinsk8erkid";
const MATT_TAGS = Object.freeze(["hessmodee", "HESSMODEE"]);
function assertBotIdentity(username) {
  const u = String(username || KEVIN_TAG);
  if (/^hessmodee$/i.test(u)) throw new Error("POLICY_NEVER_HESSMODEE_BOT_LOGIN");
  return u;
}
module.exports = { SPIKE_ROOT, VENDOR_MAIN, GYM_ROOT, KEVIN_TAG, MATT_TAGS, assertBotIdentity, resolveGymRoot };
