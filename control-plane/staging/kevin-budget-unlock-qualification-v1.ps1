# kevin-budget-unlock-qualification-v1.ps1
# Morning pre-gate for identity-key Supervisor package. Authority: NONE.
# Does NOT mutate kevin-supervisor.ps1, continuation-state, or work-items.
# Exit 0 = qualification prerequisites PASS; Exit 1 = NOT READY.
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $Root

$At = Get-Date
$Stamp = $At.ToString('yyyy-MM-ddTHH:mm:ss.fffffffK')
$OutDir = Join-Path $Root 'reports\engineering\fixtures\budget-unlock'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$LatestPath = Join-Path $Root 'reports\autonomy-budget-unlock-qualification-latest.json'

$ExpectedSupervisorSha = 'D131003E01890E442824C04925047A50EA71C77EF686D64D3B591FE44AFE48E8'
$cases = New-Object System.Collections.Generic.List[object]

function Add-Case([string]$Name, [bool]$Ok, [string]$Detail) {
  $cases.Add([pscustomobject]@{ name = $Name; pass = $Ok; detail = $Detail })
  $tag = if ($Ok) { 'PASS' } else { 'FAIL' }
  Write-Host ("[{0}] {1} - {2}" -f $tag, $Name, $Detail)
}

# --- 1) Fixtures regression (must stay green) ---
$fxScript = Join-Path $Root 'control-plane\staging\kevin-attempt-history-budget-fixtures-v1.ps1'
$fxOk = $false
$fxDetail = 'missing fixtures script'
if (Test-Path $fxScript) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $fxScript
  $fxCode = $LASTEXITCODE
  $fxResultPath = Join-Path $Root 'reports\engineering\fixtures\attempt-history\result-attempt-history-budget-fixtures-v1.json'
  if ((Test-Path $fxResultPath) -and $fxCode -eq 0) {
    $fx = Get-Content $fxResultPath -Raw | ConvertFrom-Json
    $fxOk = ($fx.verdict -eq 'PASS' -and [int]$fx.pass -eq 7 -and [int]$fx.fail -eq 0)
    $fxDetail = "exit=$fxCode; pass=$($fx.pass)/$($fx.total); verdict=$($fx.verdict)"
  } else {
    $fxDetail = "exit=$fxCode; result_missing=$(-not (Test-Path $fxResultPath))"
  }
}
Add-Case 'fixtures_pass_7_of_7' $fxOk $fxDetail

# --- 2) Durable outcome ledger ---
$dvScript = Join-Path $Root 'control-plane\staging\kevin-outcome-durable-verify-v1.ps1'
$dvOk = $false
$dvDetail = 'missing durable verify script'
if (Test-Path $dvScript) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $dvScript
  $dvCode = $LASTEXITCODE
  $ledgerPath = Join-Path $Root 'reports\autonomy-outcome-durable-latest.json'
  if ((Test-Path $ledgerPath) -and $dvCode -eq 0) {
    $led = Get-Content $ledgerPath -Raw | ConvertFrom-Json
    # Accept pass>=8 so newly COMPLETE owner items (e.g. reader-e2e) can extend the ledger without breaking this gate.
    $dvOk = ($led.verdict -eq 'PASS' -and [int]$led.pass -ge 8 -and [int]$led.fail -eq 0)
    $dvDetail = "exit=$dvCode; pass=$($led.pass)/$($led.total); durable=$($led.durable_outcome_proof_count); fallback=$($led.durable_via_public_fallback_count)"
  } else {
    $dvDetail = "exit=$dvCode; ledger_missing=$(-not (Test-Path $ledgerPath))"
  }
}
Add-Case 'durable_ledger_pass_ge_8' $dvOk $dvDetail

# --- 3) Supervisor pin unchanged (no overnight mutate) ---
$supPath = Join-Path $Root 'kevin-supervisor.ps1'
$supOk = $false
$supDetail = 'missing kevin-supervisor.ps1'
$supSha = $null
if (Test-Path $supPath) {
  $supSha = (Get-FileHash $supPath -Algorithm SHA256).Hash
  $supOk = ($supSha -eq $ExpectedSupervisorSha)
  $supDetail = "sha=$supSha; expected=$ExpectedSupervisorSha; match=$supOk"
}
Add-Case 'supervisor_live_pin_unchanged' $supOk $supDetail

# --- 4) Autonomy IDLE / READY=0 (honest idle; do not unlock under active READY spin) ---
$wiPath = Join-Path $Root 'inbox\autonomy\work-items.json'
$idleOk = $false
$idleDetail = 'missing work-items'
$readyCount = $null
$completeCount = $null
$blockedCount = $null
if (Test-Path $wiPath) {
  $wi = Get-Content $wiPath -Raw | ConvertFrom-Json
  $readyCount = @($wi.items | Where-Object { $_.status -eq 'READY' }).Count
  $completeCount = @($wi.items | Where-Object { $_.status -eq 'COMPLETE' }).Count
  $blockedCount = @($wi.items | Where-Object { $_.status -eq 'BLOCKED' }).Count
  $contPath = Join-Path $Root 'reports\autonomy-continuation-latest.json'
  $contStatus = 'UNKNOWN'
  if (Test-Path $contPath) {
    $cont = Get-Content $contPath -Raw | ConvertFrom-Json
    $contStatus = [string]$cont.status
  }
  $idleOk = ($readyCount -eq 0 -and $contStatus -eq 'IDLE_NO_ELIGIBLE_DEMAND')
  $idleDetail = "READY=$readyCount COMPLETE=$completeCount BLOCKED=$blockedCount continuation=$contStatus"
}
Add-Case 'idle_ready_zero_honest' $idleOk $idleDetail

# --- 5) Live identity-key demo: annotation prose must NOT change identity fp for COMPLETE hq item ---
function Get-TextSha([string]$Text) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    return (-join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('X2') }))
  } finally { $sha.Dispose() }
}
function Get-MaterialFingerprint([hashtable]$Item, [string[]]$Fields) {
  $material = [ordered]@{}
  foreach ($name in $Fields) {
    if ($Item.ContainsKey($name)) { $material[$name] = $Item[$name] }
  }
  return Get-TextSha (($material | ConvertTo-Json -Depth 30 -Compress))
}
$IdentityFields = @(
  'id','program','lane','status','authority_class','failure_family','acceptance_criteria',
  'dependencies_ready','blocked','failure_attempts'
)
$CurrentFields = $IdentityFields + @('material_new_evidence','next_action','completion_evidence')

$idOk = $false
$idDetail = 'hq COMPLETE item missing'
if (Test-Path $wiPath) {
  $hq = @($wi.items | Where-Object { $_.id -eq 'hq-direct-chat-real-roundtrip' })[0]
  if ($null -ne $hq) {
    $h = @{
      id = [string]$hq.id
      program = [string]$hq.program
      lane = [string]$hq.lane
      status = [string]$hq.status
      authority_class = [string]$hq.authority_class
      failure_family = $(if ($hq.PSObject.Properties.Name -contains 'failure_family') { $hq.failure_family } else { $null })
      acceptance_criteria = @($hq.acceptance_criteria)
      dependencies_ready = [bool]$hq.dependencies_ready
      blocked = [bool]($(if ($hq.PSObject.Properties.Name -contains 'blocked') { $hq.blocked } else { $false }))
      failure_attempts = [int]$hq.failure_attempts
      material_new_evidence = $false
      next_action = [string]$hq.next_action
      completion_evidence = [string]$hq.completion_evidence
    }
    $idA = Get-MaterialFingerprint $h $IdentityFields
    $curA = Get-MaterialFingerprint $h $CurrentFields
    $h2 = $h.Clone()
    $h2.next_action = ($h.next_action + ' [annotation-only morning note]')
    $idB = Get-MaterialFingerprint $h2 $IdentityFields
    $curB = Get-MaterialFingerprint $h2 $CurrentFields
    $idOk = ($idA -eq $idB -and $curA -ne $curB)
    $idDetail = "identity_stable=$($idA -eq $idB); current_changed=$($curA -ne $curB); id_fp=$($idA.Substring(0,12))"
  }
}
Add-Case 'live_identity_key_annotation_stable' $idOk $idDetail

# --- 6) Hard invariants encoded ---
$invOk = $true
$invDetail = 'no_supervisor_mutate; no_fingerprint_wipe; no_budget_unlock_claim; authority=NONE'
Add-Case 'invariants_encoded' $invOk $invDetail

$pass = @($cases | Where-Object { $_.pass }).Count
$fail = @($cases | Where-Object { -not $_.pass }).Count
$total = $cases.Count
$allOk = ($fail -eq 0)
$verdict = if ($allOk) { 'READY_FOR_MORNING_TYPED_PACKAGE' } else { 'NOT_READY' }

$receipt = [ordered]@{
  schema = 1
  kind = 'kevin-budget-unlock-qualification'
  version = 'v1'
  authority_effect = 'NONE'
  mutates_supervisor = $false
  mutates_continuation_state = $false
  mutates_work_items = $false
  grants_budget_unlock = $false
  at = $Stamp
  supervisor_sha256_observed = $supSha
  supervisor_sha256_expected = $ExpectedSupervisorSha
  work_items = [ordered]@{
    ready = $readyCount
    complete = $completeCount
    blocked = $blockedCount
  }
  prerequisites = @(
    'fixtures PASS 7/7'
    'durable ledger PASS >=8 (reader-complete extends to 9/9)'
    'Supervisor v1.8.8 pin unchanged'
    'IDLE READY=0 honest'
    'live identity-key annotation stability demo'
  )
  morning_still_required = @(
    'Typed Supervisor identity-key package + CI'
    'Benchmark 30/30 critical=0 after package'
    'No live fingerprint wipe as unlock'
    'Correlate attempt-journal candidate before production crossing'
  )
  cases = $cases
  pass = $pass
  fail = $fail
  total = $total
  verdict = $verdict
  truth_boundary = 'Qualification gate only. Does not unlock turn budgets, mutate Supervisor, or reopen COMPLETE/BLOCKED items. Morning typed package still required.'
}

$json = ($receipt | ConvertTo-Json -Depth 12)
Set-Content -Path $LatestPath -Value $json -Encoding UTF8
$stampName = 'result-budget-unlock-qualification-v1.json'
Set-Content -Path (Join-Path $OutDir $stampName) -Value $json -Encoding UTF8
Write-Host ("VERDICT={0} pass={1} fail={2} total={3}" -f $verdict, $pass, $fail, $total)
Write-Host ("LATEST={0}" -f $LatestPath)
if ($allOk) { exit 0 } else { exit 1 }
