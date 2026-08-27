$ErrorActionPreference = "Stop"

$ws = Join-Path $env:USERPROFILE ".openclaw\workspace"
$reports = Join-Path $ws "reports"
$utf8 = New-Object System.Text.UTF8Encoding $false
$repo = "hessmodee/KEVIN-WORK"
$stamp = Join-Path $reports "publish-last.txt"

$allow = @(
  @{ repo = "reports/BOARD.md";            local = (Join-Path $reports "BOARD.md") },
  @{ repo = "reports/system-status.md";    local = (Join-Path $reports "system-status.md") },
  @{ repo = "reports/board.json";          local = (Join-Path $reports "board.json") },
  @{ repo = "reports/dashboard-state.json";local = (Join-Path $reports "dashboard-state.json") }
)

function Read-Stamp {
  if (Test-Path $stamp) { return @(Get-Content $stamp) }
  return @()
}

function Write-Stamp([string[]]$lines) {
  [IO.File]::WriteAllLines($stamp, $lines, $utf8)
}

function Publish-GhFile([string]$repoPath, [string]$localPath) {
  if (-not (Test-Path $localPath)) {
    Write-Host "skip missing $repoPath"
    return
  }

  $hash = (Get-FileHash $localPath -Algorithm SHA256).Hash
  $prev = @(Read-Stamp)
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
    message = "kevin publish"
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
  Write-Stamp @($rest + $key)
  Write-Host "published $repoPath"
}

foreach ($item in $allow) {
  Publish-GhFile $item.repo $item.local
}
