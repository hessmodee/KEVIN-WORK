$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
$utf8=New-Object System.Text.UTF8Encoding($false)

function Read-Lf([string]$Path){return ((Get-Content -LiteralPath $Path -Raw) -replace "`r`n","`n")}
function Write-Lf([string]$Path,[string]$Text){[IO.File]::WriteAllText($Path,($Text -replace "`r`n","`n"),$utf8)}
function Replace-One([string]$Text,[string]$Old,[string]$New,[string]$Label){
  $Old=$Old -replace "`r`n","`n";$New=$New -replace "`r`n","`n"
  $count=([regex]::Matches($Text,[regex]::Escape($Old))).Count
  if($count -ne 1){throw "$Label replacement count=$count"}
  return $Text.Replace($Old,$New)
}
function Require-Blob([string]$Path,[string]$Expected){$actual=(& git hash-object -- $Path).Trim();if($actual -cne $Expected){throw "$Path preimage mismatch expected=$Expected actual=$actual"};Write-Host "PASS preimage $Path $actual"}

$worker='control-plane/dispatcher/kevin-mission-worker-v0.1.ps1'
$dispatcher='control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1'
$intake='control-plane/intake/kevin-work-order-intake-v0.1.ps1'
$installer='control-plane/install/KEVIN-CONTROL-PLANE-v1.ps1'
$testCore='.github/scripts/test-control-plane-v1.ps1'
$testIntake='.github/scripts/test-work-order-intake-v1.ps1'
$testInstaller='.github/scripts/test-control-plane-installer-v1.ps1'

Require-Blob $worker '5546b2bc5d6eb87b7f25b3d72214e99fe6636ba8'
Require-Blob $dispatcher '893d2fac2e0ffb5aa536d9d6b02eb49164018d10'
Require-Blob $intake '75709657b6d34ffb24a9e6a9dc968d07e0467557'

# Worker: add one bounded format-recovery model call for candidate and review JSON.
$t=Read-Lf $worker
$old=@'
function Extract-JsonObject([string]$Text){
  if([string]::IsNullOrWhiteSpace($Text)){throw 'Model returned empty visible text.'}
  $t=$Text.Trim();$first=$t.IndexOf('{');$last=$t.LastIndexOf('}')
  if($first -lt 0 -or $last -le $first){throw 'Model response contained no JSON object.'}
  return ($t.Substring($first,$last-$first+1)|ConvertFrom-Json)
}
'@
$new=@'
function Extract-JsonObject([string]$Text){
  if([string]::IsNullOrWhiteSpace($Text)){throw 'Model returned empty visible text.'}
  $t=$Text.Trim();$first=$t.IndexOf('{');$last=$t.LastIndexOf('}')
  if($first -lt 0 -or $last -le $first){throw 'Model response contained no JSON object.'}
  return ($t.Substring($first,$last-$first+1)|ConvertFrom-Json)
}

$script:FormatRecoveryCount=0
function New-FormatRecoveryPrompt([string]$BasePrompt,[string]$Label){
  return ("FORMAT RECOVERY FOR {0}: The previous response contained no JSON object. Do not explain, apologize, use markdown, or discuss the failure. Return exactly one valid JSON object matching the requested schema below. Preserve the mission and all safety constraints. This is the only format-recovery attempt.`n`n{1}" -f $Label,$BasePrompt)
}
function Invoke-AgentJson {
  param(
    [Parameter(Mandatory=$true)]$Runtime,
    [Parameter(Mandatory=$true)][string]$SessionKey,
    [Parameter(Mandatory=$true)][string]$PromptPath,
    [Parameter(Mandatory=$true)][string]$RepairPromptPath,
    [Parameter(Mandatory=$true)][string]$Label,
    [int]$TimeoutSeconds=220
  )
  $primary=Invoke-ExactNative -Executable $Runtime.Node -Argv @($Runtime.Cli,'agent','--agent','kevin-lab-qwen','--session-key',$SessionKey,'--json','--timeout','180','--message-file',$PromptPath) -TimeoutSeconds $TimeoutSeconds -WorkingDirectory $Workspace
  if($primary.ExitCode -ne 0){throw "$Label model run failed exit=$($primary.ExitCode): $($primary.Stderr)"}
  $outer=$primary.Stdout|ConvertFrom-Json;$visible=Extract-AssistantText $outer
  try{return (Extract-JsonObject $visible)}catch{
    $script:FormatRecoveryCount=[int]$script:FormatRecoveryCount+1
    $base=[IO.File]::ReadAllText($PromptPath);$repairPrompt=New-FormatRecoveryPrompt -BasePrompt $base -Label $Label
    [IO.File]::WriteAllText($RepairPromptPath,$repairPrompt,$Utf8)
    if((Get-Item -LiteralPath $RepairPromptPath).Length -gt 20000){throw "$Label format-recovery prompt exceeded 20KB cap."}
    $repair=Invoke-ExactNative -Executable $Runtime.Node -Argv @($Runtime.Cli,'agent','--agent','kevin-lab-qwen','--session-key',("repair-"+$SessionKey),'--json','--timeout','180','--message-file',$RepairPromptPath) -TimeoutSeconds $TimeoutSeconds -WorkingDirectory $Workspace
    if($repair.ExitCode -ne 0){throw "$Label format-recovery model run failed exit=$($repair.ExitCode): $($repair.Stderr)"}
    $repairOuter=$repair.Stdout|ConvertFrom-Json;$repairVisible=Extract-AssistantText $repairOuter
    try{return (Extract-JsonObject $repairVisible)}catch{throw "$Label model JSON contract failed after one bounded format-recovery attempt."}
  }
}
'@
$t=Replace-One $t $old $new 'worker recovery helpers'

$old=@'
if($Mode -eq 'SelfTest'){
  $ids=@($Catalog.missions|ForEach-Object{[string]$_.id})
  if($ids.Count -lt 1){throw 'Mission catalog is empty.'}
  if(($ids|Select-Object -Unique).Count -ne $ids.Count){throw 'Mission catalog contains duplicate ids.'}
  Write-Output ("MISSION_WORKER_SELF_TEST_PASS missions={0}" -f $ids.Count);exit 0
}
'@
$new=@'
if($Mode -eq 'SelfTest'){
  $ids=@($Catalog.missions|ForEach-Object{[string]$_.id})
  if($ids.Count -lt 1){throw 'Mission catalog is empty.'}
  if(($ids|Select-Object -Unique).Count -ne $ids.Count){throw 'Mission catalog contains duplicate ids.'}
  $probe=Extract-JsonObject 'prefix {"ok":true} suffix';if(-not [bool]$probe.ok){throw 'JSON extraction self-test failed.'}
  $rp=New-FormatRecoveryPrompt -BasePrompt 'RETURN CONTRACT' -Label 'Candidate';if($rp -notmatch 'FORMAT RECOVERY FOR Candidate' -or $rp -notmatch 'RETURN CONTRACT'){throw 'Format-recovery prompt self-test failed.'}
  Write-Output ("MISSION_WORKER_SELF_TEST_PASS missions={0} json_recovery=1" -f $ids.Count);exit 0
}
'@
$t=Replace-One $t $old $new 'worker selftest'

$old=@'
  $gen=Invoke-ExactNative -Executable $rt.Node -Argv @($rt.Cli,'agent','--agent','kevin-lab-qwen','--session-key',$session,'--json','--timeout','180','--message-file',$promptPath) -TimeoutSeconds 220 -WorkingDirectory $Workspace
  if($gen.ExitCode -ne 0){throw "Candidate model run failed exit=$($gen.ExitCode): $($gen.Stderr)"}
  $outer=$gen.Stdout|ConvertFrom-Json;$proposal=Extract-JsonObject (Extract-AssistantText $outer)
'@
$new=@'
  $candidateRepairPath=Join-Path $runRoot 'candidate.repair.prompt.txt'
  $proposal=Invoke-AgentJson -Runtime $rt -SessionKey $session -PromptPath $promptPath -RepairPromptPath $candidateRepairPath -Label 'Candidate' -TimeoutSeconds 220
'@
$t=Replace-One $t $old $new 'candidate model invocation'

$old=@'
  $review=Invoke-ExactNative -Executable $rt.Node -Argv @($rt.Cli,'agent','--agent','kevin-lab-qwen','--session-key',("review-$stamp-$MissionId"),'--json','--timeout','180','--message-file',$reviewPath) -TimeoutSeconds 220 -WorkingDirectory $Workspace
  if($review.ExitCode -ne 0){throw "Review model run failed exit=$($review.ExitCode): $($review.Stderr)"}
  $reviewOuter=$review.Stdout|ConvertFrom-Json;$evaluation=Extract-JsonObject (Extract-AssistantText $reviewOuter)
'@
$new=@'
  $reviewRepairPath=Join-Path $runRoot 'review.repair.prompt.txt'
  $evaluation=Invoke-AgentJson -Runtime $rt -SessionKey ("review-$stamp-$MissionId") -PromptPath $reviewPath -RepairPromptPath $reviewRepairPath -Label 'Review' -TimeoutSeconds 220
'@
$t=Replace-One $t $old $new 'review model invocation'

$old='candidate_only=$true;safety=[ordered]@{production_mutation=$false;authority_expansion=$false;generated_code_executed=$false}}'
$new='candidate_only=$true;format_recovery_count=[int]$script:FormatRecoveryCount;safety=[ordered]@{production_mutation=$false;authority_expansion=$false;generated_code_executed=$false}}'
$count=([regex]::Matches($t,[regex]::Escape($old))).Count
if($count -ne 2){throw "worker result recovery-count insertion count=$count"}
$t=$t.Replace($old,$new)
Write-Lf $worker $t

# Dispatcher: surface a sanitized worker root cause through the existing acknowledgement channel.
$t=Read-Lf $dispatcher
$needle=@'
function Normalize-Recent($State,[int]$Max=30){$items=@($State.recent);if($items.Count -gt $Max){$items=@($items|Select-Object -Last $Max)};$State.recent=$items}
'@
$insert=@'
function Sanitize-PublicDetail([AllowEmptyString()][string]$Text){
  if($null -eq $Text){return ''};$s=($Text -replace '[\r\n]+',' ').Trim()
  if($env:USERPROFILE){$s=$s.Replace([string]$env:USERPROFILE,'<HOME>')}
  if($env:USERNAME){$s=$s -replace [regex]::Escape([string]$env:USERNAME),'<USER>'}
  if($s.Length -gt 700){$s=$s.Substring(0,700)}
  return $s
}
function Normalize-Recent($State,[int]$Max=30){$items=@($State.recent);if($items.Count -gt $Max){$items=@($items|Select-Object -Last $Max)};$State.recent=$items}
'@
$t=Replace-One $t $needle $insert 'dispatcher sanitizer'
$old=@'
  Save-State $State;Write-JsonAtomic $result $LatestPath
  Write-Output ("MISSION_DISPATCHER_RESULT mission={0} state={1} worker={2}" -f $mission,$result.state,$workerState)
  if($result.state -eq 'DISPATCH_INFRA_FAILURE'){exit 2};exit 0
'@
$new=@'
  Save-State $State;Write-JsonAtomic $result $LatestPath
  if($result.state -eq 'DISPATCH_INFRA_FAILURE'){
    $publicDetail=Sanitize-PublicDetail ([string]$result.worker_error)
    Write-Output ("MISSION_DISPATCHER_RESULT mission={0} state={1} worker={2} detail={3}" -f $mission,$result.state,$workerState,$publicDetail)
    exit 2
  }
  Write-Output ("MISSION_DISPATCHER_RESULT mission={0} state={1} worker={2}" -f $mission,$result.state,$workerState)
  exit 0
'@
$t=Replace-One $t $old $new 'dispatcher failure detail'
Write-Lf $dispatcher $t

# Intake: a schema-valid execution failure becomes terminal for that idempotency key.
$t=Read-Lf $intake
$old=@'
  try{
    Validate-Order $o
'@
$new=@'
  $validated=$false;$ledgerRecorded=$false
  try{
    Validate-Order $o;$validated=$true
'@
$t=Replace-One $t $old $new 'intake validation flags'
$old=@'
    $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=$oid;idempotency_key=$oIdem;verb=$oVerb;target=$oTarget;completed_at=(Get-Date).ToString('o');status='VERIFIED'});Save-Ledger $ledger
'@
$new=@'
    $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=$oid;idempotency_key=$oIdem;verb=$oVerb;target=$oTarget;completed_at=(Get-Date).ToString('o');status='VERIFIED'});Save-Ledger $ledger;$ledgerRecorded=$true
'@
$t=Replace-One $t $old $new 'intake verified ledger flag'
$old=@'
  }catch{
    $ack.status='FAILED';$ack.detail=One-Line $_.Exception.Message;Write-JsonAtomic $ack $LatestPath;try{Publish-Ack $ack}catch{};Write-Output ("WORK_ORDER_FAILED id={0} detail={1}" -f $ack.order_id,$ack.detail);exit 2
  }
'@
$new=@'
  }catch{
    $ack.status='FAILED';$ack.detail=One-Line $_.Exception.Message
    if($validated -and -not $ledgerRecorded -and $oIdem){
      $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=$(if($oid){[string]$oid}else{''});idempotency_key=[string]$oIdem;verb=$(if($oVerb){[string]$oVerb}else{''});target=$(if($oTarget){[string]$oTarget}else{''});completed_at=(Get-Date).ToString('o');status='FAILED'});Save-Ledger $ledger;$ledgerRecorded=$true
    }
    Write-JsonAtomic $ack $LatestPath;try{Publish-Ack $ack}catch{};Write-Output ("WORK_ORDER_FAILED id={0} detail={1}" -f $ack.order_id,$ack.detail);exit 2
  }
'@
$t=Replace-One $t $old $new 'intake terminal failure ledger'
Write-Lf $intake $t

# Strengthen runtime tests with the exact failures observed on Kevin.
$t=Read-Lf $testCore
$old=@'
  Write-Host ($inspectOut -join "`n")

  $intakeOut=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode SelfTest
'@
$new=@'
  Write-Host ($inspectOut -join "`n")

  $dispatchFail=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-mission-dispatcher-v0.1.ps1') -Mode Dispatch -RequestedMission checkpoint-resume 2>&1
  $dispatchFailCode=$LASTEXITCODE
  if($dispatchFailCode -ne 2 -or ($dispatchFail -join "`n") -notmatch 'detail=.*helper_system_status.py missing'){throw "Dispatcher did not surface sanitized worker root cause: exit=$dispatchFailCode output=$($dispatchFail -join ' | ')"}
  Write-Host 'PASS dispatcher failure detail propagation.'

  $intakeOut=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode SelfTest
'@
$t=Replace-One $t $old $new 'core runtime dispatcher failure test'
$old="if(`$intake -match 'command_string|shell_command|arbitrary_command'){throw 'Intake exposes command-string authority.'}`nWrite-Host 'PASS authority/static contracts.'"
$new="if(`$intake -match 'command_string|shell_command|arbitrary_command'){throw 'Intake exposes command-string authority.'}`n`$workerText=Get-Content 'control-plane/dispatcher/kevin-mission-worker-v0.1.ps1' -Raw;if(-not `$workerText.Contains('FORMAT RECOVERY FOR') -or -not `$workerText.Contains('format_recovery_count')){throw 'Worker format-recovery contract missing.'}`n`$dispatcherText=Get-Content 'control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1' -Raw;if(-not `$dispatcherText.Contains('Sanitize-PublicDetail') -or -not `$dispatcherText.Contains('detail={3}')){throw 'Dispatcher public failure-detail contract missing.'}`nWrite-Host 'PASS authority/static contracts.'"
$t=Replace-One $t $old $new 'core static recovery contract'
Write-Lf $testCore $t

$t=Read-Lf $testIntake
$old=@'
      if (mode=="malformed") {
        order="{\"schema\":1,\"kind\":\"kevin-work-order\",\"idempotency_key\":\"malformed-key-001\",\"created_at\":\""+created+"\",\"expires_at\":\""+expires+"\",\"authority_class\":\"GREEN\",\"verb\":\"run_reconcile\",\"target\":\"autonomy\"}";
      } else {
'@
$new=@'
      if (mode=="malformed") {
        order="{\"schema\":1,\"kind\":\"kevin-work-order\",\"idempotency_key\":\"malformed-key-001\",\"created_at\":\""+created+"\",\"expires_at\":\""+expires+"\",\"authority_class\":\"GREEN\",\"verb\":\"run_reconcile\",\"target\":\"autonomy\"}";
      } else if (mode=="execution_failure") {
        order="{\"schema\":1,\"kind\":\"kevin-work-order\",\"id\":\"ci-order-fail1\",\"idempotency_key\":\"ci-idem-fail1\",\"created_at\":\""+created+"\",\"expires_at\":\""+expires+"\",\"authority_class\":\"GREEN\",\"verb\":\"run_benchmark\",\"target\":\"kevin-benchmark-v1\",\"reason\":\"CI terminal failure replay regression\"}";
      } else {
'@
$t=Replace-One $t $old $new 'intake fake execution failure order'
$old=@'
  $env:FAKE_ORDER_MODE='malformed'
  $third=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode Poll 2>&1
  if($LASTEXITCODE -ne 2 -or ($third -join "`n") -notmatch 'WORK_ORDER_FAILED'){throw "Malformed order did not fail cleanly: exit=$LASTEXITCODE output=$($third -join ' | ')"}
  Write-Host ($third -join "`n")

  Write-Host 'WORK_ORDER_INTAKE_E2E_PASS'
'@
$new=@'
  $env:FAKE_ORDER_MODE='execution_failure'
  $third=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode Poll 2>&1
  if($LASTEXITCODE -ne 2 -or ($third -join "`n") -notmatch 'WORK_ORDER_FAILED'){throw "Valid execution failure did not fail cleanly: exit=$LASTEXITCODE output=$($third -join ' | ')"}
  $failedLatest=Get-Content (Join-Path $reports 'work-order-latest.json') -Raw|ConvertFrom-Json;if($failedLatest.status -ne 'FAILED'){throw 'Execution failure acknowledgement was not retained.'}
  $ledger=Get-Content (Join-Path $cp 'State\work-order-ledger-v1.json') -Raw|ConvertFrom-Json;if(@($ledger.processed|Where-Object{$_.idempotency_key -eq 'ci-idem-fail1' -and $_.status -eq 'FAILED'}).Count -ne 1){throw 'Execution failure was not terminalized in idempotency ledger.'}
  $fourth=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode Poll
  if($LASTEXITCODE -ne 0 -or ($fourth -join "`n") -notmatch 'WORK_ORDER_REPLAY_IGNORED'){throw "Failed-order replay was not ignored: $($fourth -join ' | ')"}
  $afterReplay=Get-Content (Join-Path $reports 'work-order-latest.json') -Raw|ConvertFrom-Json;if($afterReplay.status -ne 'FAILED'){throw 'Replay overwrote the terminal FAILED acknowledgement.'}
  Write-Host 'PASS schema-valid execution failure is terminal and replay-safe.'

  $env:FAKE_ORDER_MODE='malformed'
  $fifth=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode Poll 2>&1
  if($LASTEXITCODE -ne 2 -or ($fifth -join "`n") -notmatch 'WORK_ORDER_FAILED'){throw "Malformed order did not fail cleanly: exit=$LASTEXITCODE output=$($fifth -join ' | ')"}
  Write-Host ($fifth -join "`n")

  Write-Host 'WORK_ORDER_INTAKE_E2E_PASS'
'@
$t=Replace-One $t $old $new 'intake terminal failure regression'
Write-Lf $testIntake $t

# Repin fresh-install package and its pin regression to the repaired components.
$newWorker=(& git hash-object -- $worker).Trim();$newDispatcher=(& git hash-object -- $dispatcher).Trim();$newIntake=(& git hash-object -- $intake).Trim()
foreach($p in @($installer,$testInstaller)){
  $x=Read-Lf $p
  $x=$x.Replace('5546b2bc5d6eb87b7f25b3d72214e99fe6636ba8',$newWorker)
  $x=$x.Replace('893d2fac2e0ffb5aa536d9d6b02eb49164018d10',$newDispatcher)
  $x=$x.Replace('75709657b6d34ffb24a9e6a9dc968d07e0467557',$newIntake)
  Write-Lf $p $x
}

# Parse everything before running tests.
foreach($p in @($worker,$dispatcher,$intake,$installer,$testCore,$testIntake,$testInstaller)){
  $tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $p),[ref]$tokens,[ref]$errors)
  if($errors -and $errors.Count){$m=($errors|ForEach-Object{"$p line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; ';throw $m}
}
Write-Host "NEW_WORKER_BLOB=$newWorker"
Write-Host "NEW_DISPATCHER_BLOB=$newDispatcher"
Write-Host "NEW_INTAKE_BLOB=$newIntake"

& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $testCore
if($LASTEXITCODE -ne 0){throw 'Control-plane core test failed after repair.'}
& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $testIntake
if($LASTEXITCODE -ne 0){throw 'Work-order intake E2E failed after repair.'}
& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $testInstaller
if($LASTEXITCODE -ne 0){throw 'Fresh-install pin/transport test failed after repair.'}
Write-Host 'CONTROL_PLANE_V11_PATCH_TEST_PASS'
