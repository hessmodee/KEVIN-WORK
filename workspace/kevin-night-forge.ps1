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

function Invoke-TimeoutProc([string]$fileName, [string]$arguments, [int]$sec, [string]$cwd) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $fileName
  $psi.Arguments = $arguments
  if ($cwd) { $psi.WorkingDirectory = $cwd }
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $true
  $p = New-Object System.Diagnostics.Process
  $script:LastProcExit = -1
  $p.StartInfo = $psi
  [void]$p.Start()
  if (-not $p.WaitForExit($sec * 1000)) {
    try { $p.Kill() } catch {}
    throw "TIMEOUT ${sec}s $fileName"
  }
  $script:LastProcExit = $p.ExitCode
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  if ($p.ExitCode -ne 0) { throw "exit $($p.ExitCode) $err $out" }
  return ($out + $err)
}

function Write-Summary {
  $rows = @()
  if (Test-Path $log) {
    Get-Content $log | ForEach-Object {
      if ($_.Trim()) {
        try { $rows += ($_ | ConvertFrom-Json) } catch {}
      }
    }
  }
  $cycles = @($rows | Where-Object { $_.step -eq "cycle" })
  $pass = @($cycles | Where-Object { $_.result -eq "PASS" }).Count
  $fail = @($cycles | Where-Object { $_.result -eq "FAIL" }).Count
  $q = @($rows | Where-Object { $_.step -eq "qwen-qa" })
  $qp = 0; $qf = 0; $nr = 0
  foreach ($item in $q) {
    if ($item.pass) { $qp += [int]$item.pass }
    if ($item.fail) { $qf += [int]$item.fail }
    if ($item.noreply) { $nr += [int]$item.noreply }
  }
  $md = @(
    "# Night Forge summary",
    "- cycles PASS/FAIL: $pass / $fail",
    "- plugin tests: frozen kevin-core-v0.1.0-green",
    "- Qwen Chat QA pass/fail/NO_REPLY: $qp / $qf / $nr",
    "- halt: $(if (Test-Path $halt) { Get-Content $halt -Raw } else { 'none' })",
    "- latest: $latest"
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

  $cycleFails = 0
  if (Test-Path $log) {
    $tail = @(Get-Content $log | Where-Object { $_ -match '"step":"cycle"' } | Select-Object -Last 3)
    foreach ($line in $tail) {
      try {
        $o = $line | ConvertFrom-Json
        if ($o.result -eq "FAIL") { $cycleFails++ } else { $cycleFails = 0 }
      } catch {}
    }
  }
  if ($cycleFails -ge 3) {
    [IO.File]::WriteAllText($halt, "three consecutive cycle failures", $utf8)
    Rec @{ step = "cycle"; result = "HALTED"; error = "three consecutive failures" }
    Write-Latest @{ overall = "HALTED"; reason = "three consecutive failures" }
    Write-Host "HALTED three consecutive failures"
    Write-Summary
    exit 0
  }

  $py = (Get-Command python).Source
  $npm = (Get-Command npm.cmd).Source
  $pwsh = (Get-Command powershell.exe).Source
  $swAll = [Diagnostics.Stopwatch]::StartNew()
  $status = "PASS"; $san = "PASS"; $plug = "PASS"; $qPass = 0; $qFail = 0; $qNr = 0; $qTools = 0
  $overall = "PASS"

  python $statePy start night-forge "Night Forge cycle" forge --source forge | Out-Host

  $statusJson = Invoke-TimeoutProc $py "`"$ws\helper_system_status.py`" --json" 30 $ws
  Write-Host $statusJson
  Rec @{ step = "system-status"; result = "PASS"; ms = 0 }
  $st = $statusJson | ConvertFrom-Json
  if ($st.ok -ne $true) { throw "system-status not ok" }
  if ([int]$st.ram_load_percent -ge 85) { throw "RESOURCE_GUARD ram $($st.ram_load_percent)%" }
  if ([double]$st.disk_free_gb -lt 20) { throw "RESOURCE_GUARD disk $($st.disk_free_gb)GB" }
  if ($st.ollama_status -ne "running") { throw "RESOURCE_GUARD ollama $($st.ollama_status)" }
  if ($st.gateway_status -ne "open") { throw "RESOURCE_GUARD gateway $($st.gateway_status)" }

  $sanOut = Invoke-TimeoutProc $py "`"$ws\helper_sanitize_check.py`"" 30 $ws
  Write-Host $sanOut
  if ($sanOut -notmatch "fails: 0") { $san = "FAIL"; throw "sanitizer $sanOut" }

  $plugOut = Invoke-TimeoutProc $npm "test" 120 $freeze
  Write-Host $plugOut
  Rec @{ step = "plugin-test"; result = "PASS"; exit_code = $script:LastProcExit; ms = 0 }

  $tests = @(
    @{ q = "Reply with only the word PONG."; e = '(?i)^pong\.?$' },
    @{ q = "What is 2+2? Reply with only the number."; e = '^4$' },
    @{ q = "What is your name? One word."; e = '(?i)kevin' },
    @{ q = "Do not emit JSON. Reply with only the word OK."; e = '(?i)^ok\.?$' }
  )
  foreach ($t in $tests) {
    [void](Invoke-TimeoutProc $pwsh "-NoProfile -ExecutionPolicy Bypass -Command `"openclaw agent --agent kevin-lab-qwen --message '/new'`"" 45 $ws)
    $raw = Invoke-TimeoutProc $pwsh "-NoProfile -ExecutionPolicy Bypass -Command `"openclaw agent --agent kevin-lab-qwen --json --message '$($t.q)'`"" 90 $ws
    $i = $raw.IndexOf("{")
    if ($i -lt 0) { $qFail++; $qNr++; throw "Qwen JSON missing" }
    $o = $raw.Substring($i) | ConvertFrom-Json
    $text = $o.result.meta.finalAssistantVisibleText
    if (-not $text) { $text = $o.result.payloads[0].text }
    $calls = 0
    if ($o.result.meta.toolSummary.calls) { $calls = [int]$o.result.meta.toolSummary.calls }
    $qTools += $calls
    if ($text -eq "NO_REPLY" -or -not $text) { $qNr++; $qFail++; throw "NO_REPLY" }
    if ($calls -ne 0) { throw "UNEXPECTED_TOOLS $calls" }
    if ($text -notmatch $t.e) { $qFail++; throw "Qwen mismatch [$text]" }
    $qPass++
    Write-Host "QWEN PASS [$text] $($o.result.meta.durationMs)ms"
  }
  Rec @{ step = "qwen-qa"; result = "PASS"; pass = $qPass; fail = $qFail; noreply = $qNr; tools = $qTools }

  $swAll.Stop()
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
  Rec @{ step = "cycle"; result = "FAIL"; error = "$_" }
  Write-Latest @{ overall = "FAIL"; error = "$_"; qwen_pass = $qPass; qwen_fail = $qFail; qwen_noreply = $qNr }
  python $statePy finish night-forge FAIL "$_" --source forge | Out-Host
  Write-Summary
  Write-Host "NIGHT FORGE STOP: $_"
  exit 1
} finally {
  if ($owned) { try { $mutex.ReleaseMutex() } catch {} }
  $mutex.Dispose()
}
