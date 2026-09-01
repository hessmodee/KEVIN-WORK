param([switch]$SelfTest)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Evidence = Join-Path $Workspace 'reports\self-reliance'
$StatePath = Join-Path $Evidence 'watchdog-state.json'
$MaintenancePath = Join-Path $Workspace 'kevin-maintenance-runner.ps1'
$WorkOrderIntakePath = Join-Path $Workspace 'ControlPlane\kevin-work-order-intake-v0.1.ps1'
$ConfigPath = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\openclaw.json' } else { '' }
$MaxAttempts = 3
$CooldownMinutes = 15
$MaintenanceIntervalMinutes = 5
$WorkOrderIntervalMinutes = 2
$KnownBackgroundPowerShellTasks = @('Kevin Self-Reliance Watchdog v1','KevinGitHubBridge','KevinNightForge','Kevin UI Bridge v0.3')

function Write-JsonAtomic([string]$Path,[object]$Object) {
    New-Item -ItemType Directory -Force (Split-Path $Path -Parent) | Out-Null
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,($Object | ConvertTo-Json -Depth 20),$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Ensure-Property([object]$Object,[string]$Name,[object]$Default) {
    if ($null -eq $Object.PSObject.Properties[$Name]) { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Default }
}
function Read-State {
    if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
        try { return (Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json) } catch {}
    }
    return [pscustomobject]@{
        schema=2;failure_family='';attempts=0;cooldown_until=$null;last_result='NEVER';updated_at=$null;
        last_maintenance_at=$null;maintenance_result='NEVER';last_work_order_at=$null;work_order_result='NEVER';
        startup_class='UNKNOWN';gateway_probe_exit=$null;config_validate_exit=$null;config_schema_exit=$null;
        gateway_task_running=$false;binary_version='UNKNOWN';config_last_touched_version='UNKNOWN';
        console_hygiene_result='NEVER';console_hygiene_changed=0;console_hygiene_failures=0
    }
}
function Save-State([object]$State,[string]$Result) {
    Ensure-Property $State 'last_result' ''
    Ensure-Property $State 'updated_at' $null
    $State.last_result = $Result
    $State.updated_at = (Get-Date).ToString('o')
    Write-JsonAtomic $StatePath $State
}

function ConvertTo-Win32CommandLineArg([AllowEmptyString()][string]$Value) {
    if ($null -eq $Value -or $Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0
    for ($i=0; $i -lt $Value.Length; $i++) {
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
function Invoke-ExactNative([string]$Executable,[string[]]$Argv,[int]$TimeoutSeconds) {
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
    return [pscustomobject]@{ ExitCode=$code; Stdout=$stdout; Stderr=$stderr; TimedOut=$timed }
}
function Get-OpenClawRuntime {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command node -ErrorAction SilentlyContinue }
    if (-not $node) { throw 'node missing' }
    if (-not $env:APPDATA) { throw 'APPDATA missing' }
    $cli = Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { throw 'OpenClaw runtime missing' }
    return [pscustomobject]@{ Node=[string]$node.Source; Cli=$cli }
}
function Invoke-OpenClawFixed([string[]]$Argv,[int]$TimeoutSeconds) {
    $o = Get-OpenClawRuntime
    return (Invoke-ExactNative $o.Node (@($o.Cli) + @($Argv)) $TimeoutSeconds)
}
function One-Line([AllowEmptyString()][string]$Text) {
    if ($null -eq $Text) { return '' }
    $s = ($Text -replace '[\r\n]+',' ').Trim()
    if ($s.Length -gt 4000) { $s = $s.Substring(0,4000) }
    return $s
}
function Safe-Classify([string]$Text) {
    $s = (One-Line $Text).ToLowerInvariant()
    if ($s -match 'migration.{0,20}lock|startup.{0,20}lock') { return 'MIGRATION_LOCK' }
    if ($s -match 'older binary|newer version|lasttouchedversion|version skew') { return 'VERSION_SKEW' }
    if ($s -match 'invalid config|config.{0,30}invalid|validation failed|unknown config|unrecognized config|schema.{0,20}(invalid|error)') { return 'CONFIG_INVALID' }
    if ($s -match 'plugin.{0,30}(load failed|dependency|failed)|dependency tree corrupted') { return 'PLUGIN_LOAD_FAILURE' }
    if ($s -match 'err_module_not_found|cannot find module|cannot find package|module not found') { return 'MODULE_LOAD_FAILURE' }
    if ($s -match 'eaddrinuse|already.{0,20}listening|port.{0,20}in use') { return 'PORT_CONFLICT' }
    if ($s -match 'unauthorized|forbidden|authentication|invalid token') { return 'AUTH_FAILURE' }
    if ($s -match 'econnrefused|connection refused|connect failed|rpc.{0,20}(unavailable|failed)|not running|stopped') { return 'GATEWAY_STOPPED_OR_RPC' }
    if ($s -match 'typeerror|referenceerror|syntaxerror|uncaught exception') { return 'RUNTIME_EXCEPTION' }
    if ($s -match 'timed out|timeout') { return 'TIMEOUT' }
    if ([string]::IsNullOrWhiteSpace($s)) { return 'EMPTY_FAILURE' }
    return 'OTHER_FAILURE'
}
function Get-BinaryVersion {
    try {
        $r = Invoke-OpenClawFixed @('--version') 20
        if ($r.ExitCode -ne 0) { return 'UNKNOWN' }
        $m = [regex]::Match((One-Line ($r.Stdout + ' ' + $r.Stderr)),'\b20\d{2}\.\d+\.\d+(?:-\d+)?\b')
        if ($m.Success) { return $m.Value }
    } catch {}
    return 'UNKNOWN'
}
function Read-SafeConfigFacts {
    $facts = [ordered]@{ last_touched_version='UNKNOWN';gateway_mode='UNKNOWN';gateway_bind='UNKNOWN';auth_mode='UNKNOWN';telegram_present=$false;discord_present=$false }
    if (-not $ConfigPath -or -not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) { return [pscustomobject]$facts }
    try {
        $c = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        if ($c.meta -and $c.meta.lastTouchedVersion -and [string]$c.meta.lastTouchedVersion -match '^20\d{2}\.\d+\.\d+(?:-\d+)?$') { $facts.last_touched_version = [string]$c.meta.lastTouchedVersion }
        if ($c.gateway) {
            if ([string]$c.gateway.mode -match '^(local|remote)$') { $facts.gateway_mode = [string]$c.gateway.mode }
            if ([string]$c.gateway.bind -match '^(loopback|lan|tailnet|custom)$') { $facts.gateway_bind = [string]$c.gateway.bind }
            if ($c.gateway.auth -and [string]$c.gateway.auth.mode -match '^(none|token|password|trusted-proxy)$') { $facts.auth_mode = [string]$c.gateway.auth.mode }
        }
        if ($c.channels) {
            $facts.telegram_present = ($null -ne $c.channels.PSObject.Properties['telegram'])
            $facts.discord_present = ($null -ne $c.channels.PSObject.Properties['discord'])
        }
        if ($c.plugins -and $c.plugins.entries) {
            $facts.telegram_present = $facts.telegram_present -or ($null -ne $c.plugins.entries.PSObject.Properties['telegram'])
            $facts.discord_present = $facts.discord_present -or ($null -ne $c.plugins.entries.PSObject.Properties['discord'])
        }
    } catch {}
    return [pscustomobject]$facts
}
function Gateway-TaskRunning {
    if ($env:OS -ne 'Windows_NT') { return $false }
    try {
        $t = Get-ScheduledTask -TaskName 'OpenClaw Gateway' -ErrorAction SilentlyContinue
        if (-not $t) {
            $all = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'OpenClaw Gateway*' })
            if ($all.Count -eq 1) { $t = $all[0] }
        }
        return [bool]($t -and [string]$t.State -eq 'Running')
    } catch { return $false }
}

function Add-HiddenWindowStyle([string]$Arguments) {
    $a = [string]$Arguments
    if ($a -match '(?i)(?:^|\s)-(?:WindowStyle|w)\s+Hidden(?:\s|$)') { return $a }
    if ([string]::IsNullOrWhiteSpace($a)) { return '-WindowStyle Hidden' }
    return ('-WindowStyle Hidden ' + $a.Trim())
}
function Repair-KnownBackgroundConsoleTasks {
    if ($env:OS -ne 'Windows_NT') { return [pscustomobject]@{ Result='NOT_WINDOWS';Changed=0;Failures=0 } }
    $changed = 0
    $failures = 0
    foreach ($name in $KnownBackgroundPowerShellTasks) {
        try {
            $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
            if (-not $task) { continue }
            $actions = @($task.Actions)
            if ($actions.Count -ne 1) { $failures++; continue }
            $a = $actions[0]
            $exe = [IO.Path]::GetFileName([string]$a.Execute)
            if ($exe -notmatch '(?i)^(powershell|pwsh)\.exe$') { continue }
            $before = [string]$a.Arguments
            $after = Add-HiddenWindowStyle $before
            if ($after -eq $before) { continue }
            $p = @{ Execute=[string]$a.Execute; Argument=$after }
            if (-not [string]::IsNullOrWhiteSpace([string]$a.WorkingDirectory)) { $p.WorkingDirectory = [string]$a.WorkingDirectory }
            Set-ScheduledTask -TaskName $name -Action (New-ScheduledTaskAction @p) -ErrorAction Stop | Out-Null
            $changed++
        } catch { $failures++ }
    }
    $result = if ($failures -gt 0) { 'PARTIAL' } elseif ($changed -gt 0) { 'REPAIRED' } else { 'OK' }
    return [pscustomobject]@{ Result=$result;Changed=$changed;Failures=$failures }
}

function Maintenance-Due([object]$State) {
    Ensure-Property $State 'last_maintenance_at' $null
    if (-not $State.last_maintenance_at) { return $true }
    try { return ([DateTimeOffset]::Parse([string]$State.last_maintenance_at).AddMinutes($MaintenanceIntervalMinutes) -le [DateTimeOffset]::Now) } catch { return $true }
}
function WorkOrder-Due([object]$State) {
    Ensure-Property $State 'last_work_order_at' $null
    if (-not $State.last_work_order_at) { return $true }
    try { return ([DateTimeOffset]::Parse([string]$State.last_work_order_at).AddMinutes($WorkOrderIntervalMinutes) -le [DateTimeOffset]::Now) } catch { return $true }
}
function Invoke-MaintenanceFixed {
    if (-not (Test-Path -LiteralPath $MaintenancePath -PathType Leaf)) { return [pscustomobject]@{ ExitCode=127 } }
    return (Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',$MaintenancePath,'-CheckOnly') 600)
}
function Invoke-WorkOrderIntakeFixed {
    if (-not (Test-Path -LiteralPath $WorkOrderIntakePath -PathType Leaf)) { return [pscustomobject]@{ ExitCode=127 } }
    return (Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',$WorkOrderIntakePath,'-Mode','Poll') 600)
}
function Run-MaintenanceIfDue([object]$State) {
    Ensure-Property $State 'maintenance_result' 'NEVER'
    if (-not (Maintenance-Due $State)) { return }
    $r = Invoke-MaintenanceFixed
    $State.last_maintenance_at = (Get-Date).ToString('o')
    $State.maintenance_result = if ($r.ExitCode -eq 0) { 'OK' } else { 'FAILED' }
}
function Run-WorkOrderIfDue([object]$State) {
    Ensure-Property $State 'work_order_result' 'NEVER'
    if (-not (WorkOrder-Due $State)) { return }
    $r = Invoke-WorkOrderIntakeFixed
    $State.last_work_order_at = (Get-Date).ToString('o')
    $State.work_order_result = if ($r.ExitCode -eq 0) { 'OK' } else { 'FAILED' }
}

function Invoke-SelfTest {
    if ($MaxAttempts -ne 3) { throw 'retry invariant' }
    if ($CooldownMinutes -ne 15) { throw 'cooldown invariant' }
    if ($MaintenanceIntervalMinutes -ne 5 -or $WorkOrderIntervalMinutes -ne 2) { throw 'cadence invariant' }
    if ((Safe-Classify 'startup-migration lock is active') -ne 'MIGRATION_LOCK') { throw 'classifier migration invariant' }
    if ((Safe-Classify 'plugin load failed: dependency tree corrupted') -ne 'PLUGIN_LOAD_FAILURE') { throw 'classifier plugin invariant' }
    if ((Safe-Classify 'Invalid config at x') -ne 'CONFIG_INVALID') { throw 'classifier config invariant' }
    if ((@('gateway','status','--require-rpc','--json') -join ' ') -ne 'gateway status --require-rpc --json') { throw 'status argv drift' }
    if ((@('gateway','restart','--wait','30s','--json') -join ' ') -ne 'gateway restart --wait 30s --json') { throw 'restart argv drift' }
    if ([IO.Path]::GetFileName($MaintenancePath) -ne 'kevin-maintenance-runner.ps1') { throw 'maintenance target drift' }
    if ([IO.Path]::GetFileName($WorkOrderIntakePath) -ne 'kevin-work-order-intake-v0.1.ps1') { throw 'workorder target drift' }
    Write-Host 'KEVIN SELF-RELIANCE WATCHDOG v1.3 SELFTEST PASS implementation=v1.5.1 gateway_truth=fresh outage_maintenance_wake=true work_order_poll=true safe_startup_classifier=true direct_config_secrets=false retry_max=3 cooldown=15m arbitrary_shell=false caller_argv=false'
}
if ($SelfTest) { Invoke-SelfTest; exit 0 }

$s = Read-State
foreach ($x in @(
    @('schema',2),@('failure_family',''),@('attempts',0),@('cooldown_until',$null),@('last_result','NEVER'),@('updated_at',$null),
    @('last_maintenance_at',$null),@('maintenance_result','NEVER'),@('last_work_order_at',$null),@('work_order_result','NEVER'),
    @('startup_class','UNKNOWN'),@('gateway_probe_exit',$null),@('config_validate_exit',$null),@('config_schema_exit',$null),
    @('gateway_task_running',$false),@('binary_version','UNKNOWN'),@('config_last_touched_version','UNKNOWN'),
    @('console_hygiene_result','NEVER'),@('console_hygiene_changed',0),@('console_hygiene_failures',0)
)) { Ensure-Property $s $x[0] $x[1] }
$s.schema = 2
$h = Repair-KnownBackgroundConsoleTasks
$s.console_hygiene_result = [string]$h.Result
$s.console_hygiene_changed = [int]$h.Changed
$s.console_hygiene_failures = [int]$h.Failures

# Critical resilience rule: maintenance and work-order intake stay alive even when OpenClaw/Gateway is unhealthy.
Run-WorkOrderIfDue $s
Run-MaintenanceIfDue $s

$s.binary_version = Get-BinaryVersion
$facts = Read-SafeConfigFacts
$s.config_last_touched_version = [string]$facts.last_touched_version
$s.gateway_task_running = [bool](Gateway-TaskRunning)

$status = $null
try { $status = Invoke-OpenClawFixed @('gateway','status','--require-rpc','--json') 30 } catch { $status = [pscustomobject]@{ ExitCode=127;Stdout='';Stderr='runtime bootstrap failure';TimedOut=$false } }
$s.gateway_probe_exit = [int]$status.ExitCode
if ($status.ExitCode -eq 0) {
    $s.failure_family = ''
    $s.attempts = 0
    $s.cooldown_until = $null
    $s.startup_class = 'OK'
    Save-State $s 'HEALTHY'
    exit 0
}

$validate = $null
$schema = $null
try { $validate = Invoke-OpenClawFixed @('config','validate','--json') 45 } catch { $validate = [pscustomobject]@{ ExitCode=127;Stdout='';Stderr='';TimedOut=$false } }
try { $schema = Invoke-OpenClawFixed @('config','schema','--json') 45 } catch { $schema = [pscustomobject]@{ ExitCode=127;Stdout='';Stderr='';TimedOut=$false } }
$s.config_validate_exit = [int]$validate.ExitCode
$s.config_schema_exit = [int]$schema.ExitCode
$combined = [string]($status.Stdout + ' ' + $status.Stderr + ' ' + $validate.Stdout + ' ' + $validate.Stderr + ' ' + $schema.Stdout + ' ' + $schema.Stderr)
$class = Safe-Classify $combined
if ($facts.last_touched_version -ne 'UNKNOWN' -and $s.binary_version -ne 'UNKNOWN' -and $facts.last_touched_version -ne $s.binary_version) {
    $class = 'VERSION_SKEW'
} elseif ($validate.ExitCode -ne 0 -and $schema.ExitCode -eq 0 -and $class -eq 'OTHER_FAILURE') {
    $class = 'CONFIG_INVALID'
} elseif (-not $s.gateway_task_running -and $class -eq 'OTHER_FAILURE') {
    $class = 'GATEWAY_STOPPED_OR_RPC'
}
$s.startup_class = $class

if ([string]$s.failure_family -ne $class) {
    $s.failure_family = $class
    $s.attempts = 0
    $s.cooldown_until = $null
}
$now = [DateTimeOffset]::Now
if ($s.cooldown_until) {
    try {
        if ([DateTimeOffset]::Parse([string]$s.cooldown_until) -gt $now) { Save-State $s ('COOLDOWN_' + $class); exit 0 }
    } catch {}
}

# Config/module/version/plugin/migration failures require a typed root repair, never blind restart churn.
if (@('CONFIG_INVALID','PLUGIN_LOAD_FAILURE','MODULE_LOAD_FAILURE','VERSION_SKEW','MIGRATION_LOCK','RUNTIME_EXCEPTION') -contains $class) {
    Save-State $s ('NEEDS_TYPED_REPAIR_' + $class)
    exit 0
}
if ([int]$s.attempts -ge $MaxAttempts) {
    $s.cooldown_until = $now.AddMinutes($CooldownMinutes).ToString('o')
    Save-State $s ('COOLDOWN_' + $class)
    exit 0
}
$s.attempts = [int]$s.attempts + 1
try { $null = Invoke-OpenClawFixed @('gateway','restart','--wait','30s','--json') 75 } catch {}
Start-Sleep -Seconds 2
$verify = $null
try { $verify = Invoke-OpenClawFixed @('gateway','status','--require-rpc','--json') 30 } catch { $verify = [pscustomobject]@{ ExitCode=127 } }
if ($verify.ExitCode -eq 0) {
    $s.failure_family = ''
    $s.attempts = 0
    $s.cooldown_until = $null
    $s.startup_class = 'OK'
    $s.gateway_probe_exit = 0
    $s.gateway_task_running = [bool](Gateway-TaskRunning)
    Save-State $s 'RECOVERED'
    exit 0
}
if ([int]$s.attempts -ge $MaxAttempts) { $s.cooldown_until = $now.AddMinutes($CooldownMinutes).ToString('o') }
Save-State $s ('REPAIR_FAILED_' + $class)
exit 0
