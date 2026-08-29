$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
$old='2e7c87912638242e490f0d12d39b87b1428cb363'
$new='75709657b6d34ffb24a9e6a9dc968d07e0467557'
$paths=@('control-plane/install/KEVIN-CONTROL-PLANE-v1.ps1','.github/scripts/test-control-plane-installer-v1.ps1')
foreach($p in $paths){
  $t=Get-Content -LiteralPath $p -Raw
  $count=([regex]::Matches($t,[regex]::Escape($old))).Count
  if($count -ne 1){throw "Expected exactly one old intake pin in ${p}; found $count"}
  $t=$t.Replace($old,$new)
  [IO.File]::WriteAllText($p,$t,(New-Object Text.UTF8Encoding($false)))
}
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'control-plane/install/KEVIN-CONTROL-PLANE-v1.ps1'),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){throw 'Repinned installer failed PowerShell parse.'}
Write-Host 'PASS final installer/test repinned to replay-safe intake.'
