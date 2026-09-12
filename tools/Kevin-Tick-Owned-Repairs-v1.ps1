# Kevin-Tick-Owned-Repairs-v1.ps1
# Smallest forever teach: Tick owns (1) OUTCOME_PROVEN public/continuation sync
# and (2) console-hygiene detector. No hand-invoke. No PASS claim. No KEVIN_ACTED paint for GROKBOT.
# Grant: inbox/grants/OWNER-STANDING-GRANT-GREEN-YELLOW-v1.md (GREEN console hygiene + teach Tick)
$ErrorActionPreference = 'Continue'
$utf8 = New-Object System.Text.UTF8Encoding $false
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
$reports = Join-Path $ws 'reports'
New-Item -ItemType Directory -Force -Path $reports | Out-Null
$refresh = Join-Path $ws 'tools\Refresh-Kevin-PublicOutcomeProven-v1.ps1'
$detect = Join-Path $ws 'tools\Detect-Kevin-ConsoleHygiene-v1.ps1'
$out = Join-Path $reports 'tick-owned-repairs-latest.json'

$outcome = [ordered]@{ ran = $false; exit_code = $null; error = '' }
$hygiene = [ordered]@{ ran = $false; exit_code = $null; risk_count = $null; error = '' }

if (Test-Path -LiteralPath $refresh) {
  try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $refresh -Publish
    $outcome.ran = $true
    $outcome.exit_code = [int]$LASTEXITCODE
  } catch {
    $outcome.ran = $true
    $outcome.error = [string]$_.Exception.Message
    $outcome.exit_code = 1
  }
} else {
  $outcome.error = 'missing Refresh-Kevin-PublicOutcomeProven-v1.ps1'
}

if (Test-Path -LiteralPath $detect) {
  try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $detect
    $hygiene.ran = $true
    $hygiene.exit_code = [int]$LASTEXITCODE
    $detPath = Join-Path $reports 'console-hygiene-latest.json'
    if (Test-Path -LiteralPath $detPath) {
      try { $hygiene.risk_count = [int]((Get-Content -LiteralPath $detPath -Raw -Encoding UTF8 | ConvertFrom-Json).visible_console_risk_count) } catch {}
    }
  } catch {
    $hygiene.ran = $true
    $hygiene.error = [string]$_.Exception.Message
    $hygiene.exit_code = 1
  }
} else {
  $hygiene.error = 'missing Detect-Kevin-ConsoleHygiene-v1.ps1'
}

$doc = [ordered]@{
  schema = 1
  kind = 'kevin-tick-owned-repairs'
  version = '1.0.0'
  at = [datetime]::Now.ToString('o')
  authority = 'GREEN'
  actor_note = 'Tick-owned; do not dress GROKBOT_ACTED as KEVIN_ACTED'
  families = @('INVOKE_POST_PROVEN_PUBLIC_CONTINUATION_SYNC', 'CONSOLE_HYGIENE_DETECT_VBS_WRAP')
  outcome_proven_sync = $outcome
  console_hygiene_detect = $hygiene
  truth_boundary = 'Detector + public lag sync only. Not PASS. Not hand-invoke. ready=0 after PROVEN is expected.'
}
[IO.File]::WriteAllText($out, (($doc | ConvertTo-Json -Depth 8) + "`n"), $utf8)
Write-Host ("tick-owned-repairs outcome_exit={0} hygiene_risk={1}" -f $outcome.exit_code, $hygiene.risk_count)
$fail = 0
if ($outcome.exit_code -and $outcome.exit_code -ne 0) { $fail = 1 }
if ($hygiene.exit_code -and $hygiene.exit_code -ne 0) { $fail = 1 }
exit $fail