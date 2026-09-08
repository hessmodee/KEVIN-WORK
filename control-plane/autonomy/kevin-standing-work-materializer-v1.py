#!/usr/bin/env python3
from __future__ import annotations
import argparse, datetime as dt, json, re
from pathlib import Path
from typing import Any
UTC=dt.timezone.utc
ID_RE=re.compile(r"^[a-z0-9][a-z0-9._-]{2,96}$")
ALLOWED_SELECTOR_LANES={"production","staging","research","skill-lab"}
LANE_MAP={"guardian":"research"}
class ContractError(ValueError): pass
def require(ok: bool,msg: str)->None:
    if not ok: raise ContractError(msg)
def parse_time(value: str)->dt.datetime:
    parsed=dt.datetime.fromisoformat(str(value).replace("Z","+00:00"))
    require(parsed.tzinfo is not None,"time must be timezone-aware")
    return parsed.astimezone(UTC)
def load(path: str)->dict[str,Any]:
    value=json.loads(Path(path).read_text(encoding="utf-8"))
    require(isinstance(value,dict),f"{path}: expected object")
    return value
def slot_for(now: dt.datetime,hours: int):
    require(1<=hours<=168,"recurrence hours outside 1..168")
    epoch_hours=int(now.timestamp()//3600)
    start_hour=(epoch_hours//hours)*hours
    start=dt.datetime.fromtimestamp(start_hour*3600,tz=UTC)
    end=start+dt.timedelta(hours=hours)
    return start.strftime("%Y%m%dt%H00z").lower(),start,end
def safe_id(parent: str,suffix: str)->str:
    iid=f"{parent}--{suffix}".lower()
    require(bool(ID_RE.fullmatch(iid)),f"generated id invalid: {iid}")
    return iid
def validate_catalog(catalog):
    require(catalog.get("schema")==1,"catalog schema must be 1")
    require(catalog.get("kind")=="kevin-standing-work-supply-catalog","catalog kind mismatch")
    require(catalog.get("authority_effect")=="NONE","catalog authority effect must be NONE")
    deny=set(map(str,(catalog.get("policy") or {}).get("never_auto_authorize") or []))
    require({"arbitrary_shell","purchase","credential_access"}.issubset(deny),"core protected effects missing")
    require(isinstance(catalog.get("standing_work"),list) and catalog["standing_work"],"standing_work cannot be empty")
def validate_items(items):
    require(items.get("schema")==1,"items schema must be 1")
    require(items.get("kind")=="kevin-work-items","items kind mismatch")
    require(isinstance(items.get("items"),list),"items must be list")
def materialize(catalog,current,now,max_new=8):
    validate_catalog(catalog); validate_items(current); require(1<=max_new<=32,"max_new outside 1..32")
    deny=set(map(str,catalog["policy"]["never_auto_authorize"]))
    existing=list(current["items"])
    seen={str(x.get("id","")) for x in existing if isinstance(x,dict)}
    emitted=[]; skipped=[]
    for raw in catalog["standing_work"]:
        require(isinstance(raw,dict),"standing work row must be object")
        parent=str(raw.get("id","")).strip().lower()
        require(bool(ID_RE.fullmatch(parent)),f"standing id invalid: {parent}")
        effects=set(map(str,raw.get("effects") or []))
        if effects & deny: raise ContractError(f"standing item {parent} contains protected effect")
        trigger=raw.get("trigger") or {}
        trigger_kind=str(trigger.get("kind",""))
        if trigger_kind!="always":
            skipped.append({"id":parent,"reason":"EVIDENCE_TRIGGER_REQUIRES_FACT_ADAPTER"}); continue
        recurrence=raw.get("recurrence")
        if recurrence:
            require(recurrence.get("kind")=="interval_hours",f"{parent}: unsupported recurrence")
            label,start,end=slot_for(now,int(recurrence.get("hours",0)))
            iid=safe_id(parent,"slot-"+label)
            slot_note=(f"Scheduled recurrence slot {start.isoformat().replace('+00:00','Z')} through "
                       f"{end.isoformat().replace('+00:00','Z')}; this is a new due instance of the "
                       "standing parent, not a rename or retry-budget reset.")
        else:
            label="standing"; iid=safe_id(parent,label)
            slot_note="One standing instance; duplicate materialization is forbidden."
        if iid in seen:
            skipped.append({"id":parent,"reason":"INSTANCE_ALREADY_PRESENT"}); continue
        if len(emitted)>=max_new:
            skipped.append({"id":parent,"reason":"MAX_NEW_REACHED"}); continue
        source_lane=str(raw.get("lane","")).lower()
        lane=LANE_MAP.get(source_lane,source_lane)
        require(lane in ALLOWED_SELECTOR_LANES,f"{parent}: selector lane unsupported")
        criteria=[str(x).strip() for x in raw.get("acceptance_criteria") or [] if str(x).strip()]
        require(criteria,f"{parent}: acceptance criteria required")
        item={
          "id":iid,"standing_parent_id":parent,"standing_due_slot":label,
          "program":str(raw.get("program","")),"authority_class":"GREEN","status":"OPEN",
          "lane":lane,"source_lane":source_lane,"work_type":str(raw.get("work_type","verification")).lower(),
          "severity":str(raw.get("severity","medium")),"owner_value":int(raw.get("owner_value",3)),
          "worker":str(raw.get("worker","")),"required_capabilities":list(raw.get("required_capabilities") or []),
          "dependencies_ready":True,"blocked":False,"failure_attempts":0,"material_new_evidence":True,
          "effects":list(raw.get("effects") or []),"acceptance_criteria":criteria+[slot_note],
          "next_action":str(raw.get("next_action","")),"standing_trigger":trigger,
          "standing_recurrence":recurrence,"downstream_consumer":"KEVIN_STANDING_PROGRAM_AND_OWNER_VALUE_PORTFOLIO"
        }
        require(item["next_action"],f"{parent}: next_action required")
        emitted.append(item); seen.add(iid)
    out=dict(current); out["items"]=existing+emitted
    out["materialization"]={"schema":1,"kind":"kevin-standing-work-materialization",
       "generated_at":now.isoformat().replace("+00:00","Z"),"authority_effect":"NONE_ADMISSION_ONLY",
       "history_preserved":True,"new_count":len(emitted),"new_ids":[x["id"] for x in emitted],"skipped":skipped}
    return out
def selftest():
    cat={"schema":1,"kind":"kevin-standing-work-supply-catalog","authority_effect":"NONE",
      "policy":{"never_auto_authorize":["arbitrary_shell","purchase","credential_access","external_send"]},
      "standing_work":[{"id":"platform-self-heal-watch-v1","program":"self-heal","lane":"guardian",
      "work_type":"verification","owner_value":5,"worker":"guardian","required_capabilities":["kevin_system_status"],
      "effects":[],"trigger":{"kind":"always"},"recurrence":{"kind":"interval_hours","hours":2},
      "acceptance_criteria":["Inspect fresh runtime truth."],"next_action":"Inspect runtime truth."}]}
    cur={"schema":1,"kind":"kevin-work-items","items":[{"id":"existing-owner-item","status":"OPEN"}]}
    t=parse_time("2026-09-07T18:30:00Z")
    a=materialize(cat,cur,t)
    require(len(a["items"])==2,"one due item expected")
    n=a["items"][1]
    require(n["id"]=="platform-self-heal-watch-v1--slot-20260907t1800z","slot mismatch")
    require(n["lane"]=="research" and n["source_lane"]=="guardian","lane mapping failed")
    require(a["items"][0]["id"]=="existing-owner-item","existing work changed")
    b=materialize(cat,a,parse_time("2026-09-07T19:59:59Z"))
    require(len(b["items"])==2 and b["materialization"]["new_count"]==0,"same slot duplicated")
    c=materialize(cat,a,parse_time("2026-09-07T20:00:01Z"))
    require(c["materialization"]["new_count"]==1,"next slot missing")
    bad=json.loads(json.dumps(cat)); bad["standing_work"][0]["effects"]=["purchase"]
    try: materialize(bad,cur,t)
    except ContractError: pass
    else: raise AssertionError("protected effect materialized")
    ev=json.loads(json.dumps(cat)); ev["standing_work"][0]["trigger"]={"kind":"report_stale"}
    d=materialize(ev,cur,t)
    require(d["materialization"]["new_count"]==0,"evidence trigger did not fail closed")
    print("KEVIN STANDING WORK MATERIALIZER v1 SELFTEST PASS recurrence_slots=true history_preserved=true protected_effects=blocked guardian_safe_lane=true evidence_triggers=fail_closed authority_effect=none")
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--catalog"); ap.add_argument("--items"); ap.add_argument("--now"); ap.add_argument("--output"); ap.add_argument("--max-new",type=int,default=8); ap.add_argument("--selftest",action="store_true")
    a=ap.parse_args()
    if a.selftest: selftest(); return 0
    require(a.catalog and a.items and a.now and a.output,"catalog/items/now/output required")
    out=materialize(load(a.catalog),load(a.items),parse_time(a.now),a.max_new)
    p=Path(a.output); p.parent.mkdir(parents=True,exist_ok=True); p.write_text(json.dumps(out,indent=2)+"\n",encoding="utf-8"); return 0
if __name__=="__main__": raise SystemExit(main())
