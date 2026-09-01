from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.15.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.16.ps1')
EXPECTED_SRC_SHA = 'F6C283AEFDC069AF528480AA59E0D1649AFEF251E638B901E18ACBCCBE282A2C'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA:
    raise SystemExit(f'v1.3.15 source identity mismatch: {actual}')
text = raw.decode('utf-8')


def once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)

once("version='1.3.15'", "version='1.3.16'", 'state version')

constants_anchor = "$RuntimePolicyNames = @('AGENTS.md','HEARTBEAT.md','MEMORY.md','SOUL.md','TOOLS.md')\n"
constants = constants_anchor + """$SupervisorV16Sha = '63B8D9C27625E0FB6AFE62165BE376E7ED7EB416E5DA15BB47C206BBF4AE4989'\n$SupervisorV17Sha = '796B1756CE0B3C9E926AA72A32410FC9119F0AD4FEC2E6CA15D977F4DA87333A'\n$ForgeV37Sha = '4C83DF29E765D61F2B26D2029FE6C2C7ED68DA90E5A7A457A82BE769029E22CA'\n$ForgeV40Sha = '433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'\n$ForgeV40Source = 'control-plane/forge/kevin-design-forge-v4.0.ps1'\n$BenchmarkBaselineBeforeSha = 'B4F2B01ADBFC946754A987797F94D3E50C51300111DE4003546825D11ED649A1'\n"""
once(constants_anchor, constants, 'migration constants')

old_allow = "'diagnose_goal_os_forge_anchor','diagnose_benchmark_baseline_forge_anchor') -contains [string]$m.operation)"
new_allow = "'diagnose_goal_os_forge_anchor','diagnose_benchmark_baseline_forge_anchor','migrate_supervisor_forge_demand_gated_v17') -contains [string]$m.operation)"
once(old_allow, new_allow, 'operation allowlist')

assert_anchor = "function Assert-Restart([object]$m) {\n"
assert_code = r'''function Assert-SupervisorForgeDemandGateMigration([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('Supervisor/Forge migration manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'migrate_supervisor_forge_demand_gated_v17'){throw 'Supervisor/Forge migration operation mismatch'}
}
function Get-DemandGatedSupervisorV17([string]$Text) {
    $oldHeader='# Kevin Supervisor v1.6 High Gear'
    $newHeader='# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel'
    if((Get-LiteralOccurrenceCount $Text $oldHeader) -ne 1){throw 'Supervisor v1.6 header anchor mismatch'}
    $nl=if($Text.Contains("`r`n")){"`r`n"}else{"`n"}
    $anchor='    $recoveryExperiment = $null'+$nl
    if((Get-LiteralOccurrenceCount $Text $anchor) -ne 1){throw 'Supervisor recovery-dispatch anchor mismatch'}
    $lines=@(
        '    # v1.7: legacy Supervisor candidate dispatch is retired.',
        '    # Durable owner work is admitted by the governed selector/Task Flow path; Forge v4 consumes only typed eligible demand.',
        '    Ensure-Property $state "last_mission" ""',
        '    Ensure-Property $state "last_result" "NO_ELIGIBLE_MISSION"',
        '    Ensure-Property $state "next_eligible_at" ((Get-Date).AddMinutes(3).ToString("o"))',
        '    Ensure-Property $state "updated_at" ((Get-Date).ToString("o"))',
        '    Save-JsonAtomic $statePath $state',
        '',
        '    Rec @{',
        '        event = "cycle"',
        '        result = "NO_ELIGIBLE_MISSION"',
        '        detail = "Legacy Supervisor candidate dispatch retired; governed demand flow owns admission."',
        '    }',
        '',
        '    Write-Status `',
        '        "WAITING" `',
        '        "No eligible legacy mission. Governed work selection and Task Flow own admission; Forge v4 requires typed demand." `',
        '        $state',
        '',
        '    Write-Host "SUPERVISOR IDLE NO_ELIGIBLE_MISSION"',
        '    return',
        '',
        '    $recoveryExperiment = $null'
    )
    $block=($lines -join $nl)+$nl
    $out=$Text.Replace($oldHeader,$newHeader).Replace($anchor,$block)
    if((Get-LiteralOccurrenceCount $out $newHeader) -ne 1){throw 'Supervisor v1.7 header missing after patch'}
    $idle=$out.IndexOf('SUPERVISOR IDLE NO_ELIGIBLE_MISSION',[StringComparison]::Ordinal)
    $legacy=$out.IndexOf('MissionContractPath',[StringComparison]::Ordinal)
    if($idle -lt 0 -or $legacy -lt 0 -or $idle -ge $legacy){throw 'Supervisor demand gate is not before legacy Forge dispatch'}
    $between=$out.Substring($idle,$legacy-$idle)
    if($between -notmatch '(?m)^\s*return\s*$'){throw 'Supervisor demand gate lacks fail-closed return'}
    return $out
}
''' + assert_anchor
once(assert_anchor, assert_code, 'migration assertion/helper insertion')

migration_anchor = "function Restart-UiBridge([object]$m) {\n"
migration_code = r'''function Migrate-SupervisorForgeDemandGatedV17([object]$m) {
    Assert-SupervisorForgeDemandGateMigration $m
    if($env:OS -ne 'Windows_NT'){throw 'Supervisor/Forge coordinated migration requires Windows'}
    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $forgeTarget=(Get-AliasSpec 'design_forge_runner').Target
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    foreach($p in @($supervisorTarget,$forgeTarget,$baselineTarget)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('coordinated migration target missing: '+[IO.Path]::GetFileName($p))}}

    $supBefore=Get-Sha $supervisorTarget
    $forgeBefore=Get-Sha $forgeTarget
    $baselineBefore=Get-Sha $baselineTarget
    if($supBefore -ne $SupervisorV16Sha){throw ('Supervisor expected-current mismatch actual='+$supBefore)}
    if($forgeBefore -ne $ForgeV37Sha){throw ('Forge expected-current mismatch actual='+$forgeBefore)}
    if($baselineBefore -ne $BenchmarkBaselineBeforeSha){throw ('Benchmark baseline expected-current mismatch actual='+$baselineBefore)}

    $baselineObj=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
    if(-not$baselineObj.hashes){throw 'Benchmark baseline hashes missing'}
    if(([string]$baselineObj.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV16Sha){throw 'Benchmark baseline Supervisor anchor does not match live v1.6'}
    if(([string]$baselineObj.hashes.forge).ToUpperInvariant() -ne $ForgeV37Sha){throw 'Benchmark baseline Forge anchor does not match live v3.7'}

    $supText=[IO.File]::ReadAllText($supervisorTarget)
    $supPatched=Get-DemandGatedSupervisorV17 $supText
    $supStage=Join-Path $StageRoot ([string]$m.id+'.supervisor.ps1')
    [IO.File]::WriteAllText($supStage,$supPatched,$Utf8)
    if((Get-Sha $supStage) -ne $SupervisorV17Sha){throw ('Supervisor v1.7 deterministic candidate hash mismatch actual='+(Get-Sha $supStage))}
    Parse-PowerShell $supStage
    $supStageText=[IO.File]::ReadAllText($supStage)
    foreach($marker in @('# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel','SUPERVISOR IDLE NO_ELIGIBLE_MISSION','governed selector/Task Flow path')){if(-not$supStageText.Contains($marker)){throw ('Supervisor v1.7 marker missing: '+$marker)}}
    if($supStageText -match '(?i)Invoke-Expression|kevin_shell|Start-Process\s+cmd\.exe'){throw 'Supervisor v1.7 introduced forbidden arbitrary execution marker'}

    $forgeBytes=Get-RemoteFixedBytes $ForgeV40Source
    $forgeStage=Join-Path $StageRoot ([string]$m.id+'.forge.ps1')
    [IO.File]::WriteAllBytes($forgeStage,$forgeBytes)
    if((Get-Sha $forgeStage) -ne $ForgeV40Sha){throw ('Forge v4 staged identity mismatch actual='+(Get-Sha $forgeStage))}
    Parse-PowerShell $forgeStage
    Invoke-FixedSelfTest 'design_forge_runner' $forgeStage
    $forgeStageText=[IO.File]::ReadAllText($forgeStage)
    foreach($marker in @("status='IDLE_NO_ELIGIBLE_DEMAND'",'demand_driven=$true','round_robin=$false')){if(-not$forgeStageText.Contains($marker)){throw ('Forge v4 demand-gate marker missing: '+$marker)}}
    if($forgeStageText.Contains('MissionContractPath')){throw 'Forge v4 unexpectedly accepts legacy MissionContractPath'}

    $baselineText=[IO.File]::ReadAllText($baselineTarget)
    if((Get-LiteralOccurrenceCount $baselineText $SupervisorV16Sha) -ne 1){throw 'Benchmark baseline old Supervisor anchor must occur exactly once'}
    if((Get-LiteralOccurrenceCount $baselineText $ForgeV37Sha) -ne 1){throw 'Benchmark baseline old Forge anchor must occur exactly once'}
    if((Get-LiteralOccurrenceCount $baselineText $SupervisorV17Sha) -ne 0){throw 'Benchmark baseline already contains candidate Supervisor anchor'}
    if((Get-LiteralOccurrenceCount $baselineText $ForgeV40Sha) -ne 0){throw 'Benchmark baseline already contains candidate Forge anchor'}
    $baselinePatched=$baselineText.Replace($SupervisorV16Sha,$SupervisorV17Sha).Replace($ForgeV37Sha,$ForgeV40Sha)
    $baselineStage=Join-Path $StageRoot ([string]$m.id+'.baseline.json')
    [IO.File]::WriteAllText($baselineStage,$baselinePatched,$Utf8)
    $baselineStageObj=Get-Content -LiteralPath $baselineStage -Raw|ConvertFrom-Json
    if(([string]$baselineStageObj.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV17Sha){throw 'staged baseline Supervisor anchor mismatch'}
    if(([string]$baselineStageObj.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'staged baseline Forge anchor mismatch'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir|Out-Null
    $supBackup=Join-Path $backupDir 'kevin-supervisor.ps1'
    $forgeBackup=Join-Path $backupDir 'kevin-design-forge.ps1'
    $baselineBackup=Join-Path $backupDir 'benchmark-baseline.json'
    Copy-Item -LiteralPath $supervisorTarget -Destination $supBackup -Force
    Copy-Item -LiteralPath $forgeTarget -Destination $forgeBackup -Force
    Copy-Item -LiteralPath $baselineTarget -Destination $baselineBackup -Force

    $supMutex=$null;$forgeMutex=$null;$supOwned=$false;$forgeOwned=$false
    try {
        $supMutex=New-Object -TypeName System.Threading.Mutex -ArgumentList $false,'Global\KevinSupervisor'
        $forgeMutex=New-Object -TypeName System.Threading.Mutex -ArgumentList $false,'Global\KevinDesignForge'
        try{$supOwned=$supMutex.WaitOne(60000)}catch[System.Threading.AbandonedMutexException]{$supOwned=$true}
        if(-not$supOwned){throw 'Supervisor did not become idle within 60 seconds'}
        try{$forgeOwned=$forgeMutex.WaitOne(60000)}catch[System.Threading.AbandonedMutexException]{$forgeOwned=$true}
        if(-not$forgeOwned){throw 'Forge did not become idle within 60 seconds'}

        if((Get-Sha $supervisorTarget) -ne $SupervisorV16Sha){throw 'Supervisor changed after staging; aborting TOCTOU'}
        if((Get-Sha $forgeTarget) -ne $ForgeV37Sha){throw 'Forge changed after staging; aborting TOCTOU'}
        if((Get-Sha $baselineTarget) -ne $BenchmarkBaselineBeforeSha){throw 'Benchmark baseline changed after staging; aborting TOCTOU'}

        foreach($pair in @(@($supStage,$supervisorTarget),@($forgeStage,$forgeTarget),@($baselineStage,$baselineTarget))){
            $tmp=[string]$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $pair[1] -Force
        }
        if((Get-Sha $supervisorTarget) -ne $SupervisorV17Sha){throw 'installed Supervisor v1.7 hash mismatch'}
        if((Get-Sha $forgeTarget) -ne $ForgeV40Sha){throw 'installed Forge v4 hash mismatch'}
        $liveBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$liveBase.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV17Sha -or ([string]$liveBase.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'installed Benchmark baseline anchors mismatch'}
        Parse-PowerShell $supervisorTarget
        Parse-PowerShell $forgeTarget
        Invoke-FixedSelfTest 'design_forge_runner' $forgeTarget
        Assert-Benchmark30
        return [ordered]@{
            changed=$true
            supervisor_before=$supBefore
            supervisor_after=(Get-Sha $supervisorTarget)
            forge_before=$forgeBefore
            forge_after=(Get-Sha $forgeTarget)
            baseline_before=$baselineBefore
            baseline_after=(Get-Sha $baselineTarget)
            demand_gate='legacy Supervisor dispatch retired; Forge v4 typed-demand only'
            mutex_protected=$true
            rollback_available=$true
        }
    } catch {
        if(Test-Path -LiteralPath $supBackup -PathType Leaf){Copy-Item -LiteralPath $supBackup -Destination $supervisorTarget -Force}
        if(Test-Path -LiteralPath $forgeBackup -PathType Leaf){Copy-Item -LiteralPath $forgeBackup -Destination $forgeTarget -Force}
        if(Test-Path -LiteralPath $baselineBackup -PathType Leaf){Copy-Item -LiteralPath $baselineBackup -Destination $baselineTarget -Force}
        try{Assert-Benchmark30}catch{}
        throw ('Supervisor/Forge coordinated migration rollback completed: '+$_.Exception.Message)
    } finally {
        if($forgeOwned -and $forgeMutex){try{$forgeMutex.ReleaseMutex()}catch{}}
        if($supOwned -and $supMutex){try{$supMutex.ReleaseMutex()}catch{}}
        if($forgeMutex){$forgeMutex.Dispose()}
        if($supMutex){$supMutex.Dispose()}
    }
}
''' + migration_anchor
once(migration_anchor, migration_code, 'migration function insertion')

switch_old = "            'diagnose_benchmark_baseline_forge_anchor' { Diagnose-BenchmarkBaselineForgeAnchor; break }\n"
switch_new = switch_old + "            'migrate_supervisor_forge_demand_gated_v17' { Migrate-SupervisorForgeDemandGatedV17 $m; break }\n"
once(switch_old, switch_new, 'process switch')

family_old = "            'diagnose_benchmark_baseline_forge_anchor' {'benchmark_baseline_forge_anchor_diagnosis_failure'}\n"
family_new = family_old + "            'migrate_supervisor_forge_demand_gated_v17' {'supervisor_forge_demand_gate_migration_failure'}\n"
once(family_old, family_new, 'failure family')

selftest_anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.15 SELFTEST PASS benchmark_baseline_anchor=fixed typed_apply_failure=handled scheduler_backoff_poison=false arbitrary_shell=false authority_expansion=false'\n"
selftest = r'''    $sf=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-supervisor-forge-v17';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='migrate_supervisor_forge_demand_gated_v17';expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-Common $sf;Assert-SupervisorForgeDemandGateMigration $sf
    $sfBad=$sf|ConvertTo-Json -Depth 10|ConvertFrom-Json;$sfBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-SupervisorForgeDemandGateMigration $sfBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Supervisor/Forge path accepted'}
    $nl=[Environment]::NewLine
    $fixture='# Kevin Supervisor v1.6 High Gear'+$nl+'prefix'+$nl+'    $recoveryExperiment = $null'+$nl+'legacy MissionContractPath suffix'+$nl
    $gate=Get-DemandGatedSupervisorV17 $fixture
    if(-not$gate.Contains('# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel') -or -not$gate.Contains('SUPERVISOR IDLE NO_ELIGIBLE_MISSION')){throw 'Supervisor v1.7 deterministic patch fixture failed'}
    if($gate.IndexOf('SUPERVISOR IDLE NO_ELIGIBLE_MISSION') -ge $gate.IndexOf('MissionContractPath')){throw 'Supervisor v1.7 gate fixture is after legacy dispatch'}
''' + selftest_anchor + "    Write-Host 'KEVIN MAINTENANCE v1.3.16 SELFTEST PASS supervisor_forge_migration=fixed baseline_anchor=atomic mutex_protected=true demand_gate=true rollback=true arbitrary_shell=false authority_expansion=false'\n"
once(selftest_anchor, selftest, 'selftest insertion')

# Strong generator invariants.
required = [
    "version='1.3.16'",
    'migrate_supervisor_forge_demand_gated_v17',
    'Global\\KevinSupervisor',
    'Global\\KevinDesignForge',
    'BenchmarkBaselineBeforeSha',
    'SUPERVISOR IDLE NO_ELIGIBLE_MISSION',
    'IDLE_NO_ELIGIBLE_DEMAND',
    'rollback completed',
    'caller-selected Supervisor/Forge path accepted',
]
for marker in required:
    if marker not in text:
        raise SystemExit('missing generated invariant: ' + marker)

OUT.write_bytes(text.encode('utf-8'))
print('MAINT_V1316_GENERATED', hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
