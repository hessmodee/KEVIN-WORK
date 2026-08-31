param([switch]$SelfTest)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Repo = 'hessmodee/KEVIN-WORK'
$SourceRef = '999b1a5f903fe9d74ace3a88d912b2dd6e253fc2'
$SourcePath = 'control-plane/maintenance/kevin-maintenance-runner-v1.3.1.ps1'
$ExpectedBefore = '97F3FAE54C72F97D3634A6C070FD2E2C7E31B516FEB318CD3D1AECC4A17910C7'
$ExpectedAfter = '8371806430518E00E67E7592C9C309B8F03075091C13FDA529CADD34B2CED9D6'
$Workspace = Join-Path $env:USERPROFILE '.openclaw\workspace'
$Target = Join-Path $Workspace 'kevin-maintenance-runner.ps1'
$Reports = Join-Path $Workspace 'reports'
$Benchmark = Join-Path $Workspace 'kevin-benchmark-v1.ps1'
$BenchmarkLatest = Join-Path $Reports 'benchmark-v1\latest.json'
$Receipt = Join-Path $Reports 'self-reliance\bootstrap-maintenance-v1.3.1-proven.json'
$WatchdogTask = 'Kevin Self-Reliance Watchdog v1'

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Safe([object]$Value,[int]$Max = 600) {
    $s = [string]$Value
    if (-not $s) { return '' }
    if ($env:USERPROFILE) { $s = [regex]::Replace($s,[regex]::Escape([string]$env:USERPROFILE),'~',[Text.RegularExpressions.RegexOptions]::IgnoreCase) }
    $s = $s.Replace("`r",' ').Replace("`n",' ')
    if ($s.Length -gt $Max) { $s = $s.Substring(0,$Max) }
    return $s
}
function Write-JsonAtomic([string]$Path,[object]$Object) {
    New-Item -ItemType Directory -Force (Split-Path $Path -Parent) | Out-Null
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,($Object | ConvertTo-Json -Depth 20),$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Parse-PowerShell([string]$Path) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    if ($errors.Count -gt 0) { throw ('parser rejected candidate: ' + $errors[0].Message) }
}
function Invoke-SelfTest([string]$Path) {
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path -SelfTest 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    }
    finally { $ErrorActionPreference = $old }
    if ($code -ne 0) { throw ('maintenance v1.3.1 self-test exit=' + $code) }
    if ($out -notmatch [regex]::Escape('KEVIN MAINTENANCE v1.3.1 SELFTEST PASS')) { throw 'maintenance v1.3.1 self-test marker missing' }
}
function Fetch-Candidate([string]$Destination) {
    $endpoint = 'repos/' + $Repo + '/contents/' + $SourcePath + '?ref=' + $SourceRef
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $b64 = (& gh api $endpoint --jq '.content' 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    }
    finally { $ErrorActionPreference = $old }
    if ($code -ne 0) { throw 'immutable candidate fetch failed' }
    try { $bytes = [Convert]::FromBase64String(($b64 -replace '\s','')) }
    catch { throw 'immutable candidate decode failed' }
    [IO.File]::WriteAllBytes($Destination,$bytes)
    $actual = Get-Sha $Destination
    if ($actual -ne $ExpectedAfter) { throw ('candidate SHA256 mismatch actual=' + $actual) }
    Parse-PowerShell $Destination
    $txt = [IO.File]::ReadAllText($Destination)
    if ($txt -match '(?m)\breturn(?=\$|\[|@)') { throw 'candidate Windows return-token regression' }
    Invoke-SelfTest $Destination
}
function Wait-Quiescent {
    $deadline = (Get-Date).AddSeconds(45)
    do {
        $active = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
            $_.CommandLine -and (
                $_.CommandLine -match 'kevin-maintenance-runner\.ps1' -or
                $_.CommandLine -match 'kevin-self-reliance-watchdog\.ps1'
            ) -and $_.ProcessId -ne $PID
        })
        if ($active.Count -eq 0) { return }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    throw 'maintenance/watchdog execution did not quiesce'
}
function Assert-WatchdogTask {
    $t = Get-ScheduledTask -TaskName $WatchdogTask -ErrorAction Stop
    if ([string]$t.State -eq 'Disabled') { throw 'self-reliance watchdog task disabled' }
    if ([string]$t.Principal.RunLevel -ne 'Limited') { throw 'self-reliance watchdog privilege widened' }
}
function Assert-FreshBenchmark30 {
    if (-not (Test-Path -LiteralPath $Benchmark -PathType Leaf)) { throw 'benchmark runner missing' }
    $deadline = (Get-Date).AddSeconds(90)
    while ($true) {
        $started = [DateTime]::UtcNow
        $old = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Benchmark 2>&1 | Out-String).Trim()
            $code = [int]$LASTEXITCODE
        }
        finally { $ErrorActionPreference = $old }
        if ($out -match '(?i)BENCHMARK\s+SKIP_ACTIVE_WORK') {
            if ((Get-Date) -ge $deadline) { throw 'fresh benchmark retry budget exhausted' }
            Start-Sleep 5
            continue
        }
        if ($code -ne 0) { throw ('benchmark failed exit=' + $code) }
        if (-not (Test-Path -LiteralPath $BenchmarkLatest -PathType Leaf)) { throw 'benchmark evidence missing' }
        $b = Get-Content -LiteralPath $BenchmarkLatest -Raw | ConvertFrom-Json
        if ([string]$b.status -ne 'PASS' -or [int]$b.regression.passed -ne 30 -or [int]$b.regression.total -ne 30 -or [int]$b.regression.critical_failures -ne 0) { throw 'benchmark not 30/30 critical=0' }
        if ((Get-Item -LiteralPath $BenchmarkLatest).LastWriteTimeUtc -lt $started.AddSeconds(-3)) { throw 'benchmark evidence not fresh' }
        return $b
    }
}
function Invoke-BootstrapSelfTest {
    if ($SourceRef -notmatch '^[0-9a-f]{40}$') { throw 'immutable ref invariant' }
    if ($ExpectedBefore -notmatch '^[A-F0-9]{64}$' -or $ExpectedAfter -notmatch '^[A-F0-9]{64}$') { throw 'hash invariant' }
    if ($ExpectedBefore -eq $ExpectedAfter) { throw 'upgrade identity invariant' }
    if ((Safe 'abc' 10) -ne 'abc') { throw 'Safe runtime invariant' }
    Write-Host 'KEVIN MAINTENANCE v1.3.1 TRUST BOOTSTRAP SELFTEST PASS immutable_ref=true exact_hashes=true fresh_benchmark=true rollback=true typed_lane_postproof=deferred arbitrary_shell=false authority_expansion=false'
}
if ($SelfTest) { Invoke-BootstrapSelfTest; exit 0 }

$session = Get-Date -Format 'yyyyMMdd-HHmmss'
$root = Join-Path $Reports 'self-reliance'
$stage = Join-Path $root ('maintenance-v131-stage-' + $session)
$backup = Join-Path $root ('maintenance-v131-backup-' + $session + '.ps1')
New-Item -ItemType Directory -Force $stage | Out-Null
$candidate = Join-Path $stage 'kevin-maintenance-runner-v1.3.1.ps1'
$mutated = $false
$before = ''
try {
    Write-Host '=== KEVIN MAINTENANCE v1.3.1 TRUST TRANSITION ==='
    $before = Get-Sha $Target
    if ($before -ne $ExpectedBefore -and $before -ne $ExpectedAfter) { throw ('unexpected installed maintenance identity ' + $before) }
    Write-Host ('PASS current maintenance identity ' + $before)

    Fetch-Candidate $candidate
    Write-Host ('PASS candidate exact + Windows runtime self-test ' + $ExpectedAfter)

    Wait-Quiescent
    Write-Host 'PASS maintenance/watchdog quiescent'

    if ($before -ne $ExpectedAfter) {
        Copy-Item -LiteralPath $Target -Destination $backup -Force
        $tmp = $Target + '.v131-' + [guid]::NewGuid().ToString('N')
        Copy-Item -LiteralPath $candidate -Destination $tmp -Force
        Move-Item -LiteralPath $tmp -Destination $Target -Force
        $mutated = $true
    }
    if ((Get-Sha $Target) -ne $ExpectedAfter) { throw 'installed maintenance v1.3.1 hash mismatch' }
    Invoke-SelfTest $Target
    Write-Host ('PASS installed maintenance v1.3.1 ' + (Get-Sha $Target))

    Assert-WatchdogTask
    Write-Host 'PASS watchdog task remains enabled-state + Limited'

    $b = Assert-FreshBenchmark30
    Write-Host 'PASS fresh benchmark 30/30 critical=0'

    $proof = [ordered]@{
        schema = 1
        kind = 'kevin-maintenance-v1.3.1-trust-transition-proof'
        at = (Get-Date).ToString('o')
        status = 'PROVEN'
        authority_class = 'GREEN'
        authority_delta = 'NONE'
        before = $before
        after = (Get-Sha $Target)
        source = [ordered]@{ repo = $Repo; commit = $SourceRef; path = $SourcePath; sha256 = $ExpectedAfter }
        watchdog = [ordered]@{ task = $WatchdogTask; run_level = 'Limited' }
        benchmark = [ordered]@{ status = [string]$b.status; passed = [int]$b.regression.passed; total = [int]$b.regression.total; critical = [int]$b.regression.critical_failures }
        typed_lane = [ordered]@{ status = 'PENDING_AUTONOMOUS_POSTPROOF'; reason = 'Preserve exhausted v1.3 failure evidence; Bess will publish a fresh schema-3 manifest id after installation and verify Kevin processes it without owner-local commands.' }
        arbitrary_shell = $false
        authority_expansion = $false
    }
    Write-JsonAtomic $Receipt $proof
    Write-Host ('PROOF ' + $Receipt)
    Write-Host 'MAINTENANCE v1.3.1 TRUST TRANSITION PROVEN watchdog=Limited benchmark=30/30 typed_lane=pending_autonomous_postproof'
    exit 0
}
catch {
    $err = $_.Exception.Message
    Write-Host ('MAINTENANCE v1.3.1 TRUST TRANSITION FAILED ' + (Safe $err 700))
    if ($mutated -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
        Copy-Item -LiteralPath $backup -Destination $Target -Force
        Write-Host ('ROLLBACK maintenance restored ' + (Get-Sha $Target))
    }
    exit 1
}
finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
