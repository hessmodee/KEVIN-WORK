#!/usr/bin/env node
"use strict";
const path = require("path");
const fs = require("fs");
const GAMERTAG = "kevinsk8erkid";
const CACHE = process.env.KEVIN_MC_AUTH_CACHE || path.resolve(__dirname, "..", "..", "..", "credentials", "kevin-minecraft");
const REALM_PICK = process.env.KEVIN_REALM_NAME_HINT || "HESSMODEE";
const TIMEOUT_MS = Number(process.env.KEVIN_REALMS_JOIN_TIMEOUT_MS || 60000);
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
console.log("[realms] gamertag:", GAMERTAG);
console.log("[realms] profilesFolder:", CACHE);
console.log("[realms] pick hint:", REALM_PICK);
console.log("[realms] never hessmodee creds");
let settled = false; let client;
const timer = setTimeout(function () {
  if (settled) return; settled = true;
  try { if (client && client.close) client.close(); } catch (e) {}
  console.error("REALMS_JOIN_TIMEOUT");
  console.error("Possible NETHERNET_GATE (Realms 26.10+ JSON-RPC). See PrismarineJS bedrock-protocol #717.");
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
try {
  client = bedrock.createClient({
    username: GAMERTAG,
    profilesFolder: CACHE,
    skipPing: true,
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
  try {
    client.queue("text", {
      type: "chat", needs_translation: false, source_name: GAMERTAG, xuid: "",
      platform_chat_id: "", filtered_message: "", message: "KEVIN_REALMS_JOIN_OK"
    });
  } catch (e) { console.log("[realms] chat send skipped"); }
  console.log("KEVIN_REALMS_JOIN_OK");
  setTimeout(function () { try { client.close(); } catch (e) {} process.exit(0); }, 2000);
});
client.on("kick", function (p) {
  console.error("[realms] kick", p);
  if (!settled) {
    settled = true; clearTimeout(timer);
    const s = JSON.stringify(p || {});
    if (/nether|jsonrpc/i.test(s)) fail(5, "NETHERNET_GATE");
    fail(7, "KICKED");
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
