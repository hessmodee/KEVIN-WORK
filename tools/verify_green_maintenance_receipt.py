from __future__ import annotations
import json, re, sys
from datetime import datetime, timezone

ALLOWED_ACTIONS={"collect_diagnostics","run_support_bridge","run_benchmark","enable_expected_automation"}
HEX64=re.compile(r"^[A-Fa-f0-9]{64}$")
ID=re.compile(r"^[A-Za-z0-9._-]{8,140}$")

def parse_time(v:str)->datetime:
    d=datetime.fromisoformat(v.replace("Z","+00:00"))
    if d.tzinfo is None or d.utcoffset() is None: raise ValueError("timestamp must be timezone-aware")
    return d.astimezone(timezone.utc)

def verify(r:dict)->list[str]:
    e=[]
    allowed={"schema","kind","receipt_id","idempotency_key","action","target","authority_class","started_at","finished_at","precondition_fingerprint","postcondition","rollback","evidence","result"}
    if set(r)!=allowed: e.append("receipt fields mismatch")
    if r.get("schema")!=1 or r.get("kind")!="kevin-green-maintenance-receipt": e.append("schema/kind mismatch")
    if not ID.fullmatch(str(r.get("receipt_id",""))) or not ID.fullmatch(str(r.get("idempotency_key",""))): e.append("id format invalid")
    if r.get("action") not in ALLOWED_ACTIONS: e.append("action not GREEN allowlisted")
    if r.get("authority_class")!="GREEN": e.append("authority class must be GREEN")
    if not HEX64.fullmatch(str(r.get("precondition_fingerprint",""))): e.append("precondition fingerprint invalid")
    try:
        if parse_time(str(r.get("finished_at",""))) < parse_time(str(r.get("started_at",""))): e.append("finished_at precedes started_at")
    except Exception: e.append("timestamp invalid")
    p=r.get("postcondition") or {}; rb=r.get("rollback") or {}; result=r.get("result")
    if set(p)!={"verified","check","observed"} or not isinstance(p.get("verified"),bool) or not str(p.get("check","")).strip() or not str(p.get("observed","")).strip(): e.append("postcondition contract invalid")
    if set(rb)!={"required","available","performed","evidence"} or any(not isinstance(rb.get(k),bool) for k in ("required","available","performed")): e.append("rollback contract invalid")
    evidence=r.get("evidence");
    if not isinstance(evidence,list) or not evidence or any(not str(x).strip() for x in evidence): e.append("evidence required")
    if result not in {"PASS","FAIL","ROLLED_BACK"}: e.append("result invalid")
    if result=="PASS" and not p.get("verified"): e.append("PASS requires independently verified postcondition")
    if rb.get("required") and not rb.get("available"): e.append("mutable action requiring rollback must declare rollback available")
    if result=="ROLLED_BACK" and not rb.get("performed"): e.append("ROLLED_BACK requires rollback.performed=true")
    if rb.get("performed") and not str(rb.get("evidence","")).strip(): e.append("performed rollback requires evidence")
    if result=="FAIL" and p.get("verified"): e.append("FAIL cannot claim verified postcondition")
    return e

def main(path:str)->int:
    r=json.load(open(path,encoding="utf-8")); errors=verify(r)
    print(json.dumps({"ok":not errors,"errors":errors},sort_keys=True))
    return 0 if not errors else 2

if __name__=="__main__":
    if len(sys.argv)!=2: raise SystemExit("usage: verify_green_maintenance_receipt.py RECEIPT.json")
    raise SystemExit(main(sys.argv[1]))
