param(
    [Parameter(Mandatory = $true)][string]$WorkId,
    [Parameter(Mandatory = $true)][string]$SkillKey,
    [Parameter(Mandatory = $true)][string]$RequestId
)
# Kevin Proven Skill Invoke Worker v1
# Authority delta: NONE. Stages GREEN invocation work orders only.
# Does not execute shell, purchases, Skill Lab requalification, or fixed:main.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
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

$py = $null
foreach ($cand in @('python', 'python3', 'py')) {
    $cmd = Get-Command $cand -ErrorAction SilentlyContinue
    if ($cmd) { $py = $cmd.Source; break }
}
if (-not $py) { throw 'PYTHON_NOT_AVAILABLE' }

$requestPath = Join-Path $RunRoot ($RequestId + '.request.json')
$statePath = Join-Path $RunRoot ($RequestId + '.json')
$receiptPath = Join-Path $ReceiptRoot ($RequestId + '.json')

$builderArgs = @($Builder, '--invocation-id', $RequestId, '--output', $requestPath)
if (Test-Path -LiteralPath $Items) { $builderArgs += @('--work-items', $Items, '--work-id', $WorkId) }
$built = & $py @builderArgs
if ($LASTEXITCODE -ne 0) { throw ('BUILDER_REJECTED ' + $built) }

$stage = & $py $Invoker 'stage' '--registry' $Registry '--proof-root' $ProofRoot '--request' $requestPath '--state' $statePath '--queue-ready' $Ready
if ($LASTEXITCODE -ne 0) { throw ('STAGE_REJECTED ' + $stage) }

$reconcile = & $py $Invoker 'reconcile' '--state' $statePath '--queue-done' $Done '--queue-failed' $Failed '--receipt' $receiptPath '--artifact-root' $ArtifactRoot
# Pending DONE records is a successful stage, not a failure. Fail only on reject.
if ($LASTEXITCODE -eq 2) { throw ('RECONCILE_REJECTED ' + $reconcile) }

$out = [ordered]@{
    schema = 1
    kind = 'kevin-proven-skill-invoke-worker-result'
    version = '1.0.0'
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
