#!/usr/bin/env node
'use strict';
/** Compact P0 OPS FLOOR painter honesty smoke (CI). */
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const ROOT = path.resolve(__dirname, '../..');
function loadPainterApi() {
  const source = path.join(ROOT, 'docs/ops/hq-p0-floor-painter-v1.source.js');
  if (fs.existsSync(source)) return require(source);
  const parts = [];
  for (let i = 1; i <= 16; i++) {
    const id = String(i).padStart(2, '0');
    parts.push(fs.readFileSync(path.join(ROOT, `docs/hq-p0-floor-painter-v1.b64.${id}.txt`), 'utf8'));
  }
  const code = Buffer.from(parts.join('').replace(/\s+/g, ''), 'base64').toString('utf8');
  const tmp = path.join(__dirname, '.hq-p0-floor-painter-rebuilt.js');
  fs.writeFileSync(tmp, code);
  return require(tmp);
}
const API = loadPainterApi();
const FIX = path.join(__dirname, 'fixtures');
const load = (n) => JSON.parse(fs.readFileSync(path.join(FIX, n), 'utf8'));
const now = Date.parse('2026-09-12T02:30:00Z');
let passed = 0;
function test(name, fn) {
  try { fn(); passed += 1; console.log('PASS', name); }
  catch (e) { console.error('FAIL', name); console.error(e && e.stack || e); process.exitCode = 1; }
}
const receipt = load('west-motor-invoke-receipt.json');
const rejectProven = load('reject-west-motor-proven.json');

test('THROTTLED on WAITING_ITEM_BUDGETS', () => {
  const c = API.floorCenterState({
    floor: load('hq-live-floor-throttled-waiting-budgets.json'),
    continuation: load('continuation-waiting-item-budgets.json'),
    support: { generated_at: '2026-09-12T02:00:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, supervisor: { cycle: 12 }, active_workers: {} },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    receipt, reject: rejectProven
  }, now);
  assert.strictEqual(c.label, 'THROTTLED');
  assert.notStrictEqual(c.label, 'READY');
  assert.notStrictEqual(c.label, 'WORKING');
});

test('ready>=1 → WORKING', () => {
  const c = API.floorCenterState({
    floor: load('hq-live-floor-ready-working.json'),
    continuation: load('continuation-transport-routed.json'),
    engineering: load('engineering-ready-2.json'),
    invokeReady: load('invoke-ready-2.json'),
    support: { generated_at: '2026-09-12T02:30:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, active_workers: {} },
    receipt, reject: { ...rejectProven, live_action_era_ready_invoke_count: 2 }
  }, now);
  assert.strictEqual(c.label, 'WORKING');
  assert.notStrictEqual(c.label, 'READY');
});

test('Bridge stale alone ≠ WORKING', () => {
  const c = API.floorCenterState({
    bridge: load('bridge-stale-alone.json'),
    continuation: { status: 'IDLE_NO_ELIGIBLE_DEMAND', generated_at: '2026-09-12T02:30:00Z' },
    support: { generated_at: '2026-09-12T02:30:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, active_workers: { tick: 1, bridge: 1, supervisor: 0 } },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 }, ui_bridge: { heartbeat_age_seconds: 9999 } } },
    receipt, reject: rejectProven
  }, now);
  assert.notStrictEqual(c.label, 'WORKING');
  assert.strictEqual(c.neverBridgeCoupled, true);
});

test('transport COMPLETED stripe MIXED; ready=0 ≠ WORKING', () => {
  const bundle = {
    floor: load('hq-live-floor-transport-completed.json'),
    continuation: { status: 'OUTCOME_PROVEN', outcome_proven: true, version: '1.8.12', selected_id: 'owner-west-motor-transport-dispatch-template-v1', generated_at: '2026-09-11T20:36:25Z' },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    support: { generated_at: '2026-09-11T20:36:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, active_workers: {} },
    receipt, reject: { outcome_proven: true, verify_actor: 'MIXED', receipt_status: 'PROVEN', work_id_hint: 'owner-west-motor-transport-dispatch-template-v1', live_action_era_ready_invoke_count: 0 },
    selection: { id: 'owner-west-motor-transport-dispatch-template-v1' }
  };
  const stripe = API.completedStripe(bundle);
  assert.strictEqual(stripe.show, true);
  assert.strictEqual(stripe.transportCompleted, true);
  assert.strictEqual(stripe.westMotorRetained, true);
  assert.notStrictEqual(API.floorCenterState(bundle, now).label, 'WORKING');
});

test('tools canary stays stale until fresh', () => {
  const chip = API.toolsCanary({ canary: load('main-agent-canary-omen.json') }, now);
  assert.ok(chip.stale);
});

test('scaffold never KEVIN_ACTED', () => {
  const sc = API.scaffoldPulse({
    scaffold: load('scaffold-heartbeat-fresh.json'),
    continuation: { status: 'IDLE_NO_ELIGIBLE_DEMAND', generated_at: '2026-09-12T02:30:00Z' },
    support: { generated_at: '2026-09-12T02:30:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, active_workers: {} },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } }
  }, now);
  assert.strictEqual(sc.actor, 'GROKBOT_ACTED');
  assert.notStrictEqual(sc.actor, 'KEVIN_ACTED');
});


test('skill_lab GAP → center GAP', () => {
  const c = API.floorCenterState({
    floor: load('hq-live-floor-skill-lab-gap.json'),
    continuation: { status: 'IDLE_NO_ELIGIBLE_DEMAND', generated_at: '2026-09-12T03:05:00Z' },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    support: { generated_at: '2026-09-12T03:05:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, active_workers: {} },
    receipt, reject: rejectProven
  }, now);
  assert.strictEqual(c.label, 'GAP');
  assert.strictEqual(c.skillLab.chrome, 'GAP');
  assert.notStrictEqual(c.label, 'WORKING');
  assert.notStrictEqual(c.label, 'READY');
});
test('skill_lab LAB when running/ready > 0', () => {
  const c = API.floorCenterState({
    floor: load('hq-live-floor-skill-lab-lab.json'),
    continuation: { status: 'IDLE_NO_ELIGIBLE_DEMAND', generated_at: '2026-09-12T03:05:00Z' },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    support: { generated_at: '2026-09-12T03:05:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, active_workers: {} },
    receipt, reject: rejectProven
  }, now);
  assert.strictEqual(c.label, 'LAB');
  assert.ok(c.skillLab.running_count >= 1 || c.skillLab.ready_count >= 1);
  assert.notStrictEqual(c.label, 'WORKING');
});
test('skill_lab PROVE promote-to-registry pending', () => {
  const c = API.floorCenterState({
    floor: load('hq-live-floor-skill-lab-prove.json'),
    continuation: { status: 'IDLE_NO_ELIGIBLE_DEMAND', generated_at: '2026-09-12T03:05:00Z' },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    support: { generated_at: '2026-09-12T03:05:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, active_workers: {} },
    receipt, reject: rejectProven
  }, now);
  assert.strictEqual(c.label, 'PROVE');
  assert.strictEqual(c.skillLab.provePending, true);
  assert.notStrictEqual(c.label, 'READY');
});


test('painted_hint VERIFYING refuses READY (hq-live-floor first)', () => {
  const c = API.floorCenterState({
    floor: {
      schema: 'kevin.hq-live-floor.v1',
      cycle: 5,
      status: 'OUTCOME_PROVEN',
      outcome_proven: true,
      painted_hint: 'VERIFYING',
      waiting_item_budgets: false,
      action_era_ready_count: 0,
      selected_id: 'owner-west-motor-transport-dispatch-template-v1',
      supervisor_sha256: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB',
      supervisor_version: '1.8.12'
    },
    continuation: { status: 'ROUTED_TO_PROVEN_SKILL_INVOCATION', generated_at: '2026-09-12T03:05:00Z', selected_id: 'owner-west-motor-transport-dispatch-template-v1' },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    support: { generated_at: '2026-09-12T03:05:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, supervisor: { cycle: 449 }, active_workers: {} },
    receipt, reject: { ...rejectProven, outcome_proven: true, verify_actor: 'MIXED' }
  }, now);
  assert.strictEqual(c.label, 'VERIFYING');
  assert.notStrictEqual(c.label, 'READY');
});


test('painted_hint THROTTLED + skill_lab GAP refuses READY', () => {
  const c = API.floorCenterState({
    floor: {
      schema: 'kevin.hq-live-floor.v1',
      cycle: 450,
      status: 'OUTCOME_PROVEN',
      outcome_proven: true,
      center: 'THROTTLED',
      center_status: 'THROTTLED',
      painted_hint: 'THROTTLED',
      waiting_item_budgets: true,
      throttled: true,
      action_era_ready_count: 0,
      selected_id: 'owner-west-motor-transport-dispatch-template-v1',
      supervisor_sha256: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB',
      supervisor_version: '1.8.12',
      skill_lab: { stage: 'GAP', failed_count: 5, ready_count: 0, running_count: 0, required_skill_key_missing: true }
    },
    continuation: { status: 'WAITING_ITEM_BUDGETS', waiting_item_budgets: true, generated_at: '2026-09-12T03:28:00Z' },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    support: { generated_at: '2026-09-12T03:28:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, supervisor: { cycle: 450 }, active_workers: {} },
    receipt, reject: { ...rejectProven, outcome_proven: true, verify_actor: 'MIXED' }
  }, now);
  assert.strictEqual(c.label, 'THROTTLED');
  assert.notStrictEqual(c.label, 'READY');
  assert.notStrictEqual(c.label, 'GAP'); // throttle beats GAP for center when published THROTTLED
});


test('painted_hint COMPLETED refuses READY (stripe owns COMPLETED)', () => {
  const c = API.floorCenterState({
    floor: {
      schema: 'kevin.hq-live-floor.v1',
      cycle: 450,
      painted_hint: 'COMPLETED',
      center: 'COMPLETED',
      outcome_proven: true,
      action_era_ready_count: 0,
      selected_id: 'owner-west-motor-transport-dispatch-template-v1',
      supervisor_sha256: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB',
      supervisor_version: '1.8.12'
    },
    continuation: { generated_at: '2026-09-12T03:40:00Z' },
    engineering: { action: { queues: { ready: 0 }, composite_skills: { ready: 0 } } },
    support: { generated_at: '2026-09-12T03:40:00Z', hashes: { supervisor: 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB' }, supervisor: { cycle: 450 }, active_workers: {} },
    receipt, reject: { ...rejectProven, outcome_proven: true, verify_actor: 'MIXED' }
  }, now);
  assert.notStrictEqual(c.label, 'READY');
  assert.notStrictEqual(c.label, 'COMPLETED');
});

console.log(`\n${passed} tests passed`);
if (process.exitCode) { console.error('TEST SUITE FAILED'); process.exit(process.exitCode); }
console.log('TEST SUITE OK');
process.exit(0);
