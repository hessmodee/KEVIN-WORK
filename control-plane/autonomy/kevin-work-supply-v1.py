#!/usr/bin/env python3
"""Kevin Autonomy Work Supply v1: deterministic, authority-neutral work planner."""
from __future__ import annotations
import argparse, copy, datetime as dt, hashlib, json
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

TERMINAL={"COMPLETE","COMPLETED","CLOSED","PROVEN","OMEN_PROVEN","REPEATEDLY_PROVEN","RESPONSIBILITY_TRANSFERRED","RETIRED","SUPERSEDED"}
PROTECTED={"arbitrary_shell","credential_access","permission_widening","external_send","purchase","financial_transaction","production_chat_send","automatic_promotion","safety_weakening"}
SEVERITY={"critical":5,"high":4,"medium":3,"low":2,"info":1}

def parse_time(v:Any)->Optional[dt.datetime]:
    if not v:return None
    s=str(v).strip()
    if s.endswith("Z"):s=s[:-1]+"+00:00"
    try:x=dt.datetime.fromisoformat(s)
    except ValueError:return None
    if x.tzinfo is None:x=x.replace(tzinfo=dt.timezone.utc)
    return x.astimezone(dt.timezone.utc)

def now_utc(v:Optional[str])->dt.datetime:
    if not v:return dt.datetime.now(dt.timezone.utc)
    x=parse_time(v)
    if x is None:raise ValueError("--now must be ISO-8601")
    return x

def load_json(path:Optional[str], default:Any)->Any:
    if not path or not Path(path).exists():return copy.deepcopy(default)
    return json.loads(Path(path).read_text(encoding="utf-8"))

def recursive_values(node:Any,key:str)->List[Any]:
    out=[]
    if isinstance(node,dict):
        for k,v in node.items():
            if k==key:out.append(v)
            out+=recursive_values(v,key)
    elif isinstance(node,list):
        for v in node:out+=recursive_values(v,key)
    return out

def capabilities(doc:Any)->set[str]:
    out=set()
    if not isinstance(doc,dict):return out
    for v in doc.get("capabilities",[]) or []:
        if isinstance(v,str):out.add(v)
        elif isinstance(v,dict) and v.get("effective") is True and v.get("id"):out.add(str(v["id"]))
    for w in doc.get("workers",[]) or []:
        if isinstance(w,dict) and w.get("effective") is True:
            if w.get("id"):out.add("worker:"+str(w["id"]))
            for c in w.get("capabilities",[]) or []:out.add(str(c))
    return out

def terminal(item:Dict[str,Any])->bool:
    return str(item.get("status","")).upper() in TERMINAL

def cooldown(item:Dict[str,Any],now:dt.datetime)->bool:
    t=parse_time(item.get("cooldown_until") or item.get("not_before"))
    return bool(t and t>now)

def eligible(item:Dict[str,Any],now:dt.datetime)->bool:
    if terminal(item):return False
    if str(item.get("authority_class","")).upper()!="GREEN":return False
    if item.get("blocked") is True or item.get("dependencies_ready") is False:return False
    if cooldown(item,now):return False
    if set(map(str,item.get("effects",[]) or [])) & PROTECTED:return False
    return True

def block_reason(item:Dict[str,Any],now:dt.datetime)->str:
    if terminal(item):return "TERMINAL"
    if str(item.get("authority_class","")).upper()!="GREEN":return "AUTHORITY_NOT_GREEN"
    if set(map(str,item.get("effects",[]) or [])) & PROTECTED:return "PROTECTED_EFFECT_REQUIRES_OWNER"
    if item.get("blocked") is True:return str(item.get("block_reason") or "BLOCKED")
    if item.get("dependencies_ready") is False:return str(item.get("block_reason") or "DEPENDENCY_NOT_READY")
    if cooldown(item,now):return "COOLDOWN"
    return ""

def trigger_due(trigger:Dict[str,Any],ctx:Dict[str,Any],now:dt.datetime)->Tuple[bool,str]:
    kind=str(trigger.get("kind","always")).lower()
    if kind=="always":return True,"STANDING"
    if kind=="report_stale":
        name=str(trigger.get("report","support")); report=ctx.get(name) or {}; age=int(trigger.get("older_than_minutes",15))
        times=[]
        for key in ("at","generated_at","updated_at","refreshed_at","timestamp"):
            for v in recursive_values(report,key):
                x=parse_time(v)
                if x:times.append(x)
        if not times:return True,name.upper()+"_TIMESTAMP_MISSING"
        stale=(now-max(times)).total_seconds()>=age*60
        return stale,(name.upper()+"_STALE" if stale else "FRESH")
    if kind=="field_equals":
        name=str(trigger.get("report","support")); key=str(trigger.get("key","")); want=trigger.get("value")
        return want in recursive_values(ctx.get(name) or {},key),f"{name}:{key}={want}"
    if kind=="skill_manifests_present":
        n=int(ctx.get("skill_manifest_count",0));return n>0,f"SKILL_MANIFESTS={n}"
    raise ValueError("unsupported trigger kind: "+kind)

def skill_ids(root:Optional[str])->List[str]:
    if not root or not Path(root).exists():return []
    out=[]
    for p in sorted(Path(root).glob("*.json")):
        try:d=load_json(str(p),{})
        except Exception:continue
        if isinstance(d,dict) and d.get("id"):
            ver=str(d.get("version","")).strip(); ident=str(d["id"])
            out.append(ident+"@"+ver if ver else ident)
    return out

def synth(spec:Dict[str,Any],caps:set[str],reason:str,now:dt.datetime)->Dict[str,Any]:
    item={"id":spec["id"],"program":spec["program"],"authority_class":"GREEN","status":"READY","lane":spec.get("lane","staging"),
          "work_type":spec.get("work_type","execution"),"severity":spec.get("severity","medium"),"owner_value":int(spec.get("owner_value",3)),
          "dependencies_ready":True,"blocked":False,"failure_attempts":0,"material_new_evidence":True,
          "generated_by":"kevin-work-supply-v1","generated_reason":reason,"acceptance_criteria":list(spec.get("acceptance_criteria",[])),
          "next_action":spec.get("next_action",""),"worker":spec.get("worker","main"),
          "required_capabilities":list(spec.get("required_capabilities",[])),"effects":list(spec.get("effects",[]))}
    if set(map(str,item["effects"])) & PROTECTED:
        item.update(status="BLOCKED",blocked=True,dependencies_ready=False,block_reason="PROTECTED_EFFECT_REQUIRES_OWNER");return item
    missing=sorted(c for c in item["required_capabilities"] if c not in caps)
    if missing:item.update(status="BLOCKED",blocked=True,dependencies_ready=False,block_reason="MISSING_EFFECTIVE_CAPABILITY:"+",".join(missing))
    return item

def pri(x:Dict[str,Any])->tuple:
    return (-int(x.get("owner_value",0)),-SEVERITY.get(str(x.get("severity","")).lower(),0),str(x.get("id","")))

def build_supply(base:Dict[str,Any],catalog:Dict[str,Any],inventory:Dict[str,Any],support:Dict[str,Any],engineering:Dict[str,Any],autonomy:Dict[str,Any],skills:List[str],now:dt.datetime):
    items=[copy.deepcopy(x) for x in base.get("items",[]) or [] if isinstance(x,dict)]
    by_id={str(x["id"]):x for x in items if x.get("id")}; caps=capabilities(inventory)
    ctx={"support":support,"engineering":engineering,"autonomy":autonomy,"skill_manifest_count":len(skills),"skill_manifest_ids":skills}
    generated=[];skipped=[]
    for spec in catalog.get("standing_work",[]) or []:
        sid=str(spec.get("id",""))
        if not sid:continue
        if sid in by_id:
            skipped.append({"id":sid,"reason":"EXISTING_ITEM_NO_ATTEMPT_RESET"});continue
        due,reason=trigger_due(spec.get("trigger",{"kind":"always"}),ctx,now)
        if not due:skipped.append({"id":sid,"reason":reason});continue
        c=synth(spec,caps,reason,now);items.append(c);by_id[sid]=c;generated.append(c)
    active=[x for x in items if not terminal(x)]
    elig=sorted([x for x in active if eligible(x,now)],key=pri)
    blocked=sorted([x for x in active if not eligible(x,now)],key=pri)
    truth="ELIGIBLE_WORK" if elig else ("BLOCKED_WORK_PRESENT" if blocked else "TRUE_IDLE")
    top=None
    if blocked:
        b=blocked[0];top={"id":b.get("id"),"reason":block_reason(b,now),"next_action":b.get("next_action","")}
    state={"schema":1,"kind":"kevin-autonomy-work-supply-state","version":"1.0.1","at":now.isoformat(),"truth_state":truth,
           "authority_effect":"NONE_PLANNER_ONLY","activity_claim_policy":"WORKING_REQUIRES_ACTIVE_LEASE_AND_MACHINE_EVIDENCE",
           "eligible_count":len(elig),"blocked_count":len(blocked),"generated_count":len(generated),"skill_manifest_count":len(skills),
           "effective_capabilities":sorted(caps),"selected_candidate":elig[0].get("id") if elig else None,"top_blocker":top,
           "generated":[{"id":x.get("id"),"status":x.get("status"),"block_reason":x.get("block_reason"),"worker":x.get("worker")} for x in generated],
           "skipped":skipped}
    material={k:v for k,v in state.items() if k not in {"at","fingerprint"}}
    state["fingerprint"]=hashlib.sha256(json.dumps(material,sort_keys=True,separators=(",",":")).encode()).hexdigest().upper()
    merged={"schema":int(base.get("schema",1) or 1),"kind":base.get("kind","kevin-work-items"),
            "safe_for_public_repo":bool(base.get("safe_for_public_repo",True)),"supply_version":"1.0.1","items":items}
    return merged,state

def write(path:Optional[str],value:Any):
    text=json.dumps(value,indent=2)+"\n"
    if path:
        p=Path(path);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding="utf-8")
    else:print(text,end="")

def main()->int:
    a=argparse.ArgumentParser()
    for name,req in [("items",True),("catalog",True),("inventory",False),("support",False),("engineering",False),("autonomy",False),("skills-dir",False),("now",False),("output-items",False),("output-state",False)]:
        a.add_argument("--"+name,required=req)
    x=a.parse_args()
    merged,state=build_supply(load_json(x.items,{"schema":1,"items":[]}),load_json(x.catalog,{"standing_work":[]}),
        load_json(x.inventory,{"capabilities":[]}),load_json(x.support,{}),load_json(x.engineering,{}),load_json(x.autonomy,{}),skill_ids(x.skills_dir),now_utc(x.now))
    if x.output_items:write(x.output_items,merged)
    if x.output_state:write(x.output_state,state)
    if not x.output_items and not x.output_state:write(None,{"state":state,"work_items":merged})
    return 0
if __name__=="__main__":raise SystemExit(main())
