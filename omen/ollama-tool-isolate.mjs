import { createHash, randomUUID } from 'node:crypto';
import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Fixed local endpoint and synthetic prompt. No tool execution, downloads,
// configuration changes, credentials or automatic publication.
export const MODELS = Object.freeze(['llama3.1:8b', 'qwen2.5:14b']);
const sha = value => createHash('sha256').update(value).digest('hex').toUpperCase();
const object = x => x !== null && typeof x === 'object' && !Array.isArray(x);
export function classify(response) {
  const calls = response?.message?.tool_calls;
  if (response?.done !== true) return 'INCOMPLETE_RESPONSE';
  if (!Array.isArray(calls) || calls.length === 0) return 'NO_STRUCTURED_TOOL_CALL';
  if (calls.length !== 1) return 'UNEXPECTED_CALL_COUNT';
  const fn = calls[0]?.function;
  if (fn?.name !== 'get_weather') return 'WRONG_TOOL';
  if (!object(fn.arguments) || Object.keys(fn.arguments).length !== 1 ||
      fn.arguments.city !== 'Preston Idaho') return 'INVALID_ARGUMENTS';
  return 'PASS';
}
async function request(path, body) {
  const response = await fetch('http://127.0.0.1:11434' + path, {
    method: body ? 'POST' : 'GET', redirect: 'error',
    headers: { 'Content-Type': 'application/json' },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(body ? 120000 : 10000),
  });
  if (!response.ok) throw new Error('HTTP_' + response.status);
  return response.json();
}
export async function probe(send = request) {
  const result = {
    schema: 1, kind: 'kevin-ollama-isolation-receipt',
    id: randomUUID(), generated_at: new Date().toISOString(),
    safe_for_public_repo: true, status: 'FAIL', api: 'native-/api/chat',
    models: [], tool_execution_attempted: false,
    truth_boundary: 'Structured model tool-call generation only. Does not prove OpenClaw dispatch, filesystem writes, desktop actions or autonomous work.',
  };
  let names;
  try {
    const tags = await send('/api/tags');
    if (!Array.isArray(tags.models)) throw new Error('INVALID_TAGS');
    names = tags.models.map(m => m.name);
  } catch {
    result.failure = 'OLLAMA_PREFLIGHT_FAILED'; return result;
  }
  // One inference request per installed model, sequentially. No retry loop.
  for (const model of MODELS) {
    if (!names.includes(model)) {
      result.models.push({ model, status: 'MODEL_NOT_INSTALLED' }); continue;
    }
    const start = Date.now();
    try {
      const response = await send('/api/chat', {
        model, stream: false, keep_alive: 0,
        options: { temperature: 0, num_ctx: 8192, num_predict: 256 },
        messages: [{ role: 'user', content: 'Call get_weather with city exactly "Preston Idaho". Do not answer in prose.' }],
        tools: [{ type: 'function', function: {
          name: 'get_weather', description: 'Get weather for a city',
          parameters: { type: 'object', properties: { city: { type: 'string' } }, required: ['city'], additionalProperties: false },
        } }],
      });
      result.models.push({ model, status: classify(response), duration_ms: Date.now() - start,
        response_sha256: sha(JSON.stringify(response)) });
    } catch {
      result.models.push({ model, status: 'REQUEST_FAILED_OR_TIMED_OUT', duration_ms: Date.now() - start });
    }
  }
  if (result.models.length === MODELS.length && result.models.every(m => m.status === 'PASS')) result.status = 'PASS';
  return result;
}
export async function saveReceipt(report, root) {
  await mkdir(root, { recursive: true });
  const history = join(root, 'ollama-isolate-' + report.id + '.json');
  const latest = join(root, 'ollama-isolate-latest.json');
  const stage = latest + '.' + randomUUID() + '.tmp';
  const bytes = JSON.stringify(report, null, 2) + '\n';
  await writeFile(history, bytes, { flag: 'wx' });
  await writeFile(stage, bytes, { flag: 'wx' });
  await rename(stage, latest);
  return latest;
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.length !== 2) throw new Error('This diagnostic accepts no arguments.');
  const report = await probe();
  report.source_sha256 = sha(await readFile(fileURLToPath(import.meta.url)));
  const target = await saveReceipt(report, join(homedir(), '.openclaw', 'workspace', 'reports'));
  console.log('Ollama isolation: ' + report.status);
  for (const m of report.models) console.log(m.model + ': ' + m.status);
  console.log('Receipt: ' + target);
  process.exitCode = report.status === 'PASS' ? 0 : 1;
}
