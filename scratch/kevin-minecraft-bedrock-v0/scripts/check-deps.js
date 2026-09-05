#!/usr/bin/env node
"use strict";
try {
  require("bedrock-protocol");
  require("prismarine-auth");
  console.log("DEPS_OK");
  process.exit(0);
} catch (e) {
  console.error("MISSING_DEPS");
  process.exit(2);
}
