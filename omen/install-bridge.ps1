# Copies GitHub inbox into Kevin's workspace every 15 minutes.
# Run ONCE on HESS-PC as hessm (or re-run to refresh pull-inbox.ps1).
# After that, Grok writes to GitHub and this pulls it.
# v1.2 puller also fetches the catalog-contract repair and runs it when hashes mismatch.
$ErrorActionPreference = 'Stop'
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
$pull = Join-Path $ws 'pull-inbox.ps1'
New-Item -ItemType Directory -Force -Path $ws, (Join-Path $ws 'inbox'), (Join-Path $ws 'reports'), (Join-Path $ws 'tools') | Out-Null

$wrote = $false
try {
  $raw = gh api 'repos/hessmodee/KEVIN-WORK/contents/omen/pull-inbox.ps1' --jq .content
  if ($raw) {
    $bytes = [Convert]::FromBase64String(($raw -replace "`n", ''))
    [IO.File]::WriteAllBytes($pull, $bytes)
    $wrote = $true
  }
} catch {}
if (-not $wrote) {
  $local = Join-Path (Split-Path -Parent $PSCommandPath) 'pull-inbox.ps1'
  if (Test-Path -LiteralPath $local) { Copy-Item -LiteralPath $local -Destination $pull -Force; $wrote = $true }
}
if (-not $wrote) { throw 'GITHUB_FETCH_EMPTY omen/pull-inbox.ps1' }

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$pull`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName 'KevinGitHubBridge' -Action $action -Trigger $trigger -User $env:USERNAME -RunLevel Limited -Force | Out-Null
& $pull
Write-Host 'Bridge installed. Inbox + catalog-contract repair check every 15 minutes.'
