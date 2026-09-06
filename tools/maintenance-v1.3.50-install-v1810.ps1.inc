function Assert-AutonomyControllerV1810Install([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed-notcontains[string]$p){throw ('autonomy controller v1.8.10 install manifest must not supply '+[string]$p)}}
    if([string]$m.operation-ne'install_autonomy_controller_v1810'){throw 'autonomy controller v1.8.10 install operation mismatch'}
}
function Get-RemoteAutonomyControllerV1810Bytes([string]$RepoPath) {
    if($RepoPath-notin@($SupervisorV1810Source,$SelectorV12Source)){throw 'v1.8.10 autonomy controller source path rejected'}
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.content')
    if($r.ExitCode-ne0){throw 'v1.8.10 autonomy controller source fetch failed'}
    try{return [Convert]::FromBase64String(([string]$r.Output-replace'\s',''))}catch{throw 'v1.8.10 autonomy controller source base64 decode failed'}
}
function Invoke-SupervisorV1810SelfTest([string]$Path) {
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path -SelfTest 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code-ne0-or$out-notmatch'KEVIN SUPERVISOR v1\.8\.10 SELFTEST PASS'){throw 'Supervisor v1.8.10 fixed selftest failed'}
    if($out-notmatch'route_before_turn_charge=true'-or$out-notmatch'owner_value_skills_not_main=true'){throw 'Supervisor v1.8.10 routing selftest markers missing'}
}
function Invoke-SelectorV12SelfTest([string]$Path) {
    $py=Get-Command python -ErrorAction SilentlyContinue
    $CommandArguments=@($Path,'--selftest')
    if(-not$py){$py=Get-Command py -ErrorAction SilentlyContinue;$CommandArguments=@('-3',$Path,'--selftest')}
    if(-not$py){throw 'python runtime unavailable for selector v1.2 selftest'}
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $py.Source @CommandArguments 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code-ne0-or$out-notmatch'KEVIN WORK SELECTOR v1\.2 SELFTEST PASS'){throw 'selector v1.2 fixed selftest failed'}
}
function Install-AutonomyControllerV1810([object]$m) {
    Assert-AutonomyControllerV1810Install $m
    if($env:OS-ne'Windows_NT'){throw 'autonomy controller v1.8.10 install requires Windows'}

    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $selectorDir=Join-Path $Workspace 'ControlPlane'
    $selectorTarget=Join-Path $selectorDir 'kevin-work-selector-v1.2.py'
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    foreach($p in @($supervisorTarget,$baselineTarget)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('v1.8.10 install target missing: '+[IO.Path]::GetFileName($p))}}
    New-Item -ItemType Directory -Force -Path $selectorDir|Out-Null

    $supBefore=Get-Sha $supervisorTarget
    $selectorBefore=Get-Sha $selectorTarget
    try{$base=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json}catch{throw 'Benchmark baseline is not valid JSON'}
    if(-not$base.hashes){throw 'Benchmark baseline hashes missing'}
    $baseSup=([string]$base.hashes.supervisor).ToUpperInvariant()
    $baseForge=([string]$base.hashes.forge).ToUpperInvariant()

    if($supBefore-eq$SupervisorV1810Sha-and$selectorBefore-eq$SelectorV12Sha-and$baseSup-eq$SupervisorV1810Sha-and$baseForge-eq$ForgeV40Sha){
        Parse-PowerShell $supervisorTarget
        Invoke-SupervisorV1810SelfTest $supervisorTarget
        Invoke-SelectorV12SelfTest $selectorTarget
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;supervisor_after=$supBefore;selector_after=$selectorBefore;baseline_supervisor_anchor=$baseSup;history_preserved=$true;work_items_preserved=$true;mission_leases_preserved=$true}
    }

    if($supBefore-ne$SupervisorV1810PredecessorSha){throw ('Supervisor v1.8.10 expected-current mismatch actual='+$supBefore)}
    if($selectorBefore-and$selectorBefore-ne$SelectorV12Sha){throw ('selector v1.2 target contains unexpected identity actual='+$selectorBefore)}
    if($baseSup-ne$SupervisorV1810PredecessorSha){throw ('Benchmark baseline Supervisor anchor mismatch actual='+$baseSup)}
    if($baseForge-ne$ForgeV40Sha){throw ('Benchmark baseline Forge anchor changed actual='+$baseForge)}

    $supBytes=Get-RemoteAutonomyControllerV1810Bytes $SupervisorV1810Source
    $selBytes=Get-RemoteAutonomyControllerV1810Bytes $SelectorV12Source
    $supStage=Join-Path $StageRoot ([string]$m.id+'.supervisor-v1810.ps1')
    $selStage=Join-Path $StageRoot ([string]$m.id+'.selector-v12.py')
    [IO.File]::WriteAllBytes($supStage,$supBytes)
    [IO.File]::WriteAllBytes($selStage,$selBytes)
    if((Get-Sha $supStage)-ne$SupervisorV1810Sha){throw 'Supervisor v1.8.10 source hash mismatch'}
    if((Get-Sha $selStage)-ne$SelectorV12Sha){throw 'selector v1.2 source hash mismatch'}
    Parse-PowerShell $supStage
    Invoke-SupervisorV1810SelfTest $supStage
    Invoke-SelectorV12SelfTest $selStage

    $supText=[IO.File]::ReadAllText($supStage)
    foreach($marker in @('# Kevin Supervisor v1.8.10 Capability-Aware Continuation Controller','ROUTED_TO_SKILL_LAB','owner-value-skills','turn_charged=$false','history_error=$false','kevin-work-selector-v1.2.py',$SelectorV12Sha)){
        if(-not$supText.Contains([string]$marker)){throw ('Supervisor v1.8.10 required marker missing: '+[string]$marker)}
    }
    foreach($bad in @('Invoke-Expression','kevin_shell','Start-Process cmd.exe')){if($supText.Contains($bad)){throw ('Supervisor v1.8.10 forbidden marker: '+$bad)}}

    $baseStageObj=$base|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $baseStageObj.hashes.supervisor=$SupervisorV1810Sha
    if(([string]$baseStageObj.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'staged Benchmark Forge anchor changed'}
    $baseStage=Join-Path $StageRoot ([string]$m.id+'.benchmark-baseline.json')
    [IO.File]::WriteAllText($baseStage,($baseStageObj|ConvertTo-Json -Depth 30),$Utf8)
    $verify=Get-Content -LiteralPath $baseStage -Raw|ConvertFrom-Json
    if(([string]$verify.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV1810Sha){throw 'staged Benchmark Supervisor v1.8.10 anchor mismatch'}
    if(([string]$verify.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'staged Benchmark Forge anchor mismatch'}

    $mutex=New-Object Threading.Mutex($false,'Global\KevinSupervisor')
    $owned=$false
    try{$owned=$mutex.WaitOne(10000)}catch [Threading.AbandonedMutexException]{$owned=$true}
    if(-not$owned){$mutex.Dispose();throw 'Supervisor mutex busy; bounded v1.8.10 install deferred'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $supBackup=Join-Path $backupDir 'kevin-supervisor.ps1'
    $baseBackup=Join-Path $backupDir 'benchmark-baseline.json'
    $selBackup=Join-Path $backupDir 'kevin-work-selector-v1.2.py'
    Copy-Item -LiteralPath $supervisorTarget -Destination $supBackup -Force
    Copy-Item -LiteralPath $baselineTarget -Destination $baseBackup -Force
    $selectorExisted=Test-Path -LiteralPath $selectorTarget -PathType Leaf
    if($selectorExisted){Copy-Item -LiteralPath $selectorTarget -Destination $selBackup -Force}

    try{
        if((Get-Sha $supervisorTarget)-ne$SupervisorV1810PredecessorSha){throw 'Supervisor changed after v1.8.10 staging; aborting TOCTOU'}
        if($selectorExisted-and(Get-Sha $selectorTarget)-ne$SelectorV12Sha){throw 'selector v1.2 changed after staging; aborting TOCTOU'}
        $liveBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$liveBase.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV1810PredecessorSha-or([string]$liveBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'Benchmark anchors changed after staging; aborting TOCTOU'}

        foreach($pair in @(@($supStage,$supervisorTarget),@($selStage,$selectorTarget),@($baseStage,$baselineTarget))){
            $tmp=[string]$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $pair[1] -Force
        }

        if((Get-Sha $supervisorTarget)-ne$SupervisorV1810Sha){throw 'installed Supervisor v1.8.10 hash mismatch'}
        if((Get-Sha $selectorTarget)-ne$SelectorV12Sha){throw 'installed selector v1.2 hash mismatch'}
        $postBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$postBase.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV1810Sha-or([string]$postBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'installed Benchmark anchors mismatch'}

        Parse-PowerShell $supervisorTarget
        Invoke-SupervisorV1810SelfTest $supervisorTarget
        Invoke-SelectorV12SelfTest $selectorTarget
        Assert-Benchmark30
        return [ordered]@{changed=$true;supervisor_before=$supBefore;supervisor_after=(Get-Sha $supervisorTarget);selector_before=$selectorBefore;selector_after=(Get-Sha $selectorTarget);benchmark_supervisor_anchor=$SupervisorV1810Sha;forge_anchor=$ForgeV40Sha;history_preserved=$true;work_items_preserved=$true;mission_leases_preserved=$true;route_before_turn_charge=$true;owner_value_skills_to_skill_lab=$true;public_history_skip_invalid=$true;rollback_available=$true}
    }catch{
        $primary=$_.Exception.Message
        Copy-Item -LiteralPath $supBackup -Destination $supervisorTarget -Force
        Copy-Item -LiteralPath $baseBackup -Destination $baselineTarget -Force
        if($selectorExisted){Copy-Item -LiteralPath $selBackup -Destination $selectorTarget -Force}else{Remove-Item -LiteralPath $selectorTarget -Force -ErrorAction SilentlyContinue}
        try{Assert-Benchmark30}catch{}
        throw ('autonomy controller v1.8.10 rollback completed: '+$primary)
    }finally{
        if($owned){try{$mutex.ReleaseMutex()}catch{}}
        $mutex.Dispose()
    }
}
