$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0

$installer='control-plane/install/KEVIN-CONTROL-PLANE-v1.2-REVIEW-REPAIR.ps1'
if(-not(Test-Path -LiteralPath $installer)){throw 'v1.2 review repair installer missing'}
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $installer),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("installer line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'v1.2 review repair installer parse failed'}
Write-Host 'PASS v1.2 review repair installer parses on Windows PowerShell 5.1.'

& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $installer -Mode ValidateTransport
if($LASTEXITCODE -ne 0){throw 'v1.2 review repair exact argv transport test failed'}
Write-Host 'PASS v1.2 review repair exact argv transport.'

$pins=[ordered]@{
  'control-plane/desired-state-v1.json'='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
  'control-plane/OWNER-AUTHORIZATION-v1.md'='b0cc4465f12457492b3a6c2761287398cc6295b5'
  'control-plane/actuator/kevin-autonomy-actuator-v0.1.ps1'='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
  'control-plane/actuator/kevin-autonomy-bridge-v0.1l.ps1'='2b0a4f168b2d5f64b1979063eaf62807373e25ce'
  'control-plane/dispatcher/mission-catalog-v1.json'='743db880f6529f59341f2e0f89da533091392001'
  'control-plane/dispatcher/kevin-mission-worker-v0.1.ps1'='a3e9797aca21aa99121148e21473beeccde1f63f'
  'control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1'='766fa55163b238f04ca54cc18164363b962a777e'
  'control-plane/intake/kevin-work-order-intake-v0.1.ps1'='b21488796d967da6b892190538d61b4e58d072f5'
}
foreach($kv in $pins.GetEnumerator()){$actual=(& git hash-object -- $kv.Key).Trim();if($actual -cne [string]$kv.Value){throw "Pinned source mismatch for $($kv.Key): expected $($kv.Value), got $actual"};Write-Host "PASS source pin $($kv.Key) => $actual"}

$text=Get-Content -LiteralPath $installer -Raw
foreach($needle in @(
  '3b02fb4acfadb715a017641b622179a9cf422eb0',
  'a3e9797aca21aa99121148e21473beeccde1f63f',
  'd3a2078b-bb1a-438b-8a40-2a6b6c836e5f',
  'befc526f-5f59-4216-9339-cfd998d303f0',
  'b2b620e7-b217-471f-be51-dea33f6bc839',
  '5ab49387-6664-4620-a9a1-1b0165a3b9d3',
  '$OrderBranch=''kevin-control-plane-v1''',
  'A CURRENT work order exists; refusing review repair while intake has pending work.',
  'Review model JSON contract failed after one bounded format-recovery attempt.',
  'CONTROL_PLANE_V12_REVIEW_PROTOCOL_READY',
  'line_fallback=1',
  'scheduler_jobs_recreated=$false',
  'KEVIN CONTROL PLANE v1.2 REVIEW REPAIR INSTALLED + PROVEN',
  'ROLLBACK-CONTROL-PLANE-v1.2.ps1'
)){if(-not $text.Contains($needle)){throw "v1.2 review repair installer missing contract: $needle"}}

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
  if($text -match [regex]::Escape($forbidden)){throw "v1.2 repair contains forbidden scheduler/authority pattern: $forbidden"}
}
Write-Host 'PASS v1.2 repair cannot create/remove/update/enable/disable scheduler jobs.'

$atomicNeedle='$tmpTarget="$WorkerPath.tmp-$PID"'
if(-not $text.Contains($atomicNeedle)){throw 'Worker-only atomic mutation contract missing.'}
foreach($badTarget in @('$DispatcherPath.tmp-','$IntakePath.tmp-','Move-Item -LiteralPath $tmpTarget -Destination $DispatcherPath','Move-Item -LiteralPath $tmpTarget -Destination $IntakePath')){if($text.Contains($badTarget)){throw "Unexpected non-worker file mutation contract: $badTarget"}}
if(-not $text.Contains('Only mission worker changed; exact v1.2 identity proven.')){throw 'Worker-only proof statement missing.'}
$errorNeedle='[string](Get-OptionalPropertyValue $ws ''error'') -eq ''Review model JSON contract failed after one bounded format-recovery attempt.'''
if(-not $text.Contains($errorNeedle)){throw 'Exact reviewer failure reset precondition missing.'}
$familyNeedle='[string](Get-OptionalPropertyValue $ds ''failure_family'') -eq [string](Get-OptionalPropertyValue $ws ''mission_id'')'
if(-not $text.Contains($familyNeedle)){throw 'Failure-family/mission reset binding missing.'}
Write-Host 'PASS v1.2 worker-only mutation and exact cooldown-reset contracts.'
Write-Host 'CONTROL_PLANE_V12_REVIEW_REPAIR_INSTALLER_TEST_PASS'
