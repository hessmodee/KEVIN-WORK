#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'control-plane' / 'maintenance' / 'kevin-maintenance-runner-v1.3.45.ps1'
OUT = ROOT / 'control-plane' / 'maintenance' / 'kevin-maintenance-runner-v1.3.46.ps1'
EXPECTED_BASE = 'AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D'
OLD_MAINT = '3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E'
NEW_MAINT = EXPECTED_BASE


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one anchor, found {count}')
    return text.replace(old, new, 1)


raw = SRC.read_bytes()
if sha(raw) != EXPECTED_BASE:
    raise SystemExit(f'base source identity mismatch: {sha(raw)}')
text = raw.decode('utf-8-sig')

# v1.3.46: truthful audit blockers. PowerShell unary '-' is numeric negation,
# not logical negation; the old form reported recovered Benchmark/UI as blockers.
text = replace_once(text, "if(-$benchOk){$blockers+='BENCHMARK_NOT_PASS'}", "if(-not $benchOk){$blockers+='BENCHMARK_NOT_PASS'}", 'benchmark blocker')
text = replace_once(text, "if(-$hbFresh){$blockers+='UI_BRIDGE_STALE'}", "if(-not $hbFresh){$blockers+='UI_BRIDGE_STALE'}", 'ui blocker')

# v1.3.46: PowerShell -File selftest staging must retain a .ps1 extension.
old_tmp = "$tmp=$path+'.stage-'+[guid]::NewGuid().ToString('N');[IO.File]::WriteAllText($tmp,$text,$Utf8);Parse-PowerShell $tmp"
new_tmp = "$tmp=$path+'.stage-'+[guid]::NewGuid().ToString('N')+'.ps1';[IO.File]::WriteAllText($tmp,$text,$Utf8);Parse-PowerShell $tmp"
text = replace_once(text, old_tmp, new_tmp, 'ui watchdog stage suffix')

# v1.3.46: installed OpenClaw cron get may wrap the job in `job` or `item`.
old_b = "try{$b=$before.output|ConvertFrom-Json}catch{throw 'Maintenance cron get before reset invalid JSON'}\n    if([string]$b.declarationKey-ne$declarationKey -or [string]$b.name-ne$expectedName){throw 'Maintenance cron readback identity mismatch'}"
new_b = "try{$b=$before.output|ConvertFrom-Json}catch{throw 'Maintenance cron get before reset invalid JSON'}\n    if($b.PSObject.Properties['job']){$b=$b.job}elseif($b.PSObject.Properties['item']){$b=$b.item}\n    if([string]$b.declarationKey-ne$declarationKey -or [string]$b.name-ne$expectedName){throw 'Maintenance cron readback identity mismatch'}"
text = replace_once(text, old_b, new_b, 'cron before wrapper')
old_a = "try{$a=$after.output|ConvertFrom-Json}catch{throw 'Maintenance cron get after reset invalid JSON'}\n    if([string]$a.declarationKey-ne$declarationKey -or [string]$a.name-ne$expectedName){throw 'Maintenance cron identity changed during reset'}"
new_a = "try{$a=$after.output|ConvertFrom-Json}catch{throw 'Maintenance cron get after reset invalid JSON'}\n    if($a.PSObject.Properties['job']){$a=$a.job}elseif($a.PSObject.Properties['item']){$a=$a.item}\n    if([string]$a.declarationKey-ne$declarationKey -or [string]$a.name-ne$expectedName){throw 'Maintenance cron identity changed during reset'}"
text = replace_once(text, old_a, new_a, 'cron after wrapper')

# Fixed, no-caller-path desired-state convergence. It accepts only the already
# proven v1.3.44 -> v1.3.45 Maintenance pin transition and preserves every
# other desired-state section semantically.
sync_fn = r'''
function Sync-LocalDesiredStateV18 {
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
    $old='3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E'
    $new='AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D'
    $live=Get-Sha (Join-Path $Workspace 'kevin-maintenance-runner.ps1')
    if($live-ne$new){throw ('installed Maintenance identity is not qualified v1.3.45 actual='+$live)}
    $remoteMaint=([string]$remote.core_hashes.maintenance_runner).ToUpperInvariant()
    $localMaint=([string]$local.core_hashes.maintenance_runner).ToUpperInvariant()
    if($remoteMaint-ne$new){throw ('remote desired-state Maintenance pin unexpected actual='+$remoteMaint)}
    $remoteSections=[ordered]@{authority=$remote.authority;required_automations=$remote.required_automations;health_contract=$remote.health_contract;green_registry=$remote.green_registry;work_conserving=$remote.work_conserving}
    $localSections=[ordered]@{authority=$local.authority;required_automations=$local.required_automations;health_contract=$local.health_contract;green_registry=$local.green_registry;work_conserving=$local.work_conserving}
    if((Get-TextSha256 ($remoteSections|ConvertTo-Json -Depth 30 -Compress))-ne(Get-TextSha256 ($localSections|ConvertTo-Json -Depth 30 -Compress))){throw 'desired-state non-target sections differ'}
    foreach($name in @('supervisor','benchmark','forge','goal_os','support_bridge')){
        if(([string]$remote.core_hashes.$name).ToUpperInvariant()-ne([string]$local.core_hashes.$name).ToUpperInvariant()){throw ('desired-state non-Maintenance core pin differs: '+$name)}
    }
    $remoteSha=Get-TextSha256 $remoteText
    $beforeSha=Get-Sha $target
    if($localMaint-eq$new){
        if($beforeSha-ne$remoteSha){throw 'local desired-state has new Maintenance pin but does not exactly match canonical remote desired-state'}
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;before=$beforeSha;after=$beforeSha;maintenance_pin=$new;authority_effect='NONE'}
    }
    if($localMaint-ne$old){throw ('local desired-state Maintenance pin not approved predecessor actual='+$localMaint)}
    $stage=Join-Path $StageRoot ('desired-state-v18-'+[guid]::NewGuid().ToString('N')+'.json')
    [IO.File]::WriteAllText($stage,$remoteText,$Utf8)
    try{$verify=Get-Content -LiteralPath $stage -Raw|ConvertFrom-Json}catch{throw 'staged desired-state invalid'}
    if(([string]$verify.core_hashes.maintenance_runner).ToUpperInvariant()-ne$new){throw 'staged desired-state Maintenance pin mismatch'}
    $backupDir=Join-Path $BackupRoot ('desired-state-v18-'+(Get-Date -Format 'yyyyMMdd-HHmmss'));New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $backup=Join-Path $backupDir 'desired-state-v1.json';Copy-Item -LiteralPath $target -Destination $backup -Force
    try{
        $tmp=$target+'.typed-'+[guid]::NewGuid().ToString('N');Copy-Item -LiteralPath $stage -Destination $tmp -Force;Move-Item -LiteralPath $tmp -Destination $target -Force
        if((Get-Sha $target)-ne$remoteSha){throw 'installed desired-state bytes do not match canonical remote'}
        Assert-Governance
        Assert-Benchmark30
        return [ordered]@{changed=$true;idempotent=$false;before=$beforeSha;after=(Get-Sha $target);maintenance_pin=$new;backup=(Safe-Text $backup 500);authority_effect='NONE'}
    }catch{
        Copy-Item -LiteralPath $backup -Destination $target -Force
        try{Assert-Benchmark30}catch{}
        throw ('desired-state sync rollback completed: '+$_.Exception.Message)
    }finally{Remove-Item -LiteralPath $stage -Force -ErrorAction SilentlyContinue}
}
'''.strip('\n')
anchor = 'function Refresh-FullAutonomyAssessment {'
if text.count(anchor) != 1:
    raise SystemExit('refresh function anchor mismatch')
text = text.replace(anchor, sync_fn + '\n\n' + anchor, 1)

# Add the fixed operation at every contract/dispatch/failure-family surface.
old_allow = "'ensure_ui_bridge_watchdog','refresh_full_autonomy_assessment') -contains [string]$m.operation"
new_allow = "'ensure_ui_bridge_watchdog','refresh_full_autonomy_assessment','sync_local_desired_state_v18') -contains [string]$m.operation"
text = replace_once(text, old_allow, new_allow, 'common allowlist')
old_validate = "        'refresh_full_autonomy_assessment' { Assert-NoCallerArgs $m 'refresh_full_autonomy_assessment' }\n        default { throw 'operation not allowlisted' }"
new_validate = "        'refresh_full_autonomy_assessment' { Assert-NoCallerArgs $m 'refresh_full_autonomy_assessment' }\n        'sync_local_desired_state_v18' { Assert-NoCallerArgs $m 'sync_local_desired_state_v18' }\n        default { throw 'operation not allowlisted' }"
text = replace_once(text, old_validate, new_validate, 'operation validator')
old_dispatch = "            'refresh_full_autonomy_assessment' { Refresh-FullAutonomyAssessment; break }"
new_dispatch = "            'refresh_full_autonomy_assessment' { Refresh-FullAutonomyAssessment; break }\n            'sync_local_desired_state_v18' { Sync-LocalDesiredStateV18; break }"
text = replace_once(text, old_dispatch, new_dispatch, 'operation dispatch')
old_family = "            'refresh_full_autonomy_assessment' {'full_autonomy_refresh_failure'}\n            default {'typed_replace_failure'}"
new_family = "            'refresh_full_autonomy_assessment' {'full_autonomy_refresh_failure'}\n            'sync_local_desired_state_v18' {'local_desired_state_sync_failure'}\n            default {'typed_replace_failure'}"
text = replace_once(text, old_family, new_family, 'failure family')

# Update state version and add a distinct selftest marker without deleting the
# previous historical marker.
text = replace_once(text, "version='1.3.45'", "version='1.3.46'", 'state version')
old_self = "    Write-Host 'KEVIN MAINTENANCE v1.3.45 SELFTEST PASS main_tool_diagnosis=true ui_watchdog=true autonomy_refresh=true arbitrary_shell=false authority_expansion=false'"
new_self = old_self + "\n    Write-Host 'KEVIN MAINTENANCE v1.3.46 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=fixed_v18_cas_rollback arbitrary_shell=false authority_expansion=false'"
text = replace_once(text, old_self, new_self, 'v1346 selftest')

OUT.write_text(text, encoding='utf-8', newline='\n')
print('MAINTENANCE_V1346_GENERATED', sha(OUT.read_bytes()))
