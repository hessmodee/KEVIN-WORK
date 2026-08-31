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
function Safe-Text([object]$Value,[int]$MaxLength = 900) {
    $s = [string]$Value
    if (-not $s) { return '' }
    if ($env:USERPROFILE) {
        $s = [regex]::Replace($s,[regex]::Escape([string]$env:USERPROFILE),'~',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    foreach ($pattern in @(
        '(?i)\bghp_[A-Za-z0-9_]{8,}\b',
        '(?i)\bgithub_pat_[A-Za-z0-9_]{8,}\b',
        '(?i)\bsk-[A-Za-z0-9_-]{8,}\b',
        '(?i)(Authorization\s*:\s*Bearer\s+)[^\s''";,]+'
    )) {
        $s = [regex]::Replace($s,$pattern,'[REDACTED]')
    }
    $s = $s.Replace("`r",' ').Replace("`n",' ')
    if ($s.Length -gt $MaxLength) { $s = $s.Substring(0,$MaxLength) }
    return $s
}
function Save-State([string]$Status,[string]$ManifestId = '',[string]$Detail = '',[hashtable]$Extra = $null) {
    $obj = [ordered]@{
        schema = 3
        kind = 'kevin-maintenance-state'
        version = '1.3.1'
        at = (Get-Date).ToString('o')
        status = $Status
        manifest_id = $ManifestId
        detail = (Safe-Text $Detail)
    }
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
        $env:GH_PROMPT_DISABLED = '1'
        $old = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $out = (& $gh @Arguments 2>&1 | Out-String).Trim()
            $code = [int]$LASTEXITCODE
        }
        finally { $ErrorActionPreference = $old }
        return [pscustomobject]@{ ExitCode = $code; Output = [string]$out }
    }
    finally {
        if ($null -ne $oldGh) { $env:GH_TOKEN = $oldGh } else { Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue }
        if ($null -ne $oldGithub) { $env:GITHUB_TOKEN = $oldGithub } else { Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue }
    }
}
function Get-RemoteManifestText {
    $r = Invoke-Gh @('api',('repos/' + $Repo + '/contents/' + $ManifestRemote),'--jq','.content')
    if ($r.ExitCode -ne 0) {
        if ($r.Output -match '404|Not Found') { return $null }
        throw ('manifest fetch failed: ' + (Safe-Text $r.Output 400))
    }
    try { return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$r.Output -replace '\s',''))) }
    catch { throw 'manifest base64 decode failed' }
}

function Get-AliasSpec([string]$Alias) {
    switch ($Alias) {
        'maintenance_runner' {
            return [pscustomobject]@{
                Target = (Join-Path $Workspace 'kevin-maintenance-runner.ps1')
                Source = '^control-plane/maintenance/kevin-maintenance-runner-v[0-9._-]+\.ps1$'
                SelfTestArgs = @('-SelfTest')
                Marker = 'KEVIN MAINTENANCE v1.3.1 SELFTEST PASS'
            }
        }
        'work_order_intake' {
            return [pscustomobject]@{
                Target = (Join-Path $Workspace 'ControlPlane\kevin-work-order-intake-v0.1.ps1')
                Source = '^control-plane/intake/kevin-work-order-intake-v[0-9._-]+\.ps1$'
                SelfTestArgs = @('-Mode','SelfTest')
                Marker = 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS'
            }
        }
        'skill_lab_runner' {
            return [pscustomobject]@{
                Target = (Join-Path $Workspace 'kevin-skill-lab.ps1')
                Source = '^control-plane/skill-lab/kevin-skill-lab-v[0-9._-]+\.ps1$'
                SelfTestArgs = @('-SelfTest')
                Marker = 'KEVIN SKILL LAB v1.0.3 SELFTEST PASS'
            }
        }
        'ui_bridge_runner' {
            return [pscustomobject]@{
                Target = (Join-Path $Workspace 'kevin-ui-bridge.ps1')
                Source = ''
                SelfTestArgs = @('-SelfTest')
                Marker = ''
            }
        }
        default { throw ('target alias not allowlisted: ' + $Alias) }
    }
}
function Get-RemoteBytes([string]$RepoPath,[string]$Alias) {
    $spec = Get-AliasSpec $Alias
    if (-not $spec.Source -or $RepoPath -notmatch $spec.Source) { throw 'remote source path outside alias root' }
    $r = Invoke-Gh @('api',('repos/' + $Repo + '/contents/' + $RepoPath),'--jq','.content')
    if ($r.ExitCode -ne 0) { throw ('remote source fetch failed: ' + (Safe-Text $r.Output 400)) }
    try { return [Convert]::FromBase64String(([string]$r.Output -replace '\s','')) }
    catch { throw 'remote source base64 decode failed' }
}

function Read-Attempts {
    if (-not (Test-Path -LiteralPath $AttemptPath -PathType Leaf)) { return [pscustomobject]@{ schema = 1; items = @() } }
    try { return Get-Content -LiteralPath $AttemptPath -Raw | ConvertFrom-Json }
    catch { return [pscustomobject]@{ schema = 1; items = @() } }
}
function Get-AttemptRecord([object]$State,[string]$Id) {
    $hits = @($State.items | Where-Object { [string]$_.id -eq $Id })
    if ($hits.Count -gt 1) { throw 'duplicate maintenance attempt state' }
    if ($hits.Count -eq 1) { return $hits[0] }
    return $null
}
function Save-Attempt([string]$Id,[int]$Attempts,[string]$Status,[string]$FailureFamily = '') {
    $state = Read-Attempts
    $items = @($state.items | Where-Object { [string]$_.id -ne $Id })
    $items += ,[pscustomobject]@{
        id = $Id
        attempts = $Attempts
        status = $Status
        failure_family = $FailureFamily
        updated_at = (Get-Date).ToString('o')
    }
    Write-JsonAtomic $AttemptPath ([ordered]@{ schema = 1; kind = 'kevin-typed-maintenance-attempts'; items = $items })
}

function Assert-Common([object]$m) {
    if ([int]$m.schema -ne 3) { throw 'manifest schema must be 3' }
    if ([string]$m.kind -ne 'kevin-self-maintenance-manifest') { throw 'manifest kind mismatch' }
    if ([string]$m.id -notmatch '^[A-Za-z0-9._-]{6,96}$') { throw 'manifest id invalid' }
    if ([string]$m.authority_class -ne 'GREEN') { throw 'maintenance must be GREEN' }
    if ([string]$m.authority_delta -ne 'NONE') { throw 'authority_delta must be NONE' }
    if ([string]$m.production_effect -ne 'NONE') { throw 'production_effect must be NONE' }
    if ([string]$m.owner_policy -ne $OwnerPolicy) { throw 'owner policy mismatch' }
    if ([bool]$m.preauthorized -ne $true) { throw 'manifest must be preauthorized' }
    if ($m.expires_at -and (Get-Date) -gt [datetime]$m.expires_at) { throw 'manifest expired' }
    if (-not (@('replace_pinned_component','restart_ui_bridge') -contains [string]$m.operation)) { throw 'operation not allowlisted' }
}
function Assert-Replace([object]$m) {
    $spec = Get-AliasSpec ([string]$m.target_alias)
    if ([string]$m.target_alias -eq 'ui_bridge_runner') { throw 'UI Bridge cannot use replace operation' }
    if ([string]$m.source_path -notmatch $spec.Source) { throw 'source path outside alias root' }
    foreach ($n in @('source_sha256','expected_current_sha256','expected_after_sha256')) {
        if ([string]$m.$n -notmatch '^[A-Fa-f0-9]{64}$') { throw ($n + ' invalid') }
    }
    if (([string]$m.source_sha256).ToUpperInvariant() -ne ([string]$m.expected_after_sha256).ToUpperInvariant()) { throw 'source hash must equal after hash' }
}
function Assert-Restart([object]$m) {
    if ([string]$m.target_alias -ne 'ui_bridge_runner') { throw 'UI restart target alias mismatch' }
    if ([string]$m.expected_current_sha256 -notmatch '^[A-Fa-f0-9]{64}$') { throw 'UI restart expected hash invalid' }
    if ([string]$m.task_name -ne 'Kevin UI Bridge v0.3') { throw 'UI restart task name mismatch' }
    if ([int]$m.heartbeat_timeout_seconds -lt 5 -or [int]$m.heartbeat_timeout_seconds -gt 30) { throw 'UI heartbeat timeout outside 5..30 seconds' }
}
function Assert-Governance {
    $desired = Join-Path $Workspace 'ControlPlane\desired-state-v1.json'
    $owner = Join-Path $Workspace 'ControlPlane\OWNER-AUTHORIZATION-v1.md'
    if (-not (Test-Path -LiteralPath $desired -PathType Leaf) -or -not (Test-Path -LiteralPath $owner -PathType Leaf)) { throw 'governance roots missing' }
    $d = Get-Content -LiteralPath $desired -Raw | ConvertFrom-Json
    if (-not [bool]$d.authority.green_only -or [bool]$d.authority.allow_arbitrary_shell -or [bool]$d.authority.allow_authority_expansion -or [bool]$d.authority.allow_novel_production_promotion) { throw 'governance denies action' }
    $ot = [IO.File]::ReadAllText($owner)
    if (-not $ot.Contains('apply an owner-preauthorized GREEN maintenance package only through the typed maintenance/reconciliation contract')) { throw 'owner preauthorization clause missing' }
}
function Parse-PowerShell([string]$Path) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    if ($errors.Count -gt 0) { throw ('PowerShell parser rejected candidate: ' + $errors[0].Message) }
}
function Invoke-FixedSelfTest([string]$Alias,[string]$Path) {
    $spec = Get-AliasSpec $Alias
    $args = @($spec.SelfTestArgs)
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path @args 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    }
    finally { $ErrorActionPreference = $old }
    if ($code -ne 0) { throw ('fixed self-test failed exit=' + $code) }
    if ($out -notmatch [regex]::Escape([string]$spec.Marker)) { throw 'fixed self-test marker missing' }
}
function Assert-Benchmark30 {
    $bench = Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    $latest = Join-Path $Reports 'benchmark-v1\latest.json'
    if (-not (Test-Path -LiteralPath $bench -PathType Leaf)) { throw 'benchmark script missing' }
    $deadline = (Get-Date).AddSeconds(60)
    while ($true) {
        $started = [DateTime]::UtcNow
        $old = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $bench 2>&1 | Out-String).Trim()
            $code = [int]$LASTEXITCODE
        }
        finally { $ErrorActionPreference = $old }
        if ($out -match '(?i)BENCHMARK\s+SKIP_ACTIVE_WORK') {
            if ((Get-Date) -ge $deadline) { throw 'fresh benchmark retry budget exhausted' }
            Start-Sleep 5
            continue
        }
        if ($code -ne 0) { throw ('benchmark failed exit=' + $code) }
        if (-not (Test-Path -LiteralPath $latest)) { throw 'benchmark evidence missing' }
        $b = Get-Content $latest -Raw | ConvertFrom-Json
        if ([string]$b.status -ne 'PASS' -or [int]$b.regression.passed -ne 30 -or [int]$b.regression.total -ne 30 -or [int]$b.regression.critical_failures -ne 0) { throw 'benchmark not 30/30 critical=0' }
        if ((Get-Item $latest).LastWriteTimeUtc -lt $started.AddSeconds(-3)) { throw 'benchmark evidence not fresh' }
        return
    }
}

function New-InstallResult([bool]$Changed,[string]$Before,[string]$After,[bool]$Idempotent,[string]$Backup = '') {
    $result = [ordered]@{
        changed = $Changed
        before = $Before
        after = $After
        idempotent = $Idempotent
    }
    if ($Backup) { $result['backup'] = $Backup }
    return $result
}
function New-RestartResult([string]$Hash,[string]$TaskName,[string]$HeartbeatAt,[string]$State) {
    return [ordered]@{
        changed = $true
        hash = $Hash
        task_name = $TaskName
        heartbeat_at = $HeartbeatAt
        state = $State
    }
}
function Install-Pinned([object]$m) {
    $alias = [string]$m.target_alias
    $spec = Get-AliasSpec $alias
    $target = [string]$spec.Target
    $before = Get-Sha $target
    $cur = ([string]$m.expected_current_sha256).ToUpperInvariant()
    $after = ([string]$m.expected_after_sha256).ToUpperInvariant()
    if ($before -eq $after) {
        Invoke-FixedSelfTest $alias $target
        Assert-Benchmark30
        return (New-InstallResult $false $before $before $true)
    }
    if ($before -ne $cur) { throw ('expected-current mismatch alias=' + $alias + ' actual=' + $before) }
    $bytes = Get-RemoteBytes ([string]$m.source_path) $alias
    $stage = Join-Path $StageRoot ([string]$m.id + '.candidate.ps1')
    [IO.File]::WriteAllBytes($stage,$bytes)
    if ((Get-Sha $stage) -ne $after) { throw 'staged source hash mismatch' }
    Parse-PowerShell $stage
    Invoke-FixedSelfTest $alias $stage
    $backupDir = Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir | Out-Null
    $backup = Join-Path $backupDir ([IO.Path]::GetFileName($target))
    Copy-Item -LiteralPath $target -Destination $backup -Force
    try {
        $tmp = $target + '.typed-' + [guid]::NewGuid().ToString('N')
        Copy-Item $stage $tmp -Force
        Move-Item $tmp $target -Force
        if ((Get-Sha $target) -ne $after) { throw 'installed target hash mismatch' }
        Invoke-FixedSelfTest $alias $target
        Assert-Benchmark30
        return (New-InstallResult $true $before (Get-Sha $target) $false (Safe-Text $backup 500))
    }
    catch {
        Copy-Item $backup $target -Force
        throw ('replace rollback completed: ' + $_.Exception.Message)
    }
}
function Restart-UiBridge([object]$m) {
    if ($env:OS -ne 'Windows_NT') { throw 'UI restart requires Windows' }
    $spec = Get-AliasSpec 'ui_bridge_runner'
    $actual = Get-Sha $spec.Target
    if ($actual -ne ([string]$m.expected_current_sha256).ToUpperInvariant()) { throw ('UI Bridge hash mismatch actual=' + $actual) }
    $task = Get-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue
    if (-not $task) { throw 'UI Bridge task missing' }
    $heartbeat = Join-Path $Reports 'action-era\ui-bridge\heartbeat.json'
    $started = Get-Date
    try { Stop-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue } catch {}
    Start-ScheduledTask -TaskName ([string]$m.task_name)
    $deadline = (Get-Date).AddSeconds([int]$m.heartbeat_timeout_seconds)
    $fresh = $null
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if (Test-Path $heartbeat) {
            try {
                $h = Get-Content $heartbeat -Raw | ConvertFrom-Json
                if ([string]$h.kind -eq 'kevin-ui-bridge-heartbeat' -and [datetime]$h.at -ge $started.AddSeconds(-2) -and [string]$h.state -eq 'READY') {
                    $fresh = $h
                    break
                }
            }
            catch {}
        }
    }
    if (-not $fresh) { throw 'UI Bridge did not produce fresh READY heartbeat' }
    Assert-Benchmark30
    return (New-RestartResult $actual ([string]$m.task_name) ([string]$fresh.at) ([string]$fresh.state))
}

function Process-Typed([object]$m) {
    Assert-Common $m
    if ([string]$m.operation -eq 'replace_pinned_component') { Assert-Replace $m } else { Assert-Restart $m }
    Assert-Governance
    $state = Read-Attempts
    $rec = Get-AttemptRecord $state ([string]$m.id)
    $attempts = if ($rec) { [int]$rec.attempts } else { 0 }
    if ($rec -and [string]$rec.status -eq 'PROVEN') {
        Save-State 'ALREADY_APPLIED_PROVEN' ([string]$m.id) 'Maintenance previously proven.' @{ attempts = $attempts }
        return
    }
    if ($attempts -ge $MaxAttempts) {
        Save-State 'BLOCKED_FAILURE_BUDGET' ([string]$m.id) 'Failure budget exhausted.' @{ attempts = $attempts }
        return
    }
    $attempts++
    try {
        $result = if ([string]$m.operation -eq 'replace_pinned_component') { Install-Pinned $m } else { Restart-UiBridge $m }
        Save-Attempt ([string]$m.id) $attempts 'PROVEN'
        Save-State 'APPLIED_PREAUTHORIZED_PROVEN' ([string]$m.id) 'Applied and independently verified.' @{ attempts = $attempts; operation = [string]$m.operation; result = $result }
    }
    catch {
        $family = if ([string]$m.operation -eq 'replace_pinned_component') { 'typed_replace_failure' } else { 'ui_bridge_restart_failure' }
        Save-Attempt ([string]$m.id) $attempts 'FAILED' $family
        Save-State 'APPLY_FAILED' ([string]$m.id) $_.Exception.Message @{ attempts = $attempts; failure_family = $family }
        throw
    }
}

function Legacy-Stage([string]$Text,[bool]$Apply) {
    $m = $Text | ConvertFrom-Json
    if ([int]$m.schema -ne 1 -or [string]$m.kind -ne 'kevin-maintenance-manifest') { throw 'legacy manifest invalid' }
    if (-not $Apply) {
        Save-State 'LEGACY_STAGED_APPROVAL_REQUIRED' ([string]$m.id) 'Legacy executable package requires one-time ApplyOnce.'
        return
    }
    throw 'v1.3.1 never executes legacy executable maintenance packages'
}
function Invoke-SelfTest {
    $base = [pscustomobject]@{
        schema = 3
        kind = 'kevin-self-maintenance-manifest'
        id = 'selftest-maint-001'
        authority_class = 'GREEN'
        authority_delta = 'NONE'
        production_effect = 'NONE'
        owner_policy = $OwnerPolicy
        preauthorized = $true
        operation = 'replace_pinned_component'
        target_alias = 'maintenance_runner'
        source_path = 'control-plane/maintenance/kevin-maintenance-runner-v1.3.1.ps1'
        source_sha256 = ('A' * 64)
        expected_current_sha256 = ('B' * 64)
        expected_after_sha256 = ('A' * 64)
        expires_at = (Get-Date).AddMinutes(10).ToString('o')
    }
    Assert-Common $base
    Assert-Replace $base
    foreach ($case in @(
        @('work_order_intake','control-plane/intake/kevin-work-order-intake-v1.2.2.ps1'),
        @('skill_lab_runner','control-plane/skill-lab/kevin-skill-lab-v1.0.4.ps1')
    )) {
        $x = $base | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $x.target_alias = $case[0]
        $x.source_path = $case[1]
        Assert-Replace $x
    }
    $installProbe = New-InstallResult $false ('A' * 64) ('A' * 64) $true
    if (-not [bool]$installProbe.idempotent -or [bool]$installProbe.changed) { throw 'install result factory runtime invariant' }
    $restartProbe = New-RestartResult ('B' * 64) 'Kevin UI Bridge v0.3' '2026-01-01T00:00:00Z' 'READY'
    if ([string]$restartProbe.state -ne 'READY' -or -not [bool]$restartProbe.changed) { throw 'restart result factory runtime invariant' }
    $bad = $base | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $bad.target_alias = 'supervisor'
    $blocked = $false
    try { Assert-Replace $bad } catch { $blocked = $true }
    if (-not $blocked) { throw 'unknown alias accepted' }
    $bad = $base | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $bad.operation = 'shell'
    $blocked = $false
    try { Assert-Common $bad } catch { $blocked = $true }
    if (-not $blocked) { throw 'arbitrary operation accepted' }
    Write-Host 'KEVIN MAINTENANCE v1.3.1 SELFTEST PASS aliases=3 ui_restart=1 result_factories=true legacy_autoapply=false arbitrary_shell=false authority_expansion=false max_attempts=3'
}

if ($SelfTest) { Invoke-SelfTest; exit 0 }
try {
    $text = Get-RemoteManifestText
    if ($null -eq $text) {
        Save-State 'NO_MANIFEST' '' 'No maintenance proposal is waiting.'
        exit 0
    }
    $m = $text | ConvertFrom-Json
    if ([int]$m.schema -eq 3 -and [string]$m.kind -eq 'kevin-self-maintenance-manifest') {
        Process-Typed $m
        exit 0
    }
    if ([int]$m.schema -eq 2 -and [string]$m.kind -eq 'kevin-typed-maintenance-manifest') {
        Save-State 'SCHEMA2_NEEDS_MIGRATION' ([string]$m.id) 'v1.3.1 requires schema-3 aliases for self-maintenance transport.'
        exit 0
    }
    Legacy-Stage $text ([bool]$ApplyOnce)
    exit 0
}
catch {
    if (-not (Test-Path $LatestPath) -or (Get-Content $LatestPath -Raw) -notmatch 'APPLY_FAILED') {
        Save-State 'ERROR' '' $_.Exception.Message
    }
    Write-Host ('MAINTENANCE ERROR ' + (Safe-Text $_.Exception.Message 600))
    exit 1
}
