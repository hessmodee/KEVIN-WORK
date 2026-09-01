param(
    [switch]$SelfTest,
    [switch]$CheckOnly
)
# Kevin Supervisor v1.8.4 Governed Autonomy Continuation Controller - Native OpenClaw Runtime
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)
$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Reports = Join-Path $Workspace 'reports'
$Runtime = Join-Path $Reports 'autonomy-runtime'
$Selector = Join-Path $Workspace 'ControlPlane\kevin-work-selector-v1.1.py'
$StatePath = Join-Path $Runtime 'continuation-state.json'
$SelectionPath = Join-Path $Reports 'autonomy-selection-current.json'
$LatestPath = Join-Path $Reports 'autonomy-continuation-latest.json'
$ExpectedSelectorSha = '9DF1F770E8855232758AC275FA2D3A82C6D484099B5B2D2185A999ACDE185DE4'
$Base = 'https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/'
$MinRepeatMinutes = 15
$FailureCooldownMinutes = 60
$MaxSameFingerprintTurns = 3

foreach ($d in @($Reports, $Runtime, (Split-Path -Parent $Selector))) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

function Write-Utf8Atomic([string]$Path, [string]$Text) {
    $tmp = $Path + '.tmp-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp, $Text, $Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Write-JsonAtomic([string]$Path, [object]$Object) {
    Write-Utf8Atomic $Path ($Object | ConvertTo-Json -Depth 30)
}

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-TextSha([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $Utf8.GetBytes([string]$Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToUpperInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Safe-Text([object]$Value, [int]$Max = 220) {
    $s = [string]$Value
    if ($env:USERPROFILE) {
        $s = [regex]::Replace($s, [regex]::Escape([string]$env:USERPROFILE), '~', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    foreach ($p in @(
        '(?i)\bghp_[A-Za-z0-9_]{8,}\b',
        '(?i)\bgithub_pat_[A-Za-z0-9_]{8,}\b',
        '(?i)\bsk-[A-Za-z0-9_-]{8,}\b',
        '(?i)(Authorization\s*:\s*Bearer\s+)[^\s''";,]+'
    )) {
        $s = [regex]::Replace($s, $p, '[REDACTED]')
    }
    $s = $s.Replace("`r", ' ').Replace("`n", ' ')
    if ($s.Length -gt $Max) { $s = $s.Substring(0, $Max) }
    return $s
}

function Read-State {
    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) {
        return [pscustomobject]@{ same_fingerprint_turns = 0 }
    }
    try {
        return Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{ same_fingerprint_turns = 0 }
    }
}

function Save-Latest([string]$Status, [hashtable]$Extra = $null) {
    $o = [ordered]@{
        schema = 1
        kind = 'kevin-autonomy-continuation-state'
        version = '1.8.4'
        at = (Get-Date).ToString('o')
        status = $Status
        authority_effect = 'NONE_CONTROLLER_ONLY'
        model_call_counts_as_accomplishment = $false
    }
    if ($Extra) {
        foreach ($k in $Extra.Keys) { $o[$k] = $Extra[$k] }
    }
    Write-JsonAtomic $LatestPath $o
    return $o
}

function ConvertTo-Win32CommandLineArg([AllowEmptyString()][string]$Value) {
    if ($null -eq $Value -or $Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $sb = New-Object Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0
    for ($i = 0; $i -lt $Value.Length; $i++) {
        $ch = $Value[$i]
        if ($ch -eq '\') { $slashes++; continue }
        if ($ch -eq '"') {
            if ($slashes -gt 0) { [void]$sb.Append(('\' * ($slashes * 2))) }
            [void]$sb.Append('\"')
            $slashes = 0
            continue
        }
        if ($slashes -gt 0) { [void]$sb.Append(('\' * $slashes)); $slashes = 0 }
        [void]$sb.Append($ch)
    }
    if ($slashes -gt 0) { [void]$sb.Append(('\' * ($slashes * 2))) }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function Invoke-FixedNativeBounded([string]$Executable, [string[]]$Argv, [int]$TimeoutSeconds) {
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $Executable
    $psi.Arguments = (($Argv | ForEach-Object { ConvertTo-Win32CommandLineArg ([string]$_) }) -join ' ')
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = New-Object Diagnostics.Process
    $p.StartInfo = $psi
    if (-not $p.Start()) { throw 'fixed native process start failed' }
    $ot = $p.StandardOutput.ReadToEndAsync()
    $et = $p.StandardError.ReadToEndAsync()
    $timed = $false
    if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
        $timed = $true
        try { $p.Kill() } catch {}
        $p.WaitForExit()
    }
    $stdout = [string]$ot.Result
    $stderr = [string]$et.Result
    $code = if ($timed) { 124 } else { [int]$p.ExitCode }
    $p.Dispose()
    $combined = (($stdout + "`n" + $stderr).Trim())
    return [pscustomobject]@{ exit_code = $code; output = [string]$combined; timed_out = $timed }
}

function Get-FixedOpenClawRuntime {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command node -ErrorAction SilentlyContinue }
    if (-not $node) { throw 'node runtime unavailable' }
    if (-not $env:APPDATA) { throw 'APPDATA unavailable' }
    $cli = Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { throw 'OpenClaw native runtime unavailable' }
    return [pscustomobject]@{ node = $node.Source; cli = $cli }
}

function Invoke-OpenClaw([string[]]$Args) {
    $oldConfig = [Environment]::GetEnvironmentVariable('OPENCLAW_CONFIG_PATH', 'Process')
    $oldRoot = [Environment]::GetEnvironmentVariable('OPENCLAW_HOME', 'Process')
    try {
        Remove-Item Env:OPENCLAW_CONFIG_PATH -ErrorAction SilentlyContinue
        Remove-Item Env:OPENCLAW_HOME -ErrorAction SilentlyContinue
        $r = Get-FixedOpenClawRuntime
        return Invoke-FixedNativeBounded $r.node (@($r.cli) + @($Args)) 180
    }
    finally {
        if ($null -ne $oldConfig) { $env:OPENCLAW_CONFIG_PATH = $oldConfig } else { Remove-Item Env:OPENCLAW_CONFIG_PATH -ErrorAction SilentlyContinue }
        if ($null -ne $oldRoot) { $env:OPENCLAW_HOME = $oldRoot } else { Remove-Item Env:OPENCLAW_HOME -ErrorAction SilentlyContinue }
    }
}

function Get-PythonExe {
    $c = Get-Command python -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $c = Get-Command py -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    throw 'python runtime unavailable'
}

function Get-ControlText([string]$Relative) {
    if ($Relative -notmatch '^(control-plane/autonomy/(standing-programs-v1|failure-families-v1)\.json|inbox/autonomy/(work-items|state)\.json)$') {
        throw 'control-plane fetch path rejected'
    }
    $url = $Base + $Relative
    $r = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 20
    if ([int]$r.StatusCode -ne 200) { throw 'control-plane fetch failed' }
    $t = [string]$r.Content
    try { $null = $t | ConvertFrom-Json }
    catch { throw 'control-plane JSON invalid' }
    return $t
}

function Invoke-Selector([hashtable]$Paths) {
    if ((Get-Sha $Selector) -ne $ExpectedSelectorSha) { throw 'selector exact hash mismatch' }
    $py = Get-PythonExe
    $args = @(
        $Selector,
        '--programs', $Paths.programs,
        '--items', $Paths.items,
        '--state', $Paths.state,
        '--failure-families', $Paths.failures,
        '--now', (Get-Date).ToUniversalTime().ToString('o')
    )
    if ([IO.Path]::GetFileName($py) -match '^py(\.exe)?$') { $args = @('-3') + $args }
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& $py @args 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $old
    }
    if ($code -ne 0) { throw ('selector failed: ' + (Safe-Text $out)) }
    try { return $out | ConvertFrom-Json }
    catch { throw 'selector output invalid JSON' }
}

function Get-ToolCallCount([object]$Object) {
    $script:KevinToolCallCount = 0
    function Visit-KevinNode([object]$Node) {
        if ($null -eq $Node) { return }
        if ($Node -is [Collections.IDictionary]) {
            foreach ($key in $Node.Keys) {
                $value = $Node[$key]
                if ([string]$key -match '(?i)^(toolCalls|tool_calls|toolUse|tool_use)$') {
                    if ($value -is [Collections.IEnumerable] -and -not ($value -is [string])) { $script:KevinToolCallCount += @($value).Count }
                    elseif ($value) { $script:KevinToolCallCount++ }
                }
                Visit-KevinNode $value
            }
            return
        }
        if ($Node -is [Collections.IEnumerable] -and -not ($Node -is [string])) {
            foreach ($value in $Node) { Visit-KevinNode $value }
            return
        }
        foreach ($property in $Node.PSObject.Properties) {
            $value = $property.Value
            if ($property.Name -match '(?i)^(toolCalls|tool_calls|toolUse|tool_use)$') {
                if ($value -is [Collections.IEnumerable] -and -not ($value -is [string])) { $script:KevinToolCallCount += @($value).Count }
                elseif ($value) { $script:KevinToolCallCount++ }
            }
            Visit-KevinNode $value
        }
    }
    Visit-KevinNode $Object
    return [int]$script:KevinToolCallCount
}

function Invoke-Cycle {
    $mutex = New-Object Threading.Mutex($false, 'Global\KevinSupervisor')
    $owned = $false
    $tmp = ''
    try {
        try { $owned = $mutex.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $owned = $true }
        if (-not $owned) {
            Save-Latest 'SKIP_MUTEX_BUSY' | Out-Null
            return
        }

        if ((Get-Sha $Selector) -ne $ExpectedSelectorSha) { throw 'selector not installed at qualified identity' }
        $tmp = Join-Path $Runtime ('cycle-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Force -Path $tmp | Out-Null

        $specs = [ordered]@{
            programs = 'control-plane/autonomy/standing-programs-v1.json'
            items = 'inbox/autonomy/work-items.json'
            state = 'inbox/autonomy/state.json'
            failures = 'control-plane/autonomy/failure-families-v1.json'
        }
        $paths = @{}
        $fingerParts = @()
        foreach ($k in $specs.Keys) {
            $t = Get-ControlText $specs[$k]
            $p = Join-Path $tmp ($k + '.json')
            [IO.File]::WriteAllText($p, $t, $Utf8)
            $paths[$k] = $p
            $fingerParts += ($k + ':' + (Get-TextSha $t))
        }

        $sel = Invoke-Selector $paths
        if ([string]$sel.authority_effect -ne 'NONE_SELECTION_ONLY') { throw 'selector authority contract mismatch' }
        if ($null -eq $sel.selection) {
            Save-Latest 'IDLE_NO_ELIGIBLE_DEMAND' @{ eligible_count = [int]$sel.eligible_count; blocked_count = @($sel.blocked).Count } | Out-Null
            return
        }

        $id = [string]$sel.selection.id
        if ($id -notmatch '^[a-z0-9][a-z0-9._-]{2,96}$') { throw 'selected work id invalid' }
        $finger = Get-TextSha (($fingerParts + ('selection:' + $id)) -join "`n")
        Write-JsonAtomic $SelectionPath ([ordered]@{
            schema = 1
            kind = 'kevin-autonomy-selection'
            selected_at = (Get-Date).ToString('o')
            id = $id
            program = [string]$sel.selection.program
            lane = [string]$sel.selection.lane
            score = [double]$sel.selection.score
            fingerprint = $finger
            authority_effect = 'NONE_SELECTION_ONLY'
            source = 'deterministic kevin-work-selector-v1.1'
        })

        $st = Read-State
        $now = Get-Date
        $lastAt = [datetime]::MinValue
        if ($st.PSObject.Properties.Name -contains 'last_turn_at' -and $st.last_turn_at) {
            try { $lastAt = [datetime]$st.last_turn_at } catch { $lastAt = [datetime]::MinValue }
        }
        $lastFingerprint = if ($st.PSObject.Properties.Name -contains 'last_fingerprint') { [string]$st.last_fingerprint } else { '' }
        $same = ($lastFingerprint -eq $finger)
        $turns = if ($same) { [int]$st.same_fingerprint_turns } else { 0 }
        $cool = [datetime]::MinValue
        if ($st.PSObject.Properties.Name -contains 'cooldown_until' -and $st.cooldown_until) {
            try { $cool = [datetime]$st.cooldown_until } catch { $cool = [datetime]::MinValue }
        }

        if ($cool -gt $now) {
            Save-Latest 'COOLDOWN_UNCHANGED_WORK' @{ selected_id = $id; fingerprint = $finger; cooldown_until = $cool.ToString('o'); same_fingerprint_turns = $turns } | Out-Null
            return
        }
        if ($same -and $lastAt -ne [datetime]::MinValue -and ($now - $lastAt).TotalMinutes -lt $MinRepeatMinutes) {
            Save-Latest 'WAIT_UNCHANGED_WORK' @{ selected_id = $id; fingerprint = $finger; minutes_since_turn = [math]::Round(($now - $lastAt).TotalMinutes, 1); same_fingerprint_turns = $turns } | Out-Null
            return
        }
        if ($turns -ge $MaxSameFingerprintTurns) {
            $until = $now.AddMinutes($FailureCooldownMinutes)
            Write-JsonAtomic $StatePath ([ordered]@{ schema = 1; last_selected_id = $id; last_fingerprint = $finger; last_turn_at = $lastAt.ToString('o'); same_fingerprint_turns = $turns; cooldown_until = $until.ToString('o'); reason = 'UNCHANGED_WORK_AFTER_BOUNDED_TURNS' })
            Save-Latest 'COOLDOWN_BUDGET_EXHAUSTED' @{ selected_id = $id; fingerprint = $finger; cooldown_until = $until.ToString('o'); same_fingerprint_turns = $turns } | Out-Null
            return
        }
        if ($CheckOnly) {
            Save-Latest 'CHECK_ONLY_ELIGIBLE' @{ selected_id = $id; fingerprint = $finger; eligible_count = [int]$sel.eligible_count } | Out-Null
            return
        }

        $gw = $null
        for ($probeAttempt = 1; $probeAttempt -le 3; $probeAttempt++) {
            $gw = Invoke-OpenClaw @('gateway', 'status', '--require-rpc', '--json')
            if ($gw.exit_code -eq 0) { break }
            if ($probeAttempt -lt 3) { Start-Sleep -Milliseconds (500 * $probeAttempt) }
        }
        if ($null -eq $gw -or $gw.exit_code -ne 0) { throw 'gateway RPC probe failed after bounded retries' }
        $mainCheck = Invoke-OpenClaw @('skills', 'check', '--agent', 'main', '--json')
        if ($mainCheck.exit_code -ne 0) { throw 'fixed main agent preflight failed' }
        $message = 'KEVIN_AUTONOMY_CONTINUATION_V1. The deterministic governed selector selected work item ID ' + $id + '. Read your Standing Orders and local reports/autonomy-selection-current.json. Independently refresh evidence and confirm this item is still eligible and UNSATISFIED before any side effect. If stale, satisfied, blocked, cooled, prohibited, or missing a proven typed GREEN capability, do not improvise or widen authority; record the exact blocker through normal Kevin evidence. Otherwise execute the highest-value safe next step through proven typed GREEN mechanisms, semantically verify the real outcome, record evidence and reusable learning, then leave durable next state so a later cycle can continue. Do not manufacture Forge/design demand. Do not use arbitrary shell/code transport, self-grant permissions, spend money, perform live trades, expose credentials, or send unauthorized third-party/public owner-representing communications. A model response, heartbeat, publish commit, cycle, candidate, or hash alone is not an accomplishment.'
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-OpenClaw @('agent', '--agent', 'main', '--json', '--message', $message)
        $sw.Stop()
        if ($r.exit_code -ne 0) { throw ('main-agent turn failed: ' + (Safe-Text $r.output)) }
        try { $agent = $r.output | ConvertFrom-Json }
        catch { throw 'main-agent output invalid JSON' }
        $toolCalls = Get-ToolCallCount $agent
        $turns++
        Write-JsonAtomic $StatePath ([ordered]@{
            schema = 1
            last_selected_id = $id
            last_fingerprint = $finger
            last_turn_at = $now.ToString('o')
            same_fingerprint_turns = $turns
            cooldown_until = $null
            last_agent_output_sha256 = (Get-TextSha $r.output)
            last_tool_calls = $toolCalls
        })
        Save-Latest 'AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF' @{
            selected_id = $id
            fingerprint = $finger
            eligible_count = [int]$sel.eligible_count
            duration_ms = [int]$sw.ElapsedMilliseconds
            tool_calls = $toolCalls
            same_fingerprint_turns = $turns
            truth_boundary = 'A real main-agent turn occurred. This does not by itself prove the selected owner outcome completed.'
        } | Out-Null
    }
    catch {
        Save-Latest 'CONTROLLER_ERROR' @{ failure = (Safe-Text $_.Exception.Message) } | Out-Null
        throw
    }
    finally {
        if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        if ($owned) { try { $mutex.ReleaseMutex() } catch {} }
        $mutex.Dispose()
    }
}

if ($SelfTest) {
    if ($ExpectedSelectorSha -notmatch '^[A-F0-9]{64}$') { throw 'selector hash invariant failed' }
    foreach ($p in @(
        'control-plane/autonomy/standing-programs-v1.json',
        'control-plane/autonomy/failure-families-v1.json',
        'inbox/autonomy/work-items.json',
        'inbox/autonomy/state.json'
    )) {
        if ($p -notmatch '^(control-plane/autonomy/(standing-programs-v1|failure-families-v1)\.json|inbox/autonomy/(work-items|state)\.json)$') { throw 'fixed fetch path invariant failed' }
    }
    $bad = '../../evil'
    $blocked = $false
    try { $null = Get-ControlText $bad } catch { $blocked = $true }
    if (-not $blocked) { throw 'arbitrary control-plane path accepted' }
    if ($MinRepeatMinutes -lt 10 -or $MaxSameFingerprintTurns -gt 3 -or $FailureCooldownMinutes -lt 60) { throw 'anti-spin budget weakened' }
    Write-Host 'KEVIN SUPERVISOR v1.8.4 SELFTEST PASS selector_first=true gateway_agent=fixed-main gateway_rpc_only=true gateway_probe_retries=3 main_preflight=true no_forge_dispatch=true anti_spin=true openclaw_native_node=true shell_shim_bypassed=true native_timeout=180s arbitrary_shell=false authority_expansion=false'
    exit 0
}

Invoke-Cycle
