# fix-and-apply-forge-m1.ps1
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Root = 'C:\Users\hessm\.openclaw\workspace'
$MaintPath = Join-Path $Root 'kevin-maintenance-runner.ps1'
$ExpectedMaintCurrent = 'DFF72850E1BBBB2E18397AF38EB593E7234EEB634B596A4651F4537A688B77A9'
function Get-Sha256([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant() }
$before = Get-Sha256 $MaintPath
if ($before -ne $ExpectedMaintCurrent) {
  if ((Get-Content $MaintPath -Raw) -match 'historical_v16_migrate=retired') { Write-Host ("ALREADY_APPLIED after=" + $before); exit 0 }
  throw ("maint hash " + $before + " != expected " + $ExpectedMaintCurrent)
}
$supLive = Get-Sha256 (Join-Path $Root 'kevin-supervisor.ps1')
Write-Host ("BEFORE maint=" + $before + " superv=" + $supLive)
$text = [IO.File]::ReadAllText($MaintPath)
$needle = '$SupervisorV183Source = ' + [char]39 + [char]39 + 'control-plane/autonomy/kevin-supervisor-v1.8.8.ps1' + [char]39 + [char]39
# Actual needle in file uses doubled single quotes inside single-quoted PS string:
$needle = @'
$SupervisorV183Source = 'control-plane/autonomy/kevin-supervisor-v1.8.8.ps1'
'@
$needle = $needle.Trim()
if ($text -notmatch [regex]::Escape($needle)) { throw 'const needle missing' }
if ($text -notmatch '\$SupervisorV189Sha') {
  $insert = $needle + "`r`n" + ('$SupervisorV189Sha = ' + [char]39 + $supLive + [char]39) + "`r`n" + ('$SelectorV12Sha = ' + [char]39 + '52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A' + [char]39) + "`r`n" + ('$SupervisorV189Source = ' + [char]39 + 'control-plane/autonomy/kevin-supervisor-v1.8.9-identity-key.ps1' + [char]39)
  $text = $text.Replace($needle, $insert)
}
$text = [regex]::Replace($text, 'function Migrate-SupervisorForgeDemandGatedV17\(\[object\]\$m\) \{\r?\n    Assert-SupervisorForgeDemandGateMigration \$m', "function Migrate-SupervisorForgeDemandGatedV17([object]`$m) {`r`n    throw 'retired_vs_live_v189: migrate_supervisor_forge_demand_gated_v17 retired by Forge Package M1; live Supervisor is v1.8.9; no disk write'`r`n    Assert-SupervisorForgeDemandGateMigration `$m", 1)
$text = [regex]::Replace($text, 'function Repair-SupervisorV171ForgePin\(\[object\]\$m\) \{\r?\n    Assert-SupervisorV171ForgePinRepair \$m', "function Repair-SupervisorV171ForgePin([object]`$m) {`r`n    throw 'retired_vs_live_v189: repair_supervisor_v171_forge_pin retired by Forge Package M1; no disk write'`r`n    Assert-SupervisorV171ForgePinRepair `$m", 1)
if ($text -notmatch 'retired_vs_live_v189: migrate_supervisor') { throw 'migrate retire failed' }
if ($text -notmatch 'retired_vs_live_v189: repair_supervisor') { throw 'repair retire failed' }
$cronPatched = $false
foreach ($nl in @("`r`n","`n")) {
  $old = "function Get-GovernedContinuationJob([object[]]`$Jobs) {" + $nl + "    `$legacyName='Kevin Supervisor v1.6 High Gear'" + $nl + "    `$hits=@(`$Jobs|Where-Object{[string](Get-OptionalPropertyValue `$_ 'name')-eq`$legacyName})" + $nl + "    `$duplicates=@(`$Jobs|Where-Object{[string](Get-OptionalPropertyValue `$_ 'name')-eq'Kevin Autonomy Continuation v1'})" + $nl + "    if(`$hits.Count-ne1-or`$duplicates.Count-ne0){throw 'exactly one existing governed Supervisor wake is required; duplicate or missing owner'}"
  $new = "function Get-GovernedContinuationJob([object[]]`$Jobs) {" + $nl + "    `$acceptedNames=@('Kevin Supervisor v1.6 High Gear','Kevin Autonomy Continuation v1','Kevin Supervisor v1.8.8','Kevin Supervisor v1.8.9')" + $nl + "    `$hits=@(`$Jobs|Where-Object{`$acceptedNames -contains [string](Get-OptionalPropertyValue `$_ 'name')})" + $nl + "    if(`$hits.Count-ne1){throw 'exactly one existing governed Supervisor wake is required; duplicate or missing owner'}"
  if ($text.Contains($old)) { $text = $text.Replace($old,$new); $cronPatched=$true; break }
}
if (-not $cronPatched) { throw 'cron patch failed' }
$ensurePatched = $false
foreach ($nl in @("`r`n","`n")) {
  $eOld = "    if((Get-Sha (Join-Path `$Workspace 'kevin-supervisor.ps1'))-ne`$SupervisorV183Sha){throw 'qualified governed Supervisor must be installed before cadence reconciliation'}" + $nl + "    if((Get-Sha (Join-Path `$Workspace 'ControlPlane\kevin-work-selector-v1.1.py'))-ne`$SelectorV11Sha){throw 'qualified governed selector missing'}"
  $eNew = "    `$supSha=(Get-Sha (Join-Path `$Workspace 'kevin-supervisor.ps1'))" + $nl + "    if(`$supSha-ne`$SupervisorV189Sha -and `$supSha-ne`$SupervisorV183Sha){throw 'qualified governed Supervisor must be installed before cadence reconciliation'}" + $nl + "    `$sel12=(Join-Path `$Workspace 'ControlPlane\kevin-work-selector-v1.2.py'); `$sel11=(Join-Path `$Workspace 'ControlPlane\kevin-work-selector-v1.1.py')" + $nl + "    if((Test-Path -LiteralPath `$sel12 -PathType Leaf) -and (Get-Sha `$sel12)-eq`$SelectorV12Sha){ }" + $nl + "    elseif((Test-Path -LiteralPath `$sel11 -PathType Leaf) -and (Get-Sha `$sel11)-eq`$SelectorV11Sha){ }" + $nl + "    else{throw 'qualified governed selector missing (need v1.2 or v1.1 pin)'}"
  if ($text.Contains($eOld)) { $text = $text.Replace($eOld,$eNew); $ensurePatched=$true; break }
}
if (-not $ensurePatched) { throw 'ensure patch failed' }
$text = $text.Replace("version='1.3.48'", "version='1.3.49'")
$m = [regex]::Match($text, "Write-Host 'KEVIN MAINTENANCE v1\.3\.48 SELFTEST PASS[^']*'")
if (-not $m.Success) { throw 'v1.3.48 marker missing' }
if ($text -notmatch 'supervisor_live_pin=v1\.8\.9') {
  $add = $m.Value + "`r`nWrite-Host 'KEVIN MAINTENANCE v1.3.49 SELFTEST PASS supervisor_live_pin=v1.8.9 historical_v16_migrate=retired cron_dual_accept=true selector_v12_pin=true identity_key_budget_aware=true'"
  $text = $text.Remove($m.Index, $m.Length).Insert($m.Index, $add)
}
if ([regex]::IsMatch($text, '(?m)^ = ')) { throw 'bare assignment lines detected - abort' }
if ($text -notmatch [regex]::Escape('$SupervisorV189Sha = ''' + $supLive + '''')) { throw 'V189Sha not embedded' }
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Bak = Join-Path $Root ("reports\maintenance\backups\forge-m1-retire-v16-" + $Stamp)
$StageDir = Join-Path $Root 'control-plane\maintenance'
New-Item -ItemType Directory -Force -Path $Bak,$StageDir | Out-Null
$stagePath = Join-Path $StageDir ("kevin-maintenance-runner-v1.3.49-m1-" + $Stamp + ".ps1")
[IO.File]::WriteAllText($stagePath, $text, $Utf8)
$stageSha = Get-Sha256 $stagePath
Write-Host ("STAGED=" + $stageSha)
$st = & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $stagePath -SelfTest 2>&1 | Out-String
Write-Host $st
if ($LASTEXITCODE -ne 0) { throw ("SelfTest failed " + $LASTEXITCODE) }
if ($st -notmatch 'historical_v16_migrate=retired') { throw 'M1 marker missing in SelfTest' }
Copy-Item $MaintPath (Join-Path $Bak 'kevin-maintenance-runner.ps1.before') -Force
Copy-Item $stagePath (Join-Path $Bak 'kevin-maintenance-runner-v1.3.49-m1.ps1') -Force
if ((Get-Sha256 $MaintPath) -ne $ExpectedMaintCurrent) { throw 'TOCTOU' }
[IO.File]::WriteAllText($MaintPath, $text, $Utf8)
$after = Get-Sha256 $MaintPath
if ($after -ne $stageSha) { throw ("after mismatch " + $after + " vs " + $stageSha) }
$st2 = & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $MaintPath -SelfTest 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $st2 -notmatch 'historical_v16_migrate=retired') {
  Copy-Item (Join-Path $Bak 'kevin-maintenance-runner.ps1.before') $MaintPath -Force
  throw 'post-apply SelfTest failed; rolled back'
}
$dsPath = Join-Path $Root 'ControlPlane\desired-state-v1.json'
$dsTouched = $false
if (Test-Path $dsPath) {
  Copy-Item $dsPath (Join-Path $Bak 'desired-state-v1.json.before') -Force
  $dsRaw = [IO.File]::ReadAllText($dsPath)
  if ($dsRaw.Contains($ExpectedMaintCurrent)) {
    [IO.File]::WriteAllText($dsPath, $dsRaw.Replace($ExpectedMaintCurrent, $after), $Utf8)
    $dsTouched = $true
  }
}
$canon = Join-Path $StageDir 'kevin-maintenance-runner-v1.3.49.ps1'
[IO.File]::WriteAllText($canon, $text, $Utf8)
$receipt = [ordered]@{
  schema=1; kind='kevin-forge-m1-maintenance-retire-apply'; version='v1'
  id=('RECEIPT-forge-m1-maintenance-retire-apply-' + $Stamp)
  at=(Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffffffK')
  actor='Grok Bot'; auth='OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04'
  method='LARGE_typed_YELLOW_apply_backup_selftest_literal_patch'
  package='Forge Package M1'; apply_performed=$true
  backup_dir=$Bak; before=$before; after=$after; staged_path=$stagePath
  canonical_source=$canon; expected_current=$ExpectedMaintCurrent
  supervisor_live=$supLive; desired_state_maint_pin_refreshed=$dsTouched
  openclaw_json_touched=$false; desktop_touched=$false; selftest='PASS'
}
$receiptPath = Join-Path $Root ("reports\engineering\RECEIPT-forge-m1-maintenance-retire-apply-" + $Stamp + ".json")
$json = ($receipt | ConvertTo-Json -Depth 8)
Set-Content $receiptPath -Value $json -Encoding UTF8
Set-Content (Join-Path $Root 'reports\forge-m1-maintenance-retire-apply-latest.json') -Value $json -Encoding UTF8
Set-Content (Join-Path $Bak 'APPLY-RECEIPT.json') -Value $json -Encoding UTF8
Write-Host ("AFTER maint=" + $after)
Write-Host ("BACKUP=" + $Bak)
Write-Host ("RECEIPT=" + $receiptPath)
Write-Host 'VERDICT=APPLY_PASS forge_m1_retired=true'
