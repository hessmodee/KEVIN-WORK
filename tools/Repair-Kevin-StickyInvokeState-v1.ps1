param([switch]$SelfTest)
# Repair-Kevin-StickyInvokeState-v1.ps1
# GREEN-C. Quarantines leftover Supervisor RequestId run files and stale
# Action Era invoke-invoke-* work orders for the 8-vehicle job.
# Isolated diagnose uses diagnose-<work-id> so it can STAGE_OK forever
# while Supervisor keeps failing on invoke-<work-id> leftovers.
# Does not delete DONE records, receipts, continuation history, or other
# WorkInstances. Does not recopy Supervisor. Does not replace the live
# worker pin. Not PASS.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$WorkId = 'owner-west-motor-parts-chase-fresh-8-v1'
$StickyId = 'invoke-' + $WorkId
$OrderPrefix = 'invoke-' + $StickyId
$RunRoot = Join-Path $Workspace 'reports\invocations\runs'
$Ready = Join-Path $Workspace 'reports\action-era\queue\ready'
$Failed = Join-Path $Workspace 'reports\action-era\queue\failed'
$QRoot = Join-Path $Workspace 'reports\invocations\quarantine'

function Get-Sha256Upper([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return ([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($Path)) | ForEach-Object { $_.ToString('X2') }) -join ''
}

if ($SelfTest) {
    if ($StickyId -ne 'invoke-owner-west-motor-parts-chase-fresh-8-v1') { throw 'sticky id' }
    if ($OrderPrefix -ne 'invoke-invoke-owner-west-motor-parts-chase-fresh-8-v1') { throw 'order prefix' }
    Write-Host 'KEVIN STICKY INVOKE STATE v1 SELFTEST PASS'
    exit 0
}

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
    version = '1.0.0'
    authority = 'GREEN'
    work_id = $WorkId
    sticky_request_id = $StickyId
    status = $(if ($moved.Count -gt 0) { 'QUARANTINED' } else { 'ALREADY_CLEAN' })
    quarantined_count = $moved.Count
    quarantined = $moved
    outcome_proven = $false
    truth_boundary = 'Quarantined leftover Supervisor RequestId files only. Isolated diagnose is not Action Era. This is not PASS.'
}
Write-Output (($result | ConvertTo-Json -Compress -Depth 6))
exit 0
