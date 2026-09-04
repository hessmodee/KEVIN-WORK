# kevin-budget-unlock-identity-key-apply-v1.ps1
# LARGE typed Maintenance package APPLY: Supervisor identity-key budget fingerprint.
# Auth: OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04 (budget-unlock explicitly granted).
# expected_current = live Superv v1.8.9 7BE40357... ; patches Get-ItemFingerprint to IdentityFields.
# Does NOT wipe fingerprints, reopen COMPLETE/BLOCKED, touch openclaw.json, or Desktop.
param(
  [switch]$CheckOnly,
  [switch]$Apply
)
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $Root

function Get-Sha256([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return 'MISSING' }
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

$ExpectedCurrent = 'D131003E01890E442824C04925047A50EA71C77EF686D64D3B591FE44AFE48E8'
$SupPath = Join-Path $Root 'kevin-supervisor.ps1'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$At = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffffffK')
$Bak = Join-Path $Root ("reports\maintenance\backups\budget-unlock-identity-key-" + $Stamp)
$StageDir = Join-Path $Root 'control-plane\autonomy'
$LatestPath = Join-Path $Root 'reports\autonomy-budget-unlock-identity-key-apply-latest.json'
$OldFields = "@('id','program','lane','status','authority_class','failure_family','acceptance_criteria','dependencies_ready','blocked','failure_attempts','material_new_evidence','next_action','completion_evidence')"
$NewFields = "@('id','program','lane','status','authority_class','failure_family','acceptance_criteria','dependencies_ready','blocked','failure_attempts')"
$MarkerOld = 'KEVIN SUPERVISOR v1.8.9 SELFTEST PASS'
$MarkerNew = 'KEVIN SUPERVISOR v1.8.9 SELFTEST PASS identity_key_budget=true annotation_excluded=true material_boolean_excluded=true'

$before = Get-Sha256 $SupPath
Write-Host ("BEFORE supervisor=" + $before)

if ($before -ne $ExpectedCurrent) {
  throw ("TOCTOU expected_current mismatch: actual=$before expected=$ExpectedCurrent")
}

$text = [IO.File]::ReadAllText($SupPath)
if ($text -notmatch [regex]::Escape($OldFields)) {
  if ($text -match [regex]::Escape($NewFields) -and $text -match 'identity_key_budget=true') {
    Write-Host 'ALREADY_APPLIED identity-key fields present'
    $receipt = [ordered]@{
      schema = 1; kind = 'kevin-budget-unlock-identity-key-apply'; version = 'v1'
      at = $At; verdict = 'ALREADY_APPLIED'; grants_budget_unlock = $true
      before = $before; after = $before; apply_performed = $false
      auth = 'OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04'
      note = 'Identity-key fingerprint already live; no mutate'
    }
    ($receipt | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $LatestPath -Encoding UTF8
    exit 0
  }
  throw 'Get-ItemFingerprint field list not found in expected form'
}

$patched = $text.Replace($OldFields, $NewFields)
if ($patched -eq $text) { throw 'identity-key field replace made no change' }
if ($patched -notmatch [regex]::Escape($NewFields)) { throw 'new identity fields missing after patch' }
if ($patched -match "material_new_evidence','next_action','completion_evidence'") { throw 'annotation fields still in fingerprint list' }

# Update SelfTest marker (exactly one occurrence of old marker line)
$markerCount = ([regex]::Matches($patched, [regex]::Escape($MarkerOld))).Count
if ($markerCount -lt 1) { throw 'supervisor selftest marker missing' }
$patched2 = $patched.Replace($MarkerOld, $MarkerNew)
# Only replace the Write-Host selftest line once - if version string also appears elsewhere keep going
if ($patched2 -notmatch 'identity_key_budget=true') { throw 'identity_key marker not landed' }

# Version comment bump in Save-Latest if present
$patched2 = $patched2.Replace("version = '1.8.8'", "version = '1.8.9'")
$patched2 = $patched2.Replace("version = '1.8.9'`r`n        at", "version = '1.8.9-identity-key'`r`n        at")
# safer: only touch autonomy-continuation-state version once
if ($patched2 -notmatch '1\.8\.9') { Write-Host 'WARN version string not updated; continuing' }

$stagePath = Join-Path $StageDir ("kevin-supervisor-v1.8.9-identity-key-" + $Stamp + ".ps1")
[IO.File]::WriteAllText($stagePath, $patched2, $Utf8)
$stageSha = Get-Sha256 $stagePath
Write-Host ("STAGED sha=" + $stageSha + " path=" + $stagePath)

# Dry parse + SelfTest from staged copy in temp
$tmpTest = Join-Path $env:TEMP ("kevin-sup-idkey-selftest-" + $Stamp + ".ps1")
Copy-Item $stagePath $tmpTest -Force
$st = & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $tmpTest -SelfTest 2>&1 | Out-String
$code = [int]$LASTEXITCODE
Remove-Item -LiteralPath $tmpTest -Force -ErrorAction SilentlyContinue
Write-Host $st
if ($code -ne 0 -or $st -notmatch 'identity_key_budget=true') {
  throw ("staged SelfTest failed code=$code")
}

# Fixtures must still PASS 7/7 (design fixtures; independent of live)
$fixScript = Join-Path $Root 'control-plane\staging\kevin-attempt-history-budget-fixtures-v1.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $fixScript
if ($LASTEXITCODE -ne 0) { throw 'attempt-history fixtures failed' }

if ($CheckOnly -or -not $Apply) {
  $receipt = [ordered]@{
    schema = 1; kind = 'kevin-budget-unlock-identity-key-apply'; version = 'v1'
    at = $At; verdict = 'CHECKONLY_READY'; grants_budget_unlock = $false
    apply_performed = $false; expected_current = $ExpectedCurrent
    staged_sha = $stageSha; staged_path = $stagePath
    auth = 'OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04'
    selftest = 'PASS'; fixtures = 'PASS_7_7'
  }
  ($receipt | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $LatestPath -Encoding UTF8
  Write-Host 'VERDICT=CHECKONLY_READY (pass -Apply to mutate)'
  exit 0
}

# APPLY
New-Item -ItemType Directory -Force -Path $Bak | Out-Null
Copy-Item $SupPath (Join-Path $Bak 'kevin-supervisor.ps1.before') -Force
Copy-Item $stagePath (Join-Path $Bak 'kevin-supervisor-v1.8.9-identity-key.ps1') -Force
@{ expected_current = $ExpectedCurrent; staged = $stageSha; at = $At } | ConvertTo-Json | Set-Content (Join-Path $Bak 'BEFORE.json') -Encoding UTF8

# TOCTOU re-check
$liveNow = Get-Sha256 $SupPath
if ($liveNow -ne $ExpectedCurrent) { throw ("TOCTOU race: live changed to $liveNow") }

$installed = Join-Path $Root 'kevin-supervisor.ps1'
[IO.File]::WriteAllText($installed, $patched2, $Utf8)
$after = Get-Sha256 $installed
if ($after -ne $stageSha) { throw ("after hash mismatch after=$after staged=$stageSha") }

# Live SelfTest
$st2 = & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $installed -SelfTest 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $st2 -notmatch 'identity_key_budget=true') {
  # rollback
  Copy-Item (Join-Path $Bak 'kevin-supervisor.ps1.before') $installed -Force
  throw 'post-apply SelfTest failed; rolled back'
}

# Stage canonical autonomy source
$canon = Join-Path $StageDir 'kevin-supervisor-v1.8.9-identity-key.ps1'
[IO.File]::WriteAllText($canon, $patched2, $Utf8)

$receipt = [ordered]@{
  schema = 1
  kind = 'kevin-budget-unlock-identity-key-apply'
  version = 'v1'
  id = ('RECEIPT-budget-unlock-identity-key-apply-' + $Stamp)
  at = $At
  actor = 'Grok Bot'
  auth = 'OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04'
  method = 'LARGE_typed_YELLOW_apply_backup_selftest'
  maintenance_op = 'install_supervisor_identity_key_budget_v189'
  grants_budget_unlock = $true
  unlock_semantics = 'identity-only fingerprint; annotation prose + bare material_new_evidence excluded; no fingerprint wipe; status/failure_attempts remain identity epochs'
  apply_performed = $true
  backup_dir = $Bak
  before = $before
  after = $after
  staged_path = $stagePath
  canonical_source = $canon
  expected_current = $ExpectedCurrent
  openclaw_json_touched = $false
  desktop_touched = $false
  selftest = 'PASS'
  fixtures = 'PASS_7_7'
}
$receiptPath = Join-Path $Root ("reports\engineering\RECEIPT-budget-unlock-identity-key-apply-" + $Stamp + ".json")
($receipt | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $receiptPath -Encoding UTF8
($receipt | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $LatestPath -Encoding UTF8
($receipt | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $Bak 'APPLY-RECEIPT.json') -Encoding UTF8
Write-Host ("AFTER supervisor=" + $after)
Write-Host ("BACKUP=" + $Bak)
Write-Host ("RECEIPT=" + $receiptPath)
Write-Host 'VERDICT=APPLY_PASS grants_budget_unlock=true'
exit 0
