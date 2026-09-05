"use strict";
/**
 * Load Discord config from env only. Never invent tokens.
 * Prefer C:\Users\hessm\.openclaw\.env already loaded by host, or process.env.
 */
const fs = require("fs");
const path = require("path");

function loadDotEnvFile(filePath) {
  try {
    if (!fs.existsSync(filePath)) return;
    const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
    for (const line of lines) {
      const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
      if (!m) continue;
      const key = m[1];
      let val = m[2];
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      if (process.env[key] == null || process.env[key] === "") process.env[key] = val;
    }
  } catch (e) {
    // ignore
  }
}

function bootstrapEnv() {
  const candidates = [
    process.env.OPENCLAW_ENV_FILE,
    path.resolve("C:/Users/hessm/.openclaw/.env"),
    path.resolve(__dirname, "../../../.env"),
    path.resolve(__dirname, "../.env"),
  ].filter(Boolean);
  for (const c of candidates) loadDotEnvFile(c);
}

function csvIds(v) {
  return String(v || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

function getConfig() {
  bootstrapEnv();
  const token = process.env.DISCORD_BOT_TOKEN || "";
  const altPath = "C:/Users/hessm/.openclaw/credentials/kevin-discord/DISCORD_BOT_TOKEN";
  let tokenSource = token ? "env" : null;
  let resolved = token;
  if (!resolved && fs.existsSync(altPath)) {
    try {
      const raw = fs.readFileSync(altPath, "utf8").trim();
      if (raw.length > 10) {
        resolved = raw;
        tokenSource = "credentials-file";
      }
    } catch (e) {}
  }
  return {
    token: resolved,
    tokenPresent: !!(resolved && resolved.length > 10),
    tokenSource,
    guildId: process.env.DISCORD_GUILD_ID || "",
    textChannelId: process.env.DISCORD_TEXT_CHANNEL_ID || "",
    voiceAllowlist: csvIds(process.env.DISCORD_VOICE_CHANNEL_ALLOWLIST),
    ownerUserId: process.env.DISCORD_OWNER_USER_ID || "",
    prefix: process.env.KEVIN_DISCORD_PREFIX || "!k",
    sttBackend: process.env.KEVIN_STT_BACKEND || "stub",
    ttsBackend: process.env.KEVIN_TTS_BACKEND || "stub",
  };
}

function requireTokenOrExit() {
  const cfg = getConfig();
  if (!cfg.tokenPresent) {
    console.log("READY_FOR_OWNER_TOKEN");
    console.log("Place DISCORD_BOT_TOKEN in C:\\Users\\hessm\\.openclaw\\.env or credentials/kevin-discord/DISCORD_BOT_TOKEN");
    process.exit(2);
  }
  return cfg;
}

module.exports = { getConfig, requireTokenOrExit, bootstrapEnv };
