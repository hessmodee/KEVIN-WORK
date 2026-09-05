#!/usr/bin/env node
"use strict";
process.env.KEVIN_REALMS_STAY = process.env.KEVIN_REALMS_STAY || "1";
require("./realms-join.js");
