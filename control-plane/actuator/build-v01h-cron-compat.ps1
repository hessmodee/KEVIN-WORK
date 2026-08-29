Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'

$act='control-plane/actuator/kevin-autonomy-actuator-v0.1.ps1'
$src='control-plane/actuator/KEVIN-AUTONOMY-RESUME-v0.1g.ps1'
$dst='control-plane/actuator/KEVIN-AUTONOMY-RESUME-v0.1h.ps1'

function Parse-Ps([string]$Path){
  $tokens=$null;$errors=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path),[ref]$tokens,[ref]$errors)
  if($errors -and $errors.Count){
    $errors|ForEach-Object{Write-Error ("line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)}
    throw "PowerShell parse failed: $Path"
  }
}

# Patch the reconciler to the scheduler vocabulary/schema actually shipped by OpenClaw 2026.7.1-2.
$a=Get-Content -LiteralPath $act -Raw
$nsCount=([regex]::Matches($a,[regex]::Escape("'automations'"))).Count
if($nsCount -lt 5){throw "Expected at least 5 scheduler namespace calls in reconciler; found $nsCount"}
$a=$a.Replace("'automations'","'cron'")

$exactRepls=[ordered]@{
  "@('cron','run',`$JobId,'--wait','--wait-timeout',(""{0}m"" -f `$WaitMinutes),'--poll-interval','2s','--json')" = "@('cron','run',`$JobId,'--wait','--wait-timeout',(""{0}m"" -f `$WaitMinutes),'--poll-interval','2s')"
  "@('cron','runs','--id',`$JobId,'--limit','3','--json')" = "@('cron','runs','--id',`$JobId,'--limit','3')"
  "@('cron','enable',`$job.id,'--json')" = "@('cron','enable',`$job.id)"
  "@('cron','get',`$job.id,'--json')" = "@('cron','get',`$job.id)"
}
foreach($kv in $exactRepls.GetEnumerator()){
  $count=([regex]::Matches($a,[regex]::Escape([string]$kv.Key))).Count
  if($count -ne 1){throw "Expected exactly one reconciler compatibility target, found $count: $($kv.Key)"}
  $a=$a.Replace([string]$kv.Key,[string]$kv.Value)
}

# Stable cron.runs returns { entries: [...] }, not { runs: [...] }.
$oldItems="if (`$runs -and (`$runs.PSObject.Properties.Name -contains 'runs')) { `$items=@(`$runs.runs) } elseif (`$runs) { `$items=@(`$runs) }"
$newItems="if (`$runs -and (`$runs.PSObject.Properties.Name -contains 'entries')) { `$items=@(`$runs.entries) } elseif (`$runs -and (`$runs.PSObject.Properties.Name -contains 'runs')) { `$items=@(`$runs.runs) } elseif (`$runs) { `$items=@(`$runs) }"
if(([regex]::Matches($a,[regex]::Escape($oldItems))).Count -ne 1){throw 'Expected run-history parser target not found exactly once.'}
$a=$a.Replace($oldItems,$newItems)

if($a -match [regex]::Escape("'automations'")){throw 'Reconciler still contains executable automations namespace.'}
if($a -match "@\('cron','(?:get|enable|run|runs)'[^\r\n]*'--json'"){throw 'Unsupported --json remains on stable cron simple command.'}
[IO.File]::WriteAllText((Join-Path (Get-Location) $act),$a,(New-Object Text.UTF8Encoding($false)))
Parse-Ps $act
$newBlob=(git hash-object $act).Trim().ToLowerInvariant()
if($LASTEXITCODE -ne 0 -or $newBlob -notmatch '^[0-9a-f]{40}$'){throw "Could not compute reconciler Git blob: $newBlob"}

# Build a resume from the already validated v0.1g package, but make it compatible with the installed stable CLI.
$t=Get-Content -LiteralPath $src -Raw
$t=$t.Replace('v0.1g','v0.1h')
$t=$t.Replace("`$OldActuatorBlob='ef1e7f9ea6847e6d963af0cd40c28735573bc26d'","`$OldActuatorBlob='489dfd2277245341a790c00a5db04ecd3ffb4fab'")
$t=$t.Replace("`$NewActuatorBlob='489dfd2277245341a790c00a5db04ecd3ffb4fab'","`$NewActuatorBlob='$newBlob'")
$t=$t.Replace("'automations'","'cron'")

# cron get emits JSON directly but does not accept --json in 2026.7.1-2.
$t=$t.Replace("@('cron','get',`$rId,'--json')","@('cron','get',`$rId)")
$t=$t.Replace("@('cron','get',`$bId,'--json')","@('cron','get',`$bId)")

# cron run emits JSON directly but does not accept --json in 2026.7.1-2.
$t=$t.Replace("@('cron','run',`$rId,'--wait','--wait-timeout','5m','--poll-interval','2s','--json')","@('cron','run',`$rId,'--wait','--wait-timeout','5m','--poll-interval','2s')")

if($t -match [regex]::Escape("'automations'")){throw 'Resume still contains executable automations namespace.'}
if($t -match "@\('cron','(?:get|enable|run|runs)'[^\r\n]*'--json'"){throw 'Resume retains unsupported --json on stable cron simple command.'}
if($t -notmatch [regex]::Escape("@('cron','create','*/3 * * * *'")){throw 'Reconciler cron create call missing.'}
if($t -notmatch [regex]::Escape("@('cron','create','*/5 * * * *'")){throw 'Telemetry cron create call missing.'}
if($t -notmatch [regex]::Escape("@('cron','get',`$rId)")){throw 'Reconciler cron get verification missing.'}
if($t -notmatch [regex]::Escape("@('cron','get',`$bId)")){throw 'Telemetry cron get verification missing.'}
if($t -notmatch [regex]::Escape("`$OldActuatorBlob='489dfd2277245341a790c00a5db04ecd3ffb4fab'")){throw 'Current installed actuator pin missing.'}
if($t -notmatch [regex]::Escape("`$NewActuatorBlob='$newBlob'")){throw 'New cron-compatible actuator pin missing.'}
[IO.File]::WriteAllText((Join-Path (Get-Location) $dst),$t,(New-Object Text.UTF8Encoding($false)))
Parse-Ps $dst

Write-Host "PASS built cron-compatible reconciler and resume v0.1h."
Write-Host "ACTUATOR_BLOB=$newBlob"
