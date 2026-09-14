# kevin-tick.ps1
# Source-mirror of the HESS KevinTick pulse order.
# Close-loop MUST run BEFORE helper_append_daily_note.py so a reimage cannot lose the wire.
# Do not recopy Supervisor. ExpectedSelectorSha 52EADBCA... stands.
# GitHub ControlPlane invoke-worker pin stays 16C49542... — do not overwrite.
# No Night Forge. No HEARTBEAT.md work list. Floor is the one clock.
$ErrorActionPreference = 'Continue'
$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ws = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $here }

function Invoke-TickStep([string]$label, [string]$path, [string[]]$args) {
  if (-not (Test-Path -LiteralPath $path)) {
    Write-Host ("tick skip {0}; missing {1}" -f $label, $path)
    return
  }
  Write-Host ("tick step {0}" -f $label)
  try {
    if ($args) { & powershell -NoProfile -ExecutionPolicy Bypass -File $path @args }
    else { & powershell -NoProfile -ExecutionPolicy Bypass -File $path }
  } catch {
    Write-Host ("tick FAIL {0}: {1}" -f $label, $_)
  }
}

# 1) Close-loop first: GitHub work-items -> local, reconcile RUNNING/OPEN owner invokes, COMPLETE on main
Invoke-TickStep 'close-invocation-loop' (Join-Path $here 'Tick-CloseInvocationLoop-v1.ps1')

# 2) Tick-owned repairs (hygiene + leftover outcome sync)
Invoke-TickStep 'tick-owned-repairs' (Join-Path $here 'Kevin-Tick-Owned-Repairs-v1.ps1')

# 3) Rebuild outcomes from invocations/done, then ONE CLOCK floor PushPublic
#    (Kevin-Tick-Owned-Repairs currently exits before its floor block; call explicitly.)
Invoke-TickStep 'owner-outcomes' (Join-Path $here 'Publish-Kevin-OwnerOutcomes-v1.ps1')
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'Publish-Kevin-HqLiveFloor-v1.ps1') -PushPublic
} catch { Write-Host "hq-live-floor FAIL: $_" }

# 4) Family-loop readiness: at most one OPEN refresh of an already-PROVEN West Motor key
Invoke-TickStep 'family-loop' (Join-Path $here 'Materialize-Kevin-FamilyLoop-v1.ps1')

# LAST: daily-note helpers — never before close-loop
$helper = Join-Path $ws 'helper_append_daily_note.py'
if (Test-Path -LiteralPath $helper) {
  try {
    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
    if ($py) { & $py.Source $helper 'tick close-loop ran' }
  } catch { Write-Host "daily-note FAIL: $_" }
} else {
  Write-Host 'tick skip daily-note; helper_append_daily_note.py not present'
}

Write-Host 'kevin-tick done'
