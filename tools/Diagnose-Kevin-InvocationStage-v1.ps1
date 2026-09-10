param([switch]$SelfTest)
# Diagnose-Kevin-InvocationStage-v1.ps1
# GREEN-A/C. Runs builder+stage against live HESS-PC files and publishes ONLY
# a reason-code (+ hashes). No raw logs, configs, environment, or secrets.
# Uses an isolated diagnose queue so it cannot collide with Supervisor orders.
# Does not recopy Supervisor. Does not replace the live worker pin. Not PASS.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$Autonomy = Join-Path $Workspace 'control-plane\autonomy'
$Builder = Join-Path $Autonomy 'kevin-proven-skill-request-builder-v1.py'
$Invoker = Join-Path $Autonomy 'kevin-proven-skill-invocation-v1.py'
$Items = Join-Path $Workspace 'inbox\autonomy\work-items.json'
$Registry = Join-Path $Workspace 'reports\capabilities\composite-skills.json'
$ProofRoot = Join-Path $Workspace 'reports\action-era\skills\done'
$Ready = Join-Path $Workspace 'reports\invocations\diagnose-ready'
$RunRoot = Join-Path $Workspace 'reports\invocations\diagnose-runs'
$OutDir = Join-Path $Workspace 'reports\invocations'
$LiveReady = Join-Path $Workspace 'reports\action-era\queue\ready'
$WorkId = 'owner-west-motor-parts-chase-fresh-8-v1'
$RequestId = 'diagnose-' + $WorkId
$InvExpected = '471E505151E211C254FAB9DD090AEA76E7D304B01333FEA03B115D2ECE39B7E8'
$BldExpected = '93A8A881E04CC8E6AE0B900275C6158AF166484F663988EBB564BC47C4140031'

function Get-Sha256Upper([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return ([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($Path)) | ForEach-Object { $_.ToString('X2') }) -join ''
}
function Write-Utf8NoBom([string]$Path, [string]$Text) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, $Utf8)
}
function Reason-FromJson([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    try {
        $o = $Text | ConvertFrom-Json
        if ($o.reason) { return [string]$o.reason }
        if ($o.status) { return [string]$o.status }
    } catch {}
    if ($Text -match '([A-Z][A-Z0-9_]{5,80})') { return $Matches[1] }
    return 'UNPARSEABLE_REASON'
}

if ($SelfTest) {
    if ($InvExpected.Length -ne 64) { throw 'inv hash pin' }
    Write-Host 'KEVIN INVOCATION STAGE DIAGNOSE v1 SELFTEST PASS'
    exit 0
}

New-Item -ItemType Directory -Force -Path $RunRoot, $Ready, $OutDir | Out-Null
$invHash = Get-Sha256Upper $Invoker
$bldHash = Get-Sha256Upper $Builder
$missing = @()
foreach ($pair in @(@('builder',$Builder), @('invoker',$Invoker), @('registry',$Registry), @('work-items',$Items), @('proof-root',$ProofRoot))) {
    if (-not (Test-Path -LiteralPath $pair[1])) { $missing += $pair[0] }
}

$reason = 'NOT_RUN'
$class = 'PRECHECK'
$exitCode = -1
$readyCount = 0
$liveReadyCount = 0
if ($missing.Count -gt 0) {
    $reason = 'MISSING:' + (($missing | Select-Object -First 6) -join ',')
    $class = 'MISSING_INPUT'
} elseif ($invHash -ne $InvExpected -or $bldHash -ne $BldExpected) {
    $reason = 'PYTHON_HASH_MISMATCH'
    $class = 'PYTHON_NOT_V112'
} else {
    $py = $null
    foreach ($cand in @('python','python3','py')) {
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if ($cmd) { $py = $cmd.Source; break }
    }
    if (-not $py) {
        $reason = 'PYTHON_NOT_AVAILABLE'
        $class = 'PYTHON_NOT_AVAILABLE'
    } else {
        $req = Join-Path $RunRoot ($RequestId + '.request.json')
        $st = Join-Path $RunRoot ($RequestId + '.json')
        if (Test-Path -LiteralPath $st) { Remove-Item -LiteralPath $st -Force }
        function Invoke-HiddenPython([string[]]$PyArgs) {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $py
            $psi.Arguments = ($PyArgs | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.CreateNoWindow = $true
            $p = New-Object System.Diagnostics.Process
            $p.StartInfo = $psi
            [void]$p.Start()
            $stdout = $p.StandardOutput.ReadToEnd()
            $stderr = $p.StandardError.ReadToEnd()
            $p.WaitForExit()
            return [pscustomobject]@{ ExitCode = [int]$p.ExitCode; Combined = ([string]$stdout + [string]$stderr).Trim() }
        }
        $built = Invoke-HiddenPython @($Builder, '--invocation-id', $RequestId, '--output', $req, '--work-items', $Items, '--work-id', $WorkId)
        if ($built.ExitCode -ne 0) {
            $reason = Reason-FromJson $built.Combined
            if (-not $reason) { $reason = 'BUILDER_REJECTED' }
            $class = 'BUILDER_REJECTED'
            $exitCode = $built.ExitCode
        } else {
            $stage = Invoke-HiddenPython @($Invoker, 'stage', '--registry', $Registry, '--proof-root', $ProofRoot, '--request', $req, '--state', $st, '--queue-ready', $Ready)
            $exitCode = $stage.ExitCode
            if ($stage.ExitCode -ne 0) {
                $reason = Reason-FromJson $stage.Combined
                if (-not $reason) { $reason = 'STAGE_REJECTED' }
                $class = 'STAGE_REJECTED'
            } else {
                $reason = 'STAGE_OK_WAITING_ACTION_ERA'
                $class = 'STAGED'
            }
        }
    }
}
if (Test-Path -LiteralPath $Ready) {
    $readyCount = @(Get-ChildItem -LiteralPath $Ready -File -Filter 'invoke-*.json' -ErrorAction SilentlyContinue).Count
}
if (Test-Path -LiteralPath $LiveReady) {
    $liveReadyCount = @(Get-ChildItem -LiteralPath $LiveReady -File -Filter 'invoke-*.json' -ErrorAction SilentlyContinue).Count
}

$reject = [ordered]@{
    schema = 1
    kind = 'kevin-invocation-public-reject'
    version = '1.2.0'
    authority = 'GREEN'
    generated_at = [datetime]::Now.ToString('o')
    safe_for_public_repo = $true
    public_payload_policy = 'reason-code and hashes only; no raw logs, configs, environment, or secrets'
    work_id_hint = $WorkId
    reason = $reason
    reason_class = $class
    python_exit = $exitCode
    invocation_py_sha256 = $invHash
    builder_py_sha256 = $bldHash
    expected_invocation_py_sha256 = $InvExpected
    expected_builder_py_sha256 = $BldExpected
    diagnose_ready_count = $readyCount
    live_action_era_ready_invoke_count = $liveReadyCount
    isolated_diagnose_queue = $true
    outcome_proven = $false
    truth_boundary = 'Diagnostic reason-code only. Isolated diagnose queue is not Action Era. STAGE_OK is not PASS. PASS still requires workbook + note + DONE + hashes + receipt.'
}
$outPath = Join-Path $OutDir 'latest-public-reject.json'
Write-Utf8NoBom $outPath (($reject | ConvertTo-Json -Depth 6) + "`n")
Write-Output ($reject | ConvertTo-Json -Depth 6)

try {
    $b64 = [Convert]::ToBase64String($Utf8.GetBytes((Get-Content -Raw $outPath)))
    $api = 'repos/hessmodee/KEVIN-WORK/contents/reports/invocations/latest-public-reject.json'
    $sha = $null
    try { $sha = gh api $api --jq .sha 2>$null } catch {}
    if ($sha) { gh api --method PUT $api -f message='invocation diagnose' -f content=$b64 -f sha=$sha | Out-Null }
    else { gh api --method PUT $api -f message='invocation diagnose' -f content=$b64 | Out-Null }
} catch { Write-Host "upload skip: $_" }
exit 0
