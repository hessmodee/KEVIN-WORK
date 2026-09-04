#!/usr/bin/env python3
"""Policy-only Minecraft companion gate. No network/game executor in this file."""
from __future__ import annotations
from typing import Any, Dict

ALLOWED={"follow","come","stay","status","inventory","find","collect","help_build","stop"}
RESOURCE_ALLOW={"oak_log","spruce_log","birch_log","cobblestone","dirt","sand","coal","iron_ore","wheat","carrot","potato"}
MAX_COLLECT=64

class PolicyError(ValueError): pass

def decide(req:Dict[str,Any], owner_uuid:str)->Dict[str,Any]:
    if not isinstance(req,dict): raise PolicyError("REQUEST_NOT_OBJECT")
    required={"request_id","actor_uuid","server_scope","command"}
    missing=sorted(required-set(req))
    if missing: raise PolicyError("MISSING_FIELDS:"+",".join(missing))
    if req["actor_uuid"]!=owner_uuid: raise PolicyError("UNTRUSTED_ACTOR")
    if req["server_scope"] not in {"localhost","lan_private","private_server"}: raise PolicyError("PUBLIC_SERVER_REQUIRES_OWNER_REVIEW")
    cmd=str(req["command"])
    if cmd not in ALLOWED: raise PolicyError("COMMAND_NOT_ALLOWED")
    if any(k in req for k in ("shell","code","script","url","file_path","executable","secret")):
        raise PolicyError("FORBIDDEN_INJECTION_SURFACE")
    if cmd in {"find","collect"}:
        resource=req.get("resource")
        if resource not in RESOURCE_ALLOW: raise PolicyError("RESOURCE_NOT_ALLOWED")
    if cmd=="collect":
        qty=req.get("quantity")
        if not isinstance(qty,int) or isinstance(qty,bool) or qty<1 or qty>MAX_COLLECT: raise PolicyError("QUANTITY_OUT_OF_BOUNDS")
    if cmd=="help_build":
        plan=req.get("plan_id")
        if not isinstance(plan,str) or not plan.startswith("approved-build-"): raise PolicyError("BUILD_PLAN_NOT_APPROVED")
    protected={"public_chat","pvp_real_player","grief","exploit","anti_cheat_evasion","install_mod","credential_access"}
    effects=set(map(str,req.get("effects",[]) or []))
    if effects & protected: raise PolicyError("PROTECTED_GAME_EFFECT")
    return {"allow":True,"request_id":req["request_id"],"command":cmd,"receipt_required":True,"postcondition_required":cmd not in {"status","inventory"}}
