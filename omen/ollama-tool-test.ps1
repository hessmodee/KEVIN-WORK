# Tests both local models and records the receipt required by CURRENT_TASK.
# Does not change OpenClaw config or execute model tool calls.
$ErrorActionPreference = 'Stop'
$diagnostic = Join-Path $PSScriptRoot 'ollama-tool-isolate.mjs'
if (-not (Test-Path -LiteralPath $diagnostic -PathType Leaf)) {
    throw 'Missing ollama-tool-isolate.mjs beside this script. Use the complete repository version.'
}
& node $diagnostic
exit $LASTEXITCODE
