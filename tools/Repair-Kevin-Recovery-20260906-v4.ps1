param(
    [switch]$CheckOnly,
    [switch]$Apply,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)

# Recovery v4 is intentionally a narrow evidence-location wrapper around the
# already Windows-qualified Recovery v3 engine. It does not change v3's R04,
# rollback, Benchmark, UI task, or Notepad proof logic.
$V3Sha = 'DAC43A78079A5FA4BDF5E212E265EEBE37950CA4F72E604F50833C86DE3A7D7F'
$EvidenceSha = 'EEC855AA7B3677335477634C2D60B2573D75B27ECAA8CCEF96E248CD9949838A'
$ConfigSha = '29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA'
$SourceCommit = '131f3afd51413f228be64ef660a8e51d9be96a0e'
$SourceBlob = 'ec76565f225fdcb880ab0bbad6a58b5d555e2de0'
$IsolationSourceSha = 'A8A6B2311608A17D3609F74CF02632A0314BD774CA50283FEDD1834E6390DCD2'
$VisibleToolsSha = '564D5607031E853D56F7327E93D6DC81E236F4CDAB2B4478B29FB38925D726CD'
$TranscriptSha = '719DB25A60E76EFCE1EA5A76E524C702BF37162883468FB0C1EE89A5A57702C2'
$OutputSha = 'E584CFA617FA4FC9B813C9151D696AFA0983DC26414EC18F23CA0D895C9882F8'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$V3Path = Join-Path $ScriptRoot 'Repair-Kevin-Recovery-20260906-v3.ps1'
$EvidencePath = Join-Path $ScriptRoot 'Kevin-Recovery-Main-Canary-20260906.json'
$Workspace = Join-Path (Join-Path $env:USERPROFILE '.openclaw') 'workspace'
$MainCanaryPath = Join-Path $Workspace 'reports\main-agent-canary-omen.json'
$IsolationPath = Join-Path $Workspace 'reports\ollama-isolate-latest.json'

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Read-Json([string]$Path) {
    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}
function Get-Prop([object]$Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}
function Assert-ExactIsolation([object]$Iso) {
    if ([string]$Iso.kind -cne 'kevin-ollama-isolation-receipt' -or
        [string]$Iso.status -cne 'PASS' -or
        [bool]$Iso.tool_execution_attempted -or
        [string]$Iso.source_sha256 -cne $IsolationSourceSha) {
        throw 'Local Ollama isolation receipt contract changed'
    }
    $models = @($Iso.models)
    if ($models.Count -ne 2) { throw 'Local isolation receipt must contain exactly two models' }
    foreach ($name in @('llama3.1:8b','qwen2.5:14b')) {
        $row = @($models | Where-Object { [string]$_.model -ceq $name })
        if ($row.Count -ne 1 -or [string]$row[0].status -cne 'PASS') {
            throw ('Local isolation PASS missing for ' + $name)
        }
    }
}
function Assert-ExactCanary([object]$Canary) {
    if ([string]$Canary.kind -cne 'kevin-main-agent-canary-public' -or
        [string]$Canary.state -cne 'OMEN_PROVEN' -or
        [string]$Canary.agent -cne 'fixed:main' -or
        -not [bool]$Canary.gateway_probe_ok -or
        [int]$Canary.agent_exit_code -ne 0 -or
        [string]$Canary.status -cne 'ok' -or
        -not [bool]$Canary.exact_expected_reply -or
        [int]$Canary.tool_calls -ne 0 -or
        [int]$Canary.visible_tool_count -ne 5 -or
        [int]$Canary.visible_kevin_tool_count -ne 5 -or
        [string]$Canary.visible_tool_names_sha256 -cne $VisibleToolsSha -or
        -not [bool]$Canary.has_kevin_system_status -or
        [string]$Canary.output_sha256 -cne $OutputSha -or
        [string]$Canary.runner_version -cne '1.3.43+modelid') {
        throw 'Published fixed-main canary contract changed'
    }
    $shape = Get-Prop $Canary 'canary_shape'
    $tx = Get-Prop $shape 'transcript'
    if ($null -eq $tx -or
        -not [bool](Get-Prop $tx 'present') -or
        -not [bool](Get-Prop $tx 'complete') -or
        [int](Get-Prop $tx 'tool_calls') -ne 0 -or
        -not [bool](Get-Prop $tx 'final_exact') -or
        [string](Get-Prop $tx 'sha256') -cne $TranscriptSha -or
        [string](Get-Prop $tx 'provider') -cne 'ollama-chat-16k' -or
        [string](Get-Prop $tx 'model_id') -cne 'qwen2.5:14b') {
        throw 'Published fixed-main correlated transcript contract changed'
    }
}
function Get-PinnedEvidence {
    if ((Get-Sha $EvidencePath) -cne $EvidenceSha) {
        throw 'Pinned recovery canary evidence file missing or SHA256 mismatch'
    }
    $e = Read-Json $EvidencePath
    if ([int]$e.schema -ne 1 -or
        [string]$e.kind -cne 'kevin-recovery-main-canary-evidence' -or
        [string]$e.qualified_config_sha256 -cne $ConfigSha -or
        [string]$e.source_repository -cne 'hessmodee/KEVIN-WORK' -or
        [string]$e.source_commit -cne $SourceCommit -or
        [string]$e.source_path -cne 'reports/main-agent-canary-omen.json' -or
        [string]$e.source_blob_sha1 -cne $SourceBlob) {
        throw 'Pinned recovery canary evidence envelope changed'
    }
    Assert-ExactCanary $e.canary
    return $e
}
function Assert-EvidenceTimeline([object]$Evidence) {
    if (-not (Test-Path -LiteralPath $IsolationPath -PathType Leaf)) {
        throw 'Fresh local Ollama isolation receipt missing'
    }
    $iso = Read-Json $IsolationPath
    Assert-ExactIsolation $iso
    $now = [DateTimeOffset]::Now
    $isoAt = [DateTimeOffset]::Parse([string]$iso.generated_at)
    $canaryAt = [DateTimeOffset]::Parse([string]$Evidence.canary.generated_at)
    if (($now - $isoAt).TotalHours -gt 12 -or ($isoAt - $now).TotalMinutes -gt 5) {
        throw 'Local Ollama isolation receipt is stale or future-dated'
    }
    if (($now - $canaryAt).TotalHours -gt 12 -or ($canaryAt - $now).TotalMinutes -gt 5) {
        throw 'Pinned fixed-main canary is stale or future-dated'
    }
    if ($canaryAt -lt $isoAt) {
        throw 'Pinned fixed-main canary predates the local dual-model isolation proof'
    }
}
function Write-StagedCanary([object]$Canary) {
    $dir = Split-Path -Parent $MainCanaryPath
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        throw 'Kevin reports directory missing; refusing to create a new workspace structure'
    }
    if (Test-Path -LiteralPath $MainCanaryPath -PathType Leaf) {
        throw 'Local main-agent canary appeared during staging; refusing to overwrite it'
    }
    $tmp = $MainCanaryPath + '.recovery-v4-' + $PID + '-' + [guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::WriteAllText($tmp, ($Canary | ConvertTo-Json -Depth 60), $Utf8)
        Move-Item -LiteralPath $tmp -Destination $MainCanaryPath
    } finally {
        if (Test-Path -LiteralPath $tmp -PathType Leaf) {
            Remove-Item -LiteralPath $tmp -Force
        }
    }
    return (Get-Sha $MainCanaryPath)
}
function Invoke-V3([switch]$DoApply) {
    if ((Get-Sha $V3Path) -cne $V3Sha) {
        throw 'Recovery v3 engine missing or SHA256 mismatch'
    }
    $args = @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$V3Path)
    if ($DoApply) { $args += '-Apply' } else { $args += '-CheckOnly' }
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& powershell.exe @args 2>&1)
        $code = [int]$LASTEXITCODE
    } finally {
        $ErrorActionPreference = $old
    }
    $output | ForEach-Object { Write-Host $_ }
    if ($code -ne 0) { throw ('Recovery v3 engine exited ' + $code) }
    $joined = ($output | Out-String)
    if (-not $DoApply -and $joined -notmatch 'KEVIN_RECOVERY_V3_READY') {
        throw 'Recovery v3 returned zero without its READY marker'
    }
    if ($DoApply -and $joined -notmatch 'KEVIN_RECOVERY_V3_APPLIED_PROVEN') {
        throw 'Recovery v3 returned zero without its APPLIED_PROVEN marker'
    }
}
function Invoke-SelfTest {
    foreach ($sha in @($V3Sha,$EvidenceSha,$ConfigSha,$IsolationSourceSha,$VisibleToolsSha,$TranscriptSha,$OutputSha)) {
        if ($sha -cnotmatch '^[A-F0-9]{64}$') { throw 'Malformed SHA256 pin' }
    }
    if ($SourceCommit -cnotmatch '^[a-f0-9]{40}$' -or $SourceBlob -cnotmatch '^[a-f0-9]{40}$') {
        throw 'Malformed Git identity pin'
    }
    Write-Host 'KEVIN RECOVERY V4 SELFTEST PASS wrapper_only=true v3_engine_pinned=true sidecar_pinned=true source_commit_pinned=true source_blob_pinned=true local_evidence_outranks_fallback=true transient_stage_cleanup_guarded=true arbitrary_shell=false network=false'
}

if ($SelfTest) { Invoke-SelfTest; exit 0 }
if ($Apply -and $CheckOnly) { throw 'Choose only one of -Apply or -CheckOnly' }
if (-not $Apply) { $CheckOnly = $true }
if ($env:OS -ne 'Windows_NT') { throw 'Run this on the Windows PC that hosts Kevin' }

$mutex = New-Object Threading.Mutex($false,'Global\KevinPlatformRecovery20260906V4')
$owned = $false
$createdStage = $false
$stagedSha = ''
try {
    try { $owned = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }
    if (-not $owned) { throw 'Kevin Recovery v4 is already active' }

    if (Test-Path -LiteralPath $MainCanaryPath -PathType Leaf) {
        # Never mask a contradictory local receipt with published fallback evidence.
        $local = Read-Json $MainCanaryPath
        Assert-ExactCanary $local
        $iso = Read-Json $IsolationPath
        Assert-ExactIsolation $iso
        $localAt = [DateTimeOffset]::Parse([string]$local.generated_at)
        $isoAt = [DateTimeOffset]::Parse([string]$iso.generated_at)
        $now = [DateTimeOffset]::Now
        if (($now - $localAt).TotalHours -gt 12 -or $localAt -lt $isoAt) {
            throw 'Existing local main-agent canary is stale or predates current isolation; refusing published fallback'
        }
        Invoke-V3 -DoApply:$Apply
        if ($CheckOnly) { Write-Host 'KEVIN_RECOVERY_V4_READY canary_source=existing_local v3=qualified staged=false' }
        else { Write-Host 'KEVIN_RECOVERY_V4_APPLIED_PROVEN canary_source=existing_local v3=proven' }
        exit 0
    }

    $evidence = Get-PinnedEvidence
    Assert-EvidenceTimeline $evidence
    $stagedSha = Write-StagedCanary $evidence.canary
    $createdStage = $true

    Invoke-V3 -DoApply:$Apply

    if ($CheckOnly) {
        Write-Host 'KEVIN_RECOVERY_V4_READY canary_source=pinned_commit_131f3 staged_transient=true v3=qualified'
    } else {
        Write-Host 'KEVIN_RECOVERY_V4_APPLIED_PROVEN canary_source=pinned_commit_131f3 staged_transient=true v3=proven'
    }
} finally {
    if ($createdStage -and (Test-Path -LiteralPath $MainCanaryPath -PathType Leaf)) {
        $currentSha = Get-Sha $MainCanaryPath
        if ($currentSha -ceq $stagedSha) {
            Remove-Item -LiteralPath $MainCanaryPath -Force
            Write-Host 'KEVIN_RECOVERY_V4_STAGED_CANARY_CLEANUP verified=true'
        } else {
            Write-Warning 'Recovery v4 did not remove staged canary because its bytes changed after staging; preserving newer/contradictory evidence.'
        }
    }
    if ($owned) { try { $mutex.ReleaseMutex() } catch {} }
    $mutex.Dispose()
}
