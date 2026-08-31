param(
    [switch]$SelfTest,
    [switch]$Preflight
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Repo = 'hessmodee/KEVIN-WORK'
$SourceRef = 'a556563a56e2756b8a9f87d3472028101465a580'
$Workspace = Join-Path $env:USERPROFILE '.openclaw\workspace'
$Control = Join-Path $Workspace 'ControlPlane'
$Reports = Join-Path $Workspace 'reports'
$EvidenceRoot = Join-Path $Reports 'self-reliance'
$Receipt = Join-Path $EvidenceRoot 'bootstrap-self-reliance-v1.1-proven.json'
$Benchmark = Join-Path $Workspace 'kevin-benchmark-v1.ps1'
$BenchmarkLatest = Join-Path $Reports 'benchmark-v1\latest.json'
$TaskName = 'Kevin Self-Reliance Watchdog v1'
$ExpectedMaintenanceBefore = '3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483'

$Components = @(
    [pscustomobject]@{
        Name = 'maintenance'
        Source = 'control-plane/maintenance/kevin-maintenance-runner-v1.3.ps1'
        Sha256 = '97F3FAE54C72F97D3634A6C070FD2E2C7E31B516FEB318CD3D1AECC4A17910C7'
        Target = (Join-Path $Workspace 'kevin-maintenance-runner.ps1')
        Args = @('-SelfTest')
        Marker = 'KEVIN MAINTENANCE v1.3 SELFTEST PASS'
    },
    [pscustomobject]@{
        Name = 'intake'
        Source = 'control-plane/intake/kevin-work-order-intake-v1.2.2.ps1'
        Sha256 = '55942149C892AD988E1AEE5A6FF7983D71D891ECA5B71FA20CC3FB9E7D03E903'
        Target = (Join-Path $Control 'kevin-work-order-intake-v0.1.ps1')
        Args = @('-Mode','SelfTest')
        Marker = 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS'
    },
    [pscustomobject]@{
        Name = 'watchdog'
        Source = 'control-plane/maintenance/kevin-self-reliance-watchdog-v1.1.ps1'
        Sha256 = '4A6ACA6EC40E027B29CCC4C34C50EDAE9EAE90E0C8FEB41B92ACEE44CCB53D93'
        Target = (Join-Path $Workspace 'kevin-self-reliance-watchdog.ps1')
        Args = @('-SelfTest')
        Marker = 'KEVIN SELF-RELIANCE WATCHDOG v1.1 SELFTEST PASS'
    }
)

function Get-Sha256([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ''
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Sanitize-Text([object]$Value, [int]$Max = 700) {
    $s = [string]$Value
    if (-not $s) {
        return ''
    }
    if ($env:USERPROFILE) {
        $s = [regex]::Replace(
            $s,
            [regex]::Escape([string]$env:USERPROFILE),
            '~',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }
    $s = $s.Replace("`r",' ').Replace("`n",' ')
    if ($s.Length -gt $Max) {
        $s = $s.Substring(0,$Max)
    }
    return $s
}

function Write-JsonAtomic([string]$Path, [object]$Object) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Path -Parent) | Out-Null
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp, ($Object | ConvertTo-Json -Depth 30), $Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Parse-PowerShellFile([string]$Path) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    if ($errors.Count -gt 0) {
        throw ('PowerShell parser rejected ' + $Path + ': ' + $errors[0].Message)
    }
}

function Invoke-ComponentSelfTest([object]$Component, [string]$Path) {
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path @($Component.Args) 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $old
    }
    if ($code -ne 0) {
        throw ('fixed self-test failed component=' + $Component.Name + ' exit=' + $code)
    }
    if ($out -notmatch [regex]::Escape([string]$Component.Marker)) {
        throw ('self-test marker missing component=' + $Component.Name)
    }
}

function Invoke-GitHubApi([string[]]$Arguments) {
    $gh = Get-Command gh.exe -ErrorAction SilentlyContinue
    if (-not $gh) {
        $gh = Get-Command gh -ErrorAction Stop
    }
    $oldPrompt = [Environment]::GetEnvironmentVariable('GH_PROMPT_DISABLED','Process')
    try {
        $env:GH_PROMPT_DISABLED = '1'
        $old = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $out = (& $gh.Source @Arguments 2>&1 | Out-String).Trim()
            $code = [int]$LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $old
        }
        return [pscustomobject]@{
            ExitCode = $code
            Output = [string]$out
        }
    }
    finally {
        if ($null -ne $oldPrompt) {
            $env:GH_PROMPT_DISABLED = $oldPrompt
        }
        else {
            Remove-Item Env:GH_PROMPT_DISABLED -ErrorAction SilentlyContinue
        }
    }
}

function Fetch-Component([object]$Component, [string]$Destination) {
    $endpoint = 'repos/' + $Repo + '/contents/' + [string]$Component.Source + '?ref=' + $SourceRef
    $r = Invoke-GitHubApi @('api',$endpoint,'--jq','.content')
    if ($r.ExitCode -ne 0) {
        throw ('fixed source fetch failed component=' + $Component.Name + ' detail=' + (Sanitize-Text $r.Output 250))
    }
    try {
        $bytes = [Convert]::FromBase64String(([string]$r.Output -replace '\s',''))
    }
    catch {
        throw ('source decode failed component=' + $Component.Name)
    }
    [IO.File]::WriteAllBytes($Destination,$bytes)

    $actual = Get-Sha256 $Destination
    if ($actual -ne [string]$Component.Sha256) {
        throw ('source SHA256 mismatch component=' + $Component.Name + ' actual=' + $actual)
    }
    Parse-PowerShellFile $Destination
    Invoke-ComponentSelfTest $Component $Destination
}

function New-WatchdogTaskParts([string]$WatchdogPath) {
    $psExe = (Get-Command powershell.exe -ErrorAction Stop).Source
    $arg = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $WatchdogPath + '"'
    $action = New-ScheduledTaskAction -Execute $psExe -Argument $arg -WorkingDirectory $Workspace
    $repeat = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration (New-TimeSpan -Days 3650)
    $logon = New-ScheduledTaskTrigger -AtLogOn -User ([Security.Principal.WindowsIdentity]::GetCurrent().Name)
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Minutes 12) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    return [pscustomobject]@{
        Action = $action
        Triggers = @($repeat,$logon)
        Settings = $settings
        Principal = $principal
    }
}

function Assert-WatchdogTaskParts([object]$Parts, [string]$WatchdogPath) {
    if ([string]$Parts.Principal.RunLevel -ne 'Limited') {
        throw 'watchdog task privilege widened'
    }
    if (@($Parts.Action).Count -ne 1) {
        throw 'watchdog task action count mismatch'
    }
    if ([IO.Path]::GetFileName([string]$Parts.Action.Execute) -notmatch '(?i)^powershell\.exe$') {
        throw 'watchdog task executable mismatch'
    }
    $args = [string]$Parts.Action.Arguments
    foreach ($required in @('-NoProfile','-NonInteractive','-ExecutionPolicy Bypass',$WatchdogPath)) {
        if ($args -notmatch [regex]::Escape($required)) {
            throw ('watchdog task argv missing ' + $required)
        }
    }
}

function Register-WatchdogTask([string]$WatchdogPath) {
    $parts = New-WatchdogTaskParts $WatchdogPath
    Assert-WatchdogTaskParts $parts $WatchdogPath
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $parts.Action `
        -Trigger $parts.Triggers `
        -Settings $parts.Settings `
        -Principal $parts.Principal `
        -Description 'External fixed-action Kevin recovery kernel: gateway health/restart plus typed GREEN maintenance wake.' `
        -Force | Out-Null
}

function Assert-RegisteredWatchdog([string]$WatchdogPath) {
    $t = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    if (-not $t.Enabled) {
        throw 'watchdog task disabled'
    }
    if ([string]$t.Principal.RunLevel -ne 'Limited') {
        throw 'watchdog task privilege widened'
    }
    $a = @($t.Actions)
    if ($a.Count -ne 1) {
        throw 'watchdog task action count mismatch'
    }
    if ([IO.Path]::GetFileName([string]$a[0].Execute) -notmatch '(?i)^powershell\.exe$') {
        throw 'watchdog task executable mismatch'
    }
    if ([string]$a[0].Arguments -notmatch [regex]::Escape($WatchdogPath)) {
        throw 'watchdog task target mismatch'
    }
}

function Wait-Quiescent {
    $deadline = (Get-Date).AddSeconds(45)
    do {
        $active = @(
            Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
            Where-Object {
                $_.CommandLine -and (
                    $_.CommandLine -match 'kevin-maintenance-runner\.ps1' -or
                    $_.CommandLine -match 'kevin-work-order-intake-v0\.1\.ps1' -or
                    $_.CommandLine -match 'kevin-self-reliance-watchdog\.ps1'
                )
            }
        )
        if ($active.Count -eq 0) {
            return
        }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    throw 'Kevin maintenance/intake/watchdog execution did not quiesce'
}

function Install-Atomic([string]$Source, [string]$Target, [string]$Expected) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Target -Parent) | Out-Null
    $tmp = $Target + '.self-reliance-' + [guid]::NewGuid().ToString('N')
    Copy-Item -LiteralPath $Source -Destination $tmp -Force
    Move-Item -LiteralPath $tmp -Destination $Target -Force
    if ((Get-Sha256 $Target) -ne $Expected) {
        throw ('installed target hash mismatch ' + $Target)
    }
}

function Assert-FreshBenchmark30 {
    if (-not (Test-Path -LiteralPath $Benchmark -PathType Leaf)) {
        throw 'benchmark runner missing'
    }
    $deadline = (Get-Date).AddSeconds(90)
    while ($true) {
        $started = [DateTime]::UtcNow
        $old = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Benchmark 2>&1 | Out-String).Trim()
            $code = [int]$LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $old
        }

        if ($out -match '(?i)BENCHMARK\s+SKIP_ACTIVE_WORK') {
            if ((Get-Date) -ge $deadline) {
                throw 'fresh benchmark retry budget exhausted'
            }
            Start-Sleep 5
            continue
        }
        if ($code -ne 0) {
            throw ('benchmark failed exit=' + $code)
        }
        if (-not (Test-Path -LiteralPath $BenchmarkLatest -PathType Leaf)) {
            throw 'benchmark evidence missing'
        }

        $b = Get-Content -LiteralPath $BenchmarkLatest -Raw | ConvertFrom-Json
        if (
            [string]$b.status -ne 'PASS' -or
            [int]$b.regression.passed -ne 30 -or
            [int]$b.regression.total -ne 30 -or
            [int]$b.regression.critical_failures -ne 0
        ) {
            throw 'benchmark not 30/30 critical=0'
        }
        if ((Get-Item -LiteralPath $BenchmarkLatest).LastWriteTimeUtc -lt $started.AddSeconds(-3)) {
            throw 'benchmark evidence not fresh'
        }
        return $b
    }
}

function Invoke-SelfTest {
    if ($SourceRef -notmatch '^[0-9a-f]{40}$') {
        throw 'immutable source ref invalid'
    }
    if ($Components.Count -ne 3) {
        throw 'component count invariant'
    }
    foreach ($c in $Components) {
        if ([string]$c.Sha256 -notmatch '^[A-F0-9]{64}$') {
            throw ('hash invariant ' + $c.Name)
        }
        if ([string]$c.Source -notmatch '^control-plane/(maintenance|intake)/[A-Za-z0-9._-]+\.ps1$') {
            throw ('source root invariant ' + $c.Name)
        }
    }
    if ($TaskName -ne 'Kevin Self-Reliance Watchdog v1') {
        throw 'task name invariant'
    }
    if ($ExpectedMaintenanceBefore -ne '3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483') {
        throw 'bootstrap root hash invariant'
    }

    $safeProbe = Sanitize-Text "alpha`r`nbeta" 100
    if ($safeProbe -ne 'alpha  beta') {
        throw ('sanitize runtime invariant failed: ' + $safeProbe)
    }

    Write-Host 'KEVIN SELF-RELIANCE BOOTSTRAP v1.1 SELFTEST PASS components=3 safe_runtime=true immutable_ref=true exact_hashes=true task=limited rollback=true arbitrary_shell=false caller_payload=false'
}

function Invoke-Preflight {
    Invoke-SelfTest
    $root = Join-Path $env:TEMP ('kevin-self-reliance-preflight-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    try {
        foreach ($c in $Components) {
            $candidate = Join-Path $root ($c.Name + '.ps1')
            Fetch-Component $c $candidate
            Write-Host ('PREFLIGHT component=' + $c.Name + ' sha256=' + (Get-Sha256 $candidate))
        }
        $watchdogPath = Join-Path $Workspace 'kevin-self-reliance-watchdog.ps1'
        $parts = New-WatchdogTaskParts $watchdogPath
        Assert-WatchdogTaskParts $parts $watchdogPath
        Write-Host 'KEVIN SELF-RELIANCE BOOTSTRAP v1.1 PREFLIGHT PASS api_fetch=true component_selftests=true task_contract=true'
    }
    finally {
        Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($SelfTest) {
    Invoke-SelfTest
    exit 0
}
if ($Preflight) {
    Invoke-Preflight
    exit 0
}

$session = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $EvidenceRoot ('bootstrap-backup-' + $session)
$stage = Join-Path $EvidenceRoot ('bootstrap-stage-' + $session)
New-Item -ItemType Directory -Force -Path $backup,$stage | Out-Null

$taskBeforeXml = $null
$taskBeforePresent = $false
$mutated = $false
$before = @{}

try {
    Write-Host '=== KEVIN SELF-RELIANCE BOOTSTRAP v1.1 ==='

    $maint = $Components | Where-Object { $_.Name -eq 'maintenance' }
    $currentMaint = Get-Sha256 $maint.Target
    if ($currentMaint -ne $ExpectedMaintenanceBefore -and $currentMaint -ne [string]$maint.Sha256) {
        throw ('maintenance root unexpected actual=' + $currentMaint)
    }
    Write-Host ('PASS root maintenance identity ' + $currentMaint)

    foreach ($c in $Components) {
        $before[$c.Name] = Get-Sha256 $c.Target
        if (Test-Path -LiteralPath $c.Target -PathType Leaf) {
            Copy-Item -LiteralPath $c.Target -Destination (Join-Path $backup ($c.Name + '.before.ps1')) -Force
        }

        $staged = Join-Path $stage ($c.Name + '.ps1')
        Fetch-Component $c $staged
        Write-Host ('PASS staged ' + $c.Name + ' ' + $c.Sha256)
    }

    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        $taskBeforePresent = $true
        $taskBeforeXml = Export-ScheduledTask -TaskName $TaskName
    }

    Wait-Quiescent

    foreach ($c in $Components) {
        $staged = Join-Path $stage ($c.Name + '.ps1')
        if ((Get-Sha256 $c.Target) -ne [string]$c.Sha256) {
            Install-Atomic $staged $c.Target $c.Sha256
            $mutated = $true
        }
        Invoke-ComponentSelfTest $c $c.Target
        Write-Host ('PASS installed ' + $c.Name + ' ' + (Get-Sha256 $c.Target))
    }

    $watchdogTarget = ($Components | Where-Object { $_.Name -eq 'watchdog' }).Target
    Register-WatchdogTask $watchdogTarget
    $mutated = $true
    Assert-RegisteredWatchdog $watchdogTarget
    Write-Host 'PASS external watchdog task exact + Limited'

    Start-ScheduledTask -TaskName $TaskName
    $watchdogState = Join-Path $EvidenceRoot 'watchdog-state.json'
    $watchdogStarted = Get-Date
    $deadline = (Get-Date).AddSeconds(75)
    $fresh = $null
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
        if (Test-Path -LiteralPath $watchdogState -PathType Leaf) {
            try {
                $w = Get-Content -LiteralPath $watchdogState -Raw | ConvertFrom-Json
                $isFresh = ([datetime]$w.updated_at -ge $watchdogStarted.AddSeconds(-2))
                if ($isFresh -and [string]$w.last_result -in @('HEALTHY','RECOVERED')) {
                    $fresh = $w
                    break
                }
            }
            catch {
            }
        }
    }
    if (-not $fresh) {
        throw 'watchdog did not produce fresh HEALTHY/RECOVERED evidence'
    }
    Write-Host ('PASS watchdog runtime ' + [string]$fresh.last_result)

    $b = Assert-FreshBenchmark30
    Write-Host 'PASS fresh benchmark 30/30 critical=0'

    $receiptObject = [ordered]@{
        schema = 1
        kind = 'kevin-self-reliance-bootstrap-proof'
        version = '1.1'
        at = (Get-Date).ToString('o')
        status = 'PROVEN'
        authority_class = 'GREEN'
        authority_delta = 'NONE'
        source = [ordered]@{
            repo = $Repo
            commit = $SourceRef
            canonical_lf = $true
        }
        components = [ordered]@{
            maintenance = [ordered]@{
                before = $before['maintenance']
                after = (Get-Sha256 (($Components | Where-Object { $_.Name -eq 'maintenance' }).Target))
            }
            intake = [ordered]@{
                before = $before['intake']
                after = (Get-Sha256 (($Components | Where-Object { $_.Name -eq 'intake' }).Target))
            }
            watchdog = [ordered]@{
                before = $before['watchdog']
                after = (Get-Sha256 (($Components | Where-Object { $_.Name -eq 'watchdog' }).Target))
            }
        }
        watchdog = [ordered]@{
            task = $TaskName
            run_level = 'Limited'
            state = [string]$fresh.last_result
            maintenance_wake = 'fixed_-CheckOnly'
            gateway_actions = 'fixed_status_restart'
        }
        benchmark = [ordered]@{
            status = [string]$b.status
            passed = [int]$b.regression.passed
            total = [int]$b.regression.total
            critical = [int]$b.regression.critical_failures
        }
        rollback_backup = (Sanitize-Text $backup 400)
        arbitrary_shell = $false
        caller_payload = $false
    }

    Write-JsonAtomic $Receipt $receiptObject
    Write-Host ('PROOF ' + $Receipt)
    Write-Host 'SELF-RELIANCE BOOTSTRAP PROVEN maintenance=v1.3 intake=v1.2.2 watchdog=v1.1 benchmark=30/30'
    exit 0
}
catch {
    $err = $_.Exception.Message
    Write-Host ('SELF-RELIANCE BOOTSTRAP FAILED ' + (Sanitize-Text $err 700))
    if ($mutated) {
        Write-Host 'ROLLBACK starting'
        foreach ($c in $Components) {
            $bp = Join-Path $backup ($c.Name + '.before.ps1')
            if (Test-Path -LiteralPath $bp -PathType Leaf) {
                Copy-Item -LiteralPath $bp -Destination $c.Target -Force
            }
            else {
                Remove-Item -LiteralPath $c.Target -Force -ErrorAction SilentlyContinue
            }
        }
        try {
            if ($taskBeforePresent -and $taskBeforeXml) {
                Register-ScheduledTask -TaskName $TaskName -Xml $taskBeforeXml -Force | Out-Null
            }
            else {
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Host ('ROLLBACK task warning ' + (Sanitize-Text $_.Exception.Message 300))
        }
        Write-Host 'ROLLBACK component files restored'
    }
    exit 1
}
finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
