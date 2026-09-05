#!/usr/bin/env node
"use strict";
/**
 * Bedrock device-code auth for kevinsk8erkid.
 * Client: Titles.MinecraftNintendoSwitch (00000000441cc96b) + live flow + Nintendo.
 * CRITICAL: Never open microsoft.com/link?otc=CODE — that hits oauth20_remoteconnect
 * and fails with first-party consent error. Open plain https://www.microsoft.com/link
 * and TYPE the code.
 */
const path = require("path");
const fs = require("fs");
const GAMERTAG = "kevinsk8erkid";
const CACHE = process.env.KEVIN_MC_AUTH_CACHE || path.resolve(__dirname, "..", "..", "..", "credentials", "kevin-minecraft");
const READY_MD = path.resolve(__dirname, "..", "READY_FOR_OWNER_AUTH.md");
const READY_TXT = path.resolve(__dirname, "..", "READY_FOR_OWNER_DEVICE_CODE.txt");
function fail(code, msg) { console.error(msg); process.exit(code); }
let Authflow, Titles;
try {
  ({ Authflow, Titles } = require("prismarine-auth"));
} catch (e) { fail(2, "MISSING_DEPS"); }
if (!fs.existsSync(CACHE)) {
  try { fs.mkdirSync(CACHE, { recursive: true }); } catch (e) { fail(3, "CACHE_DIR_CREATE_FAILED"); }
}

function writeReady(userCode, verificationUri) {
  const uri = verificationUri || "https://www.microsoft.com/link";
  const code = userCode || "(waiting)";
  const md = [
    "# READY_FOR_OWNER_AUTH",
    "",
    "**Gamertag:** kevinsk8erkid ONLY (never hessmodee).",
    "**Method:** prismarine-auth live + Titles.MinecraftNintendoSwitch (`00000000441cc96b`) + deviceType Nintendo.",
    "",
    "## Do this now (phone or PC browser)",
    "",
    "1. Open **exactly**: https://www.microsoft.com/link",
    "2. Sign in as **kevinsk8erkid** (Microsoft account for that Xbox gamertag).",
    "3. Type this code **manually**: `" + code + "`",
    "4. Approve / continue until Microsoft says you are signed in.",
    "5. Leave this Node process running until it prints `AUTH_CACHE_OK`.",
    "",
    "## HARD NO (causes first-party failure)",
    "",
    "- Do **NOT** open `https://www.microsoft.com/link?otc=" + code + "` or any `?otc=` URL.",
    "- That path uses `login.live.com/oauth20_remoteconnect` and returns:",
    "  *\"application is a first party application, the user does not have consent...\"*",
    "- Do **NOT** use hessmodee.",
    "- Do **NOT** invent / paste a password into chat.",
    "",
    "## If code expired or \"That code didn't work\"",
    "",
    "1. Ctrl+C this process.",
    "2. Re-run: `node scripts/device-code-auth.js`",
    "3. Use the **new** code only (old codes die in ~15 min).",
    "",
    "## Alternates (same scratch)",
    "",
    "- `node scripts/sisu-auth.js` — same live device-code client, sisu Xbox path (try if live XBL resets).",
    "- `node scripts/msal-device-auth.js` — Azure MSAL device login (microsoftonline.com); weaker title tokens; last resort.",
    "",
    "## After AUTH_CACHE_OK",
    "",
    "`node scripts/realms-join.js` → expect `KEVIN_REALMS_JOIN_OK` or `NETHERNET_GATE`.",
    "",
    "verification_uri: " + uri,
    "user_code: " + code,
    ""
  ].join("\n");
  fs.writeFileSync(READY_MD, md, "utf8");
  const txt = [
    "READY_FOR_OWNER_DEVICE_CODE",
    "URL: https://www.microsoft.com/link",
    "CODE: " + code,
    "DO_NOT_USE_OTC_QUERY: never open link?otc= (first-party consent fail)",
    "Sign in as kevinsk8erkid ONLY (never hessmodee).",
    "Details: READY_FOR_OWNER_AUTH.md"
  ].join("\n");
  fs.writeFileSync(READY_TXT, txt, "utf8");
}

function onMsaCode(data) {
  const uri = data && (data.verification_uri || data.verificationUri) || "https://www.microsoft.com/link";
  const code = data && (data.user_code || data.userCode);
  writeReady(code, uri);
  console.log("READY_FOR_OWNER_DEVICE_CODE");
  console.log("DEVICE_CODE_URL: https://www.microsoft.com/link");
  console.log("DEVICE_USER_CODE:", code);
  console.log("HARD_NO: Do NOT open microsoft.com/link?otc=... (first-party consent error)");
  console.log("OWNER_ACTION: Open https://www.microsoft.com/link , sign in as kevinsk8erkid, TYPE the code.");
  console.log("WROTE:", READY_MD);
  if (data && data.message) console.log("DEVICE_MESSAGE:", data.message);
}

console.log("[auth] gamertag target:", GAMERTAG);
console.log("[auth] profilesFolder:", CACHE);
console.log("[auth] client: Titles.MinecraftNintendoSwitch + live + Nintendo");
console.log("[auth] NEVER use hessmodee credentials");
writeReady("(pending)", "https://www.microsoft.com/link");
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
    if (/ECONNRESET|ETIMEDOUT|fetch/i.test(msg)) {
      console.error("HINT: Network blip during Xbox Live. Re-run device-code-auth.js with a fresh code.");
    }
    fail(6, "FAIL_CLOSED_AUTH");
  }
})();
