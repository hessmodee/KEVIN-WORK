#!/usr/bin/env python3
import importlib.util
from pathlib import Path
HERE=Path(__file__).resolve().parent
SRC=HERE.parent/"control-plane"/"autonomy"/"kevin-work-supply-v1.py"
spec=importlib.util.spec_from_file_location("supply",SRC)
m=importlib.util.module_from_spec(spec);assert spec.loader;spec.loader.exec_module(m)
NOW=m.now_utc("2026-09-04T04:00:00Z")

def empty_items():return {"schema":1,"kind":"kevin-work-items","safe_for_public_repo":True,"items":[]}
def cat(required=None,effects=None,trigger=None,recurrence=None):
    item={"id":"test-work","program":"test","required_capabilities":required or [],"effects":effects or [],"trigger":trigger or {"kind":"always"},"owner_value":5,"severity":"high","next_action":"test"}
    if recurrence:item["recurrence"]=recurrence
    return {"schema":1,"standing_work":[item]}
def run(catalog,inventory=None,items=None,autonomy=None,now=NOW):
    return m.build_supply(items or empty_items(),catalog,inventory or {"capabilities":[]},{},{},autonomy or {},[],now)

def test_eligible_when_capability_effective():
    _,s=run(cat(["safe_tool"]),{"capabilities":["safe_tool"]});assert s["truth_state"]=="ELIGIBLE_WORK";assert s["eligible_count"]==1

def test_missing_capability_is_blocked_not_idle():
    _,s=run(cat(["missing_tool"]));assert s["truth_state"]=="BLOCKED_WORK_PRESENT";assert s["top_blocker"]["reason"].startswith("MISSING_EFFECTIVE_CAPABILITY:")

def test_all_protected_effects_never_auto_eligible():
    expected={
      "arbitrary_shell","credential_access","credential_entry","permission_widening",
      "external_send","email_send","public_post","purchase","financial_transaction","live_crypto_trade",
      "file_delete","destructive_overwrite","software_install","production_chat_send","automatic_promotion","safety_weakening",
      "governance_edit","authority_boundary_change",
      "game_public_server_join","game_public_chat","pvp_real_player"
    }
    assert expected.issubset(m.PROTECTED)
    for effect in sorted(expected):
        _,s=run(cat([], [effect]))
        assert s["truth_state"]=="BLOCKED_WORK_PRESENT", effect
        assert s["top_blocker"]["reason"]=="PROTECTED_EFFECT_REQUIRES_OWNER", effect

def test_existing_blocked_backlog_is_not_true_idle():
    x=empty_items();x["items"].append({"id":"blocked-real-work","program":"test","authority_class":"GREEN","status":"BLOCKED","blocked":True,"dependencies_ready":False,"owner_value":5,"severity":"high","next_action":"install bounded tool"})
    _,s=run({"schema":1,"standing_work":[]},items=x);assert s["truth_state"]=="BLOCKED_WORK_PRESENT";assert s["top_blocker"]["id"]=="blocked-real-work"

def test_true_idle_requires_no_backlog():
    _,s=run({"schema":1,"standing_work":[]});assert s["truth_state"]=="TRUE_IDLE";assert s["eligible_count"]==0;assert s["blocked_count"]==0

def test_existing_item_never_reset():
    x=empty_items();x["items"].append({"id":"test-work","program":"test","authority_class":"GREEN","status":"COMPLETE","dependencies_ready":True,"blocked":False})
    merged,s=run(cat([]),items=x);assert len([i for i in merged["items"] if i["id"]=="test-work"])==1;assert merged["items"][0]["status"]=="COMPLETE";assert s["truth_state"]=="TRUE_IDLE"

def test_recurring_work_does_not_reset_same_occurrence():
    c=cat([],recurrence={"kind":"interval_hours","hours":6})
    merged,s=run(c)
    assert s["generated_count"]==1
    oid=s["generated"][0]["id"]
    merged["items"][0]["status"]="COMPLETE"
    merged2,s2=run(c,items=merged)
    assert s2["generated_count"]==0
    assert len([i for i in merged2["items"] if i["id"]==oid])==1
    assert merged2["items"][0]["status"]=="COMPLETE"

def test_recurring_work_creates_new_future_occurrence_without_reset():
    c=cat([],recurrence={"kind":"interval_hours","hours":6})
    merged,s=run(c)
    first=s["generated"][0]["id"]
    merged["items"][0]["status"]="COMPLETE"
    future=m.now_utc("2026-09-04T10:01:00Z")
    merged2,s2=run(c,items=merged,now=future)
    second=s2["generated"][0]["id"]
    assert first!=second
    assert len(merged2["items"])==2
    assert merged2["items"][0]["status"]=="COMPLETE"
    assert merged2["items"][1]["status"]=="READY"

def test_fingerprint_stable():
    _,a=run(cat(["x"]));_,b=run(cat(["x"]));assert a["fingerprint"]==b["fingerprint"]

def test_stale_autonomy_report_creates_guardian_work():
    trigger={"kind":"report_stale","report":"autonomy","older_than_minutes":30}
    _,s=run(cat(["audit"],trigger=trigger),{"capabilities":["audit"]},autonomy={"generated_at":"2026-09-04T02:00:00Z"})
    assert s["truth_state"]=="ELIGIBLE_WORK";assert s["generated_count"]==1;assert s["generated"][0]["id"]=="test-work"

def test_fresh_autonomy_report_does_not_create_guardian_work():
    trigger={"kind":"report_stale","report":"autonomy","older_than_minutes":30}
    _,s=run(cat(["audit"],trigger=trigger),{"capabilities":["audit"]},autonomy={"generated_at":"2026-09-04T03:50:00Z"})
    assert s["truth_state"]=="TRUE_IDLE";assert s["generated_count"]==0;assert s["skipped"][0]["reason"]=="FRESH"

if __name__=="__main__":
    ts=[v for k,v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in ts:t()
    print(f"KEVIN WORK SUPPLY v1 SELFTEST PASS ({len(ts)} tests)")