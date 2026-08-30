from pathlib import Path

worker_path = Path('control-plane/dispatcher/kevin-mission-worker-v0.1.ps1')
dispatcher_path = Path('control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1')
worker = worker_path.read_text(encoding='utf-8')
dispatcher = dispatcher_path.read_text(encoding='utf-8')

def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit(f'{label}: expected 1 match, found {n}')
    return text.replace(old, new, 1)

# --- Worker: final review fallback may be strict line protocol OR strict JSON. ---
insert_before = "function Invoke-ReviewLineFallback {"
review_helpers = r'''function Validate-ReviewObject {
  param([Parameter(Mandatory=$true)]$Object,[Parameter(Mandatory=$true)][string]$ExpectedMissionId)
  if($null -eq $Object){throw 'Review structured object was null.'}
  $mission=[string](Get-PropertyValue $Object 'mission_id')
  if($mission -cne $ExpectedMissionId){throw "Review structured mission mismatch: $mission"}
  $verdict=([string](Get-PropertyValue $Object 'verdict')).ToUpperInvariant()
  if($verdict -notin @('PASS','REJECT')){throw "Review structured verdict invalid: $verdict"}
  $scoreRaw=Get-PropertyValue $Object 'score';$score=0
  if($null -eq $scoreRaw -or -not [int]::TryParse([string]$scoreRaw,[ref]$score) -or $score -lt 0 -or $score -gt 100){throw "Review structured score invalid: $scoreRaw"}
  $semanticRaw=Get-PropertyValue $Object 'semantic_success'
  if($semanticRaw -isnot [bool]){throw 'Review structured semantic_success must be boolean.'}
  $failProp=$Object.PSObject.Properties['failures'];if($null -eq $failProp){throw 'Review structured failures property missing.'};$failures=@($failProp.Value)
  $secProp=$Object.PSObject.Properties['security_findings'];if($null -eq $secProp){throw 'Review structured security_findings property missing.'};$security=@($secProp.Value)
  $lesson=[string](Get-PropertyValue $Object 'reusable_lesson');if([string]::IsNullOrWhiteSpace($lesson)){throw 'Review structured reusable_lesson was empty.'}
  $next=[string](Get-PropertyValue $Object 'next_experiment');if([string]::IsNullOrWhiteSpace($next)){throw 'Review structured next_experiment was empty.'}
  return [pscustomobject]@{mission_id=$mission;verdict=$verdict;score=$score;failures=$failures;security_findings=$security;reusable_lesson=$lesson;next_experiment=$next;semantic_success=[bool]$semanticRaw}
}
function Parse-ReviewStructuredFallback {
  param([Parameter(Mandatory=$true)][string]$Text,[Parameter(Mandatory=$true)][string]$ExpectedMissionId)
  $lineError=''
  try{return (Parse-ReviewLineProtocol -Text $Text -ExpectedMissionId $ExpectedMissionId)}catch{$lineError=[string]$_.Exception.Message}
  try{
    $obj=Extract-JsonObject $Text
    return (Validate-ReviewObject -Object $obj -ExpectedMissionId $ExpectedMissionId)
  }catch{
    $jsonError=[string]$_.Exception.Message
    throw ("REVIEW_OUTPUT_CONTRACT_FAILURE line=[{0}] json=[{1}]" -f $lineError,$jsonError)
  }
}
'''
worker = once(worker, insert_before, review_helpers + insert_before, 'insert structured review helpers')
worker = once(worker,
    "  return (Parse-ReviewLineProtocol -Text $visible -ExpectedMissionId $MissionId)\n}",
    "  return (Parse-ReviewStructuredFallback -Text $visible -ExpectedMissionId $MissionId)\n}",
    'use dual structured fallback')

old_self = '''  $lp=Parse-ReviewLineProtocol -Text ("MISSION_ID=probe\nVERDICT=PASS\nSCORE=80\nSEMANTIC_SUCCESS=true\nFAILURE=NONE\nSECURITY_FINDING=NONE\nREUSABLE_LESSON=keep evidence\nNEXT_EXPERIMENT=bounded test\n") -ExpectedMissionId 'probe';if($lp.verdict -ne 'PASS' -or [int]$lp.score -ne 80 -or @($lp.failures).Count -ne 0 -or @($lp.security_findings).Count -ne 0){throw 'Review line protocol self-test failed.'}
  Write-Output ("MISSION_WORKER_SELF_TEST_PASS missions={0} json_recovery=1 line_fallback=1" -f $ids.Count);exit 0'''
new_self = '''  $lp=Parse-ReviewLineProtocol -Text ("MISSION_ID=probe\nVERDICT=PASS\nSCORE=80\nSEMANTIC_SUCCESS=true\nFAILURE=NONE\nSECURITY_FINDING=NONE\nREUSABLE_LESSON=keep evidence\nNEXT_EXPERIMENT=bounded test\n") -ExpectedMissionId 'probe';if($lp.verdict -ne 'PASS' -or [int]$lp.score -ne 80 -or @($lp.failures).Count -ne 0 -or @($lp.security_findings).Count -ne 0){throw 'Review line protocol self-test failed.'}
  $jsonProbe='{"mission_id":"probe","verdict":"REJECT","score":55,"failures":["missing evidence"],"security_findings":[],"reusable_lesson":"prove the claim","next_experiment":"bounded rerun","semantic_success":false}'
  $jp=Parse-ReviewStructuredFallback -Text $jsonProbe -ExpectedMissionId 'probe';if($jp.verdict -ne 'REJECT' -or [int]$jp.score -ne 55 -or @($jp.failures).Count -ne 1){throw 'Review JSON fallback self-test failed.'}
  $closed=$false;try{$null=Parse-ReviewStructuredFallback -Text 'unstructured prose only' -ExpectedMissionId 'probe'}catch{if([string]$_.Exception.Message -match '^REVIEW_OUTPUT_CONTRACT_FAILURE '){$closed=$true}};if(-not $closed){throw 'Review structured fallback did not fail closed on prose.'}
  Write-Output ("MISSION_WORKER_SELF_TEST_PASS missions={0} json_recovery=1 structured_fallback=line-or-json fail_closed=1" -f $ids.Count);exit 0'''
worker = once(worker, old_self, new_self, 'worker self-test expansion')

# Validate every review object, including the normal JSON path, before using it.
worker = once(worker,
    "  if([string]$evaluation.mission_id -ne $MissionId){throw 'Review mission mismatch.'}\n  $score=[int]$evaluation.score;$securityCount=@($evaluation.security_findings).Count",
    "  $evaluation=Validate-ReviewObject -Object $evaluation -ExpectedMissionId $MissionId\n  $score=[int]$evaluation.score;$securityCount=@($evaluation.security_findings).Count",
    'normalize review object')

# --- Dispatcher: budget repeated infrastructure failures by failure family, not mission id. ---
family_anchor = "function Normalize-Recent($State,[int]$Max=30){"
family_fn = r'''function Get-InfraFailureFamily {
  param([AllowEmptyString()][string]$WorkerState,[AllowEmptyString()][string]$ErrorText)
  $s=(($WorkerState+' '+$ErrorText) -replace '[\r\n]+',' ').ToLowerInvariant()
  if($s -match 'review line protocol|review model json contract|review_output_contract_failure|review output contract|review.*format-recovery'){return 'review-output-contract'}
  if($s -match 'candidate.*json contract|candidate mission mismatch|candidate.*format-recovery|candidate prompt exceeded'){return 'candidate-output-contract'}
  if($s -match 'exit=124|timed out|timeout'){return 'model-timeout'}
  if($s -match 'resource_guard|14b.*busy|mutex.*busy'){return 'resource-guard'}
  if($s -match 'openclaw runtime|node.exe not found|model run failed exit='){return 'runtime-transport'}
  return 'infra-other'
}
'''
dispatcher = once(dispatcher, family_anchor, family_fn + family_anchor, 'insert failure-family classifier')

old_disp_self = "if($Mode -eq 'SelfTest'){if(-not(Test-Path -LiteralPath $WorkerPath)){throw 'Mission worker missing.'};$r=Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','SelfTest') 60 $Workspace;if($r.ExitCode -ne 0){throw \"Mission worker self-test failed: $($r.Stdout) $($r.Stderr)\"};Write-Output 'MISSION_DISPATCHER_SELF_TEST_PASS';exit 0}"
new_disp_self = "if($Mode -eq 'SelfTest'){if(-not(Test-Path -LiteralPath $WorkerPath)){throw 'Mission worker missing.'};$r=Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','SelfTest') 60 $Workspace;if($r.ExitCode -ne 0){throw \"Mission worker self-test failed: $($r.Stdout) $($r.Stderr)\"};$f1=Get-InfraFailureFamily 'INFRA_FAILURE' 'Review line protocol expected exactly one MISSION_ID= line; saw 0.';$f2=Get-InfraFailureFamily 'INFRA_FAILURE' 'Review model JSON contract failed after one bounded format-recovery attempt.';if($f1 -ne 'review-output-contract' -or $f2 -ne $f1){throw 'Cross-mission review failure-family classifier self-test failed.'};Write-Output 'MISSION_DISPATCHER_SELF_TEST_PASS failure_family=review-output-contract';exit 0}"
dispatcher = once(dispatcher, old_disp_self, new_disp_self, 'dispatcher self-test expansion')

old_failure = '''    $result.state='DISPATCH_INFRA_FAILURE';$same=([string]$State.failure_family -eq $mission);if(-not $same){$State.failure_family=$mission;$State.attempts=0};$State.attempts=[int]$State.attempts+1;$State.last_mission=$mission;$State.last_result='INFRA_FAILURE'
    if([int]$State.attempts -ge [int]$Catalog.policy.max_same_mission_infra_failures){$State.cooldown_until=([DateTimeOffset]::Now.AddMinutes([double]$Catalog.policy.infra_failure_cooldown_minutes)).ToString('o')}
    $result.worker_error=(($worker.Stdout+' '+$worker.Stderr) -replace '[\r\n]+',' ').Trim()'''
new_failure = '''    $result.state='DISPATCH_INFRA_FAILURE';$rawError=(($worker.Stdout+' '+$worker.Stderr) -replace '[\r\n]+',' ').Trim();$family=Get-InfraFailureFamily -WorkerState $workerState -ErrorText $rawError;$same=([string]$State.failure_family -eq $family);if(-not $same){$State.failure_family=$family;$State.attempts=0};$State.attempts=[int]$State.attempts+1;$State.last_mission=$mission;$State.last_result='INFRA_FAILURE';$result.failure_family=$family;$result.failure_attempts=[int]$State.attempts
    if([int]$State.attempts -ge [int]$Catalog.policy.max_same_mission_infra_failures){$State.cooldown_until=([DateTimeOffset]::Now.AddMinutes([double]$Catalog.policy.infra_failure_cooldown_minutes)).ToString('o');$result.cooldown_until=[string]$State.cooldown_until}
    $result.worker_error=$rawError'''
dispatcher = once(dispatcher, old_failure, new_failure, 'cross-mission failure budget')

worker_path.write_text(worker, encoding='utf-8')
dispatcher_path.write_text(dispatcher, encoding='utf-8')

# Static invariants.
if 'Parse-ReviewStructuredFallback' not in worker or 'REVIEW_OUTPUT_CONTRACT_FAILURE' not in worker:
    raise SystemExit('worker structured fallback repair missing')
if "return 'review-output-contract'" not in dispatcher or '$State.failure_family -eq $family' not in dispatcher:
    raise SystemExit('dispatcher family budget repair missing')
print('PATCH_V13_OK')
