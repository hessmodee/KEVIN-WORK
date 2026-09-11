param([switch]$SelfTest)
# Repair-Kevin-WorkItems-Uniqueness-v1.ps1
# GREEN-C. Makes owner-west-motor-parts-chase-fresh-8-v1 unique in the live
# work-items.json without wiping other items or resetting history.
# 0 matches -> insert canonical fictional 8-vehicle item.
# 2+ matches -> keep the OPEN + 8-vehicle copy, archive extras.
# 1 match -> no-op. Requires builder v1.0.3. Not PASS.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$Builder = Join-Path $Workspace 'control-plane\autonomy\kevin-proven-skill-request-builder-v1.py'
$Items = Join-Path $Workspace 'inbox\autonomy\work-items.json'
$Archive = Join-Path $Workspace 'inbox\autonomy\archive'
$WorkId = 'owner-west-motor-parts-chase-fresh-8-v1'
$BldExpected = '83B3EDA62AA60A6CD479D79C18BB564B9E33CBD852B4898C365EF99B43EB0875'

function Get-Sha256Upper([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return ([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($Path)) | ForEach-Object { $_.ToString('X2') }) -join ''
}

if ($SelfTest) {
    if ($BldExpected.Length -ne 64) { throw 'bld hash pin' }
    if ($WorkId -notmatch 'west-motor-parts-chase-fresh-8') { throw 'work id' }
    Write-Host 'KEVIN WORK-ITEMS UNIQUENESS v1 SELFTEST PASS'
    exit 0
}

$got = Get-Sha256Upper $Builder
if ($got -ne $BldExpected) {
    Write-Host ('uniqueness repair skipped; builder hash ' + $got + ' != v1.0.3')
    exit 2
}
if (-not (Test-Path -LiteralPath $Items -PathType Leaf)) {
    Write-Host 'uniqueness repair skipped; work-items.json missing'
    exit 2
}
$py = $null
foreach ($cand in @('python','python3','py')) {
    $cmd = Get-Command $cand -ErrorAction SilentlyContinue
    if ($cmd) { $py = $cmd.Source; break }
}
if (-not $py) {
    Write-Host 'uniqueness repair skipped; python missing'
    exit 2
}
New-Item -ItemType Directory -Force -Path $Archive | Out-Null
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $py
$psi.Arguments = '"' + $Builder + '" --repair-unique --work-items "' + $Items + '" --work-id ' + $WorkId + ' --archive "' + $Archive + '"'
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
Write-Output ($stdout.Trim())
if ($stderr) { Write-Host $stderr }
exit $p.ExitCode
