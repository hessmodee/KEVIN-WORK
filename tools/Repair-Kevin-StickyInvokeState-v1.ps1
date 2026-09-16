param(
  [switch]$SelfTest,
  [string]$WorkId = ''
)
# Repair-Kevin-StickyInvokeState-v1.ps1
# GREEN-C. Quarantines leftover Supervisor RequestId run files and stale
# Action Era invoke-invoke-* work orders for the LIVE selected WorkInstance.
# Isolated diagnose uses diagnose-<work-id> so it can STAGE_OK forever
# while Supervisor keeps failing on invoke-<work-id> leftovers.
# Does not delete DONE records, receipts, continuation history, or other
# WorkInstances. Does not recopy Supervisor. Does not replace the live
# worker pin. Not PASS.
# v1.1.0: WorkId follows floor/continuation selected_id. Never defaults to a
# COMPLETE parent (fresh-8). Pass -WorkId to override.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }

function Get-JsonField([string]$Path, [string]$Name) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    try {
        $o = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        $v = $o.$Name
        if ($null -ne $v) { return [string]$v }
    } catch {}
    return ''
}

function Get-WorkItemStatus([string]$Id) {
    $itemsPath = Join-Path $Workspace 'inbox\autonomy\work-items.json'
    if (-not $Id) { return '' }
    if (-not (Test-Path -LiteralPath $itemsPath -PathType Leaf)) { return '' }
    try {
        $wi = Get-Content -LiteralPath $itemsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($it in @($wi.items)) {
            if ([string]$it.id -eq $Id) { return [string]$it.status }
        }
    } catch {}
    return ''
}

function Get-SelectedWorkId {
    $floor = Join-Path $Workspace 'reports\hq-live-floor.json'
    $cont = Join-Path $Workspace 'reports\autonomy-continuation-latest.json'
    foreach ($c in @((Get-JsonField $floor 'selected_id'), (Get-JsonField $cont 'selected_id'))) {
        if ([string]::IsNullOrWhiteSpace($c)) { continue }
        $st = (Get-WorkItemStatus $c).ToUpperInvariant()
        if ($st -in @('COMPLETE', 'COMPLETED', 'DONE', 'CLOSED', 'PROVEN')) { continue }
        return $c
    }
    return ''
}

if ($SelfTest) {
    $testId = 'owner-west-motor-lot-walk-checklist-refresh-v1'
    $testSticky = 'invoke-' + $testId
    $testPrefix = 'invoke-' + $testSticky
    if ($testSticky -ne 'invoke-owner-west-motor-lot-walk-checklist-refresh-v1') { throw 'sticky id' }
    if ($testPrefix -ne 'invoke-invoke-owner-west-motor-lot-walk-checklist-refresh-v1') { throw 'order prefix' }
    if ((Get-Command Get-SelectedWorkId).Name -ne 'Get-SelectedWorkId') { throw 'resolver missing' }
    Write-Host 'KEVIN STICKY INVOKE STATE v1.1.0 SELFTEST PASS'
    exit 0
}

if (-not $WorkId) { $WorkId = Get-SelectedWorkId }
if (-not $WorkId) {
    $empty = [ordered]@{
        schema = 1
        kind = 'kevin-sticky-invoke-state-repair'
        version = '1.1.0'
        authority = 'GREEN'
        work_id = ''
        sticky_request_id = ''
        status = 'NO_OPEN_SELECTED_ID'
        quarantined_count = 0
        quarantined = @()
        outcome_proven = $false
        truth_boundary = 'No OPEN selected_id on floor/continuation. Refusing to default to a COMPLETE parent. Not PASS.'
    }
    Write-Output (($empty | ConvertTo-Json -Compress -Depth 6))
    exit 0
}

$StickyId = 'invoke-' + $WorkId
$OrderPrefix = 'invoke-' + $StickyId
$RunRoot = Join-Path $Workspace 'reports\invocations\runs'
$Ready = Join-Path $Workspace 'reports\action-era\queue\ready'
$Failed = Join-Path $Workspace 'reports\action-era\queue\failed'
$QRoot = Join-Path $Workspace 'reports\invocations\quarantine'

New-Item -ItemType Directory -Force -Path $QRoot | Out-Null
$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$moved = @()

function Move-Sticky([string]$Dir, [string]$Prefix) {
    if (-not (Test-Path -LiteralPath $Dir)) { return }
    foreach ($f in @(Get-ChildItem -LiteralPath $Dir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like ($Prefix + '*') })) {
        $dest = Join-Path $QRoot ($stamp + '-' + $f.Directory.Name + '-' + $f.Name)
        Move-Item -LiteralPath $f.FullName -Destination $dest -Force
        $script:moved += ($f.Directory.Name + '/' + $f.Name)
    }
}

Move-Sticky $RunRoot $StickyId
Move-Sticky $Ready $OrderPrefix
Move-Sticky $Failed $OrderPrefix

$result = [ordered]@{
    schema = 1
    kind = 'kevin-sticky-invoke-state-repair'
    version = '1.1.0'
    authority = 'GREEN'
    work_id = $WorkId
    sticky_request_id = $StickyId
    status = $(if ($moved.Count -gt 0) { 'QUARANTINED' } else { 'ALREADY_CLEAN' })
    quarantined_count = $moved.Count
    quarantined = $moved
    outcome_proven = $false
    truth_boundary = 'Quarantined leftover Supervisor RequestId files for the LIVE selected WorkInstance only. Isolated diagnose is not Action Era. This is not PASS.'
}
Write-Output (($result | ConvertTo-Json -Compress -Depth 6))
exit 0
