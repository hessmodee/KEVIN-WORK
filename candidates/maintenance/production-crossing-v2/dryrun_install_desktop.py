from contract import validate_request, ContractError
import json
req={
  "schema":2,
  "kind":"kevin-production-crossing-request",
  "id":"desktop-hesspc-dryrun-20260904-0805",
  "authority_class":"YELLOW",
  "operation":"install_kevin_desktop_v0_1",
  "requires_owner_approval":True,
  "preconditions":{
    "source_contract":"docs/engineering/KEVIN-DESKTOP-TYPED-CROSSING-CONTRACT-2026-09-03.md",
    "plugin_id":"kevin-desktop",
    "requested_tools":[
      "kevin_system_status",
      "kevin_desktop_find_folder",
      "kevin_desktop_open_folder",
      "kevin_app_launch"
    ],
    "fixed_main_tools_before":0,
    "benchmark":{"status":"PASS","passed":30,"total":30,"critical":0},
    "rollback_required":True
  }
}
plan=validate_request(req)
print("PLAN="+json.dumps(plan, indent=2))
bad=dict(req); bad["requires_owner_approval"]=False
try:
  validate_request(bad); print("FAIL_NO_OWNER")
except ContractError as e:
  print("NEG_OWNER_GATE_OK:"+str(e))
bad2=json.loads(json.dumps(req)); bad2["preconditions"]["requested_tools"].append("exec")
try:
  validate_request(bad2); print("FAIL_EXTRA")
except ContractError as e:
  print("NEG_EXTRA_TOOL_OK:"+str(e))
print("production_effect="+plan["production_effect"])
print("authority_delta="+plan["authority_delta"])
