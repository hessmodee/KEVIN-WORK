"use strict";
const nodeParts = process.versions.node.split(".").map(Number);
if (nodeParts[0] < 22 || (nodeParts[0] === 22 && nodeParts[1] < 12)) {
  console.error("NODE_TOO_OLD need>=22.12 got=" + process.versions.node);
  process.exit(1);
}
const { Client, GatewayIntentBits } = require("discord.js");
const voice = require("@discordjs/voice");
let daveyOk = false;
try { require("@snazzah/davey"); daveyOk = true; } catch (e) {
  console.warn("DAVEY_OPTIONAL_WARN", String(e && e.message || e));
}
const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildVoiceStates, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent],
});
void client;
let report = "";
try { report = voice.generateDependencyReport(); } catch (e) {
  report = "REPORT_FAIL:" + String(e && e.message || e);
}
console.log("IMPORT_OK");
console.log("DISCORDJS_VOICE_SCRATCH_OK");
console.log("node=" + process.versions.node);
console.log("davey=" + (daveyOk ? "OK" : "MISSING"));
console.log("--- dependency report ---");
console.log(report);
process.exit(0);
