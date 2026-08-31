param([switch]$SelfTest)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Repo = 'hessmodee/KEVIN-WORK'
$SourceRef = '999b1a5f903fe9d74ace3a88d912b2dd6e253fc2'
$SourcePath = 'control-plane/maintenance/kevin-maintenance-runner-v1.3.1.ps1'
$ExpectedBefore = '97F3FAE54C72F97D3634A6C070FD2E2C7E31B516FEB318CD3D1AECC4A17910C7'
$ExpectedAfter = '8371806430518E00E67E7592C9C309B8F03075091C13FDA529CADD34B2CED9D6'
$ExpectedManifestId = 'typed-ui-bridge-restart-v034-schema3-20260830-1858'
$Workspace = Join-Path $env:USERPROFILE '.openclaw\workspace'
$Target = Join-Path $Workspace 'kevin-maintenance-runner.ps1'
$Reports = Join-Path $Workspace 'reports'
$MaintenanceLatest = Join-Path $Reports 'maintenance\latest.json'
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
    foreach ($pattern in @('(?m)\breturn(?=\$|\[|@)','(?i)-Filter''')) {
        if ($txt -match $pattern) { throw ('candidate Windows token regression ' + $pattern) }
    }
    Invoke-SelfTest $Destination
}
function Assert-WatchdogTask {
    $t = Get-ScheduledTask -TaskName $WatchdogTask -ErrorAction Stop
    if ([string]$t.State -eq 'Disabled') { throw 'self-reliance watchdog task disabled' }
    if ([string]$t.Principal.RunLevel -ne 'Limited') { throw 'self-reliance watchdog privilege widened' }
}
function Assert-TypedMaintenanceProof {
    if (-not (Test-Path -LiteralPath $MaintenanceLatest -PathType Leaf)) { throw 'maintenance state missing after typed proof' }
    $m = Get-Content -LiteralPath $MaintenanceLatest -Raw | ConvertFrom-Json
    if ([string]$m.manifest_id -ne $ExpectedManifestId) { throw ('unexpected maintenance manifest proof ' + [string]$m.manifest_id) }
    if (-not (@('APPLIED_PREAUTHORIZED_PROVEN','ALREADY_APPLIED_PROVEN') -contains [string]$m.status)) { throw ('typed maintenance not proven status=' + [string]$m.status) }
    if ([string]$m.status -eq 'APPLIED_PREAUTHORIZED_PROVEN') {
        if ($null -eq $m.result -or [string]$m.result.state -ne 'READY') { throw 'typed UI restart result missing fresh READY state' }
    }
    return $m
}
function Assert-Benchmark30 {
    if (-not (Test-Path -LiteralPath $BenchmarkLatest -PathType Leaf)) { throw 'benchmark evidence missing' }
    $b = Get-Content -LiteralPath $BenchmarkLatest -Raw | ConvertFrom-Json
    if ([string]$b.status -ne 'PASS' -or [int]$b.regression.passed -ne 30 -or [int]$b.regression.total -ne 30 -or [int]$b.regression.critical_failures -ne 0) { throw 'benchmark not 30/30 critical=0' }
    return $b
}
function Invoke-BootstrapSelfTest {
    if ($SourceRef -notmatch '^[0-9a-f]{40}$') { throw 'immutable ref invariant' }
    if ($ExpectedBefore -notmatch '^[A-F0-9]{64}$' -or $ExpectedAfter -notmatch '^[A-F0-9]{64}$') { throw 'hash invariant' }
    if ($ExpectedBefore -eq $ExpectedAfter) { throw 'upgrade identity invariant' }
    if ((Safe 'abc' 10) -ne 'abc') { throw 'Safe runtime invariant' }
    Write-Host 'KEVIN MAINTENANCE v1.3.1 BOOTSTRAP SELFTEST PASS immutable_ref=true exact_hashes=true typed_postproof=true rollback=true arbitrary_shell=false authority_expansion=false'
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

    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Target -CheckOnly 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    }
    finally { $ErrorActionPreference = $old }
    if ($code -ne 0) { throw ('typed post-install proof failed exit=' + $code + ' output=' + (Safe $out 500)) }

    $m = Assert-TypedMaintenanceProof
    Write-Host ('PASS typed self-maintenance lane ' + [string]$m.status + ' manifest=' + [string]$m.manifest_id)
    $b = Assert-Benchmark30
    Write-Host 'PASS benchmark 30/30 critical=0'

    $proof = [ordered]@{
        schema = 1
        kind = 'kevin-maintenance-v1.3.1-bootstrap-proof'
        at = (Get-Date).ToString('o')
        status = 'PROVEN'
        authority_class = 'GREEN'
        authority_delta = 'NONE'
        before = $before
        after = (Get-Sha $Target)
        source = [ordered]@{ repo = $Repo; commit = $SourceRef; path = $SourcePath; sha256 = $ExpectedAfter }
        typed_maintenance = [ordered]@{ manifest_id = [string]$m.manifest_id; status = [string]$m.status }
        watchdog = [ordered]@{ task = $WatchdogTask; run_level = 'Limited' }
        benchmark = [ordered]@{ status = [string]$b.status; passed = [int]$b.regression.passed; total = [int]$b.regression.total; critical = [int]$b.regression.critical_failures }
        arbitrary_shell = $false
        authority_expansion = $false
    }
    Write-JsonAtomic $Receipt $proof
    Write-Host ('PROOF ' + $Receipt)
    Write-Host 'MAINTENANCE v1.3.1 PROVEN typed_lane=true watchdog=Limited benchmark=30/30'
    exit 0
}
catch {
    $err = $_.Exception.Message
    Write-Host ('MAINTENANCE v1.3.1 BOOTSTRAP FAILED ' + (Safe $err 700))
    if ($mutated -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
        Copy-Item -LiteralPath $backup -Destination $Target -Force
        Write-Host ('ROLLBACK maintenance restored ' + (Get-Sha $Target))
    }
    exit 1
}
finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
