#!/usr/bin/env node
"use strict";
/**
 * Last-resort MSAL device-code (Azure public client).
 * Uses login.microsoftonline.com device login — avoids live.com oauth20_remoteconnect.
 * Does NOT do full Xbox title auth; Realms/Bedrock may still reject. Prefer device-code-auth.js.
 * Default clientId = prismarine-auth Constants msalConfig (Office365APIEditor public id) unless
 * KEVIN_MSAL_CLIENT_ID is set to a Matt-owned Azure public client with XboxLive.signin.
 */
const path = require("path");
const fs = require("fs");
const GAMERTAG = "kevinsk8erkid";
const CACHE = process.env.KEVIN_MC_AUTH_CACHE || path.resolve(__dirname, "..", "..", "..", "credentials", "kevin-minecraft");
const READY_MD = path.resolve(__dirname, "..", "READY_FOR_OWNER_AUTH.md");
const CLIENT_ID = process.env.KEVIN_MSAL_CLIENT_ID || "389b1b32-b5d5-43b2-bddc-84ce938d6737";
function fail(code, msg) { console.error(msg); process.exit(code); }
let Authflow;
try { ({ Authflow } = require("prismarine-auth")); } catch (e) { fail(2, "MISSING_DEPS"); }
if (!fs.existsSync(CACHE)) fs.mkdirSync(CACHE, { recursive: true });

function onMsaCode(data) {
  const uri = (data && (data.verificationUri || data.verification_uri)) || "https://login.microsoftonline.com/common/oauth2/deviceauth";
  const code = data && (data.userCode || data.user_code);
  const md = [
    "# READY_FOR_OWNER_AUTH (msal last-resort)",
    "",
    "Method: flow=msal authTitle=" + CLIENT_ID,
    "NOTE: Weaker than Nintendo Switch live title auth. Prefer device-code-auth.js.",
    "",
    "1. Open: " + uri,
    "2. Sign in as **kevinsk8erkid** only",
    "3. Enter code: `" + code + "`",
    ""
  ].join("\n");
  fs.writeFileSync(READY_MD, md, "utf8");
  console.log("READY_FOR_OWNER_DEVICE_CODE");
  console.log("DEVICE_CODE_URL:", uri);
  console.log("DEVICE_USER_CODE:", code);
  console.log("OWNER_ACTION: Sign in as kevinsk8erkid at DEVICE_CODE_URL");
}

console.log("[msal-auth] LAST RESORT | client:", CLIENT_ID);
console.log("[msal-auth] Prefer: node scripts/device-code-auth.js");
const flow = new Authflow(
  GAMERTAG,
  CACHE,
  { flow: "msal", authTitle: CLIENT_ID },
  onMsaCode
);
(async () => {
  try {
    const xbl = await flow.getXboxToken();
    if (!xbl || !xbl.XSTSToken) fail(4, "FAIL_CLOSED_NO_TOKEN");
    console.log("AUTH_CACHE_OK");
    console.log("WARN: MSAL path may lack Bedrock title tokens; join may still fail.");
    console.log("NEXT: node scripts/realms-join.js");
    process.exit(0);
  } catch (e) {
    console.error("[msal-auth] error:", e && e.message ? e.message : e);
    fail(6, "FAIL_CLOSED_AUTH");
  }
})();
