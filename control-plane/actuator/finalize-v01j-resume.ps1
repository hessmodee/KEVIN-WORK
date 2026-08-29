Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$p='control-plane/actuator/KEVIN-AUTONOMY-SCHEDULER-RESUME-v0.1j.ps1'
$text=Get-Content -LiteralPath $p -Raw

function Replace-Once([string]$Old,[string]$New,[string]$Label){
  $count=([regex]::Matches($text,[regex]::Escape($Old))).Count
  if($count -ne 1){throw "Expected exactly one ${Label} target; found $count"}
  $script:text=$text.Replace($Old,$New)
}

Replace-Once -Label 'bridge blob pin' -Old "`$NewBridgeBlob='d9ccb7d0eb1f46a6ddafd4cd917e947e82d1c3b5'" -New "`$NewBridgeBlob='d542581dc4783fc8f34ede34edf47e4427df7091'"

Replace-Once -Label 'Assert-CronJob parameter' -Old '  param($Job,[string]$Label,[string]$ExpectedExpr,[string[]]$ExpectedArgv,[string]$ExpectedCwd)' -New "  param(`$Job,[string]`$Label,[string]`$ExpectedExpr,[string[]]`$ExpectedArgv,[string]`$ExpectedCwd,[string]`$ExpectedGhExe='')"

$oldAssert='  if([string]$Job.payload.cwd -cne $ExpectedCwd){throw "$Label cwd mismatch."};if([string]$Job.schedule.kind -ne ''cron'' -or [string]$Job.schedule.expr -cne $ExpectedExpr){throw "$Label schedule mismatch."}'
$newAssert=@'
  if([string]$Job.payload.cwd -cne $ExpectedCwd){throw "$Label cwd mismatch."};if([string]$Job.schedule.kind -ne 'cron' -or [string]$Job.schedule.expr -cne $ExpectedExpr){throw "$Label schedule mismatch."}
  if($ExpectedGhExe){
    if(-not $Job.payload.env -or -not ($Job.payload.env.PSObject.Properties.Name -contains 'KEVIN_GH_EXE')){throw "$Label stored environment is missing KEVIN_GH_EXE."}
    if([string]$Job.payload.env.KEVIN_GH_EXE -cne $ExpectedGhExe){throw "$Label KEVIN_GH_EXE mismatch. Expected '$ExpectedGhExe', got '$([string]$Job.payload.env.KEVIN_GH_EXE)'."}
  }
'@.TrimEnd()
Replace-Once -Label 'Assert-CronJob environment verification' -Old $oldAssert -New $newAssert

Replace-Once -Label 'telemetry command env' -Old "'--output-max-bytes','32768','--no-deliver','--json')" -New "'--output-max-bytes','32768','--command-env',(`"KEVIN_GH_EXE={0}`" -f `$script:GhExe),'--no-deliver','--json')"

Replace-Once -Label 'telemetry cron verification call' -Old "Assert-CronJob `$bj 'Telemetry' '*/5 * * * *' `$bridgeArgv `$Root" -New "Assert-CronJob `$bj 'Telemetry' '*/5 * * * *' `$bridgeArgv `$Root `$script:GhExe"

Replace-Once -Label 'final bridge proof label' -Old "Write-Host 'Bridge: hardened exact gh transport + bounded retry'" -New "Write-Host 'Bridge: hardened exact gh transport + bounded retry + pinned scheduler gh.exe'"

[IO.File]::WriteAllText((Join-Path (Get-Location) $p),$text,(New-Object Text.UTF8Encoding($false)))
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $p),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'Final v0.1j resume parse failed'}
$check=Get-Content -LiteralPath $p -Raw
if($check -match 'd9ccb7d0eb1f46a6ddafd4cd917e947e82d1c3b5'){throw 'Old bridge blob remains.'}
if($check -notmatch 'd542581dc4783fc8f34ede34edf47e4427df7091'){throw 'Final bridge blob pin missing.'}
if($check -notmatch [regex]::Escape("'--command-env',(`"KEVIN_GH_EXE={0}`" -f `$script:GhExe)")){throw 'Telemetry command environment pin missing.'}
if($check -notmatch [regex]::Escape('payload.env.KEVIN_GH_EXE')){throw 'Stored environment verification missing.'}
if($check -notmatch [regex]::Escape("Assert-CronJob `$bj 'Telemetry' '*/5 * * * *' `$bridgeArgv `$Root `$script:GhExe")){throw 'Telemetry environment verification call missing.'}
$blob=(git hash-object $p).Trim().ToLowerInvariant()
if($LASTEXITCODE -ne 0 -or $blob -notmatch '^[0-9a-f]{40}$'){throw 'Could not compute final resume Git blob.'}
Write-Host "PASS final v0.1j resume parse and scheduler environment verification."
Write-Host "RESUME_BLOB=$blob"
