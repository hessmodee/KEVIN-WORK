from pathlib import Path

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.7.ps1')
DST=Path('control-plane/maintenance/generated/kevin-maintenance-runner-v1.3.8.ps1')
text=SRC.read_text(encoding='utf-8')

def once(old,new):
    global text
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'expected exactly one marker, got {n}: {old[:100]!r}')
    text=text.replace(old,new,1)

once("version='1.3.7'","version='1.3.8'")
once("'replace_runtime_policy_bundle','migrate_design_forge_v40')","'replace_runtime_policy_bundle','migrate_design_forge_v40','configure_skill_workshop_guardrails')")

insert=r'''
function Assert-SkillWorkshopGuardrails([object]$m) {
    foreach($name in @('path','key','value','command','args','plugin','target','mode','approval_policy')){
        if($m.PSObject.Properties[$name]){throw ('skill workshop guardrail manifest must not supply '+$name)}
    }
}
function Invoke-OpenClawFixedConfig([string[]]$Args) {
    $cmd=Get-Command openclaw -ErrorAction SilentlyContinue
    if(-not$cmd){throw 'OpenClaw CLI unavailable'}
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $cmd.Source @Args 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    return [pscustomobject]@{exit_code=$code;output=[string]$out}
}
function Get-WorkshopAuthoredValue([string]$Path,[string[]]$Allowed) {
    if($Path -notin @('skills.workshop.autonomous.mode','skills.workshop.approvalPolicy')){throw 'workshop config path not fixed'}
    $r=Invoke-OpenClawFixedConfig @('config','get',$Path,'--json')
    if($r.exit_code -ne 0){return [pscustomobject]@{present=$false;value=''}}
    $v=[string]$r.output;$v=$v.Trim().Trim('"')
    if($Allowed -notcontains $v){throw ('unexpected authored value at '+$Path)}
    return [pscustomobject]@{present=$true;value=$v}
}
function Restore-WorkshopValue([string]$Path,[object]$Before) {
    if([bool]$Before.present){$r=Invoke-OpenClawFixedConfig @('config','set',$Path,[string]$Before.value);if($r.exit_code -ne 0){throw ('rollback set failed '+$Path)}}
    else{$r=Invoke-OpenClawFixedConfig @('config','unset',$Path);if($r.exit_code -ne 0){throw ('rollback unset failed '+$Path)}}
}
function Configure-SkillWorkshopGuardrails {
    $modePath='skills.workshop.autonomous.mode'
    $approvalPath='skills.workshop.approvalPolicy'
    $beforeMode=Get-WorkshopAuthoredValue $modePath @('off','propose','auto')
    $beforeApproval=Get-WorkshopAuthoredValue $approvalPath @('pending','auto')
    if($beforeMode.present -and $beforeMode.value -eq 'propose' -and $beforeApproval.present -and $beforeApproval.value -eq 'pending'){
        $v=Invoke-OpenClawFixedConfig @('config','validate','--json');if($v.exit_code -ne 0){throw 'existing Workshop guardrails present but config invalid'}
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;autonomous_mode='propose';approval_policy='pending'}
    }
    $dryMode=Invoke-OpenClawFixedConfig @('config','set',$modePath,'propose','--dry-run','--json')
    if($dryMode.exit_code -ne 0){throw 'Workshop propose dry-run rejected'}
    $dryApproval=Invoke-OpenClawFixedConfig @('config','set',$approvalPath,'pending','--dry-run','--json')
    if($dryApproval.exit_code -ne 0){throw 'Workshop pending dry-run rejected'}
    try{
        $setMode=Invoke-OpenClawFixedConfig @('config','set',$modePath,'propose');if($setMode.exit_code -ne 0){throw 'Workshop propose write failed'}
        $setApproval=Invoke-OpenClawFixedConfig @('config','set',$approvalPath,'pending');if($setApproval.exit_code -ne 0){throw 'Workshop pending write failed'}
        $validate=Invoke-OpenClawFixedConfig @('config','validate','--json');if($validate.exit_code -ne 0){throw 'OpenClaw config invalid after Workshop guardrails'}
        $mode=Get-WorkshopAuthoredValue $modePath @('off','propose','auto')
        $approval=Get-WorkshopAuthoredValue $approvalPath @('pending','auto')
        if(-not$mode.present -or $mode.value -ne 'propose'){throw 'Workshop propose readback failed'}
        if(-not$approval.present -or $approval.value -ne 'pending'){throw 'Workshop pending readback failed'}
        $skills=Invoke-OpenClawFixedConfig @('skills','check','--agent','main','--json');if($skills.exit_code -ne 0){throw 'main-agent skills check failed after Workshop guardrails'}
        Assert-Benchmark30
        return [ordered]@{changed=$true;idempotent=$false;autonomous_mode='propose';approval_policy='pending';rollback_available=$true}
    }catch{
        $primary=$_.Exception.Message
        try{Restore-WorkshopValue $approvalPath $beforeApproval}catch{}
        try{Restore-WorkshopValue $modePath $beforeMode}catch{}
        try{Invoke-OpenClawFixedConfig @('config','validate','--json')|Out-Null}catch{}
        try{Assert-Benchmark30}catch{}
        throw ('skill workshop guardrail rollback completed: '+$primary)
    }
}
'''.strip()
once('function Process-Typed([object]$m) {',insert+'\n\nfunction Process-Typed([object]$m) {')

once("        'migrate_design_forge_v40' { Assert-ForgeMigration $m }\n        default { throw 'operation not allowlisted' }",
     "        'migrate_design_forge_v40' { Assert-ForgeMigration $m }\n        'configure_skill_workshop_guardrails' { Assert-SkillWorkshopGuardrails $m }\n        default { throw 'operation not allowlisted' }")
once("            'migrate_design_forge_v40' { Migrate-DesignForgeV40 $m; break }\n        }",
     "            'migrate_design_forge_v40' { Migrate-DesignForgeV40 $m; break }\n            'configure_skill_workshop_guardrails' { Configure-SkillWorkshopGuardrails; break }\n        }")
once("            'migrate_design_forge_v40' {'forge_validator_migration_failure'}\n            default {'typed_replace_failure'}",
     "            'migrate_design_forge_v40' {'forge_validator_migration_failure'}\n            'configure_skill_workshop_guardrails' {'skill_workshop_guardrail_failure'}\n            default {'typed_replace_failure'}")

selftest=r'''
    $guard=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$guard.operation='configure_skill_workshop_guardrails';Assert-Common $guard;Assert-SkillWorkshopGuardrails $guard
    $guardBad=$guard|ConvertTo-Json -Depth 10|ConvertFrom-Json;$guardBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary.path';$blocked=$false;try{Assert-SkillWorkshopGuardrails $guardBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Workshop config path accepted'}
'''.rstrip()
once("    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='migrate_design_forge_v40';target_alias='design_forge_runner';source_path='control-plane/forge/kevin-design-forge-v4.0.ps1';source_sha256=('C'*64);expected_forge_current_sha256=('B'*64);expected_forge_after_sha256=('C'*64);expected_benchmark_current_sha256=('D'*64);expires_at=(Get-Date).AddMinutes(10).ToString('o')}",
     selftest+"\n    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='migrate_design_forge_v40';target_alias='design_forge_runner';source_path='control-plane/forge/kevin-design-forge-v4.0.ps1';source_sha256=('C'*64);expected_forge_current_sha256=('B'*64);expected_forge_after_sha256=('C'*64);expected_benchmark_current_sha256=('D'*64);expires_at=(Get-Date).AddMinutes(10).ToString('o')}")
once("    Write-Host 'KEVIN MAINTENANCE v1.3.7 SELFTEST PASS aliases=6 runtime_policy_bundle=5 convergence_audit=1 convergence_publish=1 runtime_capability_audit=1 fixed_public_receipt=2 read_only_openclaw_probes=1 arbitrary_shell=false authority_expansion=false max_attempts=3'",
     "    Write-Host 'KEVIN MAINTENANCE v1.3.7 SELFTEST PASS compatibility=v1.3.8'\n    Write-Host 'KEVIN MAINTENANCE v1.3.8 SELFTEST PASS aliases=6 runtime_policy_bundle=5 workshop_guardrails=propose_pending fixed_config_paths=2 config_dry_run=true rollback=true arbitrary_shell=false authority_expansion=false max_attempts=3'")

DST.parent.mkdir(parents=True,exist_ok=True)
DST.write_text(text,encoding='utf-8',newline='\n')
print(DST)
