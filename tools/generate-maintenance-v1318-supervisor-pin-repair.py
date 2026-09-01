from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.17.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.18.ps1')
EXPECTED_SRC_SHA256 = '667BBFD034F33E7EE95E887B0AB5FFF9742092B9FB7F25A127F160CE0772AAA2'
SUPERVISOR_V171_SHA = '47A0A1D0E3F744E972E2F2239F100CA2B009ABD3928D0281E4587A364B7C27AC'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA256:
    raise SystemExit(f'v1.3.17 source identity mismatch: {actual}')
text = raw.decode('utf-8')

def replace_once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)

replace_once("version='1.3.17'", "version='1.3.18'", 'state version')

replace_once(
    "$SupervisorV17Sha = '796B1756CE0B3C9E926AA72A32410FC9119F0AD4FEC2E6CA15D977F4DA87333A'\n$ForgeV37Sha =",
    "$SupervisorV17Sha = '796B1756CE0B3C9E926AA72A32410FC9119F0AD4FEC2E6CA15D977F4DA87333A'\n$SupervisorV171Sha = '" + SUPERVISOR_V171_SHA + "'\n$ForgeV37Sha =",
    'v1.7.1 identity constant',
)

old_allow = "'diagnose_benchmark_baseline_forge_anchor','migrate_supervisor_forge_demand_gated_v17')"
new_allow = "'diagnose_benchmark_baseline_forge_anchor','migrate_supervisor_forge_demand_gated_v17','repair_supervisor_v171_forge_pin')"
replace_once(old_allow, new_allow, 'common operation allowlist')

assert_anchor = "function Get-DemandGatedSupervisorV17([string]$Text) {"
assert_block = r'''function Assert-SupervisorV171ForgePinRepair([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('Supervisor v1.7.1 pin repair manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'repair_supervisor_v171_forge_pin'){throw 'Supervisor v1.7.1 pin repair operation mismatch'}
}
function Get-SupervisorV171ForgePinPatched([string]$Text) {
    $header='# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel'
    if((Get-LiteralOccurrenceCount $Text $header) -ne 1){throw 'Supervisor v1.7 header anchor mismatch'}
    if((Get-LiteralOccurrenceCount $Text $ForgeV37Sha) -ne 1){throw 'Supervisor v1.7 old Forge pin must occur exactly once'}
    if((Get-LiteralOccurrenceCount $Text $ForgeV40Sha) -ne 0){throw 'Supervisor v1.7 already contains Forge v4 pin'}
    $out=$Text.Replace($ForgeV37Sha,$ForgeV40Sha).Replace('Design Forge hash changed from approved v3.7.','Design Forge hash changed from approved v4.0.')
    if((Get-LiteralOccurrenceCount $out $ForgeV37Sha) -ne 0){throw 'Supervisor v1.7.1 retained old Forge pin'}
    if((Get-LiteralOccurrenceCount $out $ForgeV40Sha) -ne 1){throw 'Supervisor v1.7.1 Forge v4 pin missing or duplicated'}
    if(-not$out.Contains('SUPERVISOR IDLE NO_ELIGIBLE_MISSION')){throw 'Supervisor v1.7.1 demand gate marker missing'}
    return $out
}
'''
replace_once(assert_anchor, assert_block + assert_anchor, 'Supervisor v1.7.1 validators')

repair_anchor = "function Restart-UiBridge([object]$m) {"
repair_block = r'''function Repair-SupervisorV171ForgePin([object]$m) {
    Assert-SupervisorV171ForgePinRepair $m
    if($env:OS -ne 'Windows_NT'){throw 'Supervisor v1.7.1 repair requires Windows'}
    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $forgeTarget=(Get-AliasSpec 'design_forge_runner').Target
    if(-not(Test-Path -LiteralPath $supervisorTarget -PathType Leaf)){throw 'Supervisor target missing'}
    if(-not(Test-Path -LiteralPath $forgeTarget -PathType Leaf)){throw 'Forge target missing'}
    $before=Get-Sha $supervisorTarget
    $forge=Get-Sha $forgeTarget
    if($forge -ne $ForgeV40Sha){throw ('Forge v4 expected-current mismatch actual='+$forge)}
    if($before -eq $SupervisorV171Sha){Assert-Benchmark30;return [ordered]@{changed=$false;idempotent=$true;supervisor_after=$before;forge_pin=$ForgeV40Sha}}
    if($before -ne $SupervisorV17Sha){throw ('Supervisor v1.7 expected-current mismatch actual='+$before)}

    $patched=Get-SupervisorV171ForgePinPatched ([IO.File]::ReadAllText($supervisorTarget))
    $stage=Join-Path $StageRoot ([string]$m.id+'.supervisor-v171.ps1')
    [IO.File]::WriteAllText($stage,$patched,$Utf8)
    $stageSha=Get-Sha $stage
    if($stageSha -ne $SupervisorV171Sha){throw ('Supervisor v1.7.1 deterministic candidate hash mismatch actual='+$stageSha)}
    Parse-PowerShell $stage
    $stageText=[IO.File]::ReadAllText($stage)
    if((Get-LiteralOccurrenceCount $stageText $ForgeV40Sha) -ne 1){throw 'Supervisor v1.7.1 staged Forge pin mismatch'}
    if((Get-LiteralOccurrenceCount $stageText $ForgeV37Sha) -ne 0){throw 'Supervisor v1.7.1 staged old Forge pin remained'}
    foreach($marker in @('# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel','SUPERVISOR IDLE NO_ELIGIBLE_MISSION','governed selector/Task Flow path')){if(-not$stageText.Contains($marker)){throw ('Supervisor v1.7.1 marker missing: '+$marker)}}
    if($stageText -match '(?i)Invoke-Expression|kevin_shell|Start-Process\s+cmd\.exe'){throw 'Supervisor v1.7.1 introduced forbidden arbitrary execution marker'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir|Out-Null
    $backup=Join-Path $backupDir 'kevin-supervisor.ps1'
    Copy-Item -LiteralPath $supervisorTarget -Destination $backup -Force
    $mutex=$null;$owned=$false
    try {
        $mutex=New-Object -TypeName System.Threading.Mutex -ArgumentList $false,'Global\KevinSupervisor'
        try{$owned=$mutex.WaitOne(60000)}catch [System.Threading.AbandonedMutexException]{$owned=$true}
        if(-not$owned){throw 'Supervisor did not become idle within 60 seconds'}
        if((Get-Sha $supervisorTarget) -ne $SupervisorV17Sha){throw 'Supervisor changed after staging; aborting TOCTOU'}
        if((Get-Sha $forgeTarget) -ne $ForgeV40Sha){throw 'Forge changed after staging; aborting TOCTOU'}
        $tmp=$supervisorTarget+'.typed-'+[guid]::NewGuid().ToString('N')
        Copy-Item -LiteralPath $stage -Destination $tmp -Force
        Move-Item -LiteralPath $tmp -Destination $supervisorTarget -Force
        if((Get-Sha $supervisorTarget) -ne $SupervisorV171Sha){throw 'installed Supervisor v1.7.1 hash mismatch'}
        Parse-PowerShell $supervisorTarget
        Assert-Benchmark30
        return [ordered]@{changed=$true;supervisor_before=$before;supervisor_after=(Get-Sha $supervisorTarget);forge_pin=$ForgeV40Sha;demand_gate_preserved=$true;rollback_available=$true}
    } catch {
        if(Test-Path -LiteralPath $backup -PathType Leaf){Copy-Item -LiteralPath $backup -Destination $supervisorTarget -Force}
        try{Assert-Benchmark30}catch{}
        throw ('Supervisor v1.7.1 repair rollback completed: '+$_.Exception.Message)
    } finally {
        if($owned -and $mutex){try{$mutex.ReleaseMutex()}catch{}}
        if($mutex){$mutex.Dispose()}
    }
}
'''
replace_once(repair_anchor, repair_block + repair_anchor, 'Supervisor v1.7.1 repair implementation')

old_validate = "        'migrate_supervisor_forge_demand_gated_v17' { Assert-SupervisorForgeDemandGateMigration $m }\n        default { throw 'operation not allowlisted' }"
new_validate = "        'migrate_supervisor_forge_demand_gated_v17' { Assert-SupervisorForgeDemandGateMigration $m }\n        'repair_supervisor_v171_forge_pin' { Assert-SupervisorV171ForgePinRepair $m }\n        default { throw 'operation not allowlisted' }"
replace_once(old_validate, new_validate, 'typed validation switch')

old_exec = "            'migrate_supervisor_forge_demand_gated_v17' { Migrate-SupervisorForgeDemandGatedV17 $m; break }\n        }"
new_exec = "            'migrate_supervisor_forge_demand_gated_v17' { Migrate-SupervisorForgeDemandGatedV17 $m; break }\n            'repair_supervisor_v171_forge_pin' { Repair-SupervisorV171ForgePin $m; break }\n        }"
replace_once(old_exec, new_exec, 'execution switch')

old_family = "            'migrate_supervisor_forge_demand_gated_v17' {'supervisor_forge_demand_gate_migration_failure'}\n            default {'typed_replace_failure'}"
new_family = "            'migrate_supervisor_forge_demand_gated_v17' {'supervisor_forge_demand_gate_migration_failure'}\n            'repair_supervisor_v171_forge_pin' {'supervisor_v171_forge_pin_repair_failure'}\n            default {'typed_replace_failure'}"
replace_once(old_family, new_family, 'failure family switch')

selftest_anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.17 SELFTEST PASS operation_parity=fixed supervisor_forge_validation=true arbitrary_shell=false authority_expansion=false'\n"
selftest_insert = selftest_anchor + r'''    $sr=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$sr.operation='repair_supervisor_v171_forge_pin';Assert-Common $sr;Assert-SupervisorV171ForgePinRepair $sr
    $srBad=$sr|ConvertTo-Json -Depth 10|ConvertFrom-Json;$srBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-SupervisorV171ForgePinRepair $srBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Supervisor repair path accepted'}
    $fixture='# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel'+[Environment]::NewLine+$ForgeV37Sha+[Environment]::NewLine+'Design Forge hash changed from approved v3.7.'+[Environment]::NewLine+'SUPERVISOR IDLE NO_ELIGIBLE_MISSION'+[Environment]::NewLine
    $fixed=Get-SupervisorV171ForgePinPatched $fixture
    if((Get-LiteralOccurrenceCount $fixed $ForgeV37Sha)-ne0 -or (Get-LiteralOccurrenceCount $fixed $ForgeV40Sha)-ne1){throw 'Supervisor v1.7.1 Forge pin fixture failed'}
    Write-Host 'KEVIN MAINTENANCE v1.3.18 SELFTEST PASS supervisor_v171_forge_pin=fixed demand_gate_preserved=true rollback=true operation_parity=true arbitrary_shell=false authority_expansion=false'
'''
replace_once(selftest_anchor, selftest_insert, 'v1.3.18 selftest block')

OUT.write_text(text, encoding='utf-8', newline='')
sha = hashlib.sha256(OUT.read_bytes()).hexdigest().upper()
print('MAINT_V1318_GENERATED sha256=' + sha)
