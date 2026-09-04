#!/usr/bin/env python3
import importlib.util
from pathlib import Path
HERE=Path(__file__).resolve().parent
SRC=HERE.parent/"control-plane"/"autonomy"/"kevin-work-supply-v1.py"
spec=importlib.util.spec_from_file_location("supply",SRC)
m=importlib.util.module_from_spec(spec);assert spec.loader;spec.loader.exec_module(m)
NOW=m.now_utc("2026-09-04T04:00:00Z")

def empty_items():return {"schema":1,"kind":"kevin-work-items","safe_for_public_repo":True,"items":[]}
def cat(required=None,effects=None):
    return {"schema":1,"standing_work":[{"id":"test-work","program":"test","required_capabilities":required or [],"effects":effects or [],"trigger":{"kind":"always"},"owner_value":5,"severity":"high","next_action":"test"}]}
def run(catalog,inventory=None,items=None):
    return m.build_supply(items or empty_items(),catalog,inventory or {"capabilities":[]},{},{},[],NOW)

def test_eligible_when_capability_effective():
    _,s=run(cat(["safe_tool"]),{"capabilities":["safe_tool"]});assert s["truth_state"]=="ELIGIBLE_WORK";assert s["eligible_count"]==1

def test_missing_capability_is_blocked_not_idle():
    _,s=run(cat(["missing_tool"]));assert s["truth_state"]=="BLOCKED_WORK_PRESENT";assert s["top_blocker"]["reason"].startswith("MISSING_EFFECTIVE_CAPABILITY:")

def test_protected_effect_never_auto_eligible():
    _,s=run(cat([], ["arbitrary_shell"]));assert s["truth_state"]=="BLOCKED_WORK_PRESENT";assert s["top_blocker"]["reason"]=="PROTECTED_EFFECT_REQUIRES_OWNER"

def test_existing_blocked_backlog_is_not_true_idle():
    x=empty_items();x["items"].append({"id":"blocked-real-work","program":"test","authority_class":"GREEN","status":"BLOCKED","blocked":True,"dependencies_ready":False,"owner_value":5,"severity":"high","next_action":"install bounded tool"})
    _,s=run({"schema":1,"standing_work":[]},items=x);assert s["truth_state"]=="BLOCKED_WORK_PRESENT";assert s["top_blocker"]["id"]=="blocked-real-work"

def test_true_idle_requires_no_backlog():
    _,s=run({"schema":1,"standing_work":[]});assert s["truth_state"]=="TRUE_IDLE";assert s["eligible_count"]==0;assert s["blocked_count"]==0

def test_existing_item_never_reset():
    x=empty_items();x["items"].append({"id":"test-work","program":"test","authority_class":"GREEN","status":"COMPLETE","dependencies_ready":True,"blocked":False})
    merged,s=run(cat([]),items=x);assert len([i for i in merged["items"] if i["id"]=="test-work"])==1;assert merged["items"][0]["status"]=="COMPLETE";assert s["truth_state"]=="TRUE_IDLE"

def test_fingerprint_stable():
    _,a=run(cat(["x"]));_,b=run(cat(["x"]));assert a["fingerprint"]==b["fingerprint"]

if __name__=="__main__":
    ts=[v for k,v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in ts:t()
    print(f"KEVIN WORK SUPPLY v1 SELFTEST PASS ({len(ts)} tests)")
