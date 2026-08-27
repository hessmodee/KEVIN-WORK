$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding $false
$src = Join-Path $env:USERPROFILE ".openclaw"
$ws = Join-Path $src "workspace"
$freeze = Join-Path $src "extensions\kevin-core-v0.1.0-green"
$reports = Join-Path $ws "reports"
$log = Join-Path $reports "forge-night.jsonl"
New-Item -ItemType Directory -Force -Path $reports | Out-Null

function Rec([hashtable]$h) {
  $h.at = (Get-Date).ToString("o")
  $h.host = $env:COMPUTERNAME
  $line = ($h | ConvertTo-Json -Compress)
  [IO.File]::AppendAllText($log, $line + "`n", $utf8)
}

function Step([string]$name, [scriptblock]$fn) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  try {
    & $fn
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
    $sw.Stop()
    Rec @{ step = $name; result = "PASS"; ms = $sw.ElapsedMilliseconds }
    Write-Host "PASS $name $($sw.ElapsedMilliseconds)ms"
  } catch {
    $sw.Stop()
    Rec @{ step = $name; result = "FAIL"; ms = $sw.ElapsedMilliseconds; error = "$_" }
    Write-Host "FAIL $name $_"
    throw
  }
}

try {
  if (-not (Test-Path $freeze)) { throw "missing freeze $freeze" }
  Step "system-status" {
    python (Join-Path $ws "helper_system_status.py") --json | Out-Host
  }
  Step "sanitize" {
    python (Join-Path $ws "helper_sanitize_check.py") | Out-Host
  }
  Step "plugin-test" {
    Push-Location $freeze
    try { npm test | Out-Host } finally { Pop-Location }
  }
  Rec @{ step = "cycle"; result = "PASS" }
  Write-Host "NIGHT FORGE PASS"
  exit 0
} catch {
  Rec @{ step = "cycle"; result = "FAIL"; error = "$_" }
  Write-Host "NIGHT FORGE STOP: $_"
  exit 1
}
