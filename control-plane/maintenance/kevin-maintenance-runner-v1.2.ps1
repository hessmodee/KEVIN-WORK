param(
    [switch]$CheckOnly,
    [switch]$ApplyOnce,
    [switch]$SelfTest
)

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

foreach ($d in @($Root,$StageRoot,$BackupRoot)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

function Write-Utf8Atomic([string]$Path,[string]$Text) {
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,$Text,$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Write-JsonAtomic([string]$Path,[object]$Object) {
    Write-Utf8Atomic $Path ($Object | ConvertTo-Json -Depth 30)
}

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Safe-Text([object]$Value,[int]$MaxLength=900) {
    $s=[string]$Value
    if(-not $s){return ''}
    if($env:USERPROFILE){$s=[regex]::Replace($s,[regex]::Escape([string]$env:USERPROFILE),'~',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)}
    foreach($pattern in @('(?i)\bghp_[A-Za-z0-9_]{8,}\b','(?i)\bgithub_pat_[A-Za-z0-9_]{8,}\b','(?i)\bsk-[A-Za-z0-9_-]{8,}\b','(?i)(Authorization\s*:\s*Bearer\s+)[^\s''";,]+')){$s=[regex]::Replace($s,$pattern,'[REDACTED]')}
    $s=$s.Replace("`r",' ').Replace("`n",' ')
    if($s.Length -gt $MaxLength){$s=$s.Substring(0,$MaxLength)}
    return $s
}

function Save-State([string]$Status,[string]$ManifestId='',[string]$Detail='',[hashtable]$Extra=$null) {
    $obj=[ordered]@{schema=2;kind='kevin-maintenance-state';version='1.2';at=(Get-Date).ToString('o');status=$Status;manifest_id=$ManifestId;detail=(Safe-Text $Detail)}
    if($Extra){foreach($k in $Extra.Keys){$obj[$k]=$Extra[$k]}}
    Write-JsonAtomic $LatestPath $obj
}

function Invoke-Gh([string[]]$Arguments) {
    $gh=(Get-Command gh -ErrorAction Stop).Source
    $oldGh=[Environment]::GetEnvironmentVariable('GH_TOKEN','Process')
    $oldGithub=[Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    try {
        Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
        Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
        $old=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$out=(& $gh @Arguments 2>&1 | Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
        return [pscustomobject]@{ExitCode=$code;Output=[string]$out}
    }
    finally {
        if($null-ne$oldGh){$env:GH_TOKEN=$oldGh}else{Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue}
        if($null-ne$oldGithub){$env:GITHUB_TOKEN=$oldGithub}else{Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue}
    }
}

function Get-RemoteBytes([string]$RepoPath) {
    if($RepoPath -notmatch '^control-plane/skill-lab/[A-Za-z0-9._-]+\.ps1$'){throw 'remote source path outside typed maintenance roots'}
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.content')
    if($r.ExitCode -ne 0){throw ('remote source fetch failed: '+(Safe-Text $r.Output 400))}
    try{return [Convert]::FromBase64String(([string]$r.Output -replace '\s',''))}catch{throw 'remote source base64 decode failed'}
}

function Get-RemoteManifestText {
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$ManifestRemote),'--jq','.content')
    if($r.ExitCode -ne 0){
        if($r.Output -match '404|Not Found'){return $null}
        throw ('manifest fetch failed: '+(Safe-Text $r.Output 400))
    }
    try{return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$r.Output -replace '\s','')))}catch{throw 'manifest base64 decode failed'}
}

function Read-Attempts {
    if(-not(Test-Path -LiteralPath $AttemptPath -PathType Leaf)){return [pscustomobject]@{schema=1;items=@()}}
    try{return Get-Content -LiteralPath $AttemptPath -Raw|ConvertFrom-Json}catch{return [pscustomobject]@{schema=1;items=@()}}
}

function Get-AttemptRecord([object]$State,[string]$Id) {
    $hits=@($State.items|Where-Object{[string]$_.id -eq $Id})
    if($hits.Count -gt 1){throw 'duplicate maintenance attempt state'}
    if($hits.Count -eq 1){return $hits[0]}
    return $null
}

function Save-Attempt([string]$Id,[int]$Attempts,[string]$Status,[string]$FailureFamily='') {
    $state=Read-Attempts
    $items=@($state.items|Where-Object{[string]$_.id -ne $Id})
    $items+=,[pscustomobject]@{id=$Id;attempts=$Attempts;status=$Status;failure_family=$FailureFamily;updated_at=(Get-Date).ToString('o')}
    Write-JsonAtomic $AttemptPath ([ordered]@{schema=1;kind='kevin-typed-maintenance-attempts';items=$items})
}

function Resolve-Alias([string]$Alias) {
    switch($Alias){
        'skill_lab_runner' { return (Join-Path $Workspace 'kevin-skill-lab.ps1') }
        'ui_bridge_runner' { return (Join-Path $Workspace 'kevin-ui-bridge.ps1') }
        default { throw ('target alias not allowlisted: '+$Alias) }
    }
}

function Assert-CommonTypedManifest([object]$m) {
    if([int]$m.schema -ne 2){throw 'typed manifest schema must be 2'}
    if([string]$m.kind -ne 'kevin-typed-maintenance-manifest'){throw 'typed manifest kind mismatch'}
    if([string]$m.id -notmatch '^[A-Za-z0-9._-]{6,96}$'){throw 'typed manifest id invalid'}
    if([string]$m.authority_class -ne 'GREEN'){throw 'typed maintenance must be GREEN'}
    if([string]$m.authority_delta -ne 'NONE'){throw 'typed maintenance authority_delta must be NONE'}
    if([string]$m.production_effect -ne 'NONE'){throw 'typed maintenance production_effect must be NONE'}
    if([string]$m.owner_policy -ne $OwnerPolicy){throw 'typed maintenance owner policy mismatch'}
    if([bool]$m.preauthorized -ne $true){throw 'typed maintenance must be owner-preauthorized'}
    if($m.expires_at -and (Get-Date) -gt [datetime]$m.expires_at){throw 'typed maintenance manifest expired'}
    $op=[string]$m.operation
    if(-not(@('replace_pinned_file','restart_ui_bridge') -contains $op)){throw ('typed maintenance operation not allowlisted: '+$op)}
}

function Assert-ReplaceManifest([object]$m) {
    if([string]$m.target_alias -ne 'skill_lab_runner'){throw 'replace target alias not allowlisted'}
    if([string]$m.source_path -notmatch '^control-plane/skill-lab/[A-Za-z0-9._-]+\.ps1$'){throw 'replace source path invalid'}
    foreach($name in @('source_sha256','expected_current_sha256','expected_after_sha256')){if([string]$m.$name -notmatch '^[A-Fa-f0-9]{64}$'){throw ($name+' invalid')}}
    if(([string]$m.source_sha256).ToUpperInvariant() -ne ([string]$m.expected_after_sha256).ToUpperInvariant()){throw 'source_sha256 must equal expected_after_sha256'}
}

function Assert-RestartManifest([object]$m) {
    if([string]$m.target_alias -ne 'ui_bridge_runner'){throw 'UI restart target alias mismatch'}
    if([string]$m.expected_current_sha256 -notmatch '^[A-Fa-f0-9]{64}$'){throw 'UI restart expected hash invalid'}
    if([string]$m.task_name -ne 'Kevin UI Bridge v0.3'){throw 'UI restart task name mismatch'}
    if([int]$m.heartbeat_timeout_seconds -lt 5 -or [int]$m.heartbeat_timeout_seconds -gt 30){throw 'UI heartbeat timeout outside 5..30 seconds'}
}

function Assert-Governance {
    $desired=Join-Path $Workspace 'ControlPlane\desired-state-v1.json'
    $owner=Join-Path $Workspace 'ControlPlane\OWNER-AUTHORIZATION-v1.md'
    if(-not(Test-Path -LiteralPath $desired -PathType Leaf)){throw 'typed maintenance governance desired-state missing'}
    if(-not(Test-Path -LiteralPath $owner -PathType Leaf)){throw 'typed maintenance owner authorization missing'}
    $d=Get-Content -LiteralPath $desired -Raw|ConvertFrom-Json
    if(-not[bool]$d.authority.green_only -or [bool]$d.authority.allow_arbitrary_shell -or [bool]$d.authority.allow_authority_expansion -or [bool]$d.authority.allow_novel_production_promotion){throw 'typed maintenance governance denies action'}
    $ot=[IO.File]::ReadAllText($owner)
    if(-not$ot.Contains('apply an owner-preauthorized GREEN maintenance package only through the typed maintenance/reconciliation contract')){throw 'typed maintenance owner preauthorization clause missing'}
}

function Parse-PowerShell([string]$Path) {
    $tokens=$null;$errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    if($errors.Count -gt 0){throw ('PowerShell parser rejected candidate: '+($errors[0].Message))}
}

function Invoke-FixedSelfTest([string]$Path,[string]$ExpectedMarker) {
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path -SelfTest 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code -ne 0){throw ('fixed self-test failed exit='+$code)}
    if($out -notmatch [regex]::Escape($ExpectedMarker)){throw 'fixed self-test marker missing'}
}

function Assert-Benchmark30 {
    $bench=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    $latest=Join-Path $Reports 'benchmark-v1\latest.json'
    if(-not(Test-Path -LiteralPath $bench -PathType Leaf)){throw 'benchmark script missing'}
    $deadline=(Get-Date).AddSeconds(60)
    while($true){
        $started=[DateTime]::UtcNow
        $old=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $bench 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
        if($out -match '(?i)BENCHMARK\s+SKIP_ACTIVE_WORK'){
            if((Get-Date)-ge$deadline){throw 'fresh benchmark active-work retry budget exhausted'}
            Start-Sleep -Seconds 5
            continue
        }
        if($code -ne 0){throw ('fresh benchmark process failed exit='+$code)}
        if(-not(Test-Path -LiteralPath $latest -PathType Leaf)){throw 'fresh benchmark evidence missing'}
        $b=Get-Content -LiteralPath $latest -Raw|ConvertFrom-Json
        if([string]$b.status -ne 'PASS' -or [int]$b.regression.passed -ne 30 -or [int]$b.regression.total -ne 30 -or [int]$b.regression.critical_failures -ne 0){throw 'fresh benchmark not PASS 30/30 critical=0'}
        if((Get-Item -LiteralPath $latest).LastWriteTimeUtc -lt $started.AddSeconds(-3)){throw 'benchmark evidence was not freshly written'}
        return
    }
}

function Install-PinnedFile([object]$m) {
    $target=Resolve-Alias ([string]$m.target_alias)
    $before=Get-Sha $target
    $expectedCurrent=([string]$m.expected_current_sha256).ToUpperInvariant()
    $expectedAfter=([string]$m.expected_after_sha256).ToUpperInvariant()
    if($before -eq $expectedAfter){
        if([string]$m.target_alias -eq 'skill_lab_runner'){Invoke-FixedSelfTest $target 'KEVIN SKILL LAB v1.0.3 SELFTEST PASS'}
        Assert-Benchmark30
        return [ordered]@{changed=$false;before=$before;after=$before;idempotent=$true}
    }
    if($before -ne $expectedCurrent){throw ('expected-current mismatch alias='+[string]$m.target_alias+' actual='+$before)}
    $bytes=Get-RemoteBytes ([string]$m.source_path)
    $stage=Join-Path $StageRoot ([string]$m.id+'.candidate.ps1')
    [IO.File]::WriteAllBytes($stage,$bytes)
    if((Get-Sha $stage) -ne $expectedAfter){throw 'staged source hash mismatch'}
    Parse-PowerShell $stage
    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $backup=Join-Path $backupDir ([IO.Path]::GetFileName($target))
    Copy-Item -LiteralPath $target -Destination $backup -Force
    try {
        $tmp=$target+'.typed-'+[guid]::NewGuid().ToString('N')
        Copy-Item -LiteralPath $stage -Destination $tmp -Force
        Move-Item -LiteralPath $tmp -Destination $target -Force
        if((Get-Sha $target) -ne $expectedAfter){throw 'installed target hash mismatch'}
        if([string]$m.target_alias -eq 'skill_lab_runner'){Invoke-FixedSelfTest $target 'KEVIN SKILL LAB v1.0.3 SELFTEST PASS'}
        Assert-Benchmark30
        return [ordered]@{changed=$true;before=$before;after=(Get-Sha $target);backup=(Safe-Text $backup 500);idempotent=$false}
    }
    catch {
        Copy-Item -LiteralPath $backup -Destination $target -Force
        throw ('replace rollback completed: '+$_.Exception.Message)
    }
}

function Restart-UiBridge([object]$m) {
    if($env:OS -ne 'Windows_NT'){throw 'UI Bridge restart requires Windows host'}
    $target=Resolve-Alias 'ui_bridge_runner'
    $actual=Get-Sha $target
    if($actual -ne ([string]$m.expected_current_sha256).ToUpperInvariant()){throw ('UI Bridge hash mismatch actual='+$actual)}
    $task=Get-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue
    if(-not $task){throw 'UI Bridge scheduled task missing'}
    $heartbeat=Join-Path $Reports 'action-era\ui-bridge\heartbeat.json'
    $started=Get-Date
    try{Stop-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue}catch{}
    Start-ScheduledTask -TaskName ([string]$m.task_name)
    $deadline=(Get-Date).AddSeconds([int]$m.heartbeat_timeout_seconds)
    $fresh=$null
    while((Get-Date)-lt$deadline){
        Start-Sleep -Milliseconds 500
        if(Test-Path -LiteralPath $heartbeat -PathType Leaf){
            try{$h=Get-Content -LiteralPath $heartbeat -Raw|ConvertFrom-Json;if([string]$h.kind -eq 'kevin-ui-bridge-heartbeat' -and [datetime]$h.at -ge $started.AddSeconds(-2) -and [string]$h.state -eq 'READY'){$fresh=$h;break}}catch{}
        }
    }
    if(-not$fresh){throw 'UI Bridge did not produce fresh READY heartbeat after bounded restart'}
    Assert-Benchmark30
    return [ordered]@{changed=$true;hash=$actual;task_name=[string]$m.task_name;heartbeat_at=[string]$fresh.at;state=[string]$fresh.state;session_id=[int]$fresh.session_id}
}

function Process-Typed([object]$m,[bool]$Mutate) {
    Assert-CommonTypedManifest $m
    if([string]$m.operation -eq 'replace_pinned_file'){Assert-ReplaceManifest $m}else{Assert-RestartManifest $m}
    Assert-Governance
    $state=Read-Attempts;$rec=Get-AttemptRecord $state ([string]$m.id);$attempts=if($rec){[int]$rec.attempts}else{0}
    if($rec -and [string]$rec.status -eq 'PROVEN'){Save-State 'ALREADY_APPLIED_PROVEN' ([string]$m.id) 'Typed maintenance was previously proven.' @{attempts=$attempts;operation=[string]$m.operation};return}
    if($attempts -ge $MaxAttempts){Save-State 'BLOCKED_FAILURE_BUDGET' ([string]$m.id) 'Typed maintenance failure budget exhausted.' @{attempts=$attempts;operation=[string]$m.operation};return}
    if(-not$Mutate){Save-State 'TYPED_VALIDATED_PREAUTHORIZED' ([string]$m.id) 'Typed GREEN maintenance validated; mutation disabled for this invocation.' @{attempts=$attempts;operation=[string]$m.operation};return}
    $attempts++
    try {
        $result=if([string]$m.operation -eq 'replace_pinned_file'){Install-PinnedFile $m}else{Restart-UiBridge $m}
        Save-Attempt ([string]$m.id) $attempts 'PROVEN' ''
        Save-State 'APPLIED_PREAUTHORIZED_PROVEN' ([string]$m.id) 'Typed GREEN maintenance applied and independently verified.' @{attempts=$attempts;operation=[string]$m.operation;result=$result}
    }
    catch {
        $family=if([string]$m.operation -eq 'replace_pinned_file'){'typed_replace_failure'}else{'ui_bridge_restart_failure'}
        Save-Attempt ([string]$m.id) $attempts 'FAILED' $family
        Save-State 'APPLY_FAILED' ([string]$m.id) $_.Exception.Message @{attempts=$attempts;operation=[string]$m.operation;failure_family=$family}
        throw
    }
}

function Legacy-Stage([string]$ManifestText,[bool]$Apply) {
    # Preserve v1 bootstrap behavior only. Legacy executable packages never auto-apply.
    $m=$ManifestText|ConvertFrom-Json
    if([int]$m.schema-ne1-or[string]$m.kind-ne'kevin-maintenance-manifest'){throw 'legacy manifest invalid'}
    if([string]$m.authority_class-ne'GREEN'-or[string]$m.production_effect-ne'NONE'-or[string]$m.authority_delta-ne'NONE'-or[bool]$m.requires_owner_approval-ne$true){throw 'legacy manifest authority contract invalid'}
    if([string]$m.payload_path -notmatch '^inbox/maintenance/packages/[A-Za-z0-9._-]+\.ps1$'){throw 'legacy payload path invalid'}
    if([string]$m.payload_sha256 -notmatch '^[A-Fa-f0-9]{64}$'){throw 'legacy payload hash invalid'}
    if(-not$Apply){Save-State 'LEGACY_STAGED_APPROVAL_REQUIRED' ([string]$m.id) 'Legacy executable maintenance remains explicit ApplyOnce only.';return}
    throw 'v1.2 refuses to execute legacy PowerShell packages. Bootstrap legacy ApplyOnce must be performed by v1.1d before v1.2 installation.'
}

function Invoke-SelfTest {
    $good=[pscustomobject]@{schema=2;kind='kevin-typed-maintenance-manifest';id='selftest-replace-001';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='replace_pinned_file';target_alias='skill_lab_runner';source_path='control-plane/skill-lab/kevin-skill-lab-v1.0.3.ps1';source_sha256=('A'*64);expected_current_sha256=('B'*64);expected_after_sha256=('A'*64);expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-CommonTypedManifest $good;Assert-ReplaceManifest $good
    $bad=($good|ConvertTo-Json -Depth 10|ConvertFrom-Json);$bad.operation='shell';$blocked=$false;try{Assert-CommonTypedManifest $bad}catch{$blocked=$true};if(-not$blocked){throw 'arbitrary operation negative self-test failed'}
    $bad2=($good|ConvertTo-Json -Depth 10|ConvertFrom-Json);$bad2.target_alias='supervisor';$blocked=$false;try{Assert-ReplaceManifest $bad2}catch{$blocked=$true};if(-not$blocked){throw 'unallowlisted target negative self-test failed'}
    $bad3=($good|ConvertTo-Json -Depth 10|ConvertFrom-Json);$bad3.authority_delta='ADD';$blocked=$false;try{Assert-CommonTypedManifest $bad3}catch{$blocked=$true};if(-not$blocked){throw 'authority expansion negative self-test failed'}
    $ui=[pscustomobject]@{schema=2;kind='kevin-typed-maintenance-manifest';id='selftest-ui-001';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='restart_ui_bridge';target_alias='ui_bridge_runner';expected_current_sha256=('C'*64);task_name='Kevin UI Bridge v0.3';heartbeat_timeout_seconds=15;expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-CommonTypedManifest $ui;Assert-RestartManifest $ui
    Write-Host 'KEVIN MAINTENANCE v1.2 SELFTEST PASS typed_ops=2 legacy_autoapply=false arbitrary_shell=false authority_expansion=false max_attempts=3'
}

if($SelfTest){Invoke-SelfTest;exit 0}

try {
    $text=Get-RemoteManifestText
    if($null-eq$text){Save-State 'NO_MANIFEST' '' 'No maintenance proposal is waiting.';exit 0}
    $m=$text|ConvertFrom-Json
    if([int]$m.schema -eq 2 -and [string]$m.kind -eq 'kevin-typed-maintenance-manifest'){
        # Compatibility behavior: the existing v1.1d cron still calls -CheckOnly.
        # For schema-2 typed GREEN manifests, owner policy explicitly preauthorizes
        # these fixed operations; therefore the reconciler may mutate automatically.
        $mutate=$true
        if($ApplyOnce){$mutate=$true}
        Process-Typed $m $mutate
        exit 0
    }
    Legacy-Stage $text ([bool]$ApplyOnce)
    exit 0
}
catch {
    if(-not(Test-Path -LiteralPath $LatestPath -PathType Leaf) -or (Get-Content $LatestPath -Raw) -notmatch 'APPLY_FAILED'){
        Save-State 'ERROR' '' $_.Exception.Message
    }
    Write-Host ('MAINTENANCE ERROR '+(Safe-Text $_.Exception.Message 600))
    exit 1
}
