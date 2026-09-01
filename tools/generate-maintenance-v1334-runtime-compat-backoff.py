from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.33.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.34.ps1')
EXPECTED_SRC_SHA256 = '33F52DC59D0801C0731DDF58362656349F71972B678E5E7E069366E3E44DA971'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA256:
    raise SystemExit(f'v1.3.33 source identity mismatch: {actual}')
text = raw.decode('utf-8')


def once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)


once("version='1.3.33'", "version='1.3.34'", 'state version')

# Omen-proven installed OpenClaw exposes cron; upstream retains cron as the
# compatibility alias. Use that stable surface for the fixed continuation job.
once("Invoke-OpenClawFixedConfig @('automations','list','--all','--json')",
     "Invoke-OpenClawFixedConfig @('cron','list','--all','--json')", 'continuation list CLI')
once("Invoke-OpenClawFixedConfig @('automations','add','--name',$name,'--every','5m','--session','main','--system-event',$event,'--wake','now')",
     "Invoke-OpenClawFixedConfig @('cron','add','--name',$name,'--every','5m','--session','main','--system-event',$event,'--wake','now')", 'continuation add CLI')
once("Invoke-OpenClawFixedConfig @('automations','get',$id,'--json')",
     "Invoke-OpenClawFixedConfig @('cron','get',$id,'--json')", 'continuation get CLI')
once("Invoke-OpenClawFixedConfig @('automations','run',$id)",
     "Invoke-OpenClawFixedConfig @('cron','run',$id)", 'continuation run CLI')

old_allow = "'run_self_reliance_watchdog_once','diagnose_gateway_failure_detail','repair_openclaw_windows_lkg') -contains [string]$m.operation)"
new_allow = "'run_self_reliance_watchdog_once','diagnose_gateway_failure_detail','repair_openclaw_windows_lkg','reconcile_maintenance_cron_backoff') -contains [string]$m.operation)"
once(old_allow, new_allow, 'common operation allowlist')

anchor = "function Assert-MainAgentCanary([object]$m) {\n"
block = r'''function Reconcile-MaintenanceCronBackoff {
    $declarationKey='kevin-maintenance-intake-v1'
    $expectedName='Kevin Maintenance Intake v1.1d'
    $list=Invoke-OpenClawFixedConfig @('cron','list','--all','--json')
    if($list.exit_code-ne0){throw 'Maintenance cron list failed'}
    try{$obj=$list.output|ConvertFrom-Json}catch{throw 'Maintenance cron list returned invalid JSON'}
    $jobs=if($obj -is [array]){@($obj)}elseif($obj.PSObject.Properties['jobs']){@($obj.jobs)}elseif($obj.PSObject.Properties['items']){@($obj.items)}else{@($obj)}
    $matches=@($jobs|Where-Object{[string]$_.declarationKey -eq $declarationKey -and [string]$_.name -eq $expectedName})
    if($matches.Count-ne1){throw ('Maintenance cron identity did not resolve exactly once count='+$matches.Count)}
    $id=[string]$matches[0].id
    if($id -notmatch '^[A-Za-z0-9-]{8,96}$'){throw 'Maintenance cron id invalid'}
    $before=Invoke-OpenClawFixedConfig @('cron','get',$id,'--json')
    if($before.exit_code-ne0){throw 'Maintenance cron get before reset failed'}
    try{$b=$before.output|ConvertFrom-Json}catch{throw 'Maintenance cron get before reset invalid JSON'}
    if([string]$b.declarationKey-ne$declarationKey -or [string]$b.name-ne$expectedName){throw 'Maintenance cron readback identity mismatch'}
    if($b.PSObject.Properties['enabled'] -and -not[bool]$b.enabled){throw 'Maintenance cron unexpectedly disabled before reset'}
    $beforeErrors=if($b.state -and $b.state.PSObject.Properties['consecutiveErrors']){[int]$b.state.consecutiveErrors}else{0}
    $rawBefore=[string]$before.output
    if($rawBefore -notmatch '"everyMs"\s*:\s*300000'){throw 'Maintenance cron cadence changed before reset'}

    # A committed enabled=true patch is the scheduler-owned reset primitive.
    # It does not execute this job and therefore cannot recurse into Maintenance.
    $edit=Invoke-OpenClawFixedConfig @('cron','edit',$id,'--enable')
    if($edit.exit_code-ne0){throw 'Maintenance cron enable/reset patch failed'}
    $after=Invoke-OpenClawFixedConfig @('cron','get',$id,'--json')
    if($after.exit_code-ne0){throw 'Maintenance cron get after reset failed'}
    try{$a=$after.output|ConvertFrom-Json}catch{throw 'Maintenance cron get after reset invalid JSON'}
    if([string]$a.declarationKey-ne$declarationKey -or [string]$a.name-ne$expectedName){throw 'Maintenance cron identity changed during reset'}
    if($a.PSObject.Properties['enabled'] -and -not[bool]$a.enabled){throw 'Maintenance cron not enabled after reset'}
    $afterErrors=if($a.state -and $a.state.PSObject.Properties['consecutiveErrors']){[int]$a.state.consecutiveErrors}else{0}
    $scheduleErrors=if($a.state -and $a.state.PSObject.Properties['scheduleErrorCount']){[int]$a.state.scheduleErrorCount}else{0}
    if($afterErrors-ne0 -or $scheduleErrors-ne0){throw ('Maintenance cron backoff counters not reset errors='+$afterErrors+' schedule='+$scheduleErrors)}
    $rawAfter=[string]$after.output
    if($rawAfter -notmatch '"everyMs"\s*:\s*300000'){throw 'Maintenance cron cadence changed during reset'}
    Assert-Benchmark30
    return [ordered]@{state='OMEN_PROVEN';declaration_key=$declarationKey;job_name=$expectedName;enabled=$true;cadence_ms=300000;consecutive_errors_before=$beforeErrors;consecutive_errors_after=$afterErrors;schedule_errors_after=$scheduleErrors;job_executed=$false;authority_effect='NONE'}
}

''' + anchor
once(anchor, block, 'backoff reconciler insertion')

once("        'repair_openclaw_windows_lkg' { Assert-NoCallerArgs $m 'repair_openclaw_windows_lkg' }\n        default { throw 'operation not allowlisted' }",
     "        'repair_openclaw_windows_lkg' { Assert-NoCallerArgs $m 'repair_openclaw_windows_lkg' }\n        'reconcile_maintenance_cron_backoff' { Assert-NoCallerArgs $m 'reconcile_maintenance_cron_backoff' }\n        default { throw 'operation not allowlisted' }", 'validation dispatch')
once("            'repair_openclaw_windows_lkg' { Repair-OpenClawWindowsLkg; break }\n        }",
     "            'repair_openclaw_windows_lkg' { Repair-OpenClawWindowsLkg; break }\n            'reconcile_maintenance_cron_backoff' { Reconcile-MaintenanceCronBackoff; break }\n        }", 'execution dispatch')
once("            'repair_openclaw_windows_lkg' {'openclaw_windows_lkg_recovery_failure'}\n            default {'typed_replace_failure'}",
     "            'repair_openclaw_windows_lkg' {'openclaw_windows_lkg_recovery_failure'}\n            'reconcile_maintenance_cron_backoff' {'maintenance_cron_backoff_reconcile_failure'}\n            default {'typed_replace_failure'}", 'failure dispatch')

self_anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.33 SELFTEST PASS watchdog_probe=v1.6.0 probe_no_intake=true probe_no_restart=true classifier_proof=true native_npm_cli=true package_rollback=true arbitrary_shell=false authority_expansion=false'\n"
self_extra = self_anchor + r'''    $rb=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$rb.operation='reconcile_maintenance_cron_backoff';Assert-Common $rb;Assert-NoCallerArgs $rb 'reconcile_maintenance_cron_backoff'
    $rbBad=$rb|ConvertTo-Json -Depth 10|ConvertFrom-Json;$rbBad|Add-Member -NotePropertyName job_id -NotePropertyValue 'caller-selected';$blocked=$false;try{Assert-NoCallerArgs $rbBad 'reconcile_maintenance_cron_backoff'}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Maintenance cron id accepted'}
    $contFn=(Get-Command Ensure-AutonomyContinuationAutomation).ScriptBlock.ToString();if($contFn -match "'automations'"){throw 'runtime-incompatible automations CLI remains in continuation'};if($contFn -notmatch "'cron'"){throw 'cron compatibility alias missing from continuation'}
    $backFn=(Get-Command Reconcile-MaintenanceCronBackoff).ScriptBlock.ToString();if(-not$backFn.Contains("'kevin-maintenance-intake-v1'")){throw 'fixed Maintenance declaration key missing'};if(-not$backFn.Contains("'Kevin Maintenance Intake v1.1d'")){throw 'fixed Maintenance name missing'};if(-not$backFn.Contains("'--enable'")){throw 'scheduler-owned reset patch missing'};if($backFn -match "'run'\s*,\s*\$id"){throw 'backoff reconciler must not execute Maintenance job'}
    Write-Host 'KEVIN MAINTENANCE v1.3.34 SELFTEST PASS continuation_cli=cron_alias runtime_compatible=true maintenance_backoff_reset=enabled_patch no_recursive_run=true fixed_job_identity=true benchmark_postcondition=true arbitrary_shell=false authority_expansion=false'
'''
once(self_anchor, self_extra, 'v1.3.34 selftest')

OUT.write_text(text, encoding='utf-8', newline='')
print('MAINT_V1334_GENERATED sha256=' + hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
