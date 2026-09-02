# Fixed-main authored tool-policy diagnostic

Candidate only. No install or production tool grant is performed by these files.

The Python classifier summarizes supplied config. The Windows collector reads the
fixed local OpenClaw config, requires 2026.7.1-2, and runs only fixed config
validation and `sandbox explain --agent main --json` probes. It emits bounded
metadata, counts and hashes rather than raw configuration or unknown tool names.

## Repair transferred from the September 2 CI incident

Failure family: `powershell_policy_collection_shape`. A function returning a
one-element array emits its element by default; a zero-element array emits no
object. Preserve array values with unary comma at every helper return boundary,
and serialize with `ConvertTo-Json -InputObject` to retain JSON array shape.
Do not relax the validator to accept strings just to make a valid singleton pass.

The self-test exercises parsed JSON with missing, empty, one-item and multi-item
lists, malformed scalar/object/item inputs, singleton agent lists and stable JSON
array hashes. Run it with Windows PowerShell 5.1 before a machine crossing.

Exact upstream source also showed that model-specific `byProvider` entries precede
provider-wide entries; both implementations and regression fixtures preserve that
order. Unknown sandbox values are represented as OTHER, never echoed publicly.

## Limits and required next proof

These are authored-policy observations, not a reimplementation of the complete
effective tool resolver. Provider aliases/case normalization, wildcard groups,
default sandbox inheritance, channel/sender/plugin gates and actual per-turn
inventory still need installed-runtime evidence. `known_control_allowed` means
literal authored membership only; it does not certify safety or grant authority.
`read` and session-history tools may expose private data unless separately scoped.
An empty authored allow list is not proof that a runtime exposes no tools.

Production use requires a registered fixed read-only bridge operation. The
installed Maintenance source must be recovered before modifying that runner.
After diagnosis, any tool grant must have separate exact preconditions, backup,
negative tests and actual allowed-task proof, followed by Benchmark and rollback
where applicable. No T4/T5 or model-learning claim follows from passing CI.

Sources checked September 2, 2026:
- https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_return
- https://github.com/openclaw/openclaw/blob/v2026.7.1-2/src/agents/provider-tool-policy.ts
- https://docs.openclaw.ai/gateway/config-tools
