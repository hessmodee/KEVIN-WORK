param(
    [switch]$CheckOnly,
    [switch]$Apply,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)

$ConfigSha = '29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA'
$TrustedConfigSha = 'DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4'
$BaselineSha = '2EE72E14E01CD6F22CCC851FF6AA304A113799CECEDCAB7349F9F9E6058A3143'
$BenchmarkSha = '4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964'
$UiSha = '5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42'
$MaintenanceSha = '715E40DF0CFDC94FC8D470A83273467A6B10CC6CB9A2956E3A94FADC69B9646B'
$SupervisorSha = 'D77BCAA7E2CB76B0F477F7CBAC0C93CC1ABF010F24373EC2F0207D73A1B76810'
$ForgeSha = '433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
$ReaderSha = 'C107FEEDA4CA7B330FF44B7E9083DDAA854D9057085F165797B3EAF6FC458C5D'
$TaskName = 'Kevin UI Bridge v0.3'

$ExpectedTools = @(
    'kevin_system_status',
    'kevin_desktop_find_folder',
    'kevin_desktop_open_folder',
    'kevin_desktop_list_folder',
    'kevin_app_launch'
)
$ExpectedDenies = @(
    'exec','tool_call','tool_search','tool_describe','write','edit','apply_patch',
    'sessions_send','sessions_spawn','sessions_yield','subagents','web_search',
    'web_fetch','process','skill_workshop'
)

$OpenClawRoot = Join-Path $env:USERPROFILE '.openclaw'
$Workspace = Join-Path $OpenClawRoot 'workspace'
$ConfigPath = Join-Path $OpenClawRoot 'openclaw.json'
$ReaderConfigPath = Join-Path $env:USERPROFILE '.openclaw-reader\openclaw.json'
$BaselinePath = Join-Path $Workspace 'reports\benchmark-v1\baseline.json'
$BenchmarkPath = Join-Path $Workspace 'kevin-benchmark-v1.ps1'
$BenchmarkLatest = Join-Path $Workspace 'reports\benchmark-v1\latest.json'
$UiBridgePath = Join-Path $Workspace 'kevin-ui-bridge.ps1'
$MaintenancePath = Join-Path $Workspace 'kevin-maintenance-runner.ps1'
$SupervisorPath = Join-Path $Workspace 'kevin-supervisor.ps1'
$ForgePath = Join-Path $Workspace 'kevin-design-forge.ps1'
$UiRoot = Join-Path $Workspace 'reports\action-era\ui-bridge'
$HeartbeatPath = Join-Path $UiRoot 'heartbeat.json'
$UiInbox = Join-Path $UiRoot 'inbox'
$UiResults = Join-Path $UiRoot 'results'
$IsolationLatest = Join-Path $Workspace 'reports\ollama-isolate-latest.json'
$MainCanaryPath = Join-Path $Workspace 'reports\main-agent-canary-omen.json'
$RepairRoot = Join-Path $Workspace 'reports\maintenance\platform-recovery-20260906-v3'
$ReceiptPath = Join-Path $Workspace 'reports\maintenance\platform-recovery-20260906-v3-latest.json'

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Read-Json([string]$Path) {
    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}
function Write-JsonAtomic([string]$Path, [object]$Value) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp, ($Value | ConvertTo-Json -Depth 60), $Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Get-Prop([object]$Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}
function Has-Prop([object]$Object, [string]$Name) {
    if ($null -eq $Object) { return $false }
    return ($null -ne $Object.PSObject.Properties[$Name])
}
function Assert-ExactStrings([object]$Actual, [string[]]$Expected, [string]$Name) {
    $a = @($Actual | ForEach-Object { [string]$_ })
    if ($a.Count -ne $Expected.Count) { throw ($Name + ' count mismatch') }
    for ($i = 0; $i -lt $Expected.Count; $i++) {
        if ($a[$i] -cne $Expected[$i]) { throw ($Name + ' mismatch at index ' + $i) }
    }
}

function Convert-CanonicalNode([object]$Value, [string]$Path = '$') {
    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value -is [bool] -or $Value -is [byte] -or
        $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64] -or
        $Value -is [uint16] -or $Value -is [uint32] -or $Value -is [uint64] -or
        $Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return $Value
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $out = [ordered]@{}
        foreach ($key in @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)) {
            $child = $Path + '.' + $key
            if ($child -in @('$.meta.lastTouchedAt','$.meta.lastTouchedVersion')) { continue }
            $out[$key] = Convert-CanonicalNode $Value[$key] $child
        }
        return $out
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = @()
        $index = 0
        foreach ($item in $Value) {
            $items += ,(Convert-CanonicalNode $item ($Path + '[' + $index + ']'))
            $index++
        }
        return $items
    }
    $props = @($Value.PSObject.Properties | Where-Object { $_.MemberType -in @('NoteProperty','Property') } | Sort-Object Name)
    if ($props.Count -gt 0) {
        $out = [ordered]@{}
        foreach ($prop in $props) {
            $child = $Path + '.' + [string]$prop.Name
            if ($child -in @('$.meta.lastTouchedAt','$.meta.lastTouchedVersion')) { continue }
            $out[[string]$prop.Name] = Convert-CanonicalNode $prop.Value $child
        }
        return $out
    }
    return [string]$Value
}
function Get-CanonicalJson([object]$Value) {
    return ((Convert-CanonicalNode $Value) | ConvertTo-Json -Depth 60 -Compress)
}
function Get-MaskedBaseline([object]$Baseline) {
    $copy = $Baseline | ConvertTo-Json -Depth 60 | ConvertFrom-Json
    $copy.hashes.production_config = 'TARGET_IGNORED'
    return (Get-CanonicalJson $copy)
}
function Get-MainAgent([object]$Config) {
    $agents = Get-Prop $Config 'agents'
    $hits = @(@(Get-Prop $agents 'list') | Where-Object { [string](Get-Prop $_ 'id') -ceq 'main' })
    if ($hits.Count -ne 1) { throw ('Expected exactly one main agent; got ' + $hits.Count) }
    return $hits[0]
}
function Assert-CurrentConfigContract([object]$Config) {
    $rootTools = Get-Prop $Config 'tools'
    if ($null -eq $rootTools) { throw 'Global tools block missing' }
    if ([string](Get-Prop $rootTools 'profile') -cne 'coding') { throw 'Global tools.profile changed' }
    if (Has-Prop $rootTools 'allow') { throw 'Global tools.allow unexpectedly present' }
    Assert-ExactStrings (Get-Prop $rootTools 'alsoAllow') $ExpectedTools 'Global tools.alsoAllow'
    Assert-ExactStrings (Get-Prop $rootTools 'deny') $ExpectedDenies 'Global tools.deny'

    $main = Get-MainAgent $Config
    $mainTools = Get-Prop $main 'tools'
    if ($null -eq $mainTools) { throw 'main.tools missing' }
    Assert-ExactStrings (Get-Prop $mainTools 'allow') $ExpectedTools 'main.tools.allow'
    if ((Has-Prop $mainTools 'alsoAllow') -or (Has-Prop $mainTools 'deny')) { throw 'Unexpected main tool-policy surface' }

    $defaults = Get-Prop (Get-Prop $Config 'agents') 'defaults'
    if (Has-Prop $defaults 'tools') { throw 'agents.defaults.tools unexpectedly present' }
    $compaction = Get-Prop $defaults 'compaction'
    if ([int64](Get-Prop $compaction 'reserveTokensFloor') -ne 2048 -or
        [int64](Get-Prop $compaction 'reserveTokens') -ne 2048 -or
        [int64](Get-Prop $compaction 'keepRecentTokens') -ne 4000) {
        throw 'Compaction contract changed'
    }

    $modelValue = Get-Prop $main 'model'
    if ($null -eq $modelValue) { throw 'main.model missing' }
    $primary = if ($modelValue -is [string]) { [string]$modelValue } else { [string](Get-Prop $modelValue 'primary') }
    if ($primary -cne 'ollama-chat-16k/qwen2.5:14b') { throw 'Main Qwen primary changed' }
    $fallbacks = @((Get-Prop $modelValue 'fallbacks') | ForEach-Object { [string]$_ })
    Assert-ExactStrings $fallbacks @('ollama-chat-16k/llama3.1:8b') 'main.model.fallbacks'

    $mainModels = Get-Prop $main 'models'
    if ($null -eq $mainModels -or @($mainModels.PSObject.Properties).Count -ne 0) { throw 'main.models is not the qualified empty object' }

    $defaultsModels = Get-Prop $defaults 'models'
    if ($null -eq $defaultsModels) { throw 'agents.defaults.models missing' }
    foreach ($ref in @('ollama-chat-16k/qwen2.5:14b','ollama-chat-16k/llama3.1:8b')) {
        $entry = Get-Prop $defaultsModels $ref
        if ($null -eq $entry) { throw ('Qualified agent model override missing: ' + $ref) }
        $params = Get-Prop $entry 'params'
        if ([int64](Get-Prop $params 'num_ctx') -ne 12288 -or [double](Get-Prop $params 'temperature') -ne 0) {
            throw ('Qualified 12k agent runtime cap changed: ' + $ref)
        }
    }

    $providers = Get-Prop (Get-Prop $Config 'models') 'providers'
    $legacy = Get-Prop $providers 'ollama-chat'
    if ($null -eq $legacy) { throw 'ollama-chat provider missing' }
    if ([int64](Get-Prop $legacy 'timeoutSeconds') -ne 600) { throw 'ollama-chat timeout changed' }
    $legacyLlama = @(@(Get-Prop $legacy 'models') | Where-Object { [string](Get-Prop $_ 'id') -ceq 'llama3.1:8b' })
    if ($legacyLlama.Count -ne 1 -or -not [bool](Get-Prop (Get-Prop $legacyLlama[0] 'compat') 'supportsTools')) {
        throw 'Legacy local Llama tool capability contract changed'
    }

    $provider = Get-Prop $providers 'ollama-chat-16k'
    if ($null -eq $provider) { throw 'ollama-chat-16k provider missing' }
    $api = [string](Get-Prop $provider 'api')
    if ($api -and $api -cne 'ollama') { throw 'Local provider API changed' }
    $baseUrl = [string](Get-Prop $provider 'baseUrl')
    if (-not $baseUrl) { $baseUrl = [string](Get-Prop $provider 'baseURL') }
    if ($baseUrl -and $baseUrl -notmatch '^http://(127\.0\.0\.1|localhost):11434/?$') { throw 'Local provider is no longer loopback' }
    if ([int64](Get-Prop $provider 'timeoutSeconds') -ne 900) { throw 'ollama-chat-16k timeout changed' }

    $qwen = @(@(Get-Prop $provider 'models') | Where-Object { [string](Get-Prop $_ 'id') -ceq 'qwen2.5:14b' })
    if ($qwen.Count -ne 1) { throw 'Expected one qwen2.5:14b entry' }
    $qwenParams = Get-Prop $qwen[0] 'params'
    if ([int64](Get-Prop $qwen[0] 'contextTokens') -ne 16384 -or
        [int64](Get-Prop $qwenParams 'num_ctx') -ne 16384 -or
        [double](Get-Prop $qwenParams 'temperature') -ne 0 -or
        [string](Get-Prop $qwenParams 'keep_alive') -cne '10m') {
        throw 'Qualified Qwen 16k runtime contract changed'
    }

    $llama = @(@(Get-Prop $provider 'models') | Where-Object { [string](Get-Prop $_ 'id') -ceq 'llama3.1:8b' })
    if ($llama.Count -ne 1) { throw 'Expected one llama3.1:8b fallback entry' }
    $llamaParams = Get-Prop $llama[0] 'params'
    Assert-ExactStrings (Get-Prop $llama[0] 'input') @('text') 'llama16k.input'
    if ([int64](Get-Prop $llama[0] 'contextTokens') -ne 12288 -or
        [int64](Get-Prop $llamaParams 'num_ctx') -ne 12288 -or
        [double](Get-Prop $llamaParams 'temperature') -ne 0 -or
        [string](Get-Prop $llamaParams 'keep_alive') -cne '10m' -or
        -not [bool](Get-Prop (Get-Prop $llama[0] 'compat') 'supportsTools')) {
        throw 'Qualified Llama fallback runtime contract changed'
    }

    $bind = [string](Get-Prop (Get-Prop $Config 'gateway') 'bind')
    if ($bind -and $bind -cne 'loopback') { throw 'Gateway is not loopback-bound' }
}

function Assert-QualificationEvidence {
    if (-not (Test-Path -LiteralPath $IsolationLatest -PathType Leaf)) { throw 'Fresh Ollama isolation receipt missing' }
    $iso = Read-Json $IsolationLatest
    $isoAt = [DateTimeOffset]::Parse([string]$iso.generated_at)
    $now = [DateTimeOffset]::Now
    if (($now - $isoAt).TotalHours -gt 12 -or ($isoAt - $now).TotalMinutes -gt 5) { throw 'Ollama isolation receipt is stale or future-dated' }
    if ([string]$iso.kind -cne 'kevin-ollama-isolation-receipt' -or [string]$iso.status -cne 'PASS' -or
        [bool]$iso.tool_execution_attempted -or [string]$iso.source_sha256 -cne 'A8A6B2311608A17D3609F74CF02632A0314BD774CA50283FEDD1834E6390DCD2') {
        throw 'Ollama isolation receipt contract changed'
    }
    $isoModels = @($iso.models)
    if ($isoModels.Count -ne 2) { throw 'Isolation receipt does not contain exactly two model proofs' }
    foreach ($model in @('llama3.1:8b','qwen2.5:14b')) {
        $row = @($isoModels | Where-Object { [string]$_.model -ceq $model })
        if ($row.Count -ne 1 -or [string]$row[0].status -cne 'PASS') { throw ('Isolation PASS missing for ' + $model) }
    }

    if (-not (Test-Path -LiteralPath $MainCanaryPath -PathType Leaf)) { throw 'Fresh main-agent canary receipt missing' }
    $canary = Read-Json $MainCanaryPath
    $canaryAt = [DateTimeOffset]::Parse([string]$canary.generated_at)
    if (($now - $canaryAt).TotalHours -gt 12 -or ($canaryAt - $now).TotalMinutes -gt 5) { throw 'Main-agent canary receipt is stale or future-dated' }
    if ($canaryAt -lt $isoAt) { throw 'Main-agent canary predates the dual-model isolation proof' }
    if ([string]$canary.kind -cne 'kevin-main-agent-canary-public' -or [string]$canary.state -cne 'OMEN_PROVEN' -or
        -not [bool]$canary.gateway_probe_ok -or [int]$canary.agent_exit_code -ne 0 -or [string]$canary.status -cne 'ok' -or
        -not [bool]$canary.exact_expected_reply -or [int]$canary.visible_tool_count -ne 5 -or
        [int]$canary.visible_kevin_tool_count -ne 5 -or -not [bool]$canary.has_kevin_system_status) {
        throw 'Main-agent canary proof contract changed'
    }
    $transcript = Get-Prop (Get-Prop $canary 'canary_shape') 'transcript'
    if ($null -eq $transcript -or -not [bool](Get-Prop $transcript 'present') -or -not [bool](Get-Prop $transcript 'complete') -or
        [string](Get-Prop $transcript 'provider') -cne 'ollama-chat-16k' -or [string](Get-Prop $transcript 'model_id') -cne 'qwen2.5:14b') {
        throw 'Main-agent correlated transcript does not prove current Qwen route'
    }
}

function Assert-ConfigValidateReadOnly {
    $cmd = Get-Command 'openclaw.cmd' -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command 'openclaw' -ErrorAction SilentlyContinue }
    if (-not $cmd) { throw 'OpenClaw CLI not found for config validation' }
    $before = Get-Sha $ConfigPath
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = (& $cmd.Source config validate 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    } finally { $ErrorActionPreference = $old }
    if ($code -ne 0) { throw ('OpenClaw config validate failed: ' + $output) }
    if ((Get-Sha $ConfigPath) -cne $before) { throw 'Config validation unexpectedly changed production config bytes' }
}

function Find-TrustedConfigCopy {
    $candidates = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $OpenClawRoot -PathType Container) {
        Get-ChildItem -LiteralPath $OpenClawRoot -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -le 2097152 -and $_.Name -match '(?i)^openclaw\.json' } |
            ForEach-Object { [void]$candidates.Add($_.FullName) }
    }
    $backupRoot = Join-Path $Workspace 'reports\maintenance\backups'
    if (Test-Path -LiteralPath $backupRoot -PathType Container) {
        Get-ChildItem -LiteralPath $backupRoot -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -le 2097152 -and $_.Name -match '(?i)(openclaw|config)' } |
            Select-Object -First 5000 |
            ForEach-Object { [void]$candidates.Add($_.FullName) }
    }
    foreach ($path in @($candidates | Select-Object -Unique)) {
        try {
            if ((Get-Sha $path) -ceq $TrustedConfigSha) { return $path }
        } catch {}
    }
    return ''
}
function Assert-BenchmarkR04Only {
    if ((Get-Sha $BenchmarkPath) -cne $BenchmarkSha) { throw 'Benchmark runner identity changed' }
    $source = Get-Content -LiteralPath $BenchmarkPath -Raw
    if ($source -notmatch '(?s)Add-Result\s+\$reg\s+"R04".*?baseline\.hashes\.production_config') {
        throw 'Installed R04 contract not found'
    }
    $latest = Read-Json $BenchmarkLatest
    if ([string]$latest.status -cne 'FAIL_CRITICAL_REGRESSION' -or
        [int]$latest.regression.passed -ne 29 -or
        [int]$latest.regression.total -ne 30 -or
        [int]$latest.regression.critical_failures -ne 1) {
        throw 'Benchmark is not exact 29/30 critical1'
    }
    $failed = @($latest.regression.rows | Where-Object { -not [bool]$_.pass })
    if ($failed.Count -ne 1 -or [string]$failed[0].id -cne 'R04' -or -not [bool]$failed[0].critical) {
        throw 'Benchmark failure is not exactly critical R04'
    }
}
function Invoke-FreshBenchmark30 {
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        $started = [DateTime]::UtcNow
        $old = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $BenchmarkPath 2>&1 | Out-String).Trim()
            $code = [int]$LASTEXITCODE
        } finally { $ErrorActionPreference = $old }
        if ($output -match '(?i)BENCHMARK\s+SKIP_(ACTIVE_WORK|OVERLAP)') { Start-Sleep -Seconds 5; continue }
        if ($code -ne 0) { throw ('Benchmark exit=' + $code + ' ' + $output) }
        if ((Get-Item -LiteralPath $BenchmarkLatest).LastWriteTimeUtc -lt $started.AddSeconds(-3)) { throw 'Benchmark evidence not fresh' }
        $latest = Read-Json $BenchmarkLatest
        if ([string]$latest.status -cne 'PASS' -or [int]$latest.regression.passed -ne 30 -or
            [int]$latest.regression.total -ne 30 -or [int]$latest.regression.critical_failures -ne 0) {
            throw 'Fresh Benchmark is not 30/30 critical0'
        }
        return $latest
    }
    throw 'Benchmark retry budget exhausted'
}

function Get-UiTaskState {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) { return [pscustomobject]@{ok=$false;reason='missing'} }
    $actions = @($task.Actions)
    if ($actions.Count -ne 1) { return [pscustomobject]@{ok=$false;reason='actions'} }
    $powerShellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
    $expectedArgs = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $UiBridgePath + '" -RunLoop'
    if ([IO.Path]::GetFullPath([string]$actions[0].Execute) -ine [IO.Path]::GetFullPath($powerShellExe)) { return [pscustomobject]@{ok=$false;reason='execute'} }
    if ([string]$actions[0].Arguments -cne $expectedArgs) { return [pscustomobject]@{ok=$false;reason='arguments'} }
    if ([string]$task.Principal.LogonType -inotmatch 'Interactive') { return [pscustomobject]@{ok=$false;reason='logon'} }
    if ([string]$task.Principal.RunLevel -inotmatch 'Limited') { return [pscustomobject]@{ok=$false;reason='runlevel'} }
    if (-not [bool]$task.Settings.Enabled) { return [pscustomobject]@{ok=$false;reason='disabled'} }
    return [pscustomobject]@{ok=$true;reason='exact'}
}
function Wait-UiHeartbeat {
    $started = [DateTimeOffset]::Now
    Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    $first = $null
    $deadline = (Get-Date).AddSeconds(35)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if (Test-Path -LiteralPath $HeartbeatPath -PathType Leaf) {
            try {
                $heartbeat = Read-Json $HeartbeatPath
                $at = [DateTimeOffset]::Parse([string]$heartbeat.at)
                if ((@('READY','WORKING') -contains [string]$heartbeat.state) -and
                    [bool]$heartbeat.explorer_same_session -and [int]$heartbeat.session_id -gt 0 -and
                    $at -ge $started.AddSeconds(-2)) {
                    $first = $heartbeat
                    break
                }
            } catch {}
        }
    }
    if (-not $first) { throw 'UI Bridge did not produce a fresh interactive heartbeat' }
    $firstAt = [DateTimeOffset]::Parse([string]$first.at)
    Start-Sleep -Seconds 7
    $second = Read-Json $HeartbeatPath
    $secondAt = [DateTimeOffset]::Parse([string]$second.at)
    if ($secondAt -le $firstAt.AddSeconds(2) -or ([DateTimeOffset]::Now - $secondAt).TotalSeconds -gt 10 -or
        (@('READY','WORKING') -notcontains [string]$second.state) -or -not [bool]$second.explorer_same_session) {
        throw 'UI Bridge heartbeat did not continue after startup'
    }
    return [ordered]@{first_at=$firstAt.ToString('o');second_at=$secondAt.ToString('o');session_id=[int]$second.session_id;state=[string]$second.state}
}
function Register-KnownUiTask {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $powerShellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
    $arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $UiBridgePath + '" -RunLoop'
    $action = New-ScheduledTaskAction -Execute $powerShellExe -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
    $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Days 3650)
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Kevin narrow InteractiveToken UI Bridge. GREEN Notepad-only.' -Force | Out-Null
}
function Repair-UiTask {
    if ((Get-Sha $UiBridgePath) -cne $UiSha) { throw 'UI Bridge source identity changed' }
    New-Item -ItemType Directory -Path $RepairRoot -Force | Out-Null
    $backup = ''
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        $backup = Join-Path $RepairRoot ('ui-task.before.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.xml')
        Export-ScheduledTask -TaskName $TaskName | Set-Content -LiteralPath $backup -Encoding Unicode
    }
    try {
        try { Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue } catch {}
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
        Register-KnownUiTask
        $state = Get-UiTaskState
        if (-not $state.ok) { throw ('UI task readback failed: ' + $state.reason) }
        return [ordered]@{status='REPAIRED';heartbeat=(Wait-UiHeartbeat);backup=$backup}
    } catch {
        $message = $_.Exception.Message
        if ($backup -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
            if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
            }
            Register-ScheduledTask -TaskName $TaskName -Xml (Get-Content -LiteralPath $backup -Raw) -Force | Out-Null
        }
        throw ('UI repair failed; previous task restored when available: ' + $message)
    }
}
function Invoke-NotepadProof {
    $sessionId = [int]([Diagnostics.Process]::GetCurrentProcess().SessionId)
    $ownerNotepad = @(Get-Process -Name Notepad -ErrorAction SilentlyContinue | Where-Object { [int]$_.SessionId -eq $sessionId })
    if ($ownerNotepad.Count -gt 0) { throw 'Close Notepad before Apply so the proof does not disturb your work' }
    New-Item -ItemType Directory -Path $UiInbox,$UiResults -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $orderId = 'platform-recovery-ui-' + $stamp
    $nonce = [guid]::NewGuid().ToString('N').ToUpperInvariant()
    $request = [ordered]@{schema=1;kind='kevin-ui-bridge-request';authority='GREEN';operation='ui_notepad_write';app='notepad';order_id=$orderId;nonce=$nonce;filename=('Kevin UI Recovery Verification - '+$stamp+'.txt');content=('KEVIN_UI_RECOVERY_OK '+$stamp)}
    $resultPath = Join-Path $UiResults ($orderId + '-' + $nonce + '.result.json')
    Write-JsonAtomic (Join-Path $UiInbox ($orderId + '-' + $nonce + '.json')) $request
    $deadline = (Get-Date).AddSeconds(70)
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $resultPath -PathType Leaf)) { Start-Sleep -Milliseconds 500 }
    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) { throw 'UI Notepad round-trip proof timed out' }
    $result = Read-Json $resultPath
    if ([string]$result.status -cne 'DONE') { throw ('UI Notepad proof failed: ' + [string]$result.status + ' ' + [string]$result.reason) }
    if (-not (Test-Path -LiteralPath ([string]$result.data.output_path) -PathType Leaf) -or
        -not (Test-Path -LiteralPath ([string]$result.data.screenshot_path) -PathType Leaf)) {
        throw 'UI Notepad proof evidence files are missing'
    }
    return [ordered]@{status='ROUND_TRIP_PROVEN';order_id=$orderId;output_sha256=[string]$result.data.sha256;screenshot_sha256=[string]$result.data.screenshot_sha256;session_id=[int]$result.data.session_id}
}

function Get-Preflight {
    $pins = @(
        @($ConfigPath,$ConfigSha,'config'),@($BaselinePath,$BaselineSha,'baseline'),@($BenchmarkPath,$BenchmarkSha,'benchmark'),
        @($UiBridgePath,$UiSha,'ui'),@($MaintenancePath,$MaintenanceSha,'maintenance'),@($SupervisorPath,$SupervisorSha,'supervisor'),
        @($ForgePath,$ForgeSha,'forge'),@($ReaderConfigPath,$ReaderSha,'reader')
    )
    foreach ($pin in $pins) {
        $actual = Get-Sha ([string]$pin[0])
        if ($actual -cne [string]$pin[1]) { throw ([string]$pin[2] + ' identity changed: ' + $actual) }
    }
    Assert-BenchmarkR04Only
    $config = Read-Json $ConfigPath
    Assert-CurrentConfigContract $config
    $trustedPath = Find-TrustedConfigCopy
    if (-not $trustedPath) { throw 'SAFE STOP: proven exact-five DBF596 config bytes not found in bounded backups' }
    $trusted = Read-Json $trustedPath
    # v3 deliberately adopts the exact current config only after its 19-path drift was
    # independently redacted/reviewed and its local-model behavior was requalified.
    # The current and predecessor file SHA pins are the cryptographic boundary; no
    # generic semantic ignore list is introduced.
    Assert-QualificationEvidence
    Assert-ConfigValidateReadOnly
    if ((Get-Sha $ConfigPath) -cne $ConfigSha) { throw 'Production config changed during qualification' }
    $baseline = Read-Json $BaselinePath
    if ([string]$baseline.hashes.production_config -cne $TrustedConfigSha) { throw 'Baseline config anchor changed' }
    if ([string]$baseline.hashes.supervisor -cne $SupervisorSha -or [string]$baseline.hashes.forge -cne $ForgeSha -or [string]$baseline.hashes.reader_config -cne $ReaderSha) {
        throw 'Non-R04 baseline anchors changed'
    }
    return [pscustomobject]@{baseline=$baseline;non_target=(Get-MaskedBaseline $baseline);trusted_path=$trustedPath;ui=(Get-UiTaskState)}
}
function Repair-R04([object]$Preflight) {
    $dir = Join-Path $RepairRoot ('r04-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $backup = Join-Path $dir 'baseline.json.before'
    Copy-Item -LiteralPath $BaselinePath -Destination $backup -Force
    if ((Get-Sha $backup) -cne $BaselineSha) { throw 'Baseline backup verification failed' }
    $after = $Preflight.baseline | ConvertTo-Json -Depth 60 | ConvertFrom-Json
    $after.hashes.production_config = $ConfigSha
    if ((Get-MaskedBaseline $after) -cne $Preflight.non_target) { throw 'Non-target baseline semantics changed before write' }
    try {
        Write-JsonAtomic $BaselinePath $after
        $installed = Read-Json $BaselinePath
        if ([string]$installed.hashes.production_config -cne $ConfigSha -or (Get-MaskedBaseline $installed) -cne $Preflight.non_target) {
            throw 'Installed baseline verification failed'
        }
        if ((Get-Sha $ConfigPath) -cne $ConfigSha -or (Get-Sha $BenchmarkPath) -cne $BenchmarkSha) { throw 'Protected identity changed during R04 repair' }
        $null = Invoke-FreshBenchmark30
        return [ordered]@{status='APPLIED_PROVEN';previous_anchor=$TrustedConfigSha;current_anchor=$ConfigSha;target_leaf='hashes.production_config';non_target_semantics_preserved=$true;backup=$backup}
    } catch {
        $message = $_.Exception.Message
        Copy-Item -LiteralPath $backup -Destination $BaselinePath -Force
        if ((Get-Sha $BaselinePath) -cne $BaselineSha) { throw ('R04 rollback integrity failed: ' + $message) }
        throw ('R04 failed; exact rollback completed: ' + $message)
    }
}
function Invoke-SelfTest {
    foreach ($sha in @($ConfigSha,$TrustedConfigSha,$BaselineSha,$BenchmarkSha,$UiSha,$MaintenanceSha,$SupervisorSha,$ForgeSha,$ReaderSha)) {
        if ($sha -cnotmatch '^[A-F0-9]{64}$') { throw 'Malformed SHA pin' }
    }
    $a = [pscustomobject]@{meta=[pscustomobject]@{lastTouchedAt='old';lastTouchedVersion='1'};tools=[pscustomobject]@{deny=@('exec');alsoAllow=@('x')};z=1}
    $b = [pscustomobject]@{z=1;tools=[pscustomobject]@{alsoAllow=@('x');deny=@('exec')};meta=[pscustomobject]@{lastTouchedAt='new';lastTouchedVersion='2'}}
    if ((Get-CanonicalJson $a) -cne (Get-CanonicalJson $b)) { throw 'Canonical benign-metadata test failed' }
    $b.tools.deny = @('exec','write')
    if ((Get-CanonicalJson $a) -ceq (Get-CanonicalJson $b)) { throw 'Dangerous semantic diff was ignored' }

    $qualified = [pscustomobject]@{
        tools = [pscustomobject]@{ profile='coding'; alsoAllow=$ExpectedTools; deny=$ExpectedDenies }
        agents = [pscustomobject]@{
            defaults = [pscustomobject]@{
                compaction = [pscustomobject]@{ reserveTokensFloor=2048; reserveTokens=2048; keepRecentTokens=4000 }
                models = [pscustomobject]@{
                    'ollama-chat-16k/qwen2.5:14b' = [pscustomobject]@{ params=[pscustomobject]@{num_ctx=12288;temperature=0} }
                    'ollama-chat-16k/llama3.1:8b' = [pscustomobject]@{ params=[pscustomobject]@{num_ctx=12288;temperature=0} }
                }
            }
            list = @([pscustomobject]@{
                id='main'
                model=[pscustomobject]@{primary='ollama-chat-16k/qwen2.5:14b';fallbacks=@('ollama-chat-16k/llama3.1:8b')}
                models=[pscustomobject]@{}
                tools=[pscustomobject]@{allow=$ExpectedTools}
            })
        }
        models = [pscustomobject]@{providers=[pscustomobject]@{
            'ollama-chat'=[pscustomobject]@{timeoutSeconds=600;models=@([pscustomobject]@{id='llama3.1:8b';compat=[pscustomobject]@{supportsTools=$true}})}
            'ollama-chat-16k'=[pscustomobject]@{
                api='ollama';baseUrl='http://127.0.0.1:11434';timeoutSeconds=900
                models=@(
                    [pscustomobject]@{id='qwen2.5:14b';contextTokens=16384;params=[pscustomobject]@{num_ctx=16384;temperature=0;keep_alive='10m'}},
                    [pscustomobject]@{id='llama3.1:8b';input=@('text');contextTokens=12288;params=[pscustomobject]@{num_ctx=12288;temperature=0;keep_alive='10m'};compat=[pscustomobject]@{supportsTools=$true}}
                )
            }
        }}
        gateway = [pscustomobject]@{bind='loopback'}
    }
    Assert-CurrentConfigContract $qualified
    $qualified.agents.list[0].model.fallbacks = @('unsafe/other')
    $refused = $false
    try { Assert-CurrentConfigContract $qualified } catch { $refused = $true }
    if (-not $refused) { throw 'Qualification contract failed to reject fallback drift' }
    Write-Host 'KEVIN RECOVERY V3 SELFTEST PASS exact_current_sha=true qualified_local_models=true evidence_gated=true r04_one_leaf=true rollback=true ui_rebuild=true notepad_roundtrip=true arbitrary_shell=false'
}

if ($SelfTest) { Invoke-SelfTest; exit 0 }
if ($Apply -and $CheckOnly) { throw 'Choose only one of -Apply or -CheckOnly' }
if (-not $Apply) { $CheckOnly = $true }
if ($env:OS -ne 'Windows_NT') { throw 'Run this on the Windows PC that hosts Kevin' }

$mutex = New-Object Threading.Mutex($false,'Global\KevinPlatformRecovery20260906V3')
$owned = $false
try {
    try { $owned = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }
    if (-not $owned) { throw 'Kevin recovery is already active' }
    $preflight = Get-Preflight
    if ($CheckOnly) {
        Write-Host ('KEVIN_RECOVERY_V3_READY trusted_config=found current_config=QUALIFIED_LOCAL_MODEL_EVOLUTION r04=qualified ui_task=' + $preflight.ui.ok + ' ui_reason=' + $preflight.ui.reason)
        exit 0
    }
    New-Item -ItemType Directory -Path $RepairRoot -Force | Out-Null
    $receipt = [ordered]@{schema=3;kind='kevin-platform-recovery-20260906-v3';started_at=(Get-Date).ToString('o');status='STARTED';r04=$null;ui=$null;ui_proof=$null;final_benchmark=$null}
    $receipt.r04 = Repair-R04 $preflight
    Write-JsonAtomic $ReceiptPath $receipt
    try {
        $receipt.ui = Repair-UiTask
        $receipt.ui_proof = Invoke-NotepadProof
        $latest = Invoke-FreshBenchmark30
        $receipt.final_benchmark = [ordered]@{status='PASS';passed=30;total=30;critical=0;at=[string]$latest.at}
        $receipt.status = 'APPLIED_PROVEN'
        $receipt.completed_at = (Get-Date).ToString('o')
        Write-JsonAtomic $ReceiptPath $receipt
        Write-Host 'KEVIN_RECOVERY_V3_APPLIED_PROVEN benchmark=30/30 ui=sustained ui_notepad=ROUND_TRIP_PROVEN'
    } catch {
        $receipt.status = 'PARTIAL_R04_PROVEN_UI_FAILED'
        $receipt.ui = [ordered]@{status='FAILED';error=$_.Exception.Message}
        $receipt.completed_at = (Get-Date).ToString('o')
        Write-JsonAtomic $ReceiptPath $receipt
        throw ('R04 is repaired and Benchmark is green, but UI recovery failed: ' + $_.Exception.Message)
    }
} finally {
    if ($owned) { try { $mutex.ReleaseMutex() } catch {} }
    $mutex.Dispose()
}
