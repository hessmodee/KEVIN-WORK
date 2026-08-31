from pathlib import Path

SRC=Path('control-plane/intake/kevin-work-order-intake-v1.2.4.ps1')
DST=Path('control-plane/intake/generated/kevin-work-order-intake-v1.2.5.ps1')
text=SRC.read_text(encoding='utf-8')

def once(old,new):
    global text
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'expected exactly one marker, got {n}: {old[:180]!r}')
    text=text.replace(old,new,1)

anchor="function Invoke-OsAwarenessSnapshot {"
insert=r'''
function Assert-MaintenanceTerminalProven([object]$State,[DateTimeOffset]$Started) {
    if($null-eq$State){throw 'Maintenance evidence missing after execution'}
    $status=[string]$State.status
    if(@('APPLIED_PREAUTHORIZED_PROVEN','ALREADY_APPLIED_PROVEN') -notcontains $status){throw ('Maintenance terminal state not proven: '+$status)}
    if(-not$State.at){throw 'Maintenance evidence timestamp missing'}
    $at=[DateTimeOffset]::Parse([string]$State.at)
    if($at-lt$Started.AddSeconds(-3)){throw 'Maintenance evidence is not fresh for this execution'}
    return ('maintenance proven status='+$status+' manifest='+[string]$State.manifest_id)
}
function Invoke-MaintenanceVerified {
    $started=[DateTimeOffset]::Now
    $null=Invoke-FixedPowerShell $MaintenancePath @('-CheckOnly') 600
    $latest=Join-Path $Reports 'maintenance\latest.json'
    $state=Read-JsonFile $latest
    return Assert-MaintenanceTerminalProven $state $started
}
'''.strip()
once(anchor,insert+'\n\n'+anchor)

old="function Execute-Order($o){switch([string]$o.verb){'dispatch_mission'{return Invoke-FixedPowerShell $DispatcherPath @('-Mode','Dispatch','-RequestedMission',[string]$o.target) 560}'run_reconcile'{return Invoke-FixedPowerShell $ActuatorPath @('-Mode','Reconcile') 600}'run_benchmark'{return Run-CronVerified 'kevin-benchmark-v1' 9}'run_support_bridge'{return Run-CronVerified 'kevin-support-bridge-v1' 5}'refresh_autonomy_telemetry'{$env:KEVIN_GH_AUTH_MODE='stored';return Invoke-FixedPowerShell $BridgePath @() 180}'run_typed_maintenance'{return Invoke-FixedPowerShell $MaintenancePath @('-CheckOnly') 600}'run_os_awareness'{return Invoke-OsAwarenessSnapshot}};throw 'No executor for work-order verb.'}"
new="function Execute-Order($o){switch([string]$o.verb){'dispatch_mission'{return Invoke-FixedPowerShell $DispatcherPath @('-Mode','Dispatch','-RequestedMission',[string]$o.target) 560}'run_reconcile'{return Invoke-FixedPowerShell $ActuatorPath @('-Mode','Reconcile') 600}'run_benchmark'{return Run-CronVerified 'kevin-benchmark-v1' 9}'run_support_bridge'{return Run-CronVerified 'kevin-support-bridge-v1' 5}'refresh_autonomy_telemetry'{$env:KEVIN_GH_AUTH_MODE='stored';return Invoke-FixedPowerShell $BridgePath @() 180}'run_typed_maintenance'{return Invoke-MaintenanceVerified}'run_os_awareness'{return Invoke-OsAwarenessSnapshot}};throw 'No executor for work-order verb.'}"
once(old,new)

fixture=r'''
    $now=[DateTimeOffset]::Now
    $mGood=[pscustomobject]@{status='APPLIED_PREAUTHORIZED_PROVEN';at=$now.ToString('o');manifest_id='selftest-manifest'}
    $mv=Assert-MaintenanceTerminalProven $mGood $now.AddSeconds(-1);if($mv-notmatch'maintenance proven'){throw 'Maintenance success fixture rejected'}
    $mBad=[pscustomobject]@{status='BLOCKED_FAILURE_BUDGET';at=$now.ToString('o');manifest_id='selftest-manifest'};$blocked=$false;try{Assert-MaintenanceTerminalProven $mBad $now.AddSeconds(-1)}catch{$blocked=$true};if(-not$blocked){throw 'blocked Maintenance state accepted as success'}
    $mStale=[pscustomobject]@{status='ALREADY_APPLIED_PROVEN';at=$now.AddMinutes(-5).ToString('o');manifest_id='selftest-manifest'};$blocked=$false;try{Assert-MaintenanceTerminalProven $mStale $now}catch{$blocked=$true};if(-not$blocked){throw 'stale Maintenance evidence accepted as fresh success'}
'''.rstrip()
once("    if((ConvertTo-Win32CommandLineArg 'a b')-ne'\"a b\"'){throw 'Win32 argv quote selftest failed'}",fixture+"\n    if((ConvertTo-Win32CommandLineArg 'a b')-ne'\"a b\"'){throw 'Win32 argv quote selftest failed'}")
old_mark="""    Write-Host 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS compatibility=v1.2.4'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.3 SELFTEST PASS compatibility=v1.2.4'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.4 SELFTEST PASS verbs=7 stale_order_retirement=true terminal_idle=true semantic_ack_dedupe=true os_awareness_snapshot=fixed maintenance_target=fixed arbitrary_shell=false caller_argv=false caller_path=false'"""
new_mark="""    Write-Host 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS compatibility=v1.2.5'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.3 SELFTEST PASS compatibility=v1.2.5'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.4 SELFTEST PASS compatibility=v1.2.5'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.5 SELFTEST PASS verbs=7 stale_order_retirement=true terminal_idle=true semantic_ack_dedupe=true maintenance_semantic_postcondition=true maintenance_freshness=true false_success_blocked=true arbitrary_shell=false caller_argv=false caller_path=false'"""
once(old_mark,new_mark)
DST.parent.mkdir(parents=True,exist_ok=True)
DST.write_text(text,encoding='utf-8',newline='\n')
print(DST)
