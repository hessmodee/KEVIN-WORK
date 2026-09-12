# Publish-Kevin-HqLiveFloor-v1.ps1 - Tick-owned HQ floor truth (honest, cycle++)
# GROKBOT_ACTED teach. No PASS. No hand-invoke. No Supervisor select.
param(
  [string]$ScaffoldWho = '',
  [string]$ScaffoldOneLine = '',
  [bool]$ScaffoldActive = $false,
  [switch]$PushPublic
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding $false
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
$floorPath = Join-Path $ws 'reports\hq-live-floor.json'
$supPath = Join-Path $ws 'kevin-supervisor.ps1'
$contPath = Join-Path $ws 'reports\autonomy-continuation-latest.json'
$readyDir = Join-Path $ws 'reports\action-era\queue\ready'
# ONE CLOCK (Matt P0 2026-09-11): reports/hq-live-floor.json cycle is AUTHORITATIVE.
# support-latest.supervisor.cycle must NEVER overwrite floor cycle and must NEVER be used
# as painter freeze sentinel. Sync support UP to floor only. Never paint/freeze from 449 when floor>=450.
$MIN_CYCLE_FLOOR = 450  # historic 449 was a dead support sentinel — floor never regresses below 450

$cycle = 0
$prev = $null
if (Test-Path -LiteralPath $floorPath) {
  try { $prev = Get-Content -LiteralPath $floorPath -Raw -Encoding UTF8 | ConvertFrom-Json; $cycle = [int]($prev.cycle) } catch {}
}
$cycle++
if ($cycle -lt $MIN_CYCLE_FLOOR) { $cycle = $MIN_CYCLE_FLOOR }

$now = [datetime]::Now.ToString('o')
$supSha = ''
$supVer = 'unknown'
if (Test-Path -LiteralPath $supPath) {
  $supSha = (Get-FileHash -LiteralPath $supPath -Algorithm SHA256).Hash.ToUpperInvariant()
  $head = Get-Content -LiteralPath $supPath -Encoding UTF8 -TotalCount 40
  $joined = $head -join "`n"
  if ($joined -match 'Supervisor v(1\.\d+\.\d+)') { $supVer = $Matches[1] }
  elseif ($joined -match 'v1\.(\d+\.\d+)') { $supVer = '1.' + $Matches[1] }
}

$cont = $null
if (Test-Path -LiteralPath $contPath) { $cont = Get-Content -LiteralPath $contPath -Raw -Encoding UTF8 | ConvertFrom-Json }
$status = if ($cont) { [string]$cont.status } else { '' }
$selected = if ($cont) { [string]$cont.selected_id } else { '' }
$outcome = $false
if ($cont -and $cont.PSObject.Properties.Name -contains 'outcome_proven') { $outcome = [bool]$cont.outcome_proven }

$readyCount = 0
if (Test-Path -LiteralPath $readyDir) { $readyCount = @(Get-ChildItem -LiteralPath $readyDir -File -Filter 'invoke-*.json' -EA SilentlyContinue).Count }

$waitingFlag = Test-Path -LiteralPath (Join-Path $ws 'reports\engineering\WAITING-ITEM-BUDGETS.flag')
$waiting = ($status -eq 'WAITING_ITEM_BUDGETS') -or $waitingFlag

$partsPath = Join-Path $ws 'reports\invocations\done\invoke-owner-west-motor-parts-chase-fresh-8-v1.json'
$transportPath = Join-Path $ws 'reports\invocations\done\invoke-owner-west-motor-transport-dispatch-template-v1.json'
$westProven = $false; $westAt = $null; $westReceiptSha = $null
$transportProven = $false; $transportAt = $null; $transportReceiptSha = $null
if (Test-Path $partsPath) {
  try {
    $pr = Get-Content $partsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$pr.status -eq 'PROVEN') {
      $westProven = $true
      $westAt = [string]$pr.completed_at
      $westReceiptSha = if ($pr.receipt_sha256) { [string]$pr.receipt_sha256 } else { (Get-FileHash $partsPath -Algorithm SHA256).Hash.ToUpperInvariant() }
    }
  } catch {}
}
if (Test-Path $transportPath) {
  try {
    $tr = Get-Content $transportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$tr.status -eq 'PROVEN') {
      $transportProven = $true
      $transportAt = [string]$tr.completed_at
      $transportReceiptSha = (Get-FileHash $transportPath -Algorithm SHA256).Hash.ToUpperInvariant()
    }
  } catch {}
}

$lastStart = if ($cont -and $cont.last_invoke_started_at) { [string]$cont.last_invoke_started_at } elseif ($prev) { [string]$prev.last_invoke_started_at } else { $null }
$lastDone = if ($transportAt) { $transportAt } elseif ($cont -and $cont.last_invoke_completed_at) { [string]$cont.last_invoke_completed_at } elseif ($prev) { [string]$prev.last_invoke_completed_at } else { $null }
$lastActor = if ($prev -and $prev.last_actor) { [string]$prev.last_actor } else { 'MIXED' }

$hint = 'READY'
if ($waiting) { $hint = 'THROTTLED' }
elseif ($readyCount -ge 1) { $hint = 'WORKING' }
elseif ($status -match 'VERIFY') { $hint = 'VERIFYING' }
elseif ($outcome -and $transportProven) { $hint = 'THROTTLED' }  # after COMPLETED, do not stay VERIFYING forever when budgets wait
if ($ScaffoldActive) { $hint = 'SCAFFOLD' }

$labReady = 0; $labRun = 0; $labFailed = 0; $labDoneN = 0
$rr = Join-Path $ws 'reports\action-era\skills\ready'
$runD = Join-Path $ws 'reports\action-era\skills\running'
$failD = Join-Path $ws 'reports\action-era\skills\failed'
$labDone = Join-Path $ws 'reports\action-era\skills\done'
if (Test-Path $rr) { $labReady = @(Get-ChildItem $rr -File -Filter '*.json' -EA SilentlyContinue).Count }
if (Test-Path $runD) { $labRun = @(Get-ChildItem $runD -File -Filter '*.json' -EA SilentlyContinue).Count }
if (Test-Path $failD) { $labFailed = @(Get-ChildItem $failD -File -Filter '*.json' -EA SilentlyContinue).Count }
if (Test-Path $labDone) { $labDoneN = @(Get-ChildItem $labDone -File -Filter '*.json' -EA SilentlyContinue).Count }
$labStage = 'IDLE'
if ($labReady -gt 0 -or $labRun -gt 0) { $labStage = 'LAB' }
elseif ($labFailed -gt 0) { $labStage = 'GAP' }
if ($labReady -gt 0 -or $labRun -gt 0) {
  if ($hint -notin @('WORKING','VERIFYING','SCAFFOLD','THROTTLED')) { $hint = 'LAB' }
}

$bridgePath = Join-Path $ws 'reports\bridge-latest.json'
$bridgeStatus = 'UNKNOWN'; $bridgePuller = $null; $bridgeAt = $null; $bridgeHost = $null
$bridgeWhy = 'reports/bridge-latest.json missing on disk'
if (Test-Path $bridgePath) {
  try {
    $br = Get-Content $bridgePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $bridgeStatus = if ($br.bridge) { [string]$br.bridge } else { 'UNKNOWN' }
    $bridgePuller = [string]$br.puller
    $bridgeAt = [string]$br.at
    $bridgeHost = [string]$br.host
    $bridgeWhy = 'Local HESS bridge file present; HQ UNKNOWN means public main bridge-latest was not refreshed'
  } catch { $bridgeWhy = "bridge-latest parse fail: $_" }
}

$scaffold = [ordered]@{
  active = [bool]$ScaffoldActive
  who = $ScaffoldWho
  one_line = $ScaffoldOneLine
  updated_at = if ($ScaffoldActive) { $now } elseif ($prev -and $prev.scaffold) { [string]$prev.scaffold.updated_at } else { $now }
}


# CENTER_PAINT_LOCK (Matt 2026-09-11): center/painted_hint never OUTCOME_PROVEN.
# HOLD select + budgets => THROTTLED; idle => READY. Stripes use outcome_proven / *_proven fields.
if ($waiting) { $hint = 'THROTTLED' }
elseif ($hint -in @('OUTCOME_PROVEN','COMPLETED','PROVEN')) { $hint = 'READY' }
if ($hint -eq 'OUTCOME_PROVEN') { $hint = $(if ($waiting) { 'THROTTLED' } else { 'READY' }) }
$centerAllowed = @('THROTTLED','READY','WORKING','VERIFYING','SCAFFOLD','LAB','PROVE','GAP','BLOCKED','INVOKING')
if ($centerAllowed -notcontains $hint) { $hint = $(if ($waiting) { 'THROTTLED' } else { 'READY' }) }

$skillLab = [ordered]@{
  stage = $labStage
  ready_count = $labReady
  running_count = $labRun
  failed_count = $labFailed
  done_count = $labDoneN
  entrypoint = 'kevin-skill-lab.ps1'
  cron = 'kevin-skill-lab-v1'
  required_skill_key_missing = ($labStage -eq 'GAP')
  reason = if ($labStage -eq 'GAP') { 'capability GAP / prior lab fails; Lab-first when budgets clear' } else { '' }
}

$dealPath = Join-Path $ws 'reports\invocations\done\invoke-owner-dealership-operations-opportunity-scan-fresh-2026-09-11-v1.json'
$dealProven = $false; $dealAt = $null; $dealReceiptSha = $null
if (Test-Path $dealPath) {
  try {
    $dr = Get-Content $dealPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$dr.status -eq 'PROVEN') {
      $dealProven = $true
      $dealAt = [string]$dr.completed_at
      $dealReceiptSha = if ($dr.receipt_sha256) { [string]$dr.receipt_sha256 } else { (Get-FileHash $dealPath -Algorithm SHA256).Hash.ToUpperInvariant() }
    }
  } catch {}
}
$doc = [ordered]@{
  schema = 'kevin.hq-live-floor.v1'
  kind = 'kevin.hq-live-floor.v1'
  updated_at = $now
  generated_at = $now
  cycle = $cycle
  cycle_authority = 'hq-live-floor'
  one_clock = 'floor'
  painter_frozen = $false
  cycle_frozen = $false
  support_cycle_is_not_authority = $true
  supervisor_version = $supVer
  supervisor_sha256 = $supSha
  supervisor_sha = $supSha
  selected_id = $selected
  status = $(if ($outcome) { 'OUTCOME_PROVEN' } else { $status })
  center_status = $hint
  center = $hint
  outcome_proven = $outcome
  action_era_ready_count = $readyCount
  ready_count = $readyCount
  last_invoke_started_at = $lastStart
  last_invoke_completed_at = $lastDone
  last_actor = $lastActor
  verify_actor = $lastActor
  waiting_item_budgets = $waiting
  budget_remaining = $null
  throttled = ($hint -eq 'THROTTLED')
  throttle_reason = $(if ($waiting) { 'WAITING_ITEM_BUDGETS' } else { $null })
  west_motor_proven = $westProven
  west_motor_completed_at = $westAt
  west_motor_receipt_sha256 = $westReceiptSha
  west_motor_invocation_id = 'invoke-owner-west-motor-parts-chase-fresh-8-v1'
  transport_proven = $transportProven
  transport_completed_at = $transportAt
  transport_receipt_sha256 = $transportReceiptSha
  transport_invocation_id = 'invoke-owner-west-motor-transport-dispatch-template-v1'
  transport_skill_key = 'vehicle-transport-mission-pack@1'
  dealership_proven = $dealProven
  dealership_completed_at = $dealAt
  dealership_receipt_sha256 = $dealReceiptSha
  dealership_invocation_id = 'invoke-owner-dealership-operations-opportunity-scan-fresh-2026-09-11-v1'
  dealership_skill_key = 'dealership-operations-opportunity-scan-pack@1'
  scaffold = $scaffold
  painted_hint = $hint
  skill_lab = $skillLab
  bridge = [ordered]@{
    status = $bridgeStatus
    puller = $bridgePuller
    at = $bridgeAt
    host = $bridgeHost
    why = $bridgeWhy
  }
  detail = $(if ($waiting) { 'WAITING_ITEM_BUDGETS — HOLD select' } else { $hint })
}


# Owner-outcomes stripes + last_attempt (halt gate; not painter). Merge if present.
$ooPath = Join-Path $ws 'reports\owner-outcomes-latest.json'
if (Test-Path -LiteralPath $ooPath) {
  try {
    $oo = Get-Content $ooPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($oo.newest_receipt -and $oo.newest_receipt.completed_at) {
      $doc['last_attempt'] = [string]$oo.newest_receipt.completed_at
      if (-not $doc['last_invoke_completed_at'] -or [string]$doc['last_invoke_completed_at'] -lt [string]$oo.newest_receipt.completed_at) {
        $doc['last_invoke_completed_at'] = [string]$oo.newest_receipt.completed_at
      }
    }
    $doc['owner_outcomes_path'] = 'reports/owner-outcomes-latest.json'
    $doc['west_motor_family_loop'] = 'docs/engineering/KEVIN-WEST-MOTOR-ONE-FAMILY-LOOP-v1.md'
    $doc['clone_prove_freeze'] = $true
    $map = @{
      'west-motor-lot-walk-checklist-pack@1' = 'lot_walk'
      'west-motor-aging-inventory-action-pack@1' = 'aging_inventory'
      'west-motor-delivery-prep-pack@1' = 'delivery_prep'
      'west-motor-recon-priority-board-pack@1' = 'recon_priority'
      'west-motor-trade-intake-pack@1' = 'trade_intake'
      'dealership-friction-reducer-pack@1' = 'friction_reducer'
    }
    foreach ($row in @($oo.outcomes)) {
      $sk = [string]$row.skill_key
      if ($map.ContainsKey($sk)) {
        $pfx = $map[$sk]
        $doc[($pfx + '_proven')] = $true
        $doc[($pfx + '_completed')] = $true
        $doc[($pfx + '_receipt_sha256')] = [string]$row.receipt_sha256
        $doc[($pfx + '_skill_key')] = $sk
        $doc[($pfx + '_invocation_id')] = [string]$row.invocation_id
        $doc[($pfx + '_completed_at')] = [string]$row.completed_at
      }
    }
  } catch {}
}

[IO.File]::WriteAllText($floorPath, (($doc | ConvertTo-Json -Depth 10) + "`n"), $utf8)
Write-Host ("hq-live-floor cycle={0} hint={1} status={2} ready={3}" -f $cycle, $hint, $doc.status, $readyCount)


# ONE CLOCK: sync support.supervisor.cycle UP to floor.cycle only. Never read support into floor.
$supportPath = Join-Path $ws 'reports\support-latest.json'
if (Test-Path -LiteralPath $supportPath) {
  try {
    $sup = Get-Content -LiteralPath $supportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $sc = 0
    if ($sup.supervisor -and $sup.supervisor.PSObject.Properties.Name -contains 'cycle') { $sc = [int]$sup.supervisor.cycle }
    if ($sc -lt $cycle) {
      if (-not $sup.supervisor) { $sup | Add-Member -NotePropertyName supervisor -NotePropertyValue ([ordered]@{}) -Force }
      $sup.supervisor.cycle = $cycle
      $sup | Add-Member -NotePropertyName cycle_authority -NotePropertyValue 'hq-live-floor' -Force
      $sup.generated_at = $now
      [IO.File]::WriteAllText($supportPath, (($sup | ConvertTo-Json -Depth 12) + "`n"), $utf8)
      Write-Host ("support.cycle synced UP -> {0} (was {1}; floor authoritative)" -f $cycle, $sc)
    } else {
      Write-Host ("support.cycle already >= floor ({0} >= {1}); floor remains authority" -f $sc, $cycle)
    }
  } catch { Write-Host "support.cycle sync FAIL: $_" }
}

if ($PushPublic) {
  $bytes = [IO.File]::ReadAllBytes($floorPath)
  $b64 = [Convert]::ToBase64String($bytes)
  $repoPath = 'reports/hq-live-floor.json'
  $sha = $null
  try { $sha = gh api "repos/hessmodee/KEVIN-WORK/contents/$repoPath" --jq .sha 2>$null } catch {}
  $msg = "GROKBOT_ACTED: hq-live-floor cycle $cycle $($hint)"
  if ($sha) {
    $r = gh api --method PUT "repos/hessmodee/KEVIN-WORK/contents/$repoPath" -f message="$msg" -f content="$b64" -f sha="$sha" --jq .commit.sha
  } else {
    $r = gh api --method PUT "repos/hessmodee/KEVIN-WORK/contents/$repoPath" -f message="$msg" -f content="$b64" --jq .commit.sha
  }
  Write-Host "public_floor_commit=$r"
  # also refresh public support so painter fallback cycle cannot stick at 449
  if (Test-Path -LiteralPath $supportPath) {
    $sbytes = [IO.File]::ReadAllBytes($supportPath)
    $sb64 = [Convert]::ToBase64String($sbytes)
    $spath = 'reports/support-latest.json'
    $ssha = $null
    try { $ssha = gh api "repos/hessmodee/KEVIN-WORK/contents/$spath" --jq .sha 2>$null } catch {}
    $smsg = "GROKBOT_ACTED: support-latest.supervisor.cycle sync $cycle (floor PushPublic)"
    if ($ssha) { $null = gh api --method PUT "repos/hessmodee/KEVIN-WORK/contents/$spath" -f message="$smsg" -f content="$sb64" -f sha="$ssha" --jq .commit.sha }
    else { $null = gh api --method PUT "repos/hessmodee/KEVIN-WORK/contents/$spath" -f message="$smsg" -f content="$sb64" --jq .commit.sha }
  }
}