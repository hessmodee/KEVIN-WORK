"""Kevin production crossing v2 candidate contract.

Pure validation/planning only. No filesystem, subprocess, network, registry,
scheduled-task, config, or process mutation is performed here.
"""
from __future__ import annotations
from typing import Any, Mapping

DESKTOP_TOOLS_V0_1 = (
    "kevin_system_status",
    "kevin_desktop_find_folder",
    "kevin_desktop_open_folder",
    "kevin_app_launch",
)
DESKTOP_TOOLS_V0_2 = (
    "kevin_system_status",
    "kevin_desktop_find_folder",
    "kevin_desktop_open_folder",
    "kevin_desktop_list_folder",
    "kevin_app_launch",
)
# Back-compat alias for existing install_kevin_desktop_v0_1 tests/callers.
DESKTOP_TOOLS = DESKTOP_TOOLS_V0_1
OPS = (
    "install_kevin_desktop_v0_1",
    "install_kevin_desktop_list_folder_v0_2",
    "retire_legacy_kevin_night_forge",
)
LEGACY_TASK = "KevinNightForge"

class ContractError(ValueError):
    pass

def _exact_bool(v: Any) -> bool:
    return type(v) is bool

def validate_request(req: Mapping[str, Any]) -> dict[str, Any]:
    if not isinstance(req, Mapping):
        raise ContractError("request must be an object")
    allowed={"schema","kind","id","authority_class","operation","requires_owner_approval","preconditions"}
    extra=set(req)-allowed
    if extra:
        raise ContractError(f"unexpected fields: {sorted(extra)}")
    if req.get("schema") != 2 or req.get("kind") != "kevin-production-crossing-request":
        raise ContractError("schema/kind mismatch")
    rid=req.get("id")
    if not isinstance(rid,str) or not (6 <= len(rid) <= 96) or not all(c.isalnum() or c in "._-" for c in rid):
        raise ContractError("invalid id")
    if req.get("authority_class") != "YELLOW":
        raise ContractError("candidate crossing must remain YELLOW")
    if req.get("operation") not in OPS:
        raise ContractError("operation not allowlisted")
    if not _exact_bool(req.get("requires_owner_approval")) or req["requires_owner_approval"] is not True:
        raise ContractError("explicit owner approval required")
    pre=req.get("preconditions")
    if not isinstance(pre,Mapping):
        raise ContractError("preconditions required")
    if req["operation"]=="install_kevin_desktop_v0_1":
        return _desktop_plan(rid,pre)
    if req["operation"]=="install_kevin_desktop_list_folder_v0_2":
        return _list_folder_plan(rid,pre)
    return _night_forge_plan(rid,pre)

def _desktop_plan(rid: str, pre: Mapping[str, Any]) -> dict[str, Any]:
    allowed={"source_contract","plugin_id","requested_tools","fixed_main_tools_before","benchmark","rollback_required"}
    if set(pre)!=allowed:
        raise ContractError("desktop precondition set must be exact")
    if pre["source_contract"]!="docs/engineering/KEVIN-DESKTOP-TYPED-CROSSING-CONTRACT-2026-09-03.md":
        raise ContractError("wrong desktop source contract")
    if pre["plugin_id"]!="kevin-desktop":
        raise ContractError("wrong plugin")
    tools=pre["requested_tools"]
    if not isinstance(tools,list) or tuple(tools)!=DESKTOP_TOOLS_V0_1 or len(set(tools))!=4:
        raise ContractError("requested tool inventory must be exactly the four qualified tools")
    if pre["fixed_main_tools_before"]!=0:
        raise ContractError("fixed:main precondition drift")
    b=pre["benchmark"]
    if b!={"status":"PASS","passed":30,"total":30,"critical":0}:
        raise ContractError("fresh 30/30 benchmark precondition required")
    if pre["rollback_required"] is not True:
        raise ContractError("rollback required")
    return {
        "request_id":rid,
        "operation":"install_kevin_desktop_v0_1",
        "production_effect":"CANDIDATE_ONLY",
        "authority_delta":"NONE",
        "exact_expected_tools":list(DESKTOP_TOOLS_V0_1),
        "required_live_proofs":[
            "exact installed plugin identity",
            "exact fixed:main effective inventory equals four tools",
            "positive real-turn folder/app canary",
            "forbidden shell/path/argument negative tests",
            "fresh benchmark 30/30 critical 0",
            "fresh support + engineering evidence",
            "exact rollback bytes/config checkpoint",
        ],
    }

def _list_folder_plan(rid: str, pre: Mapping[str, Any]) -> dict[str, Any]:
    allowed={
        "source_contract","plugin_id","requested_tools","fixed_main_tools_before",
        "benchmark","rollback_required","plugin_version"
    }
    if set(pre)!=allowed:
        raise ContractError("list_folder precondition set must be exact")
    if pre["source_contract"]!="docs/engineering/KEVIN-DESKTOP-LIST-FOLDER-CROSSING-CONTRACT-2026-09-04.md":
        raise ContractError("wrong list_folder source contract")
    if pre["plugin_id"]!="kevin-desktop":
        raise ContractError("wrong plugin")
    if pre["plugin_version"]!="0.2.0":
        raise ContractError("wrong plugin version")
    tools=pre["requested_tools"]
    if not isinstance(tools,list) or tuple(tools)!=DESKTOP_TOOLS_V0_2 or len(set(tools))!=5:
        raise ContractError("requested tool inventory must be exactly the five qualified tools")
    before=pre["fixed_main_tools_before"]
    if not isinstance(before,list) or tuple(before)!=DESKTOP_TOOLS_V0_1:
        raise ContractError("fixed:main must already be exact-4 before list_folder widen")
    b=pre["benchmark"]
    if b!={"status":"PASS","passed":30,"total":30,"critical":0}:
        raise ContractError("fresh 30/30 benchmark precondition required")
    if pre["rollback_required"] is not True:
        raise ContractError("rollback required")
    return {
        "request_id":rid,
        "operation":"install_kevin_desktop_list_folder_v0_2",
        "production_effect":"CANDIDATE_ONLY",
        "authority_delta":"NONE",
        "exact_expected_tools":list(DESKTOP_TOOLS_V0_2),
        "exact_before_tools":list(DESKTOP_TOOLS_V0_1),
        "required_live_proofs":[
            "exact installed plugin identity 0.2.0",
            "exact fixed:main effective inventory equals five tools",
            "positive list_folder Desktop canary returns real basenames",
            "forbidden traversal/absolute/invalid_root negatives",
            "prior four tools still healthy",
            "fresh benchmark 30/30 critical 0",
            "fresh support + engineering evidence",
            "exact rollback bytes/config checkpoint",
        ],
    }

def _night_forge_plan(rid: str, pre: Mapping[str, Any]) -> dict[str, Any]:
    allowed={"task_name","replacement_scheduler_proven","benchmark","rollback_required"}
    if set(pre)!=allowed:
        raise ContractError("task-retirement precondition set must be exact")
    if pre["task_name"]!=LEGACY_TASK:
        raise ContractError("only KevinNightForge may be targeted")
    if pre["replacement_scheduler_proven"] is not True:
        raise ContractError("replacement scheduler must already be proven")
    if pre["benchmark"]!={"status":"PASS","passed":30,"total":30,"critical":0}:
        raise ContractError("fresh 30/30 benchmark precondition required")
    if pre["rollback_required"] is not True:
        raise ContractError("rollback required")
    return {
        "request_id":rid,
        "operation":"retire_legacy_kevin_night_forge",
        "production_effect":"CANDIDATE_ONLY",
        "authority_delta":"NONE",
        "exact_task_name":LEGACY_TASK,
        "required_live_proofs":[
            "task exists before change and identity is exact",
            "modern supervisor/design-forge schedulers healthy",
            "disable-first observation window",
            "fresh benchmark 30/30 critical 0",
            "remove only after disable proof",
            "no other scheduled-task semantic change",
        ],
    }
