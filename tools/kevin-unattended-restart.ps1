# Kevin unattended restart helper — NO PASSWORD. Owner Autologon must already be configured.
param(
  [int]$DelaySec = 60,
  [switch]$WhatIf
)
Write-Output "KEVIN_RESTART_PLAN delaySec=$DelaySec"
Write-Output "REQUIRES: READY_FOR_OWNER_AUTOLOGON completed by Owner (Sysinternals Autologon LSA)."
Write-Output "POST: see docs/engineering/KEVIN-RESUME-AFTER-REBOOT-CHECKLIST-v1.md"
if ($WhatIf) {
  Write-Output "WHATIF shutdown /r /t $DelaySec"
  exit 0
}
shutdown.exe /r /t $DelaySec /c "Kevin scheduled restart — Owner Autologon expected"
Write-Output "KEVIN_RESTART_ISSUED"
