param([string]$Runner='control-plane/maintenance/kevin-maintenance-runner-v1.3.44.ps1')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner),[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0].Message}
foreach($name in @('Enter-MaintenanceMutex','Read-Attempts','Get-AttemptRecord','Save-Attempt','Write-JsonAtomic','Write-Utf8Atomic','Process-Typed')){
 $fn=$ast.Find({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$name},$true)
 if(-not$fn){throw "missing $name"};. ([scriptblock]::Create($fn.Extent.Text))
}
$held=Enter-MaintenanceMutex
if($null-eq$held){throw 'first mutex acquisition failed'}
try{
 $definition=(Get-Command Enter-MaintenanceMutex).Definition
 $job=Start-Job -ScriptBlock {param($body);function Enter-MaintenanceMutex {};Set-Item Function:Enter-MaintenanceMutex ([scriptblock]::Create($body));$m=Enter-MaintenanceMutex;if($null-ne$m){$m.ReleaseMutex();$m.Dispose();return 'UNEXPECTED_OWNER'};return 'BUSY'} -ArgumentList $definition
 $result=$job|Wait-Job -Timeout 30|Receive-Job
 if($result-ne'BUSY'){throw 'concurrent maintenance process acquired mutex'}
 $job|Remove-Job -Force
}finally{$held.ReleaseMutex();$held.Dispose()}
$held=Enter-MaintenanceMutex;if($null-eq$held){throw 'lock did not release'};$held.ReleaseMutex();$held.Dispose()
$Utf8=New-Object Text.UTF8Encoding($false);$MaxAttempts=3
$root=Join-Path $env:RUNNER_TEMP ('maintenance-journal-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory $root|Out-Null
$AttemptPath=Join-Path $root 'attempts.json'
function Assert-Common($m){}
function Assert-Governance{}
function Save-State($a,$b,$c,$d){}
function Audit-RuntimeConvergence {
 $saved=Read-Attempts
 if($saved.items[0].status-ne'IN_PROGRESS'-or$saved.items[0].attempts-ne$script:ExpectedAttempts){throw 'attempt not reserved before effect'}
 $script:SeenReservation=$true
 throw 'INTENTIONAL_EFFECT_FAILURE'
}
$m=[pscustomobject]@{id='journal-fixture';operation='audit_runtime_convergence'}
try{
 $script:ExpectedAttempts=1;$script:SeenReservation=$false
 try{Process-Typed $m}catch{}
 if(-not$script:SeenReservation){throw 'effect ran before durable reservation'}
 # Simulate restart after pre-effect reservation, with no terminal write.
 Save-Attempt 'journal-fixture' 1 'IN_PROGRESS'
 $script:ExpectedAttempts=2;$script:SeenReservation=$false
 try{Process-Typed $m}catch{}
 if(-not$script:SeenReservation){throw 'restart lost prior attempt'}
 [IO.File]::WriteAllText($AttemptPath,'BROKEN')
 $blocked=$false;try{Read-Attempts|Out-Null}catch{$blocked=$true};if(-not$blocked){throw 'corrupt budget reset'}
 Write-Host 'MAINTENANCE_EXCLUSION_PASS concurrent_process_blocked=true released=true pre_effect_journal=true restart_budget_retained=true corrupt_state_rejected=true'
}finally{Remove-Item -LiteralPath $root -Recurse -Force}
