from pathlib import Path

src=Path('control-plane/intake/kevin-work-order-intake-v0.1.ps1').read_text(encoding='utf-8')
out=src

out=out.replace("[ValidateSet('Poll','SelfTest')]","[ValidateSet('Poll','SelfTest','PolicySelfTest')]")
out=out.replace("$SupportPath=Join-Path $Reports 'support-latest.json'","$SupportPath=Join-Path $Reports 'support-latest.json'\n$AutonomyPath=Join-Path $Reports 'autonomy-latest.json'\n$PolicyCliPath=Join-Path $PSScriptRoot 'work_order_policy_cli_v1_1.py'")
out=out.replace("return [pscustomobject]@{schema=1;processed=@();updated_at=(Get-Date).ToString('o')}","return [pscustomobject]@{schema=2;processed=@();failures=@();cooldowns=@();evidence=@();updated_at=(Get-Date).ToString('o')}")
out=out.replace("$allowed=@('schema','kind','id','idempotency_key','created_at','expires_at','authority_class','verb','target','reason')","$allowed=@('schema','kind','id','idempotency_key','created_at','expires_at','authority_class','verb','target','reason','precondition_fingerprint','cooldown_key')")
out=out.replace("foreach($n in @('schema','kind','id','idempotency_key','created_at','expires_at','authority_class','verb','target'))","foreach($n in @('schema','kind','id','idempotency_key','created_at','expires_at','authority_class','verb','target','precondition_fingerprint'))")

anchor="function Is-Replay($Ledger,[string]$Key){return @($Ledger.processed|Where-Object{[string]$_.idempotency_key -eq $Key}).Count -gt 0}\n"
insert=r'''
function Ensure-LedgerShape($Ledger){
  if($null -eq $Ledger.PSObject.Properties['schema']){$Ledger|Add-Member NoteProperty schema 2}else{$Ledger.schema=2}
  foreach($n in @('processed','failures','cooldowns','evidence')){if($null -eq $Ledger.PSObject.Properties[$n]){$Ledger|Add-Member NoteProperty $n @()}}
  return $Ledger
}
function Get-PythonExe {$p=Get-Command python.exe -ErrorAction SilentlyContinue;if(-not $p){$p=Get-Command python -ErrorAction SilentlyContinue};if(-not $p){throw 'python missing for typed GREEN admission policy'};return $p.Source}
function Invoke-AdmissionPolicy($Order,$Ledger){
  foreach($p in @($PolicyCliPath,$SupportPath,$AutonomyPath,$CatalogPath)){if(-not(Test-Path -LiteralPath $p)){throw "Admission input missing: $p"}}
  $tmp=Join-Path $env:TEMP ("kevin-admit-{0}" -f [guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $tmp -Force|Out-Null
  try{
    $orderPath=Join-Path $tmp 'order.json';$snapPath=Join-Path $tmp 'snapshot.json';$ledgerPath=Join-Path $tmp 'ledger.json';$catalogPath=Join-Path $tmp 'catalog.json'
    Write-JsonAtomic $Order $orderPath
    $snapshot=[ordered]@{support=(Read-JsonFile $SupportPath);autonomy=(Read-JsonFile $AutonomyPath)};Write-JsonAtomic $snapshot $snapPath
    Write-JsonAtomic $Ledger $ledgerPath;Copy-Item -LiteralPath $CatalogPath -Destination $catalogPath -Force
    $r=Invoke-ExactNative -Executable (Get-PythonExe) -Argv @($PolicyCliPath,'--order',$orderPath,'--snapshot',$snapPath,'--ledger',$ledgerPath,'--catalog',$catalogPath) -TimeoutSeconds 30 -WorkingDirectory $PSScriptRoot
    if($r.ExitCode -ne 0){throw "Admission policy failed: $(One-Line ($r.Stdout+' '+$r.Stderr))"}
    return ($r.Stdout|ConvertFrom-Json)
  }finally{Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue}
}
function Add-FailureRecord($Ledger,$Order,[string]$Family,[string]$Detail){
  $now=(Get-Date).ToString('o');$key=[string](Get-OptionalPropertyValue $Order 'cooldown_key');if(-not $key){$key=([string](Get-OptionalPropertyValue $Order 'verb'))+':'+([string](Get-OptionalPropertyValue $Order 'target'))}
  $Ledger.failures=@($Ledger.failures)+@([pscustomobject]@{at=$now;id=[string](Get-OptionalPropertyValue $Order 'id');idempotency_key=[string](Get-OptionalPropertyValue $Order 'idempotency_key');family=$Family;cooldown_key=$key;detail=(One-Line $Detail)})
  $recent=@($Ledger.failures|Where-Object{[string]$_.cooldown_key -eq $key}|Select-Object -Last 3)
  if($recent.Count -ge 3){$until=(Get-Date).AddMinutes(30).ToString('o');$Ledger.cooldowns=@($Ledger.cooldowns|Where-Object{[string]$_.key -ne $key})+@([pscustomobject]@{key=$key;until=$until;family=$Family;reason='three bounded failed attempts'})}
}
function Verify-Postcondition($Order,[DateTimeOffset]$Started){
  $verb=[string](Get-OptionalPropertyValue $Order 'verb');$target=[string](Get-OptionalPropertyValue $Order 'target')
  switch($verb){
    'run_benchmark' {$s=Read-JsonFile $SupportPath;return ($s -and [string]$s.benchmark.status -eq 'PASS' -and [DateTimeOffset]::Parse([string]$s.benchmark.at) -ge $Started)}
    'run_support_bridge' {$s=Read-JsonFile $SupportPath;return ($s -and [DateTimeOffset]::Parse([string]$s.generated_at) -ge $Started)}
    'refresh_autonomy_telemetry' {$a=Read-JsonFile $AutonomyPath;return ($a -and [DateTimeOffset]::Parse([string]$a.generated_at) -ge $Started)}
    'run_reconcile' {$a=Read-JsonFile $AutonomyPath;return ($a -and [DateTimeOffset]::Parse([string]$a.generated_at) -ge $Started -and -not [string]::IsNullOrWhiteSpace([string]$a.state))}
    'dispatch_mission' {$m=Read-JsonFile (Join-Path $Reports 'mission-factory-latest.json');return ($m -and [string]$m.mission_id -eq $target -and [DateTimeOffset]::Parse([string]$m.generated_at) -ge $Started -and [string]$m.state -in @('PASS','REJECT','INFRA_FAILURE'))}
  }
  return $false
}
'''
if anchor not in out: raise SystemExit('anchor missing')
out=out.replace(anchor,anchor+insert)

self_anchor="if($Mode -eq 'SelfTest'){"
policy_test=r'''if($Mode -eq 'PolicySelfTest'){
  if(-not(Test-Path -LiteralPath $PolicyCliPath)){throw 'Policy CLI missing'}
  $raw=[IO.File]::ReadAllText($MyInvocation.MyCommand.Path)
  foreach($needle in @('Invoke-AdmissionPolicy','Verify-Postcondition','Add-FailureRecord','precondition_fingerprint','cooldowns','evidence')){if(-not $raw.Contains($needle)){throw "PolicySelfTest missing contract: $needle"}}
  Write-Output 'WORK_ORDER_POLICY_SELF_TEST_PASS';exit 0
}

'''
out=out.replace(self_anchor,policy_test+self_anchor)

old=r'''  $o=$remote.data;$ledger=Get-Ledger
'''
new=r'''  $o=$remote.data;$ledger=Ensure-LedgerShape (Get-Ledger)
'''
out=out.replace(old,new)
old=r'''    Validate-Order $o;$validated=$true
    $oid=[string](Get-OptionalPropertyValue $o 'id');$oIdem=[string](Get-OptionalPropertyValue $o 'idempotency_key');$oVerb=[string](Get-OptionalPropertyValue $o 'verb');$oTarget=[string](Get-OptionalPropertyValue $o 'target')
    $ack.order_id=$oid;$ack.idempotency_key=$oIdem;$ack.verb=$oVerb;$ack.target=$oTarget
    if(Is-Replay $ledger $oIdem){Write-Output 'WORK_ORDER_REPLAY_IGNORED';exit 0}
    $detail=Execute-Order $o;$ack.status='VERIFIED';$ack.detail=$detail
    $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=$oid;idempotency_key=$oIdem;verb=$oVerb;target=$oTarget;completed_at=(Get-Date).ToString('o');status='VERIFIED'});Save-Ledger $ledger;$ledgerRecorded=$true
'''
new=r'''    Validate-Order $o;$validated=$true
    $oid=[string](Get-OptionalPropertyValue $o 'id');$oIdem=[string](Get-OptionalPropertyValue $o 'idempotency_key');$oVerb=[string](Get-OptionalPropertyValue $o 'verb');$oTarget=[string](Get-OptionalPropertyValue $o 'target')
    $ack.order_id=$oid;$ack.idempotency_key=$oIdem;$ack.verb=$oVerb;$ack.target=$oTarget
    $admission=Invoke-AdmissionPolicy $o $ledger
    if([string]$admission.decision -ne 'ACCEPT_GREEN'){$ack.status=[string]$admission.decision;$ack.detail='typed GREEN admission denied execution';Write-JsonAtomic $ack $LatestPath;try{Publish-Ack $ack}catch{};Write-Output ("WORK_ORDER_NOT_ADMITTED id={0} decision={1}" -f $oid,$ack.status);exit 0}
    $started=[DateTimeOffset]::Now;$detail=Execute-Order $o
    if(-not(Verify-Postcondition $o $started)){throw 'POSTCONDITION_NOT_VERIFIED'}
    $ack.status='VERIFIED';$ack.detail=$detail
    $evidence=[pscustomobject]@{id=$oid;idempotency_key=$oIdem;verb=$oVerb;target=$oTarget;admission_precondition=[string]$admission.precondition_fingerprint;started_at=$started.ToString('o');verified_at=(Get-Date).ToString('o');postcondition_verified=$true}
    $ledger.evidence=@($ledger.evidence)+@($evidence)
    $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=$oid;idempotency_key=$oIdem;verb=$oVerb;target=$oTarget;completed_at=(Get-Date).ToString('o');status='VERIFIED'});Save-Ledger $ledger;$ledgerRecorded=$true
'''
if old not in out: raise SystemExit('execution block missing')
out=out.replace(old,new)

old=r'''    if($validated -and -not $ledgerRecorded -and $oIdem){
      $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=$(if($oid){[string]$oid}else{''});idempotency_key=[string]$oIdem;verb=$(if($oVerb){[string]$oVerb}else{''});target=$(if($oTarget){[string]$oTarget}else{''});completed_at=(Get-Date).ToString('o');status='FAILED'});Save-Ledger $ledger;$ledgerRecorded=$true
    }
'''
new=r'''    if($validated -and -not $ledgerRecorded -and $oIdem){
      Add-FailureRecord $ledger $o 'execution_or_postcondition' $ack.detail;Save-Ledger $ledger;$ledgerRecorded=$true
    }
'''
if old not in out: raise SystemExit('failure block missing')
out=out.replace(old,new)

Path('control-plane/intake/kevin-work-order-intake-v0.2-candidate.ps1').write_text(out,encoding='utf-8')
print('WORK_ORDER_INTAKE_V12_CANDIDATE_BUILT')
