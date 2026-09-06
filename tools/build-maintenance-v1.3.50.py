#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.49.ps1"
DST = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.50.ps1"
SUP = ROOT / "control-plane" / "autonomy" / "kevin-supervisor-v1.8.10.ps1"
SEL = ROOT / "control-plane" / "autonomy" / "kevin-work-selector-v1.2.py"
INC = ROOT / "tools" / "maintenance-v1.3.50-install-v1810.ps1.inc"
QUAL = ROOT / "reports" / "engineering" / "QUALIFICATION-maint-v1.3.50-supervisor-v1810.json"

EXPECTED_PARENT = "715E40DF0CFDC94FC8D470A83273467A6B10CC6CB9A2956E3A94FADC69B9646B"
EXPECTED_LIVE_SUPERVISOR = "D77BCAA7E2CB76B0F477F7CBAC0C93CC1ABF010F24373EC2F0207D73A1B76810"
EXPECTED_SELECTOR = "52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def replace_once(text: str, old: str, new: str, label: str) -> str:
    n = text.count(old)
    if n != 1:
        raise SystemExit(f"{label}: expected exact anchor once, found {n}")
    return text.replace(old, new, 1)


parent_sha = sha256(SRC)
if parent_sha != EXPECTED_PARENT:
    raise SystemExit(f"parent Maintenance identity changed: {parent_sha}")
selector_sha = sha256(SEL)
if selector_sha != EXPECTED_SELECTOR:
    raise SystemExit(f"selector v1.2 identity changed: {selector_sha}")
supervisor_sha = sha256(SUP)

text = SRC.read_text(encoding="utf-8")
include = INC.read_text(encoding="utf-8").strip()

text = replace_once(
    text,
    "$SupervisorV189Source = 'control-plane/autonomy/kevin-supervisor-v1.8.9-identity-key.ps1'",
    "$SupervisorV189Source = 'control-plane/autonomy/kevin-supervisor-v1.8.9-identity-key.ps1'\n"
    + f"$SupervisorV1810PredecessorSha = '{EXPECTED_LIVE_SUPERVISOR}'\n"
    + f"$SupervisorV1810Sha = '{supervisor_sha}'\n"
    + "$SupervisorV1810Source = 'control-plane/autonomy/kevin-supervisor-v1.8.10.ps1'\n"
    + "$SelectorV12Source = 'control-plane/autonomy/kevin-work-selector-v1.2.py'",
    "insert v1.8.10 pins",
)
text = replace_once(text, "version='1.3.49'", "version='1.3.50'", "state version")
text = replace_once(
    text,
    "'run_main_agent_canary','install_autonomy_controller_v183','diagnose_gateway_rpc'",
    "'run_main_agent_canary','install_autonomy_controller_v183','install_autonomy_controller_v1810','diagnose_gateway_rpc'",
    "operation allowlist",
)
text = replace_once(
    text,
    "function Assert-GatewayRpcDiagnosis([object]$m) {",
    include + "\n\nfunction Assert-GatewayRpcDiagnosis([object]$m) {",
    "insert v1.8.10 implementation",
)
text = replace_once(
    text,
    "'install_autonomy_controller_v183' { Assert-AutonomyControllerV183Install $m }\n        'diagnose_gateway_rpc'",
    "'install_autonomy_controller_v183' { Assert-AutonomyControllerV183Install $m }\n        'install_autonomy_controller_v1810' { Assert-AutonomyControllerV1810Install $m }\n        'diagnose_gateway_rpc'",
    "validation dispatch",
)
text = replace_once(
    text,
    "'install_autonomy_controller_v183' { Install-AutonomyControllerV183 $m; break }\n            'diagnose_gateway_rpc'",
    "'install_autonomy_controller_v183' { Install-AutonomyControllerV183 $m; break }\n            'install_autonomy_controller_v1810' { Install-AutonomyControllerV1810 $m; break }\n            'diagnose_gateway_rpc'",
    "execution dispatch",
)
text = replace_once(
    text,
    "'install_autonomy_controller_v183' {'autonomy_controller_v183_install_failure'}\n            'diagnose_gateway_rpc'",
    "'install_autonomy_controller_v183' {'autonomy_controller_v183_install_failure'}\n            'install_autonomy_controller_v1810' {'autonomy_controller_v1810_install_failure'}\n            'diagnose_gateway_rpc'",
    "failure-family dispatch",
)
text = replace_once(
    text,
    "$acceptedNames=@('Kevin Supervisor v1.6 High Gear','Kevin Autonomy Continuation v1','Kevin Supervisor v1.8.8','Kevin Supervisor v1.8.9')",
    "$acceptedNames=@('Kevin Supervisor v1.6 High Gear','Kevin Autonomy Continuation v1','Kevin Supervisor v1.8.8','Kevin Supervisor v1.8.9','Kevin Supervisor v1.8.10')",
    "scheduler accepted names",
)
text = replace_once(
    text,
    "if($supSha-ne$SupervisorV189Sha -and $supSha-ne$SupervisorV183Sha){throw 'qualified governed Supervisor must be installed before cadence reconciliation'}",
    "if($supSha-ne$SupervisorV1810Sha -and $supSha-ne$SupervisorV189Sha -and $supSha-ne$SupervisorV183Sha){throw 'qualified governed Supervisor must be installed before cadence reconciliation'}",
    "scheduler accepted hashes",
)

fixture = """    $aci10=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json
    $aci10.operation='install_autonomy_controller_v1810'
    Assert-Common $aci10
    Assert-AutonomyControllerV1810Install $aci10
    $aci10Bad=$aci10|ConvertTo-Json -Depth 10|ConvertFrom-Json
    $aci10Bad|Add-Member -NotePropertyName source_path -NotePropertyValue 'caller-selected'
    $blocked=$false
    try{Assert-AutonomyControllerV1810Install $aci10Bad}catch{$blocked=$true}
    if(-not$blocked){throw 'caller-selected Supervisor v1.8.10 source accepted'}
    if($SupervisorV1810PredecessorSha-notmatch'^[A-F0-9]{64}$'-or$SupervisorV1810Sha-notmatch'^[A-F0-9]{64}$'-or$SupervisorV1810PredecessorSha-eq$SupervisorV1810Sha){throw 'Supervisor v1.8.10 transition pins invalid'}
    if($SelectorV12Sha-ne'52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A'){throw 'selector v1.2 pin changed'}"""
text = replace_once(
    text,
    "    Write-Host 'KEVIN MAINTENANCE v1.3.26 SELFTEST PASS fixed_main_canary=true gateway_rpc_only=true gateway_probe_retries=3 supervisor_v183=true selector_v11=true arbitrary_shell=false authority_expansion=false'",
    fixture + "\n    Write-Host 'KEVIN MAINTENANCE v1.3.26 SELFTEST PASS fixed_main_canary=true gateway_rpc_only=true gateway_probe_retries=3 supervisor_v183=true selector_v11=true arbitrary_shell=false authority_expansion=false'",
    "selftest fixture",
)
text = replace_once(
    text,
    "Write-Host 'KEVIN MAINTENANCE v1.3.49 SELFTEST PASS supervisor_live_pin=v1.8.9 historical_v16_migrate=retired cron_dual_accept=true selector_v12_pin=true identity_key_budget_aware=true'",
    "Write-Host 'KEVIN MAINTENANCE v1.3.49 SELFTEST PASS supervisor_live_pin=v1.8.9 historical_v16_migrate=retired cron_dual_accept=true selector_v12_pin=true identity_key_budget_aware=true'\n"
    + "Write-Host 'KEVIN MAINTENANCE v1.3.50 SELFTEST PASS supervisor_v1810_install=fixed exact_live_predecessor=true selector_v12=true baseline_anchor=atomic history_preserved=true work_items_preserved=true mission_leases_preserved=true route_before_turn_charge=true owner_value_skills_to_skill_lab=true rollback=true arbitrary_shell=false authority_expansion=false'",
    "v1.3.50 marker",
)

DST.write_text(text, encoding="utf-8", newline="\n")
candidate_sha = sha256(DST)
qualification = {
    "schema": 1,
    "kind": "kevin-maintenance-v1.3.50-supervisor-v1810-qualification",
    "parent_maintenance_sha256": parent_sha,
    "candidate_maintenance_sha256": candidate_sha,
    "live_supervisor_predecessor_sha256": EXPECTED_LIVE_SUPERVISOR,
    "candidate_supervisor_sha256": supervisor_sha,
    "selector_v12_sha256": selector_sha,
    "operation": "install_autonomy_controller_v1810",
    "authority_class": "GREEN",
    "authority_delta": "NONE",
    "production_effect": "NONE",
    "preserves": ["continuation-history", "work-items", "mission-leases", "forge-anchor"],
    "postcondition": "fresh Benchmark PASS 30/30 critical0",
    "rollback": "exact supervisor/selector/baseline backups",
}
QUAL.parent.mkdir(parents=True, exist_ok=True)
QUAL.write_text(json.dumps(qualification, indent=2) + "\n", encoding="utf-8")
print(json.dumps(qualification, indent=2))
