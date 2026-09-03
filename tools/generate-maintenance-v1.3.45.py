from pathlib import Path
import hashlib

ROOT=Path(__file__).resolve().parents[1]
src=ROOT/'control-plane/maintenance/kevin-maintenance-runner-v1.3.44.ps1'
dst=ROOT/'control-plane/maintenance/kevin-maintenance-runner-v1.3.45.ps1'
expected_base='3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E'
expected_after='9615BE7D546F0482A0D295CABD01D87411C4FC93159349CEFC40594FDD6E8CD2'

data=src.read_bytes()
actual=hashlib.sha256(data).hexdigest().upper()
if actual!=expected_base:
    raise SystemExit(f'base v1.3.44 identity mismatch actual={actual}')
text=data.decode('utf-8')

def once(old,new,label):
    global text
    c=text.count(old)
    if c!=1:
        raise SystemExit(f'{label} expected one occurrence, found {c}')
    text=text.replace(old,new,1)

once("version='1.3.44'","version='1.3.45'","state version")

needle="$RuntimePolicyNames = @('AGENTS.md','HEARTBEAT.md','MEMORY.md','SOUL.md','TOOLS.md')\n"
insert=needle+'''$FixedMainConfigSha = '23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5'
$FixedMainPreviousConfigSha = '215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84'
$FixedMainLegacyBaselineSha = '1396897473D874154FF24DB933D4B4FB643298652FC3C0C05097971DC2336B30'
$FixedMainBenchmarkSha = '4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964'
$FixedMainSupervisorSha = 'F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138'
$FixedMainForgeSha = '433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
$FixedMainReaderSha = 'C107FEEDA4CA7B330FF44B7E9083DDAA854D9057085F165797B3EAF6FC458C5D'
$FixedUiBridgeSha = '5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42'
$FixedUiBridgeTaskName = 'Kevin UI Bridge v0.3'
'''
once(needle,insert,"fixed identities")

once("'replace_pinned_component','restart_ui_bridge','audit_runtime_convergence'",
     "'replace_pinned_component','restart_ui_bridge','repair_ui_bridge_task_v1','reconcile_fixed_main_r04_v1','audit_runtime_convergence'",
     "operation allowlist")

start=text.index("function Restart-UiBridge([object]$m) {")
end=text.index("\nfunction Audit-RuntimeConvergence",start)
block=r'''function Get-UiBridgeTaskContractState([string]$TaskName=$FixedUiBridgeTaskName) {
    $task=Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if(-not$task){return [pscustomobject]@{ok=$false;reason='missing';task=$null}}
    $actions=@($task.Actions)
    if($actions.Count-ne1){return [pscustomobject]@{ok=$false;reason='actions';task=$task}}
    $ui=Join-Path $Workspace 'kevin-ui-bridge.ps1'
    $ps=(Get-Command powershell.exe -ErrorAction Stop).Source
    $args='-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$ui+'" -RunLoop'
    try{$execOk=([IO.Path]::GetFullPath([string]$actions[0].Execute)-ieq[IO.Path]::GetFullPath($ps))}catch{$execOk=$false}
    if(-not$execOk){return [pscustomobject]@{ok=$false;reason='execute';task=$task}}
    if([string]$actions[0].Arguments-cne$args){return [pscustomobject]@{ok=$false;reason='arguments';task=$task}}
    if([string]$task.Principal.LogonType-inotmatch'Interactive'){return [pscustomobject]@{ok=$false;reason='principal_logon';task=$task}}
    if([string]$task.Principal.RunLevel-inotmatch'Limited'){return [pscustomobject]@{ok=$false;reason='principal_level';task=$task}}
    return [pscustomobject]@{ok=$true;reason='exact';task=$task}
}
function Wait-SustainedUiBridge([string]$TaskName,[int]$TimeoutSeconds=30) {
    $heartbeat=Join-Path $Reports 'action-era\ui-bridge\heartbeat.json'
    $started=[DateTimeOffset]::Now
    Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    $first=$null
    $deadline=(Get-Date).AddSeconds($TimeoutSeconds)
    while((Get-Date)-lt$deadline){
        Start-Sleep -Milliseconds 500
        if(Test-Path -LiteralPath $heartbeat -PathType Leaf){
            try{
                $h=Get-Content -LiteralPath $heartbeat -Raw|ConvertFrom-Json
                $at=[DateTimeOffset]::Parse([string]$h.at)
                if([string]$h.kind-eq'kevin-ui-bridge-heartbeat' -and
                   @('READY','WORKING')-contains[string]$h.state -and
                   [int]$h.session_id-gt0 -and
                   [bool]$h.explorer_same_session -and
                   $at-ge$started.AddSeconds(-2) -and
                   ([DateTimeOffset]::Now-$at).TotalSeconds-lt10){
                    $first=$h;break
                }
            }catch{}
        }
    }
    if(-not$first){throw 'UI Bridge did not produce a fresh interactive heartbeat'}
    $firstAt=[DateTimeOffset]::Parse([string]$first.at);$session=[int]$first.session_id
    Start-Sleep -Seconds 7
    try{$second=Get-Content -LiteralPath $heartbeat -Raw|ConvertFrom-Json;$secondAt=[DateTimeOffset]::Parse([string]$second.at)}catch{throw 'UI Bridge sustained heartbeat unreadable'}
    if([string]$second.kind-ne'kevin-ui-bridge-heartbeat' -or
       @('READY','WORKING')-notcontains[string]$second.state -or
       [int]$second.session_id-ne$session -or
       -not[bool]$second.explorer_same_session -or
       $secondAt-le$firstAt.AddSeconds(2) -or
       ([DateTimeOffset]::Now-$secondAt).TotalSeconds-gt10){
        throw 'UI Bridge heartbeat did not continue in the logged-in Explorer session'
    }
    return [ordered]@{first_at=$firstAt.ToString('o');second_at=$secondAt.ToString('o');session_id=$session;state=[string]$second.state;explorer_same_session=$true}
}
function Register-KnownGoodUiBridgeTask {
    $ui=Join-Path $Workspace 'kevin-ui-bridge.ps1'
    $user=[Security.Principal.WindowsIdentity]::GetCurrent().Name
    $ps=(Get-Command powershell.exe -ErrorAction Stop).Source
    $args='-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$ui+'" -RunLoop'
    $action=New-ScheduledTaskAction -Execute $ps -Argument $args
    $trigger=New-ScheduledTaskTrigger -AtLogOn -User $user
    $principal=New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    $settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Days 3650)
    Register-ScheduledTask -TaskName $FixedUiBridgeTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Kevin narrow InteractiveToken UI Bridge. GREEN Notepad-only. No generic mouse/keyboard/browser.' -Force|Out-Null
}
function Restart-UiBridge([object]$m) {
    if($env:OS-ne'Windows_NT'){throw 'UI restart requires Windows'}
    $spec=Get-AliasSpec 'ui_bridge_runner';$actual=Get-Sha $spec.Target
    if($actual-ne([string]$m.expected_current_sha256).ToUpperInvariant()){throw('UI Bridge hash mismatch actual='+$actual)}
    $state=Get-UiBridgeTaskContractState ([string]$m.task_name)
    if(-not$state.ok){throw('UI Bridge task contract mismatch: '+[string]$state.reason)}
    try{Stop-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue}catch{}
    $hb=Wait-SustainedUiBridge ([string]$m.task_name) ([int]$m.heartbeat_timeout_seconds)
    Assert-Benchmark30
    return [ordered]@{changed=$true;hash=$actual;task_name=[string]$m.task_name;heartbeat_first=$hb.first_at;heartbeat_second=$hb.second_at;state=$hb.state;session_id=$hb.session_id;sustained=$true}
}
function Repair-UiBridgeTaskV1 {
    if($env:OS-ne'Windows_NT'){throw 'UI task repair requires Windows'}
    $ui=Join-Path $Workspace 'kevin-ui-bridge.ps1'
    if((Get-Sha $ui)-cne$FixedUiBridgeSha){throw('UI Bridge identity changed: '+(Get-Sha $ui))}
    $state=Get-UiBridgeTaskContractState $FixedUiBridgeTaskName
    if($state.ok){
        try{
            try{Stop-ScheduledTask -TaskName $FixedUiBridgeTaskName -ErrorAction SilentlyContinue}catch{}
            $hb=Wait-SustainedUiBridge $FixedUiBridgeTaskName 30
            Assert-Benchmark30
            return [ordered]@{changed=$false;task_contract='EXACT';heartbeat=$hb;idempotent=$true}
        }catch{
            # Exact definition but failed durable startup: recover from the known-good task contract.
        }
    }
    $backup=''
    $hadTask=$null-ne(Get-ScheduledTask -TaskName $FixedUiBridgeTaskName -ErrorAction SilentlyContinue)
    if($hadTask){
        $dir=Join-Path $BackupRoot ('ui-task-repair-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
        New-Item -ItemType Directory -Path $dir -Force|Out-Null
        $backup=Join-Path $dir 'ui-task.before.xml'
        Export-ScheduledTask -TaskName $FixedUiBridgeTaskName|Set-Content -LiteralPath $backup -Encoding Unicode
    }
    try{
        try{Stop-ScheduledTask -TaskName $FixedUiBridgeTaskName -ErrorAction SilentlyContinue}catch{}
        if(Get-ScheduledTask -TaskName $FixedUiBridgeTaskName -ErrorAction SilentlyContinue){Unregister-ScheduledTask -TaskName $FixedUiBridgeTaskName -Confirm:$false}
        Register-KnownGoodUiBridgeTask
        $after=Get-UiBridgeTaskContractState $FixedUiBridgeTaskName
        if(-not$after.ok){throw('repaired UI Bridge task contract invalid: '+[string]$after.reason)}
        $hb=Wait-SustainedUiBridge $FixedUiBridgeTaskName 30
        Assert-Benchmark30
        return [ordered]@{changed=$true;task_contract='REPAIRED';heartbeat=$hb;backup=(Safe-Text $backup 500);rollback_available=[bool]$backup}
    }catch{
        $primary=$_.Exception.Message
        if($backup-and(Test-Path -LiteralPath $backup -PathType Leaf)){
            try{
                if(Get-ScheduledTask -TaskName $FixedUiBridgeTaskName -ErrorAction SilentlyContinue){Unregister-ScheduledTask -TaskName $FixedUiBridgeTaskName -Confirm:$false -ErrorAction SilentlyContinue}
                Register-ScheduledTask -TaskName $FixedUiBridgeTaskName -Xml (Get-Content -LiteralPath $backup -Raw) -Force|Out-Null
            }catch{throw('UI task repair failed and rollback failed: '+$primary+' / '+$_.Exception.Message)}
        }elseif(-not$hadTask){
            try{if(Get-ScheduledTask -TaskName $FixedUiBridgeTaskName -ErrorAction SilentlyContinue){Unregister-ScheduledTask -TaskName $FixedUiBridgeTaskName -Confirm:$false -ErrorAction SilentlyContinue}}catch{}
        }
        throw('UI task repair failed; prior definition restored when available: '+$primary)
    }
}
function Get-R04NonTargetJson([object]$Baseline) {
    $copy=$Baseline|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $copy.hashes.production_config='TARGET_IGNORED'
    return ($copy|ConvertTo-Json -Depth 30 -Compress)
}
function Assert-FixedMainR04Baseline([object]$b) {
    if($null-eq$b -or [int]$b.schema-ne1 -or [string]$b.kind-cne'kevin-benchmark-v1-baseline'){throw 'R04 baseline schema/kind mismatch'}
    if($null-eq$b.hashes){throw 'R04 baseline hashes missing'}
    foreach($n in @('supervisor','forge','production_config','reader_config','benchmark_spec','goal_os','promotion_policy')){
        $p=$b.hashes.PSObject.Properties[$n]
        if($null-eq$p -or [string]$p.Value-cnotmatch'^[A-Fa-f0-9]{64}$'){throw('R04 baseline hash missing/invalid: '+$n)}
    }
    if(([string]$b.hashes.supervisor).ToUpperInvariant()-cne$FixedMainSupervisorSha){throw 'R04 baseline supervisor anchor changed'}
    if(([string]$b.hashes.forge).ToUpperInvariant()-cne$FixedMainForgeSha){throw 'R04 baseline forge anchor changed'}
    if(([string]$b.hashes.reader_config).ToUpperInvariant()-cne$FixedMainReaderSha){throw 'R04 baseline reader anchor changed'}
}
function Assert-R04OnlyEvidence([object]$latest) {
    if($null-eq$latest -or $null-eq$latest.regression){throw 'R04 Benchmark evidence missing'}
    if([string]$latest.status-cne'FAIL_CRITICAL_REGRESSION' -or [int]$latest.regression.passed-ne29 -or [int]$latest.regression.total-ne30 -or [int]$latest.regression.critical_failures-ne1){throw 'R04 Benchmark is not exact 29/30 critical1'}
    $rows=@($latest.regression.rows);if($rows.Count-ne30){throw 'R04 Benchmark rows incomplete'}
    $failed=@($rows|Where-Object{-not[bool]$_.pass})
    if($failed.Count-ne1 -or [string]$failed[0].id-cne'R04' -or -not[bool]$failed[0].critical){throw 'R04 Benchmark failure is not exactly critical R04'}
}
function Reconcile-FixedMainR04V1 {
    $cfg=Join-Path $env:USERPROFILE '.openclaw\openclaw.json'
    $baseline=Join-Path $Reports 'benchmark-v1\baseline.json'
    $bench=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    $latest=Join-Path $Reports 'benchmark-v1\latest.json'
    if((Get-Sha $cfg)-cne$FixedMainConfigSha){throw('R04 protected config identity changed: '+(Get-Sha $cfg))}
    if((Get-Sha $bench)-cne$FixedMainBenchmarkSha){throw('R04 Benchmark identity changed: '+(Get-Sha $bench))}
    if(-not(Test-Path -LiteralPath $baseline -PathType Leaf)){throw 'R04 baseline missing'}
    $b=Get-Content -LiteralPath $baseline -Raw|ConvertFrom-Json;Assert-FixedMainR04Baseline $b
    $anchor=([string]$b.hashes.production_config).ToUpperInvariant()
    if($anchor-eq$FixedMainConfigSha){
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;target_leaf='hashes.production_config';anchor=$anchor;benchmark='30/30 critical0'}
    }
    if($anchor-ne$FixedMainPreviousConfigSha){throw('R04 baseline production_config anchor is not a recognized recovery state: '+$anchor)}
    if((Get-Sha $baseline)-cne$FixedMainLegacyBaselineSha){throw('R04 legacy baseline bytes changed: '+(Get-Sha $baseline))}
    if(-not(Test-Path -LiteralPath $latest -PathType Leaf)){throw 'R04 Benchmark latest missing'}
    Assert-R04OnlyEvidence (Get-Content -LiteralPath $latest -Raw|ConvertFrom-Json)
    $beforeNonTarget=Get-R04NonTargetJson $b
    $dir=Join-Path $BackupRoot ('fixed-main-r04-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $dir -Force|Out-Null
    $backup=Join-Path $dir 'baseline.json.before';Copy-Item -LiteralPath $baseline -Destination $backup -Force
    if((Get-Sha $backup)-cne$FixedMainLegacyBaselineSha){throw 'R04 backup verification failed'}
    $after=$b|ConvertTo-Json -Depth 30|ConvertFrom-Json;$after.hashes.production_config=$FixedMainConfigSha
    if((Get-R04NonTargetJson $after)-cne$beforeNonTarget){throw 'R04 staged non-target semantics changed'}
    $stage=Join-Path $dir 'baseline.json.stage';[IO.File]::WriteAllText($stage,($after|ConvertTo-Json -Depth 30),$Utf8)
    $stageObj=Get-Content -LiteralPath $stage -Raw|ConvertFrom-Json
    if(([string]$stageObj.hashes.production_config).ToUpperInvariant()-cne$FixedMainConfigSha -or (Get-R04NonTargetJson $stageObj)-cne$beforeNonTarget){throw 'R04 serialized stage verification failed'}
    try{
        $tmp=$baseline+'.r04-'+[guid]::NewGuid().ToString('N');Copy-Item -LiteralPath $stage -Destination $tmp -Force;Move-Item -LiteralPath $tmp -Destination $baseline -Force
        $installed=Get-Content -LiteralPath $baseline -Raw|ConvertFrom-Json
        if(([string]$installed.hashes.production_config).ToUpperInvariant()-cne$FixedMainConfigSha -or (Get-R04NonTargetJson $installed)-cne$beforeNonTarget){throw 'R04 installed baseline verification failed'}
        if((Get-Sha $cfg)-cne$FixedMainConfigSha -or (Get-Sha $bench)-cne$FixedMainBenchmarkSha){throw 'R04 protected identity changed during crossing'}
        Assert-Benchmark30
        return [ordered]@{changed=$true;idempotent=$false;target_leaf='hashes.production_config';previous_anchor=$FixedMainPreviousConfigSha;current_anchor=$FixedMainConfigSha;benchmark='30/30 critical0';rollback=(Safe-Text $backup 500);non_target_semantics_preserved=$true}
    }catch{
        $primary=$_.Exception.Message;Copy-Item -LiteralPath $backup -Destination $baseline -Force
        if((Get-Sha $baseline)-cne$FixedMainLegacyBaselineSha){throw('R04 recovery failed and exact rollback failed: '+$primary)}
        throw('R04 recovery failed; exact baseline rollback completed: '+$primary)
    }
}
'''
text=text[:start]+block+text[end:]

once("        'restart_ui_bridge' { Assert-Restart $m }\n",
     "        'restart_ui_bridge' { Assert-Restart $m }\n        'repair_ui_bridge_task_v1' { Assert-NoCallerArgs $m 'repair_ui_bridge_task_v1' }\n        'reconcile_fixed_main_r04_v1' { Assert-NoCallerArgs $m 'reconcile_fixed_main_r04_v1' }\n",
     "validation dispatch")
once("            'restart_ui_bridge' { Restart-UiBridge $m; break }\n",
     "            'restart_ui_bridge' { Restart-UiBridge $m; break }\n            'repair_ui_bridge_task_v1' { Repair-UiBridgeTaskV1; break }\n            'reconcile_fixed_main_r04_v1' { Reconcile-FixedMainR04V1; break }\n",
     "execution dispatch")
once("            'restart_ui_bridge' {'ui_bridge_restart_failure'}\n",
     "            'restart_ui_bridge' {'ui_bridge_restart_failure'}\n            'repair_ui_bridge_task_v1' {'ui_bridge_task_repair_failure'}\n            'reconcile_fixed_main_r04_v1' {'fixed_main_r04_reconcile_failure'}\n",
     "failure dispatch")

needle="    Write-Host 'KEVIN MAINTENANCE v1.3.44 SELFTEST PASS reader_status_canary_predicate=live_openclaw status_ok_or_success=true toolSummary_call_boundary=true entries_inventory_not_required=true failures_zero=true privacy_categories=6 authority_expansion=false arbitrary_shell=false'\n"
extra=needle+r'''    $r04=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$r04.operation='reconcile_fixed_main_r04_v1';Assert-Common $r04;Assert-NoCallerArgs $r04 'reconcile_fixed_main_r04_v1'
    $r04Bad=$r04|ConvertTo-Json -Depth 10|ConvertFrom-Json;$r04Bad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-NoCallerArgs $r04Bad 'reconcile_fixed_main_r04_v1'}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected R04 path accepted'}
    $fixture=[pscustomobject]@{schema=1;kind='kevin-benchmark-v1-baseline';hashes=[pscustomobject]@{supervisor=$FixedMainSupervisorSha;forge=$FixedMainForgeSha;production_config=$FixedMainPreviousConfigSha;reader_config=$FixedMainReaderSha;benchmark_spec=('A'*64);goal_os=('B'*64);promotion_policy=('C'*64)}};Assert-FixedMainR04Baseline $fixture
    $non=Get-R04NonTargetJson $fixture;$fixture2=$fixture|ConvertTo-Json -Depth 20|ConvertFrom-Json;$fixture2.hashes.production_config=$FixedMainConfigSha;if((Get-R04NonTargetJson $fixture2)-cne$non){throw 'R04 target-only semantic fixture failed'};$fixture2.hashes.goal_os=('D'*64);if((Get-R04NonTargetJson $fixture2)-ceq$non){throw 'R04 non-target mutation fixture not detected'}
    $ev=[pscustomobject]@{status='FAIL_CRITICAL_REGRESSION';regression=[pscustomobject]@{passed=29;total=30;critical_failures=1;rows=@(1..30|ForEach-Object{[pscustomobject]@{id=('R{0:d2}'-f$_);pass=($_-ne4);critical=($_-eq4)}})}};Assert-R04OnlyEvidence $ev
    $uit=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$uit.operation='repair_ui_bridge_task_v1';Assert-Common $uit;Assert-NoCallerArgs $uit 'repair_ui_bridge_task_v1'
    $uitBad=$uit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$uitBad|Add-Member -NotePropertyName task_name -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-NoCallerArgs $uitBad 'repair_ui_bridge_task_v1'}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected UI task accepted'}
    foreach($h in @($FixedMainConfigSha,$FixedMainPreviousConfigSha,$FixedMainLegacyBaselineSha,$FixedMainBenchmarkSha,$FixedMainSupervisorSha,$FixedMainForgeSha,$FixedMainReaderSha,$FixedUiBridgeSha)){if($h-cnotmatch'^[A-F0-9]{64}$'){throw 'v1.3.45 fixed identity malformed'}}
    Write-Host 'KEVIN MAINTENANCE v1.3.45 SELFTEST PASS r04_recovery=fixed_one_leaf ui_restart=sustained_heartbeat ui_task_repair=fixed_interactive_runloop rollback=true arbitrary_shell=false authority_expansion=false'
'''
once(needle,extra,"selftest extension")

out=text.encode('utf-8')
actual_after=hashlib.sha256(out).hexdigest().upper()
if actual_after!=expected_after:
    raise SystemExit(f'generated v1.3.45 hash mismatch actual={actual_after}')
dst.write_bytes(out)
print(f'generated {dst} sha256={actual_after}')
