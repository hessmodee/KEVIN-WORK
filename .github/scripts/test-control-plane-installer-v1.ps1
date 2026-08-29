$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0

$installer='control-plane/install/KEVIN-CONTROL-PLANE-v1.ps1'
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $installer),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("installer line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'Installer parse failed'}
Write-Host 'PASS installer parses on Windows PowerShell 5.1.'

& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $installer -Mode ValidateTransport
if($LASTEXITCODE -ne 0){throw 'Installer exact argv transport test failed'}
Write-Host 'PASS installer exact argv transport.'

$pins=[ordered]@{
  'control-plane/desired-state-v1.json'='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
  'control-plane/OWNER-AUTHORIZATION-v1.md'='b0cc4465f12457492b3a6c2761287398cc6295b5'
  'control-plane/actuator/kevin-autonomy-actuator-v0.1.ps1'='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
  'control-plane/actuator/kevin-autonomy-bridge-v0.1l.ps1'='2b0a4f168b2d5f64b1979063eaf62807373e25ce'
  'control-plane/dispatcher/mission-catalog-v1.json'='743db880f6529f59341f2e0f89da533091392001'
  'control-plane/dispatcher/kevin-mission-worker-v0.1.ps1'='3b02fb4acfadb715a017641b622179a9cf422eb0'
  'control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1'='766fa55163b238f04ca54cc18164363b962a777e'
  'control-plane/intake/kevin-work-order-intake-v0.1.ps1'='b21488796d967da6b892190538d61b4e58d072f5'
  'control-plane/schemas/work-order-v1.schema.json'='c030d84c1da9de2d1df4f3a9b067dbd4ac8935c9'
}
foreach($kv in $pins.GetEnumerator()){
  $actual=(& git hash-object -- $kv.Key).Trim()
  if($actual -cne [string]$kv.Value){throw "Pinned blob mismatch for $($kv.Key): expected $($kv.Value), got $actual"}
  Write-Host "PASS pin $($kv.Key) => $actual"
}

$text=Get-Content -LiteralPath $installer -Raw
foreach($needle in @(
  'KEVIN CONTROL PLANE v1 INSTALLED + PROVEN',
  'Kevin Mission Dispatcher v1',
  'Kevin Work Order Intake v1',
  'kevin-mission-dispatcher-v1',
  'kevin-work-order-intake-v1',
  '*/3 * * * *',
  '*/2 * * * *',
  'KEVIN_GH_AUTH_MODE=stored',
  'Existing autonomy scheduler jobs remained untouched.',
  'A CURRENT work order already exists. Refusing first-install activation',
  '__not_allowlisted__'
)){if(-not $text.Contains($needle)){throw "Installer missing contract: $needle"}}
foreach($bad in @('Invoke-Expression','openclaw automations','command_string','shell_command','automatic production promotion')){if($text -match [regex]::Escape($bad)){throw "Installer contains forbidden/obsolete pattern: $bad"}}
Write-Host 'PASS installer authority and scheduler contracts.'
Write-Host 'CONTROL_PLANE_INSTALLER_V1_TEST_PASS'
