$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $dir

function Require-Ok([string]$name) {
  if ($LASTEXITCODE -ne 0) {
    throw "STOP: $name failed ($LASTEXITCODE)"
  }
}

try {
  Write-Host "===== GATE 1 plugin:build ====="
  npm run plugin:build
  Require-Ok "npm run plugin:build"

  Write-Host "===== GATE 2 plugin:validate ====="
  npm run plugin:validate
  Require-Ok "npm run plugin:validate"

  Write-Host "===== GATE 3 tests ====="
  npm test
  Require-Ok "npm test"

  Write-Host "===== openclaw.plugin.json ====="
  Get-Content (Join-Path $dir "openclaw.plugin.json") -Raw

  Write-Host "REAL GREEN BENCH. Stop. Do not install, link, enable, or restart."
  exit 0
} catch {
  Write-Host $_
  exit 1
}
