param(
    [switch]$CheckOnly,
    [switch]$Apply,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

# V2 is a fail-closed compatibility wrapper around the exact reviewed/merged V1
# candidate. V1 incorrectly required the informational baseline benchmark_runner
# anchor to equal the currently executed Benchmark script, even though R04 only
# reconciles hashes.production_config and the live Benchmark independently pins
# its executable identity. V2 removes only that over-constraint, preserves the
# baseline runner anchor as non-target state, and strengthens the self-test.
$Repo = 'hessmodee/KEVIN-WORK'
$V1Commit = 'e57bf5b013bbbbad98a4c34b0e933c8d2912bfe5'
$V1Path = 'candidates/maintenance/r04-production-config-rebaseline-v1/kevin-r04-production-config-rebaseline-v1.ps1'
$V1Blob = '3a3289d1ab4cb4d92062638cda01a3548b7e6cd2'

function Count-Ordinal([string]$Text,[string]$Needle) {
    if (-not $Needle) { throw 'empty transform needle' }
    $count = 0
    $offset = 0
    while ($true) {
        $i = $Text.IndexOf($Needle,$offset,[StringComparison]::Ordinal)
        if ($i -lt 0) { break }
        $count++
        $offset = $i + $Needle.Length
    }
    return $count
}

function Get-V1Text {
    $gh = Get-Command gh.exe -ErrorAction SilentlyContinue
    if (-not $gh) { $gh = Get-Command gh -ErrorAction Stop }
    $endpoint = 'repos/' + $Repo + '/contents/' + $V1Path + '?ref=' + $V1Commit
    $oldGh = [Environment]::GetEnvironmentVariable('GH_TOKEN','Process')
    $oldGithub = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    try {
        $env:GH_PROMPT_DISABLED = '1'
        $raw = (& $gh.Source api $endpoint -H 'Accept: application/vnd.github+json' 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) { throw ('Pinned R04 V1 fetch failed: ' + $raw) }
        $meta = $raw | ConvertFrom-Json
        if ([string]$meta.sha -cne $V1Blob) { throw ('Pinned R04 V1 blob mismatch actual=' + [string]$meta.sha) }
        $bytes = [Convert]::FromBase64String(([string]$meta.content -replace '\s',''))
        return [Text.Encoding]::UTF8.GetString($bytes)
    }
    finally {
        if ($null -ne $oldGh) { $env:GH_TOKEN=$oldGh } else { Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue }
        if ($null -ne $oldGithub) { $env:GITHUB_TOKEN=$oldGithub } else { Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue }
    }
}

function Convert-V1ToV2([string]$Text) {
    $badGuard = "    if (([string]`$baseline.hashes.benchmark_runner).ToUpperInvariant() -ne `$ExpectedBenchmark) { throw 'R04 baseline Benchmark runner anchor mismatch' }"
    if ((Count-Ordinal $Text $badGuard) -ne 1) { throw 'R04 V1 runner-anchor guard shape changed; refusing transform' }
    $guardReplacement = @"
    # benchmark_runner is a preserved non-target baseline anchor. The currently
    # executed Benchmark runner is independently pinned by Get-Sha `$BenchmarkPath.
    # Do not silently rebaseline this unrelated anchor as part of R04.
    `$baselineRunnerAnchor = ([string]`$baseline.hashes.benchmark_runner).ToUpperInvariant()
    if (`$baselineRunnerAnchor -notmatch '^[A-F0-9]{64}$') { throw 'R04 baseline Benchmark runner anchor malformed' }
"@.TrimEnd("`r","`n")
    $Text = $Text.Replace($badGuard,$guardReplacement)

    $fixtureNeedle = 'benchmark_runner=$ExpectedBenchmark'
    if ((Count-Ordinal $Text $fixtureNeedle) -ne 1) { throw 'R04 V1 self-test runner fixture shape changed; refusing transform' }
    $Text = $Text.Replace($fixtureNeedle,"benchmark_runner=('9'*64)")

    $fingerprintNeedle = '    $before = Get-NonTargetFingerprint $b'
    if ((Count-Ordinal $Text $fingerprintNeedle) -ne 1) { throw 'R04 V1 fingerprint self-test shape changed; refusing transform' }
    $fingerprintReplacement = @"
    `$before = Get-NonTargetFingerprint `$b
    `$runnerMutation = `$b | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    `$runnerMutation.hashes.benchmark_runner = ('8'*64)
    if ((Get-NonTargetFingerprint `$runnerMutation) -eq `$before) { throw 'SELFTEST benchmark_runner is not protected as non-target state' }
"@.TrimEnd("`r","`n")
    $Text = $Text.Replace($fingerprintNeedle,$fingerprintReplacement)

    $marker = 'KEVIN R04 REBASELINE v1 SELFTEST PASS one_leaf_only=true rollback_required=true arbitrary_path=false arbitrary_command=false authority_expansion=false'
    if ((Count-Ordinal $Text $marker) -ne 1) { throw 'R04 V1 self-test marker shape changed; refusing transform' }
    $Text = $Text.Replace($marker,'KEVIN R04 REBASELINE v2 SELFTEST PASS one_leaf_only=true runner_anchor=preserved benchmark_runner_live=pinned rollback_required=true arbitrary_path=false arbitrary_command=false authority_expansion=false')

    return $Text
}

function New-TransformedCandidate {
    $text = Convert-V1ToV2 (Get-V1Text)
    $path = Join-Path $env:TEMP ('kevin-r04-v2-' + [guid]::NewGuid().ToString('N') + '.ps1')
    [IO.File]::WriteAllText($path,$text,$Utf8)
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue; throw ('R04 V2 parser rejected: ' + $errors[0].Message) }
    return $path
}

function Invoke-Candidate([string]$Path,[string]$Switch) {
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path $Switch 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    }
    finally { $ErrorActionPreference = $old }
    if ($out) { Write-Host $out }
    if ($code -ne 0) { throw ('R04 V2 child failed exit=' + $code) }
    return $out
}

function Invoke-SelfTest {
    if ($V1Commit -cnotmatch '^[a-f0-9]{40}$' -or $V1Blob -cnotmatch '^[a-f0-9]{40}$') { throw 'R04 V1 Git pin malformed' }
    $candidate = New-TransformedCandidate
    try {
        $out = Invoke-Candidate $candidate '-SelfTest'
        if ($out -notmatch 'R04 REBASELINE v2 SELFTEST PASS') { throw 'R04 V2 transformed self-test marker missing' }
    }
    finally { Remove-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue }
    Write-Host 'KEVIN R04 V2 WRAPPER SELFTEST PASS source=v1_exact transform=fail_closed runner_anchor=preserved'
}

if ($SelfTest) { Invoke-SelfTest; exit 0 }
if ($Apply -and $CheckOnly) { throw 'Choose only one of -Apply or -CheckOnly' }
if (-not $Apply) { $CheckOnly = $true }

$candidate = New-TransformedCandidate
try {
    $switch = if ($Apply) { '-Apply' } else { '-CheckOnly' }
    $out = Invoke-Candidate $candidate $switch
    if ($Apply -and $out -notmatch 'R04_REBASELINE_APPLIED_PROVEN') { throw 'R04 V2 apply proof marker missing' }
    if ($CheckOnly -and $out -notmatch 'R04_REBASELINE_READY') { throw 'R04 V2 check proof marker missing' }
}
finally { Remove-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue }
