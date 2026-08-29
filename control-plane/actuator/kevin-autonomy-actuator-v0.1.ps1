param(
    [ValidateSet('Audit','Reconcile','SelfTest')]
    [string]$Mode = 'Reconcile'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$Workspace = Join-Path $env:USERPROFILE '.openclaw\workspace'
$Root = Join-Path $Workspace 'ControlPlane'
$Reports = Join-Path $Workspace 'reports'
if (-not (Test-Path -LiteralPath $Reports)) { $Reports = Join-Path $Workspace 'Reports' }
$DesiredPath = Join-Path $Root 'desired-state-v1.json'
$OwnerAuthPath = Join-Path $Root 'OWNER-AUTHORIZATION-v1.md'
$StateDir = Join-Path $Root 'State'
$EvidenceDir = Join-Path $Root 'Evidence'
$QueueDir = Join-Path $Root 'Queue'
$StatePath = Join-Path $StateDir 'reconciler-state-v1.json'
$LatestEvidencePath = Join-Path $Reports 'autonomy-latest.json'
$QueuePath = Join-Path $QueueDir 'mission-queue-v1.json'

foreach ($d in @($Root,$StateDir,$EvidenceDir,$QueueDir,$Reports)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Write-JsonAtomic {
    param([Parameter(Mandatory=$true)]$Object,[Parameter(Mandatory=$true)][string]$Path)
    $tmp = "$Path.tmp-$PID"
    $json = $Object | ConvertTo-Json -Depth 30
    [System.IO.File]::WriteAllText($tmp, $json, (New-Object System.Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Get-Sha256Text {
    param([Parameter(Mandatory=$true)][string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')
    } finally { $sha.Dispose() }
}

function Get-OpenClawLauncher {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command node -ErrorAction SilentlyContinue }
    $shim = Get-Command openclaw.cmd -ErrorAction SilentlyContinue
    if (-not $shim) { $shim = Get-Command openclaw -ErrorAction SilentlyContinue }
    if (-not $shim) { throw 'OpenClaw CLI not found in PATH.' }

    if ($node) {
        $shimDir = Split-Path -Parent $shim.Source
        $pkgDir = Join-Path $shimDir 'node_modules\openclaw'
        $pkgJson = Join-Path $pkgDir 'package.json'
        if (Test-Path -LiteralPath $pkgJson) {
            try {
                $pkg = Get-Content -LiteralPath $pkgJson -Raw | ConvertFrom-Json
                $binRel = $null
                if ($pkg.bin -is [string]) { $binRel = [string]$pkg.bin }
                elseif ($pkg.bin -and $pkg.bin.openclaw) { $binRel = [string]$pkg.bin.openclaw }
                if ($binRel) {
                    $cli = Join-Path $pkgDir $binRel
                    if (Test-Path -LiteralPath $cli) {
                        return [pscustomobject]@{ Kind='node'; Executable=$node.Source; Cli=$cli }
                    }
                }
            } catch { }
        }
    }
    return [pscustomobject]@{ Kind='shim'; Executable=$shim.Source; Cli=$null }
}

$script:OpenClawLauncher = $null
function Invoke-OpenClawRaw {
    param([Parameter(Mandatory=$true)][string[]]$Args)
    if (-not $script:OpenClawLauncher) { $script:OpenClawLauncher = Get-OpenClawLauncher }
    $errFile = Join-Path $env:TEMP ("kevin-openclaw-stderr-{0}-{1}.txt" -f $PID,[guid]::NewGuid().ToString('N'))
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($script:OpenClawLauncher.Kind -eq 'node') {
            $outLines = & $script:OpenClawLauncher.Executable $script:OpenClawLauncher.Cli @Args 2> $errFile
        } else {
            $outLines = & $script:OpenClawLauncher.Executable @Args 2> $errFile
        }
        $exit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldEap
    }
    $stderr = ''
    if (Test-Path -LiteralPath $errFile) {
        $stderr = Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
    }
    $stdout = (($outLines | ForEach-Object { [string]$_ }) -join "`n")
    return [pscustomobject]@{ ExitCode=$exit; Stdout=$stdout; Stderr=$stderr }
}

function Invoke-OpenClawJson {
    param([Parameter(Mandatory=$true)][string[]]$Args)
    $r = Invoke-OpenClawRaw -Args $Args
    if ($r.ExitCode -ne 0) { throw "OpenClaw command failed ($($r.ExitCode)): $($Args -join ' ') :: $($r.Stderr)" }
    if ([string]::IsNullOrWhiteSpace($r.Stdout)) { return $null }
    try { return ($r.Stdout | ConvertFrom-Json) }
    catch { throw "OpenClaw returned non-JSON output for: $($Args -join ' ')" }
}

function Read-JsonFile {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try { return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json) }
    catch { return $null }
}

function Get-SupportSnapshot {
    $p = Join-Path $Reports 'support-latest.json'
    return [pscustomobject]@{ Path=$p; Data=(Read-JsonFile -Path $p) }
}

function Get-DashboardSnapshot {
    $p = Join-Path $Reports 'dashboard-state.json'
    return [pscustomobject]@{ Path=$p; Data=(Read-JsonFile -Path $p) }
}

function Get-LiveJobs {
    $obj = Invoke-OpenClawJson -Args @('cron','list','--all','--json')
    if ($null -eq $obj) { return @() }
    if ($obj.PSObject.Properties.Name -contains 'jobs') { return @($obj.jobs) }
    return @($obj)
}

function Find-SnapshotJob {
    param($Support,[string]$DeclarationKey,[string]$Name)
    if (-not $Support -or -not $Support.cron -or -not $Support.cron.jobs) { return $null }
    foreach ($j in @($Support.cron.jobs)) {
        if (($j.declaration_key -eq $DeclarationKey) -or ($j.name -eq $Name)) { return $j }
    }
    return $null
}

function Find-LiveJob {
    param($LiveJobs,$SnapshotJob,[string]$Name)
    foreach ($j in @($LiveJobs)) {
        if ($SnapshotJob -and $j.id -eq $SnapshotJob.id) { return $j }
        if ($j.name -eq $Name) { return $j }
    }
    return $null
}

function Get-ReconcilerState {
    $s = Read-JsonFile -Path $StatePath
    if ($s) { return $s }
    return [pscustomobject]@{
        schema = 1
        failure_family = ''
        fingerprint = ''
        attempts = 0
        cooldown_until = $null
        queue_index = 0
        last_action = ''
        last_result = ''
        updated_at = (Get-Date).ToString('o')
    }
}

function Save-ReconcilerState { param($State) $State.updated_at=(Get-Date).ToString('o'); Write-JsonAtomic -Object $State -Path $StatePath }

function Add-Drift {
    param([System.Collections.ArrayList]$List,[string]$Family,[string]$Severity,[string]$Detail,[string]$Verb,[string]$Target)
    [void]$List.Add([pscustomobject]@{ family=$Family; severity=$Severity; detail=$Detail; verb=$Verb; target=$Target })
}

function Test-DesiredState {
    param($Desired,$Support,$Dashboard)
    $drift = New-Object System.Collections.ArrayList
    if (-not $Support) {
        Add-Drift $drift 'support_snapshot_missing' 'repair' 'support-latest.json is missing or invalid.' 'run_support_bridge' 'kevin-support-bridge-v1'
        return @($drift)
    }

    if ($Desired.health_contract.governance_must_be_ok -and (-not $Support.governance.ok)) {
        Add-Drift $drift 'governance_failed' 'review' 'Owner/governance contract is not healthy.' '' ''
    }

    foreach ($p in $Desired.core_hashes.PSObject.Properties) {
        $actual = ''
        if ($Support.hashes -and ($Support.hashes.PSObject.Properties.Name -contains $p.Name)) { $actual = [string]$Support.hashes.$($p.Name) }
        if ($actual -ne [string]$p.Value) {
            Add-Drift $drift ("core_hash_"+$p.Name) 'review' ("Pinned hash mismatch for {0}." -f $p.Name) '' $p.Name
        }
    }

    $snapTime = $null
    try { $snapTime = [DateTimeOffset]::Parse([string]$Support.generated_at) } catch { }
    if (-not $snapTime) {
        Add-Drift $drift 'support_snapshot_time_invalid' 'repair' 'Support snapshot timestamp is invalid.' 'run_support_bridge' 'kevin-support-bridge-v1'
    } else {
        $ageMin = ([DateTimeOffset]::Now - $snapTime).TotalMinutes
        if ($ageMin -gt [double]$Desired.health_contract.support_snapshot_max_age_minutes) {
            Add-Drift $drift 'support_snapshot_stale' 'repair' ("Support snapshot is {0:N1} minutes old." -f $ageMin) 'run_support_bridge' 'kevin-support-bridge-v1'
        }
    }

    foreach ($expected in @($Desired.required_automations)) {
        $sj = Find-SnapshotJob -Support $Support -DeclarationKey $expected.declaration_key -Name $expected.name
        if (-not $sj) {
            Add-Drift $drift ("automation_missing_"+$expected.declaration_key) 'review' ("Expected automation not present in fresh Support Bridge snapshot: {0}" -f $expected.name) '' $expected.declaration_key
            continue
        }
        if ($expected.must_be_enabled -and (-not [bool]$sj.enabled)) {
            Add-Drift $drift ("automation_disabled_"+$expected.declaration_key) 'repair' ("Expected automation is disabled: {0}" -f $expected.name) 'enable_expected_automation' $expected.declaration_key
        }
    }

    if ([string]$Support.benchmark.status -ne [string]$Desired.health_contract.benchmark_required_status) {
        Add-Drift $drift 'benchmark_not_pass' 'repair' ("Benchmark status is {0}, expected {1}." -f $Support.benchmark.status,$Desired.health_contract.benchmark_required_status) 'run_benchmark' 'kevin-benchmark-v1'
    }

    if ($Dashboard -and $Dashboard.health -and ([string]$Dashboard.health.overall -ne 'healthy')) {
        Add-Drift $drift 'dashboard_health_not_healthy' 'review' ("Dashboard overall health is {0}." -f $Dashboard.health.overall) '' 'dashboard'
    }
    return @($drift)
}

function Get-Fingerprint {
    param($Drift)
    $items = @($Drift)
    if ($items.Count -eq 0) {
        $semantic = 'NO_DRIFT'
    } else {
        $semantic = @($items | ForEach-Object { "{0}|{1}|{2}|{3}" -f $_.family,$_.severity,$_.verb,$_.target }) -join "`n"
    }
    return Get-Sha256Text -Text $semantic
}

function Get-JobIdentity {
    param($Support,$LiveJobs,[string]$DeclarationKey,[string]$Name)
    $sj = Find-SnapshotJob -Support $Support -DeclarationKey $DeclarationKey -Name $Name
    $lj = Find-LiveJob -LiveJobs $LiveJobs -SnapshotJob $sj -Name $Name
    if ($lj) { return [pscustomobject]@{ id=[string]$lj.id; name=[string]$lj.name } }
    if ($sj) { return [pscustomobject]@{ id=[string]$sj.id; name=[string]$sj.name } }
    return $null
}

function Run-And-VerifyJob {
    param([string]$JobId,[int]$WaitMinutes=5)
    $started = [DateTimeOffset]::Now
    $null = Invoke-OpenClawJson -Args @('cron','run',$JobId,'--wait','--wait-timeout',("{0}m" -f $WaitMinutes),'--poll-interval','2s')
    Start-Sleep -Milliseconds 400
    $runs = Invoke-OpenClawJson -Args @('cron','runs','--id',$JobId,'--limit','3')
    $items = @()
    if ($runs -and ($runs.PSObject.Properties.Name -contains 'entries')) { $items=@($runs.entries) } elseif ($runs -and ($runs.PSObject.Properties.Name -contains 'runs')) { $items=@($runs.runs) } elseif ($runs) { $items=@($runs) }
    foreach ($r in $items) {
        $ok = (($r.PSObject.Properties.Name -contains 'completionStatus') -and ([string]$r.completionStatus -eq 'succeeded')) -or (($r.PSObject.Properties.Name -contains 'status') -and ([string]$r.status -eq 'ok'))
        if ($ok) { return [pscustomobject]@{ ok=$true; evidence='Automation run history independently reports success.'; started_at=$started.ToString('o') } }
    }
    return [pscustomobject]@{ ok=$false; evidence='Automation run history did not show a successful terminal run.'; started_at=$started.ToString('o') }
}

function Invoke-GreenAction {
    param($Action,$Desired,$Support,$LiveJobs)
    $verb = [string]$Action.verb
    if (@($Desired.green_registry) -notcontains $verb) { throw "Verb is not in GREEN registry: $verb" }

    if ($verb -eq 'enable_expected_automation') {
        $expected = @($Desired.required_automations | Where-Object { $_.declaration_key -eq $Action.target }) | Select-Object -First 1
        if (-not $expected) { throw 'Target is not in required automation allowlist.' }
        $job = Get-JobIdentity -Support $Support -LiveJobs $LiveJobs -DeclarationKey $expected.declaration_key -Name $expected.name
        if (-not $job) { throw 'Expected automation identity cannot be resolved.' }
        $null = Invoke-OpenClawJson -Args @('cron','enable',$job.id)
        $after = Invoke-OpenClawJson -Args @('cron','get',$job.id)
        $verified = ($after -and [bool]$after.enabled)
        return [pscustomobject]@{ ok=$verified; detail=("Enable {0}; verified={1} through automations get" -f $job.name,$verified); target=$job.id }
    }

    if ($verb -eq 'run_support_bridge') {
        $expected = @($Desired.required_automations | Where-Object { $_.declaration_key -eq 'kevin-support-bridge-v1' }) | Select-Object -First 1
        $job = Get-JobIdentity -Support $Support -LiveJobs $LiveJobs -DeclarationKey $expected.declaration_key -Name $expected.name
        if (-not $job) { throw 'Support Bridge automation identity cannot be resolved.' }
        $supportPath = Join-Path $Reports 'support-latest.json'
        $before = [DateTime]::MinValue
        if (Test-Path -LiteralPath $supportPath) { $before=(Get-Item -LiteralPath $supportPath).LastWriteTimeUtc }
        $runProof = Run-And-VerifyJob -JobId $job.id -WaitMinutes 4
        $advanced = $false
        for ($i=0;$i -lt 20;$i++) {
            if (Test-Path -LiteralPath $supportPath) {
                $now=(Get-Item -LiteralPath $supportPath).LastWriteTimeUtc
                if ($now -gt $before) { $advanced=$true; break }
            }
            Start-Sleep -Seconds 1
        }
        $ok = [bool]$runProof.ok -and $advanced
        return [pscustomobject]@{ ok=$ok; detail=("Support Bridge run history success={0}; snapshot advanced={1}" -f $runProof.ok,$advanced); target=$job.id }
    }

    if ($verb -eq 'run_benchmark') {
        $expected = @($Desired.required_automations | Where-Object { $_.declaration_key -eq 'kevin-benchmark-v1' }) | Select-Object -First 1
        $job = Get-JobIdentity -Support $Support -LiveJobs $LiveJobs -DeclarationKey $expected.declaration_key -Name $expected.name
        if (-not $job) { throw 'Benchmark automation identity cannot be resolved.' }
        $runProof = Run-And-VerifyJob -JobId $job.id -WaitMinutes 8
        return [pscustomobject]@{ ok=[bool]$runProof.ok; detail=$runProof.evidence; target=$job.id }
    }

    if ($verb -eq 'collect_diagnostics') {
        return [pscustomobject]@{ ok=$true; detail='Diagnostics captured in reconciler evidence.'; target='local' }
    }
    throw "No implementation for GREEN verb: $verb"
}

function Update-WorkQueue {
    param($Desired,$Support,$Dashboard,$State)
    if (-not $Desired.work_conserving.enabled) { return $null }
    $active = 0
    if ($Support -and $Support.active_workers) {
        foreach ($p in $Support.active_workers.PSObject.Properties) { $active += [int]$p.Value }
    }
    $blockedLike = $false
    if ($Support -and $Support.supervisor) {
        $lr = [string]$Support.supervisor.last_result
        $blockedLike = $lr -match 'RECOVERY_SATURATED|RECOVERY_THROTTLED|WAIT|BLOCK|COOL'
    }
    $candidates = @($Desired.work_conserving.candidate_queue)
    $next = $null
    if ($active -eq 0 -and $blockedLike -and $candidates.Count -gt 0) {
        $idx = [int]$State.queue_index
        if ($idx -lt 0) { $idx=0 }
        $next = [string]$candidates[$idx % $candidates.Count]
        $State.queue_index = ($idx + 1) % $candidates.Count
    }
    $q = [pscustomobject]@{
        schema=1
        generated_at=(Get-Date).ToString('o')
        active_engineering_workers=$active
        supervisor_blocked_or_cooling=$blockedLike
        next_suggested_candidate=$next
        status=($(if($next){'READY_FOR_SUPERVISOR_INTEGRATION'}else{'NO_DISPATCH_NEEDED'}))
        candidate_only=$true
        note='This queue is advisory in v0.1. It never grants authority and never executes arbitrary code.'
    }
    Write-JsonAtomic -Object $q -Path $QueuePath
    return $q
}

if (-not (Test-Path -LiteralPath $DesiredPath)) { throw "Desired state missing: $DesiredPath" }
if (-not (Test-Path -LiteralPath $OwnerAuthPath)) { throw "Owner authorization missing: $OwnerAuthPath" }
$Desired = Get-Content -LiteralPath $DesiredPath -Raw | ConvertFrom-Json
if ($Desired.kind -ne 'kevin-desired-state' -or $Desired.version -ne '1.0') { throw 'Desired State schema/version mismatch.' }
if ($Desired.authority.allow_arbitrary_shell -or $Desired.authority.allow_authority_expansion -or $Desired.authority.allow_novel_production_promotion) { throw 'Desired State violates owner authority boundaries.' }

$SupportObj = Get-SupportSnapshot
$DashboardObj = Get-DashboardSnapshot
$Support = $SupportObj.Data
$Dashboard = $DashboardObj.Data
$LiveJobs = @()
$liveError = ''
try { $LiveJobs = Get-LiveJobs } catch { $liveError=$_.Exception.Message }

$state = Get-ReconcilerState
$drift = New-Object System.Collections.ArrayList
foreach($d in @(Test-DesiredState -Desired $Desired -Support $Support -Dashboard $Dashboard)){ [void]$drift.Add($d) }
$fingerprint = Get-Fingerprint -Drift @($drift)
$queue = Update-WorkQueue -Desired $Desired -Support $Support -Dashboard $Dashboard -State $state

$now = [DateTimeOffset]::Now
$decision = 'HEALTHY'
$selected = $null
$actionResult = $null

$reviewItems = @($drift | Where-Object { $_.severity -eq 'review' })
$repairItems = @($drift | Where-Object { $_.severity -eq 'repair' })
if ($reviewItems.Count -gt 0) { $decision='NEEDS_REVIEW' }
elseif ($repairItems.Count -gt 0) { $decision='AUTO_REPAIR_ELIGIBLE'; $selected=$repairItems[0] }

if ($Mode -eq 'SelfTest') {
    $decision = 'SELF_TEST_PASS'
    if ($Desired.green_registry.Count -lt 1) { throw 'GREEN registry is empty.' }
    if (@($Desired.green_registry | Where-Object { $_ -match 'shell|powershell|exec|command_string' }).Count -gt 0) { throw 'Unsafe verb present in GREEN registry.' }
}

if ($Mode -eq 'Reconcile' -and $selected -and $decision -eq 'AUTO_REPAIR_ELIGIBLE') {
    $family = [string]$selected.family
    $same = ([string]$state.failure_family -eq $family -and [string]$state.fingerprint -eq $fingerprint)
    if (-not $same) {
        $state.failure_family=$family; $state.fingerprint=$fingerprint; $state.attempts=0; $state.cooldown_until=$null
    }
    $inCooldown = $false
    if ($state.cooldown_until) {
        try { $inCooldown=([DateTimeOffset]::Parse([string]$state.cooldown_until) -gt $now) } catch { $inCooldown=$false }
    }
    if ($inCooldown) { $decision='COOLING_DOWN' }
    elseif ([int]$state.attempts -ge [int]$Desired.health_contract.max_same_failure_attempts) {
        $decision='COOLING_DOWN'
        $state.cooldown_until=$now.AddMinutes([double]$Desired.health_contract.cooldown_minutes_after_budget).ToString('o')
    } else {
        $decision='REPAIRING'
        $state.attempts=[int]$state.attempts+1
        try {
            $actionResult=Invoke-GreenAction -Action $selected -Desired $Desired -Support $Support -LiveJobs $LiveJobs
            if ($actionResult.ok) {
                $decision='VERIFIED'
                $state.failure_family=''; $state.fingerprint=''; $state.attempts=0; $state.cooldown_until=$null
            } else { $decision='AUTO_REPAIR_FAILED' }
        } catch {
            $actionResult=[pscustomobject]@{ ok=$false; detail=$_.Exception.Message; target=[string]$selected.target }
            $decision='AUTO_REPAIR_FAILED'
        }
    }
}

$state.last_action = $(if($selected){[string]$selected.verb}else{''})
$state.last_result = $decision
Save-ReconcilerState -State $state

$evidence = [pscustomobject]@{
    schema=1
    kind='kevin-autonomy-reconcile-result'
    generated_at=(Get-Date).ToString('o')
    mode=$Mode
    state=$decision
    fingerprint=$fingerprint
    drift=@($drift)
    selected_action=$(if($selected){$selected}else{$null})
    action_result=$actionResult
    failure_budget=[pscustomobject]@{ family=$state.failure_family; attempts=[int]$state.attempts; cooldown_until=$state.cooldown_until }
    work_conserving=$queue
    live_query_error=$liveError
    safety=[pscustomobject]@{ green_only=$true; arbitrary_shell=$false; authority_expansion=$false; novel_production_promotion=$false }
}
$stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
$evidenceFile=Join-Path $EvidenceDir ("$stamp-reconcile.json")
Write-JsonAtomic -Object $evidence -Path $evidenceFile
Write-JsonAtomic -Object $evidence -Path $LatestEvidencePath

Write-Output ("KEVIN AUTONOMY v0.1 :: {0} :: drift={1} :: action={2}" -f $decision,@($drift).Count,$state.last_action)
if ($decision -eq 'NEEDS_REVIEW' -or $decision -eq 'AUTO_REPAIR_FAILED') { exit 2 }
exit 0
