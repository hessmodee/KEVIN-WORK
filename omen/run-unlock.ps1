# Kevin unlock — one script. No secrets.
# Tests llama3.1:8b (qwen2.5:14b if llama fails), applies localModelLean,
# restarts gateway, uploads JSON to hessmodee/KEVIN-WORK if gh is logged in.
$ErrorActionPreference = 'Stop'

function Test-OllamaTools([string]$model) {
  $bodyObj = @{
    model = $model
    stream = $false
    options = @{ temperature = 0 }
    messages = @(@{ role = "user"; content = "Call get_weather for Preston Idaho. Do not answer in prose." })
    tools = @(@{
      type = "function"
      function = @{
        name = "get_weather"
        description = "Get weather for a city"
        parameters = @{
          type = "object"
          properties = @{ city = @{ type = "string" } }
          required = @("city")
        }
      }
    })
  }
  $body = $bodyObj | ConvertTo-Json -Depth 12
  $res = Invoke-RestMethod -Uri http://127.0.0.1:11434/api/chat -Method POST -Body $body -ContentType "application/json"
  $calls = @($res.message.tool_calls)
  $ok = $calls.Count -gt 0 -and $calls[0]
  $preview = [string]$res.message.content
  if ($preview.Length -gt 180) { $preview = $preview.Substring(0, 180) }
  $label = if ($ok) { "PASS" } else { "FAIL" }
  Write-Host "==== $model $label tool_calls=$($calls.Count) ===="
  [pscustomobject]@{
    model = $model
    verdict = $(if ($ok) { 'PASS' } else { 'FAIL' })
    toolCallCount = $(if ($ok) { $calls.Count } else { 0 })
    contentPreview = $preview
  }
}

$rows = @()
$rows += Test-OllamaTools "llama3.1:8b"
if ($rows[-1].verdict -eq "FAIL") {
  try { $rows += Test-OllamaTools "qwen2.5:14b" } catch { Write-Host "qwen2.5:14b skipped: $_" }
}

$js = @'
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
'@
Set-Content -Encoding utf8 "$env:TEMP\kevin-lean-patch.js" -Value $js
node "$env:TEMP\kevin-lean-patch.js"
openclaw config validate
openclaw gateway restart

$report = @{
  at = (Get-Date).ToString("o")
  host = $env:COMPUTERNAME
  leanApplied = $true
  models = @($rows | ForEach-Object {
    @{
      model = $_.model
      verdict = $_.verdict
      toolCallCount = $_.toolCallCount
      contentPreview = $_.contentPreview
    }
  })
}
$json = $report | ConvertTo-Json -Depth 6
$outDir = Join-Path $env:USERPROFILE ".openclaw\workspace\reports"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Set-Content -Encoding utf8 -Path (Join-Path $outDir "ollama-isolate-latest.json") -Value $json
Write-Host "==== COPY THIS JSON INTO KEVIN HQ UNLOCK ===="
Write-Host $json

function Push-KevinReport([string]$payload) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "gh not on PATH — paste the JSON into Unlock. Do not paste tokens."
    return
  }
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))
  $api = "repos/hessmodee/KEVIN-WORK/contents/reports/ollama-isolate-latest.json"
  $sha = $null
  try { $sha = gh api $api --jq .sha 2>$null } catch {}
  if ($sha) {
    gh api --method PUT $api -f message="omen isolate report" -f content=$b64 -f sha=$sha | Out-Null
  } else {
    gh api --method PUT $api -f message="omen isolate report" -f content=$b64 | Out-Null
  }
  Write-Host "Uploaded reports/ollama-isolate-latest.json — that is the bridge."
}
Push-KevinReport $json
