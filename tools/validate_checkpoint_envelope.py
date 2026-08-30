import json, sys
from pathlib import Path

STAGES=["admit","plan","build","review","benchmark","complete"]
REQUIRED={"mission_id","run_id","stage","updated_at","input_fingerprint","evidence_fingerprints","budget","failure_family","failure_attempts","next_action","semantic_completion","operation_receipts","worker_slot"}

def validate(obj):
    if set(obj)!=REQUIRED: raise ValueError("fields")
    if obj["stage"] not in STAGES: raise ValueError("stage")
    if obj["worker_slot"]!="14b-primary": raise ValueError("worker_slot")
    if len(str(obj["input_fingerprint"]))!=64: raise ValueError("input_fingerprint")
    a=obj["failure_attempts"]
    if not isinstance(a,int) or a<0 or a>3: raise ValueError("failure_attempts")
    if a and not str(obj["failure_family"]).strip(): raise ValueError("failure_family")
    b=obj["budget"]
    if set(b)!={"calls_used","calls_limit","seconds_used","seconds_limit"}: raise ValueError("budget")
    if b["calls_used"]>b["calls_limit"] or b["seconds_used"]>b["seconds_limit"]: raise ValueError("budget_exceeded")
    receipts=obj["operation_receipts"]
    keys=[r["idempotency_key"] for r in receipts]
    if len(keys)!=len(set(keys)): raise ValueError("replay")
    sc=obj["semantic_completion"]
    if obj["stage"]=="complete" and not sc.get("criteria_met"): raise ValueError("semantic_completion")
    return True

if __name__=="__main__":
    validate(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")))
    print("CHECKPOINT_ENVELOPE_VALID")
