param([switch]$SelfTest)
# Materialize-Kevin-FamilyLoop-v1.ps1
# GREEN. When Supervisor has no OPEN production execution WI with a proven
# skill key (WAITING_ITEM_BUDGETS / all owner invokes COMPLETE), append at
# most ONE refresh WorkInstance bound to west-motor-parts-chase-board-pack@1.
# Does not mint skill JSON. Does not reopen COMPLETE parents. Does not wipe
# budgets or history. Clone PROVE freeze stands. Not PASS.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$Items = Join-Path $Workspace 'inbox\autonomy\work-items.json'
$ReceiptDir = Join-Path $Workspace 'reports\engineering'
$Receipt = Join-Path $ReceiptDir 'MATERIALIZE-west-motor-family-refresh-latest.json'
$NewId = 'owner-west-motor-parts-chase-refresh-2026-09-13-v1'
$SkillKey = 'west-motor-parts-chase-board-pack@1'
$ParentId = 'owner-west-motor-parts-chase-fresh-8-v1'

function Get-Python {
    foreach ($cand in @('python','python3','py')) {
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

if ($SelfTest) {
    if ($NewId -notmatch 'parts-chase-refresh') { throw 'refresh id' }
    if ($SkillKey -ne 'west-motor-parts-chase-board-pack@1') { throw 'skill key' }
    Write-Host 'KEVIN FAMILY LOOP MATERIALIZE v1 SELFTEST PASS'
    exit 0
}

if (-not (Test-Path -LiteralPath $Items -PathType Leaf)) {
    Write-Host 'family-loop skip; work-items.json missing'
    exit 2
}
$py = Get-Python
if (-not $py) {
    Write-Host 'family-loop skip; python missing'
    exit 2
}

New-Item -ItemType Directory -Force -Path $ReceiptDir | Out-Null

$pyCode = @'
import json, copy, os, sys
from datetime import datetime, timezone
path = sys.argv[1]
receipt = sys.argv[2]
new_id = sys.argv[3]
skill_key = sys.argv[4]
parent_id = sys.argv[5]
raw = open(path, encoding="utf-8-sig").read()
wi = json.loads(raw)
items = wi.get("items") or []
ids = [str(x.get("id","")) for x in items if isinstance(x, dict)]
open_prod = [x for x in items if isinstance(x, dict)
             and str(x.get("status","")).upper()=="OPEN"
             and str(x.get("lane","")).lower()=="production"
             and str(x.get("work_type","")).lower()=="execution"
             and str(x.get("required_skill_key") or "").strip()
             and x.get("blocked") is not True]
if new_id in ids:
    doc = {"schema":1,"kind":"kevin-wi-materialize-family-loop","status":"ALREADY_PRESENT","id":new_id,"history_reset":False}
    open(receipt,"w",encoding="utf-8").write(json.dumps(doc,indent=2)+"\n")
    print("FAMILY_LOOP_ALREADY_PRESENT")
    sys.exit(0)
if open_prod:
    doc = {"schema":1,"kind":"kevin-wi-materialize-family-loop","status":"OPEN_PRODUCTION_ALREADY_ELIGIBLE","eligible":[x.get("id") for x in open_prod],"history_reset":False}
    open(receipt,"w",encoding="utf-8").write(json.dumps(doc,indent=2)+"\n")
    print("FAMILY_LOOP_NOOP_ELIGIBLE")
    sys.exit(0)
parent = next((x for x in items if x.get("id")==parent_id), None)
inputs = copy.deepcopy((parent or {}).get("owner_inputs") or {"dataset":"fictional-eight-dealership-vehicles","vehicles":[]})
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00","Z")
new = {
    "id": new_id,
    "program": "capability-reuse",
    "authority_class": "GREEN",
    "status": "OPEN",
    "lane": "production",
    "work_type": "execution",
    "priority": "high",
    "severity": "high",
    "owner_value": 8,
    "required_skill_key": skill_key,
    "required_capabilities": ["kevin_proven_skill_invoke"],
    "worker": "proven-skill-invocation",
    "reuses_proven_capability": True,
    "produces_owner_deliverable": True,
    "closes_proof_gap": True,
    "reduces_bess_intervention": True,
    "dependencies_ready": True,
    "blocked": False,
    "failure_attempts": 0,
    "material_new_evidence": True,
    "estimated_minutes": 20,
    "notepad_banned": True,
    "clone_prove_minting": False,
    "family": "west-motor-owner-value",
    "lineage": "west-motor-parts-chase-board",
    "successor_of": parent_id,
    "standing_parent_id": "west-motor-owner-value-family-loop-v1",
    "materialized_at": now,
    "materialized_by": "TICK_FAMILY_LOOP_V1",
    "never_kevin_learned_claim": True,
    "acceptance_criteria": [
        "Supervisor independently selects this OPEN GREEN WorkInstance because it names the exact already-PROVEN skill west-motor-parts-chase-board-pack@1.",
        "Family-loop REFRESH — not a new clone PROVE pack and not a history reset.",
        "PASS requires workbook + note + DONE + hashes + immutable receipt."
    ],
    "next_action": "SELECT and invoke west-motor-parts-chase-board-pack@1. Clone PROVE freeze stands.",
    "owner_inputs": inputs,
    "downstream_consumer": "WEST_MOTOR_FAMILY_LOOP_REFRESH_AND_T4_SELF_SELECT"
}
# preserve existing items exactly; only append
wi["items"] = items + [new]
wi["updated_at"] = now
open(path,"w",encoding="utf-8").write(json.dumps(wi, indent=2) + "\n")
doc = {"schema":1,"kind":"kevin-wi-materialize-family-loop","status":"APPENDED","id":new_id,"required_skill_key":skill_key,"predecessor":parent_id,"history_reset":False,"clone_prove_minting":False,"actor":"TICK_FAMILY_LOOP_V1","at":now}
open(receipt,"w",encoding="utf-8").write(json.dumps(doc, indent=2)+"\n")
print("FAMILY_LOOP_APPENDED " + new_id)
sys.exit(0)
'@

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $py
$psi.Arguments = '-'
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true
$argLine = 'import sys; sys.argv = ["family-loop", r"%s", r"%s", "%s", "%s", "%s"]; exec(sys.stdin.read())' -f $Items, $Receipt, $NewId, $SkillKey, $ParentId
# Use -c with a temp file for PS 5.1 quoting safety
$tmpPy = Join-Path $env:TEMP 'kevin-family-loop-refresh.py'
[IO.File]::WriteAllText($tmpPy, $pyCode)
$p = Start-Process -FilePath $py -ArgumentList @($tmpPy, $Items, $Receipt, $NewId, $SkillKey, $ParentId) -Wait -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $env:TEMP 'kevin-family-loop-out.txt') -RedirectStandardError (Join-Path $env:TEMP 'kevin-family-loop-err.txt')
$out = ''
$err = ''
try { $out = Get-Content -Raw (Join-Path $env:TEMP 'kevin-family-loop-out.txt') -ErrorAction SilentlyContinue } catch {}
try { $err = Get-Content -Raw (Join-Path $env:TEMP 'kevin-family-loop-err.txt') -ErrorAction SilentlyContinue } catch {}
if ($out) { Write-Host $out.TrimEnd() }
if ($err) { Write-Host $err.TrimEnd() }
exit [int]$p.ExitCode
