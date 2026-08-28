$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding $false

$homeDir = $env:USERPROFILE
$prod = Join-Path $homeDir ".openclaw"
$prodCfg = Join-Path $prod "openclaw.json"
$state = Join-Path $homeDir ".openclaw-reader"
$cfg = Join-Path $state "openclaw.json"
$ws = Join-Path $state "workspace"
$reports = Join-Path $ws "reports"
$ext = Join-Path $state "extensions\kevin-core"
$freeze = Join-Path $prod "extensions\kevin-core-v0.1.0-green"
$wrapper = Join-Path $state "start-reader-gateway.cmd"
$artifact = Join-Path $reports "reader-install-latest.json"
$port = 19001
$script:ProdShaBefore = $null
$script:FreezeManifestSha = $null
$script:FreezeIndexSha = $null
$script:FreezeCollectSha = $null
$script:FreezeTests = "FAIL"
$script:VisibleTools = @()
$script:PongText = ""
$script:PongCalls = -1
$script:PongStatus = ""

function Require-Ok($name) {
  if ($null -eq $LASTEXITCODE) { throw "STOP: $name left LASTEXITCODE null" }
  if ($LASTEXITCODE -ne 0) { throw "STOP: $name failed ($LASTEXITCODE)" }
}

function Set-ReaderEnv {
  $env:OPENCLAW_PROFILE = "reader"
  $env:OPENCLAW_STATE_DIR = $state
  $env:OPENCLAW_CONFIG_PATH = $cfg
  $env:OPENCLAW_ALLOW_MULTI_GATEWAY = "1"
  $env:OPENCLAW_GATEWAY_PORT = "$port"
}

function Test-PortOpen([int]$p) {
  try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", $p)
    $tcp.Close()
    return $true
  } catch {
    return $false
  }
}

function Write-InstallReport([string]$overall, [string]$errorText) {
  New-Item -ItemType Directory -Force -Path $reports | Out-Null
  $shaAfter = $null
  $unchanged = $false
  if (Test-Path $prodCfg) {
    $shaAfter = (Get-FileHash $prodCfg -Algorithm SHA256).Hash
    $unchanged = ($script:ProdShaBefore -eq $shaAfter)
  }
  $obj = [ordered]@{
    overall = $overall
    at = (Get-Date).ToString("o")
    fail_kind = $(if ($overall -eq "PASS") { $null } else { "FAIL" })
    error = $errorText
    prod_config_sha_before = $script:ProdShaBefore
    prod_config_sha_after = $shaAfter
    prod_config_unchanged = $unchanged
    reader_state = ".openclaw-reader"
    reader_workspace = ".openclaw-reader/workspace"
    gateway_port = $port
    plugins_allow = @("ollama", "kevin-core")
    tools_allow = @("kevin_system_status")
    freeze_tests = $script:FreezeTests
    freeze_manifest_sha = $script:FreezeManifestSha
    freeze_index_sha = $script:FreezeIndexSha
    freeze_collect_sha = $script:FreezeCollectSha
    visible_tools = @($script:VisibleTools)
    pong_status = $script:PongStatus
    pong_text = $script:PongText
    pong_calls = $script:PongCalls
  }
  $json = ($obj | ConvertTo-Json -Depth 6)
  [IO.File]::WriteAllText($artifact, $json + "`n", $utf8)
  Write-Host "wrote install artifact"
}

if (-not (Test-Path $freeze)) { throw "STOP: missing frozen plugin" }
if (-not (Test-Path $prodCfg)) { throw "STOP: missing production config" }
if ($cfg -notmatch "openclaw-reader") { throw "STOP: refusing to write non-reader config" }

try {
  Write-Host "===== 0) production hash + freeze verify ====="
  $script:ProdShaBefore = (Get-FileHash $prodCfg -Algorithm SHA256).Hash
  Write-Host "prod sha before recorded"

  $manifest = Join-Path $freeze "openclaw.plugin.json"
  if (-not (Test-Path $manifest)) { throw "STOP: freeze missing openclaw.plugin.json" }
  $man = Get-Content $manifest -Raw | ConvertFrom-Json
  $mtools = @($man.contracts.tools)
  if ($mtools.Count -ne 1 -or $mtools[0] -ne "kevin_system_status") {
    throw "STOP: freeze manifest tools were not exactly kevin_system_status"
  }
  $script:FreezeManifestSha = (Get-FileHash $manifest -Algorithm SHA256).Hash
  $script:FreezeIndexSha = (Get-FileHash (Join-Path $freeze "src\index.ts") -Algorithm SHA256).Hash
  $script:FreezeCollectSha = (Get-FileHash (Join-Path $freeze "src\collect.ts") -Algorithm SHA256).Hash

  Push-Location $freeze
  try {
    npm test
    Require-Ok "freeze npm test"
    $script:FreezeTests = "PASS"
  } finally {
    Pop-Location
  }
  Write-Host "freeze tests PASS; manifest is kevin_system_status only"

  Write-Host "===== 1) dirs ====="
  New-Item -ItemType Directory -Force -Path $ws, $reports, (Join-Path $state "extensions") | Out-Null

  Write-Host "===== 2) workspace files ====="
  $files = @{
    "AGENTS.md" = @"
# Operating rules
You are Kevin in Reader mode.
You have exactly one tool: kevin_system_status.
Call it at most once per question, and only for machine/health questions.
Never invent tools. Never use exec, write, edit, browser, or sessions.
If the tool fails, say FAIL in one short sentence and stop.
Never overwrite production memory/ or reports/.
"@
    "SOUL.md" = @"
You are Kevin. You are running in the kevin-reader lane.
Answer clearly in plain text.
Use kevin_system_status only when Matt asks about this computer, health, RAM, CPU, GPU, disk, Ollama, or the gateway.
Otherwise do not use tools.
"@
    "TOOLS.md" = @"
# Tools
kevin_system_status is the only tool.
It returns sanitized computer health. No paths, no usernames, no ports.
Do not call it for math, jokes, identity, or general chat.
"@
    "IDENTITY.md" = @"
# Identity
- Name: Kevin
- Theme: local reader
- Vibe: calm, practical, direct
"@
    "USER.md" = @"
# User
- Name: Matt
- What to call them: Matt
- Timezone: America/Boise
Matt is building and testing Kevin Reader on HESS-PC.
"@
    "HEARTBEAT.md" = @"
# Heartbeat
No heartbeat actions. Comments only.
This is the isolated Reader lane. Do not write production memory.
"@
  }
  foreach ($k in $files.Keys) {
    [IO.File]::WriteAllText((Join-Path $ws $k), $files[$k], $utf8)
  }

  Write-Host "===== 3) copy frozen plugin (no rebuild) ====="
  if (Test-Path $ext) { Remove-Item $ext -Recurse -Force }
  Copy-Item $freeze $ext -Recurse -Force

  Write-Host "===== 4) reader config (no production secrets) ====="
  $js = @"
const fs = require("fs");
const os = require("os");
const path = require("path");
const state = path.join(os.homedir(), ".openclaw-reader");
const cfgPath = path.join(state, "openclaw.json");
const ws = path.join(state, "workspace");
const cfg = {
  gateway: { port: 19001, bind: "loopback" },
  tools: {
    allow: ["kevin_system_status"],
    deny: ["exec","tool_call","tool_search","tool_describe","write","edit","apply_patch","sessions_send","sessions_spawn","sessions_yield","subagents","web_search","web_fetch","process","skill_workshop","browser"]
  },
  plugins: {
    enabled: true,
    allow: ["ollama", "kevin-core"]
  },
  models: {
    providers: {
      "ollama-tools": {
        baseUrl: "http://127.0.0.1:11434",
        api: "ollama",
        apiKey: "ollama-local",
        models: [{
          id: "qwen2.5:14b",
          name: "qwen2.5:14b",
          input: ["text"],
          contextTokens: 8192,
          params: { num_ctx: 8192, temperature: 0 }
        }]
      }
    }
  },
  agents: {
    defaults: {
      model: { primary: "ollama-tools/qwen2.5:14b" },
      workspace: ws,
      heartbeat: { every: "0m" },
      timeoutSeconds: 180,
      skills: []
    },
    list: [{
      id: "kevin-reader",
      name: "kevin-reader",
      workspace: ws,
      model: { primary: "ollama-tools/qwen2.5:14b" },
      skills: []
    }]
  }
};
fs.writeFileSync(cfgPath, Buffer.from(JSON.stringify(cfg, null, 2), "utf8"));
console.log("wrote reader config");
console.log("gateway.port", cfg.gateway.port);
console.log("tools.allow", JSON.stringify(cfg.tools.allow));
console.log("plugins.allow", JSON.stringify(cfg.plugins.allow));
console.log("agent", cfg.agents.list[0].id);
console.log("model", cfg.agents.defaults.model.primary);
"@
  [IO.File]::WriteAllText("$env:TEMP\kevin-reader-cfg.js", $js, $utf8)
  node "$env:TEMP\kevin-reader-cfg.js"
  Require-Ok "write reader config"

  Write-Host "===== 5) validate ====="
  Set-ReaderEnv
  openclaw --profile reader config validate
  Require-Ok "config validate"

  Write-Host "===== 6) link plugin ====="
  openclaw --profile reader plugins install --link --force $ext
  Require-Ok "plugins install"
  openclaw --profile reader plugins enable kevin-core
  Require-Ok "plugins enable"

  Write-Host "===== 7) validate after plugin ====="
  openclaw --profile reader config validate
  Require-Ok "config validate after plugin"

  Write-Host "===== 8) gateway wrapper + task ====="
  $node = (Get-Command node).Source
  $openclawJs = Join-Path $env:APPDATA "npm\node_modules\openclaw\dist\index.js"
  if (-not (Test-Path $openclawJs)) { throw "STOP: missing openclaw dist" }
  $cmd = @"
@echo off
set OPENCLAW_PROFILE=reader
set OPENCLAW_STATE_DIR=$state
set OPENCLAW_CONFIG_PATH=$cfg
set OPENCLAW_ALLOW_MULTI_GATEWAY=1
set OPENCLAW_GATEWAY_PORT=$port
"$node" "$openclawJs" gateway --port $port
"@
  [IO.File]::WriteAllText($wrapper, $cmd, $utf8)

  $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$wrapper`""
  $trigger = New-ScheduledTaskTrigger -AtLogOn
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
  try { Unregister-ScheduledTask -TaskName "KevinReaderGateway" -Confirm:$false -ErrorAction SilentlyContinue } catch {}
  Register-ScheduledTask -TaskName "KevinReaderGateway" -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
  if (-not (Test-PortOpen $port)) {
    Start-ScheduledTask -TaskName "KevinReaderGateway"
    Start-Sleep -Seconds 8
  } else {
    Write-Host "port $port already open; not starting a second gateway"
  }

  Write-Host "===== 9) probe ====="
  $up = $false
  1..15 | ForEach-Object {
    if (Test-PortOpen $port) { $up = $true }
    else { Start-Sleep -Seconds 2 }
  }
  if (-not $up) { throw "STOP: reader gateway not listening on $port" }
  Write-Host "reader gateway is up on $port"

  Write-Host "===== 10) plugin inspect ====="
  openclaw --profile reader plugins inspect kevin-core
  Require-Ok "plugins inspect kevin-core"

  Write-Host "===== 11) PONG inspect (no status question) ====="
  Set-ReaderEnv
  openclaw --profile reader agent --agent kevin-reader --message "/new"
  Require-Ok "reader /new"
  $raw = openclaw --profile reader agent --agent kevin-reader --json --message "Reply with only the word PONG. Do not use tools." 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { throw "STOP: reader PONG failed ($LASTEXITCODE)" }
  $i = $raw.IndexOf("{")
  if ($i -lt 0) {
    Write-Host $raw.Substring(0, [Math]::Min(2500, $raw.Length))
    throw "STOP: no JSON from reader PONG"
  }
  $o = $raw.Substring($i) | ConvertFrom-Json
  $text = $o.result.meta.finalAssistantVisibleText
  if (-not $text) { $text = $o.result.payloads[0].text }
  $entries = @($o.result.meta.systemPromptReport.tools.entries)
  $names = @()
  foreach ($e in $entries) {
    if ($null -eq $e) { continue }
    if ($e.name) { $names += [string]$e.name }
    elseif ($e -is [string]) { $names += $e }
  }
  $calls = 0
  if ($o.result.meta.toolSummary.calls) { $calls = [int]$o.result.meta.toolSummary.calls }
  $script:VisibleTools = $names
  $script:PongText = "$text"
  $script:PongCalls = $calls
  $script:PongStatus = "$($o.status)"
  Write-Host "STATUS=$($o.status)"
  Write-Host "TEXT=[$text]"
  Write-Host "CALLS=$calls"
  Write-Host "TOOL_COUNT=$($names.Count)"
  Write-Host ("TOOLS=" + ($names -join ","))
  if ($names.Count -ne 1 -or $names[0] -ne "kevin_system_status") {
    throw "STOP: provider-visible tools were not exactly [kevin_system_status]"
  }
  if ($calls -ne 0) { throw "STOP: PONG used tools" }
  if ($text -notmatch '(?i)^pong\.?$') { throw "STOP: PONG text mismatch [$text]" }

  $shaAfter = (Get-FileHash $prodCfg -Algorithm SHA256).Hash
  if ($shaAfter -ne $script:ProdShaBefore) {
    throw "STOP: production openclaw.json hash changed during Reader install"
  }

  Write-InstallReport "PASS" ""
  Write-Host "READER INSPECT PASS. Do not ask computer status until Grok says so."
  Write-Host "production config hash unchanged."
  Get-Content $artifact
} catch {
  try { Write-InstallReport "FAIL" "$_" } catch { Write-Host "could not write FAIL artifact: $_" }
  Write-Host "NIGHT/READER STOP: $_"
  exit 1
}
