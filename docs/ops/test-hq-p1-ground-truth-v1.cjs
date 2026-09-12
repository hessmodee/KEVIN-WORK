#!/usr/bin/env node
'use strict';
/**
 * Node tests for docs/hq-p1-ground-truth-v1.js pure honesty API.
 * Prefer fixtures under docs/ops/fixtures/ when present; fall back to /workspace samples.
 */
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const ROOT = path.resolve(__dirname, '../..');
const API = require(path.join(ROOT, 'docs/hq-p1-ground-truth-v1.js'));
const FIX = path.join(__dirname, 'fixtures');

function loadJson(name) {
  const candidates = [
    path.join(FIX, name),
    path.join(ROOT, 'reports/sample', name),
    path.join(ROOT, 'hq-p1-ship/reports/sample', name)
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) return JSON.parse(fs.readFileSync(p, 'utf8'));
  }
  throw new Error('missing fixture ' + name);
}

function copyFixture(srcName, destName) {
  const src = path.join(ROOT, 'reports/sample', srcName);
  const dest = path.join(FIX, destName || srcName);
  if (fs.existsSync(src) && !fs.existsSync(dest)) {
    fs.copyFileSync(src, dest);
  }
}

// Ensure local fixtures exist for offline re-runs
[
  'support-latest.json',
  'autonomy-continuation-latest.json',
  'engineering-latest.json',
  'main-agent-canary-omen.json',
  'latest-public-reject.json',
  'bridge-latest.json',
  'dashboard-state.json'
].forEach(n => copyFixture(n));

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed += 1;
    console.log('PASS', name);
  } catch (e) {
    console.error('FAIL', name);
    console.error(e && e.stack || e);
    process.exitCode = 1;
  }
}

const now = Date.parse('2026-09-11T19:15:00-06:00');
const support = loadJson('support-latest.json');
const continuation = loadJson('autonomy-continuation-latest.json');
const engineering = loadJson('engineering-latest.json');
const canary = loadJson('main-agent-canary-omen.json');
const reject = loadJson('latest-public-reject.json');
const dashboard = loadJson('dashboard-state.json');
const bridge = loadJson('bridge-latest.json');

const bundle = { support, continuation, engineering, canary, reject, dashboard, bridge };

test('version identity', () => {
  assert.strictEqual(API.VERSION, 'hq-p1-ground-truth-v1');
});

test('canary shape alone is STALE when old', () => {
  const chip = API.toolsChip(canary, now);
  assert.strictEqual(chip.label, '5 · CANARY STALE');
  assert.strictEqual(chip.stale, true);
  assert.strictEqual(API.exactFiveCanary(canary, now), false);
});

test('fresh exact-five canary is PROVEN', () => {
  const fresh = { ...canary, generated_at: new Date(now).toISOString() };
  assert.strictEqual(API.exactFiveCanary(fresh, now), true);
  assert.strictEqual(API.toolsChip(fresh, now).label, '5 PROVEN');
});

test('strip stale v1.8.11 / 685B34F3 / grok-install-v1811', () => {
  const raw = 'Invocation runtime is independently effective (Supervisor v1.8.11 hash 685B34F3, typed ALREADY_APPLIED_PROVEN for grok-install-v1811-20260908-1625, continuation version 1.8.11). Keep burned turn.';
  assert.strictEqual(API.hasStaleV1811(raw), true);
  const cleaned = API.stripStaleV1811(raw);
  assert.strictEqual(API.hasStaleV1811(cleaned), false);
  assert.ok(/burned turn/i.test(cleaned));
});

test('BLOCKED_INVOCATION_RUNTIME maps to BLOCKED with isolate pair', () => {
  const blockedBundle = {
    ...bundle,
    continuation: { ...continuation, status: 'BLOCKED_INVOCATION_RUNTIME' },
    reject
  };
  const t = API.kevinCenterTruth(blockedBundle, now);
  assert.strictEqual(t.mode, 'blocked');
  assert.strictEqual(t.label, 'BLOCKED');
  assert.ok(t.showIsolatePair);
  assert.ok(/not PASS/i.test(t.detail));
  assert.ok(t.cite && /VERIFY prior PASS MIXED/i.test(t.cite));
});

test('OUTCOME_PROVEN is honest and never invents PASS from STAGE_OK', () => {
  const t = API.kevinCenterTruth(bundle, now);
  // sample reject is OUTCOME_PROVEN; continuation is ROUTED — prefer OUTCOME_PROVEN path when reason matches
  // Actual API checks BLOCKED first, then OUTCOME_PROVEN, then ROUTED
  assert.ok(['outcome_proven', 'routed'].includes(t.mode));
  if (t.mode === 'outcome_proven') {
    assert.strictEqual(t.label, 'OUTCOME_PROVEN');
    assert.ok(!/PASS(?! MIXED)/.test(t.label));
  }
  assert.ok(String(reject.supervisor_request_id_reason).toUpperCase() === 'STAGE_OK');
  assert.notStrictEqual(t.label, 'PASS');
  assert.notStrictEqual(t.mode, 'ready');
});

test('ROUTED status is ROUTED not READY/WORKING', () => {
  const routedOnly = {
    ...bundle,
    reject: { generated_at: reject.generated_at, reason: 'OTHER', outcome_proven: false },
    continuation: { ...continuation, status: 'ROUTED_TO_PROVEN_SKILL_INVOCATION' },
    dashboard: { ...dashboard, current_task: null },
    support: { ...support, active_workers: { design_forge: 0, night_forge: 0, supervisor: 0, benchmark: 0 } },
    engineering: { ...engineering, action: { ...engineering.action, queues: { ready: 0 }, composite_skills: { ready: 0 } } }
  };
  const t = API.kevinCenterTruth(routedOnly, now);
  assert.strictEqual(t.mode, 'routed');
  assert.strictEqual(t.label, 'ROUTED');
});

test('WORKING only with live worker or Action Era ready>=1', () => {
  const idle = {
    dashboard: { generated_at: new Date(now).toISOString(), current_task: null },
    support: { generated_at: new Date(now).toISOString(), active_workers: { tick: 1, bridge: 1, supervisor: 0 } },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } }
  };
  assert.strictEqual(API.mayShowWorkingBuilding(idle, now), false);
  assert.strictEqual(API.honestWorkerState('tick', 'working', idle, now), 'ready');
  assert.strictEqual(API.honestWorkerState('chat', 'working', idle, now), 'ready');
  assert.strictEqual(API.honestWorkerState('build', 'building', idle, now), 'ready');

  const live = {
    ...idle,
    support: { generated_at: new Date(now).toISOString(), active_workers: { supervisor: 1, tick: 0 } }
  };
  assert.strictEqual(API.mayShowWorkingBuilding(live, now), true);

  const era = {
    ...idle,
    support: { generated_at: new Date(now).toISOString(), active_workers: {} },
    engineering: { action: { queues: { ready: 2 }, composite_skills: { ready: 2 } } }
  };
  assert.strictEqual(API.mayShowWorkingBuilding(era, now), true);
});

test('clocks expose LAST OWNER ATTEMPT + LAST PLATFORM SIGNAL + cycle', () => {
  const c = API.clocksFromReports(bundle, now);
  assert.ok(c.lastOwnerAttempt.at, 'owner attempt timestamp');
  assert.ok(/Sep 8/i.test(c.lastOwnerAttempt.label) || /9:31/.test(c.lastOwnerAttempt.label) || c.lastOwnerAttempt.at.includes('2026-09-08'));
  assert.ok(c.lastPlatformSignal.at, 'platform signal');
  assert.strictEqual(Number(c.cycle), 449);
});

test('newswire builds from support/continuation/reject/engineering/benchmark', () => {
  const stories = API.newswireStories(bundle, now);
  const ids = stories.map(s => s.id);
  assert.ok(ids.includes('support-latest'));
  assert.ok(ids.includes('autonomy-continuation-latest'));
  assert.ok(ids.includes('invocations/latest-public-reject'));
  assert.ok(ids.includes('engineering/latest'));
  assert.ok(ids.includes('benchmark'));
});

test('empty newswire shows no-new-events + last 3 lines', () => {
  const empty = API.emptyNewswireFallback({ continuation: { history: [
    { id: 'a', status: 'X', last_turn_at: '2026-09-08T09:31:00-06:00' },
    { id: 'b', status: 'Y', last_turn_at: '2026-09-07T16:14:00-06:00' },
    { id: 'c', status: 'Z', last_turn_at: '2026-09-06T12:00:00-06:00' }
  ] } }, [{ id: 'empty', empty: true, text: 'no new events since unknown', lastLines: [] }]);
  assert.ok(/no new events since/i.test(empty[0].text));
  assert.ok(Array.isArray(empty[0].lastLines));
  assert.ok(empty[0].lastLines.length <= 3);
});

test('scaffold visible with GROKBOT_ACTED, never Kevin WORKING/learning', () => {
  const sc = API.scaffoldState(bundle, { grokbotActed: true, cosActive: true, lastAction: 'GROKBOT_ACTED · overlay' });
  assert.strictEqual(sc.visible, true);
  assert.strictEqual(sc.chip, 'SCAFFOLD');
  assert.strictEqual(sc.actor, 'GROKBOT_ACTED');
  assert.strictEqual(sc.neverKevinWorking, true);
  assert.strictEqual(sc.neverKevinLearning, true);
  assert.ok(sc.dashedToKevin);
  const idle = API.scaffoldState({ continuation: { status: 'IDLE_NO_ELIGIBLE_DEMAND' } }, {});
  assert.strictEqual(idle.visible, false);
});

test('selected worker CSS restores overflow/scroll', () => {
  const css = API.selectedWorkerCss();
  assert.ok(/overflow:\s*auto/i.test(css));
  assert.ok(/\.card\.detail/i.test(css));
  assert.ok(/max-height:\s*none/i.test(css));
});

test('work-items.json no longer cites stale v1811 markers', () => {
  const wiPath = path.join(ROOT, 'inbox/autonomy/work-items.json');
  const raw = fs.readFileSync(wiPath, 'utf8');
  assert.ok(!/v1\.8\.11/.test(raw));
  assert.ok(!/685B34F3/.test(raw));
  assert.ok(!/grok-install-v1811/.test(raw));
});

console.log(`\n${passed} tests passed`);
if (process.exitCode) {
  console.error('TEST SUITE FAILED');
  process.exit(process.exitCode);
}
console.log('TEST SUITE OK');
process.exit(0);
