$ErrorActionPreference = "Continue"
$gatewayVbs = Join-Path $env:USERPROFILE ".openclaw\gateway.vbs"
$reload = Join-Path $env:USERPROFILE ".openclaw\workspace\scratch\reload-chat-gateway.ps1"
$flag = Join-Path $env:USERPROFILE ".openclaw\workspace\scratch\gw-recycle-once.flag"
$log = Join-Path $env:USERPROFILE ".openclaw\workspace\scratch\keeper-recycle.log"
function L($m) { Add-Content -Path $log -Value ("[{0}] {1}" -f (Get-Date -Format o), $m) -ErrorAction SilentlyContinue }
function Test-ChatGatewayListen {
    $rows = @(Get-NetTCPConnection -State Listen -LocalPort 18789 -ErrorAction SilentlyContinue)
    foreach ($row in $rows) {
        if ($row.LocalAddress -eq '127.0.0.1' -or $row.LocalAddress -eq '::1') { return $true }
    }
    return $false
}
function Get-ChatGatewayProcess {
    # Reader also runs `openclaw ... gateway --port 19001`. Matching "gateway" alone
    # made Keeper treat Reader as Chat, so 18789 stayed down. Chat is 18789 only.
    @(
        Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match "(?i)openclaw.*gateway.*--port\s+18789" }
    )
}
L "KEEPER_BOOT"
if (Test-Path $flag) {
  L "FLAG_PRESENT"
  try {
    if (Test-Path $reload) {
      & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $reload *>&1 | ForEach-Object { L ("RELOAD " + $_) }
    } else { L "NO_RELOAD_SCRIPT" }
  } catch { L ("RELOAD_ERR " + $_.Exception.Message) }
  Remove-Item -Force $flag -ErrorAction SilentlyContinue
  L "FLAG_CLEARED"
}
while ($true) {
    try {
        $listening = Test-ChatGatewayListen
        $gw = @(Get-ChatGatewayProcess)
        if (-not $listening) {
            L ("CHAT_GATEWAY_DOWN listen=false procs=" + $gw.Count + " starting gateway.vbs")
            Start-Process -FilePath "$env:WINDIR\System32\wscript.exe" -ArgumentList @("//B","//Nologo",$gatewayVbs) -WindowStyle Hidden
            Start-Sleep -Seconds 8
            $up = Test-ChatGatewayListen
            L ("CHAT_GATEWAY_START_RESULT listen=" + $up)
        }
    } catch { L ("KEEPER_LOOP_ERR " + $_.Exception.Message) }
    Start-Sleep -Seconds 52
}
