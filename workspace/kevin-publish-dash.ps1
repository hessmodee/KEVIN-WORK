$ErrorActionPreference = "Stop"
$ws = Join-Path $env:USERPROFILE ".openclaw\workspace"
$utf8 = New-Object System.Text.UTF8Encoding $false
function Publish-Gh($repoPath, $localPath) {
  if (-not (Test-Path $localPath)) { Write-Host "skip missing $localPath"; return }
  $hash = (Get-FileHash $localPath -Algorithm SHA256).Hash
  $stamp = Join-Path $ws "reports\publish-last.txt"
  $prev = @()
  if (Test-Path $stamp) { $prev = Get-Content $stamp }
  $key = "$repoPath $hash"
  if ($prev -contains $key) { Write-Host "unchanged $repoPath"; return }
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($localPath))
  $sha = $null
  try { $sha = gh api "repos/hessmodee/KEVIN-WORK/contents/$repoPath" --jq .sha 2>$null } catch {}
  if ($sha) {
    gh api --method PUT "repos/hessmodee/KEVIN-WORK/contents/$repoPath" -f message="kevin dash" -f content="$b64" -f sha="$sha" | Out-Null
  } else {
    gh api --method PUT "repos/hessmodee/KEVIN-WORK/contents/$repoPath" -f message="kevin dash" -f content="$b64" | Out-Null
  }
  $rest = $prev | Where-Object { $_ -notlike "$repoPath *" }
  $out = @($rest + $key)
  [IO.File]::WriteAllLines($stamp, $out, $utf8)
  Write-Host "published $repoPath"
}
Publish-Gh "reports/dashboard-state.json" (Join-Path $ws "reports\dashboard-state.json")
