# kevin-discord-text-token-gate-v1.ps1
# FREE/SAFE: detect Kevin-local Discord credential presence. Never print secret values.
# Exit 0 + TOKEN_PRESENT when ready to apply OpenClaw Discord patch.
# Exit 2 + READY_FOR_OWNER_TOKEN when missing.
[CmdletBinding()]
param()
$ErrorActionPreference = "Stop"
$envFile = "C:\Users\hessm\.openclaw\.env"
$altFile = "C:\Users\hessm\.openclaw\credentials\kevin-discord\DISCORD_BOT_TOKEN"
$present = $false
$source = $null
if (Test-Path $envFile) {
  $lines = Get-Content $envFile -ErrorAction SilentlyContinue
  foreach ($line in $lines) {
    if ($line -match '^\s*DISCORD_BOT_TOKEN\s*=\s*\S+') { $present = $true; $source = ".env"; break }
  }
}
if (-not $present -and (Test-Path $altFile)) {
  $raw = (Get-Content $altFile -Raw -ErrorAction SilentlyContinue)
  if ($raw -and $raw.Trim().Length -gt 10) { $present = $true; $source = "credentials-file" }
}
# Also refuse if live channels.discord already somehow has plaintext (do not dump)
$cfg = "C:\Users\hessm\.openclaw\openclaw.json"
$hasDiscordBlock = $false
if (Test-Path $cfg) {
  try {
    $j = Get-Content $cfg -Raw | ConvertFrom-Json
    if ($j.channels -and $j.channels.discord) { $hasDiscordBlock = $true }
  } catch {}
}
if ($present) {
  Write-Output "TOKEN_PRESENT source=$source discord_block_in_openclaw=$hasDiscordBlock"
  Write-Output "NEXT: dry-run openclaw config patch using scratch/kevin-discord-text-v0/openclaw-discord.patch.json5 then apply; pair Matt; prove KEVIN_DISCORD_TEXT_OK"
  exit 0
} else {
  Write-Output "READY_FOR_OWNER_TOKEN"
  Write-Output "Place Kevin-local DISCORD_BOT_TOKEN in .env or credentials/kevin-discord/DISCORD_BOT_TOKEN via owner secret card. Do not invent."
  Write-Output "discord_block_in_openclaw=$hasDiscordBlock"
  exit 2
}
