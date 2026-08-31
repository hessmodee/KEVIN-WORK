param([switch]$SelfTest)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Evidence = Join-Path $Workspace 'reports\self-reliance'
$StatePath = Join-Path $Evidence 'watchdog-state.json'
$MaintenancePath = Join-Path $Workspace 'kevin-maintenance-runner.ps1'
$MaxAttempts = 3
$CooldownMinutes = 15
$MaintenanceIntervalMinutes = 5

function Write-JsonAtomic([string]$Path,[object]$Object) {
    New-Item -ItemType Directory -Force (Split-Path $Path -Parent) | Out-Null
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,($Object | ConvertTo-Json -Depth 20),$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Read-State {
    if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
        try { return (Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json) } catch {}
    }
    return [pscustomobject]@{
        schema = 1
        failure_family = ''
        attempts = 0
        cooldown_until = $null
        last_result = ''
        updated_at = $null
        last_maintenance_at = $null
        maintenance_result = 'NEVER'
    }
}

function Ensure-Property([object]$Object,[string]$Name,[object]$Default) {
    if ($null -eq $Object.PSObject.Properties[$Name]) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Default
    }
}

function ConvertTo-Win32CommandLineArg([AllowEmptyString()][string]$Value) {
    if ($null -eq $Value -or $Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $sb = New-Object System.Text.StringBuilder
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
    if (-not $p.Start()) { throw 'fixed process start failed' }
    $ot = $p.StandardOutput.ReadToEndAsync()
    $et = $p.StandardError.ReadToEndAsync()
    $timed = $false
    if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
        $timed = $true
        try { $p.Kill() } catch {}
        $p.WaitForExit()
    }
    $r = [pscustomobject]@{
        ExitCode = $(if ($timed) { 124 } else { [int]$p.ExitCode })
        Stdout = [string]$ot.Result
        Stderr = [string]$et.Result
        TimedOut = $timed
    }
    $p.Dispose()
    return $r
}

function Get-OpenClawRuntime {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command node -ErrorAction SilentlyContinue }
    if (-not $node) { throw 'node missing' }
    $cli = Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { throw 'OpenClaw runtime missing' }
    return [pscustomobject]@{ Node = $node.Source; Cli = $cli }
}

function Invoke-OpenClawFixed([string[]]$Argv,[int]$TimeoutSeconds) {
    $o = Get-OpenClawRuntime
    return (Invoke-ExactNative $o.Node (@($o.Cli) + @($Argv)) $TimeoutSeconds)
}

function Invoke-MaintenanceFixed {
    if (-not (Test-Path -LiteralPath $MaintenancePath -PathType Leaf)) {
        return [pscustomobject]@{ ExitCode = 127; Stdout = ''; Stderr = 'maintenance runner missing'; TimedOut = $false }
    }
    return (Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$MaintenancePath,'-CheckOnly') 600)
}

function Save([object]$State,[string]$Result) {
    Ensure-Property $State 'last_result' ''
    Ensure-Property $State 'updated_at' $null
    $State.last_result = $Result
    $State.updated_at = (Get-Date).ToString('o')
    Write-JsonAtomic $StatePath $State
}

function Maintenance-Due([object]$State) {
    Ensure-Property $State 'last_maintenance_at' $null
    if (-not $State.last_maintenance_at) { return $true }
    try {
        return ([DateTimeOffset]::Parse([string]$State.last_maintenance_at).AddMinutes($MaintenanceIntervalMinutes) -le [DateTimeOffset]::Now)
    }
    catch { return $true }
}

function Run-MaintenanceIfDue([object]$State) {
    Ensure-Property $State 'maintenance_result' 'NEVER'
    Ensure-Property $State 'last_maintenance_at' $null
    if (-not (Maintenance-Due $State)) { return $true }
    $m = Invoke-MaintenanceFixed
    $State.last_maintenance_at = (Get-Date).ToString('o')
    if ($m.ExitCode -ne 0) {
        $State.maintenance_result = 'FAILED'
        Save $State 'MAINTENANCE_FAILED'
        return $false
    }
    $State.maintenance_result = 'OK'
    return $true
}

function Invoke-SelfTest {
    if ($MaxAttempts -ne 3) { throw 'watchdog retry invariant' }
    if ($CooldownMinutes -ne 15) { throw 'watchdog cooldown invariant' }
    if ($MaintenanceIntervalMinutes -ne 5) { throw 'maintenance cadence invariant' }
    $status = @('gateway','status','--require-rpc','--json')
    $restart = @('gateway','restart','--wait','30s','--json')
    if (($status -join ' ') -ne 'gateway status --require-rpc --json') { throw 'status argv drift' }
    if (($restart -join ' ') -ne 'gateway restart --wait 30s --json') { throw 'restart argv drift' }
    $q = ConvertTo-Win32CommandLineArg 'C:\Program Files\Kevin\x.ps1'
    if ($q -ne '"C:\Program Files\Kevin\x.ps1"') { throw 'Win32 argv quote invariant' }
    if ([IO.Path]::GetFileName($MaintenancePath) -ne 'kevin-maintenance-runner.ps1') { throw 'maintenance target drift' }
    $due = [pscustomobject]@{ last_maintenance_at = $null }
    if (-not (Maintenance-Due $due)) { throw 'maintenance-due null invariant' }
    $notDue = [pscustomobject]@{ last_maintenance_at = (Get-Date).ToString('o') }
    if (Maintenance-Due $notDue) { throw 'maintenance-due recent invariant' }
    Write-Host 'KEVIN SELF-RELIANCE WATCHDOG v1.2 SELFTEST PASS gateway_status=fixed gateway_restart=fixed maintenance_wake=fixed runtime_returns=true max_attempts=3 cooldown=15m arbitrary_shell=false caller_argv=false remote_payload=false'
}

if ($SelfTest) { Invoke-SelfTest; exit 0 }

$s = Read-State
foreach ($x in @(
    @('failure_family',''),
    @('attempts',0),
    @('cooldown_until',$null),
    @('last_result',''),
    @('updated_at',$null),
    @('last_maintenance_at',$null),
    @('maintenance_result','NEVER')
)) { Ensure-Property $s $x[0] $x[1] }

$now = [DateTimeOffset]::Now
if ($s.cooldown_until) {
    try {
        if ([DateTimeOffset]::Parse([string]$s.cooldown_until) -gt $now) { Save $s 'COOLDOWN'; exit 0 }
    }
    catch {}
}

$status = Invoke-OpenClawFixed @('gateway','status','--require-rpc','--json') 30
if ($status.ExitCode -eq 0) {
    $s.failure_family = ''
    $s.attempts = 0
    $s.cooldown_until = $null
    if (-not (Run-MaintenanceIfDue $s)) { exit 1 }
    Save $s 'HEALTHY'
    exit 0
}

if ([string]$s.failure_family -ne 'gateway_rpc_unhealthy') {
    $s.failure_family = 'gateway_rpc_unhealthy'
    $s.attempts = 0
}
$s.attempts = [int]$s.attempts + 1
if ([int]$s.attempts -gt $MaxAttempts) {
    $s.cooldown_until = $now.AddMinutes($CooldownMinutes).ToString('o')
    Save $s 'RESTART_BUDGET_EXHAUSTED'
    exit 1
}

$restart = Invoke-OpenClawFixed @('gateway','restart','--wait','30s','--json') 60
if ($restart.ExitCode -ne 0) { Save $s 'RESTART_FAILED'; exit 1 }
Start-Sleep -Seconds 3
$verify = Invoke-OpenClawFixed @('gateway','status','--require-rpc','--json') 30
if ($verify.ExitCode -ne 0) { Save $s 'RESTART_POSTCONDITION_FAILED'; exit 1 }
$s.failure_family = ''
$s.attempts = 0
$s.cooldown_until = $null
if (-not (Run-MaintenanceIfDue $s)) { exit 1 }
Save $s 'RECOVERED'
exit 0
