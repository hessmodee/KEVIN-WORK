$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0

$installer='control-plane/install/KEVIN-CONTROL-PLANE-v1.1-REPAIR.ps1'
if(-not(Test-Path -LiteralPath $installer)){throw 'v1.1 repair installer missing'}

$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $installer),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("repair installer line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'v1.1 repair installer parse failed'}
Write-Host 'PASS v1.1 repair installer parses on Windows PowerShell 5.1.'

& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $installer -Mode ValidateTransport
if($LASTEXITCODE -ne 0){throw 'v1.1 repair installer exact argv transport test failed'}
Write-Host 'PASS v1.1 repair installer exact argv transport.'

$pins=[ordered]@{
  'control-plane/desired-state-v1.json'='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
  'control-plane/OWNER-AUTHORIZATION-v1.md'='b0cc4465f12457492b3a6c2761287398cc6295b5'
  'control-plane/actuator/kevin-autonomy-actuator-v0.1.ps1'='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
  'control-plane/actuator/kevin-autonomy-bridge-v0.1l.ps1'='2b0a4f168b2d5f64b1979063eaf62807373e25ce'
  'control-plane/dispatcher/mission-catalog-v1.json'='743db880f6529f59341f2e0f89da533091392001'
  'control-plane/dispatcher/kevin-mission-worker-v0.1.ps1'='3b02fb4acfadb715a017641b622179a9cf422eb0'
  'control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1'='766fa55163b238f04ca54cc18164363b962a777e'
  'control-plane/intake/kevin-work-order-intake-v0.1.ps1'='b21488796d967da6b892190538d61b4e58d072f5'
}
foreach($kv in $pins.GetEnumerator()){
  $actual=(& git hash-object -- $kv.Key).Trim()
  if($actual -cne [string]$kv.Value){throw "Current repaired blob mismatch for $($kv.Key): expected $($kv.Value), got $actual"}
  Write-Host "PASS repaired pin $($kv.Key) => $actual"
}

$text=Get-Content -LiteralPath $installer -Raw
foreach($needle in @(
  '5546b2bc5d6eb87b7f25b3d72214e99fe6636ba8',
  '893d2fac2e0ffb5aa536d9d6b02eb49164018d10',
  '75709657b6d34ffb24a9e6a9dc968d07e0467557',
  '3b02fb4acfadb715a017641b622179a9cf422eb0',
  '766fa55163b238f04ca54cc18164363b962a777e',
  'b21488796d967da6b892190538d61b4e58d072f5',
  'Kevin Mission Dispatcher v1',
  'Kevin Work Order Intake v1',
  'Kevin Autonomy Reconciler v0.1',
  'Kevin Autonomy Telemetry v0.1',
  '*/3 * * * *',
  '*/2 * * * *',
  'KEVIN_GH_AUTH_MODE',
  'A CURRENT work order exists; refusing repair while intake has pending work.',
  'Model response contained no JSON object|JSON contract failed after one bounded format-recovery attempt',
  'Exact obsolete JSON-format failure cooldown cleared; mission queue preserved.',
  'scheduler_jobs_recreated=$false',
  'KEVIN CONTROL PLANE v1.1 REPAIR INSTALLED + PROVEN',
  'ROLLBACK-CONTROL-PLANE-v1.1.ps1'
)){if(-not $text.Contains($needle)){throw "v1.1 repair installer missing contract: $needle"}}

foreach($forbidden in @(
  "@('cron','create'",
  "@('cron','remove'",
  "@('cron','update'",
  "@('cron','enable'",
  "@('cron','disable'",
  'Invoke-Expression',
  'iex ',
  'command_string',
  'shell_command',
  'allow_arbitrary_shell=$true',
  'allow_production_mutation=$true'
)){
  if($text -match [regex]::Escape($forbidden)){throw "v1.1 repair installer contains forbidden mutation/authority pattern: $forbidden"}
}
Write-Host 'PASS v1.1 repair installer cannot create/remove/update/enable/disable scheduler jobs.'

# Require exactly the three runtime file targets in the old/new mutable pin maps.
foreach($leaf in @('kevin-mission-worker-v0.1.ps1','kevin-mission-dispatcher-v0.1.ps1','kevin-work-order-intake-v0.1.ps1')){
  if(([regex]::Matches($text,[regex]::Escape($leaf))).Count -lt 3){throw "Expected repaired runtime target not sufficiently pinned/referenced: $leaf"}
}
if($text -notmatch "state='INFRA_FAILURE'" -or $text -notmatch "failure_family.*mission_id"){throw 'Exact stale-failure state-reset preconditions are missing.'}
if($text -notmatch "Copy-Item.*mission-dispatcher-state-v1.json" -and $text -notmatch 'stateBackup'){throw 'Dispatcher-state rollback evidence contract missing.'}
Write-Host 'PASS v1.1 state-reset and rollback contracts.'

Write-Host 'CONTROL_PLANE_V11_REPAIR_INSTALLER_TEST_PASS'
