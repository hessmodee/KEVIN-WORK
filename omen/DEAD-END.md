# extra_body.tool_choice is a silent no-op on native Ollama

Prescribed by earlier OpenClaw local-models docs and copied into the Kevin handoff. It does not apply to `api: "ollama"`.

## Source

`src/agents/embedded-agent-runner/extra-params.ts` — `createOpenAICompletionsExtraBodyWrapper`:

```ts
if (model.api !== "openai-completions") {
  return underlying(model, context, options);
}
```

`extensions/ollama/src/stream.runtime.ts`:

```ts
const OLLAMA_OPTION_PARAM_KEYS = new Set([
  "num_keep", "seed", "num_predict", "top_k", "top_p", "min_p",
  "typical_p", "repeat_last_n", "temperature", "repeat_penalty",
  "presence_penalty", "frequency_penalty", "stop", "num_ctx",
  "num_batch", "num_gpu", "main_gpu", "use_mmap", "num_thread",
]);

const OLLAMA_TOP_LEVEL_PARAM_KEYS = new Set([
  "format", "keep_alive", "truncate", "shift",
]);
```

`tool_choice` is not in either set. `buildOllamaChatRequest` never adds it.

## What does reach Ollama

- `params.temperature`
- `params.num_ctx`
- `params.keep_alive` (top-level)
- `agents.defaults.experimental.localModelLean` (OpenClaw-side catalog, not an Ollama field)

## What to do instead

1. `omen/ollama-tool-test.ps1` — prove whether the model emits `tool_calls`.
2. `omen/apply-lean.js` — shrink the catalog and set temperature 0 / num_ctx 8192.
3. Disk-prove write and exec.

Do not restart the gateway solely to apply extra_body.tool_choice.
