#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.47.ps1"
DST = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.48.ps1"
EXPECTED_SRC_SHA256 = "E5A76ED53903C10F7C7E09F0223FF7CE61B0CFEB0DB1C59DBBDC7B0BC7B9628F"
LEGACY_LOCAL_DESIRED_PIN = "FF9C5FDF217B0ED5F38A8566BD54D8A654CB8DFEF0093654DDBC23DC9A1BF956"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def replace_exact(text: str, old: str, new: str, count: int = 1) -> str:
    actual = text.count(old)
    if actual != count:
        raise SystemExit(f"anchor count mismatch for {old!r}: expected {count}, got {actual}")
    return text.replace(old, new)


raw = SRC.read_bytes()
actual_src = sha256_bytes(raw)
if actual_src != EXPECTED_SRC_SHA256:
    raise SystemExit(f"v1.3.47 source identity mismatch: {actual_src}")
text = raw.decode("utf-8-sig")
newline = "\r\n" if "\r\n" in text else "\n"

text = replace_exact(text, "version='1.3.47'", "version='1.3.48'")

pred_old = "        '82C47FAD288CA6FFD69EEF5678C8262065F04C739AACCACEE889005486A5FA15'" + newline + "    )"
pred_new = "        '82C47FAD288CA6FFD69EEF5678C8262065F04C739AACCACEE889005486A5FA15'," + newline + f"        '{LEGACY_LOCAL_DESIRED_PIN}'" + newline + "    )"
text = replace_exact(text, pred_old, pred_new)

fn_lines = [
    "function Retire-LegacyNightForge {",
    "    if($env:OS-ne'Windows_NT'){throw 'legacy Night Forge retirement requires Windows'}",
    "    $taskName='KevinNightForge'",
    "    $supervisorPath=Join-Path $Workspace 'kevin-supervisor.ps1'",
    "    $forgePath=Join-Path $Workspace 'kevin-design-forge.ps1'",
    "    $supBefore=Get-Sha $supervisorPath;$forgeBefore=Get-Sha $forgePath",
    "    if($supBefore-ne$SupervisorV183Sha){throw ('modern Supervisor identity changed actual='+$supBefore)}",
    "    if($forgeBefore-ne$ForgeV40Sha){throw ('modern Forge identity changed actual='+$forgeBefore)}",
    "    $task=Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue",
    "    if(-not$task){Assert-Benchmark30;return [ordered]@{state='NOT_PRESENT_PROVEN';task=$taskName;changed=$false;modern_supervisor_unchanged=$true;modern_forge_unchanged=$true;benchmark='30/30';authority_effect='NONE_FIXED_LEGACY_TASK'}}",
    "    $priorState=[string]$task.State;$wasRunning=($priorState-eq'Running');$wasDisabled=($priorState-eq'Disabled')",
    "    $backupDir=Join-Path $BackupRoot ('legacy-night-forge-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force -Path $backupDir|Out-Null",
    "    $backup=Join-Path $backupDir 'KevinNightForge.xml'",
    "    Export-ScheduledTask -TaskName $taskName -ErrorAction Stop|Set-Content -LiteralPath $backup -Encoding Unicode",
    "    if(-not(Test-Path -LiteralPath $backup -PathType Leaf)){throw 'legacy Night Forge task backup missing'}",
    "    try{",
    "        if($wasRunning){",
    "            Stop-ScheduledTask -TaskName $taskName -ErrorAction Stop",
    "            $deadline=(Get-Date).AddSeconds(30)",
    "            while((Get-Date)-lt$deadline){Start-Sleep -Milliseconds 500;$q=Get-ScheduledTask -TaskName $taskName -ErrorAction Stop;if([string]$q.State-ne'Running'){break}}",
    "            if([string](Get-ScheduledTask -TaskName $taskName -ErrorAction Stop).State-eq'Running'){throw 'legacy Night Forge task did not stop within 30 seconds'}",
    "        }",
    "        Disable-ScheduledTask -TaskName $taskName -ErrorAction Stop|Out-Null",
    "        $after=Get-ScheduledTask -TaskName $taskName -ErrorAction Stop",
    "        if([string]$after.State-ne'Disabled'){throw ('legacy Night Forge task disable readback mismatch state='+[string]$after.State)}",
    "        if((Get-Sha $supervisorPath)-ne$supBefore){throw 'modern Supervisor changed during legacy task retirement'}",
    "        if((Get-Sha $forgePath)-ne$forgeBefore){throw 'modern Forge changed during legacy task retirement'}",
    "        Assert-Benchmark30",
    "        return [ordered]@{state='OMEN_PROVEN';task=$taskName;changed=(-not$wasDisabled);before_state=$priorState;after_state='Disabled';backup=(Safe-Text $backup 500);modern_supervisor_unchanged=$true;modern_forge_unchanged=$true;benchmark='30/30';two_former_hourly_windows_required=$true;authority_effect='NONE_FIXED_LEGACY_TASK'}",
    "    }catch{",
    "        $primary=$_.Exception.Message;$rollbackOk=$true",
    "        try{",
    "            $xml=Get-Content -LiteralPath $backup -Raw",
    "            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue",
    "            Register-ScheduledTask -TaskName $taskName -Xml $xml -Force|Out-Null",
    "            if($wasDisabled){Disable-ScheduledTask -TaskName $taskName -ErrorAction Stop|Out-Null}else{Enable-ScheduledTask -TaskName $taskName -ErrorAction Stop|Out-Null}",
    "            if($wasRunning){Start-ScheduledTask -TaskName $taskName -ErrorAction Stop}",
    "        }catch{$rollbackOk=$false}",
    "        try{Assert-Benchmark30}catch{}",
    "        if(-not$rollbackOk){throw ('legacy Night Forge retirement AND rollback failed after: '+$primary)}",
    "        throw ('legacy Night Forge retirement rollback completed: '+$primary)",
    "    }",
    "}",
    "",
]
insert = newline.join(fn_lines)
anchor = "function Sync-LocalDesiredStateV19 {"
if text.count(anchor) != 1:
    raise SystemExit("Sync-LocalDesiredStateV19 anchor ambiguous")
text = text.replace(anchor, insert + anchor, 1)

allow_old = "'refresh_full_autonomy_assessment','sync_local_desired_state_v19')"
allow_new = "'refresh_full_autonomy_assessment','sync_local_desired_state_v19','retire_legacy_night_forge')"
text = replace_exact(text, allow_old, allow_new)

validate_old = "        'sync_local_desired_state_v19' { Assert-NoCallerArgs $m 'sync_local_desired_state_v19' }" + newline + "        default { throw 'operation not allowlisted' }"
validate_new = "        'sync_local_desired_state_v19' { Assert-NoCallerArgs $m 'sync_local_desired_state_v19' }" + newline + "        'retire_legacy_night_forge' { Assert-NoCallerArgs $m 'retire_legacy_night_forge' }" + newline + "        default { throw 'operation not allowlisted' }"
text = replace_exact(text, validate_old, validate_new)

exec_old = "            'sync_local_desired_state_v19' { Sync-LocalDesiredStateV19; break }" + newline + "        }"
exec_new = "            'sync_local_desired_state_v19' { Sync-LocalDesiredStateV19; break }" + newline + "            'retire_legacy_night_forge' { Retire-LegacyNightForge; break }" + newline + "        }"
text = replace_exact(text, exec_old, exec_new)

family_old = "            'sync_local_desired_state_v19' {'local_desired_state_sync_failure'}" + newline + "            default {'typed_replace_failure'}"
family_new = "            'sync_local_desired_state_v19' {'local_desired_state_sync_failure'}" + newline + "            'retire_legacy_night_forge' {'legacy_night_forge_retirement_failure'}" + newline + "            default {'typed_replace_failure'}"
text = replace_exact(text, family_old, family_new)

marker_old = "    Write-Host 'KEVIN MAINTENANCE v1.3.47 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=live_pin_cas_rollback arbitrary_shell=false authority_expansion=false'"
marker_new = newline.join([
    marker_old,
    "    $lnf=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$lnf.operation='retire_legacy_night_forge';Assert-Common $lnf;Assert-NoCallerArgs $lnf 'retire_legacy_night_forge'",
    "    $lnfBad=$lnf|ConvertTo-Json -Depth 10|ConvertFrom-Json;$lnfBad|Add-Member -NotePropertyName task_name -NotePropertyValue 'caller-selected';$blocked=$false;try{Assert-NoCallerArgs $lnfBad 'retire_legacy_night_forge'}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected legacy task name accepted'}",
    "    $lnfFn=(Get-Command Retire-LegacyNightForge).ScriptBlock.ToString();if(-not$lnfFn.Contains(\"'KevinNightForge'\")){throw 'fixed legacy Night Forge task identity missing'};if($lnfFn -match '(?i)Invoke-Expression|cmd\\.exe|powershell\\.exe'){throw 'legacy task retirement widened execution authority'}",
    f"    if((Get-Command Sync-LocalDesiredStateV19).ScriptBlock.ToString()-notmatch'{LEGACY_LOCAL_DESIRED_PIN}'){{throw 'historical desired-state predecessor missing'}}",
    "    Write-Host 'KEVIN MAINTENANCE v1.3.48 SELFTEST PASS desired_state_historical_predecessor=true legacy_night_forge_retirement=fixed_task backup_rollback=true modern_supervisor_forge_unchanged=true benchmark_30=true arbitrary_shell=false authority_expansion=false'",
])
text = replace_exact(text, marker_old, marker_new)

for required in (
    "version='1.3.48'",
    LEGACY_LOCAL_DESIRED_PIN,
    "function Retire-LegacyNightForge",
    "'retire_legacy_night_forge' { Assert-NoCallerArgs",
    "'retire_legacy_night_forge' { Retire-LegacyNightForge; break }",
    "'legacy_night_forge_retirement_failure'",
    "KEVIN MAINTENANCE v1.3.48 SELFTEST PASS",
):
    if required not in text:
        raise SystemExit(f"required v1.3.48 anchor missing: {required}")

DST.write_text(text, encoding="utf-8", newline="")
print(f"GENERATED {DST.relative_to(ROOT)} sha256={sha256_bytes(DST.read_bytes())}")
