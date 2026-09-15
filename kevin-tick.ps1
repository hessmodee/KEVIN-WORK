try {
  $readerUp = $false
  $c = $null
  try {
    $c = New-Object System.Net.Sockets.TcpClient
    $iar = $c.BeginConnect("127.0.0.1", 19001, $null, $null)
    if ($iar.AsyncWaitHandle.WaitOne(1500, $false)) {
      $c.EndConnect($iar)
      $readerUp = $true
    }
  } catch {
  } finally {
    if ($c) { $c.Close() }
  }
  if (-not $readerUp) {
    Start-Process -FilePath "C:\Users\hessm\.openclaw-reader\start-reader-gateway.cmd" -WorkingDirectory "C:\Users\hessm\.openclaw-reader" -WindowStyle Hidden
    Write-Host "reader start (127.0.0.1:19001 not listening)"
  }
} catch {
  Write-Host "reader ensure FAIL: $_"
}

# Tick-owned Chat gateway (127.0.0.1:18789). Do not treat Reader 19001 as Chat.
# Do not re-enable the old interactive "OpenClaw Gateway" task. Keeper starts gateway.vbs.
try {
  $chatUp = $false
  $c2 = $null
  try {
    $c2 = New-Object System.Net.Sockets.TcpClient
    $iar2 = $c2.BeginConnect("127.0.0.1", 18789, $null, $null)
    if ($iar2.AsyncWaitHandle.WaitOne(1500, $false)) {
      $c2.EndConnect($iar2)
      $chatUp = $true
    }
  } catch {
  } finally {
    if ($c2) { $c2.Close() }
  }
  if (-not $chatUp) {
    Start-ScheduledTask -TaskName 'KevinGatewayKeeper'
    Write-Host "chat gateway start (127.0.0.1:18789 not listening) — KevinGatewayKeeper"
  }
} catch {
  Write-Host "chat gateway ensure FAIL: $_"
}

# Tick-owned: one board + close RUNNING invokes (do not recopy Supervisor)
try {
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\hessm\.openclaw\workspace\tools\Tick-CloseInvocationLoop-v1.ps1
  if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Host "tick-close-loop FAIL exit=$LASTEXITCODE"
  }
} catch {
  Write-Host "tick-close-loop FAIL: $_"
}
python C:\Users\hessm\.openclaw\workspace\helper_append_daily_note.py "tick"
python C:\Users\hessm\.openclaw\workspace\helper_weather_83263.py
python C:\Users\hessm\.openclaw\workspace\helper_context_83263.py
python C:\Users\hessm\.openclaw\workspace\helper_system_status.py
python C:\Users\hessm\.openclaw\workspace\helper_morning_brief.py
python C:\Users\hessm\.openclaw\workspace\helper_self_check.py
python C:\Users\hessm\.openclaw\workspace\helper_board.py
python C:\Users\hessm\.openclaw\workspace\helper_dashboard_state.py
if ($LASTEXITCODE -eq 0) {
  try {
    powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\hessm\.openclaw\workspace\kevin-publish.ps1
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
      Write-Host "publish FAIL exit=$LASTEXITCODE"
    }
  } catch {
    Write-Host "publish FAIL: $_"
  }
}

# Tick-owned forever: outcome_proven overlay + console-hygiene detector
try {
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\hessm\.openclaw\workspace\tools\Kevin-Tick-Owned-Repairs-v1.ps1
  if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Host "tick-owned-repairs FAIL exit=$LASTEXITCODE"
  }
} catch {
  Write-Host "tick-owned-repairs FAIL: $_"
}
