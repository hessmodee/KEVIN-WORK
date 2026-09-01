from pathlib import Path

src=Path('control-plane/maintenance/kevin-self-reliance-watchdog-v1.5.1.ps1')
dst=Path('control-plane/maintenance/kevin-self-reliance-watchdog-v1.6.0.ps1')
s=src.read_text(encoding='utf-8')

def once(old,new,label):
    global s
    n=s.count(old)
    if n!=1:
        raise SystemExit(f'{label}: expected one anchor, got {n}')
    s=s.replace(old,new,1)

once('param([switch]$SelfTest)','param([switch]$SelfTest,[switch]$ProbeOnly)','param')

old_task="""function Gateway-TaskRunning {
    if ($env:OS -ne 'Windows_NT') { return $false }
    try {
        $t = Get-ScheduledTask -TaskName 'OpenClaw Gateway' -ErrorAction SilentlyContinue
        if (-not $t) {
            $all = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'OpenClaw Gateway*' })
            if ($all.Count -eq 1) { $t = $all[0] }
        }
        return [bool]($t -and [string]$t.State -eq 'Running')
    } catch { return $false }
}"""
new_task="""function Gateway-TaskRunning {
    if ($env:OS -ne 'Windows_NT') { return $false }
    try {
        $t = Get-ScheduledTask -TaskName 'KevinGatewayKeeper' -ErrorAction SilentlyContinue
        if (-not $t) { $t = Get-ScheduledTask -TaskName 'OpenClaw Gateway' -ErrorAction SilentlyContinue }
        if (-not $t) {
            $all = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'OpenClaw Gateway*' })
            if ($all.Count -eq 1) { $t = $all[0] }
        }
        return [bool]($t -and [string]$t.State -eq 'Running')
    } catch { return $false }
}"""
once(old_task,new_task,'gateway-task-topology')

old_intake="""$s.schema = 2
$h = Repair-KnownBackgroundConsoleTasks
$s.console_hygiene_result = [string]$h.Result
$s.console_hygiene_changed = [int]$h.Changed
$s.console_hygiene_failures = [int]$h.Failures

# Critical resilience rule: maintenance and work-order intake stay alive even when OpenClaw/Gateway is unhealthy.
Run-WorkOrderIfDue $s
Run-MaintenanceIfDue $s"""
new_intake="""$s.schema = 2
if ($ProbeOnly) {
    $s.console_hygiene_result = 'SKIPPED_PROBE'
    $s.console_hygiene_changed = 0
    $s.console_hygiene_failures = 0
    $s.maintenance_result = 'SKIPPED_PROBE'
    $s.work_order_result = 'SKIPPED_PROBE'
} else {
    $h = Repair-KnownBackgroundConsoleTasks
    $s.console_hygiene_result = [string]$h.Result
    $s.console_hygiene_changed = [int]$h.Changed
    $s.console_hygiene_failures = [int]$h.Failures

    # Critical resilience rule: maintenance and work-order intake stay alive even when OpenClaw/Gateway is unhealthy.
    Run-WorkOrderIfDue $s
    Run-MaintenanceIfDue $s
}"""
once(old_intake,new_intake,'probe-intake-skip')

old_healthy="""if ($status.ExitCode -eq 0) {
    $s.failure_family = ''
    $s.attempts = 0
    $s.cooldown_until = $null
    $s.startup_class = 'OK'
    Save-State $s 'HEALTHY'
    exit 0
}"""
new_healthy="""if ($status.ExitCode -eq 0) {
    $s.startup_class = 'OK'
    if ($ProbeOnly) { Save-State $s 'PROBE_ONLY_HEALTHY'; exit 0 }
    $s.failure_family = ''
    $s.attempts = 0
    $s.cooldown_until = $null
    Save-State $s 'HEALTHY'
    exit 0
}"""
once(old_healthy,new_healthy,'probe-healthy')

once("$s.startup_class = $class\n\nif ([string]$s.failure_family -ne $class) {",
     "$s.startup_class = $class\nif ($ProbeOnly) { $s.failure_family = $class; Save-State $s ('PROBE_ONLY_' + $class); exit 0 }\n\nif ([string]$s.failure_family -ne $class) {",
     'probe-failure-stop')

old_marker="Write-Host 'KEVIN SELF-RELIANCE WATCHDOG v1.3 SELFTEST PASS implementation=v1.5.1 gateway_truth=fresh outage_maintenance_wake=true work_order_poll=true safe_startup_classifier=true direct_config_secrets=false retry_max=3 cooldown=15m arbitrary_shell=false caller_argv=false'"
new_marker="""if (-not $PSCommandPath -or -not (Test-Path -LiteralPath $PSCommandPath -PathType Leaf)) { throw 'self path unavailable' }
    $selfText=[IO.File]::ReadAllText($PSCommandPath)
    if ($selfText -notmatch 'param\\(\\[switch\\]\\$SelfTest,\\[switch\\]\\$ProbeOnly\\)') { throw 'ProbeOnly parameter missing' }
    if ($selfText -notmatch "maintenance_result = 'SKIPPED_PROBE'") { throw 'ProbeOnly maintenance recursion guard missing' }
    if ($selfText -notmatch "Save-State \\$s \\('PROBE_ONLY_' \\+ \\$class\\)") { throw 'ProbeOnly failure terminal missing' }
    if ($selfText -notmatch "Get-ScheduledTask -TaskName 'KevinGatewayKeeper'") { throw 'Gateway Keeper topology missing' }
    Write-Host 'KEVIN SELF-RELIANCE WATCHDOG v1.3 SELFTEST PASS implementation=v1.6.0 gateway_truth=fresh outage_maintenance_wake=true work_order_poll=true probe_only=true probe_no_intake=true probe_no_restart=true keeper_topology=true safe_startup_classifier=true direct_config_secrets=false retry_max=3 cooldown=15m arbitrary_shell=false caller_argv=false'"""
once(old_marker,new_marker,'selftest')

dst.write_text(s,encoding='utf-8',newline='\n')
print(dst)
