#!/usr/bin/env python3
"""Kevin Incident/Reflection v1.

Authority-neutral recorder for the self-repair flywheel. It never executes a repair,
changes authority, or claims an outcome. It validates evidence-bearing incident
records, emits a durable lesson/dependency-retirement artifact, and recommends a
preventative control after repeated proven repairs of the same failure family.
"""
from __future__ import annotations
import argparse, datetime as dt, hashlib, json, re
from pathlib import Path
from typing import Any, Dict, List

ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,96}$")
SHA_RE = re.compile(r"^[A-F0-9]{64}$")
PROTECTED_EFFECTS = {
    "arbitrary_shell","credential_access","credential_entry","permission_widening",
    "external_send","email_send","public_post","purchase","financial_transaction",
    "live_crypto_trade","destructive_overwrite","file_delete","software_install",
    "automatic_promotion","safety_weakening","governance_edit","authority_boundary_change"
}
PROVEN = {"PROVEN","OMEN_PROVEN","REPEATEDLY_PROVEN","COMPLETE","COMPLETED"}


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def load(path: str, default: Any) -> Any:
    p=Path(path)
    if not p.exists(): return default
    return json.loads(p.read_text(encoding="utf-8"))


def write(path: str, value: Any) -> None:
    p=Path(path); p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(value,indent=2,sort_keys=False)+"\n",encoding="utf-8")


def text_sha(value: Any) -> str:
    return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode()).hexdigest().upper()


def require(cond: bool, message: str) -> None:
    if not cond: raise ValueError(message)


def validate_evidence(rows: Any, label: str) -> List[Dict[str,Any]]:
    require(isinstance(rows,list) and rows, f"{label} evidence required")
    out=[]
    for row in rows:
        require(isinstance(row,dict), f"{label} evidence row invalid")
        source=str(row.get("source","")).strip()
        require(source and len(source)<=300, f"{label} evidence source invalid")
        sha=str(row.get("sha256","")).upper().strip()
        if sha: require(bool(SHA_RE.fullmatch(sha)), f"{label} evidence sha256 invalid")
        out.append({"source":source,"sha256":sha or None,"claim":str(row.get("claim",""))[:500]})
    return out


def validate(doc: Dict[str,Any]) -> None:
    require(int(doc.get("schema",0))==1,"schema must be 1")
    require(doc.get("kind")=="kevin-incident-reflection-input","kind mismatch")
    for key in ("incident_id","failure_family","objective_id"):
        require(bool(ID_RE.fullmatch(str(doc.get(key,"")))),f"{key} invalid")
    require(str(doc.get("observed_failure","")).strip()!="","observed_failure required")
    validate_evidence(doc.get("evidence"),"incident")
    hyps=doc.get("hypotheses")
    require(isinstance(hyps,list) and len(hyps)>=2,"at least two competing hypotheses required")
    ids=set()
    for h in hyps:
        require(isinstance(h,dict),"hypothesis invalid")
        hid=str(h.get("id","")); require(bool(ID_RE.fullmatch(hid)),"hypothesis id invalid")
        require(hid not in ids,"duplicate hypothesis id"); ids.add(hid)
        require(str(h.get("statement","")).strip()!="","hypothesis statement required")
    repair=doc.get("candidate_repair") or {}
    require(repair.get("authority_class")=="GREEN","candidate repair must remain GREEN")
    require(repair.get("authority_delta")=="NONE","candidate repair authority_delta must be NONE")
    require(repair.get("production_effect")=="NONE","candidate repair production_effect must be NONE")
    effects=set(map(str,repair.get("effects",[]) or []))
    require(not effects.intersection(PROTECTED_EFFECTS),"candidate repair contains protected effect")
    require(str(repair.get("rollback_plan","")).strip()!="","rollback_plan required")
    tests=doc.get("tests") or {}
    for key in ("positive","negative","regression"):
        require(isinstance(tests.get(key),list) and tests[key],f"{key} tests required")
    verifier=doc.get("independent_verifier") or {}
    require(verifier.get("independent") is True,"independent verifier required")
    require(str(verifier.get("status","")) in {"PENDING","PASS","FAIL"},"verifier status invalid")
    resume=doc.get("resume") or {}
    require(bool(ID_RE.fullmatch(str(resume.get("work_item_id","")))),"resume work_item_id invalid")
    require(str(resume.get("next_action","")).strip()!="","resume next_action required")


def family_proven_count(ledger: Dict[str,Any], family: str) -> int:
    n=0
    for row in ledger.get("incidents",[]) or []:
        if isinstance(row,dict) and row.get("failure_family")==family and str(row.get("repair_status","")) in PROVEN:
            n+=1
    return n


def build(doc: Dict[str,Any], ledger: Dict[str,Any], at: str) -> Dict[str,Any]:
    validate(doc)
    family=str(doc["failure_family"])
    verifier=doc["independent_verifier"]
    promotion=doc.get("promotion") or {"status":"NOT_PROMOTED"}
    repair_status=str(promotion.get("status","NOT_PROMOTED"))
    prior=family_proven_count(ledger,family)
    this_proven=(repair_status in PROVEN and verifier.get("status")=="PASS")
    proven_after=prior+(1 if this_proven else 0)
    ext=doc.get("external_intervention") or {"required":False,"actor":"kevin"}
    dependency=None
    if bool(ext.get("required")) and str(ext.get("actor","kevin")).lower() not in {"kevin","self"}:
        retirement=doc.get("dependency_retirement") or {}
        require(str(retirement.get("artifact_type","")).strip()!="","outside intervention requires dependency-retirement artifact_type")
        require(str(retirement.get("artifact_pointer","")).strip()!="","outside intervention requires dependency-retirement artifact_pointer")
        require(str(retirement.get("repeat_strategy","")).strip()!="","outside intervention requires repeat_strategy")
        dependency={
            "outside_actor":str(ext.get("actor"))[:80],
            "why_needed":str(ext.get("reason",""))[:500],
            "artifact_type":str(retirement["artifact_type"])[:80],
            "artifact_pointer":str(retirement["artifact_pointer"])[:300],
            "repeat_strategy":str(retirement["repeat_strategy"])[:800],
            "target":"same failure family should be diagnosable/recoverable by Kevin without this outside actor"
        }
    record={
        "schema":1,"kind":"kevin-incident-reflection","version":"1.0.0","at":at,
        "incident_id":doc["incident_id"],"failure_family":family,"objective_id":doc["objective_id"],
        "observed_failure":str(doc["observed_failure"])[:1200],
        "evidence":validate_evidence(doc["evidence"],"incident"),
        "hypotheses":doc["hypotheses"],"candidate_repair":doc["candidate_repair"],"tests":doc["tests"],
        "independent_verifier":verifier,"promotion":promotion,"repair_status":repair_status,
        "lesson":doc.get("lesson",{}),"resume":doc["resume"],
        "dependency_retirement":dependency,
        "same_family_proven_repairs_before":prior,"same_family_proven_repairs_after":proven_after,
        "preventative_control_required":proven_after>=2,
        "preventative_control":({
            "required":True,
            "reason":"same failure family has at least two independently verified repairs",
            "next_action":"Create or strengthen a regression test/watchdog/preflight that detects this failure before owner work is lost."
        } if proven_after>=2 else {"required":False}),
        "authority_effect":"NONE_RECORDER_ONLY",
        "truth_boundary":"This record proves only the supplied evidence/verification state. It cannot execute, promote, or claim a repair by itself."
    }
    record["fingerprint"]=text_sha({k:v for k,v in record.items() if k not in {"at","fingerprint"}})
    return record


def append_ledger(ledger: Dict[str,Any], record: Dict[str,Any]) -> Dict[str,Any]:
    rows=[x for x in (ledger.get("incidents",[]) or []) if isinstance(x,dict) and x.get("incident_id")!=record["incident_id"]]
    rows.append({
        "incident_id":record["incident_id"],"failure_family":record["failure_family"],
        "repair_status":record["repair_status"],"verifier_status":record["independent_verifier"]["status"],
        "fingerprint":record["fingerprint"],"at":record["at"],
        "dependency_retirement":record["dependency_retirement"],
        "preventative_control_required":record["preventative_control_required"]
    })
    return {"schema":1,"kind":"kevin-incident-ledger","version":"1.0.0","incidents":rows}


def main()->int:
    p=argparse.ArgumentParser()
    p.add_argument("--input",required=True);p.add_argument("--ledger",required=True)
    p.add_argument("--output-record",required=True);p.add_argument("--output-ledger",required=True)
    p.add_argument("--now")
    a=p.parse_args(); doc=load(a.input,{}) ; ledger=load(a.ledger,{"schema":1,"incidents":[]})
    record=build(doc,ledger,a.now or utc_now()); next_ledger=append_ledger(ledger,record)
    write(a.output_record,record);write(a.output_ledger,next_ledger)
    print(json.dumps({"status":"RECORDED","incident_id":record["incident_id"],"preventative_control_required":record["preventative_control_required"],"fingerprint":record["fingerprint"]}))
    return 0

if __name__=="__main__": raise SystemExit(main())
