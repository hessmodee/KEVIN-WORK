const fs = require('fs');
const os = require('os');
const path = require('path');
const p = path.join(os.homedir(), '.openclaw', 'openclaw.json');
const c = JSON.parse(fs.readFileSync(p, 'utf8'));
c.agents ??= {};
c.agents.defaults ??= {};
c.agents.defaults.model = { primary: 'ollama/llama3.1:8b' };
c.agents.defaults.models ??= {};
c.agents.defaults.models['ollama/llama3.1:8b'] = {
  params: { extra_body: { tool_choice: 'required' } }
};
c.agents.defaults.sandbox = { ...(c.agents.defaults.sandbox || {}), mode: 'off' };
if (c.agents.defaults.memorySearch) c.agents.defaults.memorySearch.enabled = false;
c.tools ??= {};
c.tools.profile = 'coding';
c.tools.allow = ['group:fs', 'group:runtime', 'group:sessions'];
c.tools.exec = { ...(c.tools.exec || {}), security: 'full', ask: 'off' };
if (c.models?.providers?.ollama) {
  c.models.providers.ollama.baseUrl = 'http://127.0.0.1:11434';
  c.models.providers.ollama.api = 'ollama';
  c.models.providers.ollama.apiKey = c.models.providers.ollama.apiKey || 'ollama-local';
}
fs.writeFileSync(p, JSON.stringify(c, null, 2));
console.log('patched', p);
