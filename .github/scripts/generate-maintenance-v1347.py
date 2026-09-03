#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.46.ps1"
DST = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.47.ps1"
EXPECTED_SRC_SHA256 = "82C47FAD288CA6FFD69EEF5678C8262065F04C739AACCACEE889005486A5FA15"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def replace_exact(text: str, old: str, new: str, count: int = 1) -> str:
    actual = text.count(old)
    if actual != count:
        raise SystemExit(f"anchor count mismatch for {old!r}: expected {count}, got {actual}")
    return text.replace(old, new)


raw = SRC.read_bytes()
if sha256_bytes(raw) != EXPECTED_SRC_SHA256:
    raise SystemExit(f"v1.3.46 source identity mismatch: {sha256_bytes(raw)}")
text = raw.decode("utf-8-sig")
newline = "\r\n" if "\r\n" in text else "\n"

start_marker = "function Sync-LocalDesiredStateV18 {"
end_marker = "function Refresh-FullAutonomyAssessment {"
start = text.find(start_marker)
end = text.find(end_marker)
if start < 0 or end < 0 or end <= start:
    raise SystemExit("desired-state sync function boundary not found")
if text.count(start_marker) != 1 or text.count(end_marker) != 1:
    raise SystemExit("desired-state sync function boundary is ambiguous")

fn_lines = [
    "function Sync-LocalDesiredStateV19 {",
    "    $remotePath='control-plane/desired-state-v1.json'",
    "    $target=Join-Path $Workspace 'ControlPlane\\desired-state-v1.json'",
    "    if(-not(Test-Path -LiteralPath $target -PathType Leaf)){throw 'local desired-state missing'}",
    "    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$remotePath),'--jq','.content')",
    "    if($r.ExitCode-ne0-or-not$r.Output){throw 'remote desired-state fetch failed'}",
    "    try{$bytes=[Convert]::FromBase64String(([string]$r.Output-replace'\\s',''));$remoteText=[Text.Encoding]::UTF8.GetString($bytes);$remote=$remoteText|ConvertFrom-Json}catch{throw 'remote desired-state invalid'}",
    "    try{$localText=[IO.File]::ReadAllText($target);$local=$localText|ConvertFrom-Json}catch{throw 'local desired-state invalid'}",
    "    foreach($o in @($local,$remote)){",
    "        if([int]$o.schema-ne1-or[string]$o.kind-ne'kevin-desired-state'){throw 'desired-state schema/kind mismatch'}",
    "        if(-not[bool]$o.authority.green_only-or[bool]$o.authority.allow_arbitrary_shell-or[bool]$o.authority.allow_authority_expansion-or[bool]$o.authority.allow_novel_production_promotion){throw 'desired-state authority invariant failed'}",
    "    }",
    "    $live=Get-Sha (Join-Path $Workspace 'kevin-maintenance-runner.ps1')",
    "    if($live-notmatch'^[A-F0-9]{64}$'){throw 'installed Maintenance identity unavailable'}",
    "    $remoteMaint=([string]$remote.core_hashes.maintenance_runner).ToUpperInvariant()",
    "    $localMaint=([string]$local.core_hashes.maintenance_runner).ToUpperInvariant()",
    "    if($remoteMaint-ne$live){throw ('remote desired-state Maintenance pin does not match installed Maintenance identity actual='+$live+' remote='+$remoteMaint)}",
    "    $approvedPredecessors=@(",
    "        '3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E',",
    "        'AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D',",
    "        '82C47FAD288CA6FFD69EEF5678C8262065F04C739AACCACEE889005486A5FA15'",
    "    )",
    "    foreach($name in @('supervisor','benchmark','forge','goal_os','support_bridge')){",
    "        $rv=([string]$remote.core_hashes.$name).ToUpperInvariant();$lv=([string]$local.core_hashes.$name).ToUpperInvariant()",
    "        if(-not$rv-or-not$lv-or$rv-ne$lv){throw ('desired-state non-Maintenance core pin differs: '+$name)}",
    "    }",
    "    $remoteSha=Get-TextSha256 $remoteText",
    "    $beforeSha=Get-Sha $target",
    "    if($localMaint-eq$remoteMaint){",
    "        if($beforeSha-ne$remoteSha){throw 'local desired-state Maintenance pin matches live but file is not byte-identical to canonical remote desired-state'}",
    "        Assert-Benchmark30",
    "        return [ordered]@{changed=$false;idempotent=$true;before=$beforeSha;after=$beforeSha;maintenance_pin=$remoteMaint;authority_effect='NONE'}",
    "    }",
    "    if($approvedPredecessors-notcontains$localMaint){throw ('local desired-state Maintenance pin is not an approved predecessor actual='+$localMaint)}",
    "    $stage=Join-Path $StageRoot ('desired-state-v19-'+[guid]::NewGuid().ToString('N')+'.json')",
    "    [IO.File]::WriteAllText($stage,$remoteText,$Utf8)",
    "    try{$verify=Get-Content -LiteralPath $stage -Raw|ConvertFrom-Json}catch{throw 'staged desired-state invalid'}",
    "    if(([string]$verify.core_hashes.maintenance_runner).ToUpperInvariant()-ne$live){throw 'staged desired-state Maintenance pin mismatch'}",
    "    $backupDir=Join-Path $BackupRoot ('desired-state-v19-'+(Get-Date -Format 'yyyyMMdd-HHmmss'));New-Item -ItemType Directory -Force -Path $backupDir|Out-Null",
    "    $backup=Join-Path $backupDir 'desired-state-v1.json';Copy-Item -LiteralPath $target -Destination $backup -Force",
    "    try{",
    "        $tmp=$target+'.typed-'+[guid]::NewGuid().ToString('N');Copy-Item -LiteralPath $stage -Destination $tmp -Force;Move-Item -LiteralPath $tmp -Destination $target -Force",
    "        if((Get-Sha $target)-ne$remoteSha){throw 'installed desired-state hash mismatch'}",
    "        Assert-Benchmark30",
    "        return [ordered]@{changed=$true;before=$beforeSha;after=(Get-Sha $target);maintenance_pin=$live;backup=(Safe-Text $backup 500);authority_effect='NONE';rollback_available=$true}",
    "    }catch{",
    "        Copy-Item -LiteralPath $backup -Destination $target -Force",
    "        try{Assert-Benchmark30}catch{}",
    "        throw ('desired-state sync rollback completed: '+$_.Exception.Message)",
    "    }finally{Remove-Item -LiteralPath $stage -Force -ErrorAction SilentlyContinue}",
    "}",
    "",
]
new_fn = newline.join(fn_lines)
text = text[:start] + new_fn + text[end:]

text = replace_exact(text, "version='1.3.46'", "version='1.3.47'")
text = replace_exact(text, "'sync_local_desired_state_v18'", "'sync_local_desired_state_v19'", count=2)
text = replace_exact(text, "Sync-LocalDesiredStateV18", "Sync-LocalDesiredStateV19", count=1)
text = replace_exact(
    text,
    "Write-Host 'KEVIN MAINTENANCE v1.3.46 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=fixed_v18_cas_rollback arbitrary_shell=false authority_expansion=false'",
    "Write-Host 'KEVIN MAINTENANCE v1.3.47 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=live_pin_cas_rollback arbitrary_shell=false authority_expansion=false'",
)

if "function Sync-LocalDesiredStateV18" in text or "sync_local_desired_state_v18" in text:
    raise SystemExit("obsolete v18 desired-state sync contract remains")
if text.count("function Sync-LocalDesiredStateV19") != 1:
    raise SystemExit("v19 desired-state sync function count mismatch")
if "remote desired-state Maintenance pin does not match installed Maintenance identity" not in text:
    raise SystemExit("live-pin desired-state invariant missing")
if "arbitrary_shell=false authority_expansion=false" not in text:
    raise SystemExit("self-test safety marker missing")

DST.write_text(text, encoding="utf-8", newline="")
print(f"GENERATED {DST.relative_to(ROOT)} sha256={sha256_bytes(DST.read_bytes())}")
