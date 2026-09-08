# Kevin silent scheduler hygiene v1
# GREEN/YELLOW: re-wrap Kevin/OpenClaw scheduled tasks so powershell.exe does not flash a window.
# Does not disable jobs, change cadence, or widen authority. Idempotent. Supports -WhatIf.
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$RepoRoot = ""
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Find-RepoRoot {
  param([string]$Hint)
  $candidates = @()
  if ($Hint) { $candidates += $Hint }
  $candidates += @(
    "C:\Users\matt\Documents\GitHub\KEVIN-WORK",
    "C:\Users\Matthew Hess\Documents\GitHub\KEVIN-WORK",
    (Join-Path $PSScriptRoot "..")
  )
  foreach ($c in $candidates) {
    if ($c -and (Test-Path (Join-Path $c "docs\index.html"))) {
      return (Resolve-Path $c).Path
    }
  }
  return $null
}

$repo = Find-RepoRoot -Hint $RepoRoot
$wrapperDest = if ($repo) { Join-Path $repo "tools\kevin-run-hidden.vbs" } else { Join-Path $PSScriptRoot "kevin-run-hidden.vbs" }
if (-not (Test-Path $wrapperDest)) {
  throw "Missing hidden launcher: $wrapperDest"
}

$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    ("$($_.TaskName) $($_.TaskPath)") -match '(?i)kevin|openclaw|hess-pc|night.?forge'
  })

$changed = New-Object System.Collections.Generic.List[object]
$already = New-Object System.Collections.Generic.List[object]
$skipped = New-Object System.Collections.Generic.List[object]

foreach ($task in $tasks) {
  $needsWrap = $false
  $newActions = @()
  foreach ($a in @($task.Actions)) {
    $exe = [string]$a.Execute
    $args = [string]$a.Arguments
    $isPs = $exe -match '(?i)powershell(\.exe)?$'
    $alreadyHidden = ($args -match '(?i)-WindowStyle\s+Hidden') -or ($exe -match '(?i)wscript(\.exe)?$')
    if ($isPs -and -not $alreadyHidden) {
      $needsWrap = $true
      if ($args -match '(?i)-File\s+"?([^"]+\.ps1)"?') {
        $scriptPath = $Matches[1]
        $rest = ($args.Substring($args.ToLower().IndexOf('.ps1') + 4)).Trim().TrimStart('"')
        $newArgs = "//B //nologo `"$wrapperDest`" `"$scriptPath`" $rest".Trim()
      } else {
        $newArgs = "//B //nologo `"$wrapperDest`" $args"
      }
      $wd = $a.WorkingDirectory
      if ([string]::IsNullOrWhiteSpace($wd)) {
        $newActions += New-ScheduledTaskAction -Execute "wscript.exe" -Argument $newArgs
      } else {
        $newActions += New-ScheduledTaskAction -Execute "wscript.exe" -Argument $newArgs -WorkingDirectory $wd
      }
    } else {
      $newActions += $a
    }
  }
  $needsHide = -not [bool]$task.Settings.Hidden
  $row = [pscustomobject]@{
    task_name = $task.TaskName
    task_path = $task.TaskPath
    hidden_before = [bool]$task.Settings.Hidden
    would_wrap = $needsWrap
    would_hide = $needsHide
  }
  if (-not $needsWrap -and -not $needsHide) {
    $already.Add($row) | Out-Null
    continue
  }
  if ($WhatIfPreference -or -not $PSCmdlet.ShouldProcess("$($task.TaskPath)$($task.TaskName)", "Hide/wrap scheduled task")) {
    $skipped.Add($row) | Out-Null
    continue
  }
  $settings = $task.Settings
  $settings.Hidden = $true
  $settings.AllowDemandStart = $true
  $settings.StartWhenAvailable = $true
  if ($needsWrap) {
    Set-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Action $newActions -Settings $settings | Out-Null
  } else {
    Set-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Settings $settings | Out-Null
  }
  $changed.Add($row) | Out-Null
}

$receipt = [pscustomobject]@{
  schema = 1
  kind = "kevin-silent-scheduler-hygiene"
  version = "1.0.0"
  generated_at = (Get-Date).ToString("o")
  what_if = [bool]$WhatIfPreference
  wrapper = $wrapperDest
  matched = $tasks.Count
  changed = $changed
  already_silent = $already
  skipped = $skipped
  note = "Grokbot remote_shell popups are a separate launcher and are not Task Scheduler jobs. This script only silences Kevin/OpenClaw scheduled tasks."
}

$json = $receipt | ConvertTo-Json -Depth 6
Write-Output $json
if ($repo) {
  $outDir = Join-Path $repo "reports"
  if (Test-Path $outDir) {
    $json | Set-Content -Path (Join-Path $outDir "silent-scheduler-hygiene-latest.json") -Encoding utf8
  }
}
Write-Output ("KEVIN_SILENT_SCHEDULER matched={0} changed={1} already={2} skipped={3}" -f $tasks.Count, $changed.Count, $already.Count, $skipped.Count)
