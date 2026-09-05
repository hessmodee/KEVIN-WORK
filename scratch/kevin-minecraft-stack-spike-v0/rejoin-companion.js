"use strict";
/**
 * Stay + companion entry: preflight MC UI -> JOIN_OK NetherNet createClient ->
 * inject into bedrockflayer -> on spawn enable GoalFollow Matt + hostile guard + autoEat.
 *
 * NEG: never attack players, never hessmodee login, no grief.
 * Never kill Minecraft.Windows / Chat / Reader. No purchases.
 * Do NOT claim FOLLOW_OK / COMBAT_OK / GUARD_OK without spawn+entity proof.
 */
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const bridge = require("./bridge");

const SPIKE = __dirname;
const LOG = path.join(SPIKE, "_rejoin-companion.log");

function log(...args) {
  const line = args.map((a) => (typeof a === "string" ? a : JSON.stringify(a))).join(" ");
  console.log(line);
  try { fs.appendFileSync(LOG, line + "\n"); } catch (e) {}
}

function mcUiRunning() {
  try {
    const r = spawnSync("tasklist", ["/FI", "IMAGENAME eq Minecraft.Windows.exe"], {
      encoding: "utf8",
      windowsHide: true,
    });
    const out = String(r.stdout || "");
    return /Minecraft\.Windows\.exe/i.test(out);
  } catch (e) {
    return false;
  }
}

function printReadyForLiveInject() {
  log("READY_FOR_LIVE_INJECT");
  log("[rejoin-companion] BLOCKED_MC_UI — Minecraft.Windows.exe is running.");
  log("[rejoin-companion] Do NOT kill UWP / Chat / Reader.");
  log("[owner] Close Minecraft (UWP) when safe, then re-run:");
  log("  scratch\\kevin-minecraft-stack-spike-v0\\rejoin-companion.cmd");
  log("[alt] Or gym stay only: scratch\\kevin-minecraft-bedrock-v0\\rejoin.cmd");
  log("[unit] Fake-packet inject smoke (no Realms): smoke-companion-wire.cmd");
  try {
    const readyPath = path.join(SPIKE, "READY_FOR_LIVE_INJECT.md");
    if (fs.existsSync(readyPath)) {
      log("[rejoin-companion] See READY_FOR_LIVE_INJECT.md");
    }
  } catch (e) {}
}

function fail(code, msg) {
  log(msg);
  process.exit(code);
}

async function main() {
  try { fs.writeFileSync(LOG, ""); } catch (e) {}
  log("[rejoin-companion] start", new Date().toISOString());
  log("[rejoin-companion] identity kevinsk8erkid — never hessmodee");
  log("[rejoin-companion] gym lock note", bridge.hashNote());

  if (mcUiRunning()) {
    printReadyForLiveInject();
    process.exit(2);
  }
  log("KEVIN_REALMS_STAY_PREFLIGHT_OK");

  // Live gate
  process.env.KEVIN_SPIKE_ALLOW_LIVE_JOIN = "1";
  process.env.KEVIN_REALMS_STAY = "1";
  process.env.KEVIN_MC_VERSION = process.env.KEVIN_MC_VERSION || "1.26.45";

  let nether;
  try {
    nether = bridge.assertNethernetReady();
    log("[rejoin-companion] nethernet", nether.ok, nether.root);
  } catch (e) {
    fail(5, "NETHERNET_GATE:" + String(e && e.message || e));
  }

  let client;
  try {
    client = bridge.createJoinOkClient({ username: "kevinsk8erkid" });
  } catch (e) {
    const msg = String(e && e.message || e);
    if (e && e.code === "READY_FOR_OWNER_DEVICE_CODE") fail(3, "READY_FOR_OWNER_DEVICE_CODE");
    if (/LIVE_JOIN_BLOCKED/.test(msg)) fail(2, msg);
    if (/NETHERNET|nether/i.test(msg)) fail(5, "NETHERNET_GATE:" + msg);
    fail(4, "CREATE_CLIENT_FAIL:" + msg);
  }

  log("KEVIN_MC_STACK_STAY_COMPANION_LIVE_ATTEMPTED");
  log("[rejoin-companion] waiting for spawn (JOIN_OK NetherNet)...");

  let spawnInfo;
  try {
    spawnInfo = await bridge.waitForClientSpawn(client);
    log("[rejoin-companion] spawn event", spawnInfo.event);
  } catch (e) {
    try { if (client && client.close) client.close(); } catch (e2) {}
    fail(4, "SPAWN_FAIL:" + String(e && e.message || e));
  }

  // Honest JOIN_OK-shaped marker for stay path (client spawned). Not JOIN_COMPAT_OK.
  log("KEVIN_REALMS_JOIN_OK");
  log("[rejoin-companion] injecting client into bedrockflayer createBotFromClient");

  let bot;
  try {
    bot = bridge.createBotFromClient(client, {
      username: "kevinsk8erkid",
      alreadySpawned: true,
      physicsEnabled: false,
      loadInternalPlugins: true,
    });
  } catch (e) {
    log("INJECT_FAIL:" + String(e && e.message || e));
    log("[rejoin-companion] staying on raw JOIN_OK client without inject");
    bot = null;
  }

  let companionStatus = null;
  if (bot) {
    log("[rejoin-companion] injected flag", !!bot._kevinInjected);
    // Wait a tick for late-bind spawn emit + players map population.
    await new Promise((r) => setTimeout(r, 1500));
    companionStatus = bridge.enableStayCompanion(bot, {
      enableGuard: true,
      enableAutoEat: true,
      range: 3,
      names: ["hessmodee", "HESSMODEE"],
    });
    log("[rejoin-companion] companion wire", companionStatus);
    if (companionStatus.follow && companionStatus.follow.entityPresent) {
      log("KEVIN_MC_FOLLOW_WIRED_NOT_PROVEN");
    } else {
      log("[rejoin-companion] Matt entity not found yet — follow deferred; will retry on interval");
    }
  }

  // Soft retry find Matt / follow without claiming OK
  const followRetry = setInterval(() => {
    if (!bot) return;
    const matt = bridge.findMattEntity(bot);
    if (!matt) {
      log("[rejoin-companion] matt poll: not found");
      return;
    }
    const fr = bridge.followMatt(bot, { range: 3 });
    log("[rejoin-companion] matt poll follow", fr.status, fr.reason || fr.action);
  }, 15000);
  if (followRetry.unref) followRetry.unref();

  const heartbeat = setInterval(() => {
    log("[rejoin-companion] heartbeat stay=1 injected=" + !!(bot && bot._kevinInjected)
      + " follow=" + (companionStatus && companionStatus.follow && companionStatus.follow.status));
  }, 30000);
  if (heartbeat.unref) heartbeat.unref();

  log("[rejoin-companion] stay active — Ctrl+C to exit. No FOLLOW_OK/COMBAT_OK claimed.");
  // Keep process alive for stay
  await new Promise(() => {});
}

main().catch((e) => {
  fail(1, "FATAL:" + String(e && e.stack || e));
});
