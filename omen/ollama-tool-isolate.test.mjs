import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { classify, probe, saveReceipt, MODELS } from './ollama-tool-isolate.mjs';
const good = () => ({ done: true, message: { tool_calls: [{ function: { name: 'get_weather', arguments: { city: 'Preston Idaho' } } }] } });
test('only complete correctly shaped exact tool call passes', () => {
  assert.equal(classify(good()), 'PASS');
  assert.equal(classify(null), 'INCOMPLETE_RESPONSE');
  assert.equal(classify({ done: true, message: { content: 'PASS tool_calls get_weather' } }), 'NO_STRUCTURED_TOOL_CALL');
  for (const args of [null, [], '{"city":"Preston Idaho"}', {city:'Logan'}, {city:'Preston Idaho',command:'exec'}]) {
    const r = good(); r.message.tool_calls[0].function.arguments = args;
    assert.equal(classify(r), 'INVALID_ARGUMENTS');
  }
  const r = good(); r.message.tool_calls[0].function.name = 'exec';
  assert.equal(classify(r), 'WRONG_TOOL');
  r.message.tool_calls.push({}); assert.equal(classify(r), 'UNEXPECTED_CALL_COUNT');
});
test('both models required, sequential; calls never executed', async () => {
  let active = 0; const seen = [];
  const r = await probe(async (path, body) => {
    if (path === '/api/tags') return { models: MODELS.map(name => ({name})) };
    assert.equal(path, '/api/chat'); assert.equal(active++, 0);
    await new Promise(resolve => setTimeout(resolve, 1));
    seen.push(body.model); assert.equal(body.keep_alive, 0); active--;
    return good();
  });
  assert.deepEqual(seen, MODELS); assert.equal(r.status, 'PASS');
  assert.equal(r.tool_execution_attempted, false);
  assert.equal(JSON.stringify(r).includes('tool_calls'), false);
});
test('missing second model fails without pulling it', async () => {
  const r = await probe(async path => path === '/api/tags' ? {models:[{name:MODELS[0]}]} : good());
  assert.equal(r.status, 'FAIL'); assert.equal(r.models[1].status, 'MODEL_NOT_INSTALLED');
});
test('failure still records second result; raw errors excluded', async () => {
  let calls = 0;
  const r = await probe(async path => {
    if (path === '/api/tags') return {models:MODELS.map(name=>({name}))};
    if (calls++ === 0) throw new Error('PRIVATE_SERVER_ERROR');
    return good();
  });
  assert.equal(r.status, 'FAIL'); assert.equal(r.models[1].status, 'PASS');
  assert.equal(JSON.stringify(r).includes('PRIVATE'), false);
});
test('failed preflight produces failure receipt', async () => {
  const r = await probe(async () => { throw new Error('private'); });
  assert.equal(r.status, 'FAIL'); assert.equal(r.failure, 'OLLAMA_PREFLIGHT_FAILED');
});
test('new failure replaces latest PASS, preserves history', async () => {
  const root = await mkdtemp(join(tmpdir(), 'kevin-isolate-'));
  try {
    await saveReceipt({id:'first',status:'PASS'},root);
    const latest = await saveReceipt({id:'second',status:'FAIL'},root);
    assert.equal(JSON.parse(await readFile(latest)).status,'FAIL');
    assert.equal(JSON.parse(await readFile(join(root,'ollama-isolate-first.json'))).status,'PASS');
  } finally { await rm(root,{recursive:true,force:true}); }
});
