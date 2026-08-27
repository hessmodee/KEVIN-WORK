$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding $false
$src = Join-Path $env:USERPROFILE ".openclaw"
$ws = Join-Path $src "workspace"
$freeze = Join-Path $src "extensions\kevin-core-v0.1.0-green"
$reports = Join-Path $ws "reports"
$log = Join-Path $reports "night-forge.jsonl"
$legacy = Join-Path $reports "forge-night.jsonl"
$latest = Join-Path $reports "night-forge-latest.json"
$summary = Join-Path $reports "night-forge-summary.md"
$halt = Join-Path $reports "night-forge-halt.txt"
$statePy = Join-Path $ws "helper_kevin_state.py"
New-Item -ItemType Directory -Force -Path $reports | Out-Null
$script:LastProcExit = -1
$qPass = 0; $qFail = 0; $qNr = 0; $qTools = 0
$status = "FAIL"; $san = "FAIL"; $plug = "FAIL"

function Rec([hashtable]$h) {
  $h.at = (Get-Date).ToString("o")
  $h.host = $env:COMPUTERNAME
  $line = ($h | ConvertTo-Json -Compress)
  [IO.File]::AppendAllText($log, $line + "`n", $utf8)
  [IO.File]::AppendAllText($legacy, $line + "`n", $utf8)
}

function Write-Latest([hashtable]$h) {
  $h.at = (Get-Date).ToString("o")
  [IO.File]::WriteAllText($latest, (($h | ConvertTo-Json -Depth 6) + "`n"), $utf8)
}

function Format-WinArgs([string[]]$ArgList) {
  ($ArgList | ForEach-Object {
    $a = [string]$_
    if ($a -match '[\s"]') { '"' + ($a -replace '"','\"') + '"' } else { $a }
  }) -join ' '
}

function Invoke-TimeoutProc {
  param(
    [string]$FileName,
    [string[]]$ArgList,
    [int]$Seconds,
    [string]$Cwd,
    [string]$Label
  )
  Write-Host "BEGIN $Label"
  $id = [guid]::NewGuid().ToString("n").Substring(0, 8)
  $safe = ($Label -replace "[^A-Za-z0-9_-]", "_")
  $outFile = Join-Path $env:TEMP "forge-$safe-$id.out.txt"
  $errFile = Join-Path $env:TEMP "forge-$safe-$id.err.txt"
  $sw = [Diagnostics.Stopwatch]::StartNew()
  $cmdline = Format-WinArgs $ArgList
  $p = Start-Process -FilePath $FileName -ArgumentList $cmdline -WorkingDirectory $Cwd -NoNewWindow -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
  $null = $p.Handle
  if (-not $p.WaitForExit($Seconds * 1000)) {
    try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
    $sw.Stop()
    throw "TIMEOUT $Label ${Seconds}s"
  }
  $p.Refresh()
  $deadline = (Get-Date).AddSeconds(2)
  while (-not $p.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 50; $p.Refresh() }
  $exitCode = $p.ExitCode
  if ($null -eq $exitCode) {
    $p.Refresh()
    $exitCode = $p.ExitCode
  }
  $sw.Stop()
  if ($null -eq $exitCode) { throw "FAIL $Label missing-exit-code" }
  $script:LastProcExit = [int]$exitCode
  $out = ""
  $err = ""
  if (Test-Path $outFile) { $out = [IO.File]::ReadAllText($outFile) }
  if (Test-Path $errFile) { $err = [IO.File]::ReadAllText($errFile) }
  Write-Host "END $Label exit=$($script:LastProcExit) ms=$($sw.ElapsedMilliseconds)"
  if ($script:LastProcExit -ne 0) { throw "FAIL $Label exit=$($script:LastProcExit) $err" }
  return $out
}

function Write-Summary {
  $rows = @()
  if (Test-Path $log) {
    Get-Content $log | ForEach-Object {
      if ($_.Trim()) { try { $rows += ($_ | ConvertFrom-Json) } catch {} }
    }
  }
  $cycles = @($rows | Where-Object { $_.step -eq "cycle" })
  $pass = @($cycles | Where-Object { $_.result -eq "PASS" }).Count
  $fail = @($cycles | Where-Object { $_.result -eq "FAIL" }).Count
  $md = @(
    "# Night Forge summary",
    "- cycles PASS/FAIL: $pass / $fail",
    "- latest: $latest",
    "- halt: $(if (Test-Path $halt) { (Get-Content $halt -Raw) } else { 'none' })"
  ) -join "`n"
  [IO.File]::WriteAllText($summary, $md + "`n", $utf8)
}

$mutex = New-Object System.Threading.Mutex($false, "Global\KevinNightForge")
$owned = $false
try {
  $owned = $mutex.WaitOne(0)
  if (-not $owned) {
    Rec @{ step = "cycle"; result = "SKIP_OVERLAP" }
    Write-Latest @{ overall = "SKIP_OVERLAP" }
    Write-Host "SKIP_OVERLAP"
    exit 0
  }
  if (Test-Path $halt) {
    Rec @{ step = "cycle"; result = "HALTED" }
    Write-Latest @{ overall = "HALTED"; reason = (Get-Content $halt -Raw) }
    Write-Host "HALTED"
    Write-Summary
    exit 0
  }

  $py = (Get-Command python).Source
  $npm = (Get-Command npm.cmd).Source
  $node = (Get-Command node).Source
  $openclawJs = Join-Path $env:APPDATA "npm\node_modules\openclaw\dist\index.js"
  if (-not (Test-Path $openclawJs)) { throw "missing $openclawJs" }

  $swAll = [Diagnostics.Stopwatch]::StartNew()
  python $statePy start night-forge "Night Forge cycle" forge --source forge | Out-Host

  Write-Host "PHASE 1 sensor"
  $statusJson = Invoke-TimeoutProc -FileName $py -ArgList @((Join-Path $ws "helper_system_status.py"), "--json") -Seconds 30 -Cwd $ws -Label "sensor"
  Write-Host $statusJson
  $st = $statusJson | ConvertFrom-Json
  if ($st.ok -ne $true) { throw "system-status not ok" }
  if ([int]$st.ram_load_percent -ge 85) { throw "RESOURCE_GUARD ram $($st.ram_load_percent)%" }
  if ([double]$st.disk_free_gb -lt 20) { throw "RESOURCE_GUARD disk $($st.disk_free_gb)GB" }
  if ($st.ollama_status -ne "running") { throw "RESOURCE_GUARD ollama $($st.ollama_status)" }
  if ($st.gateway_status -ne "open") { throw "RESOURCE_GUARD gateway $($st.gateway_status)" }
  $status = "PASS"
  Rec @{ step = "system-status"; result = "PASS"; exit_code = $script:LastProcExit }
  Write-Latest @{ overall = "RUNNING"; phase = "sensor"; system_status = $status; qwen_pass = 0 }

  Write-Host "PHASE 2 sanitize"
  $sanOut = Invoke-TimeoutProc -FileName $py -ArgList @((Join-Path $ws "helper_sanitize_check.py")) -Seconds 30 -Cwd $ws -Label "sanitize"
  Write-Host $sanOut
  if ($script:LastProcExit -ne 0) { throw "sanitizer exit $($script:LastProcExit)" }
  $san = "PASS"
  Rec @{ step = "sanitize"; result = "PASS"; exit_code = 0 }

  Write-Host "PHASE 3 plugin"
  $plugOut = Invoke-TimeoutProc -FileName $npm -ArgList @("test") -Seconds 120 -Cwd $freeze -Label "plugin"
  Write-Host $plugOut
  $plug = "PASS"
  Rec @{ step = "plugin-test"; result = "PASS"; exit_code = $script:LastProcExit }

  Write-Host "PHASE 4 qwen-qa"
  $tests = @(
    @{ id = "PONG"; q = "Reply with only the word PONG."; e = '(?i)^pong\.?$' },
    @{ id = "math"; q = "What is 2+2? Reply with only the number."; e = '^4$' },
    @{ id = "name"; q = "What is your name? One word."; e = '(?i)kevin' },
    @{ id = "ok"; q = "Do not emit JSON. Reply with only the word OK."; e = '(?i)^ok\.?$' }
  )
  foreach ($t in $tests) {
    Write-Host "PHASE 4 qwen-$($t.id) START"
    [void](Invoke-TimeoutProc -FileName $node -ArgList @($openclawJs, "agent", "--agent", "kevin-lab-qwen", "--message", "/new") -Seconds 90 -Cwd $ws -Label "qwen-$($t.id)-new")
    $raw = Invoke-TimeoutProc -FileName $node -ArgList @($openclawJs, "agent", "--agent", "kevin-lab-qwen", "--json", "--message", $t.q) -Seconds 180 -Cwd $ws -Label "qwen-$($t.id)"
    $i = $raw.IndexOf("{")
    if ($i -lt 0) { $qFail++; $qNr++; Rec @{ step = "qwen"; id = $t.id; result = "FAIL"; error = "no-json" }; Write-Latest @{ overall = "FAIL"; qwen_pass = $qPass; qwen_fail = $qFail; last = $t.id }; throw "FAIL qwen-$($t.id) JSON missing" }
    $o = $raw.Substring($i) | ConvertFrom-Json
    $text = $o.result.meta.finalAssistantVisibleText
    if (-not $text) { $text = $o.result.payloads[0].text }
    $calls = 0
    if ($o.result.meta.toolSummary.calls) { $calls = [int]$o.result.meta.toolSummary.calls }
    $qTools += $calls
    $ms = $o.result.meta.durationMs
    if ($text -eq "NO_REPLY" -or -not $text) {
      $qNr++; $qFail++
      Rec @{ step = "qwen"; id = $t.id; result = "FAIL"; noreply = $true; tools = $calls }
      Write-Latest @{ overall = "FAIL"; qwen_pass = $qPass; qwen_fail = $qFail; qwen_noreply = $qNr; last = $t.id }
      throw "FAIL qwen-$($t.id) NO_REPLY"
    }
    if ($calls -ne 0) { $qFail++; throw "FAIL qwen-$($t.id) UNEXPECTED_TOOLS $calls" }
    if ($text -notmatch $t.e) { $qFail++; throw "FAIL qwen-$($t.id) mismatch [$text]" }
    $qPass++
    Rec @{ step = "qwen"; id = $t.id; result = "PASS"; text = "$text"; ms = $ms; tools = $calls }
    Write-Latest @{
      overall = "RUNNING"
      phase = "qwen"
      system_status = $status
      sanitize = $san
      plugin_test = $plug
      qwen_pass = $qPass
      qwen_fail = $qFail
      qwen_noreply = $qNr
      qwen_tools = $qTools
      last = $t.id
    }
    Write-Host "PHASE 4 qwen-$($t.id) PASS [$text] ${ms}ms"
  }

  $swAll.Stop()
  Rec @{ step = "qwen-qa"; result = "PASS"; pass = $qPass; fail = $qFail; noreply = $qNr; tools = $qTools }
  Rec @{ step = "cycle"; result = "PASS"; ms = $swAll.ElapsedMilliseconds }
  Write-Latest @{
    overall = "PASS"
    duration_ms = $swAll.ElapsedMilliseconds
    system_status = $status
    sanitize = $san
    plugin_test = $plug
    qwen_pass = $qPass
    qwen_fail = $qFail
    qwen_noreply = $qNr
    qwen_tools = $qTools
    ram_load_percent = $st.ram_load_percent
  }
  python $statePy finish night-forge PASS "Night Forge PASS $($swAll.ElapsedMilliseconds)ms" --source forge | Out-Host
  Write-Summary
  Write-Host "NIGHT FORGE PASS"
  exit 0
} catch {
  $msg = "$_"
  $kind = "FAIL"
  if ($msg -match "TIMEOUT") { $kind = "infra_timeout" }
  Rec @{ step = "cycle"; result = "FAIL"; fail_kind = $kind; error = $msg }
  Write-Latest @{
    overall = "FAIL"
    fail_kind = $kind
    error = $msg
    system_status = $status
    sanitize = $san
    plugin_test = $plug
    qwen_pass = $qPass
    qwen_fail = $qFail
    qwen_noreply = $qNr
  }
  python $statePy finish night-forge FAIL $msg --source forge | Out-Host
  Write-Summary
  Write-Host "NIGHT FORGE STOP: $kind $msg"
  exit 1
} finally {
  if ($owned) { try { $mutex.ReleaseMutex() } catch {} }
  $mutex.Dispose()
}
