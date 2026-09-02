'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../..');
const read = name => fs.readFileSync(path.join(root, name), 'utf8');

function overviewFrame(html) {
  const frames = [...html.matchAll(/<iframe\b[^>]*>/gi)]
    .map(match => match[0])
    .filter(tag => /\bid\s*=\s*(['"])kevinCore\1/i.test(tag));
  assert.equal(frames.length, 1, 'exactly one Kevin core iframe');
  const source = frames[0].match(/\bsrc\s*=\s*(['"])(.*?)\1/i);
  assert.ok(source, 'core iframe has an explicit source');
  const url = new URL(source[2], 'https://hq.invalid/');
  assert.equal(url.origin, 'https://hq.invalid', 'core remains same-origin');
  assert.equal(url.pathname, '/hq-core-v7.html', 'core uses v7');
  assert.equal(url.hash, '#overview', 'core starts at overview');
}

assert.ok(read('docs/hq-core-v7.html').length, 'core exists and is nonempty');
overviewFrame(read('docs/index.html'));
for (const source of ['./hq-core-v7.html#overview', './hq-core-v7.html?v=9#overview']) {
  overviewFrame(`<iframe id="kevinCore" src="${source}"></iframe>`);
}
for (const source of ['./hq-core-v7.html#other', './other.html#overview', 'https://elsewhere.invalid/hq-core-v7.html#overview']) {
  assert.throws(() => overviewFrame(`<iframe id="kevinCore" src="${source}"></iframe>`));
}
assert.throws(() => overviewFrame('<iframe src="./hq-core-v7.html#overview"></iframe>'));
assert.throws(() => overviewFrame('<iframe id="kevinCore"></iframe>'));

const overlay = read('docs/ops/ops-truth-patch-v1.js');
const now = Date.now();
const healthy = () => ({
  dashboard: {generated_at: new Date(now).toISOString(), health: {overall: 'healthy'}},
  support: {
    generated_at: new Date(now).toISOString(), governance: {ok: true},
    active_workers: {},
    cron: {jobs: [{declaration_key: 'kevin-supervisor-v1', enabled: true, last_status: 'ok'}]},
  },
});

async function classify(fixture) {
  let refresh;
  const window = {top: {postMessage() {}}};
  const context = {
    window, Date, location: {origin: 'https://hq.invalid'},
    document: {getElementById() {return null;}},
    addEventListener() {}, setTimeout() {},
    setInterval(callback) {refresh = callback;},
    fetch: async url => {
      const filename = new URL(url).pathname.split('/').pop();
      assert.ok(['dashboard-state.json', 'support-latest.json'].includes(filename));
      return {ok: true, json: async () => filename === 'dashboard-state.json' ? fixture.dashboard : fixture.support};
    },
  };
  vm.runInNewContext(overlay, context, {timeout: 1000});
  assert.equal(typeof refresh, 'function', 'overlay installs its refresh');
  await refresh();
  assert.ok(window.__kevinTruth, 'real overlay publishes a status');
  return Array.from(window.__kevinTruth.states);
}

(async () => {
  const cases = [
    ['healthy idle scheduler', () => {}, ['ARMED']],
    ['completed task is idle', f => {f.dashboard.current_task = {phase: 'complete'};}, ['ARMED']],
    ['active supervisor', f => {f.support.active_workers.supervisor = 1;}, ['WORKING']],
    ['active builder', f => {f.support.active_workers.design_forge = 1;}, ['BUILDING']],
    ['both active', f => {f.support.active_workers = {supervisor: 1, design_forge: 1};}, ['BUILDING', 'WORKING']],
    ['governance failure', f => {f.support.governance.ok = false;}, ['DEGRADED']],
    ['cooldown', f => {f.support.supervisor = {last_result: 'WAIT'};}, ['COOLDOWN']],
    ['no scheduler', f => {f.support.cron.jobs = [];}, ['READY']],
    ['stale evidence', f => {f.dashboard.generated_at = f.support.generated_at = new Date(now - 7200000).toISOString();}, ['OFFLINE']],
  ];
  for (const [name, modify, expected] of cases) {
    const fixture = healthy();
    modify(fixture);
    assert.deepEqual(await classify(fixture), expected, name);
  }
  console.log('PASS HQ overview destination and 9 real-overlay status scenarios');
})().catch(error => {console.error(error); process.exitCode = 1;});
