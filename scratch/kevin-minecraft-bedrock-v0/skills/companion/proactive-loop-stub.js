"use strict";
/** STUB ONLY — not live-proven. Do not emit OK markers without receipt. */
const NAME = "companion-proactive-loop";
function notProven(action) {
  console.log("[kevin-mc-stub]", NAME, action, "NOT_PROVEN");
  return { ok: false, status: "NOT_PROVEN", action, skill: NAME };
}
module.exports = {
  name: NAME,
  status: "STUB",
  async run(ctx) { return notProven("run"); },
  notProven,
};
