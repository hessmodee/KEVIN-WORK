#!/usr/bin/env python3
from pathlib import Path

SRC = Path('control-plane/skill-lab/kevin-skill-lab-v1.0.7.ps1')
DST = Path('control-plane/skill-lab/kevin-skill-lab-v1.0.8.ps1')
text = SRC.read_text(encoding='utf-8')

old_comment = '# Kevin Skill Lab v1.0.7 - autonomously compile a fixed GREEN owner-work recipe after a fresh Supervisor Skill Lab handoff.'
new_comment = '# Kevin Skill Lab v1.0.8 - converge replay-safe owner-work execution with the proven mission-lease live wire.'
if old_comment not in text:
    raise SystemExit('version comment anchor missing')
text = text.replace(old_comment, new_comment, 1)

vars_anchor = "$reg=Join-Path $ws 'reports\\capabilities\\composite-skills.json';$ow=Join-Path $ws 'reports\\owner-work';$owLatest=Join-Path $ow 'latest.json';$qr=Join-Path $a 'queue\\ready';$qrun=Join-Path $a 'queue\\running';$qd=Join-Path $a 'queue\\done';$qf=Join-Path $a 'queue\\failed';$staleMin=15;$maxRecover=3"
vars_repl = vars_anchor + "\n$LeaseBridge=Join-Path $ws 'ControlPlane\\Invoke-KevinMissionLease.ps1'\n$LeaseStore=Join-Path $ws 'reports\\autonomy-runtime\\mission-leases-v1.json'\n$LeaseHolder='skill-lab'"
if vars_anchor not in text:
    raise SystemExit('lease variable anchor missing')
text = text.replace(vars_anchor, vars_repl, 1)

func_anchor = 'function W([string]$p,[object]$o)'
lease_code = r'''function Invoke-MissionLease([string]$LeaseAction,[string]$MissionId='', [string]$EvidenceUri='', [string]$Reason='COMPLETE'){
    if($LeaseAction-notin@('Acquire','Heartbeat','Release')){throw'lease action rejected'}
    if(-not(Test-Path -LiteralPath $LeaseBridge -PathType Leaf)){return $null}
    try{
        $ps=(Get-Command powershell -ErrorAction Stop).Source
        $a=@('-NoProfile','-File',$LeaseBridge,'-Action',$LeaseAction,'-StorePath',$LeaseStore,'-Holder',$LeaseHolder)
        if($MissionId){$a+=@('-MissionId',$MissionId)}
        if($EvidenceUri){$a+=@('-EvidenceUri',$EvidenceUri)}
        if($LeaseAction-eq'Release'){$a+=@('-Reason',$Reason)}
        $out=& $ps @a 2>&1
        if($LASTEXITCODE-ne0){return $null}
        return (($out|Out-String).Trim())
    }catch{return $null}
}
'''
if func_anchor not in text:
    raise SystemExit('function insertion anchor missing')
text = text.replace(func_anchor, lease_code + func_anchor, 1)

save_old = "function SaveT([string]$p,$s,[string]$why){$s.last_transition_at=(Get-Date).ToString('o');$s.runner_heartbeat_at=$s.last_transition_at;$s.last_recovery_reason=$why;W $p $s}"
save_new = "function SaveT([string]$p,$s,[string]$why){$s.last_transition_at=(Get-Date).ToString('o');$s.runner_heartbeat_at=$s.last_transition_at;$s.last_recovery_reason=$why;W $p $s;if($s.manifest){[void](Invoke-MissionLease 'Heartbeat' ([string]$s.manifest.id) ('reports/action-era/skills/running/'+[IO.Path]::GetFileName($p)))}}"
if save_old not in text:
    raise SystemExit('SaveT anchor missing')
text = text.replace(save_old, save_new, 1)

start_old = "W $p $s;Remove-Item $f.FullName -Force;$p}"
start_new = "W $p $s;[void](Invoke-MissionLease 'Acquire' ([string]$x.id) ('reports/action-era/skills/running/'+[IO.Path]::GetFileName($p)));[void](Invoke-MissionLease 'Heartbeat' ([string]$x.id) ('reports/action-era/skills/running/'+[IO.Path]::GetFileName($p)));Remove-Item $f.FullName -Force;$p}"
if text.count(start_old) != 1:
    raise SystemExit(f'StartSkill anchor count={text.count(start_old)}')
text = text.replace(start_old, start_new, 1)

fail_old = ";W $p $s;[void](MoveR $p $sf);Write-Host('SKILL LAB FAILED '+$why)}"
fail_new = ";W $p $s;if($s.manifest){[void](Invoke-MissionLease 'Release' ([string]$s.manifest.id) '' ('FAILED:'+$why))};[void](MoveR $p $sf);Write-Host('SKILL LAB FAILED '+$why)}"
if text.count(fail_old) != 1:
    raise SystemExit(f'Fail anchor count={text.count(fail_old)}')
text = text.replace(fail_old, fail_new, 1)

complete_old = ";Write-Host('SKILL LAB PROVEN '+$key)}"
complete_new = ";[void](Invoke-MissionLease 'Release' ([string]$s.manifest.id) '' 'COMPLETE');Write-Host('SKILL LAB PROVEN '+$key)}"
if text.count(complete_old) != 1:
    raise SystemExit(f'Complete anchor count={text.count(complete_old)}')
text = text.replace(complete_old, complete_new, 1)

selftest_marker_old = "Write-Host 'KEVIN SKILL LAB v1.0.7 SELFTEST PASS primitives=3 owner_work_compiler=fixed_green route_proof_required=true exact_recipe_allowlist=true arbitrary_shell=false authority_expansion=false'"
selftest_marker_new = "$badLease=$false;try{[void](Invoke-MissionLease 'Arbitrary' 'x')}catch{$badLease=$true};if(-not$badLease){throw'unknown lease action accepted'};Write-Host 'KEVIN SKILL LAB v1.0.8 SELFTEST PASS primitives=3 owner_work_compiler=fixed_green route_proof_required=true replay_receipt_preserved=true mission_lease_wire=preserved lease_release_on_terminal=true exact_recipe_allowlist=true arbitrary_shell=false authority_expansion=false'"
if selftest_marker_old not in text:
    raise SystemExit('selftest marker anchor missing')
text = text.replace(selftest_marker_old, selftest_marker_new, 1)

compat_old = "KEVIN SKILL LAB v1.0.3 SELFTEST PASS compatibility=v1.0.7-maintenance-v1.2"
compat_new = "KEVIN SKILL LAB v1.0.3 SELFTEST PASS compatibility=v1.0.8-maintenance-v1.2"
if compat_old not in text:
    raise SystemExit('compatibility marker anchor missing')
text = text.replace(compat_old, compat_new, 1)

selftest_exit_old = "if($SelfTest){SelfTest;exit 0}"
selftest_exit_new = r'''if($SelfTest){
    SelfTest
    if(Test-Path -LiteralPath $LeaseBridge -PathType Leaf){
        try{
            $ps=(Get-Command powershell -ErrorAction Stop).Source
            $ls=& $ps -NoProfile -File $LeaseBridge -Action SelfTest 2>&1
            if($LASTEXITCODE-ne0){throw ('mission lease wire selftest failed: '+(($ls|Out-String).Trim()))}
            Write-Host 'SKILL LAB MISSION-LEASE WIRE SELFTEST PASS runtime_bridge=true'
        }catch{throw}
    }else{
        Write-Host 'SKILL LAB MISSION-LEASE WIRE SELFTEST DEFERRED staged_source=true'
    }
    exit 0
}'''
if selftest_exit_old not in text:
    raise SystemExit('selftest exit anchor missing')
text = text.replace(selftest_exit_old, selftest_exit_new, 1)

required = [
    'Preserve-ProvenReplay',
    'OwnerWorkStage',
    "Invoke-MissionLease 'Acquire'",
    "Invoke-MissionLease 'Heartbeat'",
    "Invoke-MissionLease 'Release'",
    'kevin-owner-work-outcome',
    'v1.0.8 SELFTEST PASS',
]
for marker in required:
    if marker not in text:
        raise SystemExit('required marker missing: ' + marker)

DST.write_text(text, encoding='utf-8', newline='\n')
print(f'generated {DST} bytes={DST.stat().st_size}')
