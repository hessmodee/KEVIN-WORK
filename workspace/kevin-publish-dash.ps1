$ErrorActionPreference = "Stop"

$ws = Join-Path $env:USERPROFILE ".openclaw\workspace"
$reports = Join-Path $ws "reports"
$utf8 = New-Object System.Text.UTF8Encoding $false
$repo = "hessmodee/KEVIN-WORK"
$stamp = Join-Path $reports "publish-last.txt"

function Publish-Gh($repoPath, $localPath) {
  if (-not (Test-Path $localPath)) {
    Write-Host "skip missing $localPath"
    return
  }

  $hash = (Get-FileHash $localPath -Algorithm SHA256).Hash
  $prev = @()
  if (Test-Path $stamp) { $prev = @(Get-Content $stamp) }
  $key = "$repoPath $hash"
  if ($prev -contains $key) {
    Write-Host "unchanged $repoPath"
    return
  }

  $sha = (& gh api "repos/$repo/contents/$repoPath" --jq .sha 2>$null | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or -not $sha) {
    throw "remote SHA lookup failed for $repoPath"
  }

  $payload = [ordered]@{
    message = "kevin dash"
    content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($localPath))
    sha = $sha
  } | ConvertTo-Json -Compress

  $payloadFile = Join-Path $env:TEMP ("kevin-gh-payload-" + [guid]::NewGuid().ToString("n") + ".json")
  try {
    [IO.File]::WriteAllText($payloadFile, $payload, $utf8)
    & gh api --method PUT "repos/$repo/contents/$repoPath" --input $payloadFile --silent
    if ($LASTEXITCODE -ne 0) {
      throw "GitHub publish failed for $repoPath exit=$LASTEXITCODE"
    }
  }
  finally {
    Remove-Item $payloadFile -Force -ErrorAction SilentlyContinue
  }

  $rest = @($prev | Where-Object { $_ -notlike "$repoPath *" })
  [IO.File]::WriteAllLines($stamp, @($rest + $key), $utf8)
  Write-Host "published $repoPath"
}

Publish-Gh "reports/dashboard-state.json" (Join-Path $reports "dashboard-state.json")
