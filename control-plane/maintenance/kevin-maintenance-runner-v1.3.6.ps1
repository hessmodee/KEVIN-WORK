param(
    [switch]$CheckOnly,
    [switch]$ApplyOnce,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Workspace = if ($env:KEVIN_MAINT_TEST_ROOT) { $env:KEVIN_MAINT_TEST_ROOT } elseif ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Reports = Join-Path $Workspace 'reports'
$Root = Join-Path $Reports 'maintenance'
$StageRoot = Join-Path $Root 'staged'
$BackupRoot = Join-Path $Root 'backups'
$LatestPath = Join-Path $Root 'latest.json'
$AttemptPath = Join-Path $Root 'typed-attempts.json'
$Repo = 'hessmodee/KEVIN-WORK'
$ManifestRemote = 'inbox/maintenance/manifest.json'
$OwnerPolicy = 'Kevin Owner Authorization v1'
$MaxAttempts = 3
$AbsentHash = ('0' * 64)
$RuntimePolicyNames = @('AGENTS.md','HEARTBEAT.md','MEMORY.md','SOUL.md','TOOLS.md')
foreach ($d in @($Root,$StageRoot,$BackupRoot)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

function Write-Utf8Atomic([string]$Path,[string]$Text) {
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,$Text,$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Write-JsonAtomic([string]$Path,[object]$Object) { Write-Utf8Atomic $Path ($Object | ConvertTo-Json -Depth 30) }
function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Safe-Text([object]$Value,[int]$MaxLength = 900) {
    $s = [string]$Value
    if (-not $s) { return '' }
    if ($env:USERPROFILE) { $s = [regex]::Replace($s,[regex]::Escape([string]$env:USERPROFILE),'~',[Text.RegularExpressions.RegexOptions]::IgnoreCase) }
    foreach ($pattern in @('(?i)\bghp_[A-Za-z0-9_]{8,}\b','(?i)\bgithub_pat_[A-Za-z0-9_]{8,}\b','(?i)\bsk-[A-Za-z0-9_-]{8,}\b','(?i)(Authorization\s*:\s*Bearer\s+)[^\s''";,]+')) { $s = [regex]::Replace($s,$pattern,'[REDACTED]') }
    $s = $s.Replace("`r",' ').Replace("`n",' ')
    if ($s.Length -gt $MaxLength) { $s = $s.Substring(0,$MaxLength) }
    return $s
}
function Save-State([string]$Status,[string]$ManifestId = '',[string]$Detail = '',[hashtable]$Extra = $null) {
    $obj = [ordered]@{ schema=3; kind='kevin-maintenance-state'; version='1.3.6'; at=(Get-Date).ToString('o'); status=$Status; manifest_id=$ManifestId; detail=(Safe-Text $Detail) }
    if ($Extra) { foreach ($k in $Extra.Keys) { $obj[$k] = $Extra[$k] } }
    Write-JsonAtomic $LatestPath $obj
}

function Invoke-Gh([string[]]$Arguments) {
    $gh = (Get-Command gh -ErrorAction Stop).Source
    $oldGh = [Environment]::GetEnvironmentVariable('GH_TOKEN','Process')
    $oldGithub = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    try {
        Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
        Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
        $env:GH_PROMPT_DISABLED='1'
        $old=$ErrorActionPreference
        try { $ErrorActionPreference='Continue'; $out=(& $gh @Arguments 2>&1 | Out-String).Trim(); $code=[int]$LASTEXITCODE }
        finally { $ErrorActionPreference=$old }
        return [pscustomobject]@{ExitCode=$code;Output=[string]$out}
    }
    finally {
        if ($null -ne $oldGh) { $env:GH_TOKEN=$oldGh } else { Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue }
        if ($null -ne $oldGithub) { $env:GITHUB_TOKEN=$oldGithub } else { Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue }
    }
}
function Get-RemoteManifestText {
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$ManifestRemote),'--jq','.content')
    if ($r.ExitCode -ne 0) { if ($r.Output -match '404|Not Found') { return $null }; throw ('manifest fetch failed: '+(Safe-Text $r.Output 400)) }
    try { return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$r.Output -replace '\s',''))) } catch { throw 'manifest base64 decode failed' }
}
function Get-RemoteFixedBytes([string]$RepoPath) {
    if ($RepoPath -notmatch '^(workspace/(AGENTS|HEARTBEAT|MEMORY|SOUL|TOOLS)\.md|control-plane/(maintenance|intake|skill-lab|os-awareness|forge)/[A-Za-z0-9._-]+\.ps1)$') { throw 'fixed remote source path rejected' }
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.content')
    if ($r.ExitCode -ne 0) { throw ('remote source fetch failed: '+(Safe-Text $r.Output 400)) }
    try { return [Convert]::FromBase64String(([string]$r.Output -replace '\s','')) } catch { throw 'remote source base64 decode failed' }
}

function Get-AliasSpec([string]$Alias) {
    switch ($Alias) {
        'maintenance_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-maintenance-runner.ps1');Source='^control-plane/maintenance/kevin-maintenance-runner-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN MAINTENANCE v1.3.3 SELFTEST PASS';AllowAbsent=$false} }
        'work_order_intake' { return [pscustomobject]@{Target=(Join-Path $Workspace 'ControlPlane\kevin-work-order-intake-v0.1.ps1');Source='^control-plane/intake/kevin-work-order-intake-v[0-9._-]+\.ps1$';SelfTestArgs=@('-Mode','SelfTest');Marker='KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS';AllowAbsent=$false} }
        'skill_lab_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-skill-lab.ps1');Source='^control-plane/skill-lab/kevin-skill-lab-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN SKILL LAB v1.0.3 SELFTEST PASS';AllowAbsent=$false} }
        'os_observer_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-os-observer.ps1');Source='^control-plane/os-awareness/kevin-os-observer-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN OS OBSERVER v0.1 SELFTEST PASS';AllowAbsent=$true} }
        'self_reliance_watchdog' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-self-reliance-watchdog.ps1');Source='^control-plane/maintenance/kevin-self-reliance-watchdog-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN SELF-RELIANCE WATCHDOG v1.3 SELFTEST PASS';AllowAbsent=$false} }
        'design_forge_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-design-forge.ps1');Source='^control-plane/forge/kevin-design-forge-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN DESIGN FORGE v4.0 SELFTEST PASS';AllowAbsent=$false} }
        'ui_bridge_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-ui-bridge.ps1');Source='';SelfTestArgs=@('-SelfTest');Marker='';AllowAbsent=$false} }
        default { throw ('target alias not allowlisted: '+$Alias) }
    }
}
function Get-PolicySpec([string]$Name) {
    if ($RuntimePolicyNames -notcontains $Name) { throw ('runtime policy component not allowlisted: '+$Name) }
    $marker = switch ($Name) {
        'AGENTS.md' { 'Standing Order 1' }
        'HEARTBEAT.md' { 'ambient monitor' }
        'MEMORY.md' { 'durable' }
        'SOUL.md' { 'Chief of Staff' }
        'TOOLS.md' { 'typed' }
    }
    return [pscustomobject]@{Name=$Name;Target=(Join-Path $Workspace $Name);Source=('workspace/'+$Name);Marker=$marker}
}
function Get-RemoteBytes([string]$RepoPath,[string]$Alias) {
    $spec=Get-AliasSpec $Alias
    if (-not $spec.Source -or $RepoPath -notmatch $spec.Source) { throw 'remote source path outside alias root' }
    return Get-RemoteFixedBytes $RepoPath
}

function Read-Attempts { if (-not (Test-Path -LiteralPath $AttemptPath -PathType Leaf)) { return [pscustomobject]@{schema=1;items=@()} }; try { return Get-Content -LiteralPath $AttemptPath -Raw | ConvertFrom-Json } catch { return [pscustomobject]@{schema=1;items=@()} } }
function Get-AttemptRecord([object]$State,[string]$Id) { $hits=@($State.items|Where-Object{[string]$_.id -eq $Id}); if($hits.Count -gt 1){throw 'duplicate maintenance attempt state'}; if($hits.Count -eq 1){return $hits[0]}; return $null }
function Save-Attempt([string]$Id,[int]$Attempts,[string]$Status,[string]$FailureFamily='') { $state=Read-Attempts; $items=@($state.items|Where-Object{[string]$_.id -ne $Id}); $items+=,[pscustomobject]@{id=$Id;attempts=$Attempts;status=$Status;failure_family=$FailureFamily;updated_at=(Get-Date).ToString('o')}; Write-JsonAtomic $AttemptPath ([ordered]@{schema=1;kind='kevin-typed-maintenance-attempts';items=$items}) }

function Assert-Common([object]$m) {
    if([int]$m.schema -ne 3){throw 'manifest schema must be 3'}
    if([string]$m.kind -ne 'kevin-self-maintenance-manifest'){throw 'manifest kind mismatch'}
    if([string]$m.id -notmatch '^[A-Za-z0-9._-]{6,96}$'){throw 'manifest id invalid'}
    if([string]$m.authority_class -ne 'GREEN'){throw 'maintenance must be GREEN'}
    if([string]$m.authority_delta -ne 'NONE'){throw 'authority_delta must be NONE'}
    if([string]$m.production_effect -ne 'NONE'){throw 'production_effect must be NONE'}
    if([string]$m.owner_policy -ne $OwnerPolicy){throw 'owner policy mismatch'}
    if([bool]$m.preauthorized -ne $true){throw 'manifest must be preauthorized'}
    if($m.expires_at -and (Get-Date) -gt [datetime]$m.expires_at){throw 'manifest expired'}
    if(-not(@('replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','publish_runtime_convergence','replace_runtime_policy_bundle','migrate_design_forge_v40') -contains [string]$m.operation)){throw 'operation not allowlisted'}
}
function Assert-Replace([object]$m) {
    $spec=Get-AliasSpec ([string]$m.target_alias)
    if([string]$m.target_alias -eq 'ui_bridge_runner'){throw 'UI Bridge cannot use replace operation'}
    if([string]$m.source_path -notmatch $spec.Source){throw 'source path outside alias root'}
    foreach($n in @('source_sha256','expected_current_sha256','expected_after_sha256')){if([string]$m.$n -notmatch '^[A-Fa-f0-9]{64}$'){throw($n+' invalid')}}
    if(([string]$m.source_sha256).ToUpperInvariant() -ne ([string]$m.expected_after_sha256).ToUpperInvariant()){throw 'source hash must equal after hash'}
    if(([string]$m.expected_current_sha256).ToUpperInvariant() -eq $AbsentHash -and -not [bool]$spec.AllowAbsent){throw 'absent-current sentinel not allowed for alias'}
}
function Assert-ForgeMigration([object]$m) {
    if([string]$m.target_alias -ne 'design_forge_runner'){throw 'Forge migration target alias mismatch'}
    if([string]$m.source_path -ne 'control-plane/forge/kevin-design-forge-v4.0.ps1'){throw 'Forge migration source path mismatch'}
    foreach($n in @('source_sha256','expected_forge_current_sha256','expected_forge_after_sha256','expected_benchmark_current_sha256')){
        if([string]$m.$n -notmatch '^[A-Fa-f0-9]{64}$'){throw ($n+' invalid')}
    }
    if(([string]$m.source_sha256).ToUpperInvariant() -ne ([string]$m.expected_forge_after_sha256).ToUpperInvariant()){throw 'Forge migration source hash must equal after hash'}
    if(([string]$m.expected_forge_current_sha256).ToUpperInvariant() -eq ([string]$m.expected_forge_after_sha256).ToUpperInvariant()){throw 'Forge migration requires a real hash transition'}
}

function Get-LiteralOccurrenceCount([string]$Text,[string]$Needle) {
    if(-not $Needle){return 0}
    $count=0;$offset=0
    while($true){$i=$Text.IndexOf($Needle,$offset,[StringComparison]::OrdinalIgnoreCase);if($i -lt 0){break};$count++;$offset=$i+$Needle.Length}
    return $count
}
function Get-ForgePinPatchedBenchmark([string]$Text,[string]$Before,[string]$After) {
    $beforeCount=Get-LiteralOccurrenceCount $Text $Before
    $afterCount=Get-LiteralOccurrenceCount $Text $After
    if($beforeCount -ne 1){throw ('Benchmark must contain old Forge pin exactly once; count='+$beforeCount)}
    if($afterCount -ne 0){throw ('Benchmark already contains candidate Forge pin; count='+$afterCount)}
    return [regex]::Replace($Text,[regex]::Escape($Before),$After,[Text.RegularExpressions.RegexOptions]::IgnoreCase,[TimeSpan]::FromSeconds(1))
}
function Assert-Restart([object]$m) {
    if([string]$m.target_alias -ne 'ui_bridge_runner'){throw 'UI restart target alias mismatch'}
    if([string]$m.expected_current_sha256 -notmatch '^[A-Fa-f0-9]{64}$'){throw 'UI restart expected hash invalid'}
    if([string]$m.task_name -ne 'Kevin UI Bridge v0.3'){throw 'UI restart task name mismatch'}
    if([int]$m.heartbeat_timeout_seconds -lt 5 -or [int]$m.heartbeat_timeout_seconds -gt 30){throw 'UI heartbeat timeout outside 5..30 seconds'}
}
function Assert-RuntimeBundle([object]$m) {
    $items=@($m.components)
    if($items.Count -ne $RuntimePolicyNames.Count){throw 'runtime policy bundle must contain exactly five components'}
    $seen=@{}
    foreach($item in $items){
        $name=[string]$item.name
        $null=Get-PolicySpec $name
        if($seen.ContainsKey($name)){throw 'duplicate runtime policy component'}
        $seen[$name]=$true
        foreach($n in @('source_sha256','expected_current_sha256','expected_after_sha256')){
            if([string]$item.$n -notmatch '^[A-Fa-f0-9]{64}$'){throw ($name+' '+$n+' invalid')}
        }
        if(([string]$item.source_sha256).ToUpperInvariant() -ne ([string]$item.expected_after_sha256).ToUpperInvariant()){throw ($name+' source hash must equal after hash')}
        if(([string]$item.expected_current_sha256).ToUpperInvariant() -eq $AbsentHash){throw ($name+' absent-current is not allowed')}
    }
    foreach($name in $RuntimePolicyNames){if(-not$seen.ContainsKey($name)){throw ('missing runtime policy component '+$name)}}
}
function Assert-Governance {
    $desired=Join-Path $Workspace 'ControlPlane\desired-state-v1.json'; $owner=Join-Path $Workspace 'ControlPlane\OWNER-AUTHORIZATION-v1.md'
    if(-not(Test-Path -LiteralPath $desired -PathType Leaf) -or -not(Test-Path -LiteralPath $owner -PathType Leaf)){throw 'governance roots missing'}
    $d=Get-Content -LiteralPath $desired -Raw | ConvertFrom-Json
    if(-not[bool]$d.authority.green_only -or [bool]$d.authority.allow_arbitrary_shell -or [bool]$d.authority.allow_authority_expansion -or [bool]$d.authority.allow_novel_production_promotion){throw 'governance denies action'}
    $ot=[IO.File]::ReadAllText($owner)
    if(-not $ot.Contains('apply an owner-preauthorized GREEN maintenance package only through the typed maintenance/reconciliation contract')){throw 'owner preauthorization clause missing'}
}
function Parse-PowerShell([string]$Path) { $tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors);if($errors.Count -gt 0){throw('PowerShell parser rejected candidate: '+$errors[0].Message)} }
function Invoke-FixedSelfTest([string]$Alias,[string]$Path) {
    $spec=Get-AliasSpec $Alias;$args=@($spec.SelfTestArgs);$old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path @args 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code -ne 0){throw('fixed self-test failed exit='+$code)}
    if($out -notmatch [regex]::Escape([string]$spec.Marker)){throw 'fixed self-test marker missing'}
}
function Assert-Benchmark30 {
    $bench=Join-Path $Workspace 'kevin-benchmark-v1.ps1';$latest=Join-Path $Reports 'benchmark-v1\latest.json'
    if(-not(Test-Path -LiteralPath $bench -PathType Leaf)){throw 'benchmark script missing'}
    $deadline=(Get-Date).AddSeconds(60)
    while($true){$started=[DateTime]::UtcNow;$old=$ErrorActionPreference;try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $bench 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old};if($out -match '(?i)BENCHMARK\s+SKIP_ACTIVE_WORK'){if((Get-Date)-ge$deadline){throw 'fresh benchmark retry budget exhausted'};Start-Sleep 5;continue};if($code -ne 0){throw('benchmark failed exit='+$code)};if(-not(Test-Path -LiteralPath $latest)){throw 'benchmark evidence missing'};$b=Get-Content $latest -Raw|ConvertFrom-Json;if([string]$b.status -ne 'PASS' -or [int]$b.regression.passed -ne 30 -or [int]$b.regression.total -ne 30 -or [int]$b.regression.critical_failures -ne 0){throw 'benchmark not 30/30 critical=0'};if((Get-Item $latest).LastWriteTimeUtc -lt $started.AddSeconds(-3)){throw 'benchmark evidence not fresh'};return}
}
function Assert-Utf8Policy([string]$Path,[string]$Name) {
    $bytes=[IO.File]::ReadAllBytes($Path)
    if($bytes.Length -lt 32 -or $bytes.Length -gt 65536){throw ($Name+' size outside 32..65536 bytes')}
    if($bytes -contains 0){throw ($Name+' contains NUL byte')}
    $text=[Text.Encoding]::UTF8.GetString($bytes)
    $spec=Get-PolicySpec $Name
    if(-not $text.Contains([string]$spec.Marker)){throw ($Name+' required doctrine marker missing')}
}

function New-InstallResult([bool]$Changed,[string]$Before,[string]$After,[bool]$Idempotent,[string]$Backup='') { $r=[ordered]@{changed=$Changed;before=$Before;after=$After;idempotent=$Idempotent};if($Backup){$r['backup']=$Backup};return $r }
function New-RestartResult([string]$Hash,[string]$TaskName,[string]$HeartbeatAt,[string]$State) { return [ordered]@{changed=$true;hash=$Hash;task_name=$TaskName;heartbeat_at=$HeartbeatAt;state=$State} }

function Install-Pinned([object]$m) {
    $alias=[string]$m.target_alias;$spec=Get-AliasSpec $alias;$target=[string]$spec.Target;$hadTarget=Test-Path -LiteralPath $target -PathType Leaf;$before=Get-Sha $target;$cur=([string]$m.expected_current_sha256).ToUpperInvariant();$after=([string]$m.expected_after_sha256).ToUpperInvariant()
    if($before -eq $after){Invoke-FixedSelfTest $alias $target;Assert-Benchmark30;return (New-InstallResult $false $before $before $true)}
    if($hadTarget){if($before -ne $cur){throw('expected-current mismatch alias='+$alias+' actual='+$before)}}else{if(-not[bool]$spec.AllowAbsent -or $cur -ne $AbsentHash){throw('expected-current missing alias='+$alias)}}
    $bytes=Get-RemoteBytes ([string]$m.source_path) $alias;$stage=Join-Path $StageRoot ([string]$m.id+'.candidate.ps1');[IO.File]::WriteAllBytes($stage,$bytes)
    if((Get-Sha $stage) -ne $after){throw 'staged source hash mismatch'}
    Parse-PowerShell $stage;Invoke-FixedSelfTest $alias $stage
    $backupDir=Join-Path $BackupRoot ([string]$m.id);New-Item -ItemType Directory -Force $backupDir|Out-Null;$backup=Join-Path $backupDir ([IO.Path]::GetFileName($target));if($hadTarget){Copy-Item -LiteralPath $target -Destination $backup -Force}
    try{$tmp=$target+'.typed-'+[guid]::NewGuid().ToString('N');Copy-Item $stage $tmp -Force;Move-Item $tmp $target -Force;if((Get-Sha $target) -ne $after){throw 'installed target hash mismatch'};Invoke-FixedSelfTest $alias $target;Assert-Benchmark30;return (New-InstallResult $true $(if($hadTarget){$before}else{$AbsentHash}) (Get-Sha $target) $false $(if($hadTarget){Safe-Text $backup 500}else{''}))}catch{if($hadTarget -and (Test-Path -LiteralPath $backup -PathType Leaf)){Copy-Item $backup $target -Force}elseif(-not$hadTarget -and (Test-Path -LiteralPath $target -PathType Leaf)){Remove-Item -LiteralPath $target -Force};throw('replace rollback completed: '+$_.Exception.Message)}
}
function Migrate-DesignForgeV40([object]$m) {
    Assert-ForgeMigration $m
    $forgeSpec=Get-AliasSpec 'design_forge_runner'
    $forgeTarget=[string]$forgeSpec.Target
    $benchTarget=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    if(-not(Test-Path -LiteralPath $forgeTarget -PathType Leaf)){throw 'Forge target missing'}
    if(-not(Test-Path -LiteralPath $benchTarget -PathType Leaf)){throw 'Benchmark target missing'}

    $forgeBefore=Get-Sha $forgeTarget
    $benchBefore=Get-Sha $benchTarget
    $expectedForgeBefore=([string]$m.expected_forge_current_sha256).ToUpperInvariant()
    $expectedForgeAfter=([string]$m.expected_forge_after_sha256).ToUpperInvariant()
    $expectedBenchBefore=([string]$m.expected_benchmark_current_sha256).ToUpperInvariant()
    if($forgeBefore -ne $expectedForgeBefore){throw ('Forge expected-current mismatch actual='+$forgeBefore)}
    if($benchBefore -ne $expectedBenchBefore){throw ('Benchmark expected-current mismatch actual='+$benchBefore)}

    $forgeBytes=Get-RemoteBytes ([string]$m.source_path) 'design_forge_runner'
    $forgeStage=Join-Path $StageRoot ([string]$m.id+'.forge.ps1')
    [IO.File]::WriteAllBytes($forgeStage,$forgeBytes)
    if((Get-Sha $forgeStage) -ne $expectedForgeAfter){throw 'Forge staged hash mismatch'}
    Parse-PowerShell $forgeStage
    Invoke-FixedSelfTest 'design_forge_runner' $forgeStage

    $benchText=[IO.File]::ReadAllText($benchTarget)
    $benchPatched=Get-ForgePinPatchedBenchmark $benchText $expectedForgeBefore $expectedForgeAfter
    $benchStage=Join-Path $StageRoot ([string]$m.id+'.benchmark.ps1')
    [IO.File]::WriteAllText($benchStage,$benchPatched,$Utf8)
    Parse-PowerShell $benchStage
    $benchAfter=Get-Sha $benchStage
    if($benchAfter -eq $benchBefore){throw 'Benchmark pin migration produced no byte change'}
    if((Get-LiteralOccurrenceCount ([IO.File]::ReadAllText($benchStage)) $expectedForgeBefore) -ne 0){throw 'Old Forge pin remained in staged Benchmark'}
    if((Get-LiteralOccurrenceCount ([IO.File]::ReadAllText($benchStage)) $expectedForgeAfter) -ne 1){throw 'New Forge pin missing or duplicated in staged Benchmark'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir|Out-Null
    $forgeBackup=Join-Path $backupDir 'kevin-design-forge.ps1'
    $benchBackup=Join-Path $backupDir 'kevin-benchmark-v1.ps1'
    Copy-Item -LiteralPath $forgeTarget -Destination $forgeBackup -Force
    Copy-Item -LiteralPath $benchTarget -Destination $benchBackup -Force

    try {
        foreach($pair in @(@($forgeStage,$forgeTarget),@($benchStage,$benchTarget))){
            $tmp=$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $pair[1] -Force
        }
        if((Get-Sha $forgeTarget) -ne $expectedForgeAfter){throw 'Installed Forge hash mismatch'}
        if((Get-Sha $benchTarget) -ne $benchAfter){throw 'Installed Benchmark hash mismatch'}
        Parse-PowerShell $forgeTarget
        Parse-PowerShell $benchTarget
        Invoke-FixedSelfTest 'design_forge_runner' $forgeTarget
        Assert-Benchmark30
        return [ordered]@{
            changed=$true
            forge_before=$forgeBefore
            forge_after=(Get-Sha $forgeTarget)
            benchmark_before=$benchBefore
            benchmark_after=(Get-Sha $benchTarget)
            benchmark_pin_change='exact literal old Forge SHA -> new Forge SHA; one occurrence only'
            rollback_available=$true
        }
    } catch {
        Copy-Item -LiteralPath $forgeBackup -Destination $forgeTarget -Force
        Copy-Item -LiteralPath $benchBackup -Destination $benchTarget -Force
        try { Assert-Benchmark30 } catch { }
        throw ('coordinated Forge migration rollback completed: '+$_.Exception.Message)
    }
}
function Restart-UiBridge([object]$m) {
    if($env:OS -ne 'Windows_NT'){throw 'UI restart requires Windows'};$spec=Get-AliasSpec 'ui_bridge_runner';$actual=Get-Sha $spec.Target;if($actual -ne ([string]$m.expected_current_sha256).ToUpperInvariant()){throw('UI Bridge hash mismatch actual='+$actual)};$task=Get-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue;if(-not$task){throw 'UI Bridge task missing'};$heartbeat=Join-Path $Reports 'action-era\ui-bridge\heartbeat.json';$started=Get-Date;try{Stop-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue}catch{};Start-ScheduledTask -TaskName ([string]$m.task_name);$deadline=(Get-Date).AddSeconds([int]$m.heartbeat_timeout_seconds);$fresh=$null;while((Get-Date)-lt$deadline){Start-Sleep -Milliseconds 500;if(Test-Path $heartbeat){try{$h=Get-Content $heartbeat -Raw|ConvertFrom-Json;if([string]$h.kind -eq 'kevin-ui-bridge-heartbeat' -and [datetime]$h.at -ge $started.AddSeconds(-2) -and [string]$h.state -eq 'READY'){$fresh=$h;break}}catch{}}};if(-not$fresh){throw 'UI Bridge did not produce fresh READY heartbeat'};Assert-Benchmark30;return (New-RestartResult $actual ([string]$m.task_name) ([string]$fresh.at) ([string]$fresh.state))
}
function Audit-RuntimeConvergence {
    $policy=[ordered]@{}
    foreach($name in $RuntimePolicyNames){$spec=Get-PolicySpec $name;$policy[$name]=Get-Sha $spec.Target}
    $forge=Get-AliasSpec 'design_forge_runner'
    return [ordered]@{
        policy_hashes=$policy
        design_forge_sha256=(Get-Sha $forge.Target)
        design_forge_present=(Test-Path -LiteralPath $forge.Target -PathType Leaf)
        source_contract='fixed workspace policy set + fixed design_forge alias only'
    }
}
function Publish-RuntimeConvergence {
    $audit=Audit-RuntimeConvergence
    $public=[ordered]@{
        schema=1
        kind='kevin-runtime-convergence-public'
        generated_at=(Get-Date).ToString('o')
        state='OMEN_AUDIT_PROVEN'
        safe_for_public_repo=$true
        policy_hashes=$audit.policy_hashes
        design_forge_sha256=$audit.design_forge_sha256
        design_forge_present=$audit.design_forge_present
        maintenance_runner_sha256=(Get-Sha (Join-Path $Workspace 'kevin-maintenance-runner.ps1'))
        source_contract='fixed five runtime policy files + fixed design_forge alias + fixed maintenance runner only'
        truth_boundary='Metadata-only Omen audit. Hashes prove local file identities at generated_at; they do not by themselves prove semantic behavior.'
    }
    $local=Join-Path $Reports 'runtime-convergence-public.json'
    Write-JsonAtomic $local $public
    $repoPath='reports/runtime-convergence-omen.json'
    $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
    if($lookup.ExitCode -ne 0 -or -not $lookup.Output){throw 'runtime convergence receipt remote SHA lookup failed'}
    $payload=[ordered]@{
        message='kevin runtime convergence telemetry'
        content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))
        sha=[string]$lookup.Output
    }|ConvertTo-Json -Compress
    $payloadPath=Join-Path $env:TEMP ('kevin-runtime-convergence-'+[guid]::NewGuid().ToString('N')+'.json')
    try{
        [IO.File]::WriteAllText($payloadPath,$payload,$Utf8)
        $publish=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$payloadPath,'--silent')
        if($publish.ExitCode -ne 0){throw ('runtime convergence receipt publish failed: '+(Safe-Text $publish.Output 400))}
    }finally{Remove-Item -LiteralPath $payloadPath -Force -ErrorAction SilentlyContinue}
    $verify=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.content')
    if($verify.ExitCode -ne 0 -or -not $verify.Output){throw 'runtime convergence receipt verification fetch failed'}
    try{$remote=[Convert]::FromBase64String(([string]$verify.Output -replace '\s',''))}catch{throw 'runtime convergence receipt verification decode failed'}
    $localHash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToUpperInvariant()
    $sha=[Security.Cryptography.SHA256]::Create()
    try{$remoteHash=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()}
    if($remoteHash -ne $localHash){throw 'runtime convergence receipt remote verification hash mismatch'}
    return [ordered]@{published=$true;repo_path=$repoPath;receipt_sha256=$localHash;policy_hashes=$audit.policy_hashes;design_forge_sha256=$audit.design_forge_sha256}
}
function Install-RuntimePolicyBundle([object]$m) {
    Assert-RuntimeBundle $m
    $byName=@{}
    foreach($item in @($m.components)){$byName[[string]$item.name]=$item}
    $allAlready=$true
    foreach($name in $RuntimePolicyNames){
        $spec=Get-PolicySpec $name
        $item=$byName[$name]
        $actual=Get-Sha $spec.Target
        if($actual -ne ([string]$item.expected_after_sha256).ToUpperInvariant()){$allAlready=$false}
    }
    if($allAlready){
        foreach($name in $RuntimePolicyNames){$spec=Get-PolicySpec $name;Assert-Utf8Policy $spec.Target $name}
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;components=$RuntimePolicyNames}
    }
    $bundleStage=Join-Path $StageRoot ([string]$m.id+'-runtime-policy')
    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $bundleStage,$backupDir|Out-Null
    foreach($name in $RuntimePolicyNames){
        $spec=Get-PolicySpec $name;$item=$byName[$name]
        $cur=Get-Sha $spec.Target
        if($cur -ne ([string]$item.expected_current_sha256).ToUpperInvariant()){throw ('runtime policy expected-current mismatch '+$name+' actual='+$cur)}
        $bytes=Get-RemoteFixedBytes ([string]$spec.Source)
        $stage=Join-Path $bundleStage $name
        [IO.File]::WriteAllBytes($stage,$bytes)
        if((Get-Sha $stage) -ne ([string]$item.expected_after_sha256).ToUpperInvariant()){throw ('runtime policy staged hash mismatch '+$name)}
        Assert-Utf8Policy $stage $name
        Copy-Item -LiteralPath $spec.Target -Destination (Join-Path $backupDir $name) -Force
    }
    try{
        foreach($name in $RuntimePolicyNames){
            $spec=Get-PolicySpec $name;$item=$byName[$name];$stage=Join-Path $bundleStage $name
            $tmp=$spec.Target+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $stage -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $spec.Target -Force
            if((Get-Sha $spec.Target) -ne ([string]$item.expected_after_sha256).ToUpperInvariant()){throw ('runtime policy installed hash mismatch '+$name)}
            Assert-Utf8Policy $spec.Target $name
        }
        Assert-Benchmark30
        $after=[ordered]@{};foreach($name in $RuntimePolicyNames){$specAfter=Get-PolicySpec $name;$after[$name]=Get-Sha $specAfter.Target}
        return [ordered]@{changed=$true;idempotent=$false;after=$after}
    }catch{
        foreach($name in $RuntimePolicyNames){
            $spec=Get-PolicySpec $name;$backup=Join-Path $backupDir $name
            if(Test-Path -LiteralPath $backup -PathType Leaf){Copy-Item -LiteralPath $backup -Destination $spec.Target -Force}
        }
        throw ('runtime policy bundle rollback completed: '+$_.Exception.Message)
    }
}

function Process-Typed([object]$m) {
    Assert-Common $m
    switch([string]$m.operation){
        'replace_pinned_component' { Assert-Replace $m }
        'restart_ui_bridge' { Assert-Restart $m }
        'audit_runtime_convergence' { }
        'publish_runtime_convergence' { }
        'replace_runtime_policy_bundle' { Assert-RuntimeBundle $m }
        'migrate_design_forge_v40' { Assert-ForgeMigration $m }
        default { throw 'operation not allowlisted' }
    }
    Assert-Governance
    $state=Read-Attempts;$rec=Get-AttemptRecord $state ([string]$m.id);$attempts=if($rec){[int]$rec.attempts}else{0}
    if($rec -and [string]$rec.status -eq 'PROVEN'){Save-State 'ALREADY_APPLIED_PROVEN' ([string]$m.id) 'Maintenance previously proven.' @{attempts=$attempts};return}
    if($attempts -ge $MaxAttempts){Save-State 'BLOCKED_FAILURE_BUDGET' ([string]$m.id) 'Failure budget exhausted.' @{attempts=$attempts};return}
    $attempts++
    try{
        $result=switch([string]$m.operation){
            'replace_pinned_component' { Install-Pinned $m; break }
            'restart_ui_bridge' { Restart-UiBridge $m; break }
            'audit_runtime_convergence' { Audit-RuntimeConvergence; break }
            'publish_runtime_convergence' { Publish-RuntimeConvergence; break }
            'replace_runtime_policy_bundle' { Install-RuntimePolicyBundle $m; break }
            'migrate_design_forge_v40' { Migrate-DesignForgeV40 $m; break }
        }
        Save-Attempt ([string]$m.id) $attempts 'PROVEN'
        Save-State 'APPLIED_PREAUTHORIZED_PROVEN' ([string]$m.id) 'Applied/audited and independently verified.' @{attempts=$attempts;operation=[string]$m.operation;result=$result}
    }catch{
        $family=switch([string]$m.operation){
            'restart_ui_bridge' {'ui_bridge_restart_failure'}
            'audit_runtime_convergence' {'runtime_convergence_audit_failure'}
            'publish_runtime_convergence' {'runtime_convergence_publish_failure'}
            'replace_runtime_policy_bundle' {'runtime_policy_bundle_failure'}
            'migrate_design_forge_v40' {'forge_validator_migration_failure'}
            default {'typed_replace_failure'}
        }
        Save-Attempt ([string]$m.id) $attempts 'FAILED' $family
        Save-State 'APPLY_FAILED' ([string]$m.id) $_.Exception.Message @{attempts=$attempts;failure_family=$family}
        throw
    }
}

function Legacy-Stage([string]$Text,[bool]$Apply) { $m=$Text|ConvertFrom-Json;if([int]$m.schema -ne 1 -or [string]$m.kind -ne 'kevin-maintenance-manifest'){throw 'legacy manifest invalid'};if(-not$Apply){Save-State 'LEGACY_STAGED_APPROVAL_REQUIRED' ([string]$m.id) 'Legacy executable package requires one-time ApplyOnce.';return};throw 'v1.3.4 never executes legacy executable maintenance packages' }
function Invoke-SelfTest {
    $base=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-maint-001';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='replace_pinned_component';target_alias='maintenance_runner';source_path='control-plane/maintenance/kevin-maintenance-runner-v1.3.4.ps1';source_sha256=('A'*64);expected_current_sha256=('B'*64);expected_after_sha256=('A'*64);expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-Common $base;Assert-Replace $base
    foreach($case in @(
        @('work_order_intake','control-plane/intake/kevin-work-order-intake-v1.2.3.ps1'),
        @('skill_lab_runner','control-plane/skill-lab/kevin-skill-lab-v1.0.4.ps1'),
        @('os_observer_runner','control-plane/os-awareness/kevin-os-observer-v0.1.ps1'),
        @('self_reliance_watchdog','control-plane/maintenance/kevin-self-reliance-watchdog-v1.4.ps1'),
        @('design_forge_runner','control-plane/forge/kevin-design-forge-v4.0.ps1')
    )){$x=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$x.target_alias=$case[0];$x.source_path=$case[1];if($case[0] -eq 'os_observer_runner'){$x.expected_current_sha256=$AbsentHash};Assert-Replace $x}
    $bundle=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-runtime-policy';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='replace_runtime_policy_bundle';expires_at=(Get-Date).AddMinutes(10).ToString('o');components=@()}
    foreach($name in $RuntimePolicyNames){$bundle.components+=,[pscustomobject]@{name=$name;source_sha256=('A'*64);expected_current_sha256=('B'*64);expected_after_sha256=('A'*64)}}
    Assert-Common $bundle;Assert-RuntimeBundle $bundle
    $bad=$bundle|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.components=@($bad.components|Select-Object -First 4);$blocked=$false;try{Assert-RuntimeBundle $bad}catch{$blocked=$true};if(-not$blocked){throw 'partial runtime policy bundle accepted'}
    $bad=$bundle|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.components[0].name='BAD.md';$blocked=$false;try{Assert-RuntimeBundle $bad}catch{$blocked=$true};if(-not$blocked){throw 'unknown runtime policy component accepted'}
    $audit=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$audit.operation='audit_runtime_convergence';$audit.PSObject.Properties.Remove('target_alias');$audit.PSObject.Properties.Remove('source_path');$audit.PSObject.Properties.Remove('source_sha256');$audit.PSObject.Properties.Remove('expected_current_sha256');$audit.PSObject.Properties.Remove('expected_after_sha256');Assert-Common $audit


    $pub=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$pub.operation='publish_runtime_convergence';Assert-Common $pub
    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='migrate_design_forge_v40';target_alias='design_forge_runner';source_path='control-plane/forge/kevin-design-forge-v4.0.ps1';source_sha256=('C'*64);expected_forge_current_sha256=('B'*64);expected_forge_after_sha256=('C'*64);expected_benchmark_current_sha256=('D'*64);expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-Common $mig;Assert-ForgeMigration $mig
    $fake=('prefix '+('B'*64)+' suffix')
    $patched=Get-ForgePinPatchedBenchmark $fake ('B'*64) ('C'*64)
    if((Get-LiteralOccurrenceCount $patched ('B'*64)) -ne 0 -or (Get-LiteralOccurrenceCount $patched ('C'*64)) -ne 1){throw 'Forge pin patch helper selftest failed'}
    $blocked=$false;try{Get-ForgePinPatchedBenchmark ($fake+' '+('B'*64)) ('B'*64) ('C'*64)|Out-Null}catch{$blocked=$true};if(-not$blocked){throw 'duplicate old Forge pin accepted'}
    $bad=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.target_alias='supervisor';$blocked=$false;try{Assert-Replace $bad}catch{$blocked=$true};if(-not$blocked){throw 'unknown alias accepted'}
    $bad=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.operation='shell';$blocked=$false;try{Assert-Common $bad}catch{$blocked=$true};if(-not$blocked){throw 'arbitrary operation accepted'}
    Write-Host 'KEVIN MAINTENANCE v1.3.2 SELFTEST PASS compatibility=v1.3.4'
    Write-Host 'KEVIN MAINTENANCE v1.3.3 SELFTEST PASS compatibility=v1.3.4'
    Write-Host 'KEVIN MAINTENANCE v1.3.4 SELFTEST PASS compatibility=v1.3.5'
    Write-Host 'KEVIN MAINTENANCE v1.3.5 SELFTEST PASS compatibility=v1.3.6'
    Write-Host 'KEVIN MAINTENANCE v1.3.6 SELFTEST PASS aliases=6 runtime_policy_bundle=5 convergence_audit=1 convergence_publish=1 fixed_public_receipt=1 coordinated_forge_validator_migration=1 arbitrary_shell=false authority_expansion=false max_attempts=3'
}

if($SelfTest){Invoke-SelfTest;exit 0}
try{$text=Get-RemoteManifestText;if($null -eq $text){Save-State 'NO_MANIFEST' '' 'No maintenance proposal is waiting.';exit 0};$m=$text|ConvertFrom-Json;if([int]$m.schema -eq 3 -and [string]$m.kind -eq 'kevin-self-maintenance-manifest'){Process-Typed $m;exit 0};if([int]$m.schema -eq 2 -and [string]$m.kind -eq 'kevin-typed-maintenance-manifest'){Save-State 'SCHEMA2_NEEDS_MIGRATION' ([string]$m.id) 'v1.3.4 requires schema-3 aliases for self-maintenance transport.';exit 0};Legacy-Stage $text ([bool]$ApplyOnce);exit 0}catch{if(-not(Test-Path $LatestPath) -or (Get-Content $LatestPath -Raw) -notmatch 'APPLY_FAILED'){Save-State 'ERROR' '' $_.Exception.Message};Write-Host('MAINTENANCE ERROR '+(Safe-Text $_.Exception.Message 600));exit 1}
