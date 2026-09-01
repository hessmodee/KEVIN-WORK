from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.19.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.20.ps1')
EXPECTED_SRC_SHA256 = '7422A70B75FC8BCA069CA00DBDD1967318159F87B3E84C202A8932474611BB21'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA256:
    raise SystemExit(f'v1.3.19 source identity mismatch: {actual}')
text = raw.decode('utf-8')


def once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)

once("version='1.3.19'", "version='1.3.20'", 'state version')

old_allow = "'migrate_supervisor_forge_demand_gated_v17','repair_supervisor_v171_forge_pin') -contains [string]$m.operation)"
new_allow = "'migrate_supervisor_forge_demand_gated_v17','repair_supervisor_v171_forge_pin','ensure_autonomy_continuation_automation') -contains [string]$m.operation)"
once(old_allow, new_allow, 'operation allowlist')

anchor = "function Process-Typed([object]$m) {\n"
block = r'''function Assert-AutonomyContinuationAutomation([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('autonomy continuation manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'ensure_autonomy_continuation_automation'){throw 'autonomy continuation operation mismatch'}
}

function Get-AutonomyContinuationJobs {
    $r=Invoke-OpenClawFixedConfig @('cron','list','--all','--json')
    if($r.exit_code -ne 0){throw ('OpenClaw automation list failed: '+(Safe-Text $r.output 240))}
    try{$obj=$r.output|ConvertFrom-Json}catch{throw 'OpenClaw automation list returned invalid JSON'}
    if($obj -is [array]){return @($obj)}
    if($obj.PSObject.Properties['jobs']){return @($obj.jobs)}
    if($obj.PSObject.Properties['items']){return @($obj.items)}
    return @($obj)
}

function Ensure-AutonomyContinuationAutomation {
    $name='Kevin Autonomy Continuation v1'
    $event='KEVIN_CONTINUATION_V1: Execute standing orders now. Refresh trusted evidence. If an active GREEN goal can advance, select the highest eligible UNSATISFIED item via governed selector/Task Flow; never re-select already-satisfied work; execute only existing proven typed GREEN paths; semantically verify; record outcome/evidence/failure family; then continue. If production WIP is occupied, advance an independent eligible staging or research item within WIP. Do not manufacture Forge/design demand. If no eligible action exists, record the exact blocker and return NO_REPLY.'
    $jobs=@(Get-AutonomyContinuationJobs|Where-Object{[string]$_.name -eq $name})
    if($jobs.Count -gt 1){throw 'duplicate Kevin Autonomy Continuation jobs detected'}
    $changed=$false
    if($jobs.Count -eq 0){
        $create=Invoke-OpenClawFixedConfig @('cron','add','--name',$name,'--every','5m','--session','main','--system-event',$event,'--wake','now')
        if($create.exit_code -ne 0){throw ('autonomy continuation automation create failed: '+(Safe-Text $create.output 260))}
        $changed=$true
        $jobs=@(Get-AutonomyContinuationJobs|Where-Object{[string]$_.name -eq $name})
        if($jobs.Count -ne 1){throw 'autonomy continuation automation create did not converge to exactly one job'}
    }
    $id=[string]$jobs[0].id
    if(-not$id){throw 'autonomy continuation automation missing id'}
    $get=Invoke-OpenClawFixedConfig @('cron','get',$id,'--json')
    if($get.exit_code -ne 0){throw 'autonomy continuation automation get failed'}
    try{$job=$get.output|ConvertFrom-Json}catch{throw 'autonomy continuation automation get returned invalid JSON'}
    if([string]$job.name -ne $name){throw 'autonomy continuation job name readback mismatch'}
    if($job.PSObject.Properties['enabled'] -and [bool]$job.enabled -ne $true){throw 'autonomy continuation job is disabled'}
    $raw=[string]$get.output
    if($raw -notmatch '"everyMs"\s*:\s*300000'){throw 'autonomy continuation cadence readback mismatch'}
    if($raw -notmatch '"kind"\s*:\s*"systemEvent"'){throw 'autonomy continuation payload kind mismatch'}
    if(-not$raw.Contains('KEVIN_CONTINUATION_V1')){throw 'autonomy continuation event marker missing from readback'}
    $run=Invoke-OpenClawFixedConfig @('cron','run',$id)
    if($run.exit_code -ne 0){throw ('autonomy continuation immediate wake enqueue failed: '+(Safe-Text $run.output 220))}
    Assert-Benchmark30
    return [ordered]@{changed=$changed;idempotent=(-not$changed);job_name=$name;cadence='5m';session='main';payload='systemEvent';wake='now';immediate_run_enqueued=$true;arbitrary_shell=$false;authority_expansion=$false}
}

''' + anchor
once(anchor, block, 'autonomy continuation function insertion')

old_validation = "        'repair_supervisor_v171_forge_pin' { Assert-SupervisorV171ForgePinRepair $m }\n"
new_validation = old_validation + "        'ensure_autonomy_continuation_automation' { Assert-AutonomyContinuationAutomation $m }\n"
once(old_validation, new_validation, 'validation switch')

old_execution = "            'repair_supervisor_v171_forge_pin' { Repair-SupervisorV171ForgePin $m; break }\n"
new_execution = old_execution + "            'ensure_autonomy_continuation_automation' { Ensure-AutonomyContinuationAutomation; break }\n"
once(old_execution, new_execution, 'execution switch')

old_family = "            'repair_supervisor_v171_forge_pin' {'supervisor_v171_forge_pin_repair_failure'}\n"
new_family = old_family + "            'ensure_autonomy_continuation_automation' {'autonomy_continuation_automation_failure'}\n"
once(old_family, new_family, 'failure-family switch')

old_marker = "    Write-Host 'KEVIN MAINTENANCE v1.3.19 SELFTEST PASS supervisor_baseline_anchor=atomic forge_v4_anchor=preserved rollback=true operation_parity=true arbitrary_shell=false authority_expansion=false'\n"
new_marker = r'''    $ac=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$ac.operation='ensure_autonomy_continuation_automation';Assert-Common $ac;Assert-AutonomyContinuationAutomation $ac
    $acBad=$ac|ConvertTo-Json -Depth 10|ConvertFrom-Json;$acBad|Add-Member -NotePropertyName command -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-AutonomyContinuationAutomation $acBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected autonomy automation command accepted'}
    Write-Host 'KEVIN MAINTENANCE v1.3.19 SELFTEST PASS supervisor_baseline_anchor=atomic forge_v4_anchor=preserved rollback=true operation_parity=true arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.20 SELFTEST PASS native_automation=fixed cadence=5m system_event=true main_session=true arbitrary_shell=false authority_expansion=false'
'''
once(old_marker, new_marker, 'v1.3.20 selftest marker')

OUT.write_text(text, encoding='utf-8', newline='')
sha = hashlib.sha256(OUT.read_bytes()).hexdigest().upper()
print('MAINT_V1320_GENERATED sha256=' + sha)
