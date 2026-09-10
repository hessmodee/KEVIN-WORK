# Publish-Kevin-InvocationReject-Public-v1.ps1
# GREEN self-repair. Authority delta: NONE.
# Reads local invocation run/reject files and publishes a metadata-only public reject.
# No raw evaluator text, no paths outside the workspace reports root, no secrets.
# Run once from a GREEN agent. GitHub source is not HESS-PC apply.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$RunRoot = Join-Path $Workspace 'reports\invocations\runs'
$FailedRoot = Join-Path $Workspace 'reports\action-era\queue\failed'
$OutDir = Join-Path $Workspace 'reports\invocations'
$OutPath = Join-Path $OutDir 'latest-public-reject.json'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Get-ReasonToken {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return 'REASON_ABSENT' }
    $known = @(
        'BUILDER_REJECTED','STAGE_REJECTED','RECONCILE_REJECTED',
        'SKILL_KEY_NOT_INVOCATION_V1_COMPATIBLE','PYTHON_NOT_AVAILABLE',
        'WORK_ITEM_NOT_UNIQUE','WORK_ITEMS_INVALID','OWNER_INPUTS_INVALID',
        'VEHICLE_COUNT_MUST_BE_8','MISSING_FIELDS','FORBIDDEN_CONTENT',
        'JSON_MISSING_OR_UNSAFE','PROVEN_SKILL_NOT_FOUND',
        'PRESERVED_PROOF_NOT_PROVEN','PRESERVED_PROOF_MANIFEST_MISMATCH',
        'INVOCATION_PRIMITIVE_SEQUENCE_MISMATCH',
        'INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST',
        'WORK_ORDER_ID_COLLISION','CANONICAL_INVOCATION_WORKER_MISSING'
    )
    foreach ($token in $known) {
        if ($Text -match [regex]::Escape($token)) { return $token }
    }
    return 'UNCLASSIFIED_REJECT'
}

$candidates = @()
if (Test-Path -LiteralPath $RunRoot) {
    $candidates += Get-ChildItem -LiteralPath $RunRoot -File -ErrorAction SilentlyContinue
}
if (Test-Path -LiteralPath $FailedRoot) {
    $candidates += Get-ChildItem -LiteralPath $FailedRoot -File -ErrorAction SilentlyContinue
}

$latest = $candidates | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
$reason = 'NO_LOCAL_INVOCATION_EVIDENCE'
$sourceKind = 'none'
$sourceName = ''
$ageSeconds = $null
if ($latest) {
    $sourceKind = 'file'
    $sourceName = $latest.Name
    $ageSeconds = [int]([datetime]::UtcNow - $latest.LastWriteTimeUtc).TotalSeconds
    try {
        $raw = Get-Content -LiteralPath $latest.FullName -Raw -ErrorAction Stop
        $reason = Get-ReasonToken $raw
    } catch {
        $reason = 'EVIDENCE_UNREADABLE'
    }
}

$payload = [ordered]@{
    schema = 1
    kind = 'kevin-invocation-public-reject'
    version = '1.0.0'
    authority = 'GREEN'
    generated_at = [datetime]::Now.ToString('o')
    safe_for_public_repo = $true
    public_payload_policy = 'reason-code only; no raw logs, configs, environment, or secrets'
    work_id_hint = 'owner-west-motor-parts-chase-fresh-8-v1'
    source_kind = $sourceKind
    source_name = $sourceName
    source_age_seconds = $ageSeconds
    reason = $reason
    outcome_proven = $false
    truth_boundary = 'A published reject code is a diagnostic. It is not PASS and not a desktop-tool widen.'
}

$json = $payload | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($OutPath, $json + "`n")
Write-Output $json
exit 0
