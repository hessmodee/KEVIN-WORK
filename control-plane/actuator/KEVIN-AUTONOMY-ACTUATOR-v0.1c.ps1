Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

$BaseUrl='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/b80c4d0059d9bb5a952aa752d4de31b45b2c3f5c/control-plane/actuator/KEVIN-AUTONOMY-ACTUATOR-v0.1.ps1'
$BaseHash='BC59286F6169795B5DB06ACC216183F9A1B44FB3914D810A752B51EE93A74287'
$WrongBridge='E72A2A635326CF1AB036404E64E274D2F56E79CA5CEB268DBF9B2EA4B67BEA5'
$CorrectBridge='E72A2A635326CF1AB036404E64E274D2F56CE79CA5CEB268DBF9B2EA4B67BEA5'
$OldDesiredPin='852F681A784376BEC87825D5C00AD789EBD21101B17DA06CECBABB1F78F1330E'
$NewDesiredPin='707DCC1CDC0FA8733E5A35E05120706215649441B31122CAAFB9816338CF1003'
$OldBranch="'kevin-autonomy-actuator-v0.1'"
$PinnedRef="'689fcadf9b413cae588242cae0cdf3995bc4a70b'"

$Base=Join-Path $env:TEMP 'KEVIN-AUTONOMY-ACTUATOR-v0.1.base.ps1'
$Patched=Join-Path $env:TEMP 'KEVIN-AUTONOMY-ACTUATOR-v0.1c.patched.ps1'

Write-Host "`n==> Download immutable v0.1 base installer" -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $BaseUrl -OutFile $Base
$h=(Get-FileHash -Algorithm SHA256 -LiteralPath $Base).Hash.ToUpperInvariant()
if($h -ne $BaseHash){throw "BASE INSTALLER HASH MISMATCH. Expected $BaseHash, got $h"}
Write-Host "PASS  Immutable base installer SHA-256 verified." -ForegroundColor Green

$text=[IO.File]::ReadAllText($Base)
$bridgeCount=([regex]::Matches($text,[regex]::Escape($WrongBridge))).Count
$pinCount=([regex]::Matches($text,[regex]::Escape($OldDesiredPin))).Count
$branchCount=([regex]::Matches($text,[regex]::Escape($OldBranch))).Count
if($bridgeCount -ne 1){throw "Expected exactly one Support Bridge typo in base installer; found $bridgeCount. Refusing patch."}
if($pinCount -ne 1){throw "Expected exactly one old desired-state pin in base installer; found $pinCount. Refusing patch."}
if($branchCount -ne 1){throw "Expected exactly one mutable branch reference in base installer; found $branchCount. Refusing patch."}

$text=$text.Replace($WrongBridge,$CorrectBridge).Replace($OldDesiredPin,$NewDesiredPin).Replace($OldBranch,$PinnedRef)
if($text.Contains($WrongBridge)){throw 'Support Bridge typo remains after patch; refusing to run.'}
if($text.Contains($OldDesiredPin)){throw 'Old desired-state pin remains after patch; refusing to run.'}
if($text.Contains($OldBranch)){throw 'Mutable component branch reference remains after patch; refusing to run.'}

[IO.File]::WriteAllText($Patched,$text,(New-Object Text.UTF8Encoding($false)))
Write-Host "PASS  Applied exactly three deterministic corrections." -ForegroundColor Green
Write-Host "INFO  Support Bridge pin: $CorrectBridge" -ForegroundColor DarkGray
Write-Host "INFO  Desired State v1 pin: $NewDesiredPin" -ForegroundColor DarkGray
Write-Host "INFO  Component source pinned to commit: $($PinnedRef.Trim("'"))" -ForegroundColor DarkGray

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Patched
$code=$LASTEXITCODE
if($code -ne 0){exit $code}