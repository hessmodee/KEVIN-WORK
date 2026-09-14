# Tick-CloseInvocationLoop-v1.ps1
# Tick-owned: sync GitHub main work-items -> local, reconcile official RUNNING/OPEN
# invoke-owner-* WorkInstances against reports/invocations/done PROVEN receipts,
# COMPLETE them on GitHub main, print SYNC_OK.
# Call BEFORE helper_append_daily_note.py. No Supervisor recopy. No hand-invoke.
# ExpectedSelectorSha 52EADBCA... stands. ControlPlane invoke-worker pin 16C49542... stands.
param(
  [switch]$PushPublic = $true,
  [string]$Repo = 'hessmodee/KEVIN-WORK'
)
$ErrorActionPreference = 'Continue'
$utf8 = New-Object System.Text.UTF8Encoding $false
$ws = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$itemsPath = Join-Path $ws 'inbox\autonomy\work-items.json'
$doneDir = Join-Path $ws 'reports\invocations\done'
$logPath = Join-Path $ws 'reports\tick-close-invocation-loop-latest.json'
New-Item -ItemType Directory -Force -Path (Split-Path $itemsPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function Get-GhSha([string]$path) {
  try { return (gh api "repos/$Repo/contents/$path" --jq .sha 2>$null) } catch { return $null }
}

$now = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$synced = $false
$closed = New-Object System.Collections.Generic.List[string]
$errors = New-Object System.Collections.Generic.List[string]

# 1) GitHub main work-items.json -> local (Supervisor reads GitHub; local-only is invisible)
try {
  $raw = gh api "repos/$Repo/contents/inbox/autonomy/work-items.json" --jq .content 2>$null
  if ($raw) {
    $bytes = [Convert]::FromBase64String(($raw -replace '\s',''))
    [IO.File]::WriteAllBytes($itemsPath, $bytes)
    $synced = $true
    Write-Host 'SYNC_OK work-items.json <- github main'
  } else {
    $errors.Add('gh GET work-items empty')
    Write-Host 'SYNC_FAIL work-items GET empty'
  }
} catch {
  $errors.Add("gh GET work-items: $($_.Exception.Message)")
  Write-Host "SYNC_FAIL work-items GET: $_"
}

if (-not (Test-Path -LiteralPath $itemsPath)) {
  Write-Host 'close-loop skip; work-items.json missing'
  exit 2
}

$wi = $null
try { $wi = Get-Content -LiteralPath $itemsPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {
  Write-Host "close-loop parse FAIL: $_"
  exit 2
}
if (-not $wi.items) { Write-Host 'close-loop skip; no items'; exit 0 }

# 2) Index PROVEN invoke-owner-* receipts (local done/ is Tick/HESS truth)
$proven = @{}
if (Test-Path -LiteralPath $doneDir) {
  foreach ($p in Get-ChildItem -LiteralPath $doneDir -File -Filter 'invoke-owner-*.json' -EA SilentlyContinue) {
    try {
      $d = Get-Content -LiteralPath $p.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
      if ([string]$d.status -ne 'PROVEN') { continue }
      $inv = [string]($d.invocation_id)
      if (-not $inv) { $inv = $p.BaseName }
      $wid = if ($d.work_id) { [string]$d.work_id } elseif ($inv.StartsWith('invoke-')) { $inv.Substring(7) } else { $inv }
      $proven[$wid] = @{
        invocation_id = $inv
        receipt_sha256 = [string]$d.receipt_sha256
        completed_at = [string]$d.completed_at
        actor = if ($d.actor) { [string]$d.actor } elseif ($d.verify_actor) { [string]$d.verify_actor } else { 'MIXED' }
        skill_key = [string]$d.skill_key
        path = $p.FullName
      }
    } catch {}
  }
}

# 3) Close OPEN/RUNNING owner WIs that already have a PROVEN done receipt
$changed = $false
foreach ($it in @($wi.items)) {
  if (-not $it.id) { continue }
  $id = [string]$it.id
  if (-not $proven.ContainsKey($id)) { continue }
  $st = ([string]$it.status).ToUpperInvariant()
  if ($st -in @('COMPLETE','COMPLETED','DONE','CLOSED','PROVEN')) { continue }
  $rec = $proven[$id]
  $it.status = 'COMPLETE'
  $it.blocked = $true
  $it.block_reason = 'COMPLETE_DO_NOT_RESELECT'
  if ($rec.completed_at) { $it.completed_at = $rec.completed_at }
  if ($rec.receipt_sha256) { $it.last_receipt_sha256 = $rec.receipt_sha256 }
  $it.verify_actor = $rec.actor
  $it.autonomy_credit = $false
  $it.next_action = ("COMPLETE {0}. Receipt {1}. Do not reselect. Clone PROVE freeze stands." -f $rec.actor, $rec.receipt_sha256)
  $closed.Add($id)
  $changed = $true
  Write-Host ("CLOSED {0} receipt={1} actor={2}" -f $id, $rec.receipt_sha256, $rec.actor)
}

if ($changed) {
  $wi.updated_at = $now
  $note = 'Tick-CloseInvocationLoop CLOSED: ' + ($closed -join ', ')
  try { $wi.family_loop_note = $note } catch { $wi | Add-Member -NotePropertyName family_loop_note -NotePropertyValue $note -Force }
  [IO.File]::WriteAllText($itemsPath, (($wi | ConvertTo-Json -Depth 100) + "`n"), $utf8)
}

# 4) Push closed board to GitHub main so Supervisor Get-ControlText sees COMPLETE
$pushed = $null
if ($PushPublic -and $changed) {
  try {
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($itemsPath))
    $sha = Get-GhSha 'inbox/autonomy/work-items.json'
    $msg = "tick-close-loop: COMPLETE $($closed -join ',') COMPLETE_DO_NOT_RESELECT"
    if ($sha) {
      $pushed = gh api --method PUT "repos/$Repo/contents/inbox/autonomy/work-items.json" -f message="$msg" -f content="$b64" -f sha="$sha" --jq .commit.sha
    } else {
      $pushed = gh api --method PUT "repos/$Repo/contents/inbox/autonomy/work-items.json" -f message="$msg" -f content="$b64" --jq .commit.sha
    }
    Write-Host "PUSH_OK work-items $pushed"
  } catch {
    $errors.Add("gh PUT work-items: $($_.Exception.Message)")
    Write-Host "PUSH_FAIL work-items: $_"
  }
}

# 5) Publish missing local PROVEN owner receipts to GitHub invocations/done (sanitized files only)
foreach ($wid in $proven.Keys) {
  $rec = $proven[$wid]
  $repoPath = 'reports/invocations/done/' + $rec.invocation_id + '.json'
  try {
    $exists = $null
    try { $exists = gh api "repos/$Repo/contents/$repoPath" --jq .sha 2>$null } catch {}
    if (-not $exists) {
      $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($rec.path))
      $msg = "tick-close-loop: publish done receipt $($rec.invocation_id)"
      $null = gh api --method PUT "repos/$Repo/contents/$repoPath" -f message="$msg" -f content="$b64" --jq .commit.sha
      Write-Host "PUSH_OK receipt $($rec.invocation_id)"
    }
  } catch {
    $errors.Add("receipt push $($rec.invocation_id): $($_.Exception.Message)")
  }
}

$doc = [ordered]@{
  schema = 1
  kind = 'kevin-tick-close-invocation-loop'
  version = '1.0.0'
  at = $now
  synced = $synced
  closed = @($closed)
  pushed = $pushed
  proven_count = $proven.Count
  errors = @($errors)
  truth_boundary = 'Tick close-loop. Not KEVIN_ACTED unless Tick+Supervisor+Action Era closed with no diagnose-* RequestId.'
}
[IO.File]::WriteAllText($logPath, (($doc | ConvertTo-Json -Depth 8) + "`n"), $utf8)
if ($synced) { Write-Host 'SYNC_OK' } else { Write-Host 'SYNC_FAIL' }
if ($errors.Count -gt 0) { exit 1 }
exit 0
