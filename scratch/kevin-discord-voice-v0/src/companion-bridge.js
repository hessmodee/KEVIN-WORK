"use strict";
/**
 * Map Discord voice/text intents -> Minecraft companion actions.
 * Does not claim FOLLOW_OK / GUARD_OK live until companion receipts exist.
 * Prefer calling into scratch/kevin-minecraft-stack-spike-v0 bridge when present.
 */
const { INTENT } = require("./intent-router");
const path = require("path");
const fs = require("fs");

const SPIKE_WIRE = path.resolve(
  __dirname,
  "..",
  "..",
  "kevin-minecraft-stack-spike-v0",
  "bridge",
  "companion-wire.js"
);

function tryLoadCompanionWire() {
  try {
    if (fs.existsSync(SPIKE_WIRE)) return require(SPIKE_WIRE);
  } catch (e) {
    return null;
  }
  return null;
}

function mapIntentToCompanionAction(intent) {
  const name = intent && intent.name;
  switch (name) {
    case INTENT.FOLLOW:
      return { action: "followMatt", companion: "GoalFollow", status: "ROUTED_NOT_PROVEN" };
    case INTENT.COME:
      return { action: "followMatt", companion: "GoalFollow", range: 2, status: "ROUTED_NOT_PROVEN" };
    case INTENT.STOP:
      return { action: "stopPathfinder", companion: "pathfinder.setGoal(null)", status: "ROUTED_NOT_PROVEN" };
    case INTENT.GUARD:
      return { action: "enableHostileGuard", companion: "guard.enable", status: "ROUTED_NOT_PROVEN" };
    case INTENT.STATUS:
      return { action: "status", companion: "report", status: "ROUTED_NOT_PROVEN" };
    case INTENT.SAY:
      return {
        action: "queueChat",
        companion: "client.queue(text)",
        message: (intent.args && intent.args.message) || "",
        status: "ROUTED_NOT_PROVEN",
      };
    case INTENT.JOIN_VC:
      return { action: "joinVoice", status: "VOICE_CONTROL" };
    case INTENT.LEAVE_VC:
      return { action: "leaveVoice", status: "VOICE_CONTROL" };
    default:
      return { action: "none", status: "UNKNOWN_INTENT" };
  }
}

/**
 * Apply intent against an optional live bot/client.
 * Without bot: returns dry plan only.
 */
function applyIntent(intent, ctx = {}) {
  const plan = mapIntentToCompanionAction(intent);
  const wire = tryLoadCompanionWire();
  const bot = ctx.bot;
  const client = ctx.client || (bot && bot._client);

  if (!bot && !client) {
    return { ok: true, dry: true, plan, note: "No live bot — text/voice command accepted for later inject" };
  }

  try {
    if (plan.action === "followMatt" && wire && wire.followMatt) {
      return { ok: true, dry: false, plan, result: wire.followMatt(bot, { range: plan.range }) };
    }
    if (plan.action === "enableHostileGuard" && wire && wire.enableHostileGuard) {
      return { ok: true, dry: false, plan, result: wire.enableHostileGuard(bot, { enable: true }) };
    }
    if (plan.action === "queueChat" && wire && wire.queueChat) {
      return { ok: true, dry: false, plan, result: wire.queueChat(client, plan.message, "kevinsk8erkid") };
    }
    if (plan.action === "stopPathfinder" && bot && bot.pathfinder) {
      bot.pathfinder.setGoal(null);
      return { ok: true, dry: false, plan, result: { status: "WIRED_NOT_PROVEN", action: "stop" } };
    }
    if (plan.action === "status") {
      return {
        ok: true,
        dry: false,
        plan,
        result: {
          status: "WIRED_NOT_PROVEN",
          identity: "kevinsk8erkid",
          hasBot: !!bot,
          players: bot && bot.players ? Object.keys(bot.players).length : 0,
        },
      };
    }
  } catch (e) {
    return { ok: false, plan, error: String(e && e.message || e) };
  }

  return { ok: true, dry: true, plan, note: "Wire missing or action not bound" };
}

module.exports = { mapIntentToCompanionAction, applyIntent, tryLoadCompanionWire };
