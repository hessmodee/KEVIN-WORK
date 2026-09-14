# Install-Kevin-Tick-CloseLoopHook-v1.ps1
# Idempotent: ensure live kevin-tick.ps1 calls Tick-CloseInvocationLoop-v1.ps1
# BEFORE helper_append_daily_note.py. Does not recopy Supervisor. Does not start tasks.
param()
$ErrorActionPreference = 'Stop'
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
$live = @(
  (Join-Path $ws 'kevin-tick.ps1'),
  (Join-Path $ws 'tools\kevin-tick.ps1')
) | Where-Object { Test-Path -LiteralPath $_ }
$src = Join-Path $PSScriptRoot 'kevin-tick.ps1'
$close = Join-Path $PSScriptRoot 'Tick-CloseInvocationLoop-v1.ps1'
if (-not (Test-Path -LiteralPath $close)) { throw "missing $close" }

$hook = @'
# Tick-CloseInvocationLoop hook (source-mirror). MUST run before helper_append_daily_note.py
$closeLoop = Join-Path $PSScriptRoot 'Tick-CloseInvocationLoop-v1.ps1'
if (-not (Test-Path -LiteralPath $closeLoop)) { $closeLoop = Join-Path (Join-Path $env:USERPROFILE '.openclaw\workspace\tools') 'Tick-CloseInvocationLoop-v1.ps1' }
if (Test-Path -LiteralPath $closeLoop) {
  Write-Host 'tick hook close-invocation-loop'
  & powershell -NoProfile -ExecutionPolicy Bypass -File $closeLoop
} else { Write-Host 'tick hook close-loop MISSING' }
'@

foreach ($path in $live) {
  $txt = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  if ($txt -match 'Tick-CloseInvocationLoop-v1') {
    Write-Host "hook already present: $path"
    continue
  }
  if ($txt -match 'helper_append_daily_note') {
    $txt = $txt -replace '(?=.*helper_append_daily_note)', ($hook + "`r`n")
    # insert immediately before first helper_append_daily_note mention
    $idx = $txt.IndexOf('helper_append_daily_note')
    if ($idx -ge 0) {
      $nl = $txt.LastIndexOf("`n", $idx)
      if ($nl -lt 0) { $nl = 0 }
      $txt = $txt.Substring(0, $nl+1) + $hook + "`r`n" + $txt.Substring($nl+1)
    }
  } else {
    $txt = $hook + "`r`n" + $txt
  }
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [IO.File]::WriteAllText($path, $txt, $utf8)
  Write-Host "hook inserted: $path"
}

# Always keep tools\kevin-tick.ps1 as the source-of-truth copy
if (Test-Path -LiteralPath $src) {
  Copy-Item -LiteralPath $src -Destination (Join-Path $ws 'tools\kevin-tick.ps1') -Force
  Write-Host 'copied tools/kevin-tick.ps1 into workspace tools'
}
Write-Host 'Install-Kevin-Tick-CloseLoopHook done'
