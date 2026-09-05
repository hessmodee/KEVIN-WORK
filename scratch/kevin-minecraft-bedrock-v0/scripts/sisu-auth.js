#!/usr/bin/env node
"use strict";
/**
 * Alternate auth: live device-code client (Nintendo Switch title) + sisu Xbox path.
 * Same microsoft.com/link rules: TYPE code, never ?otc=.
 */
const path = require("path");
const fs = require("fs");
const GAMERTAG = "kevinsk8erkid";
const CACHE = process.env.KEVIN_MC_AUTH_CACHE || path.resolve(__dirname, "..", "..", "..", "credentials", "kevin-minecraft");
const READY_MD = path.resolve(__dirname, "..", "READY_FOR_OWNER_AUTH.md");
function fail(code, msg) { console.error(msg); process.exit(code); }
let Authflow, Titles;
try { ({ Authflow, Titles } = require("prismarine-auth")); } catch (e) { fail(2, "MISSING_DEPS"); }
if (!fs.existsSync(CACHE)) fs.mkdirSync(CACHE, { recursive: true });

function onMsaCode(data) {
  const code = data && (data.user_code || data.userCode);
  const md = [
    "# READY_FOR_OWNER_AUTH (sisu)",
    "",
    "Method: flow=sisu + Titles.MinecraftNintendoSwitch + deviceType Nintendo",
    "",
    "1. Open **exactly** https://www.microsoft.com/link (NO ?otc=)",
    "2. Sign in as **kevinsk8erkid** only",
    "3. Type code: `" + code + "`",
    "4. Wait for AUTH_CACHE_OK",
    ""
  ].join("\n");
  fs.writeFileSync(READY_MD, md, "utf8");
  console.log("READY_FOR_OWNER_DEVICE_CODE");
  console.log("DEVICE_CODE_URL: https://www.microsoft.com/link");
  console.log("DEVICE_USER_CODE:", code);
  console.log("HARD_NO: never use ?otc= URL");
}

console.log("[sisu-auth] kevinsk8erkid | cache:", CACHE);
const flow = new Authflow(
  GAMERTAG,
  CACHE,
  { flow: "sisu", authTitle: Titles.MinecraftNintendoSwitch, deviceType: "Nintendo" },
  onMsaCode
);
(async () => {
  try {
    const xbl = await flow.getXboxToken();
    if (!xbl || !xbl.XSTSToken) fail(4, "FAIL_CLOSED_NO_TOKEN");
    console.log("AUTH_CACHE_OK");
    console.log("NEXT: node scripts/realms-join.js");
    process.exit(0);
  } catch (e) {
    console.error("[sisu-auth] error:", e && e.message ? e.message : e);
    fail(6, "FAIL_CLOSED_AUTH");
  }
})();
