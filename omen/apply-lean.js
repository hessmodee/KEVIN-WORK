const fs = require('fs');
const os = require('os');
const path = require('path');
const p = path.join(os.homedir(), '.openclaw', 'openclaw.json');
const c = JSON.parse(fs.readFileSync(p, 'utf8'));
c.agents ??= {};
c.agents.defaults ??= {};
c.agents.defaults.model = { primary: 'ollama/llama3.1:8b' };
c.agents.defaults.experimental = {
  ...(c.agents.defaults.experimental || {}),
  localModelLean: true
};
c.agents.defaults.sandbox = { ...(c.agents.defaults.sandbox || {}), mode: 'off' };
if (c.agents.defaults.memorySearch) c.agents.defaults.memorySearch.enabled = false;
c.agents.defaults.heartbeat = { ...(c.agents.defaults.heartbeat || {}), every: '15m' };
c.agents.defaults.models ??= {};
// extra_body.tool_choice is a no-op on api: ollama. Do not set it.
c.agents.defaults.models['ollama/llama3.1:8b'] = {
  params: { temperature: 0, num_ctx: 8192 }
};
c.tools ??= {};
c.tools.profile = 'coding';
c.tools.allow = ['group:fs', 'group:runtime', 'group:sessions'];
c.tools.exec = { ...(c.tools.exec || {}), security: 'full', ask: 'off' };
if (c.models && c.models.providers && c.models.providers.ollama) {
  c.models.providers.ollama.baseUrl = 'http://127.0.0.1:11434';
  c.models.providers.ollama.api = 'ollama';
  c.models.providers.ollama.apiKey = c.models.providers.ollama.apiKey || 'ollama-local';
}
fs.writeFileSync(p, JSON.stringify(c, null, 2));
console.log('patched', p);
console.log('lean', c.agents.defaults.experimental.localModelLean);
console.log('model', JSON.stringify(c.agents.defaults.model));
console.log('params', JSON.stringify(c.agents.defaults.models['ollama/llama3.1:8b']));
