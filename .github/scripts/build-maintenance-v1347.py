#!/usr/bin/env python3
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parents[2]
src = root / 'control-plane' / 'maintenance' / 'kevin-maintenance-runner-v1.3.46.ps1'
out = root / 'control-plane' / 'maintenance' / 'kevin-maintenance-runner-v1.3.47.ps1'
text = src.read_text(encoding='utf-8-sig')

# v1.3.47 removes the generation-specific Maintenance SHA pair from desired-state
# convergence.  The live installed runner identity itself becomes the CAS anchor:
# canonical remote desired-state must pin that exact identity before local bytes may
# converge.  This prevents every Maintenance upgrade from invalidating its own sync.
version_anchor = "version='1.3.46'"
if text.count(version_anchor) != 1:
    raise SystemExit(f'version anchor count mismatch: {text.count(version_anchor)}')
text = text.replace(version_anchor, "version='1.3.47'")

start_marker = 'function Sync-LocalDesiredStateV18 {'
end_marker = '\nfunction Refresh-FullAutonomyAssessment {'
start = text.find(start_marker)
end = text.find(end_marker, start)
if start < 0 or end < 0 or text.find(start_marker, start + 1) >= 0:
    raise SystemExit('Sync-LocalDesiredStateV18 function boundary mismatch')

replacement = r'''function Sync-LocalDesiredStateV18 {
    $remotePath='control-plane/desired-state-v1.json'
    $target=Join-Path $Workspace 'ControlPlane\desired-state-v1.json'
    if(-not(Test-Path -LiteralPath $target -PathType Leaf)){throw 'local desired-state missing'}
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$remotePath),'--jq','.content')
    if($r.ExitCode-ne0-or-not$r.Output){throw 'remote desired-state fetch failed'}
    try{$bytes=[Convert]::FromBase64String(([string]$r.Output-replace'\s',''));$remoteText=[Text.Encoding]::UTF8.GetString($bytes);$remote=$remoteText|ConvertFrom-Json}catch{throw 'remote desired-state invalid'}
    try{$localText=[IO.File]::ReadAllText($target);$local=$localText|ConvertFrom-Json}catch{throw 'local desired-state invalid'}
    foreach($o in @($local,$remote)){
        if([int]$o.schema-ne1-or[string]$o.kind-ne'kevin-desired-state'){throw 'desired-state schema/kind mismatch'}
        if(-not[bool]$o.authority.green_only-or[bool]$o.authority.allow_arbitrary_shell-or[bool]$o.authority.allow_authority_expansion-or[bool]$o.authority.allow_novel_production_promotion){throw 'desired-state authority invariant failed'}
    }

    $live=Get-Sha (Join-Path $Workspace 'kevin-maintenance-runner.ps1')
    if($live-notmatch'^[A-F0-9]{64}$'){throw 'installed Maintenance identity unavailable'}
    $remoteMaint=([string]$remote.core_hashes.maintenance_runner).ToUpperInvariant()
    $localMaint=([string]$local.core_hashes.maintenance_runner).ToUpperInvariant()
    if($remoteMaint-ne$live){throw ('canonical desired-state Maintenance pin does not match live runner remote='+$remoteMaint+' live='+$live)}
    if($localMaint-notmatch'^[A-F0-9]{64}$'){throw ('local desired-state Maintenance pin invalid actual='+$localMaint)}

    # Only the Maintenance pin and non-authoritative reconciliation metadata may lag.
    # Every authority/automation/health/work-conservation section and every other core
    # component pin must already agree before exact canonical bytes can cross locally.
    $remoteSections=[ordered]@{authority=$remote.authority;required_automations=$remote.required_automations;health_contract=$remote.health_contract;green_registry=$remote.green_registry;work_conserving=$remote.work_conserving}
    $localSections=[ordered]@{authority=$local.authority;required_automations=$local.required_automations;health_contract=$local.health_contract;green_registry=$local.green_registry;work_conserving=$local.work_conserving}
    if((Get-TextSha256 ($remoteSections|ConvertTo-Json -Depth 30 -Compress))-ne(Get-TextSha256 ($localSections|ConvertTo-Json -Depth 30 -Compress))){throw 'desired-state non-target sections differ'}
    foreach($name in @('supervisor','benchmark','forge','goal_os','support_bridge')){
        $rpin=([string]$remote.core_hashes.$name).ToUpperInvariant();$lpin=([string]$local.core_hashes.$name).ToUpperInvariant()
        if($rpin-ne$lpin){throw ('desired-state non-Maintenance core pin differs: '+$name)}
    }

    $remoteSha=Get-TextSha256 $remoteText
    $beforeSha=Get-Sha $target
    if($beforeSha-eq$remoteSha){
        if($localMaint-ne$live){throw 'exact canonical desired-state bytes unexpectedly do not pin live Maintenance'}
        Assert-Governance
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;before=$beforeSha;after=$beforeSha;maintenance_pin=$live;authority_effect='NONE'}
    }

    $stage=Join-Path $StageRoot ('desired-state-v18-'+[guid]::NewGuid().ToString('N')+'.json')
    [IO.File]::WriteAllText($stage,$remoteText,$Utf8)
    try{$verify=Get-Content -LiteralPath $stage -Raw|ConvertFrom-Json}catch{throw 'staged desired-state invalid'}
    if((Get-Sha $stage)-ne$remoteSha){throw 'staged desired-state bytes do not match canonical remote'}
    if(([string]$verify.core_hashes.maintenance_runner).ToUpperInvariant()-ne$live){throw 'staged desired-state does not pin live Maintenance'}

    $backupDir=Join-Path $BackupRoot ('desired-state-v18-'+(Get-Date -Format 'yyyyMMdd-HHmmss'));New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $backup=Join-Path $backupDir 'desired-state-v1.json';Copy-Item -LiteralPath $target -Destination $backup -Force
    try{
        $tmp=$target+'.typed-'+[guid]::NewGuid().ToString('N');Copy-Item -LiteralPath $stage -Destination $tmp -Force;Move-Item -LiteralPath $tmp -Destination $target -Force
        if((Get-Sha $target)-ne$remoteSha){throw 'installed desired-state bytes do not match canonical remote'}
        $installed=Get-Content -LiteralPath $target -Raw|ConvertFrom-Json
        if(([string]$installed.core_hashes.maintenance_runner).ToUpperInvariant()-ne$live){throw 'installed desired-state does not pin live Maintenance'}
        Assert-Governance
        Assert-Benchmark30
        return [ordered]@{changed=$true;idempotent=$false;before=$beforeSha;after=(Get-Sha $target);previous_maintenance_pin=$localMaint;maintenance_pin=$live;backup=(Safe-Text $backup 500);authority_effect='NONE'}
    }catch{
        Copy-Item -LiteralPath $backup -Destination $target -Force
        try{Assert-Benchmark30}catch{}
        throw ('desired-state sync rollback completed: '+$_.Exception.Message)
    }finally{Remove-Item -LiteralPath $stage -Force -ErrorAction SilentlyContinue}
}
'''
text = text[:start] + replacement + text[end:]

marker = "    Write-Host 'KEVIN MAINTENANCE v1.3.46 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=fixed_v18_cas_rollback arbitrary_shell=false authority_expansion=false'"
if text.count(marker) != 1:
    raise SystemExit(f'selftest marker count mismatch: {text.count(marker)}')
text = text.replace(marker, marker + "\n    Write-Host 'KEVIN MAINTENANCE v1.3.47 SELFTEST PASS desired_state_sync=live_identity_cas no_generation_pin=true rollback=true arbitrary_shell=false authority_expansion=false'")

# Regression guard: the rewritten sync function must not retain generation-specific
# Maintenance identities or the obsolete v1.3.45 qualification message.
segment = text[text.find(start_marker):text.find(end_marker, text.find(start_marker))]
for forbidden in ('3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E',
                  'AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D',
                  'installed Maintenance identity is not qualified v1.3.45'):
    if forbidden in segment:
        raise SystemExit(f'generation-specific desired-state sync anchor remained: {forbidden}')
for required in ("$remoteMaint-ne$live", "Get-Sha (Join-Path $Workspace 'kevin-maintenance-runner.ps1')", 'desired-state non-target sections differ', 'Assert-Benchmark30'):
    if required not in segment:
        raise SystemExit(f'dynamic desired-state sync marker missing: {required}')

out.write_text(text, encoding='utf-8', newline='\n')
sha = hashlib.sha256(out.read_bytes()).hexdigest().upper()
print(f'BUILT {out.relative_to(root)} SHA256={sha}')
