import json, sys
from datetime import datetime, timezone
from pathlib import Path

REQUIRED={"mission_id","stage_id","owner","next_owner","input_refs","source_refs","artifact_refs","trust_level","technical_success","semantic_success","claims","assumptions","unknowns","freshness","output_schema_version","budget","approval_class","checkpoint_ref","rejection_reason"}
GRADES={"A","B","C","UNVERIFIED"}
APPROVAL={"GREEN","YELLOW","RED"}
TRUST={"RAW","PARSED","CORROBORATED","FACT_CANDIDATE","AUTHORITATIVE"}

def _dt(v):
    d=datetime.fromisoformat(str(v).replace("Z","+00:00"))
    if d.tzinfo is None or d.utcoffset() is None: raise ValueError("timezone_required")
    return d.astimezone(timezone.utc)

def _nonempty_list(v, name):
    if not isinstance(v,list) or not v or any(not str(x).strip() for x in v):
        raise ValueError(name)

def validate(obj, now=None):
    if set(obj)!=REQUIRED: raise ValueError("fields")
    if not str(obj["mission_id"]).strip() or not str(obj["stage_id"]).strip(): raise ValueError("identity")
    if not str(obj["owner"]).strip() or not str(obj["next_owner"]).strip(): raise ValueError("ownership")
    if obj["approval_class"] not in APPROVAL: raise ValueError("approval_class")
    if obj["trust_level"] not in TRUST: raise ValueError("trust_level")
    if not isinstance(obj["technical_success"],bool) or not isinstance(obj["semantic_success"],bool): raise ValueError("success_type")
    _nonempty_list(obj["input_refs"],"input_refs")
    _nonempty_list(obj["artifact_refs"],"artifact_refs")

    b=obj["budget"]
    if set(b)!={"calls_used","calls_limit","seconds_used","seconds_limit"}: raise ValueError("budget")
    for k in b:
        if not isinstance(b[k],int) or b[k]<0: raise ValueError("budget_value")
    if b["calls_used"]>b["calls_limit"] or b["seconds_used"]>b["seconds_limit"]: raise ValueError("budget_exceeded")

    f=obj["freshness"]
    if set(f)!={"evaluated_at","stale_after","freshness_required"}: raise ValueError("freshness")
    evaluated=_dt(f["evaluated_at"])
    current=_dt(now) if isinstance(now,str) else (now.astimezone(timezone.utc) if now and now.tzinfo else (now.replace(tzinfo=timezone.utc) if now else datetime.now(timezone.utc)))
    stale_after=_dt(f["stale_after"]) if f["stale_after"] else None
    if evaluated > current: raise ValueError("evaluated_at_in_future")
    if f["freshness_required"] and stale_after is None: raise ValueError("stale_after_required")

    sources=obj["source_refs"]
    if not isinstance(sources,list) or not sources: raise ValueError("source_refs")
    source_ids=set()
    for s in sources:
        if not isinstance(s,dict) or set(s)!={"source_id","kind","fingerprint"}: raise ValueError("source_ref_fields")
        sid=str(s["source_id"]).strip()
        fp=str(s["fingerprint"]).strip()
        if not sid or sid in source_ids: raise ValueError("source_id")
        if len(fp)!=64 or any(c not in "0123456789abcdefABCDEF" for c in fp): raise ValueError("source_fingerprint")
        source_ids.add(sid)

    claims=obj["claims"]
    if not isinstance(claims,list): raise ValueError("claims")
    for c in claims:
        if set(c)!={"claim","consequential","evidence_grade","source_ids"}: raise ValueError("claim_fields")
        if not str(c["claim"]).strip(): raise ValueError("claim")
        if not isinstance(c["consequential"],bool): raise ValueError("claim_consequential")
        if c["evidence_grade"] not in GRADES: raise ValueError("evidence_grade")
        refs=c["source_ids"]
        if not isinstance(refs,list): raise ValueError("claim_sources")
        if c["consequential"] and not refs: raise ValueError("unsupported_consequential_claim")
        if any(r not in source_ids for r in refs): raise ValueError("unknown_source_ref")
        if c["consequential"] and c["evidence_grade"]=="UNVERIFIED": raise ValueError("unverified_consequential_claim")

    if obj["semantic_success"]:
        if not obj["technical_success"]: raise ValueError("semantic_without_technical")
        if not claims: raise ValueError("empty_semantic_output")
        if obj["trust_level"] in {"RAW","PARSED"}: raise ValueError("semantic_success_requires_corrob_or_better")
        if f["freshness_required"] and stale_after <= current: raise ValueError("stale_semantic_output")
    if not obj["semantic_success"] and not str(obj["rejection_reason"]).strip(): raise ValueError("rejection_reason_required")
    if obj["semantic_success"] and str(obj["rejection_reason"]).strip(): raise ValueError("rejection_reason_on_success")
    return True

if __name__=="__main__":
    validate(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")))
    print("HANDOFF_ENVELOPE_V2_VALID")
