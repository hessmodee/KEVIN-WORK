import argparse, json, sys
from datetime import datetime, timezone

ALLOWED_STATUS={"OPEN","RESOLVED","COOLED","RETIRED"}
ALLOWED_CONF={"LOW","MEDIUM","HIGH"}
ALLOWED_FIELDS={
"postmortem_id","mission_id","failure_family","status","symptom","root_cause",
"fix","prevention","evidence","confidence","created_at","review_at","expires_at",
"attempts","materially_distinct_failures","semantic_progress","authority_class"
}
FORBIDDEN_TOKENS=("shell","powershell","cmd.exe","remote_exec","authority_override","permission_change","production_mutation")

def parse_ts(s):
    try:
        dt=datetime.fromisoformat(s.replace("Z","+00:00"))
        if dt.tzinfo is None:
            raise ValueError
        return dt.astimezone(timezone.utc)
    except Exception as e:
        raise ValueError(f"invalid timestamp: {s}") from e

def validate(x):
    if not isinstance(x,dict):
        return False,"postmortem must be object"
    extra=set(x)-ALLOWED_FIELDS
    if extra:
        return False,f"unknown fields: {sorted(extra)}"
    req=ALLOWED_FIELDS-{"expires_at"}
    miss=[k for k in req if k not in x]
    if miss:
        return False,f"missing fields: {sorted(miss)}"
    if x["authority_class"]!="CANDIDATE_ONLY":
        return False,"authority_class must be CANDIDATE_ONLY"
    blob=json.dumps(x,sort_keys=True).lower()
    if any(tok in blob for tok in FORBIDDEN_TOKENS):
        return False,"forbidden authority surface"
    if x["status"] not in ALLOWED_STATUS:
        return False,"invalid status"
    if x["confidence"] not in ALLOWED_CONF:
        return False,"invalid confidence"
    if not isinstance(x["evidence"],list) or not x["evidence"]:
        return False,"evidence required"
    for e in x["evidence"]:
        if not isinstance(e,dict) or set(e)!={"kind","ref","sha256"}:
            return False,"invalid evidence record"
        if not isinstance(e["sha256"],str) or len(e["sha256"])!=64 or any(c not in "0123456789abcdefABCDEF" for c in e["sha256"]):
            return False,"invalid evidence sha256"
    for k in ("symptom","root_cause","fix","prevention"):
        if not isinstance(x[k],str) or not x[k].strip():
            return False,f"{k} required"
    attempts=x["attempts"]
    distinct=x["materially_distinct_failures"]
    if not isinstance(attempts,int) or attempts<1:
        return False,"attempts invalid"
    if not isinstance(distinct,int) or distinct<1 or distinct>attempts:
        return False,"materially_distinct_failures invalid"
    if distinct>=3 and x["status"] not in {"COOLED","RETIRED","RESOLVED"}:
        return False,"third distinct failure must cool, retire, or resolve"
    if x["status"]=="RESOLVED" and x["semantic_progress"] is not True:
        return False,"resolved requires semantic_progress"
    c=parse_ts(x["created_at"])
    r=parse_ts(x["review_at"])
    if r<=c:
        return False,"review_at must be after created_at"
    if "expires_at" in x and x["expires_at"] is not None:
        ex=parse_ts(x["expires_at"])
        if ex<=r:
            return False,"expires_at must be after review_at"
    if x["confidence"]=="HIGH" and len(x["evidence"])<2:
        return False,"HIGH confidence requires at least two evidence records"
    return True,"OK"

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("path")
    a=ap.parse_args()
    x=json.load(open(a.path,encoding="utf-8"))
    ok,msg=validate(x)
    print(("PASS " if ok else "FAIL ")+msg)
    sys.exit(0 if ok else 2)

if __name__=="__main__":
    main()
