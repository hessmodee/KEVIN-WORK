#!/usr/bin/env node
"use strict";
const path = require("path");
const fs = require("fs");
const GAMERTAG = "kevinsk8erkid";
const CACHE = process.env.KEVIN_MC_AUTH_CACHE || path.resolve(__dirname, "..", "..", "..", "credentials", "kevin-minecraft");
const REALM_PICK = process.env.KEVIN_REALM_NAME_HINT || "HESSMODEE";
const TIMEOUT_MS = Number(process.env.KEVIN_REALMS_JOIN_TIMEOUT_MS || 180000);
const VERSION = process.env.KEVIN_MC_VERSION || "1.26.45";
const CONNECT_TIMEOUT = Number(process.env.KEVIN_MC_CONNECT_TIMEOUT || 120000);
const STAY = /^(1|true|yes)$/i.test(String(process.env.KEVIN_REALMS_STAY || ""));
const HI = /^(1|true|yes)$/i.test(String(process.env.KEVIN_REALMS_CHAT_HI || ""));
function fail(code, msg) { console.error(msg); process.exit(code); }
function cacheLooksWarm(dir) {
  if (!fs.existsSync(dir)) return false;
  try {
    const names = fs.readdirSync(dir).filter((n) => n !== "README.md" && n !== ".gitignore" && !n.startsWith("."));
    return names.length > 0;
  } catch (e) { return false; }
}
let bedrock;
try { bedrock = require("bedrock-protocol"); require("prismarine-auth"); } catch (e) { fail(2, "MISSING_DEPS"); }
if (!cacheLooksWarm(CACHE)) {
  console.error("FAIL_CLOSED_NO_TOKEN");
  console.error("profilesFolder empty:", CACHE);
  console.error("Next: node scripts/device-code-auth.js");
  fail(3, "READY_FOR_OWNER_DEVICE_CODE");
}
const bpRoot = path.dirname(require.resolve("bedrock-protocol"));
const hasNethernet = fs.existsSync(path.join(bpRoot, "src", "nethernet.js"));
console.log("[realms] gamertag:", GAMERTAG);
console.log("[realms] profilesFolder:", CACHE);
console.log("[realms] pick hint:", REALM_PICK);
console.log("[realms] version:", VERSION);
console.log("[realms] connectTimeout:", CONNECT_TIMEOUT);
console.log("[realms] stay:", STAY);
console.log("[realms] nethernet src:", hasNethernet ? "OK" : "MISSING (need #nethernet branch)");
console.log("[realms] never hessmodee creds");
if (!hasNethernet) {
  console.error("NETHERNET_SRC_MISSING");
  fail(5, "NETHERNET_GATE");
}
let settled = false; let client;
const timer = setTimeout(function () {
  if (settled) return; settled = true;
  try { if (client && client.close) client.close(); } catch (e) {}
  console.error("REALMS_JOIN_TIMEOUT");
  console.error("Possible NETHERNET_GATE (Realms 26.10+ JSON-RPC). See PrismarineJS bedrock-protocol #717 / PR #735.");
  process.exit(4);
}, TIMEOUT_MS);
function pickRealm(realms) {
  if (!Array.isArray(realms) || realms.length === 0) {
    throw new Error("NO_REALMS_VISIBLE");
  }
  const hint = REALM_PICK.toLowerCase();
  const hit = realms.find((r) => {
    const name = String(r.name || r.remoteSubscriptionId || "").toLowerCase();
    return name.includes(hint) || name.includes("hessmodee");
  });
  const chosen = hit || realms[0];
  console.log("[realms] chosen:", chosen && chosen.name ? chosen.name : "(unnamed)");
  return chosen;
}
function sendChat(message) {
  try {
    client.queue("text", {
      type: "chat", needs_translation: false, source_name: GAMERTAG, xuid: "",
      platform_chat_id: "", filtered_message: "", message: message
    });
  } catch (e) { console.log("[realms] chat send skipped"); }
}
try {
  client = bedrock.createClient({
    username: GAMERTAG,
    profilesFolder: CACHE,
    version: VERSION,
    skipPing: true,
    connectTimeout: CONNECT_TIMEOUT,
    conLog: console.log,
    onMsaCode: function (data) {
      console.log("READY_FOR_OWNER_DEVICE_CODE");
      console.log("DEVICE_CODE_URL:", data && (data.verification_uri || data.verificationUri || "https://www.microsoft.com/link"));
      console.log("DEVICE_USER_CODE:", data && (data.user_code || data.userCode));
    },
    realms: { pickRealm: pickRealm }
  });
} catch (e) {
  clearTimeout(timer);
  const msg = String(e && e.message ? e.message : e);
  console.error("[realms] createClient error:", msg);
  if (/nether|jsonrpc|signalling|guid/i.test(msg)) fail(5, "NETHERNET_GATE");
  if (/auth|token|msa|xbox/i.test(msg)) fail(3, "READY_FOR_OWNER_DEVICE_CODE");
  fail(6, "FAIL_CLOSED_CREATE");
}
client.on("join", function () { console.log("[realms] join"); });
client.on("spawn", function () {
  if (settled) return; settled = true; clearTimeout(timer);
  console.log("[realms] spawn (bed at house expected)");
  sendChat("KEVIN_REALMS_JOIN_OK");
  console.log("KEVIN_REALMS_JOIN_OK");
  if (HI) {
    setTimeout(function () { sendChat("hi matt"); console.log("[realms] chat hi sent"); }, 500);
  }
  if (STAY) {
    console.log("[realms] STAY=1 play loop: wait bed -> follow Matt -> chat -> invited build");
    return;
  }
  setTimeout(function () { try { client.close(); } catch (e) {} process.exit(0); }, 2000);
});
client.on("kick", function (p) {
  console.error("[realms] kick", p);
  if (!settled) {
    settled = true; clearTimeout(timer);
    const s = JSON.stringify(p || {});
    if (/nether|jsonrpc/i.test(s)) fail(5, "NETHERNET_GATE");
    fail(7, "KICKED");
  } else {
    console.error("KICKED_AFTER_JOIN");
    try { client.close(); } catch (e) {}
    process.exit(7);
  }
});
client.on("error", function (err) {
  const msg = err && err.message ? err.message : String(err);
  console.error("[realms] err", msg);
  if (/nether|jsonrpc|signalling/i.test(msg) && !settled) {
    settled = true; clearTimeout(timer); fail(5, "NETHERNET_GATE");
  }
});
client.on("close", function () { if (!settled) console.log("[realms] close"); });
setInterval(function () {
  if (settled && !STAY) return;
  const opts = client.options || {};
  console.log("[realms] status", {
    transport: opts.transport,
    networkId: opts.networkId && String(opts.networkId).slice(0, 80),
    signalProto: opts._signallingProtocol,
    signalHost: opts._signallingHost,
    skipPing: opts.skipPing,
    stay: STAY
  });
}, 5000);
