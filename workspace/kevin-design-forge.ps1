$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding $false

$root = Join-Path $env:USERPROFILE ".openclaw"
$ws = Join-Path $root "workspace"
$reports = Join-Path $ws "reports"
$lab = Join-Path $ws "forge-designs"
$stateFile = Join-Path $lab "design-forge-state.json"
$errorFile = Join-Path $lab "design-forge-last-error.txt"
$statePy = Join-Path $ws "helper_kevin_state.py"

New-Item -ItemType Directory -Force -Path $lab | Out-Null

function Format-WinArgs([string[]]$ArgList) {
  ($ArgList | ForEach-Object {
    $a = [string]$_
    if ($a -match '[\s"]') { '"' + ($a -replace '"','\"') + '"' } else { $a }
  }) -join ' '
}

function Finish-State([string]$result, [string]$summary) {
  if (Test-Path $statePy) {
    try {
      & python $statePy finish design-forge $result $summary --source forge | Out-Null
    } catch {}
  }
}

try {
  Write-Host "----------------------------------------------"
  Write-Host " KEVIN DESIGN FORGE V3"
  Write-Host "----------------------------------------------"

  Remove-Item Env:OPENCLAW_PROFILE -ErrorAction SilentlyContinue
  Remove-Item Env:OPENCLAW_STATE_DIR -ErrorAction SilentlyContinue
  Remove-Item Env:OPENCLAW_CONFIG_PATH -ErrorAction SilentlyContinue
  Remove-Item Env:OPENCLAW_GATEWAY_PORT -ErrorAction SilentlyContinue
  Remove-Item Env:OPENCLAW_GATEWAY_TOKEN -ErrorAction SilentlyContinue

  $missions = @(
    @{ id = "reader-weather"; goal = "Design a candidate for a second read-only Reader tool named kevin_weather. Use deterministic host-side collection, a narrow typed schema, sanitizer and failure tests, and preserve kevin_system_status. No model-side shell, filesystem mutation, browser, sessions, or arbitrary networking." },
    @{ id = "reader-board"; goal = "Design a candidate read-only kevin_board tool that returns a compact sanitized Kevin runtime/build summary. Include deterministic collection, explicit schema, timeout/crash/malformed-data tests, and privacy tests." },
    @{ id = "reader-self-check"; goal = "Design a candidate read-only kevin_self_check tool using deterministic host-side collection, an explicit small schema, fail-closed behavior, and timeout/crash/malformed/private-field tests." },
    @{ id = "knowledge"; goal = "Design Kevin Knowledge v0.1 for curated local retrieval only. Define ingestion allowlists, chunk/evidence metadata, stale-index detection, irrelevant-query behavior, corrupt-document handling, and prompt-injection tests. Do not allow autonomous canonical-memory rewriting." },
    @{ id = "operator"; goal = "Design Kevin Operator v0.1 as narrow typed actions, not arbitrary shell. Cover append-approved-note, create candidate-workspace file, allowlisted move/rename, read-only git inspection, and restart one explicitly allowlisted Kevin component. Define validation, roots, evidence, timeout, rollback, and failure behavior." },
    @{ id = "forge-v4"; goal = "Design the next Kevin Forge improvement: candidate-vs-control scoring, infrastructure-failure classification, bounded retries, regression gates, and promotion evidence. Never allow automatic production promotion or permission changes." }
  )

  $index = 0
  $iteration = 1
  if (Test-Path $stateFile) {
    try {
      $old = Get-Content $stateFile -Raw | ConvertFrom-Json
      $index = [int]$old.next_index
      if ($old.iteration) { $iteration = [int]$old.iteration }
    } catch {
      $index = 0
      $iteration = 1
    }
  }

  if ($index -lt 0) { $index = 0 }
  $index = $index % $missions.Count
  $mission = $missions[$index]
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $sessionKey = "design-$stamp-$($mission.id)"

  Write-Host ("Mission   = " + $mission.id)
  Write-Host ("Iteration = " + $iteration)

  if (Test-Path $statePy) {
    & python $statePy start design-forge ("Design Forge: " + $mission.id) forge --source forge | Out-Null
  }

  $prompt = @"
You are Kevin Forge, working inside an isolated candidate-design laboratory.

MISSION ID: $($mission.id)
ITERATION: $iteration
GOAL: $($mission.goal)

NON-NEGOTIABLE BOUNDARIES:
- Production Chat stays unchanged.
- Frozen Reader permissions/config stay unchanged.
- Never grant arbitrary exec, shell, browser, admin, sessions, or unrestricted filesystem access.
- Never change permissions, credentials, secrets, Telegram bindings, or production configuration.
- Never install, execute, or promote generated candidates.
- Candidate output is design/source material only.
- Prefer deterministic host-side code plus narrow typed model tools.
- Fail closed and preserve proven behavior.
- Include meaningful tests and promotion gates.
- Do not output usernames, tokens, secrets, ports, or host-specific absolute paths.
- Return at most 2 candidate files and keep total candidate content concise.

Return ONLY valid JSON with this exact top-level shape:
{
  "mission_id": "$($mission.id)",
  "iteration": $iteration,
  "title": "short title",
  "engineering_summary": "concise explanation",
  "candidate_files": [
    {"path":"relative/path","purpose":"purpose","content":"candidate content"}
  ],
  "tests": ["required test"],
  "risks": ["risk"],
  "promotion_gates": ["gate"],
  "next_experiment": "next experiment"
}
"@

  $promptFile = Join-Path $env:TEMP "kevin-design-$stamp.prompt.txt"
  $outFile = Join-Path $env:TEMP "kevin-design-$stamp.out.json"
  $errFile = Join-Path $env:TEMP "kevin-design-$stamp.err.txt"
  [IO.File]::WriteAllText($promptFile, $prompt, $utf8)

  if ((Get-Item $promptFile).Length -gt 12000) { throw "prompt exceeded 12KB safety cap" }

  $node = (Get-Command node).Source
  $openclawJs = Join-Path $env:APPDATA "npm\node_modules\openclaw\dist\index.js"
  if (-not (Test-Path $openclawJs)) { throw "OpenClaw runtime missing" }

  $args = @(
    $openclawJs,
    "agent",
    "--agent", "kevin-lab-qwen",
    "--session-key", $sessionKey,
    "--json",
    "--timeout", "180",
    "--message-file", $promptFile
  )

  Write-Host "Running proven 8K Qwen lane..."
  $p = Start-Process -FilePath $node -ArgumentList (Format-WinArgs $args) -WorkingDirectory $ws -WindowStyle Hidden -RedirectStandardOutput $outFile -RedirectStandardError $errFile -PassThru
  $null = $p.Handle

  if (-not $p.WaitForExit(210000)) {
    try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
    throw "Design Forge hard timeout"
  }

  $p.Refresh()
  $exitCode = $p.ExitCode
  if ($null -eq $exitCode) { $p.Refresh(); $exitCode = $p.ExitCode }
  if ($null -eq $exitCode) { throw "OpenClaw returned no exit code" }

  if ([int]$exitCode -ne 0) {
    $errText = if (Test-Path $errFile) { [IO.File]::ReadAllText($errFile) } else { "" }
    throw "OpenClaw exit=$exitCode $errText"
  }

  if (-not (Test-Path $outFile)) { throw "OpenClaw output file missing" }
  $raw = [IO.File]::ReadAllText($outFile)
  $outer = $raw | ConvertFrom-Json
  $visible = $outer.result.meta.finalAssistantVisibleText
  if (-not $visible) { $visible = $outer.result.payloads[0].text }
  if (-not $visible -or $visible -eq "NO_REPLY") { throw "model returned NO_REPLY" }

  $visible = $visible.Trim()
  if ($visible.StartsWith("```")) {
    $visible = $visible -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
    $visible = $visible.Trim()
  }

  $first = $visible.IndexOf("{")
  $last = $visible.LastIndexOf("}")
  if ($first -lt 0 -or $last -le $first) { throw "candidate response contained no JSON object" }
  $candidate = $visible.Substring($first, $last - $first + 1) | ConvertFrom-Json

  if ($candidate.mission_id -ne $mission.id) { throw "mission mismatch" }
  if ([int]$candidate.iteration -ne $iteration) { throw "iteration mismatch" }

  $files = @($candidate.candidate_files)
  if ($files.Count -gt 2) { throw "too many candidate files" }

  $run = Join-Path $lab "$stamp-$($mission.id)-i$iteration"
  $candidateRoot = Join-Path $run "candidate"
  New-Item -ItemType Directory -Force -Path $candidateRoot | Out-Null

  $chars = 0
  foreach ($f in $files) {
    $rel = ([string]$f.path).Replace("\","/")
    if (-not $rel) { throw "empty candidate path" }
    if ([IO.Path]::IsPathRooted($rel) -or $rel -match '(^|/)\.\.(/|$)' -or $rel -match '^[A-Za-z]:') { throw "unsafe candidate path" }
    if ($rel -notmatch '^[A-Za-z0-9._/-]+$') { throw "candidate path has forbidden characters" }

    $content = [string]$f.content
    $chars += $content.Length
    if ($chars -gt 16000) { throw "candidate content exceeded 16K cap" }

    $dest = Join-Path $candidateRoot $rel
    $parent = Split-Path $dest -Parent
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [IO.File]::WriteAllText($dest, $content, $utf8)
  }

  [IO.File]::WriteAllText((Join-Path $run "proposal.json"), ($candidate | ConvertTo-Json -Depth 12), $utf8)

  $next = ($index + 1) % $missions.Count
  $nextIteration = $iteration
  if ($next -eq 0) { $nextIteration++ }

  $state = [ordered]@{
    updated_at = (Get-Date).ToString("o")
    status = "PASS"
    last_mission = $mission.id
    last_iteration = $iteration
    last_candidate = $run
    next_index = $next
    iteration = $nextIteration
  }
  [IO.File]::WriteAllText($stateFile, ($state | ConvertTo-Json -Depth 5), $utf8)
  Remove-Item $errorFile -Force -ErrorAction SilentlyContinue

  Finish-State "PASS" ("Design Forge built candidate: " + $mission.id)

  Write-Host ""
  Write-Host "DESIGN FORGE PASS"
  Write-Host ("Mission = " + $mission.id)
  Write-Host ("Candidate files = " + $files.Count)
  Write-Host ("Saved = " + $run)
  Write-Host "Nothing was executed or promoted."
  exit 0
}
catch {
  $msg = "$_"
  [IO.File]::WriteAllText($errorFile, ((Get-Date).ToString("o") + "`n" + $msg + "`n"), $utf8)
  Finish-State "FAIL" $msg
  Write-Host ""
  Write-Host "DESIGN FORGE FAIL"
  Write-Host $msg
  Write-Host "Nothing was promoted."
  exit 1
}
