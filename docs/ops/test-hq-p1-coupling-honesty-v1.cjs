#!/usr/bin/env node
'use strict';
/**
 * Coupling honesty: Bridge vs center, receipt clock, OPS FLOOR COMPLETED stripe.
 * West-motor five-pack stays PROVEN — not a failed PASS.
 */
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const ROOT = path.resolve(__dirname, '../..');
const API = require(path.join(ROOT, 'docs/hq-p1-ground-truth-v1.js'));
const FIX = path.join(__dirname, 'fixtures');

function loadJson(name) {
  const p = path.join(FIX, name);
  if (!fs.existsSync(p)) throw new Error('missing fixture ' + name);
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

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

const now = Date.parse('2026-09-12T01:10:00Z');
const receipt = loadJson('west-motor-invoke-receipt.json');
const reject = {
  reason: 'OUTCOME_PROVEN',
  outcome_proven: true,
  verify_actor: 'MIXED',
  generated_at: '2026-09-11T19:57:17-06:00',
  work_id_hint: 'owner-west-motor-parts-chase-fresh-8-v1',
  supervisor_request_id: 'invoke-owner-west-motor-parts-chase-fresh-8-v1',
  receipt_status: 'PROVEN'
};

test('coupling identity + west-motor fixture timestamp', () => {
  assert.strictEqual(API.COUPLING, 'hq-p1-coupling-honesty-v1');
  assert.strictEqual(API.WEST_MOTOR_COMPLETED_AT, '2026-09-12T00:54:57Z');
  assert.ok(String(receipt.completed_at).startsWith('2026-09-12T00:54:57'));
  assert.strictEqual(receipt.status, 'PROVEN');
  assert.strictEqual(receipt.invocation_id, API.WEST_MOTOR_INVOKE_ID);
  const t = API.parseTs(receipt.completed_at);
  const fixture = API.parseTs(API.WEST_MOTOR_COMPLETED_AT);
  assert.ok(Number.isFinite(t) && Number.isFinite(fixture));
  assert.ok(Math.abs(t - fixture) < 1000, 'west-motor completed_at matches fixture second');
});

test('Bridge DEGRADED from stale heartbeat alone does NOT force center FAILED after OUTCOME_PROVEN', () => {
  const bundle = {
    reject,
    receipt,
    continuation: { status: 'ROUTED_TO_PROVEN_SKILL_INVOCATION', generated_at: '2026-09-11T19:09:20-06:00' },
    dashboard: {
      generated_at: '2026-09-11T12:00:00Z',
      services: { bridge: 'unknown', tick: 'healthy', ollama: 'healthy' },
      health: { overall: 'degraded', failed_checks: 1 },
      current_task: null
    },
    support: { generated_at: '2026-09-11T12:00:00Z', active_workers: {} },
    engineering: { action: { ui_bridge: { task_present: false, heartbeat_age_seconds: 9999 }, queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    bridge: { at: '2026-09-11T12:00:00Z', bridge: 'ok', puller: 'v1.6' }
  };
  const bridge = API.bridgeHonesty(bundle, now);
  assert.strictEqual(bridge.state, 'degraded');
  assert.strictEqual(bridge.disabled, false);
  const center = API.centerHonesty(bundle, now);
  assert.strictEqual(center.mode, 'outcome_proven');
  assert.strictEqual(center.label, 'OUTCOME_PROVEN');
  assert.strictEqual(center.failed, false);
  assert.strictEqual(center.inheritedBridge, false);
  assert.strictEqual(center.worstFeedIsNotKevinFailed, true);
  assert.notStrictEqual(center.label, 'FAILED');
  assert.notStrictEqual(center.mode, 'failed');
  assert.notStrictEqual(center.mode, 'degraded');
  const truth = API.kevinCenterTruth(bundle, now);
  assert.strictEqual(truth.mode, 'outcome_proven');
  assert.strictEqual(truth.failed, false);
  assert.strictEqual(truth.inheritedBridge, false);
});

test('Bridge OK when task alive even if heartbeat stale (within policy)', () => {
  const bundle = {
    dashboard: {
      generated_at: new Date(now).toISOString(),
      services: { bridge: 'unknown' },
      current_task: { id: 'live-job', phase: 'executing', title: 'live task' }
    },
    support: { generated_at: new Date(now - 20000).toISOString(), active_workers: { supervisor: 0 } },
    engineering: { action: { ui_bridge: { task_present: true, heartbeat_age_seconds: 4800 }, queues: { ready: 0 } } },
    bridge: { at: new Date(now - 7200_000).toISOString(), bridge: 'ok', puller: 'v1.6' }
  };
  const ages = API.githubBridgeAge(bundle, now);
  assert.ok(ages.heartbeatAge > API.BRIDGE_HEARTBEAT_S || ages.heartbeatAge > 900);
  assert.strictEqual(API.taskAlive(bundle, now), true);
  const b = API.bridgeHonesty(bundle, now);
  assert.strictEqual(b.state, 'ok');
  assert.strictEqual(b.label, 'OK');
  assert.strictEqual(b.reason, 'task-alive-stale-heartbeat');
  assert.strictEqual(b.disabled, false);
  assert.strictEqual(API.honestBridgeWorkerState('degraded', bundle, now), 'ready');
  assert.strictEqual(API.honestBridgeWorkerState('working', bundle, now), 'ready');
  assert.strictEqual(API.honestBridgeWorkerState('disabled', bundle, now), 'ready');
});

test('Bridge UNKNOWN→OK when GitHubBridge/support-latest is fresh vs paint', () => {
  const bundle = {
    dashboard: { generated_at: new Date(now).toISOString(), services: { bridge: 'unknown' }, current_task: null },
    support: { generated_at: new Date(now - 30_000).toISOString(), active_workers: {} },
    engineering: { action: { ui_bridge: { task_present: false }, queues: { ready: 0 } } },
    bridge: { at: new Date(now - 7200_000).toISOString(), bridge: 'ok', puller: 'v1.6' }
  };
  const b = API.bridgeHonesty(bundle, now);
  assert.strictEqual(b.state, 'ok');
  assert.strictEqual(b.reason, 'support-fresh-vs-paint');
  assert.strictEqual(b.disabled, false);
});

test('last-attempt clock uses receipt completed_at not unknown', () => {
  const bundle = {
    receipt,
    reject,
    continuation: {
      selected_id: 'owner-west-motor-parts-chase-fresh-8-v1',
      history: [{ id: 'owner-west-motor-parts-chase-fresh-8-v1', last_turn_at: '2026-09-08T09:31:09-06:00' }]
    }
  };
  const clock = API.lastAttemptClock(bundle, now);
  assert.strictEqual(clock.unknown, false);
  assert.strictEqual(clock.source, 'receipt.completed_at');
  assert.ok(String(clock.at).startsWith('2026-09-12T00:54:57'));
  assert.strictEqual(clock.fixtureWestMotor, true);
  assert.notStrictEqual(clock.age, 'unknown');
  assert.ok(clock.age && clock.age !== 'unknown');
  const fromReports = API.clocksFromReports(bundle, now);
  assert.ok(String(fromReports.lastOwnerAttempt.at).startsWith('2026-09-12T00:54:57'));
});

test('COMPLETED stripe from PROVEN invoke; WORKING not set from Bridge alone', () => {
  const idle = {
    receipt,
    reject,
    dashboard: { generated_at: new Date(now).toISOString(), current_task: null, services: { bridge: 'unknown' } },
    support: { generated_at: new Date(now).toISOString(), active_workers: { tick: 1, bridge: 1, supervisor: 0 } },
    engineering: { action: { ui_bridge: { task_present: false }, queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    bridge: { at: new Date(now).toISOString(), bridge: 'ok', puller: 'v1.6' }
  };
  const stripe = API.opsFloorStripe(idle, now);
  assert.strictEqual(stripe.stripe, 'COMPLETED');
  assert.strictEqual(stripe.skill, 'west-motor-parts-chase-board-pack@1');
  assert.ok(stripe.artifacts.length >= 2);
  assert.strictEqual(stripe.actor, 'MIXED');
  assert.strictEqual(stripe.working, false);
  assert.strictEqual(stripe.workingFromBridge, false);
  assert.strictEqual(API.mayShowWorkingBuilding(idle, now), false);
  assert.strictEqual(API.honestWorkerState('bridge', 'working', idle, now), 'ready');

  const live = {
    ...idle,
    support: { generated_at: new Date(now).toISOString(), active_workers: { supervisor: 1, tick: 0, bridge: 0 } }
  };
  assert.strictEqual(API.mayShowWorkingBuilding(live, now), true);
  assert.strictEqual(API.opsFloorStripe(live, now).workingFromBridge, false);
});

test('west-motor five-pack stays PROVEN — not failed PASS', () => {
  const pack = API.fivePackHonesty({ receipt });
  assert.strictEqual(pack.proven, true);
  assert.strictEqual(pack.paint, 'PROVEN');
  assert.strictEqual(pack.failedPass, false);
  assert.strictEqual(API.westMotorProven({ receipt }), true);
});

console.log(`\n${passed} tests passed`);
if (process.exitCode) {
  console.error('TEST SUITE FAILED');
  process.exit(process.exitCode);
}
console.log('TEST SUITE OK');
process.exit(0);
