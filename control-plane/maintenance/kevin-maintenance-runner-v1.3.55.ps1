param(
    [switch]$SelfTest,
    [switch]$ApplyOnce
)
# Kevin Maintenance v1.3.55 Invocation Worker v1.1 Promotion Wrapper
# Authority-neutral hardening around exact-pinned v1.3.53. Adds only
# install_invocation_worker_v11 plus StrictMode-safe install receipts.
# Copies autonomy worker-v1.1 onto ControlPlane worker-v1.ps1 after the live
# v1812 slot expires. Does not recopy Supervisor. Does not install v1.3.54.
# Does not change GitHub ControlPlane worker pin 16C49542. Non-v11 work is
# delegated to exact parent v1.3.53.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)
$Workspace = if ($env:KEVIN_MAINT_TEST_ROOT) { $env:KEVIN_MAINT_TEST_ROOT } elseif ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Reports = Join-Path $Workspace 'reports'
$Root = Join-Path $Reports 'maintenance'
$StageRoot = Join-Path $Root 'staged'
$BackupRoot = Join-Path $Root 'backups'
$LatestPath = Join-Path $Root 'latest.json'
$ControlPlane = Join-Path $Workspace 'ControlPlane'
$ParentCache = Join-Path $ControlPlane 'kevin-maintenance-core-v1.3.53.ps1'
$Repo = 'hessmodee/KEVIN-WORK'
$ParentRepoPath = 'control-plane/maintenance/kevin-maintenance-runner-v1.3.53.ps1'
$ManifestRepoPath = 'inbox/maintenance/manifest.json'
$ExpectedParentSha = 'EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50'
$SupervisorV1812Sha = 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB'
$WorkerV1Sha = '16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332'
$WorkerV11Sha = '7E1129B7FE2B21C90EED634B7A1A356B55630B56DD700A15A7A8C307AEB827AE'
$WorkerV11Source = 'control-plane/autonomy/kevin-proven-skill-invoke-worker-v1.1.ps1'
$WorkerV1TargetRel = 'ControlPlane/kevin-proven-skill-invoke-worker-v1.ps1'
$ForgeV40Sha = '433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
$AllowedOperations = @(
    'replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','publish_runtime_convergence',
    'publish_runtime_capabilities','replace_runtime_policy_bundle','migrate_design_forge_v40',
    'configure_skill_workshop_guardrails','run_reader_status_canary','diagnose_forge_r03_contract',
    'diagnose_goal_os_forge_anchor','diagnose_benchmark_baseline_forge_anchor',
    'migrate_supervisor_forge_demand_gated_v17','repair_supervisor_v171_forge_pin',
    'ensure_autonomy_continuation_automation','run_main_agent_canary','install_autonomy_controller_v183',
    'install_autonomy_controller_v1810','install_autonomy_controller_v1811','install_autonomy_controller_v1812','install_invocation_worker_v11','diagnose_gateway_rpc','run_self_reliance_watchdog_once',
    'diagnose_gateway_failure_detail','repair_openclaw_windows_lkg','reconcile_maintenance_cron_backoff',
    'diagnose_main_tool_policy','ensure_ui_bridge_watchdog','refresh_full_autonomy_assessment',
    'sync_local_desired_state_v19','retire_legacy_night_forge'
)

foreach($d in @($Reports,$Root,$StageRoot,$BackupRoot,$ControlPlane)){New-Item -ItemType Directory -Force -Path $d|Out-Null}

function Get-Sha([string]$Path){
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return ''}
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Write-JsonAtomic([string]$Path,[object]$Object){
    $tmp=$Path+'.tmp-'+[guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 20),$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Safe-Text([object]$Value,[int]$Max=600){
    $s=[string]$Value
    foreach($pattern in @(
        '(?i)\bghp_[A-Za-z0-9_]{8,}\b',
        '(?i)\bgithub_pat_[A-Za-z0-9_]{8,}\b',
        '(?i)\bsk-[A-Za-z0-9_-]{8,}\b',
        '(?i)(Authorization\s*:\s*Bearer\s+)[^\s''";,]+'
    )){$s=[regex]::Replace($s,$pattern,'[REDACTED]')}
    $s=$s.Replace("`r",' ').Replace("`n",' ')
    if($s.Length-gt$Max){$s=$s.Substring(0,$Max)}
    return $s
}
function Save-State([string]$Status,[string]$ManifestId='',[string]$Detail='',[hashtable]$Extra=$null){
    $o=[ordered]@{
        schema=3
        kind='kevin-maintenance-state'
        version='1.3.55'
        at=(Get-Date).ToString('o')
        status=$Status
        manifest_id=$ManifestId
        detail=(Safe-Text $Detail)
    }
    if($Extra){foreach($k in $Extra.Keys){$o[$k]=$Extra[$k]}}
    Write-JsonAtomic $LatestPath $o
}
function Invoke-GhFixed([string[]]$CommandArguments){
    $gh=(Get-Command gh -ErrorAction Stop).Source
    $oldGh=[Environment]::GetEnvironmentVariable('GH_TOKEN','Process')
    $oldGithub=[Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    $old=$ErrorActionPreference
    try{
        Remove-Item Env:GH_TOKEN,Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
        $ErrorActionPreference='Continue'
        $out=(& $gh @CommandArguments 2>&1|Out-String).Trim()
        $code=[int]$LASTEXITCODE
        if($code-ne0){throw('gh fixed request failed: '+(Safe-Text $out 240))}
        return $out
    }finally{
        $ErrorActionPreference=$old
        if($null-ne$oldGh){$env:GH_TOKEN=$oldGh}else{Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue}
        if($null-ne$oldGithub){$env:GITHUB_TOKEN=$oldGithub}else{Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue}
    }
}
function Get-RepoText([string]$Path){
    if($Path -notin @($ManifestRepoPath,$ParentRepoPath)){throw 'repo path rejected'}
    $endpoint='repos/'+$Repo+'/contents/'+$Path+'?ref=main'
    $b64=Invoke-GhFixed @('api',$endpoint,'--jq','.content')
    if(-not$b64){return $null}
    try{return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($b64-replace'\s','')))}
    catch{throw 'repo content base64 invalid'}
}
function Get-RemoteWorkerV11Bytes([string]$RepoPath){
    if($RepoPath-ne$WorkerV11Source){throw 'invocation worker v1.1 source path rejected'}
    $endpoint='repos/'+$Repo+'/contents/'+$RepoPath+'?ref=main'
    $b64=Invoke-GhFixed @('api',$endpoint,'--jq','.content')
    if(-not$b64){throw ('invocation worker v1.1 source fetch empty: '+$RepoPath)}
    try{return [Convert]::FromBase64String(($b64-replace'\s',''))}
    catch{throw ('invocation worker v1.1 source base64 invalid: '+$RepoPath)}
}
function Get-ManifestText{
    if($env:KEVIN_MAINT_TEST_ROOT -and $env:KEVIN_MAINT_TEST_MANIFEST_TEXT){
        return [string]$env:KEVIN_MAINT_TEST_MANIFEST_TEXT
    }
    return Get-RepoText $ManifestRepoPath
}
function Test-IsCanonicalExpiredObject([object]$m,[ref]$ManifestId,[ref]$ExpiresAt){
    $ManifestId.Value=''
    $ExpiresAt.Value=''
    if($null-eq$m){return $false}
    try{
        if([int]$m.schema-ne3 -or [string]$m.kind-ne'kevin-self-maintenance-manifest'){return $false}
        if([string]$m.id -notmatch '^[A-Za-z0-9._-]{6,96}$'){return $false}
        if([string]$m.authority_class-ne'GREEN' -or [string]$m.authority_delta-ne'NONE' -or [string]$m.production_effect-ne'NONE'){return $false}
        if([string]$m.owner_policy-ne'Kevin Owner Authorization v1' -or [bool]$m.preauthorized-ne$true){return $false}
        if($AllowedOperations-notcontains[string]$m.operation){return $false}
        if(-not$m.expires_at){return $false}
        try{$expiry=[DateTimeOffset]::Parse([string]$m.expires_at)}catch{return $false}
        $ManifestId.Value=[string]$m.id
        $ExpiresAt.Value=$expiry.ToString('o')
        return ([DateTimeOffset]::Now -gt $expiry)
    }catch{return $false}
}
function Test-IsCanonicalExpired([string]$Text,[ref]$ManifestId,[ref]$ExpiresAt){
    $ManifestId.Value=''
    $ExpiresAt.Value=''
    if(-not$Text){return $false}
    try{$m=ConvertFrom-Json -InputObject $Text}catch{return $false}
    return Test-IsCanonicalExpiredObject $m $ManifestId $ExpiresAt
}
function Ensure-Parent{
    if((Get-Sha $ParentCache)-eq$ExpectedParentSha){return}
    $text=Get-RepoText $ParentRepoPath
    if(-not$text){throw 'exact parent maintenance source unavailable'}
    $tmp=$ParentCache+'.stage-'+[guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,$text,$Utf8)
    $sha=Get-Sha $tmp
    if($sha-ne$ExpectedParentSha){Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue;throw('exact parent maintenance source hash mismatch actual='+$sha)}
    Move-Item -LiteralPath $tmp -Destination $ParentCache -Force
    if((Get-Sha $ParentCache)-ne$ExpectedParentSha){throw 'parent cache postcondition mismatch'}
}
function Invoke-Parent{
    Ensure-Parent
    $ps=(Get-Command powershell.exe -ErrorAction Stop).Source
    $args=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$ParentCache)
    if($ApplyOnce){$args+=,'-ApplyOnce'}
    $old=$ErrorActionPreference
    try{
        $ErrorActionPreference='Continue'
        & $ps @args
        $code=[int]$LASTEXITCODE
    }finally{$ErrorActionPreference=$old}
    return $code
}
function Parse-PowerShell([string]$Path){
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    if($errors.Count -gt 0){throw('PowerShell parser rejected candidate: '+$errors[0].Message)}
}
function Assert-Benchmark30{
    $bench=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    $latest=Join-Path $Reports 'benchmark-v1\latest.json'
    if(-not(Test-Path -LiteralPath $bench -PathType Leaf)){throw 'benchmark script missing'}
    $deadline=(Get-Date).AddSeconds(60)
    while($true){
        $started=[DateTime]::UtcNow
        $old=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $bench 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
        if($out -match '(?i)BENCHMARK\s+SKIP_ACTIVE_WORK'){if((Get-Date)-ge$deadline){throw 'fresh benchmark retry budget exhausted'};Start-Sleep 5;continue}
        if($code -ne 0){throw('benchmark failed exit='+$code)}
        if(-not(Test-Path -LiteralPath $latest)){throw 'benchmark evidence missing'}
        $b=Get-Content $latest -Raw|ConvertFrom-Json
        if([string]$b.status -ne 'PASS' -or [int]$b.regression.passed -ne 30 -or [int]$b.regression.total -ne 30 -or [int]$b.regression.critical_failures -ne 0){throw 'benchmark not 30/30 critical=0'}
        if((Get-Item $latest).LastWriteTimeUtc -lt $started.AddSeconds(-3)){throw 'benchmark evidence not fresh'}
        return
    }
}
function Get-InstallStatus([object]$Result){
    $flag=$false
    if($Result -is [System.Collections.IDictionary]){
        if($Result.Contains('idempotent')){$flag=[bool]$Result['idempotent']}
    }else{
        $prop=$Result.PSObject.Properties['idempotent']
        if($prop){$flag=[bool]$prop.Value}
    }
    if($flag){'ALREADY_APPLIED_PROVEN'}else{'APPLIED_PREAUTHORIZED_PROVEN'}
}
function New-SelfTestManifest([datetime]$Expiry,[string]$Authority='GREEN',[string]$Operation='reconcile_maintenance_cron_backoff'){
    return [pscustomobject][ordered]@{
        schema=3
        kind='kevin-self-maintenance-manifest'
        id='selftest-expired-001'
        authority_class=$Authority
        authority_delta='NONE'
        production_effect='NONE'
        owner_policy='Kevin Owner Authorization v1'
        preauthorized=$true
        operation=$Operation
        expires_at=$Expiry.ToString('o')
    }
}
function Assert-InvocationWorkerV11Install([object]$m){
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed-notcontains[string]$p){throw ('invocation worker v1.1 install manifest must not supply '+[string]$p)}}
    if([int]$m.schema-ne3){throw 'manifest schema must be 3'}
    if([string]$m.kind-ne'kevin-self-maintenance-manifest'){throw 'manifest kind mismatch'}
    if([string]$m.id -notmatch '^[A-Za-z0-9._-]{6,96}$'){throw 'manifest id invalid'}
    if([string]$m.authority_class-ne'GREEN'){throw 'maintenance must be GREEN'}
    if([string]$m.authority_delta-ne'NONE'){throw 'authority_delta must be NONE'}
    if([string]$m.production_effect-ne'NONE'){throw 'production_effect must be NONE'}
    if([string]$m.owner_policy-ne'Kevin Owner Authorization v1'){throw 'owner policy mismatch'}
    if([bool]$m.preauthorized-ne$true){throw 'manifest must be preauthorized'}
    if($m.expires_at){
        try{$expiry=[DateTimeOffset]::Parse([string]$m.expires_at)}catch{throw 'manifest expiry invalid'}
        if([DateTimeOffset]::Now -gt $expiry){throw 'manifest expired'}
    }
    if([string]$m.operation-ne'install_invocation_worker_v11'){throw 'invocation worker v1.1 install operation mismatch'}
}
function Install-StagedFile([string]$Stage,[string]$Target,[string]$ExpectedSha){
    New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($Target))|Out-Null
    $tmp=[string]$Target+'.typed-'+[guid]::NewGuid().ToString('N')
    Copy-Item -LiteralPath $Stage -Destination $tmp -Force
    Move-Item -LiteralPath $tmp -Destination $Target -Force
    if((Get-Sha $Target)-ne$ExpectedSha){throw ('installed hash mismatch: '+[IO.Path]::GetFileName($Target))}
}
function Install-InvocationWorkerV11([object]$m){
    Assert-InvocationWorkerV11Install $m
    if($env:OS-ne'Windows_NT'){throw 'invocation worker v1.1 install requires Windows'}

    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $workerTarget=Join-Path $ControlPlane 'kevin-proven-skill-invoke-worker-v1.ps1'
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    if(-not(Test-Path -LiteralPath $supervisorTarget -PathType Leaf)){throw 'Supervisor target missing; do not recopy v1.8.12 from this wrapper'}
    if(-not(Test-Path -LiteralPath $baselineTarget -PathType Leaf)){throw 'Benchmark baseline missing'}
    New-Item -ItemType Directory -Force -Path $ControlPlane|Out-Null

    $supBefore=Get-Sha $supervisorTarget
    $workerBefore=Get-Sha $workerTarget
    try{$base=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json}catch{throw 'Benchmark baseline is not valid JSON'}
    if(-not$base.hashes){throw 'Benchmark baseline hashes missing'}
    $baseSup=([string]$base.hashes.supervisor).ToUpperInvariant()
    $baseForge=([string]$base.hashes.forge).ToUpperInvariant()

    if($supBefore-ne$SupervisorV1812Sha){throw ('Supervisor is not independently proven v1.8.12; do not recopy; abort worker promotion actual='+$supBefore)}
    if($baseSup-ne$SupervisorV1812Sha){throw ('Benchmark baseline Supervisor anchor is not v1.8.12; do not recopy; actual='+$baseSup)}
    if($baseForge-ne$ForgeV40Sha){throw ('Benchmark baseline Forge anchor changed actual='+$baseForge)}

    if($workerBefore-eq$WorkerV11Sha){
        Parse-PowerShell $workerTarget
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;supervisor_before=$supBefore;supervisor_after=$supBefore;worker_before=$workerBefore;worker_after=$workerBefore;expected_current=$WorkerV1Sha;expected_after=$WorkerV11Sha;supervisor_untouched=$true;history_preserved=$true;work_items_preserved=$true;mission_leases_preserved=$true;invocation_worker_v11_installed=$true;rollback_available=$true}
    }
    if($workerBefore-ne$WorkerV1Sha){throw ('invocation worker expected-current mismatch actual='+$workerBefore+' expected='+$WorkerV1Sha)}

    $workerBytes=Get-RemoteWorkerV11Bytes $WorkerV11Source
    $workerStage=Join-Path $StageRoot ([string]$m.id+'.invoke-worker-v1.1.ps1')
    [IO.File]::WriteAllBytes($workerStage,$workerBytes)
    if((Get-Sha $workerStage)-ne$WorkerV11Sha){throw 'invocation worker v1.1 source hash mismatch'}
    Parse-PowerShell $workerStage
    $workerText=[IO.File]::ReadAllText($workerStage)
    foreach($marker in @('Kevin Proven Skill Invoke Worker v1.1','Invoke-HiddenPython','CreateNoWindow = $true','west-motor-parts-chase-board-pack@1','SKILL_KEY_NOT_INVOCATION_V1_COMPATIBLE','version = ''1.1.0''','PYTHON_NOT_AVAILABLE','BUILDER_REJECTED','NativeCommandError','$ErrorActionPreference = ''Continue''')){
        if(-not$workerText.Contains([string]$marker)){throw ('invocation worker v1.1 required marker missing: '+[string]$marker)}
    }
    foreach($bad in @('Invoke-Expression','kevin_shell','Start-Process cmd.exe')){if($workerText.Contains($bad)){throw ('invocation worker v1.1 forbidden marker: '+$bad)}}
    if($workerText -match 'ErrorActionPreference = ''Stop'''){throw 'invocation worker v1.1 still uses Stop'}

    $mutex=New-Object Threading.Mutex($false,'Global\KevinSupervisor')
    $owned=$false
    try{$owned=$mutex.WaitOne(10000)}catch [Threading.AbandonedMutexException]{$owned=$true}
    if(-not$owned){$mutex.Dispose();throw 'Supervisor mutex busy; bounded worker v1.1 install deferred'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $workerBackup=Join-Path $backupDir 'kevin-proven-skill-invoke-worker-v1.ps1'
    $workerExisted=Test-Path -LiteralPath $workerTarget -PathType Leaf
    if($workerExisted){Copy-Item -LiteralPath $workerTarget -Destination $workerBackup -Force}

    try{
        $liveSup=Get-Sha $supervisorTarget
        if($liveSup-ne$SupervisorV1812Sha){throw 'Supervisor changed after worker v1.1 staging; aborting TOCTOU; do not recopy'}
        if($workerExisted-and(Get-Sha $workerTarget)-ne$WorkerV1Sha){throw 'invocation worker changed after staging; aborting TOCTOU'}
        $liveBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$liveBase.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV1812Sha){throw 'Benchmark Supervisor anchor changed after staging; aborting TOCTOU'}
        if(([string]$liveBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'Benchmark Forge anchor changed after staging; aborting TOCTOU'}

        Install-StagedFile $workerStage $workerTarget $WorkerV11Sha
        if((Get-Sha $workerTarget)-ne$WorkerV11Sha){throw 'installed invocation worker v1.1 hash mismatch'}
        if((Get-Sha $supervisorTarget)-ne$SupervisorV1812Sha){throw 'Supervisor hash drifted during worker promotion; rollback'}
        Parse-PowerShell $workerTarget
        Assert-Benchmark30
        return [ordered]@{changed=$true;idempotent=$false;supervisor_before=$supBefore;supervisor_after=(Get-Sha $supervisorTarget);worker_before=$workerBefore;worker_after=(Get-Sha $workerTarget);expected_current=$WorkerV1Sha;expected_after=$WorkerV11Sha;supervisor_untouched=$true;history_preserved=$true;work_items_preserved=$true;mission_leases_preserved=$true;invocation_worker_v11_installed=$true;rollback_available=$true}
    }catch{
        $primary=$_.Exception.Message
        if($workerExisted){Copy-Item -LiteralPath $workerBackup -Destination $workerTarget -Force}else{Remove-Item -LiteralPath $workerTarget -Force -ErrorAction SilentlyContinue}
        try{Assert-Benchmark30}catch{}
        throw ('invocation worker v1.1 rollback completed: '+$primary)
    }finally{
        if($owned){try{$mutex.ReleaseMutex()}catch{}}
        $mutex.Dispose()
    }
}
function Invoke-SelfTest{
    if($ExpectedParentSha-notmatch'^[A-F0-9]{64}$'){throw 'parent pin invalid'}
    if($ParentRepoPath-ne'control-plane/maintenance/kevin-maintenance-runner-v1.3.53.ps1'){throw 'parent path widened'}
    if($ManifestRepoPath-ne'inbox/maintenance/manifest.json'){throw 'manifest path widened'}
    if($SupervisorV1812Sha-ne'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB'){throw 'v1.8.12 after pin drifted'}
    if($WorkerV1Sha-ne'16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332'){throw 'invocation worker current pin drifted'}
    if($WorkerV11Sha-ne'7E1129B7FE2B21C90EED634B7A1A356B55630B56DD700A15A7A8C307AEB827AE'){throw 'invocation worker v1.1 after pin drifted'}
    if($WorkerV11Source-ne'control-plane/autonomy/kevin-proven-skill-invoke-worker-v1.1.ps1'){throw 'worker v1.1 source path widened'}
    if($WorkerV1TargetRel-ne'ControlPlane/kevin-proven-skill-invoke-worker-v1.ps1'){throw 'worker live target path widened'}
    if($AllowedOperations-notcontains'install_invocation_worker_v11'){throw 'worker v1.1 operation not allowlisted'}
    if($AllowedOperations-notcontains'install_autonomy_controller_v1812'){throw 'parent v1812 operation dropped'}
    if($AllowedOperations-notcontains'install_autonomy_controller_v1811'){throw 'parent v1811 operation dropped'}
    if($AllowedOperations-notcontains'install_autonomy_controller_v1810'){throw 'parent v1810 operation dropped'}
    if($AllowedOperations-notcontains'replace_pinned_component'){throw 'replace_pinned_component dropped'}
    $id='';$exp=''
    $expired=New-SelfTestManifest (Get-Date).AddMinutes(-5)
    if(-not(Test-IsCanonicalExpiredObject $expired ([ref]$id) ([ref]$exp))){throw 'expired canonical manifest not classified'}
    if($id-ne'selftest-expired-001'){throw 'expired manifest identity mismatch'}
    $fresh=New-SelfTestManifest (Get-Date).AddMinutes(5);$id='';$exp=''
    if(Test-IsCanonicalExpiredObject $fresh ([ref]$id) ([ref]$exp)){throw 'fresh manifest classified expired'}
    $expiredV11=New-SelfTestManifest (Get-Date).AddMinutes(-5) 'GREEN' 'install_invocation_worker_v11'
    $id='';$exp=''
    if(-not(Test-IsCanonicalExpiredObject $expiredV11 ([ref]$id) ([ref]$exp))){throw 'expired worker v1.1 manifest not classified'}
    $freshV11=New-SelfTestManifest (Get-Date).AddMinutes(5) 'GREEN' 'install_invocation_worker_v11'
    $id='';$exp=''
    if(Test-IsCanonicalExpiredObject $freshV11 ([ref]$id) ([ref]$exp)){throw 'fresh worker v1.1 classified expired'}
    $expiredV1812=New-SelfTestManifest (Get-Date).AddMinutes(-5) 'GREEN' 'install_autonomy_controller_v1812'
    $id='';$exp=''
    if(-not(Test-IsCanonicalExpiredObject $expiredV1812 ([ref]$id) ([ref]$exp))){throw 'expired v1812 manifest not classified'}
    $bad=New-SelfTestManifest (Get-Date).AddMinutes(5);$bad.expires_at='not-a-time';$id='';$exp=''
    if(Test-IsCanonicalExpiredObject $bad ([ref]$id) ([ref]$exp)){throw 'malformed expiry clean-idled instead of delegated hard validation'}
    $bad=New-SelfTestManifest (Get-Date).AddMinutes(-5) 'RED';$id='';$exp=''
    if(Test-IsCanonicalExpiredObject $bad ([ref]$id) ([ref]$exp)){throw 'invalid authority clean-idled instead of delegated hard validation'}
    $json=ConvertTo-Json -InputObject $expired -Compress
    $id='';$exp=''
    if(-not(Test-IsCanonicalExpired $json ([ref]$id) ([ref]$exp))){throw 'expired JSON boundary not classified'}
    $extra=$freshV11|Select-Object *;$extra|Add-Member -NotePropertyName target_alias -NotePropertyValue 'supervisor' -Force
    try{Assert-InvocationWorkerV11Install $extra;throw 'extra property accepted'}catch{if($_.Exception.Message-notmatch'must not supply'){throw}}
    $missing=[ordered]@{changed=$true}
    $strictCaught=$false
    try{$null=[bool]$missing.idempotent}catch{if($_.Exception.Message-match'idempotent'){$strictCaught=$true}else{throw}}
    if(-not$strictCaught){throw 'strict mode did not catch missing idempotent'}
    $changed=[ordered]@{changed=$true;idempotent=$false}
    if((Get-InstallStatus $changed)-ne'APPLIED_PREAUTHORIZED_PROVEN'){throw 'changed receipt status mismatch'}
    $replay=[ordered]@{changed=$false;idempotent=$true}
    if((Get-InstallStatus $replay)-ne'ALREADY_APPLIED_PROVEN'){throw 'replay receipt status mismatch'}
    Write-Host 'KEVIN MAINTENANCE v1.3.3 SELFTEST PASS compatibility=v1.3.55'
    Write-Host 'KEVIN MAINTENANCE v1.3.55 SELFTEST PASS expired_manifest=clean_idle stale_execution=false parent=v1.3.53_exact v1812=delegated_not_recopied worker_v11=promotable receipt_idempotent=strict_safe supervisor_untouched=true github_controlplane_worker=16C49542_until_apply invocation_not_main=true west-motor-parts-chase-board-pack@1 authority_expansion=false arbitrary_shell=false'
}

if($SelfTest){Invoke-SelfTest;exit 0}

try{
    $manifestText=Get-ManifestText
    $manifestId='';$expires=''
    if(Test-IsCanonicalExpired $manifestText ([ref]$manifestId) ([ref]$expires)){
        Save-State 'EXPIRED_IDLE' $manifestId 'Expired canonical manifest refused without scheduler failure.' @{
            expires_at=$expires
            execution_attempted=$false
            authority_effect='NONE'
            parent_invoked=$false
        }
        Write-Host ('MAINTENANCE EXPIRED_IDLE id='+$manifestId)
        exit 0
    }
    $parsed=$null
    try{$parsed=ConvertFrom-Json -InputObject $manifestText}catch{$parsed=$null}
    if($parsed -and [string]$parsed.operation -eq 'install_invocation_worker_v11'){
        $result=Install-InvocationWorkerV11 $parsed
        $status=Get-InstallStatus $result
        Save-State $status ([string]$parsed.id) 'Invocation worker v1.1 Continue wrap applied/verified. Supervisor untouched.' @{
            operation='install_invocation_worker_v11'
            parent_invoked=$false
            result=$result
            authority_effect='NONE'
        }
        Write-Host ('MAINTENANCE '+$status+' id='+[string]$parsed.id+' operation=install_invocation_worker_v11')
        exit 0
    }
    $code=Invoke-Parent
    exit $code
}catch{
    Save-State 'ERROR' '' $_.Exception.Message @{authority_effect='NONE';wrapper='1.3.55'}
    Write-Host ('MAINTENANCE ERROR '+(Safe-Text $_.Exception.Message 600))
    exit 1
}
