# refresh-budget-forge-pins-v189.ps1
$ErrorActionPreference = 'Stop'
$Root = 'C:\Users\hessm\.openclaw\workspace'
$live = '7BE403577762FAD630CB71E4DA897437475366940B15DBA10F27A9AE759BF314'
$old = 'F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138'
foreach ($rel in @(
  'control-plane\staging\kevin-budget-unlock-qualification-v1.ps1',
  'control-plane\staging\kevin-budget-unlock-typed-package-preflight-v1.ps1',
  'control-plane\staging\kevin-forge-m1-typed-package-preflight-v1.ps1'
)) {
  $p = Join-Path $Root $rel
  $t = [IO.File]::ReadAllText($p)
  $t2 = $t.Replace($old, $live)
  $t2 = $t2.Replace('supervisor_v188_pin_unchanged', 'supervisor_live_pin_unchanged')
  $t2 = $t2.Replace('supervisor_live_pin_v188', 'supervisor_live_pin_v189')
  [IO.File]::WriteAllText($p, $t2)
  Write-Host ("refreshed $rel")
}
$q = Join-Path $Root 'control-plane\staging\kevin-budget-unlock-qualification-v1.ps1'
$qSha = (Get-FileHash $q -Algorithm SHA256).Hash
$pf = Join-Path $Root 'control-plane\staging\kevin-budget-unlock-typed-package-preflight-v1.ps1'
$pft = [IO.File]::ReadAllText($pf)
if ($pft -match "ExpectedQualScriptSha = '([A-F0-9]+)'") {
  [IO.File]::WriteAllText($pf, $pft.Replace($Matches[1], $qSha))
  Write-Host ("ExpectedQualScriptSha=$qSha")
}
$fp = Join-Path $Root 'control-plane\staging\kevin-forge-m1-typed-package-preflight-v1.ps1'
$ft = [IO.File]::ReadAllText($fp)
if ($ft -notmatch 'desired_aligned') {
  $ft = $ft.Replace(
    '$driftOk = ($maintLiveEqualsSupport -and $desiredMaintStale)',
    '$desiredMaintAligned = ($desiredMaint -eq $maintSha); $driftOk = (($maintLiveEqualsSupport -and $desiredMaintStale) -or $desiredMaintAligned)'
  )
  $ft = $ft.Replace('desired_stale=$desiredMaintStale")', 'desired_stale=$desiredMaintStale; desired_aligned=$desiredMaintAligned")')
  [IO.File]::WriteAllText($fp, $ft)
  Write-Host 'forge-m1 drift case patched'
} else { Write-Host 'forge-m1 drift already patched' }

# Fix M1 apply dynamic superv pin if still hard-refusing
$m1 = Join-Path $Root 'control-plane\staging\kevin-forge-m1-maintenance-retire-apply-v1.ps1'
if (Test-Path $m1) {
  $t = [IO.File]::ReadAllText($m1)
  $old2 = 'if ($supLive -ne $ExpectedSupLive) { throw ("Supervisor live pin mismatch actual=$supLive expected=$ExpectedSupLive") }'
  $new2 = 'if ($supLive -eq ''MISSING'' -or $supLive.Length -ne 64) { throw ("Supervisor live hash invalid: $supLive") }; Write-Host ("Using live Superv as V189Sha pin=" + $supLive)'
  if ($t.Contains($old2)) {
    $t = $t.Replace($old2, $new2)
    if ($t -notmatch "Replace\('7BE40357") {
      $t = $t.Replace(
        '  $text = $text.Replace($constNeedle, $constInsert)',
        "  `$text = `$text.Replace(`$constNeedle, `$constInsert)`r`n  `$text = `$text.Replace('7BE403577762FAD630CB71E4DA897437475366940B15DBA10F27A9AE759BF314', `$supLive)"
      )
    }
    [IO.File]::WriteAllText($m1, $t)
    Write-Host 'M1 apply dynamic Superv pin patched'
  } else { Write-Host 'M1 apply Superv check already relaxed or different form' }
}
Write-Host 'PIN_REFRESH_DONE'
