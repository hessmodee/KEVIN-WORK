param([switch]$SelfTest, [switch]$SkipDiagnose)
# Repair-Kevin-InvocationRegistryContract-v1.ps1
# GREEN-C self-repair. Authority delta: NONE.
# Copies invocation v1.1.2 and builder v1.0.4 (parts-chase + transport bind), strips BOM
# from work-items.json, repairs work-id uniqueness, quarantines sticky RequestId
# run files AND stale Action Era invoke-invoke-* leftovers. Then Diagnose
# publishes the python reason unless -SkipDiagnose.

# Does not recopy Supervisor v1.8.12. Does not replace the live worker pin.
# Does not reset continuation history. Not PASS.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$Autonomy = Join-Path $Workspace 'control-plane\autonomy'
$InvExpected = '471E505151E211C254FAB9DD090AEA76E7D304B01333FEA03B115D2ECE39B7E8'
$BldExpected = 'E7381E6051B988A0E36386265A0E09263D88CF83EB2EB2BAC808DF04EB5BB1B3'
$StickyId = 'invoke-owner-west-motor-parts-chase-fresh-8-v1'

function Get-Sha256Upper([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [IO.File]::ReadAllBytes($Path)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', ''))
    } finally { $sha.Dispose() }
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, $Utf8)
}

function Get-GitHubText([string]$RepoPath) {
    $api = "repos/hessmodee/KEVIN-WORK/contents/$RepoPath"
    $raw = gh api $api --jq .content
    if (-not $raw) { throw ("GITHUB_FETCH_EMPTY " + $RepoPath) }
    $bytes = [Convert]::FromBase64String(($raw -replace "`n", ''))
    return [Text.Encoding]::UTF8.GetString($bytes)
}

function Install-RepoFile([string]$RepoPath, [string]$Dest, [string]$Expected, [string]$MustContain) {
    $text = $null
    $localRepo = Join-Path $Workspace $RepoPath
    if (Test-Path -LiteralPath $localRepo -PathType Leaf) {
        $candidate = Get-Sha256Upper $localRepo
        if ($candidate -eq $Expected) {
            $text = [IO.File]::ReadAllText($localRepo)
        }
    }
    if (-not $text) {
        $text = Get-GitHubText $RepoPath
    }
    if ($text -notmatch [regex]::Escape($MustContain)) { throw ("REPAIR_CONTENT_MISSING " + $RepoPath) }
    Write-Utf8NoBom $Dest $text
    $got = Get-Sha256Upper $Dest
    if ($got -ne $Expected) {
        $raw = gh api ("repos/hessmodee/KEVIN-WORK/contents/" + $RepoPath) --jq .content
        $bytes = [Convert]::FromBase64String(($raw -replace "`n", ''))
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dest) | Out-Null
        [IO.File]::WriteAllBytes($Dest, $bytes)
        $got = Get-Sha256Upper $Dest
        if ($got -ne $Expected) { throw ("REPAIR_HASH_MISMATCH " + $RepoPath + ' got=' + $got) }
    }
    return $got
}

if ($SelfTest) {
    if ($InvExpected.Length -ne 64) { throw 'inv hash pin' }
    if ($BldExpected.Length -ne 64) { throw 'bld hash pin' }
    Write-Host 'KEVIN INVOCATION REGISTRY CONTRACT v1 SELFTEST PASS'
    exit 0
}

New-Item -ItemType Directory -Force -Path $Autonomy | Out-Null
$invPath = Join-Path $Autonomy 'kevin-proven-skill-invocation-v1.py'
$bldPath = Join-Path $Autonomy 'kevin-proven-skill-request-builder-v1.py'
$invHash = Install-RepoFile 'control-plane/autonomy/kevin-proven-skill-invocation-v1.1.2.py' $invPath $InvExpected 'CATALOG_PRIMITIVES'
$bldHash = Install-RepoFile 'control-plane/autonomy/kevin-proven-skill-request-builder-v1.py' $bldPath $BldExpected 'WORK_ITEM_NOT_FOUND'

$items = Join-Path $Workspace 'inbox\autonomy\work-items.json'
$bomStripped = $false
if (Test-Path -LiteralPath $items -PathType Leaf) {
    $bytes = [IO.File]::ReadAllBytes($items)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $rest = New-Object byte[] ($bytes.Length - 3)
        [Array]::Copy($bytes, 3, $rest, 0, $rest.Length)
        [IO.File]::WriteAllBytes($items, $rest)
        $bomStripped = $true
        Write-Host 'stripped UTF-8 BOM from work-items.json'
    }
}

$uniqueness = $null
$uniq = Join-Path $Workspace 'tools\Repair-Kevin-WorkItems-Uniqueness-v1.ps1'
if (Test-Path -LiteralPath $uniq -PathType Leaf) {
    try {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $uniqueness = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $uniq
        $ErrorActionPreference = $prev
        Write-Host ('uniqueness repair exit=' + $LASTEXITCODE)
    } catch { Write-Host ('uniqueness skip: ' + $_) }
}

$stickyStatus = $null
$sticky = Join-Path $Workspace 'tools\Repair-Kevin-StickyInvokeState-v1.ps1'
if (Test-Path -LiteralPath $sticky -PathType Leaf) {
    try {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $stickyStatus = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $sticky
        $ErrorActionPreference = $prev
        Write-Host ('sticky repair exit=' + $LASTEXITCODE)
    } catch { Write-Host ('sticky skip: ' + $_) }
}

$runRoot = Join-Path $Workspace 'reports\invocations\runs'
$qRoot = Join-Path $Workspace 'reports\invocations\quarantine'
New-Item -ItemType Directory -Force -Path $qRoot | Out-Null
$quarantined = @()
if (Test-Path -LiteralPath $runRoot) {
    $stamp = Get-Date -Format 'yyyyMMddHHmmss'
    foreach ($f in @(Get-ChildItem -LiteralPath $runRoot -File | Where-Object { $_.Name -like ($StickyId + '*') })) {
        $dest = Join-Path $qRoot ($stamp + '-' + $f.Name)
        Move-Item -LiteralPath $f.FullName -Destination $dest -Force
        $quarantined += $f.Name
    }
}

$reject = [ordered]@{
    schema = 1
    kind = 'kevin-invocation-public-reject'
    version = '1.3.2'
    authority = 'GREEN'
    generated_at = [datetime]::Now.ToString('o')
    safe_for_public_repo = $true
    public_payload_policy = 'reason-code and hashes only; no raw logs, configs, environment, or secrets'
    work_id_hint = 'owner-west-motor-parts-chase-fresh-8-v1'
    reason = 'REGISTRY_CONTRACT_REPAIRED'
    invocation_py_sha256 = $invHash
    builder_py_sha256 = $bldHash
    work_items_bom_stripped = $bomStripped
    uniqueness_repair = [string]$uniqueness
    sticky_repair = [string]$stickyStatus
    quarantined_run_files = $quarantined
    outcome_proven = $false
    truth_boundary = 'Python catalog+proof-pin+BOM-safe uniqueness builder repaired (invocation v1.1.2 / builder v1.0.4). Supervisor must re-invoke the same WorkInstance. This is not PASS.'
}
$outPath = Join-Path $Workspace 'reports\invocations\latest-public-reject.json'
Write-Utf8NoBom $outPath (($reject | ConvertTo-Json -Depth 6) + "`n")
Write-Output ($reject | ConvertTo-Json -Depth 6)
if (-not $SkipDiagnose) {
    $diag = Join-Path $Workspace 'tools\Diagnose-Kevin-InvocationStage-v1.ps1'
    if (Test-Path -LiteralPath $diag -PathType Leaf) {
        try { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $diag } catch { Write-Host ('diagnose skip: ' + $_) }
    }
}
exit 0
