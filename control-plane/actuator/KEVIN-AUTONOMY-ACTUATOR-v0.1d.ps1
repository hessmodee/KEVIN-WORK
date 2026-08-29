Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# v0.1d bootstrap repair:
# - verifies immutable Git objects using Git blob SHA-1, not manually transcribed raw-file SHA-256
# - fixes the one-character Support Bridge core-hash typo in the original installer
# - pins all component downloads to one immutable commit
# - replaces component raw SHA-256 pins with Git blob IDs read directly from that commit

$BaseUrl='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/b80c4d0059d9bb5a952aa752d4de31b45b2c3f5c/control-plane/actuator/KEVIN-AUTONOMY-ACTUATOR-v0.1.ps1'
$BaseBlob='e0dec2d3c37b407274bc4fa964e63947b8db5fd7'
$ComponentRef='689fcadf9b413cae588242cae0cdf3995bc4a70b'
$WrongBridge='E72A2A635326CF1AB036404E64E274D2F56E79CA5CEB268DBF9B2EA4B67BEA5'
$CorrectBridge='E72A2A635326CF1AB036404E64E274D2F56CE79CA5CEB268DBF9B2EA4B67BEA5'
$OldBranch="'kevin-autonomy-actuator-v0.1'"
$PinnedRef=("'{0}'" -f $ComponentRef)

$ComponentBlobs=[ordered]@{
 'desired-state-v1.json'='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
 'OWNER-AUTHORIZATION-v1.md'='b0cc4465f12457492b3a6c2761287398cc6295b5'
 'kevin-autonomy-actuator-v0.1.ps1'='38bc72bc29569c72c3618b0b8ce8fa59876ba76c'
 'kevin-autonomy-bridge-v0.1.ps1'='05bb7d3a01d9eace3105a717020656a040f4da8c'
}

function Step([string]$s){Write-Host ("`n==> "+$s) -ForegroundColor Cyan}
function Good([string]$s){Write-Host ("PASS  "+$s) -ForegroundColor Green}

function Get-GitBlobSha1 {
    param([Parameter(Mandatory=$true)][string]$Path)
    $bytes=[IO.File]::ReadAllBytes($Path)
    $header=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $bytes.Length))
    $all=New-Object byte[] ($header.Length+1+$bytes.Length)
    [Buffer]::BlockCopy($header,0,$all,0,$header.Length)
    $all[$header.Length]=0
    [Buffer]::BlockCopy($bytes,0,$all,$header.Length+1,$bytes.Length)
    $sha=[Security.Cryptography.SHA1]::Create()
    try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}
    finally{$sha.Dispose()}
}

$Base=Join-Path $env:TEMP 'KEVIN-AUTONOMY-ACTUATOR-v0.1.base.ps1'
$Patched=Join-Path $env:TEMP 'KEVIN-AUTONOMY-ACTUATOR-v0.1d.patched.ps1'

Step 'Download and verify immutable base installer'
Invoke-WebRequest -UseBasicParsing -Uri $BaseUrl -OutFile $Base
$baseActual=Get-GitBlobSha1 $Base
if($baseActual -ne $BaseBlob){throw "BASE GIT BLOB MISMATCH. Expected $BaseBlob, got $baseActual"}
Good "Base Git blob verified: $baseActual"

$text=[IO.File]::ReadAllText($Base)

# 1. Correct the exact Support Bridge core pin typo.
$bridgeCount=([regex]::Matches($text,[regex]::Escape($WrongBridge))).Count
if($bridgeCount -ne 1){throw "Expected exactly one Support Bridge typo; found $bridgeCount. Refusing patch."}
$text=$text.Replace($WrongBridge,$CorrectBridge)

# 2. Replace mutable component branch with immutable commit.
$branchCount=([regex]::Matches($text,[regex]::Escape($OldBranch))).Count
if($branchCount -ne 1){throw "Expected exactly one mutable component branch reference; found $branchCount. Refusing patch."}
$text=$text.Replace($OldBranch,$PinnedRef)

# 3. Replace the original raw SHA-256 pin table with Git blob IDs from the immutable component commit.
$pinsPattern='(?ms)^\$Pins=\[ordered\]@\{.*?^\}\r?\n\$Sources='
$pinsMatches=[regex]::Matches($text,$pinsPattern)
if($pinsMatches.Count -ne 1){throw "Expected exactly one component pin table; found $($pinsMatches.Count). Refusing patch."}
$newPins=@'
$Pins=[ordered]@{
 'desired-state-v1.json'='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
 'OWNER-AUTHORIZATION-v1.md'='b0cc4465f12457492b3a6c2761287398cc6295b5'
 'kevin-autonomy-actuator-v0.1.ps1'='38bc72bc29569c72c3618b0b8ce8fa59876ba76c'
 'kevin-autonomy-bridge-v0.1.ps1'='05bb7d3a01d9eace3105a717020656a040f4da8c'
}
$Sources=
'@
$text=[regex]::Replace($text,$pinsPattern,[System.Text.RegularExpressions.MatchEvaluator]{param($m)$newPins},1)

# 4. Add Git blob verifier to the patched base installer.
$insertMarker='function Write-JsonAtomic'
$markerIndex=$text.IndexOf($insertMarker,[StringComparison]::Ordinal)
if($markerIndex -lt 0){throw 'Could not find insertion marker for Git blob verifier.'}
$gitVerifier=@'
function Get-GitBlobSha1 {
 param([Parameter(Mandatory=$true)][string]$Path)
 $bytes=[IO.File]::ReadAllBytes($Path)
 $header=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $bytes.Length))
 $all=New-Object byte[] ($header.Length+1+$bytes.Length)
 [Buffer]::BlockCopy($header,0,$all,0,$header.Length)
 $all[$header.Length]=0
 [Buffer]::BlockCopy($bytes,0,$all,$header.Length+1,$bytes.Length)
 $sha=[Security.Cryptography.SHA1]::Create()
 try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}
 finally{$sha.Dispose()}
}

'@
$text=$text.Insert($markerIndex,$gitVerifier)

# 5. Replace component SHA-256 verification with Git blob verification.
$oldVerify=@'
$hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $tmp).Hash.ToUpperInvariant();if($hash -ne $Pins[$name]){throw "HASH MISMATCH for $name. Expected $($Pins[$name]), got $hash"};Good "$name SHA-256 $hash"
'@
$newVerify=@'
$blob=Get-GitBlobSha1 $tmp;if($blob -ne [string]$Pins[$name]){throw "GIT BLOB MISMATCH for $name. Expected $($Pins[$name]), got $blob"};Good "$name Git blob $blob"
'@
$verifyCount=([regex]::Matches($text,[regex]::Escape($oldVerify.Trim()))).Count
if($verifyCount -ne 1){throw "Expected exactly one component SHA-256 verification statement; found $verifyCount. Refusing patch."}
$text=$text.Replace($oldVerify.Trim(),$newVerify.Trim())

# Fail closed if any known unsafe/original bootstrap references remain.
if($text.Contains($WrongBridge)){throw 'Wrong Support Bridge pin remains after patch.'}
if($text.Contains($OldBranch)){throw 'Mutable component branch remains after patch.'}
if($text.Contains('Get-FileHash -Algorithm SHA256 -LiteralPath $tmp')){throw 'Old component raw SHA-256 verification remains after patch.'}
foreach($kv in $ComponentBlobs.GetEnumerator()){
    if(-not $text.Contains([string]$kv.Value)){throw "Expected Git blob pin missing after patch: $($kv.Key)"}
}

[IO.File]::WriteAllText($Patched,$text,(New-Object Text.UTF8Encoding($false)))
Good 'Applied deterministic bootstrap hardening.'
Write-Host "INFO  Correct Support Bridge core pin: $CorrectBridge" -ForegroundColor DarkGray
Write-Host "INFO  Component source commit: $ComponentRef" -ForegroundColor DarkGray
Write-Host 'INFO  Component integrity: Git blob verification' -ForegroundColor DarkGray

Step 'Launch corrected autonomy installer'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Patched
$code=$LASTEXITCODE
if($code -ne 0){exit $code}
