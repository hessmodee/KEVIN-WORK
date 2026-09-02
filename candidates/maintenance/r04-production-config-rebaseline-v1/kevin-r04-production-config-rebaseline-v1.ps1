param(
    [switch]$CheckOnly,
    [switch]$Apply,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$ExpectedCurrentConfig = '23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5'
$ExpectedPreviousConfig = '215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84'
$ExpectedBenchmark = '4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964'
$Workspace = Join-Path $env:USERPROFILE '.openclaw\workspace'
$ConfigPath = Join-Path $env:USERPROFILE '.openclaw\openclaw.json'
$BaselinePath = Join-Path $Workspace 'reports\benchmark-v1\baseline.json'
$BenchmarkPath = Join-Path $Workspace 'kevin-benchmark-v1.ps1'
$BenchmarkLatest = Join-Path $Workspace 'reports\benchmark-v1\latest.json'
$MaintenanceReportRoot = Join-Path $Workspace 'reports\maintenance'
$BackupRoot = Join-Path $MaintenanceReportRoot 'backups'
$ReceiptPath = Join-Path $MaintenanceReportRoot 'r04-production-config-rebaseline-latest.json'

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Write-Utf8Atomic([string]$Path,[string]$Text) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,$Text,$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Write-JsonAtomic([string]$Path,[object]$Object) {
    Write-Utf8Atomic $Path ($Object | ConvertTo-Json -Depth 30)
}

function Get-LeafLines([object]$Node,[string]$Path='$') {
    $lines = New-Object System.Collections.Generic.List[string]
    function Walk([object]$Value,[string]$Here) {
        if ($null -eq $Value) { $lines.Add($Here + '=<NULL>'); return }
        if ($Value -is [System.Management.Automation.PSCustomObject]) {
            $props = @($Value.PSObject.Properties | Sort-Object Name)
            if ($props.Count -eq 0) { $lines.Add($Here + '=<EMPTY_OBJECT>'); return }
            foreach ($p in $props) { Walk $p.Value ($Here + '[' + (ConvertTo-Json -InputObject ([string]$p.Name) -Compress) + ']') }
            return
        }
        if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
            $items = @($Value)
            if ($items.Count -eq 0) { $lines.Add($Here + '=<EMPTY_ARRAY>'); return }
            for ($i=0; $i -lt $items.Count; $i++) { Walk $items[$i] ($Here + '[' + $i + ']') }
            return
        }
        $serialized = $Value | ConvertTo-Json -Compress -Depth 30
        $lines.Add($Here + '=' + $serialized)
    }
    Walk $Node $Path
    return @($lines)
}

function Get-NonTargetFingerprint([object]$Baseline) {
    $text = ((Get-LeafLines $Baseline | Where-Object { -not $_.StartsWith('$["hashes"]["production_config"]=',[StringComparison]::Ordinal) } | Sort-Object) -join "`n")
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')
    } finally { $sha.Dispose() }
}

function Assert-Baseline([object]$Baseline) {
    if ($null -eq $Baseline -or ($Baseline.schema -isnot [int] -and $Baseline.schema -isnot [long]) -or $Baseline.schema -ne 1 -or [string]$Baseline.kind -ne 'kevin-benchmark-v1-baseline') { throw 'R04 baseline schema/kind mismatch' }
    if ($null -eq $Baseline.hashes) { throw 'R04 baseline hashes object missing' }
    foreach ($name in @('supervisor','forge','production_config','goal_os','promotion_policy','benchmark_spec','benchmark_runner')) {
        $v = [string]$Baseline.hashes.$name
        if ($v -notmatch '^[A-Fa-f0-9]{64}$') { throw ('R04 baseline required hash invalid: ' + $name) }
    }
    if ($Baseline.hashes.PSObject.Properties['reader_config'] -and [string]$Baseline.hashes.reader_config) {
        if ([string]$Baseline.hashes.reader_config -notmatch '^[A-Fa-f0-9]{64}$') { throw 'R04 baseline reader_config hash invalid' }
    }
}

function Assert-RepairedConfig([object]$Cfg) {
    if ($null -eq $Cfg.agents -or $null -eq $Cfg.agents.defaults -or $null -eq $Cfg.agents.defaults.compaction) { throw 'fixed:main compaction config missing' }
    $c = $Cfg.agents.defaults.compaction
    if ([int]$c.reserveTokensFloor -ne 2048) { throw 'fixed:main reserveTokensFloor not 2048' }
    if ([int]$c.reserveTokens -ne 2048) { throw 'fixed:main reserveTokens not 2048' }
    if ([int]$c.keepRecentTokens -ne 4000) { throw 'fixed:main keepRecentTokens not 4000' }

    $main = $null
    if ($Cfg.agents.PSObject.Properties['list']) { $main = @($Cfg.agents.list | Where-Object { [string]$_.id -eq 'main' }) | Select-Object -First 1 }
    $modelRef = ''
    if ($main -and $main.model) {
        if ($main.model -is [string]) { $modelRef = [string]$main.model }
        elseif ($main.model.PSObject.Properties['primary']) { $modelRef = [string]$main.model.primary }
    }
    if (-not $modelRef -and $Cfg.agents.defaults.model) {
        if ($Cfg.agents.defaults.model -is [string]) { $modelRef = [string]$Cfg.agents.defaults.model }
        elseif ($Cfg.agents.defaults.model.PSObject.Properties['primary']) { $modelRef = [string]$Cfg.agents.defaults.model.primary }
    }
    if ($modelRef -ne 'ollama-chat-16k/qwen2.5:14b') { throw ('fixed:main model mismatch: ' + $modelRef) }

    $provider = $Cfg.models.providers.PSObject.Properties['ollama-chat-16k'].Value
    if ($null -eq $provider) { throw 'ollama-chat-16k provider missing' }
    $entry = @($provider.models | Where-Object { [string]$_.id -eq 'qwen2.5:14b' }) | Select-Object -First 1
    if ($null -eq $entry) { throw 'qwen2.5:14b provider entry missing' }
    if ([int]$entry.contextTokens -ne 16384 -or [int]$entry.params.num_ctx -ne 16384) { throw 'fixed:main 16k provider contract mismatch' }
}

function Assert-R04OnlyBenchmarkFailure([object]$Latest) {
    if ($null -eq $Latest -or $null -eq $Latest.regression) { throw 'Benchmark latest evidence missing' }
    if ([string]$Latest.status -cne 'FAIL_CRITICAL_REGRESSION') { throw 'Benchmark failure status mismatch' }
    foreach ($pair in @(@('passed',29),@('total',30),@('critical_failures',1))) {
        $value = $Latest.regression.PSObject.Properties[$pair[0]].Value
        if (($value -isnot [int] -and $value -isnot [long]) -or $value -ne $pair[1]) { throw 'Benchmark is not exact 29/30 critical1 precondition' }
    }
    if ($Latest.regression.rows -isnot [Array]) { throw 'Benchmark rows must be an array' }
    $rows = @($Latest.regression.rows)
    if ($rows.Count -ne 30) { throw 'Benchmark row evidence incomplete' }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($row in $rows) {
        if ($null -eq $row -or $row -isnot [pscustomobject]) { throw 'Benchmark row shape invalid' }
        if ($row.id -isnot [string] -or $row.id -cnotmatch '^R(0[1-9]|[12][0-9]|30)$' -or -not $seen.Add($row.id)) { throw 'Benchmark row identity duplicate or unexpected' }
        if ($row.pass -isnot [bool] -or $row.critical -isnot [bool]) { throw 'Benchmark row verdicts must be booleans' }
    }
    $failed = @($rows | Where-Object { -not $_.pass })
    if ($failed.Count -ne 1 -or $failed[0].id -cne 'R04' -or -not $failed[0].critical) { throw 'Benchmark failure is not exactly R04 critical' }
}

function Get-Preflight {
    foreach ($path in @($ConfigPath,$BaselinePath,$BenchmarkPath,$BenchmarkLatest)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ('R04 fixed required file missing: ' + [IO.Path]::GetFileName($path)) }
    }
    $configSha = Get-Sha $ConfigPath
    if ($configSha -ne $ExpectedCurrentConfig) { throw ('R04 current config identity mismatch actual=' + $configSha) }
    $benchmarkSha = Get-Sha $BenchmarkPath
    if ($benchmarkSha -ne $ExpectedBenchmark) { throw ('R04 Benchmark runner identity mismatch actual=' + $benchmarkSha) }
    try { $cfg = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json } catch { throw 'R04 repaired config is not valid JSON' }
    Assert-RepairedConfig $cfg
    try { $baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json } catch { throw 'R04 baseline is not valid JSON' }
    Assert-Baseline $baseline
    if (([string]$baseline.hashes.production_config).ToUpperInvariant() -ne $ExpectedPreviousConfig) { throw ('R04 baseline production_config expected-current mismatch actual=' + [string]$baseline.hashes.production_config) }
    if (([string]$baseline.hashes.benchmark_runner).ToUpperInvariant() -ne $ExpectedBenchmark) { throw 'R04 baseline Benchmark runner anchor mismatch' }
    try { $latest = Get-Content -LiteralPath $BenchmarkLatest -Raw | ConvertFrom-Json } catch { throw 'R04 Benchmark latest is not valid JSON' }
    Assert-R04OnlyBenchmarkFailure $latest
    return [pscustomobject]@{
        config_sha=$configSha
        benchmark_sha=$benchmarkSha
        baseline=$baseline
        baseline_sha=(Get-Sha $BaselinePath)
        non_target_fingerprint=(Get-NonTargetFingerprint $baseline)
    }
}

function Invoke-BenchmarkFresh {
    $deadline = (Get-Date).AddSeconds(90)
    while ((Get-Date) -lt $deadline) {
        $started = [DateTime]::UtcNow
        $psi = New-Object Diagnostics.ProcessStartInfo
        $psi.FileName = 'powershell.exe'
        $psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $BenchmarkPath + '"'
        $psi.WorkingDirectory = $Workspace
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $p = New-Object Diagnostics.Process
        $p.StartInfo = $psi
        if (-not $p.Start()) { throw 'R04 could not start fixed Benchmark runner' }
        $stdoutTask = $p.StandardOutput.ReadToEndAsync(); $stderrTask = $p.StandardError.ReadToEndAsync()
        if (-not $p.WaitForExit(65000)) { try { $p.Kill() } catch {}; $p.WaitForExit(); throw 'R04 Benchmark execution timeout' }
        $stdout = [string]$stdoutTask.Result; $stderr = [string]$stderrTask.Result; $code = [int]$p.ExitCode; $p.Dispose()
        if ($stdout -match '(?i)BENCHMARK\s+SKIP_(ACTIVE_WORK|OVERLAP)') { Start-Sleep -Seconds 5; continue }
        if ($code -ne 0) { throw ('R04 post-change Benchmark failed exit=' + $code) }
        if (-not (Test-Path -LiteralPath $BenchmarkLatest -PathType Leaf)) { throw 'R04 Benchmark latest missing after execution' }
        if ((Get-Item -LiteralPath $BenchmarkLatest).LastWriteTimeUtc -lt $started.AddSeconds(-3)) { throw 'R04 Benchmark evidence is not fresh' }
        $latest = Get-Content -LiteralPath $BenchmarkLatest -Raw | ConvertFrom-Json
        if ([string]$latest.status -ne 'PASS' -or [int]$latest.regression.passed -ne 30 -or [int]$latest.regression.total -ne 30 -or [int]$latest.regression.critical_failures -ne 0) { throw 'R04 post-change Benchmark not 30/30 critical0' }
        return $latest
    }
    throw 'R04 fresh Benchmark retry budget exhausted'
}

function Invoke-SelfTest {
    $b = [pscustomobject]@{
        schema=1;kind='kevin-benchmark-v1-baseline';created_at='test';openclaw='2026.7.1-2';
        hashes=[pscustomobject]@{supervisor=('A'*64);forge=('B'*64);production_config=$ExpectedPreviousConfig;reader_config=('C'*64);goal_os=('D'*64);promotion_policy=('E'*64);benchmark_spec=('F'*64);benchmark_runner=$ExpectedBenchmark};
        policy=[pscustomobject]@{regression_required_percent=100;critical_model_required_percent=100;staging_to_shadow='LOCKED'}
    }
    Assert-Baseline $b
    $before = Get-NonTargetFingerprint $b
    $copy = $b | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $copy.hashes.production_config = $ExpectedCurrentConfig
    if ((Get-NonTargetFingerprint $copy) -ne $before) { throw 'SELFTEST non-target fingerprint changed' }
    $copy.policy.regression_required_percent = 99
    if ((Get-NonTargetFingerprint $copy) -eq $before) { throw 'SELFTEST failed to detect non-target mutation' }
    # Exercise the real PowerShell predicates; Python proof alone is insufficient.
    $fixture = [pscustomobject]@{status='FAIL_CRITICAL_REGRESSION';regression=[pscustomobject]@{
        passed=29;total=30;critical_failures=1;rows=@(1..30 | ForEach-Object {
            [pscustomobject]@{id=('R{0:d2}' -f $_);pass=($_ -ne 4);critical=($_ -eq 4)}
        })
    }}
    Assert-R04OnlyBenchmarkFailure $fixture
    $negativeCases = @(
        { param($x) $x.regression.rows = @() },
        { param($x) $x.regression.rows = $x.regression.rows[0..28] },
        { param($x) $x.regression.rows[29].id = 'R01' },
        { param($x) $x.regression.rows[29].id = 'R99' },
        { param($x) $x.regression.rows[3].pass = 'false' },
        { param($x) $x.regression.rows[3].critical = $false },
        { param($x) $x.regression.passed = '29' },
        { param($x) $x.regression.critical_failures = $true },
        { param($x) $x.status = 'PASS' }
    )
    foreach ($mutate in $negativeCases) {
        $bad = $fixture | ConvertTo-Json -Depth 30 | ConvertFrom-Json
        & $mutate $bad
        $rejected = $false
        try { Assert-R04OnlyBenchmarkFailure $bad } catch { $rejected = $true }
        if (-not $rejected) { throw 'SELFTEST accepted malformed Benchmark evidence' }
    }
    $structural = $b | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $original = Get-NonTargetFingerprint $structural
    $structural | Add-Member -NotePropertyName 'hashes.production_config' -NotePropertyValue 'literal-key'
    if ((Get-NonTargetFingerprint $structural) -eq $original) { throw 'SELFTEST ignored literal target-like key' }
    $original = Get-NonTargetFingerprint $structural
    $structural | Add-Member -NotePropertyName 'empty' -NotePropertyValue ([pscustomobject]@{})
    if ((Get-NonTargetFingerprint $structural) -eq $original) { throw 'SELFTEST ignored empty object' }
    $original = Get-NonTargetFingerprint $structural
    $structural.empty = @()
    if ((Get-NonTargetFingerprint $structural) -eq $original) { throw 'SELFTEST confused empty array and object' }
    $literal = $b | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $literal | Add-Member -NotePropertyName 'x.y' -NotePropertyValue $true
    $nested = $b | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $nested | Add-Member -NotePropertyName 'x' -NotePropertyValue ([pscustomobject]@{y=$true})
    if ((Get-NonTargetFingerprint $literal) -eq (Get-NonTargetFingerprint $nested)) { throw 'SELFTEST confused literal and nested keys' }
    Write-Host 'KEVIN R04 REBASELINE v1 SELFTEST PASS one_leaf_only=true rollback_required=true arbitrary_path=false arbitrary_command=false authority_expansion=false'
}

if ($SelfTest) { Invoke-SelfTest; exit 0 }
if ($Apply -and $CheckOnly) { throw 'Choose only one of -Apply or -CheckOnly' }
if (-not $Apply) { $CheckOnly = $true }

$mutex = New-Object Threading.Mutex($false,'Global\KevinR04ProductionConfigBaseline')
$owned = $false
try {
    try { $owned = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }
    if (-not $owned) { throw 'R04 baseline reconciliation is already active' }
    $pre = Get-Preflight
    if ($CheckOnly) {
        Write-Host ('R04_REBASELINE_READY config=' + $pre.config_sha + ' baseline=' + $pre.baseline_sha + ' target_leaf=hashes.production_config expected_after=' + $ExpectedCurrentConfig)
        exit 0
    }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDir = Join-Path $BackupRoot ('r04-production-config-rebaseline-' + $stamp)
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $backup = Join-Path $backupDir 'baseline.json.before'
    Copy-Item -LiteralPath $BaselinePath -Destination $backup -Force
    if ((Get-Sha $backup) -ne $pre.baseline_sha) { throw 'R04 baseline backup verification failed' }

    $after = $pre.baseline | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $after.hashes.production_config = $ExpectedCurrentConfig
    if ((Get-NonTargetFingerprint $after) -ne $pre.non_target_fingerprint) { throw 'R04 staged baseline changed non-target semantics' }
    $stage = Join-Path $backupDir 'baseline.json.stage'
    [IO.File]::WriteAllText($stage,($after | ConvertTo-Json -Depth 30),$Utf8)
    $stageObj = Get-Content -LiteralPath $stage -Raw | ConvertFrom-Json
    Assert-Baseline $stageObj
    if (([string]$stageObj.hashes.production_config).ToUpperInvariant() -ne $ExpectedCurrentConfig) { throw 'R04 staged target leaf mismatch' }
    if ((Get-NonTargetFingerprint $stageObj) -ne $pre.non_target_fingerprint) { throw 'R04 serialized stage changed non-target semantics' }

    try {
        $tmp = $BaselinePath + '.r04-' + [guid]::NewGuid().ToString('N')
        Copy-Item -LiteralPath $stage -Destination $tmp -Force
        Move-Item -LiteralPath $tmp -Destination $BaselinePath -Force
        $installed = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
        if (([string]$installed.hashes.production_config).ToUpperInvariant() -ne $ExpectedCurrentConfig) { throw 'R04 installed target leaf mismatch' }
        if ((Get-NonTargetFingerprint $installed) -ne $pre.non_target_fingerprint) { throw 'R04 installed baseline changed non-target semantics' }
        if ((Get-Sha $ConfigPath) -ne $ExpectedCurrentConfig) { throw 'R04 production config changed during crossing' }
        if ((Get-Sha $BenchmarkPath) -ne $ExpectedBenchmark) { throw 'R04 Benchmark runner changed during crossing' }
        $null = Invoke-BenchmarkFresh
        $receipt = [ordered]@{
            schema=1;kind='kevin-r04-production-config-rebaseline-receipt';at=(Get-Date).ToString('o');status='APPLIED_PROVEN';safe_for_public_repo=$true;
            config_sha256=$ExpectedCurrentConfig;baseline_before_sha256=$pre.baseline_sha;baseline_after_sha256=(Get-Sha $BaselinePath);
            target_leaf='hashes.production_config';previous_anchor=$ExpectedPreviousConfig;current_anchor=$ExpectedCurrentConfig;
            non_target_semantics_preserved=$true;benchmark='PASS_30_OF_30_CRITICAL_0';rollback_available=$true
        }
        Write-JsonAtomic $ReceiptPath $receipt
        Write-Host ('R04_REBASELINE_APPLIED_PROVEN baseline_after=' + (Get-Sha $BaselinePath) + ' benchmark=30/30 critical=0')
    } catch {
        Copy-Item -LiteralPath $backup -Destination $BaselinePath -Force
        if ((Get-Sha $BaselinePath) -ne $pre.baseline_sha) { throw ('R04 rollback integrity failure after: ' + $_.Exception.Message) }
        $failure = [ordered]@{schema=1;kind='kevin-r04-production-config-rebaseline-receipt';at=(Get-Date).ToString('o');status='ROLLED_BACK';safe_for_public_repo=$true;config_sha256=$ExpectedCurrentConfig;baseline_restored_sha256=$pre.baseline_sha;target_leaf='hashes.production_config';rollback_proven=$true}
        Write-JsonAtomic $ReceiptPath $failure
        throw ('R04 crossing failed; exact baseline rollback completed: ' + $_.Exception.Message)
    }
} finally {
    if ($owned) { try { $mutex.ReleaseMutex() } catch {} }
    $mutex.Dispose()
}
