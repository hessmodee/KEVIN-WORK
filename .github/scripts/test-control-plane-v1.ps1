$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0

$files=@(
  'control-plane/dispatcher/kevin-mission-worker-v0.1.ps1',
  'control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1',
  'control-plane/intake/kevin-work-order-intake-v0.1.ps1'
)
foreach($p in $files){
  $tokens=$null;$errors=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $p),[ref]$tokens,[ref]$errors)
  if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("$p line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw "Parse failed: $p"}
  Write-Host "PASS parse $p"
}

$catalog=Get-Content 'control-plane/dispatcher/mission-catalog-v1.json' -Raw|ConvertFrom-Json
$schema=Get-Content 'control-plane/schemas/work-order-v1.schema.json' -Raw|ConvertFrom-Json
if($catalog.kind -ne 'kevin-mission-catalog' -or $catalog.version -ne '1.0'){throw 'Catalog contract invalid.'}
if(@($catalog.missions).Count -ne 6){throw 'Expected six initial mission catalog entries.'}
if(-not $catalog.policy.candidate_only -or $catalog.policy.allow_arbitrary_shell -or $catalog.policy.allow_production_mutation){throw 'Catalog authority boundary invalid.'}
if($schema.properties.verb.enum.Count -ne 5){throw 'Unexpected work-order verb count.'}
Write-Host 'PASS JSON contracts.'

$repo=(Resolve-Path '.').Path
$fakeProfile=Join-Path $env:TEMP ('kevin-cp-v1-'+[guid]::NewGuid().ToString('N'))
$oldProfile=$env:USERPROFILE
try{
  $env:USERPROFILE=$fakeProfile
  $ws=Join-Path $fakeProfile '.openclaw\workspace'
  $cp=Join-Path $ws 'ControlPlane'
  $reports=Join-Path $ws 'reports'
  New-Item -ItemType Directory -Path $cp,$reports -Force|Out-Null
  Copy-Item 'control-plane/dispatcher/mission-catalog-v1.json' (Join-Path $cp 'mission-catalog-v1.json')
  Copy-Item 'control-plane/dispatcher/kevin-mission-worker-v0.1.ps1' (Join-Path $cp 'kevin-mission-worker-v0.1.ps1')
  Copy-Item 'control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1' (Join-Path $cp 'kevin-mission-dispatcher-v0.1.ps1')
  Copy-Item 'control-plane/intake/kevin-work-order-intake-v0.1.ps1' (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1')
  Copy-Item 'control-plane/actuator/kevin-autonomy-actuator-v0.1.ps1' (Join-Path $cp 'kevin-autonomy-actuator-v0.1.ps1')
  Copy-Item 'control-plane/actuator/kevin-autonomy-bridge-v0.1l.ps1' (Join-Path $cp 'kevin-autonomy-bridge-v0.1.ps1')

  $now=(Get-Date).ToString('o')
  $support=[ordered]@{generated_at=$now;governance=[ordered]@{ok=$true};benchmark=[ordered]@{status='PASS'};supervisor=[ordered]@{last_result='RECOVERY_SATURATED'};active_workers=[ordered]@{design_forge=0;night_forge=0;supervisor=0;benchmark=0}}
  $autonomy=[ordered]@{generated_at=$now;state='HEALTHY';work_conserving=[ordered]@{next_suggested_candidate='checkpoint-resume'}}
  [IO.File]::WriteAllText((Join-Path $reports 'support-latest.json'),($support|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)))
  [IO.File]::WriteAllText((Join-Path $reports 'autonomy-latest.json'),($autonomy|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)))

  $workerOut=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-mission-worker-v0.1.ps1') -Mode SelfTest
  if($LASTEXITCODE -ne 0 -or ($workerOut -join "`n") -notmatch 'MISSION_WORKER_SELF_TEST_PASS'){throw "Worker self-test failed: $($workerOut -join ' | ')"}
  Write-Host ($workerOut -join "`n")

  $dispOut=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-mission-dispatcher-v0.1.ps1') -Mode SelfTest
  if($LASTEXITCODE -ne 0 -or ($dispOut -join "`n") -notmatch 'MISSION_DISPATCHER_SELF_TEST_PASS'){throw "Dispatcher self-test failed: $($dispOut -join ' | ')"}
  Write-Host ($dispOut -join "`n")

  $inspectOut=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-mission-dispatcher-v0.1.ps1') -Mode Inspect
  if($LASTEXITCODE -ne 0 -or ($inspectOut -join "`n") -notmatch 'eligible=True'){throw "Dispatcher inspect failed: $($inspectOut -join ' | ')"}
  $dispatchReport=Get-Content (Join-Path $reports 'mission-dispatch-latest.json') -Raw|ConvertFrom-Json
  if(-not $dispatchReport.eligible -or -not $dispatchReport.supervisor_blocked_or_cooling){throw 'Dispatcher healthy-state eligibility report was not truthful.'}
  Write-Host ($inspectOut -join "`n")

  $intakeOut=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode SelfTest
  if($LASTEXITCODE -ne 0 -or ($intakeOut -join "`n") -notmatch 'WORK_ORDER_INTAKE_SELF_TEST_PASS'){throw "Intake self-test failed: $($intakeOut -join ' | ')"}
  Write-Host ($intakeOut -join "`n")
} finally {
  $env:USERPROFILE=$oldProfile
  Remove-Item -LiteralPath $fakeProfile -Recurse -Force -ErrorAction SilentlyContinue
}

foreach($p in $files){
  $t=Get-Content $p -Raw
  foreach($bad in @('Invoke-Expression','iex ','allow_arbitrary_shell=$true','allow_production_mutation=$true')){if($t -match [regex]::Escape($bad)){throw "Forbidden authority pattern '$bad' in $p"}}
}
$intake=Get-Content 'control-plane/intake/kevin-work-order-intake-v0.1.ps1' -Raw
foreach($verb in @('dispatch_mission','run_reconcile','run_benchmark','run_support_bridge','refresh_autonomy_telemetry')){if(-not $intake.Contains($verb)){throw "Missing typed verb: $verb"}}
if($intake -match 'command_string|shell_command|arbitrary_command'){throw 'Intake exposes command-string authority.'}
Write-Host 'PASS authority/static contracts.'
Write-Host 'CONTROL_PLANE_V1_TEST_PASS'
