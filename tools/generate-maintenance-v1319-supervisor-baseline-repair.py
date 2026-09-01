from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.18.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.19.ps1')
EXPECTED_SRC_SHA256 = '1F64E5A40F8E5708BCA3E797FBD702D411D6F23B34F4289E3BF3578404ED97DF'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA256:
    raise SystemExit(f'v1.3.18 source identity mismatch: {actual}')
text = raw.decode('utf-8')


def replace_once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)

replace_once("version='1.3.18'", "version='1.3.19'", 'state version')

start = text.find('function Repair-SupervisorV171ForgePin([object]$m) {')
end = text.find('function Restart-UiBridge([object]$m) {', start)
if start < 0 or end < 0 or end <= start:
    raise SystemExit('Supervisor v1.7.1 repair function boundaries not found')

new_func = r'''function Repair-SupervisorV171ForgePin([object]$m) {
    Assert-SupervisorV171ForgePinRepair $m
    if($env:OS -ne 'Windows_NT'){throw 'Supervisor v1.7.1 repair requires Windows'}
    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $forgeTarget=(Get-AliasSpec 'design_forge_runner').Target
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    foreach($p in @($supervisorTarget,$forgeTarget,$baselineTarget)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('Supervisor v1.7.1 coordinated repair target missing: '+[IO.Path]::GetFileName($p))}}

    $before=Get-Sha $supervisorTarget
    $forge=Get-Sha $forgeTarget
    $baselineBefore=Get-Sha $baselineTarget
    if($forge -ne $ForgeV40Sha){throw ('Forge v4 expected-current mismatch actual='+$forge)}
    try{$baselineObj=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json}catch{throw 'Benchmark baseline is not valid JSON'}
    if(-not$baselineObj.hashes){throw 'Benchmark baseline hashes missing'}
    $baselineSup=([string]$baselineObj.hashes.supervisor).ToUpperInvariant()
    $baselineForge=([string]$baselineObj.hashes.forge).ToUpperInvariant()
    if($baselineForge -ne $ForgeV40Sha){throw ('Benchmark baseline Forge anchor mismatch actual='+$baselineForge)}

    if($before -eq $SupervisorV171Sha -and $baselineSup -eq $SupervisorV171Sha){
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;supervisor_after=$before;baseline_supervisor_anchor=$baselineSup;forge_pin=$ForgeV40Sha}
    }
    if($before -ne $SupervisorV17Sha){throw ('Supervisor v1.7 expected-current mismatch actual='+$before)}
    if($baselineSup -ne $SupervisorV17Sha){throw ('Benchmark baseline Supervisor anchor expected v1.7 actual='+$baselineSup)}

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

    $baselineStageObj=$baselineObj|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $baselineStageObj.hashes.supervisor=$SupervisorV171Sha
    if(([string]$baselineStageObj.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'staged Benchmark baseline Forge anchor changed unexpectedly'}
    $baselineStage=Join-Path $StageRoot ([string]$m.id+'.benchmark-baseline.json')
    [IO.File]::WriteAllText($baselineStage,($baselineStageObj|ConvertTo-Json -Depth 30),$Utf8)
    try{$verifyBaseline=Get-Content -LiteralPath $baselineStage -Raw|ConvertFrom-Json}catch{throw 'staged Benchmark baseline invalid JSON'}
    if(([string]$verifyBaseline.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV171Sha){throw 'staged Benchmark baseline Supervisor anchor mismatch'}
    if(([string]$verifyBaseline.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'staged Benchmark baseline Forge anchor mismatch'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir|Out-Null
    $supervisorBackup=Join-Path $backupDir 'kevin-supervisor.ps1'
    $baselineBackup=Join-Path $backupDir 'benchmark-baseline.json'
    Copy-Item -LiteralPath $supervisorTarget -Destination $supervisorBackup -Force
    Copy-Item -LiteralPath $baselineTarget -Destination $baselineBackup -Force
    $mutex=$null;$owned=$false
    try {
        $mutex=New-Object -TypeName System.Threading.Mutex -ArgumentList $false,'Global\KevinSupervisor'
        try{$owned=$mutex.WaitOne(60000)}catch [System.Threading.AbandonedMutexException]{$owned=$true}
        if(-not$owned){throw 'Supervisor did not become idle within 60 seconds'}
        if((Get-Sha $supervisorTarget) -ne $SupervisorV17Sha){throw 'Supervisor changed after staging; aborting TOCTOU'}
        if((Get-Sha $forgeTarget) -ne $ForgeV40Sha){throw 'Forge changed after staging; aborting TOCTOU'}
        if((Get-Sha $baselineTarget) -ne $baselineBefore){throw 'Benchmark baseline changed after staging; aborting TOCTOU'}

        foreach($pair in @(@($stage,$supervisorTarget),@($baselineStage,$baselineTarget))){
            $tmp=$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $pair[1] -Force
        }
        if((Get-Sha $supervisorTarget) -ne $SupervisorV171Sha){throw 'installed Supervisor v1.7.1 hash mismatch'}
        Parse-PowerShell $supervisorTarget
        $installedBaseline=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$installedBaseline.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV171Sha){throw 'installed Benchmark baseline Supervisor anchor mismatch'}
        if(([string]$installedBaseline.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'installed Benchmark baseline Forge anchor mismatch'}
        Assert-Benchmark30
        return [ordered]@{changed=$true;supervisor_before=$before;supervisor_after=(Get-Sha $supervisorTarget);baseline_before=$baselineBefore;baseline_after=(Get-Sha $baselineTarget);baseline_supervisor_anchor=$SupervisorV171Sha;forge_pin=$ForgeV40Sha;demand_gate_preserved=$true;rollback_available=$true}
    } catch {
        if(Test-Path -LiteralPath $supervisorBackup -PathType Leaf){Copy-Item -LiteralPath $supervisorBackup -Destination $supervisorTarget -Force}
        if(Test-Path -LiteralPath $baselineBackup -PathType Leaf){Copy-Item -LiteralPath $baselineBackup -Destination $baselineTarget -Force}
        try{Assert-Benchmark30}catch{}
        throw ('Supervisor v1.7.1 coordinated repair rollback completed: '+$_.Exception.Message)
    } finally {
        if($owned -and $mutex){try{$mutex.ReleaseMutex()}catch{}}
        if($mutex){$mutex.Dispose()}
    }
}
'''
text = text[:start] + new_func + text[end:]

old_marker = "    Write-Host 'KEVIN MAINTENANCE v1.3.18 SELFTEST PASS supervisor_v171_forge_pin=fixed demand_gate_preserved=true rollback=true operation_parity=true arbitrary_shell=false authority_expansion=false'\n"
new_marker = old_marker + "    Write-Host 'KEVIN MAINTENANCE v1.3.19 SELFTEST PASS supervisor_baseline_anchor=atomic forge_v4_anchor=preserved rollback=true operation_parity=true arbitrary_shell=false authority_expansion=false'\n"
replace_once(old_marker, new_marker, 'v1.3.19 selftest marker')

OUT.write_text(text, encoding='utf-8', newline='')
sha = hashlib.sha256(OUT.read_bytes()).hexdigest().upper()
print('MAINT_V1319_GENERATED sha256=' + sha)
