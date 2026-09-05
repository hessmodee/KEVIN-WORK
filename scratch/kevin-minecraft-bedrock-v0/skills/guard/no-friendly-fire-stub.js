"use strict";
/**
 * No friendly fire — deny attacks on Matt (hessmodee), self, pets, villagers, golems.
 * STUB/SCAFFOLD — policy helper for combat/guard.
 */
const NAME = "guard-no-friendly-fire";
const PROTECTED_NAMES = new Set(["hessmodee", "kevinsk8erkid"]);
const PROTECTED_TYPES = new Set([
  "player", "villager", "iron_golem", "snow_golem", "wolf", "cat", "parrot",
  "horse", "donkey", "mule", "llama", "allay",
]);
function isProtected(entity) {
  if (!entity) return true;
  const n = String(entity.username || entity.name || entity.type || "").toLowerCase().replace(/^minecraft:/, "");
  if (PROTECTED_NAMES.has(n)) return true;
  if (entity.type === "player") return true;
  if (PROTECTED_TYPES.has(n)) return true;
  if (entity.customName || entity.nametag) return true; // named/pet heuristic
  return false;
}
function allowAttack(entity) {
  return !isProtected(entity);
}
async function run(ctx = {}) {
  const entity = ctx.entity;
  const allowed = allowAttack(entity);
  console.log("[kevin-mc-stub]", NAME, allowed ? "ALLOW_HOSTILE_CANDIDATE" : "DENY_FRIENDLY", "NOT_PROVEN");
  return {
    ok: false,
    status: "POLICY_CHECK_NOT_PROVEN",
    skill: NAME,
    allowed,
    reason: allowed ? "NOT_PROTECTED_NAME_TYPE" : "FRIENDLY_OR_PROTECTED",
  };
}
module.exports = { name: NAME, status: "SCAFFOLD_NOT_PROVEN", PROTECTED_NAMES, PROTECTED_TYPES, isProtected, allowAttack, run };
