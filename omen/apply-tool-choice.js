// SUPERSEDED. extra_body.tool_choice never reaches native Ollama.
// This file now runs the lean patch so old handoff steps cannot re-apply a no-op.
console.warn('apply-tool-choice.js is a no-op path. Running apply-lean.js instead.');
require('./apply-lean.js');
