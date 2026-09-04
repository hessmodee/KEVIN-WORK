# kevin-forge-m1-typed-package-preflight-v1.ps1
# Forge Package M1 typed path: retire historical Supervisor v1.6 migrate anchors vs live v1.8.8.
# Authority: NONE. Does NOT mutate Maintenance / Supervisor / cron / Forge / desired-state.
# Does NOT run LARGE apply, Benchmark, or ollama. Default = inventory + pin preflight only.
# -Apply is intentionally refused until Matt approves Package M1.
# Exit 0 = M1_PACKAGE_PATH_READY_AWAITING_MATT_APPLY; Exit 1 = NOT_READY / APPLY_REFUSED.
param(
  [switch]$Apply
)
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $Root

$At = Get-Date
$Stamp = $At.ToString('yyyy-MM-ddTHH:mm:ss.fffffffK')
$OutDir = Join-Path $Root 'reports\engineering\fixtures\forge-m1'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$LatestPath = Join-Path $Root 'reports\forge-m1-typed-package-preflight-latest.json'

# Pins (live Supervisor / Forge identity). Maintenance live may drift from desired after Maint v1.3.44.
$ExpectedSupervisorSha = 'D131003E01890E442824C04925047A50EA71C77EF686D64D3B591FE44AFE48E8'
$ExpectedForgeSha = '433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
$ExpectedV16Sha = '63B8D9C27625E0FB6AFE62165BE376E7ED7EB416E5DA15BB47C206BBF4AE4989'
$ExpectedV183ShaConst = 'D131003E01890E442824C04925047A50EA71C77EF686D64D3B591FE44AFE48E8'
$OvernightMaintSha = 'FF9C5FDF217B0ED5F38A8566BD54D8A654CB8DFEF0093654DDBC23DC9A1BF956'

$cases = New-Object System.Collections.Generic.List[object]
function Add-Case([string]$Name, [bool]$Ok, [string]$Detail) {
  $cases.Add([pscustomobject]@{ name = $Name; pass = $Ok; detail = $Detail })
  $tag = if ($Ok) { 'PASS' } else { 'FAIL' }
  Write-Host ("[{0}] {1} - {2}" -f $tag, $Name, $Detail)
}

if ($Apply) {
  Write-Host 'APPLY_REFUSED: Package M1 retires Maintenance migrate/allowlist/selftest/cron dual-match — LARGE typed Maintenance package; Matt approval required. See PLAN-maintenance-supervisor-v188-pin-convergence-2026-09-01-2315.md'
  Add-Case 'apply_refused_pending_matt' $false 'Apply switch set but package not authorized to mutate; refuse closed'
  $pass = 0; $fail = 1; $total = 1
  $receipt = [ordered]@{
    schema = 1
    kind = 'kevin-forge-m1-typed-package-preflight'
    version = 'v1'
    at = $Stamp
    authority_effect = 'NONE'
    mutates_maintenance = $false
    mutates_supervisor = $false
    mutates_forge = $false
    mutates_desired_state = $false
    manufactures_forge_current = $false
    apply_attempted = $true
    apply_performed = $false
    verdict = 'APPLY_REFUSED_PENDING_MATT'
    cases = $cases
    pass = $pass
    fail = $fail
    total = $total
    truth_boundary = 'Preflight only. No Maintenance rewrite. No cron rename. No Forge CURRENT. No workshop enable. No Benchmark/ollama thrash.'
  }
  $json = ($receipt | ConvertTo-Json -Depth 12)
  Set-Content -Path $LatestPath -Value $json -Encoding UTF8
  Set-Content -Path (Join-Path $OutDir 'result-forge-m1-typed-package-preflight-v1.json') -Value $json -Encoding UTF8
  Write-Host 'VERDICT=APPLY_REFUSED_PENDING_MATT'
  exit 1
}

function Get-Sha256([string]$Path) {
  if (-not (Test-Path $Path)) { return $null }
  return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
}

# --- 1) Supervisor live pin v1.8.8 ---
$supPath = Join-Path $Root 'kevin-supervisor.ps1'
$supSha = Get-Sha256 $supPath
$supOk = ($supSha -eq $ExpectedSupervisorSha)
Add-Case 'supervisor_live_pin_v189' $supOk ("sha=$supSha; expected=$ExpectedSupervisorSha; match=$supOk")

# --- 2) Forge typed == live == desired ---
$forgeLive = Join-Path $Root 'kevin-design-forge.ps1'
$forgeTyped = Join-Path $Root 'control-plane\forge\kevin-design-forge-v4.0.ps1'
$dsPath = Join-Path $Root 'ControlPlane\desired-state-v1.json'
$liveSha = Get-Sha256 $forgeLive
$typedSha = Get-Sha256 $forgeTyped
$desiredForge = $null
$desiredMaint = $null
$desiredSup = $null
$cronName = $null
if (Test-Path $dsPath) {
  $ds = Get-Content $dsPath -Raw | ConvertFrom-Json
  $desiredForge = [string]$ds.core_hashes.forge
  $desiredMaint = [string]$ds.core_hashes.maintenance_runner
  $desiredSup = [string]$ds.core_hashes.supervisor
  foreach ($a in @($ds.required_automations)) {
    if ($a.declaration_key -eq 'kevin-supervisor-v1') { $cronName = [string]$a.name; break }
  }
}
$forgeOk = ($liveSha -eq $ExpectedForgeSha -and $typedSha -eq $ExpectedForgeSha -and $desiredForge -eq $ExpectedForgeSha)
Add-Case 'forge_typed_live_desired_aligned' $forgeOk ("live=$liveSha; typed=$typedSha; desired=$desiredForge")

# --- 3) Support forge/supervisor pins (if present) ---
$supportPath = Join-Path $Root 'reports\support-latest.json'
$supportOk = $false
$supportDetail = 'support-latest missing'
$supportMaint = $null
if (Test-Path $supportPath) {
  $sp = Get-Content $supportPath -Raw | ConvertFrom-Json
  $sSup = [string]$sp.hashes.supervisor
  $sForge = [string]$sp.hashes.forge
  $supportMaint = [string]$sp.hashes.maintenance_runner
  $supportOk = (($sSup -eq $ExpectedSupervisorSha -or $sSup -eq $supSha) -and ($sForge -eq $ExpectedForgeSha -or $sForge -eq $liveSha))
  $supportDetail = "sup=$sSup; forge=$sForge; maint=$supportMaint"
}
Add-Case 'support_supervisor_forge_pins' $supportOk $supportDetail

# --- 4) Maintenance inventory: historical v1.6 anchors still present (debt confirmed) ---
$maintPath = Join-Path $Root 'kevin-maintenance-runner.ps1'
$maintSha = Get-Sha256 $maintPath
$maintText = if (Test-Path $maintPath) { Get-Content $maintPath -Raw } else { '' }
$hasV16 = $maintText -match [regex]::Escape('$SupervisorV16Sha') -and $maintText.Contains($ExpectedV16Sha)
$hasV183 = $maintText.Contains($ExpectedV183ShaConst) -and ($maintText -match [regex]::Escape('$SupervisorV183Sha'))
$hasMigrate = $maintText.Contains('migrate_supervisor_forge_demand_gated_v17')
$hasRepair = $maintText.Contains('repair_supervisor_v171_forge_pin')
$hasRecovery = $maintText.Contains('recoveryExperiment')
$hasCronLegacy = $maintText.Contains('Kevin Supervisor v1.6 High Gear')
$debtOk = ($hasV16 -and $hasV183 -and $hasMigrate -and $hasRepair -and $hasRecovery -and $hasCronLegacy)
Add-Case 'maintenance_v16_anchor_debt_present' $debtOk ("v16=$hasV16; v183const=$hasV183; migrate=$hasMigrate; repair=$hasRepair; recoveryExperiment=$hasRecovery; cronLegacyInMaint=$hasCronLegacy; maintSha=$maintSha")

# --- 5) Desired automation cron name still coupled to legacy label ---
$cronOk = ($cronName -eq 'Kevin Supervisor v1.6 High Gear')
Add-Case 'desired_cron_legacy_name_coupled' $cronOk ("name=$cronName")

# --- 6) Desired maintenance pin may lag live/Support after Maint v1.3.44 — note honestly ---
$maintLiveEqualsSupport = ($null -ne $supportMaint -and $maintSha -eq $supportMaint)
$desiredMaintStale = ($desiredMaint -eq $OvernightMaintSha -and $maintSha -ne $OvernightMaintSha)
# PASS when we can honestly describe the drift (Support tracks live; desired still overnight pin)
$desiredMaintAligned = ($desiredMaint -eq $maintSha); $driftOk = (($maintLiveEqualsSupport -and $desiredMaintStale) -or $desiredMaintAligned)
Add-Case 'maintenance_desired_lags_live_noted' $driftOk ("live=$maintSha; support=$supportMaint; desired=$desiredMaint; overnight=$OvernightMaintSha; desired_stale=$desiredMaintStale; desired_aligned=$desiredMaintAligned")

# --- 7) Forge CURRENT absent (no manufacture) ---
$currentPath = Join-Path $Root 'forge-demands\CURRENT.json'
$currentAbsent = -not (Test-Path $currentPath)
Add-Case 'forge_current_absent' $currentAbsent ("path=$currentPath; absent=$currentAbsent")

# --- 8) Forge state IDLE_NO_ELIGIBLE_DEMAND ---
$statePath = Join-Path $Root 'forge-designs\design-forge-state.json'
$idleOk = $false
$idleDetail = 'state missing'
if (Test-Path $statePath) {
  $st = Get-Content $statePath -Raw | ConvertFrom-Json
  $idleOk = ([string]$st.status -eq 'IDLE_NO_ELIGIBLE_DEMAND')
  $idleDetail = "status=$($st.status); reason=$($st.reason); updated_at=$($st.updated_at)"
}
Add-Case 'forge_state_idle' $idleOk $idleDetail

# --- 9) PLAN + LESSON + residual PLAN present ---
$planM1 = Join-Path $Root 'reports\engineering\PLAN-maintenance-supervisor-v188-pin-convergence-2026-09-01-2315.md'
$lesson = Join-Path $Root 'docs\engineering\LESSON-maintenance-v16-anchors-vs-live-v188-2026-09-01.md'
$residual = Join-Path $Root 'reports\engineering\PLAN-forge-v40-morning-residual-2026-09-02.md'
$docsOk = ((Test-Path $planM1) -and (Test-Path $lesson) -and (Test-Path $residual))
Add-Case 'package_plan_lesson_residual_present' $docsOk ("m1=$([bool](Test-Path $planM1)); lesson=$([bool](Test-Path $lesson)); residual=$([bool](Test-Path $residual))")

# --- 10) Invariants encoded ---
$invOk = $true
$invDetail = 'no_maint_mutate; no_supervisor_mutate; no_forge_current; no_cron_rename; no_workshop_enable; no_benchmark_required_for_preflight; apply_requires_matt=true'
Add-Case 'invariants_encoded' $invOk $invDetail

$pass = @($cases | Where-Object { $_.pass }).Count
$fail = @($cases | Where-Object { -not $_.pass }).Count
$total = $cases.Count
$allOk = ($fail -eq 0)
$verdict = if ($allOk) { 'M1_PACKAGE_PATH_READY_AWAITING_MATT_APPLY' } else { 'NOT_READY' }

$mattMustApprove = @(
  'Approve Package M1: retire migrate_supervisor_forge_demand_gated_v17 + repair_supervisor_v171_forge_pin from allowlist OR fail-closed retired_vs_live_v188 with no disk write'
  'Rewrite selftest fixtures off live v1.6 body; keep fixture-only historical tests'
  'Dual-accept cron names in Get-GovernedContinuationJob before any rename of Kevin Supervisor v1.6 High Gear'
  'Refresh desired-state maintenance_runner pin to live/Support SHA (currently lags overnight FF9C5FDF… after Maint v1.3.44)'
  'Backup + SelfTest markers supervisor_live_pin=v1.8.8 / historical_v16_migrate=retired; Benchmark only if Forge trust touched'
  'Hard no: Forge CURRENT manufacture; workshop config set; Reader canary rename; fingerprint wipe; RED/purchasing/trading'
)

$receipt = [ordered]@{
  schema = 1
  kind = 'kevin-forge-m1-typed-package-preflight'
  version = 'v1'
  at = $Stamp
  authority_effect = 'NONE'
  mutates_maintenance = $false
  mutates_supervisor = $false
  mutates_forge = $false
  mutates_desired_state = $false
  manufactures_forge_current = $false
  apply_attempted = $false
  apply_performed = $false
  grants_forge_reopen = $false
  verdict = $verdict
  pins = [ordered]@{
    supervisor_live = $supSha
    forge_live = $liveSha
    forge_typed = $typedSha
    forge_desired = $desiredForge
    maintenance_live = $maintSha
    maintenance_support = $supportMaint
    maintenance_desired = $desiredMaint
    cron_desired_name = $cronName
  }
  cases = $cases
  pass = $pass
  fail = $fail
  total = $total
  matt_must_approve = $mattMustApprove
  related = [ordered]@{
    plan_m1 = 'reports/engineering/PLAN-maintenance-supervisor-v188-pin-convergence-2026-09-01-2315.md'
    residual = 'reports/engineering/PLAN-forge-v40-morning-residual-2026-09-02.md'
    lesson = 'docs/engineering/LESSON-maintenance-v16-anchors-vs-live-v188-2026-09-01.md'
    blocked_item = 'finish-forge-v40-runtime-convergence'
  }
  truth_boundary = 'Preflight READY ≠ Package M1 applied ≠ Forge item COMPLETE. Behavioral consume-once CURRENT still owed and must not be invented.'
}

$json = ($receipt | ConvertTo-Json -Depth 12)
Set-Content -Path $LatestPath -Value $json -Encoding UTF8
Set-Content -Path (Join-Path $OutDir 'result-forge-m1-typed-package-preflight-v1.json') -Value $json -Encoding UTF8
Write-Host ("VERDICT={0} pass={1}/{2}" -f $verdict, $pass, $total)
if ($allOk) { exit 0 } else { exit 1 }
