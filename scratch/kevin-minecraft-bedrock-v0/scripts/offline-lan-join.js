#!/usr/bin/env node
"use strict";
const HOST = process.env.BEDROCK_HOST || "127.0.0.1";
const PORT = Number(process.env.BEDROCK_PORT || 19132);
const USERNAME = process.env.BEDROCK_OFFLINE_NAME || "KevinOfflineV0";
const TIMEOUT_MS = Number(process.env.BEDROCK_JOIN_TIMEOUT_MS || 15000);
function fail(code, msg) { console.error(msg); process.exit(code); }
let mod;
try { mod = require("bedrock-protocol"); } catch (e) { fail(2, "MISSING_DEPS"); }
console.log("[v0] probe " + HOST + ":" + PORT + " offline");
let settled = false; let client;
const timer = setTimeout(function () {
  if (settled) return; settled = true;
  try { if (client && client.close) client.close(); } catch (e) {}
  console.error("READY_FOR_BDS");
  process.exit(3);
}, TIMEOUT_MS);
try {
  client = mod.createClient({ host: HOST, port: PORT, username: USERNAME, offline: true, skipPing: true });
} catch (e) {
  clearTimeout(timer);
  fail(4, String(e && e.message ? e.message : e));
}
client.on("join", function () { console.log("[v0] join"); });
client.on("spawn", function () {
  if (settled) return; settled = true; clearTimeout(timer);
  console.log("[v0] spawn");
  console.log("KEVIN_MC_BEDROCK_V0_OK");
  try { client.close(); } catch (e) {}
  process.exit(0);
});
client.on("kick", function (p) { console.error("[v0] kick", p); });
client.on("error", function (err) { console.error("[v0] err", err && err.message ? err.message : err); });
client.on("close", function () { if (!settled) console.log("[v0] close"); });
