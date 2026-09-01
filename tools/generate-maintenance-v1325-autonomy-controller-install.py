from pathlib import Path
import hashlib

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.24.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.25.ps1')
EXPECTED='B5E053DFE39597DC08C58BBAD571F8590D6F10C12DA0F25363FD42723CFC2A06'
SUP_SHA='9EB3493A91B3B91AFCE05985D368849A98899C2F592C1B12D6EF94471190EE2C'
SEL_SHA='9DF1F770E8855232758AC275FA2D3A82C6D484099B5B2D2185A999ACDE185DE4'
raw=SRC.read_bytes();actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED: raise SystemExit(f'v1.3.24 identity mismatch {actual}')
text=raw.decode('utf-8')

def once(old,new,label):
    global text
    n=text.count(old)
    if n!=1: raise SystemExit(f'{label} anchor count={n}')
    text=text.replace(old,new,1)

once("version='1.3.24'","version='1.3.25'",'state version')
anchor="$BenchmarkBaselineBeforeSha = 'B4F2B01ADBFC946754A987797F94D3E50C51300111DE4003546825D11ED649A1'"
insert=anchor+f"\n$SupervisorV182Sha = '{SUP_SHA}'\n$SelectorV11Sha = '{SEL_SHA}'\n$SupervisorV182Source = 'control-plane/autonomy/kevin-supervisor-v1.8.2.ps1'\n$SelectorV11Source = 'control-plane/autonomy/kevin-work-selector-v1.1.py'"
once(anchor,insert,'identity constants')
old="'ensure_autonomy_continuation_automation','run_main_agent_canary') -contains [string]$m.operation)"
new="'ensure_autonomy_continuation_automation','run_main_agent_canary','install_autonomy_controller_v182') -contains [string]$m.operation)"
once(old,new,'allowlist')

func=r'''
function Assert-AutonomyControllerV182Install([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('autonomy controller install manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'install_autonomy_controller_v182'){throw 'autonomy controller install operation mismatch'}
}
function Get-RemoteAutonomyControllerBytes([string]$RepoPath) {
    if($RepoPath -notin @($SupervisorV182Source,$SelectorV11Source)){throw 'autonomy controller source path rejected'}
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.content')
    if($r.ExitCode -ne 0){throw 'autonomy controller source fetch failed'}
    try{return [Convert]::FromBase64String(([string]$r.Output -replace '\s',''))}catch{throw 'autonomy controller source base64 decode failed'}
}
function Invoke-FixedPythonSelfTest([string]$Path) {
    $py=Get-Command python -ErrorAction SilentlyContinue
    $args=@($Path,'--selftest')
    if(-not$py){$py=Get-Command py -ErrorAction SilentlyContinue;$args=@('-3',$Path,'--selftest')}
    if(-not$py){throw 'python runtime unavailable for selector selftest'}
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $py.Source @args 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code-ne0 -or $out -notmatch 'KEVIN WORK SELECTOR v1.1 SELFTEST PASS'){throw 'selector fixed selftest failed'}
}
function Install-AutonomyControllerV182([object]$m) {
    Assert-AutonomyControllerV182Install $m
    if($env:OS -ne 'Windows_NT'){throw 'autonomy controller install requires Windows'}
    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $selectorDir=Join-Path $Workspace 'ControlPlane'
    $selectorTarget=Join-Path $selectorDir 'kevin-work-selector-v1.1.py'
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    foreach($p in @($supervisorTarget,$baselineTarget)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('autonomy controller install target missing: '+[IO.Path]::GetFileName($p))}}
    New-Item -ItemType Directory -Force -Path $selectorDir|Out-Null
    $supBefore=Get-Sha $supervisorTarget
    $selectorBefore=Get-Sha $selectorTarget
    try{$base=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json}catch{throw 'Benchmark baseline is not valid JSON'}
    if(-not$base.hashes){throw 'Benchmark baseline hashes missing'}
    $baseSup=([string]$base.hashes.supervisor).ToUpperInvariant();$baseForge=([string]$base.hashes.forge).ToUpperInvariant()
    if($supBefore -eq $SupervisorV182Sha -and $selectorBefore -eq $SelectorV11Sha -and $baseSup -eq $SupervisorV182Sha -and $baseForge -eq $ForgeV40Sha){
        Parse-PowerShell $supervisorTarget; & $supervisorTarget -SelfTest; if($LASTEXITCODE-ne0){throw 'installed Supervisor v1.8.2 selftest failed'}
        Invoke-FixedPythonSelfTest $selectorTarget;Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;supervisor_after=$supBefore;selector_after=$selectorBefore;baseline_supervisor_anchor=$baseSup;forge_anchor=$baseForge}
    }
    if($supBefore -ne $SupervisorV171Sha){throw ('Supervisor expected-current mismatch actual='+$supBefore)}
    if($selectorBefore -and $selectorBefore -ne $SelectorV11Sha){throw ('selector target contains unexpected identity actual='+$selectorBefore)}
    if($baseSup -ne $SupervisorV171Sha){throw ('Benchmark baseline Supervisor anchor mismatch actual='+$baseSup)}
    if($baseForge -ne $ForgeV40Sha){throw ('Benchmark baseline Forge anchor changed actual='+$baseForge)}

    $supBytes=Get-RemoteAutonomyControllerBytes $SupervisorV182Source
    $selBytes=Get-RemoteAutonomyControllerBytes $SelectorV11Source
    $supStage=Join-Path $StageRoot ([string]$m.id+'.supervisor-v182.ps1')
    $selStage=Join-Path $StageRoot ([string]$m.id+'.selector-v11.py')
    [IO.File]::WriteAllBytes($supStage,$supBytes);[IO.File]::WriteAllBytes($selStage,$selBytes)
    if((Get-Sha $supStage)-ne$SupervisorV182Sha){throw 'Supervisor v1.8.2 source hash mismatch'}
    if((Get-Sha $selStage)-ne$SelectorV11Sha){throw 'selector v1.1 source hash mismatch'}
    Parse-PowerShell $supStage
    & $supStage -SelfTest;if($LASTEXITCODE-ne0){throw 'staged Supervisor v1.8.2 selftest failed'}
    Invoke-FixedPythonSelfTest $selStage
    $supText=[IO.File]::ReadAllText($supStage)
    foreach($marker in @('Governed Autonomy Continuation Controller','IDLE_NO_ELIGIBLE_DEMAND','COOLDOWN_BUDGET_EXHAUSTED','AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF')){if(-not$supText.Contains($marker)){throw ('Supervisor v1.8.2 marker missing: '+$marker)}}
    foreach($bad in @('Invoke-Expression','kevin_shell','Start-Process cmd.exe')){if($supText.Contains($bad)){throw ('Supervisor v1.8.2 forbidden marker: '+$bad)}}

    $baseStageObj=$base|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $baseStageObj.hashes.supervisor=$SupervisorV182Sha
    if(([string]$baseStageObj.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'staged Benchmark Forge anchor changed'}
    $baseStage=Join-Path $StageRoot ([string]$m.id+'.benchmark-baseline.json')
    [IO.File]::WriteAllText($baseStage,($baseStageObj|ConvertTo-Json -Depth 30),$Utf8)
    $verify=Get-Content -LiteralPath $baseStage -Raw|ConvertFrom-Json
    if(([string]$verify.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV182Sha){throw 'staged Benchmark Supervisor anchor mismatch'}
    if(([string]$verify.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'staged Benchmark Forge anchor mismatch'}

    $mutex=New-Object Threading.Mutex($false,'Global\KevinSupervisor');$owned=$false
    try{$owned=$mutex.WaitOne(10000)}catch [Threading.AbandonedMutexException]{$owned=$true}
    if(-not$owned){$mutex.Dispose();throw 'Supervisor mutex busy; bounded install deferred'}
    $backupDir=Join-Path $BackupRoot ([string]$m.id);New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $supBackup=Join-Path $backupDir 'kevin-supervisor.ps1';$baseBackup=Join-Path $backupDir 'benchmark-baseline.json';$selBackup=Join-Path $backupDir 'kevin-work-selector-v1.1.py'
    Copy-Item -LiteralPath $supervisorTarget -Destination $supBackup -Force;Copy-Item -LiteralPath $baselineTarget -Destination $baseBackup -Force
    $selectorExisted=Test-Path -LiteralPath $selectorTarget -PathType Leaf;if($selectorExisted){Copy-Item -LiteralPath $selectorTarget -Destination $selBackup -Force}
    try{
        if((Get-Sha $supervisorTarget)-ne$SupervisorV171Sha){throw 'Supervisor changed after staging; aborting TOCTOU'}
        if($selectorExisted -and (Get-Sha $selectorTarget)-ne$SelectorV11Sha){throw 'selector changed after staging; aborting TOCTOU'}
        $liveBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$liveBase.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV171Sha -or ([string]$liveBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'Benchmark anchors changed after staging; aborting TOCTOU'}
        foreach($pair in @(@($supStage,$supervisorTarget),@($selStage,$selectorTarget),@($baseStage,$baselineTarget))){$tmp=[string]$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N');Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force;Move-Item -LiteralPath $tmp -Destination $pair[1] -Force}
        if((Get-Sha $supervisorTarget)-ne$SupervisorV182Sha){throw 'installed Supervisor v1.8.2 hash mismatch'}
        if((Get-Sha $selectorTarget)-ne$SelectorV11Sha){throw 'installed selector v1.1 hash mismatch'}
        $postBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$postBase.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV182Sha -or ([string]$postBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'installed Benchmark anchors mismatch'}
        Parse-PowerShell $supervisorTarget;& $supervisorTarget -SelfTest;if($LASTEXITCODE-ne0){throw 'installed Supervisor v1.8.2 selftest failed'}
        Invoke-FixedPythonSelfTest $selectorTarget;Assert-Benchmark30
        return [ordered]@{changed=$true;supervisor_before=$supBefore;supervisor_after=(Get-Sha $supervisorTarget);selector_before=$selectorBefore;selector_after=(Get-Sha $selectorTarget);benchmark_supervisor_anchor=$SupervisorV182Sha;forge_anchor=$ForgeV40Sha;selector_first=$true;default_gateway_agent=$true;anti_spin=$true;rollback_available=$true}
    }catch{
        Copy-Item -LiteralPath $supBackup -Destination $supervisorTarget -Force;Copy-Item -LiteralPath $baseBackup -Destination $baselineTarget -Force
        if($selectorExisted){Copy-Item -LiteralPath $selBackup -Destination $selectorTarget -Force}else{Remove-Item -LiteralPath $selectorTarget -Force -ErrorAction SilentlyContinue}
        try{Assert-Benchmark30}catch{}
        throw ('autonomy controller rollback completed: '+$_.Exception.Message)
    }finally{if($owned){try{$mutex.ReleaseMutex()}catch{}};$mutex.Dispose()}
}

'''
anchor='function Assert-MainAgentCanary([object]$m) {'
once(anchor,func+anchor,'installer functions')

once("        'run_main_agent_canary' { Assert-MainAgentCanary $m }","        'run_main_agent_canary' { Assert-MainAgentCanary $m }\n        'install_autonomy_controller_v182' { Assert-AutonomyControllerV182Install $m }",'assert dispatch')
once("            'run_main_agent_canary' { Run-MainAgentCanary; break }","            'run_main_agent_canary' { Run-MainAgentCanary; break }\n            'install_autonomy_controller_v182' { Install-AutonomyControllerV182 $m; break }",'execute dispatch')
once("            'run_main_agent_canary' {'main_agent_canary_failure'}","            'run_main_agent_canary' {'main_agent_canary_failure'}\n            'install_autonomy_controller_v182' {'autonomy_controller_v182_install_failure'}",'failure dispatch')

marker="    Write-Host 'KEVIN MAINTENANCE v1.3.24 SELFTEST PASS default_agent_canary=fixed failure_receipt=true raw_text_published=false arbitrary_shell=false authority_expansion=false'"
extra=r'''    $aci=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$aci.operation='install_autonomy_controller_v182';Assert-Common $aci;Assert-AutonomyControllerV182Install $aci
    $aciBad=$aci|ConvertTo-Json -Depth 10|ConvertFrom-Json;$aciBad|Add-Member -NotePropertyName source_path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-AutonomyControllerV182Install $aciBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected autonomy controller path accepted'}
'''+marker+"\n    Write-Host 'KEVIN MAINTENANCE v1.3.25 SELFTEST PASS autonomy_controller_install=fixed supervisor_v182=true selector_v11=true baseline_anchor=atomic rollback=true arbitrary_shell=false authority_expansion=false'"
once(marker,extra,'selftest extension')

OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1325_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
