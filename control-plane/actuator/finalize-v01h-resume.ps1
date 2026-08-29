Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$p='control-plane/actuator/KEVIN-AUTONOMY-RESUME-v0.1h.ps1'
$text=Get-Content -LiteralPath $p -Raw
$repls=[ordered]@{
  "version='0.1f'"="version='0.1h'"
  "openclaw automations remove '`$rId' --json | Out-Null"="openclaw cron remove '`$rId' --json | Out-Null"
  "openclaw automations remove '`$bId' --json | Out-Null"="openclaw cron remove '`$bId' --json | Out-Null"
  "Typed job verification: automations get <job-id>"="Typed job verification: cron get <job-id>"
}
foreach($kv in $repls.GetEnumerator()){
  $count=([regex]::Matches($text,[regex]::Escape([string]$kv.Key))).Count
  if($count -ne 1){throw "Expected finalization target exactly once; count=${count}; target=$($kv.Key)"}
  $text=$text.Replace([string]$kv.Key,[string]$kv.Value)
}
[IO.File]::WriteAllText((Join-Path (Get-Location) $p),$text,(New-Object Text.UTF8Encoding($false)))
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $p),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'Final v0.1h resume parse failed'}
$check=Get-Content -LiteralPath $p -Raw
if($check -match 'openclaw automations'){throw 'Rollback still contains old automations CLI namespace'}
if($check -match 'Typed job verification: automations'){throw 'Proof text still contains old automations label'}
if($check -notmatch [regex]::Escape("version='0.1h'")){throw 'Install manifest version was not corrected'}
if($check -notmatch [regex]::Escape("openclaw cron remove '`$rId' --json")){throw 'Reconciler rollback cron removal missing'}
if($check -notmatch [regex]::Escape("openclaw cron remove '`$bId' --json")){throw 'Telemetry rollback cron removal missing'}
Write-Host 'PASS final v0.1h resume cleanup and parse.'
