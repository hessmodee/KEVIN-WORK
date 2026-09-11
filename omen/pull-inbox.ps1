# Kevin GitHubBridge puller v1.5
# GREEN-C. Copies inbox + self-updates this script + applies the catalog-contract
# python repair when live hashes mismatch. Builder pin is v1.0.3 (uniqueness).
# Does not recopy Supervisor v1.8.12. Does not replace the live worker pin.
# Does not reset history. Not PASS.
$ErrorActionPreference = 'Continue'
$PullerVersion = 'v1.5'
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
New-Item -ItemType Directory -Force -Path $ws, (Join-Path $ws 'inbox'), (Join-Path $ws 'reports'), (Join-Path $ws 'tools') | Out-Null

$InvExpected = '471E505151E211C254FAB9DD090AEA76E7D304B01333FEA03B115D2ECE39B7E8'
$BldExpected = '83B3EDA62AA60A6CD479D79C18BB564B9E33CBD852B4898C365EF99B43EB0875'

$files = @(
  'inbox/FROM_GROK.md',
  'inbox/CURRENT_TASK.md',
  'inbox/engineering/request.json',
  'workspace/HEARTBEAT.md',
  'workspace/SOUL.md',
  'omen/apply-lean.js',
  'omen/pull-inbox.ps1',
  'tools/Repair-Kevin-InvocationRegistryContract-v1.ps1',
  'tools/Repair-Kevin-WorkItems-Uniqueness-v1.ps1',
  'tools/Diagnose-Kevin-InvocationStage-v1.ps1'
)

function Get-GitHubBytes([string]$RepoPath) {
  $api = "repos/hessmodee/KEVIN-WORK/contents/$RepoPath"
  $raw = gh api $api --jq .content
  if (-not $raw) { throw ("GITHUB_FETCH_EMPTY " + $RepoPath) }
  return [Convert]::FromBase64String(($raw -replace "`n", ''))
}

function Get-Sha256Upper([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
  return ([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($Path)) | ForEach-Object { $_.ToString('X2') }) -join ''
}

foreach ($f in $files) {
  try {
    $bytes = Get-GitHubBytes $f
    $destName = Split-Path $f -Leaf
    if ($f -like 'workspace/*') { $dest = Join-Path $ws $destName }
    elseif ($f -eq 'omen/pull-inbox.ps1') { $dest = Join-Path $ws 'pull-inbox.ps1' }
    elseif ($f -like 'omen/*') { $dest = Join-Path $ws $destName }
    elseif ($f -like 'tools/*') { $dest = Join-Path $ws $f }
    else { $dest = Join-Path $ws $f }
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    [IO.File]::WriteAllBytes($dest, $bytes)
    Write-Host "pulled $f -> $dest"
  } catch { Write-Host "skip $f : $_" }
}

$diskPuller = Join-Path $ws 'pull-inbox.ps1'
if (Test-Path -LiteralPath $diskPuller) {
  $diskText = [IO.File]::ReadAllText($diskPuller)
  if ($diskText -notmatch ("PullerVersion = '" + $PullerVersion + "'") -and $diskText -match 'PullerVersion|puller =') {
    Write-Host ("puller self-update to disk script from " + $PullerVersion)
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $diskPuller
    exit $LASTEXITCODE
  }
}

$invPath = Join-Path $ws 'control-plane\autonomy\kevin-proven-skill-invocation-v1.py'
$bldPath = Join-Path $ws 'control-plane\autonomy\kevin-proven-skill-request-builder-v1.py'
$invGot = Get-Sha256Upper $invPath
$bldGot = Get-Sha256Upper $bldPath
$repair = Join-Path $ws 'tools\Repair-Kevin-InvocationRegistryContract-v1.ps1'
if ($invGot -ne $InvExpected -or $bldGot -ne $BldExpected) {
  Write-Host ("registry repair due inv=" + $invGot + " bld=" + $bldGot)
  if (Test-Path -LiteralPath $repair -PathType Leaf) {
    try {
      & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $repair
      Write-Host ("repair exit=" + $LASTEXITCODE)
    } catch { Write-Host "repair skip: $_" }
  } else {
    Write-Host 'repair script missing after pull'
  }
} else {
  Write-Host 'registry contract hashes already live'
}
$uniq = Join-Path $ws 'tools\Repair-Kevin-WorkItems-Uniqueness-v1.ps1'
if (Test-Path -LiteralPath $uniq -PathType Leaf) {
  try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $uniq
    Write-Host ('uniqueness repair exit=' + $LASTEXITCODE)
  } catch { Write-Host "uniqueness skip: $_" }
}
$diag = Join-Path $ws 'tools\Diagnose-Kevin-InvocationStage-v1.ps1'
if (Test-Path -LiteralPath $diag -PathType Leaf) {
  try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $diag
    Write-Host ('diagnose exit=' + $LASTEXITCODE)
  } catch { Write-Host "diagnose skip: $_" }
}

$invGot = Get-Sha256Upper $invPath
$bldGot = Get-Sha256Upper $bldPath
$stamp = @{
  at = (Get-Date).ToString('o')
  host = $env:COMPUTERNAME
  bridge = 'ok'
  puller = $PullerVersion
  inv_sha256 = $invGot
  bld_sha256 = $bldGot
}
$stamp | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $ws 'reports\bridge-latest.json')
try {
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content -Raw (Join-Path $ws 'reports\bridge-latest.json'))))
  $api = 'repos/hessmodee/KEVIN-WORK/contents/reports/bridge-latest.json'
  $sha = $null
  try { $sha = gh api $api --jq .sha 2>$null } catch {}
  if ($sha) { gh api --method PUT $api -f message='bridge ping' -f content=$b64 -f sha=$sha | Out-Null }
  else { gh api --method PUT $api -f message='bridge ping' -f content=$b64 | Out-Null }
} catch { Write-Host "upload skip: $_" }
