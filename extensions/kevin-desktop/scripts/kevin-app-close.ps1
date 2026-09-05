# Kevin app close — graceful first, audited force last. Never invent passwords.
# Usage: kevin-app-close.ps1 -ProcessName Minecraft.Windows [-Force]
param(
  [Parameter(Mandatory=$true)][string]$ProcessName,
  [switch]$Force,
  [int]$GraceMs = 8000
)
$ErrorActionPreference = 'Continue'
$protectedNames = @('node','openclaw','KevinChat','KevinReader','KevinOperator')
# Refuse closing by name fragments that look like Kevin gateways / protected hosts
if ($ProcessName -match '(?i)openclaw|kevin.*(chat|reader|operator)|^node$') {
  Write-Output 'KEVIN_APP_CLOSE_DENIED_PROTECTED'
  exit 10
}
$procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
if (-not $procs) {
  Write-Output "KEVIN_APP_CLOSE_ALREADY_GONE name=$ProcessName"
  exit 0
}
# Guard: never stop if process path looks like Chat/Reader gateway (belt+suspenders)
foreach ($p in $procs) {
  try {
    $path = $p.Path
    if ($path -and ($path -match '(?i)(openclaw|kevin-chat|kevin-reader|18789|19001)')) {
      Write-Output "KEVIN_APP_CLOSE_DENIED_PROTECTED path=$path"
      exit 10
    }
  } catch {}
}
$ids = @($procs | ForEach-Object { $_.Id })
Write-Output "KEVIN_APP_CLOSE_START name=$ProcessName pids=$($ids -join ',')"

# 1) CloseMainWindow (Win32; may fail on pure UWP)
foreach ($p in $procs) {
  try {
    $ok = $p.CloseMainWindow()
    Write-Output "CloseMainWindow pid=$($p.Id) returned=$ok"
  } catch {
    Write-Output "CloseMainWindow pid=$($p.Id) err=$($_.Exception.Message)"
  }
}
Start-Sleep -Milliseconds ([Math]::Min($GraceMs, 3000))
$procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
if (-not $procs) {
  Write-Output "KEVIN_APP_CLOSE_OK method=CloseMainWindow name=$ProcessName"
  exit 0
}

# 2) UI Automation WindowPattern.Close
try {
  Add-Type -AssemblyName UIAutomationClient
  Add-Type -AssemblyName UIAutomationTypes
  $root = [System.Windows.Automation.AutomationElement]::RootElement
  $liveIds = @($procs | ForEach-Object { $_.Id })
  foreach ($procId in $liveIds) {
    $c = New-Object System.Windows.Automation.PropertyCondition(
      [System.Windows.Automation.AutomationElement]::ProcessIdProperty, $procId)
    $wins = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $c)
    foreach ($w in $wins) {
      try {
        $wp = $w.GetCurrentPattern([System.Windows.Automation.WindowPattern]::Pattern)
        $wp.Close()
        Write-Output "UIA_WindowPattern.Close pid=$procId name=$($w.Current.Name)"
      } catch {
        Write-Output "UIA_Close miss pid=$procId err=$($_.Exception.Message)"
      }
    }
  }
} catch {
  Write-Output "UIA_UNAVAILABLE err=$($_.Exception.Message)"
}
Start-Sleep -Milliseconds $GraceMs
$procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
if (-not $procs) {
  Write-Output "KEVIN_APP_CLOSE_OK method=UIA name=$ProcessName"
  exit 0
}

# 3) taskkill without /F first — MUST use $procId not automatic $PID
$liveIds = @($procs | ForEach-Object { $_.Id })
foreach ($procId in $liveIds) {
  & taskkill.exe /PID $procId 2>&1 | ForEach-Object { Write-Output $_ }
}
Start-Sleep -Milliseconds 2000
$procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
if (-not $procs) {
  Write-Output "KEVIN_APP_CLOSE_OK method=taskkill name=$ProcessName"
  exit 0
}

if (-not $Force) {
  Write-Output "KEVIN_APP_CLOSE_NEED_FORCE name=$ProcessName remaining=$($procs.Id -join ',')"
  exit 2
}

foreach ($p in $procs) {
  Write-Output "AUDITED_FORCE Stop-Process -Force pid=$($p.Id) name=$ProcessName"
  Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 1000
$procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
if (-not $procs) {
  Write-Output "KEVIN_APP_CLOSE_OK method=Force name=$ProcessName"
  exit 0
}
Write-Output "KEVIN_APP_CLOSE_FAIL name=$ProcessName remaining=$($procs.Id -join ',')"
exit 1
