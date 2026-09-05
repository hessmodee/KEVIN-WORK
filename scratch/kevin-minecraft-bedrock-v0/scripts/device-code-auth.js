#!/usr/bin/env node
"use strict";
const path = require("path");
const fs = require("fs");
const GAMERTAG = "kevinsk8erkid";
const CACHE = process.env.KEVIN_MC_AUTH_CACHE || path.resolve(__dirname, "..", "..", "..", "credentials", "kevin-minecraft");
function fail(code, msg) { console.error(msg); process.exit(code); }
let Authflow, Titles;
try {
  ({ Authflow, Titles } = require("prismarine-auth"));
} catch (e) { fail(2, "MISSING_DEPS"); }
if (!fs.existsSync(CACHE)) {
  try { fs.mkdirSync(CACHE, { recursive: true }); } catch (e) { fail(3, "CACHE_DIR_CREATE_FAILED"); }
}
function onMsaCode(data) {
  console.log("READY_FOR_OWNER_DEVICE_CODE");
  console.log("DEVICE_CODE_URL:", data && (data.verification_uri || data.verificationUri || "https://www.microsoft.com/link"));
  console.log("DEVICE_USER_CODE:", data && (data.user_code || data.userCode));
  if (data && data.message) console.log("DEVICE_MESSAGE:", data.message);
  console.log("OWNER_ACTION: Open DEVICE_CODE_URL, sign in as kevinsk8erkid ONLY (never hessmodee), enter DEVICE_USER_CODE.");
}
console.log("[auth] gamertag target:", GAMERTAG);
console.log("[auth] profilesFolder:", CACHE);
console.log("[auth] NEVER use hessmodee credentials");
console.log("READY_FOR_OWNER_DEVICE_CODE");
const flow = new Authflow(
  GAMERTAG,
  CACHE,
  { flow: "live", authTitle: Titles.MinecraftNintendoSwitch, deviceType: "Nintendo" },
  onMsaCode
);
(async () => {
  try {
    const xbl = await flow.getXboxToken();
    if (!xbl || !xbl.XSTSToken) fail(4, "FAIL_CLOSED_NO_TOKEN");
    try {
      await flow.getMinecraftBedrockServicesToken({ version: "1.21.0" });
    } catch (e) {
      console.log("[auth] bedrock services token optional warn:", e && e.message ? e.message : e);
    }
    console.log("AUTH_CACHE_OK");
    console.log("[auth] cache warmed for kevinsk8erkid (secrets not printed)");
    console.log("NEXT: node scripts/realms-join.js");
    process.exit(0);
  } catch (e) {
    const msg = String(e && e.message ? e.message : e);
    console.error("[auth] error:", msg);
    fail(6, "FAIL_CLOSED_AUTH");
  }
})();
