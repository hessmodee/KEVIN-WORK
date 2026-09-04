#!/usr/bin/env python3
import importlib.util
from pathlib import Path
SRC=Path(__file__).resolve().parent.parent/"control-plane"/"game"/"minecraft-companion-policy-v1.py"
spec=importlib.util.spec_from_file_location("mc",SRC);m=importlib.util.module_from_spec(spec);assert spec.loader;spec.loader.exec_module(m)
OWNER="owner-uuid"

def base(command="status"):
    return {"request_id":"r1","actor_uuid":OWNER,"server_scope":"localhost","command":command,"effects":[]}
def fail(d,code):
    try:m.decide(d,OWNER)
    except m.PolicyError as e:assert str(e)==code,(str(e),code);return
    raise AssertionError("expected "+code)

def test_owner_private_status_allowed():assert m.decide(base())["allow"]
def test_other_player_cannot_command():
    d=base();d["actor_uuid"]="other";fail(d,"UNTRUSTED_ACTOR")
def test_public_server_fails_closed():
    d=base();d["server_scope"]="public";fail(d,"PUBLIC_SERVER_REQUIRES_OWNER_REVIEW")
def test_unknown_command_rejected():fail(base("mine_everything"),"COMMAND_NOT_ALLOWED")
def test_injection_fields_rejected():
    for field in ("shell","code","script","url","file_path","executable","secret"):
        d=base();d[field]="x";fail(d,"FORBIDDEN_INJECTION_SURFACE")
def test_collect_bounded():
    d=base("collect");d.update(resource="oak_log",quantity=32);assert m.decide(d,OWNER)["allow"]
    d["quantity"]=65;fail(d,"QUANTITY_OUT_OF_BOUNDS")
def test_resource_allowlist():
    d=base("find");d["resource"]="diamond_block";fail(d,"RESOURCE_NOT_ALLOWED")
def test_build_requires_reviewed_plan():
    d=base("help_build");d["plan_id"]="random";fail(d,"BUILD_PLAN_NOT_APPROVED")
    d["plan_id"]="approved-build-small-shed-1";assert m.decide(d,OWNER)["allow"]
def test_protected_game_effects():
    for effect in ("public_chat","pvp_real_player","grief","exploit","anti_cheat_evasion","install_mod","credential_access"):
        d=base();d["effects"]=[effect];fail(d,"PROTECTED_GAME_EFFECT")

if __name__=="__main__":
    tests=[v for k,v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:t()
    print(f"MINECRAFT COMPANION POLICY v1 SELFTEST PASS ({len(tests)} tests)")
