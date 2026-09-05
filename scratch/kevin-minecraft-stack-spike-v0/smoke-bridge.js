"use strict";
/**
 * Dry bridge smoke: require bridge + inject a fake EventEmitter client.
 * Does NOT connect to Realms. Does NOT touch JOIN_OK lockfile.
 */
const path = require("path");
const { EventEmitter } = require("events");
const bridge = require("./bridge");

function fail(code, msg) {
  console.error(msg);
  process.exit(code);
}

const note = bridge.hashNote();
console.log("[smoke-bridge] gym lock note", JSON.stringify(note));

let vendorOk = false;
try {
  bridge.loadVendor();
  vendorOk = true;
} catch (e) {
  console.error("VENDOR_FAIL", e && e.message ? e.message : e);
  fail(2, "SPIKE_VENDOR_REQUIRE_FAIL");
}

const fake = new EventEmitter();
fake.queue = function () { return Promise.resolve(); };
fake.startGameData = {
  runtime_entity_id: 1,
  entity_id: 1,
  player_position: { x: 0, y: 64, z: 0 },
  rotation: { x: 0, z: 0 },
  player_gamemode: 0,
  dimension: "overworld",
  difficulty: 1,
  engine: "1.26.45",
  world_name: "smoke",
  spawn_position: { x: 0, y: 64, z: 0 },
};

let bot;
try {
  bot = bridge.createBotFromClient(fake, {
    username: "kevinsk8erkid",
    alreadySpawned: true,
    physicsEnabled: false,
    loadInternalPlugins: false, // keep dry smoke light
  });
} catch (e) {
  console.error("INJECT_FAIL", e && e.message ? e.message : e);
  fail(3, "BRIDGE_INJECT_FAIL");
}

if (!bot || !bot._kevinInjected) fail(4, "BRIDGE_FLAG_MISSING");

const mattFind = bridge.findMattEntity(bot);
const chat = bridge.queueChat(fake, "bridge-smoke", "kevinsk8erkid");

console.log("KEVIN_MC_STACK_BRIDGE_SMOKE_OK");
console.log(JSON.stringify({
  vendorOk,
  injected: !!bot._kevinInjected,
  bridge: bot._kevinBridge,
  mattFind: mattFind ? "found" : null,
  chatQueued: chat.status,
  note: "Dry inject only. Realms createBot join NOT proven. JOIN_COMPAT not claimed.",
}, null, 2));
