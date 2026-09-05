"use strict";
/**
 * Find Matt (hessmodee) among bot.players / bot.entities by gamertag / display variants.
 * NOT live-proven. Used by companion GoalFollow wiring.
 */
const { MATT_TAGS } = require("./paths");

function normalize(name) {
  return String(name || "").trim().toLowerCase();
}

function isMattName(name) {
  const n = normalize(name);
  if (!n) return false;
  if (n === "hessmodee") return true;
  if (n.includes("hessmodee")) return true;
  // display / Xbox variants sometimes strip punctuation or add spaces
  const compact = n.replace(/[\s_\-.]/g, "");
  return compact === "hessmodee" || compact.includes("hessmodee");
}

/**
 * @param {object} bot - bedrockflayer bot (injected or LAN)
 * @param {object} [opts]
 * @returns {object|null} player entity or null
 */
function findMattEntity(bot, opts = {}) {
  if (!bot) return null;
  const prefer = (opts.names || MATT_TAGS).map(normalize);
  const players = bot.players || {};
  for (const key of Object.keys(players)) {
    const p = players[key];
    const uname = p && (p.username || p.name || p.displayName || key);
    const display = p && (p.displayName || p.nameTag || "");
    if (prefer.includes(normalize(uname)) || isMattName(uname) || isMattName(display) || isMattName(key)) {
      return p.entity || p;
    }
  }
  const entities = bot.entities || {};
  for (const id of Object.keys(entities)) {
    const e = entities[id];
    if (!e) continue;
    const uname = e.username || e.name || e.displayName || e.nameTag;
    if (e.type === "player" || e.name === "player" || uname) {
      if (prefer.includes(normalize(uname)) || isMattName(uname)) return e;
    }
  }
  return null;
}

module.exports = { findMattEntity, isMattName, normalize };
