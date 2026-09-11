#!/usr/bin/env node
'use strict';
const fs = require('fs');
const path = require('path');

function ageText(sec) {
  if (!Number.isFinite(sec)) return '?';
  if (sec < 90) return Math.round(sec) + 's';
  return Math.round(sec / 60) + 'm';
}

/** Pure Tools canary honesty — keep in sync with DESIGN.md. Complements P1-4; do not redo #127. */
function toolsCanaryHonesty(i) {
  const gate = Number.isFinite(i.canaryGateSec) ? i.canaryGateSec : 180;
  const tools = i.tools;
  const age = i.canaryAgeSec;
  const missing = age == null || (typeof age === 'number' && Number.isNaN(age));
  const stale = missing || !Number.isFinite(age) || age > gate;

  if (tools === false) {
    return {
      label: 'OFF',
      cls: 'bad',
      chipTag: Number.isFinite(age) ? ageText(age) : 'off',
      implyOn: false,
      attention: 'Kevin main tools OFF — reasoning without hands.',
    };
  }
  if (tools === true && stale) {
    return {
      label: 'CANARY STALE',
      cls: 'stale',
      chipTag: missing || !Number.isFinite(age) ? 'STALE unknown' : 'STALE ' + ageText(age),
      implyOn: false,
      attention: 'Tools canary/evidence STALE — do not treat hands as live.',
    };
  }
  if (tools === true && !stale) {
    return {
      label: 'ON',
      cls: 'fresh',
      chipTag: ageText(age),
      implyOn: true,
      attention: null,
    };
  }
  return {
    label: 'unknown',
    cls: 'unknown',
    chipTag: 'unknown',
    implyOn: false,
    attention: null,
  };
}

const fixDir = path.join(__dirname, 'fixtures');
const files = fs.readdirSync(fixDir).filter((f) => f.endsWith('.json')).sort();
let n = 0;
for (const f of files) {
  const fx = JSON.parse(fs.readFileSync(path.join(fixDir, f), 'utf8'));
  const got = toolsCanaryHonesty(fx.input);
  const exp = fx.expect;
  for (const [k, want] of Object.entries(exp)) {
    if (got[k] !== want) {
      console.error('FAIL', fx.name, k, 'got', got[k], 'want', want, got);
      process.exit(1);
    }
  }
  if (got.implyOn && got.label !== 'ON') {
    console.error('FAIL honesty', fx.name, 'implyOn without ON');
    process.exit(1);
  }
  if (got.label === 'CANARY STALE' && got.implyOn) {
    console.error('FAIL honesty', fx.name, 'ON implied under CANARY STALE');
    process.exit(1);
  }
  if (fx.name === 'TOOLS_CANARY_STALE' && got.label === 'ON') {
    console.error('FAIL honesty', fx.name, 'painted ON under stale canary');
    process.exit(1);
  }
  n++;
}

// Extra: missing canary + tools true → CANARY STALE
const miss = toolsCanaryHonesty({ tools: true, canaryAgeSec: null, canaryGateSec: 180 });
if (miss.label !== 'CANARY STALE' || miss.implyOn) {
  console.error('FAIL missing-canary', miss);
  process.exit(1);
}
n++;

console.log('PASS', n, 'fixtures+cases');
