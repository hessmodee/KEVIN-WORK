"use strict";
const { parseIntent, INTENT } = require("./src/intent-router");
const { mapIntentToCompanionAction } = require("./src/companion-bridge");
const cases = [
  ["!k follow", INTENT.FOLLOW],
  ["!k stop", INTENT.STOP],
  ["!k guard", INTENT.GUARD],
  ["!k come", INTENT.COME],
  ["!k status", INTENT.STATUS],
  ["!k say hello realm", INTENT.SAY],
  ["kevin follow me", INTENT.FOLLOW],
  ["stop following", INTENT.STOP],
];
let fail = 0;
for (const [text, expect] of cases) {
  const got = parseIntent(text, { prefix: "!k" });
  const action = mapIntentToCompanionAction(got);
  const ok = got.name === expect;
  console.log((ok ? "PASS" : "FAIL"), JSON.stringify({ text, expect, got: got.name, action: action.action }));
  if (!ok) fail += 1;
}
if (fail) { console.error("SMOKE_TEXT_ROUTER_FAIL count=" + fail); process.exit(1); }
console.log("SMOKE_TEXT_ROUTER_OK");
process.exit(0);
