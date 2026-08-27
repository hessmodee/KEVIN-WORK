$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding $false

$repo = "hessmodee/KEVIN-WORK"
$root = Join-Path $env:USERPROFILE ".openclaw"
$ws = Join-Path $root "workspace"
$reports = Join-Path $ws "reports"
$night = Join-Path $ws "kevin-night-forge.ps1"
$design = Join-Path $ws "kevin-design-forge.ps1"
$readerGreen = Join-Path $env:USERPROFILE ".openclaw-reader\READER-GREEN.json"

function Get-RepoText([string]$repoPath) {
  $raw = (& gh api "repos/$repo/contents/$repoPath" --jq .content | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or -not $raw) { throw "GitHub fetch failed: $repoPath" }
  return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($raw -replace '\s','')))
}

function Parse-PowerShell([string]$path) {
  if (-not (Test-Path $path)) { throw "missing script: $path" }
  $null = [ScriptBlock]::Create([IO.File]::ReadAllText($path))
}

$nightBackup = $null
try {
  Write-Host "================================================"
  Write-Host " KEVIN DESIGN FORGE V3 SAFE INSTALLER"
  Write-Host "================================================"

  Write-Host "===== 1) verify proven foundations ====="
  if (-not (Test-Path $readerGreen)) { throw "Reader GREEN evidence missing" }
  $rg = Get-Content $readerGreen -Raw | ConvertFrom-Json
  if ($rg.status -ne "GREEN" -or [int]$rg.tool_count -ne 1 -or $rg.tool -ne "kevin_system_status") {
    throw "Reader GREEN contract changed"
  }
  if (-not (Test-Path $night)) { throw "Night Forge missing" }
  Parse-PowerShell $night

  $nightTask = Get-ScheduledTask -TaskName "KevinNightForge" -ErrorAction Stop
  $nightInfo = Get-ScheduledTaskInfo -TaskName "KevinNightForge"
  Write-Host ("Night Forge state = " + $nightTask.State)
  Write-Host ("Night Forge last  = " + $nightInfo.LastTaskResult)
  if ($nightTask.State -eq "Disabled") { throw "Night Forge is disabled" }
  if ($nightInfo.LastTaskResult -ne 0) { throw "Night Forge baseline last result is nonzero" }
  Write-Host "PASS foundations"

  Write-Host "===== 2) fetch Design Forge from GitHub ====="
  $designText = Get-RepoText "workspace/kevin-design-forge.ps1"
  if ($designText -notmatch 'KEVIN DESIGN FORGE V3') { throw "wrong Design Forge payload" }
  if ($designText -notmatch 'kevin-lab-qwen') { throw "Design Forge is not using proven 8K agent" }
  if ($designText -match 'kevin-lab-qwen-16k') { throw "16K agent unexpectedly present" }
  [IO.File]::WriteAllText($design, $designText, $utf8)
  Parse-PowerShell $design
  Write-Host "PASS Design Forge downloaded and parses"

  Write-Host "===== 3) manual 8K Design Forge proof ====="
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $design
  $designExit = $LASTEXITCODE
  if ($designExit -ne 0) { throw "Design Forge manual proof failed exit=$designExit" }

  $designState = Join-Path $ws "forge-designs\design-forge-state.json"
  if (-not (Test-Path $designState)) { throw "Design Forge PASS state missing" }
  $ds = Get-Content $designState -Raw | ConvertFrom-Json
  if ($ds.status -ne "PASS") { throw "Design Forge state is not PASS" }
  Write-Host ("PASS Design Forge mission = " + $ds.last_mission)

  Write-Host "===== 4) back up Night Forge ====="
  $nightBackup = "$night.pre-design-forge-v3-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $night $nightBackup -Force
  Write-Host ("Backup = " + $nightBackup)

  Write-Host "===== 5) add fail-soft hourly build hook ====="
  $nightText = [IO.File]::ReadAllText($night) -replace "`r`n","`n"
  if ($nightText -notmatch 'PHASE 5 design-forge') {
    $needle = '  $swAll.Stop()'
    $count = ([regex]::Matches($nightText, [regex]::Escape($needle))).Count
    if ($count -ne 1) { throw "Night Forge insertion point count=$count" }

    $hookLines = @(
      '  Write-Host "PHASE 5 design-forge"',
      '  $designForge = Join-Path $ws "kevin-design-forge.ps1"',
      '  if (Test-Path $designForge) {',
      '    & powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File $designForge',
      '    $designExit = $LASTEXITCODE',
      '    if ($designExit -eq 0) {',
      '      Rec @{ step = "design-forge"; result = "PASS"; exit_code = 0 }',
      '      Write-Host "PHASE 5 design-forge PASS"',
      '    } else {',
      '      Rec @{ step = "design-forge"; result = "FAIL_SOFT"; exit_code = $designExit }',
      '      Write-Host "PHASE 5 design-forge FAIL-SOFT exit=$designExit"',
      '    }',
      '  } else {',
      '    Rec @{ step = "design-forge"; result = "SKIP"; error = "script missing" }',
      '    Write-Host "PHASE 5 design-forge SKIP"',
      '  }',
      ''
    )
    $hook = [string]::Join("`n", $hookLines)
    $nightText = $nightText.Replace($needle, $hook + $needle)
    [IO.File]::WriteAllText($night, $nightText, $utf8)
  }

  Parse-PowerShell $night
  $verify = [IO.File]::ReadAllText($night)
  if ($verify -notmatch 'PHASE 5 design-forge') { throw "Design Forge hook missing" }
  if ($verify -notmatch 'FAIL_SOFT') { throw "Design Forge hook is not fail-soft" }
  Write-Host "PASS hourly Design Forge hook installed"

  Write-Host "===== 6) verify background task stayed hidden ====="
  $task = Get-ScheduledTask -TaskName "KevinNightForge"
  $action = @($task.Actions)[0]
  Write-Host ("Action = " + $action.Arguments)
  if ($action.Arguments -notmatch '-WindowStyle Hidden') { throw "Night Forge lost hidden mode" }
  if ($task.State -eq "Disabled") { throw "Night Forge became disabled" }
  Write-Host "PASS scheduled Night Forge remains enabled and hidden"

  Write-Host ""
  Write-Host "================================================"
  Write-Host " KEVIN DESIGN FORGE V3 INSTALL PASS"
  Write-Host ""
  Write-Host " Kevin now builds one isolated design candidate"
  Write-Host " after each successful hourly Night Forge cycle."
  Write-Host " Candidate code is never auto-executed or promoted."
  Write-Host "================================================"
  exit 0
}
catch {
  $msg = "$_"
  if ($nightBackup -and (Test-Path $nightBackup)) {
    try {
      Copy-Item $nightBackup $night -Force
      Write-Host "Night Forge restored from backup."
    } catch {}
  }
  Write-Host ""
  Write-Host "================================================"
  Write-Host " DESIGN FORGE INSTALL STOPPED SAFELY"
  Write-Host $msg
  Write-Host "================================================"
  exit 1
}
