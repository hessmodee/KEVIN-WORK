param([switch]$SelfTest)
# Materialize-Kevin-FamilyLoop-v1.ps1
# GREEN. After the current production execution WI is COMPLETE, append at most ONE
# refresh WorkInstance bound to the next already-PROVEN West Motor key that has
# no OPEN refresh child. Does not mint skill JSON. Does not reopen COMPLETE
# parents. Does not wipe budgets. Clone PROVE freeze stands. Not PASS.
# Id must NOT be *-fresh-YYYY-MM-DD. materialized_by OWNER_FAMILY_LOOP_REFRESH.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$Items = Join-Path $Workspace 'inbox\autonomy\work-items.json'
$ReceiptDir = Join-Path $Workspace 'reports\engineering'
$Receipt = Join-Path $ReceiptDir 'MATERIALIZE-west-motor-family-refresh-latest.json'

# Order is the standing family loop after parts-chase refresh closed.
$FamilyJson = @'
[
  {"skill":"west-motor-lot-walk-checklist-pack@1","id":"owner-west-motor-lot-walk-checklist-refresh-v1","parent":"owner-west-motor-lot-walk-checklist-fresh-2026-09-11-v1","lineage":"west-motor-lot-walk-checklist"},
  {"skill":"west-motor-aging-inventory-action-pack@1","id":"owner-west-motor-aging-inventory-refresh-v1","parent":"owner-west-motor-aging-inventory-fresh-2026-09-11-v1","lineage":"west-motor-aging-inventory"},
  {"skill":"west-motor-delivery-prep-pack@1","id":"owner-west-motor-delivery-prep-refresh-v1","parent":"owner-west-motor-delivery-prep-fresh-2026-09-11-v1","lineage":"west-motor-delivery-prep"},
  {"skill":"vehicle-transport-mission-pack@1","id":"owner-vehicle-transport-mission-refresh-v1","parent":"owner-west-motor-transport-dispatch-template-v1","lineage":"vehicle-transport-mission"}
]
'@

function Get-Python {
    foreach ($cand in @('python','python3','py')) {
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

if ($SelfTest) {
    if ($FamilyJson -notmatch 'lot-walk-checklist-refresh-v1') { throw 'lot-walk refresh id' }
    if ($FamilyJson -notmatch '"id":"owner-west-motor-lot-walk-checklist-refresh-v1"') { throw 'refresh id shape' }
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
import json, copy, os, sys, re
from datetime import datetime, timezone
path = sys.argv[1]
receipt = sys.argv[2]
family = json.loads(sys.argv[3])
raw = open(path, encoding="utf-8-sig").read()
wi = json.loads(raw)
items = wi.get("items") or []
ids = [str(x.get("id","")) for x in items if isinstance(x, dict)]
fresh_re = re.compile(r"-fresh-\d{4}-\d{2}-\d{2}")
open_prod = [x for x in items if isinstance(x, dict)
             and str(x.get("status","")).upper()=="OPEN"
             and str(x.get("lane","")).lower()=="production"
             and str(x.get("work_type","")).lower()=="execution"
             and str(x.get("required_skill_key") or "").strip()
             and x.get("blocked") is not True]
if open_prod:
    doc = {"schema":1,"kind":"kevin-wi-materialize-family-loop","status":"OPEN_PRODUCTION_ALREADY_ELIGIBLE","eligible":[x.get("id") for x in open_prod],"history_reset":False}
    open(receipt,"w",encoding="utf-8").write(json.dumps(doc,indent=2)+"\n")
    print("FAMILY_LOOP_NOOP_ELIGIBLE")
    sys.exit(0)
chosen = None
for row in family:
    skill = row["skill"]
    new_id = row["id"]
    if fresh_re.search(new_id):
        continue
    open_child = [x for x in items if isinstance(x, dict)
                  and str(x.get("status","")).upper()=="OPEN"
                  and str(x.get("required_skill_key") or "")==skill
                  and "refresh" in str(x.get("id") or "").lower()]
    if open_child:
        continue
    if new_id in ids:
        continue
    chosen = row
    break
if not chosen:
    doc = {"schema":1,"kind":"kevin-wi-materialize-family-loop","status":"ALL_FAMILY_KEYS_HAVE_OPEN_OR_PRESENT","history_reset":False}
    open(receipt,"w",encoding="utf-8").write(json.dumps(doc,indent=2)+"\n")
    print("FAMILY_LOOP_NOOP_PRESENT")
    sys.exit(0)
new_id = chosen["id"]
skill_key = chosen["skill"]
parent_id = chosen["parent"]
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
    "lineage": chosen.get("lineage") or skill_key,
    "successor_of": parent_id,
    "standing_parent_id": "west-motor-owner-value-family-loop-v1",
    "materialized_at": now,
    "materialized_by": "OWNER_FAMILY_LOOP_REFRESH",
    "never_kevin_learned_claim": True,
    "acceptance_criteria": [
        "Supervisor independently selects this OPEN GREEN WorkInstance because it names the exact already-PROVEN skill " + skill_key + ".",
        "Family-loop REFRESH — not a new clone PROVE pack and not a history reset.",
        "PASS requires workbook + note + DONE + hashes + immutable receipt."
    ],
    "next_action": "SELECT and invoke " + skill_key + ". Clone PROVE freeze stands. Do not reopen COMPLETE parents.",
    "owner_inputs": inputs,
    "downstream_consumer": "WEST_MOTOR_FAMILY_LOOP_REFRESH_AND_T4_SELF_SELECT"
}
wi["items"] = items + [new]
wi["updated_at"] = now
wi["family_loop_note"] = "Appended " + new_id + " for " + skill_key + ". History preserved. No budget wipe. No new skill JSON."
open(path,"w",encoding="utf-8").write(json.dumps(wi, indent=2) + "\n")
doc = {"schema":1,"kind":"kevin-wi-materialize-family-loop","status":"APPENDED","id":new_id,"required_skill_key":skill_key,"predecessor":parent_id,"history_reset":False,"clone_prove_minting":False,"actor":"OWNER_FAMILY_LOOP_REFRESH","at":now}
open(receipt,"w",encoding="utf-8").write(json.dumps(doc, indent=2)+"\n")
print("FAMILY_LOOP_APPENDED " + new_id)
sys.exit(0)
'@

$tmpPy = Join-Path $env:TEMP 'kevin-family-loop-refresh.py'
[IO.File]::WriteAllText($tmpPy, $pyCode)
$p = Start-Process -FilePath $py -ArgumentList @($tmpPy, $Items, $Receipt, $FamilyJson) -Wait -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $env:TEMP 'kevin-family-loop-out.txt') -RedirectStandardError (Join-Path $env:TEMP 'kevin-family-loop-err.txt')
$out = ''
$err = ''
try { $out = Get-Content -Raw (Join-Path $env:TEMP 'kevin-family-loop-out.txt') -ErrorAction SilentlyContinue } catch {}
try { $err = Get-Content -Raw (Join-Path $env:TEMP 'kevin-family-loop-err.txt') -ErrorAction SilentlyContinue } catch {}
if ($out) { Write-Host $out.TrimEnd() }
if ($err) { Write-Host $err.TrimEnd() }
exit [int]$p.ExitCode
