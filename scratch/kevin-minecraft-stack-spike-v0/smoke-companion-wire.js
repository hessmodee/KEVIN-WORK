"use strict";
/**
 * Unit-test companion wire against recorded/fake packets only.
 * No Realms connect. No Minecraft.Windows interaction.
 */
const bridge = require("./bridge");

function fail(code, msg) {
  console.error(msg);
  process.exit(code);
}

const note = bridge.hashNote();
console.log("[smoke-companion-wire] gym lock note", JSON.stringify(note));

let netherOk = false;
try {
  bridge.assertNethernetReady();
  netherOk = true;
} catch (e) {
  console.log("[smoke-companion-wire] nethernet note (non-fatal for fake):", String(e && e.message || e));
}

const fake = bridge.createFakeJoinOkClient();
let bot;
try {
  bot = bridge.createBotFromClient(fake, {
    username: "kevinsk8erkid",
    alreadySpawned: true,
    physicsEnabled: false,
    loadInternalPlugins: false,
  });
} catch (e) {
  fail(3, "BRIDGE_INJECT_FAIL:" + String(e && e.message || e));
}
if (!bot || !bot._kevinInjected) fail(4, "BRIDGE_FLAG_MISSING");

// Seed fake Matt player for GoalFollow path (may still lack pathfinder if plugins off)
bot.players = bot.players || {};
bot.players.hessmodee = {
  username: "hessmodee",
  entity: { type: "player", username: "hessmodee", name: "hessmodee", position: { x: 2, y: 64, z: 2 } },
};

const matt = bridge.findMattEntity(bot);
if (!matt) fail(5, "FIND_MATT_FAIL");

const deny = bridge.attackHostileOnly(bot, matt);
if (deny.status !== "DENIED") fail(6, "NEG_PVP_MATT_NOT_DENIED:" + deny.status);

const denyPlayer = bridge.attackHostileOnly(bot, { type: "player", username: "Steve" });
if (denyPlayer.status !== "DENIED") fail(7, "NEG_PVP_PLAYER_NOT_DENIED");

const chat = bridge.queueChat(fake, "companion-wire-smoke", "kevinsk8erkid");
const attackPkt = bridge.queueAttackRuntime(fake, 99, { x: 0, y: 64, z: 0 });

// hessmodee login must throw
let loginDenied = false;
try {
  bridge.assertBotIdentity("hessmodee");
} catch (e) {
  loginDenied = /NEVER_HESSMODEE/i.test(String(e && e.message || e));
}
if (!loginDenied) fail(8, "NEG_HESSMODEE_LOGIN_NOT_DENIED");

const companion = bridge.enableStayCompanion(bot, {
  enableGuard: false, // plugins may be absent in light smoke
  enableAutoEat: false,
  range: 3,
});

console.log("KEVIN_MC_STACK_COMPANION_WIRE_SMOKE_OK");
console.log(JSON.stringify({
  netherOk,
  injected: !!bot._kevinInjected,
  mattFound: !!matt,
  denyMatt: deny.status,
  denyPlayer: denyPlayer.status,
  chatQueued: chat.status,
  attackPkt: attackPkt.status,
  companionStatus: companion.status,
  claims: companion.claims,
  note: "Fake/unit only. No live FOLLOW/COMBAT/GUARD. No Realms connect.",
}, null, 2));
process.exit(0);

