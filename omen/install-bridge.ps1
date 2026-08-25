# Copies GitHub inbox into Kevin's workspace every 15 minutes.
# Run ONCE on HESS-PC as hessm. After that, Grok writes to GitHub and this pulls it.
$ErrorActionPreference = 'Stop'
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
$pull = Join-Path $ws 'pull-inbox.ps1'
New-Item -ItemType Directory -Force -Path $ws, (Join-Path $ws 'inbox'), (Join-Path $ws 'reports') | Out-Null

@'
$ErrorActionPreference = 'Stop'
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
$files = @(
  'inbox/FROM_GROK.md',
  'inbox/CURRENT_TASK.md',
  'workspace/HEARTBEAT.md',
  'workspace/SOUL.md',
  'omen/apply-lean.js'
)
foreach ($f in $files) {
  $api = "repos/hessmodee/KEVIN-WORK/contents/$f"
  try {
    $raw = gh api $api --jq .content
    if (-not $raw) { continue }
    $bytes = [Convert]::FromBase64String(($raw -replace "`n",""))
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    $destName = Split-Path $f -Leaf
    if ($f -like 'workspace/*') { $dest = Join-Path $ws $destName }
    elseif ($f -like 'omen/*') { $dest = Join-Path $ws $destName }
    else { $dest = Join-Path $ws $f }
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Set-Content -Encoding utf8 -Path $dest -Value $text
    Write-Host "pulled $f -> $dest"
  } catch { Write-Host "skip $f : $_" }
}
$stamp = @{
  at = (Get-Date).ToString('o')
  host = $env:COMPUTERNAME
  bridge = 'ok'
}
$stamp | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $ws 'reports\bridge-latest.json')
try {
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content -Raw (Join-Path $ws 'reports\bridge-latest.json'))))
  $api = 'repos/hessmodee/KEVIN-WORK/contents/reports/bridge-latest.json'
  $sha = $null
  try { $sha = gh api $api --jq .sha 2>$null } catch {}
  if ($sha) { gh api --method PUT $api -f message='bridge ping' -f content=$b64 -f sha=$sha | Out-Null }
  else { gh api --method PUT $api -f message='bridge ping' -f content=$b64 | Out-Null }
} catch { Write-Host "upload skip: $_" }
'@ | Set-Content -Encoding utf8 $pull

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$pull`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName 'KevinGitHubBridge' -Action $action -Trigger $trigger -User $env:USERNAME -RunLevel Limited -Force | Out-Null
& $pull
Write-Host 'Bridge installed. Inbox will refresh every 15 minutes.'
