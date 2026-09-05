/**
 * P0 smoke: can we require bedrockflayer and see GoalFollow/combat/guard exports?
 * Does NOT connect to Realms. Does NOT touch JOIN_OK gym.
 */
const path = require("path");
const vendorMain = path.join(__dirname, "vendor", "mineflayer-for-bedrock-main");
let mod;
try {
  mod = require(vendorMain);
} catch (err) {
  console.error("SPIKE_REQUIRE_FAIL", err && err.message ? err.message : err);
  console.error("HINT: run install-deps (vendor npm install) first");
  process.exit(2);
}

const keys = Object.keys(mod || {}).sort();
const need = ["createBot", "GoalFollow", "GoalNear", "GoalBlock", "guard", "autoEat", "collectBlock", "version"];
const present = {};
for (const k of need) present[k] = typeof mod[k] !== "undefined";

const combatPath = path.join(vendorMain, "lib", "plugins", "combat.js");
const guardPath = path.join(vendorMain, "lib", "plugins", "guard.js");
const pathfinderPath = path.join(vendorMain, "lib", "plugins", "pathfinder.js");
const fs = require("fs");

console.log("KEVIN_MC_STACK_SPIKE_IMPORT_OK");
console.log(JSON.stringify({
  version: mod.version,
  exportKeys: keys,
  present,
  pluginFiles: {
    combat: fs.existsSync(combatPath),
    guard: fs.existsSync(guardPath),
    pathfinder: fs.existsSync(pathfinderPath),
  },
  note: "Import-only smoke. Realms/NetherNet join NOT proven here."
}, null, 2));
