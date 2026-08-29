$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
$p='control-plane/install/KEVIN-CONTROL-PLANE-v1.ps1'
$t=Get-Content -LiteralPath $p -Raw
$old='throw "GitHub blob fetch failed for $Blob: $(One-Line ($r.Stdout+'' ''+$r.Stderr))"'
$new='throw "GitHub blob fetch failed for ${Blob}: $(One-Line ($r.Stdout+'' ''+$r.Stderr))"'
if(([regex]::Matches($t,[regex]::Escape($old))).Count -ne 1){throw 'Expected exactly one $Blob: parser defect.'}
$t=$t.Replace($old,$new)
[IO.File]::WriteAllText($p,$t,(New-Object Text.UTF8Encoding($false)))
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $p),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'Installer still has parser errors.'}
Write-Host 'PASS installer parser correction.'
