param(
    [Parameter(Mandatory = $true)][string]$WorkId,
    [Parameter(Mandatory = $true)][string]$SkillKey,
    [Parameter(Mandatory = $true)][string]$RequestId
)
# Kevin Proven Skill Invoke Worker v1.1
# Authority delta: NONE. Stages GREEN invocation work orders only.
# Source wrap only. Do not replace live pin 16C49542 while v1812 slot remains.
# Change vs v1: $ErrorActionPreference Continue around native python so stderr
# NativeCommandError is not a terminating throw when LASTEXITCODE is 0.
# CreateNoWindow so nested python does not flash a console on Windows.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'
$Utf8 = New-Object Text.UTF8Encoding($false)

if ($WorkId -notmatch '^[A-Za-z0-9._-]{4,96}$') { throw 'WORK_ID_INVALID' }
if ($SkillKey -notmatch '^[A-Za-z0-9._-]{4,80}@[A-Za-z0-9._-]{1,32}$') { throw 'SKILL_KEY_INVALID' }
if ($RequestId -notmatch '^[A-Za-z0-9._-]{4,96}$') { throw 'REQUEST_ID_INVALID' }
if ($SkillKey -ne 'west-motor-parts-chase-board-pack@1') { throw 'SKILL_KEY_NOT_INVOCATION_V1_COMPATIBLE' }

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$Builder = Join-Path $Workspace 'control-plane\autonomy\kevin-proven-skill-request-builder-v1.py'
if (-not (Test-Path -LiteralPath $Builder)) { $Builder = Join-Path $PSScriptRoot '..\control-plane\autonomy\kevin-proven-skill-request-builder-v1.py' }
$Invoker = Join-Path $Workspace 'control-plane\autonomy\kevin-proven-skill-invocation-v1.py'
if (-not (Test-Path -LiteralPath $Invoker)) { $Invoker = Join-Path $PSScriptRoot '..\control-plane\autonomy\kevin-proven-skill-invocation-v1.py' }
$Items = Join-Path $Workspace 'inbox\autonomy\work-items.json'
$Registry = Join-Path $Workspace 'reports\capabilities\composite-skills.json'
$ProofRoot = Join-Path $Workspace 'reports\action-era\skills\done'
$Ready = Join-Path $Workspace 'reports\action-era\queue\ready'
$Done = Join-Path $Workspace 'reports\action-era\queue\done'
$Failed = Join-Path $Workspace 'reports\action-era\queue\failed'
$RunRoot = Join-Path $Workspace 'reports\invocations\runs'
$ReceiptRoot = Join-Path $Workspace 'reports\invocations\done'
$ArtifactRoot = Join-Path $Workspace 'reports\invocations\artifacts'
foreach ($d in @($Ready, $Done, $Failed, $RunRoot, $ReceiptRoot, $ArtifactRoot)) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

function Invoke-HiddenPython {
    param([Parameter(Mandatory = $true)][string[]]$PyArgs)
    $py = $null
    foreach ($cand in @('python', 'python3', 'py')) {
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if ($cmd) { $py = $cmd.Source; break }
    }
    if (-not $py) { throw 'PYTHON_NOT_AVAILABLE' }
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
    return [pscustomobject]@{
        ExitCode = [int]$p.ExitCode
        StdOut   = [string]$stdout
        StdErr   = [string]$stderr
        Combined = ([string]$stdout + [string]$stderr).Trim()
    }
}

$requestPath = Join-Path $RunRoot ($RequestId + '.request.json')
$statePath = Join-Path $RunRoot ($RequestId + '.json')
$receiptPath = Join-Path $ReceiptRoot ($RequestId + '.json')

$builderArgs = @($Builder, '--invocation-id', $RequestId, '--output', $requestPath)
if (Test-Path -LiteralPath $Items) { $builderArgs += @('--work-items', $Items, '--work-id', $WorkId) }
$built = Invoke-HiddenPython -PyArgs $builderArgs
if ($built.ExitCode -ne 0) { throw ('BUILDER_REJECTED ' + $built.Combined) }

$stage = Invoke-HiddenPython -PyArgs @($Invoker, 'stage', '--registry', $Registry, '--proof-root', $ProofRoot, '--request', $requestPath, '--state', $statePath, '--queue-ready', $Ready)
if ($stage.ExitCode -ne 0) { throw ('STAGE_REJECTED ' + $stage.Combined) }

$reconcile = Invoke-HiddenPython -PyArgs @($Invoker, 'reconcile', '--state', $statePath, '--queue-done', $Done, '--queue-failed', $Failed, '--receipt', $receiptPath, '--artifact-root', $ArtifactRoot)
if ($reconcile.ExitCode -eq 2) { throw ('RECONCILE_REJECTED ' + $reconcile.Combined) }

$out = [ordered]@{
    schema = 1
    kind = 'kevin-proven-skill-invoke-worker-result'
    version = '1.1.0'
    status = 'STAGED'
    authority = 'GREEN'
    work_id = $WorkId
    skill_key = $SkillKey
    invocation_id = $RequestId
    request_path = 'reports/invocations/runs/' + $RequestId + '.request.json'
    state_path = 'reports/invocations/runs/' + $RequestId + '.json'
    outcome_proven = $false
}
Write-Output ($out | ConvertTo-Json -Depth 8)
exit 0
