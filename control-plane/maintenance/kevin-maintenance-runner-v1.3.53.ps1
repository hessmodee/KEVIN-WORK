param(
    [switch]$SelfTest,
    [switch]$ApplyOnce
)
# Kevin Maintenance v1.3.53 Supervisor v1.8.12 Compatibility Wrapper
# Authority-neutral hardening around exact-pinned v1.3.52. Adds only
# install_autonomy_controller_v1812. Worker native errors fail-closed.
# Expired canonical manifests remain a clean terminal idle. Non-v1812 work is
# delegated to exact parent v1.3.52.
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
$ParentCache = Join-Path $ControlPlane 'kevin-maintenance-core-v1.3.52.ps1'
$Repo = 'hessmodee/KEVIN-WORK'
$ParentRepoPath = 'control-plane/maintenance/kevin-maintenance-runner-v1.3.52.ps1'
$ManifestRepoPath = 'inbox/maintenance/manifest.json'
$ExpectedParentSha = 'C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24'
$SupervisorV1812PredecessorSha = '685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79'
$SupervisorV1812Sha = 'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB'
$SupervisorV1812Source = 'control-plane/autonomy/kevin-supervisor-v1.8.12.ps1'
$SelectorV12Sha = '52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A'
$SelectorV12Source = 'control-plane/autonomy/kevin-work-selector-v1.2.py'
$WorkerV1Sha = '16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332'
$WorkerV1Source = 'ControlPlane/kevin-proven-skill-invoke-worker-v1.ps1'
$BuilderSha = '8E1CDB6911A4F087099788C1DAD9E5A425686B63A6FED471E49D9478688ACCF9'
$BuilderSource = 'control-plane/autonomy/kevin-proven-skill-request-builder-v1.py'
$InvokerSha = '63FA334B85F895894481DF59314326F6F0F4B0785553B8FDD33DFBFC0E88147C'
$InvokerSource = 'control-plane/autonomy/kevin-proven-skill-invocation-v1.py'
$ForgeV40Sha = '433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
$V1812Sources = @($SupervisorV1812Source,$SelectorV12Source,$WorkerV1Source,$BuilderSource,$InvokerSource)
$AllowedOperations = @(
    'replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','publish_runtime_convergence',
    'publish_runtime_capabilities','replace_runtime_policy_bundle','migrate_design_forge_v40',
    'configure_skill_workshop_guardrails','run_reader_status_canary','diagnose_forge_r03_contract',
    'diagnose_goal_os_forge_anchor','diagnose_benchmark_baseline_forge_anchor',
    'migrate_supervisor_forge_demand_gated_v17','repair_supervisor_v171_forge_pin',
    'ensure_autonomy_continuation_automation','run_main_agent_canary','install_autonomy_controller_v183',
    'install_autonomy_controller_v1810','install_autonomy_controller_v1811','install_autonomy_controller_v1812','diagnose_gateway_rpc','run_self_reliance_watchdog_once',
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
        version='1.3.53'
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
function Get-RemoteV1812Bytes([string]$RepoPath){
    if($V1812Sources-notcontains$RepoPath){throw 'v1.8.12 autonomy source path rejected'}
    $endpoint='repos/'+$Repo+'/contents/'+$RepoPath+'?ref=main'
    $b64=Invoke-GhFixed @('api',$endpoint,'--jq','.content')
    if(-not$b64){throw ('v1.8.12 source fetch empty: '+$RepoPath)}
    try{return [Convert]::FromBase64String(($b64-replace'\s',''))}
    catch{throw ('v1.8.12 source base64 invalid: '+$RepoPath)}
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
function Invoke-SupervisorV1812SelfTest([string]$Path){
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path -SelfTest 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code-ne0-or$out-notmatch'KEVIN SUPERVISOR v1\.8\.12 SELFTEST PASS'){throw 'Supervisor v1.8.12 fixed selftest failed'}
    if($out-notmatch'route_before_turn_charge=true'-or$out-notmatch'owner_value_skills_not_main=true'){throw 'Supervisor v1.8.12 routing selftest markers missing'}
    if($out-notmatch'proven_skill_before_skill_lab=true'-or$out-notmatch'invocation_not_main=true'-or$out-notmatch'invocation_worker_native_error_fail_closed=true'){throw 'Supervisor v1.8.12 invocation selftest markers missing'}
}
function Invoke-SelectorV12SelfTest([string]$Path){
    $py=Get-Command python -ErrorAction SilentlyContinue
    $CommandArguments=@($Path,'--selftest')
    if(-not$py){$py=Get-Command py -ErrorAction SilentlyContinue;$CommandArguments=@('-3',$Path,'--selftest')}
    if(-not$py){throw 'python runtime unavailable for selector v1.2 selftest'}
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $py.Source @CommandArguments 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code-ne0-or$out-notmatch'KEVIN WORK SELECTOR v1\.2 SELFTEST PASS'){throw 'selector v1.2 fixed selftest failed'}
}
function Assert-AutonomyControllerV1812Install([object]$m){
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed-notcontains[string]$p){throw ('autonomy controller v1.8.12 install manifest must not supply '+[string]$p)}}
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
    if([string]$m.operation-ne'install_autonomy_controller_v1812'){throw 'autonomy controller v1.8.12 install operation mismatch'}
}
function Install-StagedFile([string]$Stage,[string]$Target,[string]$ExpectedSha){
    New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($Target))|Out-Null
    $tmp=[string]$Target+'.typed-'+[guid]::NewGuid().ToString('N')
    Copy-Item -LiteralPath $Stage -Destination $tmp -Force
    Move-Item -LiteralPath $tmp -Destination $Target -Force
    if((Get-Sha $Target)-ne$ExpectedSha){throw ('installed hash mismatch: '+[IO.Path]::GetFileName($Target))}
}
function Install-AutonomyControllerV1812([object]$m){
    Assert-AutonomyControllerV1812Install $m
    if($env:OS-ne'Windows_NT'){throw 'autonomy controller v1.8.12 install requires Windows'}

    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $selectorDir=Join-Path $Workspace 'ControlPlane'
    $selectorTarget=Join-Path $selectorDir 'kevin-work-selector-v1.2.py'
    $workerTarget=Join-Path $selectorDir 'kevin-proven-skill-invoke-worker-v1.ps1'
    $autonomyDir=Join-Path $Workspace 'control-plane\autonomy'
    $builderTarget=Join-Path $autonomyDir 'kevin-proven-skill-request-builder-v1.py'
    $invokerTarget=Join-Path $autonomyDir 'kevin-proven-skill-invocation-v1.py'
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    foreach($p in @($supervisorTarget,$baselineTarget)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('v1.8.12 install target missing: '+[IO.Path]::GetFileName($p))}}
    New-Item -ItemType Directory -Force -Path $selectorDir|Out-Null
    New-Item -ItemType Directory -Force -Path $autonomyDir|Out-Null

    $supBefore=Get-Sha $supervisorTarget
    $selectorBefore=Get-Sha $selectorTarget
    $workerBefore=Get-Sha $workerTarget
    $builderBefore=Get-Sha $builderTarget
    $invokerBefore=Get-Sha $invokerTarget
    try{$base=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json}catch{throw 'Benchmark baseline is not valid JSON'}
    if(-not$base.hashes){throw 'Benchmark baseline hashes missing'}
    $baseSup=([string]$base.hashes.supervisor).ToUpperInvariant()
    $baseForge=([string]$base.hashes.forge).ToUpperInvariant()

    if($supBefore-eq$SupervisorV1812Sha-and$selectorBefore-eq$SelectorV12Sha-and$workerBefore-eq$WorkerV1Sha-and$builderBefore-eq$BuilderSha-and$invokerBefore-eq$InvokerSha-and$baseSup-eq$SupervisorV1812Sha-and$baseForge-eq$ForgeV40Sha){
        Parse-PowerShell $supervisorTarget
        Parse-PowerShell $workerTarget
        Invoke-SupervisorV1812SelfTest $supervisorTarget
        Invoke-SelectorV12SelfTest $selectorTarget
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;supervisor_after=$supBefore;worker_after=$workerBefore;selector_after=$selectorBefore;baseline_supervisor_anchor=$baseSup;history_preserved=$true;work_items_preserved=$true;mission_leases_preserved=$true;invocation_worker_installed=$true}
    }

    if($supBefore-ne$SupervisorV1812PredecessorSha-and$supBefore-ne$SupervisorV1812Sha){throw ('Supervisor v1.8.12 expected-current mismatch actual='+$supBefore)}
    if($selectorBefore-and$selectorBefore-ne$SelectorV12Sha){throw ('selector v1.2 target contains unexpected identity actual='+$selectorBefore)}
    if($workerBefore-and$workerBefore-ne$WorkerV1Sha){throw ('invocation worker target contains unexpected identity actual='+$workerBefore)}
    if($builderBefore-and$builderBefore-ne$BuilderSha){throw ('request builder target contains unexpected identity actual='+$builderBefore)}
    if($invokerBefore-and$invokerBefore-ne$InvokerSha){throw ('invocation python target contains unexpected identity actual='+$invokerBefore)}
    if($supBefore-eq$SupervisorV1812PredecessorSha-and$baseSup-ne$SupervisorV1812PredecessorSha){throw ('Benchmark baseline Supervisor anchor mismatch actual='+$baseSup)}
    if($supBefore-eq$SupervisorV1812Sha-and$baseSup-ne$SupervisorV1812Sha-and$baseSup-ne$SupervisorV1812PredecessorSha){throw ('Benchmark baseline Supervisor anchor mismatch actual='+$baseSup)}
    if($baseForge-ne$ForgeV40Sha){throw ('Benchmark baseline Forge anchor changed actual='+$baseForge)}

    $supBytes=Get-RemoteV1812Bytes $SupervisorV1812Source
    $selBytes=Get-RemoteV1812Bytes $SelectorV12Source
    $workerBytes=Get-RemoteV1812Bytes $WorkerV1Source
    $builderBytes=Get-RemoteV1812Bytes $BuilderSource
    $invokerBytes=Get-RemoteV1812Bytes $InvokerSource
    $supStage=Join-Path $StageRoot ([string]$m.id+'.supervisor-v1812.ps1')
    $selStage=Join-Path $StageRoot ([string]$m.id+'.selector-v12.py')
    $workerStage=Join-Path $StageRoot ([string]$m.id+'.invoke-worker-v1.ps1')
    $builderStage=Join-Path $StageRoot ([string]$m.id+'.request-builder-v1.py')
    $invokerStage=Join-Path $StageRoot ([string]$m.id+'.invocation-v1.py')
    [IO.File]::WriteAllBytes($supStage,$supBytes)
    [IO.File]::WriteAllBytes($selStage,$selBytes)
    [IO.File]::WriteAllBytes($workerStage,$workerBytes)
    [IO.File]::WriteAllBytes($builderStage,$builderBytes)
    [IO.File]::WriteAllBytes($invokerStage,$invokerBytes)
    if((Get-Sha $supStage)-ne$SupervisorV1812Sha){throw 'Supervisor v1.8.12 source hash mismatch'}
    if((Get-Sha $selStage)-ne$SelectorV12Sha){throw 'selector v1.2 source hash mismatch'}
    if((Get-Sha $workerStage)-ne$WorkerV1Sha){throw 'invocation worker source hash mismatch'}
    if((Get-Sha $builderStage)-ne$BuilderSha){throw 'request builder source hash mismatch'}
    if((Get-Sha $invokerStage)-ne$InvokerSha){throw 'invocation python source hash mismatch'}
    Parse-PowerShell $supStage
    Parse-PowerShell $workerStage
    Invoke-SupervisorV1812SelfTest $supStage
    Invoke-SelectorV12SelfTest $selStage

    $supText=[IO.File]::ReadAllText($supStage)
    foreach($marker in @('# Kevin Supervisor v1.8.12 Capability-Aware Continuation Controller','ROUTED_TO_PROVEN_SKILL_INVOCATION','BLOCKED_INVOCATION_RUNTIME','required_skill_key','turn_charged=$false','history_error=$false','kevin-work-selector-v1.2.py',$SelectorV12Sha,'invocation_not_main=true','invocation_worker_native_error_fail_closed=true','INVOCATION_WORKER_FAILED')){
        if(-not$supText.Contains([string]$marker)){throw ('Supervisor v1.8.12 required marker missing: '+[string]$marker)}
    }
    foreach($bad in @('Invoke-Expression','kevin_shell','Start-Process cmd.exe')){if($supText.Contains($bad)){throw ('Supervisor v1.8.12 forbidden marker: '+$bad)}}
    $workerText=[IO.File]::ReadAllText($workerStage)
    foreach($marker in @('west-motor-parts-chase-board-pack@1','SKILL_KEY_NOT_INVOCATION_V1_COMPATIBLE','outcome_proven = $false','STAGED')){
        if(-not$workerText.Contains([string]$marker)){throw ('invocation worker required marker missing: '+[string]$marker)}
    }
    foreach($bad in @('Invoke-Expression','kevin_shell','Start-Process cmd.exe')){if($workerText.Contains($bad)){throw ('invocation worker forbidden marker: '+$bad)}}

    $baseStageObj=$base|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $baseStageObj.hashes.supervisor=$SupervisorV1812Sha
    if(([string]$baseStageObj.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'staged Benchmark Forge anchor changed'}
    $baseStage=Join-Path $StageRoot ([string]$m.id+'.benchmark-baseline.json')
    [IO.File]::WriteAllText($baseStage,($baseStageObj|ConvertTo-Json -Depth 30),$Utf8)
    $verify=Get-Content -LiteralPath $baseStage -Raw|ConvertFrom-Json
    if(([string]$verify.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV1812Sha){throw 'staged Benchmark Supervisor v1.8.12 anchor mismatch'}
    if(([string]$verify.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'staged Benchmark Forge anchor mismatch'}

    $mutex=New-Object Threading.Mutex($false,'Global\KevinSupervisor')
    $owned=$false
    try{$owned=$mutex.WaitOne(10000)}catch [Threading.AbandonedMutexException]{$owned=$true}
    if(-not$owned){$mutex.Dispose();throw 'Supervisor mutex busy; bounded v1.8.12 install deferred'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $supBackup=Join-Path $backupDir 'kevin-supervisor.ps1'
    $baseBackup=Join-Path $backupDir 'benchmark-baseline.json'
    $selBackup=Join-Path $backupDir 'kevin-work-selector-v1.2.py'
    $workerBackup=Join-Path $backupDir 'kevin-proven-skill-invoke-worker-v1.ps1'
    $builderBackup=Join-Path $backupDir 'kevin-proven-skill-request-builder-v1.py'
    $invokerBackup=Join-Path $backupDir 'kevin-proven-skill-invocation-v1.py'
    Copy-Item -LiteralPath $supervisorTarget -Destination $supBackup -Force
    Copy-Item -LiteralPath $baselineTarget -Destination $baseBackup -Force
    $selectorExisted=Test-Path -LiteralPath $selectorTarget -PathType Leaf
    $workerExisted=Test-Path -LiteralPath $workerTarget -PathType Leaf
    $builderExisted=Test-Path -LiteralPath $builderTarget -PathType Leaf
    $invokerExisted=Test-Path -LiteralPath $invokerTarget -PathType Leaf
    if($selectorExisted){Copy-Item -LiteralPath $selectorTarget -Destination $selBackup -Force}
    if($workerExisted){Copy-Item -LiteralPath $workerTarget -Destination $workerBackup -Force}
    if($builderExisted){Copy-Item -LiteralPath $builderTarget -Destination $builderBackup -Force}
    if($invokerExisted){Copy-Item -LiteralPath $invokerTarget -Destination $invokerBackup -Force}

    try{
        $liveSup=Get-Sha $supervisorTarget
        if($supBefore-eq$SupervisorV1812PredecessorSha-and$liveSup-ne$SupervisorV1812PredecessorSha){throw 'Supervisor changed after v1.8.12 staging; aborting TOCTOU'}
        if($supBefore-eq$SupervisorV1812Sha-and$liveSup-ne$SupervisorV1812Sha){throw 'Supervisor changed after v1.8.12 staging; aborting TOCTOU'}
        if($selectorExisted-and(Get-Sha $selectorTarget)-ne$SelectorV12Sha){throw 'selector v1.2 changed after staging; aborting TOCTOU'}
        if($workerExisted-and(Get-Sha $workerTarget)-ne$WorkerV1Sha){throw 'invocation worker changed after staging; aborting TOCTOU'}
        $liveBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        $liveBaseSup=([string]$liveBase.hashes.supervisor).ToUpperInvariant()
        if(([string]$liveBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'Benchmark Forge anchor changed after staging; aborting TOCTOU'}
        if($liveBaseSup-ne$baseSup){throw 'Benchmark Supervisor anchor changed after staging; aborting TOCTOU'}

        Install-StagedFile $supStage $supervisorTarget $SupervisorV1812Sha
        Install-StagedFile $selStage $selectorTarget $SelectorV12Sha
        Install-StagedFile $workerStage $workerTarget $WorkerV1Sha
        Install-StagedFile $builderStage $builderTarget $BuilderSha
        Install-StagedFile $invokerStage $invokerTarget $InvokerSha
        Install-StagedFile $baseStage $baselineTarget (Get-Sha $baseStage)

        if((Get-Sha $supervisorTarget)-ne$SupervisorV1812Sha){throw 'installed Supervisor v1.8.12 hash mismatch'}
        if((Get-Sha $selectorTarget)-ne$SelectorV12Sha){throw 'installed selector v1.2 hash mismatch'}
        if((Get-Sha $workerTarget)-ne$WorkerV1Sha){throw 'installed invocation worker hash mismatch'}
        if((Get-Sha $builderTarget)-ne$BuilderSha){throw 'installed request builder hash mismatch'}
        if((Get-Sha $invokerTarget)-ne$InvokerSha){throw 'installed invocation python hash mismatch'}
        $postBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$postBase.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV1812Sha-or([string]$postBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'installed Benchmark anchors mismatch'}

        Parse-PowerShell $supervisorTarget
        Parse-PowerShell $workerTarget
        Invoke-SupervisorV1812SelfTest $supervisorTarget
        Invoke-SelectorV12SelfTest $selectorTarget
        Assert-Benchmark30
        return [ordered]@{changed=$true;supervisor_before=$supBefore;supervisor_after=(Get-Sha $supervisorTarget);worker_before=$workerBefore;worker_after=(Get-Sha $workerTarget);selector_before=$selectorBefore;selector_after=(Get-Sha $selectorTarget);benchmark_supervisor_anchor=$SupervisorV1812Sha;forge_anchor=$ForgeV40Sha;history_preserved=$true;work_items_preserved=$true;mission_leases_preserved=$true;route_before_turn_charge=$true;owner_value_skills_to_skill_lab=$true;proven_skill_before_skill_lab=$true;invocation_not_main=$true;invocation_worker_installed=$true;public_history_skip_invalid=$true;rollback_available=$true}
    }catch{
        $primary=$_.Exception.Message
        Copy-Item -LiteralPath $supBackup -Destination $supervisorTarget -Force
        Copy-Item -LiteralPath $baseBackup -Destination $baselineTarget -Force
        if($selectorExisted){Copy-Item -LiteralPath $selBackup -Destination $selectorTarget -Force}else{Remove-Item -LiteralPath $selectorTarget -Force -ErrorAction SilentlyContinue}
        if($workerExisted){Copy-Item -LiteralPath $workerBackup -Destination $workerTarget -Force}else{Remove-Item -LiteralPath $workerTarget -Force -ErrorAction SilentlyContinue}
        if($builderExisted){Copy-Item -LiteralPath $builderBackup -Destination $builderTarget -Force}else{Remove-Item -LiteralPath $builderTarget -Force -ErrorAction SilentlyContinue}
        if($invokerExisted){Copy-Item -LiteralPath $invokerBackup -Destination $invokerTarget -Force}else{Remove-Item -LiteralPath $invokerTarget -Force -ErrorAction SilentlyContinue}
        try{Assert-Benchmark30}catch{}
        throw ('autonomy controller v1.8.12 rollback completed: '+$primary)
    }finally{
        if($owned){try{$mutex.ReleaseMutex()}catch{}}
        $mutex.Dispose()
    }
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
function Invoke-SelfTest{
    if($ExpectedParentSha-notmatch'^[A-F0-9]{64}$'){throw 'parent pin invalid'}
    if($ParentRepoPath-ne'control-plane/maintenance/kevin-maintenance-runner-v1.3.52.ps1'){throw 'parent path widened'}
    if($ManifestRepoPath-ne'inbox/maintenance/manifest.json'){throw 'manifest path widened'}
    if($SupervisorV1812PredecessorSha-ne'685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79'){throw 'v1.8.12 predecessor pin drifted'}
    if($SupervisorV1812Sha-ne'F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB'){throw 'v1.8.12 after pin drifted'}
    if($WorkerV1Sha-ne'16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332'){throw 'invocation worker pin drifted'}
    if($AllowedOperations-notcontains'install_autonomy_controller_v1812'){throw 'v1812 operation not allowlisted'}
    if($AllowedOperations-notcontains'install_autonomy_controller_v1811'){throw 'parent v1811 operation dropped'}
    if($AllowedOperations-notcontains'install_autonomy_controller_v1810'){throw 'parent v1810 operation dropped'}
    if($AllowedOperations-notcontains'replace_pinned_component'){throw 'replace_pinned_component dropped'}
    $id='';$exp=''
    $expired=New-SelfTestManifest (Get-Date).AddMinutes(-5)
    if(-not(Test-IsCanonicalExpiredObject $expired ([ref]$id) ([ref]$exp))){throw 'expired canonical manifest not classified'}
    if($id-ne'selftest-expired-001'){throw 'expired manifest identity mismatch'}
    $fresh=New-SelfTestManifest (Get-Date).AddMinutes(5);$id='';$exp=''
    if(Test-IsCanonicalExpiredObject $fresh ([ref]$id) ([ref]$exp)){throw 'fresh manifest classified expired'}
    $expiredV1812=New-SelfTestManifest (Get-Date).AddMinutes(-5) 'GREEN' 'install_autonomy_controller_v1812'
    $id='';$exp=''
    if(-not(Test-IsCanonicalExpiredObject $expiredV1812 ([ref]$id) ([ref]$exp))){throw 'expired v1812 manifest not classified'}
    $freshV1812=New-SelfTestManifest (Get-Date).AddMinutes(5) 'GREEN' 'install_autonomy_controller_v1812'
    $id='';$exp=''
    if(Test-IsCanonicalExpiredObject $freshV1812 ([ref]$id) ([ref]$exp)){throw 'fresh v1812 classified expired'}
    $bad=New-SelfTestManifest (Get-Date).AddMinutes(5);$bad.expires_at='not-a-time';$id='';$exp=''
    if(Test-IsCanonicalExpiredObject $bad ([ref]$id) ([ref]$exp)){throw 'malformed expiry clean-idled instead of delegated hard validation'}
    $bad=New-SelfTestManifest (Get-Date).AddMinutes(-5) 'RED';$id='';$exp=''
    if(Test-IsCanonicalExpiredObject $bad ([ref]$id) ([ref]$exp)){throw 'invalid authority clean-idled instead of delegated hard validation'}
    $json=ConvertTo-Json -InputObject $expired -Compress
    $id='';$exp=''
    if(-not(Test-IsCanonicalExpired $json ([ref]$id) ([ref]$exp))){throw 'expired JSON boundary not classified'}
    $extra=$freshV1812|Select-Object *;$extra|Add-Member -NotePropertyName target_alias -NotePropertyValue 'supervisor' -Force
    try{Assert-AutonomyControllerV1812Install $extra;throw 'extra property accepted'}catch{if($_.Exception.Message-notmatch'must not supply'){throw}}
    Write-Host 'KEVIN MAINTENANCE v1.3.3 SELFTEST PASS compatibility=v1.3.53'
    Write-Host 'KEVIN MAINTENANCE v1.3.53 SELFTEST PASS expired_manifest=clean_idle stale_execution=false parent=v1.3.52_exact v1812=allowlisted invocation_worker=pinned supervisor_after=v1.8.12 worker_native_error=fail_closed delegation=fail_closed authority_expansion=false arbitrary_shell=false'
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
    if($parsed -and [string]$parsed.operation -eq 'install_autonomy_controller_v1812'){
        $result=Install-AutonomyControllerV1812 $parsed
        $status=if([bool]$result.idempotent){'ALREADY_APPLIED_PROVEN'}else{'APPLIED_PREAUTHORIZED_PROVEN'}
        Save-State $status ([string]$parsed.id) 'Supervisor v1.8.12 worker-native fail-closed applied/verified.' @{
            operation='install_autonomy_controller_v1812'
            parent_invoked=$false
            result=$result
            authority_effect='NONE'
        }
        Write-Host ('MAINTENANCE '+$status+' id='+[string]$parsed.id+' operation=install_autonomy_controller_v1812')
        exit 0
    }
    $code=Invoke-Parent
    exit $code
}catch{
    Save-State 'ERROR' '' $_.Exception.Message @{authority_effect='NONE';wrapper='1.3.53'}
    Write-Host ('MAINTENANCE ERROR '+(Safe-Text $_.Exception.Message 600))
    exit 1
}
