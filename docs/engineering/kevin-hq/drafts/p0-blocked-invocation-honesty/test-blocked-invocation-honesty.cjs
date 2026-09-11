#!/usr/bin/env node
'use strict';
const fs = require('fs');
const path = require('path');

/** Known public failure_sha256 prefix → INVOCATION_WORKER_FAILED (Self-Reliance Bridge Recovery v1). */
const WORKER_FAILED_PREFIXES = ['68845506'];

function mapsToInvocationWorkerFailed(sha) {
  const s = String(sha || '').toLowerCase();
  if (!s) return false;
  return WORKER_FAILED_PREFIXES.some((p) => s.startsWith(p.toLowerCase()));
}

/**
 * Pure invocation honesty — keep in sync with DESIGN.md
 * Isolated STAGE_OK ≠ Action Era ≠ PASS.
 */
function invocationHonesty(i) {
  const status = String(i.continuationStatus || '').toUpperCase();
  const workerFailed =
    mapsToInvocationWorkerFailed(i.failureSha256) ||
    /INVOCATION_WORKER_FAILED/i.test(String(i.rejectReason || ''));
  const blockedInvocation = /BLOCKED_INVOCATION/.test(status) || workerFailed;
  const stageOkWaiting = /STAGE_OK_WAITING|WAITING_ACTION_ERA/.test(status) || /^WAITING_/.test(status);
  const blockedFamily = /^(BLOCKED|NEEDS_|DEFERRED|COOLDOWN)/.test(status);

  let paint, cls, stateLabel;
  if (blockedInvocation) {
    paint = 'BLOCKED';
    cls = 'bad';
    stateLabel = 'BLOCKED';
  } else if (stageOkWaiting) {
    paint = 'WAITING';
    cls = 'warn';
    stateLabel = 'BLOCKED · waiting';
  } else if (blockedFamily) {
    paint = 'BLOCKED';
    cls = 'warn';
    stateLabel = 'BLOCKED';
  } else {
    paint = 'READY';
    cls = 'ok';
    stateLabel = status === 'READY' || status === '' ? 'READY' : status || 'READY';
  }

  let reasonChip = '';
  if (i.stickyRequestIdFamily) {
    reasonChip = 'sticky · ' + String(i.stickyRequestIdFamily).slice(0, 40);
  } else if (blockedInvocation || workerFailed) {
    reasonChip = 'worker exit · fail-closed';
  } else if (stageOkWaiting) {
    reasonChip = 'STAGE_OK · wait Supervisor';
  } else if (i.rejectReason) {
    reasonChip = String(i.rejectReason).slice(0, 48);
  } else if (paint !== 'READY') {
    reasonChip = 'fail-closed';
  }

  const celebrate = paint === 'READY';
  const isPass = false; // HQ never claims PASS from continuation alone; west-motor needs workbook+receipt
  const note =
    paint === 'WAITING'
      ? 'Isolated STAGE_OK ≠ Action Era ≠ PASS — wait Supervisor; do not celebrate.'
      : paint === 'BLOCKED'
        ? 'Invoke fail-closed — paint BLOCKED, no READY/DEGRADED-as-ok, no celebration.'
        : 'Healthy continuation surface — still not owner PASS without receipt.';

  return { paint, cls, stateLabel, reasonChip, celebrate, isPass, note };
}

const fixDir = path.join(__dirname, 'fixtures');
const files = fs.readdirSync(fixDir).filter((f) => f.endsWith('.json')).sort();
let n = 0;
for (const f of files) {
  const fx = JSON.parse(fs.readFileSync(path.join(fixDir, f), 'utf8'));
  const got = invocationHonesty(fx.input);
  const exp = fx.expect;
  const checks = [
    ['paint', got.paint, exp.paint],
    ['cls', got.cls, exp.cls],
    ['stateLabel', got.stateLabel, exp.stateLabel],
    ['celebrate', got.celebrate, exp.celebrate],
    ['isPass', got.isPass, exp.isPass],
  ];
  for (const [k, a, b] of checks) {
    if (a !== b) {
      console.error('FAIL', fx.name, k, 'got', a, 'want', b, got);
      process.exit(1);
    }
  }
  for (const frag of exp.reasonIncludes || []) {
    if (!String(got.reasonChip).includes(frag)) {
      console.error('FAIL', fx.name, 'reasonChip missing', frag, got.reasonChip);
      process.exit(1);
    }
  }
  for (const frag of exp.noteIncludes || []) {
    if (!String(got.note).includes(frag)) {
      console.error('FAIL', fx.name, 'note missing', frag, got.note);
      process.exit(1);
    }
  }
  // Honesty: never READY paint under blocked/waiting families
  if (fx.name !== 'HEALTHY_READY' && got.paint === 'READY') {
    console.error('FAIL honesty', fx.name, 'READY under blocked/waiting');
    process.exit(1);
  }
  if (got.paint !== 'READY' && got.celebrate) {
    console.error('FAIL honesty', fx.name, 'celebration under non-READY');
    process.exit(1);
  }
  if (got.cls === 'ok' && got.paint !== 'READY') {
    console.error('FAIL honesty', fx.name, 'DEGRADED-as-ok');
    process.exit(1);
  }
  n++;
}
console.log('PASS', n, 'fixtures');
