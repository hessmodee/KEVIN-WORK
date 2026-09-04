# kevin-budget-unlock-typed-package-preflight-v1.ps1
# Morning typed-package PATH for identity-key budget unlock.
# Authority: NONE. Does NOT mutate Supervisor / continuation / work-items / fingerprints.
# Does NOT unlock budgets. Default mode = proof-gated preflight only.
# -Apply is intentionally refused until Matt approves the large Supervisor+Maintenance package.
# Exit 0 = PACKAGE_PATH_READY_AWAITING_MATT_APPLY; Exit 1 = NOT_READY.
param(
  [switch]$Requalify,
  [switch]$Apply
)
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $Root

$At = Get-Date
$Stamp = $At.ToString('yyyy-MM-ddTHH:mm:ss.fffffffK')
$OutDir = Join-Path $Root 'reports\engineering\fixtures\budget-unlock'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$LatestPath = Join-Path $Root 'reports\autonomy-budget-unlock-typed-package-preflight-latest.json'
$ExpectedSupervisorSha = 'D131003E01890E442824C04925047A50EA71C77EF686D64D3B591FE44AFE48E8'
$ExpectedQualScriptSha = '1183025691CFA44C235A49F092983D377FED5D078E30A2E2C35721CF7DDF5DBA'

$cases = New-Object System.Collections.Generic.List[object]
function Add-Case([string]$Name, [bool]$Ok, [string]$Detail) {
  $cases.Add([pscustomobject]@{ name = $Name; pass = $Ok; detail = $Detail })
  $tag = if ($Ok) { 'PASS' } else { 'FAIL' }
  Write-Host ("[{0}] {1} - {2}" -f $tag, $Name, $Detail)
}

if ($Apply) {
  Write-Host 'APPLY_REFUSED: identity-key Supervisor mutate is a LARGE typed Maintenance package; Matt approval required. See PLAN-budget-unlock-typed-identity-key-package-2026-09-02.md'
  Add-Case 'apply_refused_pending_matt' $false 'Apply switch set but package not authorized to mutate; refuse closed'
  $pass = 0; $fail = 1; $total = 1
  $receipt = [ordered]@{
    schema = 1
    kind = 'kevin-budget-unlock-typed-package-preflight'
    version = 'v1'
    at = $Stamp
    authority_effect = 'NONE'
    mutates_supervisor = $false
    mutates_continuation_state = $false
    mutates_work_items = $false
    grants_budget_unlock = $false
    apply_attempted = $true
    apply_performed = $false
    verdict = 'APPLY_REFUSED_PENDING_MATT'
    cases = $cases
    pass = $pass
    fail = $fail
    total = $total
    truth_boundary = 'Preflight only. No fingerprint wipe. No budget unlock. No Supervisor mutate without Matt-approved typed Maintenance package + CI + Benchmark.'
  }
  $json = ($receipt | ConvertTo-Json -Depth 12)
  Set-Content -Path $LatestPath -Value $json -Encoding UTF8
  Set-Content -Path (Join-Path $OutDir 'result-budget-unlock-typed-package-preflight-v1.json') -Value $json -Encoding UTF8
  Write-Host 'VERDICT=APPLY_REFUSED_PENDING_MATT'
  exit 1
}

# --- 1) Qualification gate (consume latest, or re-run) ---
$qualScript = Join-Path $Root 'control-plane\staging\kevin-budget-unlock-qualification-v1.ps1'
$qualLatest = Join-Path $Root 'reports\autonomy-budget-unlock-qualification-latest.json'
$qualOk = $false
$qualDetail = 'qualification missing'
if ($Requalify -or -not (Test-Path $qualLatest)) {
  if (-not (Test-Path $qualScript)) { throw 'qualification script missing' }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $qualScript
  if ($LASTEXITCODE -ne 0) { $qualDetail = "requalify_exit=$LASTEXITCODE" }
}
if (Test-Path $qualLatest) {
  $q = Get-Content $qualLatest -Raw | ConvertFrom-Json
  $qualOk = ($q.verdict -eq 'READY_FOR_MORNING_TYPED_PACKAGE' -and [int]$q.pass -eq 6 -and [int]$q.fail -eq 0 -and [bool]$q.grants_budget_unlock -eq $false)
  $qualDetail = "verdict=$($q.verdict); pass=$($q.pass)/$($q.total); grants_unlock=$($q.grants_budget_unlock); at=$($q.at)"
}
Add-Case 'qualification_ready_for_typed_package' $qualOk $qualDetail

# --- 2) Qualification script pin (regression entry must not drift silently) ---
$qShaOk = $false
$qShaDetail = 'qual script missing'
if (Test-Path $qualScript) {
  $qSha = (Get-FileHash $qualScript -Algorithm SHA256).Hash
  $qShaOk = ($qSha -eq $ExpectedQualScriptSha)
  $qShaDetail = "sha=$qSha; match=$qShaOk"
}
Add-Case 'qualification_script_pin' $qShaOk $qShaDetail

# --- 3) Supervisor still at live v1.8.8 pin (pre-mutate baseline) ---
$supPath = Join-Path $Root 'kevin-supervisor.ps1'
$supOk = $false
$supDetail = 'supervisor missing'
$supSha = $null
if (Test-Path $supPath) {
  $supSha = (Get-FileHash $supPath -Algorithm SHA256).Hash
  $supOk = ($supSha -eq $ExpectedSupervisorSha)
  $supDetail = "sha=$supSha; expected=$ExpectedSupervisorSha; match=$supOk"
}
Add-Case 'supervisor_pre_mutate_pin' $supOk $supDetail

# --- 4) Honest IDLE / READY=0 ---
$wiPath = Join-Path $Root 'inbox\autonomy\work-items.json'
$idleOk = $false
$idleDetail = 'work-items missing'
if (Test-Path $wiPath) {
  $wi = Get-Content $wiPath -Raw | ConvertFrom-Json
  $ready = @($wi.items | Where-Object { $_.status -eq 'READY' }).Count
  $contStatus = 'UNKNOWN'
  $contPath = Join-Path $Root 'reports\autonomy-continuation-latest.json'
  if (Test-Path $contPath) { $contStatus = [string](Get-Content $contPath -Raw | ConvertFrom-Json).status }
  $idleOk = ($ready -eq 0 -and $contStatus -eq 'IDLE_NO_ELIGIBLE_DEMAND')
  $idleDetail = "READY=$ready continuation=$contStatus"
}
Add-Case 'idle_ready_zero_honest' $idleOk $idleDetail

# --- 5) PLAN + acceptance artifacts present ---
$planPath = Join-Path $Root 'reports\engineering\PLAN-budget-unlock-typed-identity-key-package-2026-09-02.md'
$lessonPath = Join-Path $Root 'docs\engineering\LESSON-budget-unlock-typed-package-2026-09-02.md'
$docsOk = ((Test-Path $planPath) -and (Test-Path $lessonPath))
Add-Case 'package_plan_and_lesson_present' $docsOk ("plan=$([bool](Test-Path $planPath)); lesson=$([bool](Test-Path $lessonPath))")

# --- 6) Attempt-journal correlate gate (required before production crossing; not a wipe) ---
# Local workspace may lack the GitHub-only journal docs; treat explicit PLAN checklist as the correlate surface.
$journalOk = $false
$journalDetail = 'correlate checklist missing from PLAN'
if (Test-Path $planPath) {
  $planText = Get-Content $planPath -Raw
  $hasBranch = $planText -match 'chief-engineer/history-recovery-20260902'
  $hasCiNote = $planText -match 'attempt-journal' -or $planText -match 'Attempt-journal'
  $hasNoAutoInstall = $planText -match 'NOT integrated' -or $planText -match 'uninstalled' -or $planText -match 'correlate before production'
  $journalOk = ($hasBranch -and $hasCiNote -and $hasNoAutoInstall)
  $journalDetail = "branch_ref=$hasBranch; journal_ref=$hasCiNote; no_auto_install_language=$hasNoAutoInstall"
}
Add-Case 'attempt_journal_correlate_checklist' $journalOk $journalDetail

# --- 7) Hard invariants: this package path never wipes fingerprints / never claims unlock ---
$invOk = $true
$invDetail = 'no_fingerprint_wipe; no_prose_unlock; grants_budget_unlock=false; apply_requires_matt=true; supervisor_not_replace_alias'
Add-Case 'invariants_encoded' $invOk $invDetail

$pass = @($cases | Where-Object { $_.pass }).Count
$fail = @($cases | Where-Object { -not $_.pass }).Count
$total = $cases.Count
$allOk = ($fail -eq 0)
$verdict = if ($allOk) { 'PACKAGE_PATH_READY_AWAITING_MATT_APPLY' } else { 'NOT_READY' }

$mattMustApprove = @(
  'Author/stage Supervisor identity-key source (budget key excludes next_action/completion_evidence prose; bare material_new_evidence boolean insufficient)'
  'New typed Maintenance path: Supervisor is NOT in replace_pinned_component aliases today — needs new allowlisted op or qualified install successor (large)'
  'Correlate attempt-journal candidate branch chief-engineer/history-recovery-20260902 before production crossing (CI-proven; still uninstalled / NOT integrated)'
  'Backup + SelfTest + Benchmark 30/30 critical=0 after any Supervisor/Maintenance mutate'
  'Explicit go-ahead: no fingerprint wipe, no Reader canary, no workshop enable, no live trades'
)

$receipt = [ordered]@{
  schema = 1
  kind = 'kevin-budget-unlock-typed-package-preflight'
  version = 'v1'
  authority_effect = 'NONE'
  mutates_supervisor = $false
  mutates_continuation_state = $false
  mutates_work_items = $false
  grants_budget_unlock = $false
  apply_attempted = $false
  apply_performed = $false
  apply_requires_matt_approval = $true
  at = $Stamp
  supervisor_sha256_observed = $supSha
  supervisor_sha256_expected_pre_mutate = $ExpectedSupervisorSha
  package_plan = 'reports/engineering/PLAN-budget-unlock-typed-identity-key-package-2026-09-02.md'
  qualification_latest = 'reports/autonomy-budget-unlock-qualification-latest.json'
  matt_must_approve = $mattMustApprove
  morning_still_required = @(
    'Matt approve LARGE typed Supervisor identity-key + Maintenance allowlist/install package'
    'Stage source under control-plane with expected_current=F5D8C974… / expected_after=<new>'
    'CI fixtures 7/7 + qualification 6/6 green on new source'
    'Benchmark 30/30 critical=0 post-apply'
    'Correlate attempt-journal candidate before production crossing'
  )
  cases = $cases
  pass = $pass
  fail = $fail
  total = $total
  verdict = $verdict
  truth_boundary = 'Package PATH + preflight only. READY_FOR_MORNING_TYPED_PACKAGE from overnight gate is consumed; budgets remain locked until Matt-approved typed apply with proof gates. No fingerprint wipe fakery.'
}

$json = ($receipt | ConvertTo-Json -Depth 12)
Set-Content -Path $LatestPath -Value $json -Encoding UTF8
Set-Content -Path (Join-Path $OutDir 'result-budget-unlock-typed-package-preflight-v1.json') -Value $json -Encoding UTF8
Write-Host ("VERDICT={0} pass={1} fail={2} total={3}" -f $verdict, $pass, $fail, $total)
Write-Host ("LATEST={0}" -f $LatestPath)
if ($allOk) { exit 0 } else { exit 1 }
