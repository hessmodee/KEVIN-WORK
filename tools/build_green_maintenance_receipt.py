from __future__ import annotations
import hashlib, json
from datetime import datetime, timezone

ALLOWED_ACTIONS={"collect_diagnostics","run_support_bridge","run_benchmark","enable_expected_automation"}
MUTABLE_ACTIONS={"enable_expected_automation"}


def canonical_fingerprint(obj:dict)->str:
    raw=json.dumps(obj,sort_keys=True,separators=(",",":"),ensure_ascii=True).encode("utf-8")
    return hashlib.sha256(raw).hexdigest().upper()


def _aware(v:str)->str:
    d=datetime.fromisoformat(v.replace("Z","+00:00"))
    if d.tzinfo is None or d.utcoffset() is None:
        raise ValueError("timestamp must be timezone-aware")
    return d.astimezone(timezone.utc).isoformat().replace("+00:00","Z")


def build_receipt(observation:dict)->dict:
    allowed={"receipt_id","idempotency_key","action","target","authority_class","started_at","finished_at","precondition","postcondition_check","postcondition_observed","postcondition_verified","evidence","result","rollback_available","rollback_performed","rollback_evidence"}
    if set(observation)!=allowed:
        raise ValueError("observation fields mismatch")
    action=observation["action"]
    if action not in ALLOWED_ACTIONS:
        raise ValueError("action not GREEN allowlisted")
    if observation["authority_class"]!="GREEN":
        raise ValueError("authority class must be GREEN")
    evidence=observation["evidence"]
    if not isinstance(evidence,list) or not evidence or any(not str(x).strip() for x in evidence):
        raise ValueError("evidence required")
    result=observation["result"]
    if result not in {"PASS","FAIL","ROLLED_BACK"}:
        raise ValueError("result invalid")
    required=action in MUTABLE_ACTIONS
    available=bool(observation["rollback_available"])
    performed=bool(observation["rollback_performed"])
    rollback_evidence=str(observation["rollback_evidence"] or "")
    if required and not available:
        raise ValueError("mutable action requires rollback availability")
    if performed and not rollback_evidence.strip():
        raise ValueError("performed rollback requires evidence")
    if result=="ROLLED_BACK" and not performed:
        raise ValueError("ROLLED_BACK requires performed rollback")
    verified=bool(observation["postcondition_verified"])
    if result=="PASS" and not verified:
        raise ValueError("PASS requires verified postcondition")
    if result=="FAIL" and verified:
        raise ValueError("FAIL cannot claim verified postcondition")
    return {
        "schema":1,
        "kind":"kevin-green-maintenance-receipt",
        "receipt_id":str(observation["receipt_id"]),
        "idempotency_key":str(observation["idempotency_key"]),
        "action":action,
        "target":str(observation["target"]),
        "authority_class":"GREEN",
        "started_at":_aware(str(observation["started_at"])),
        "finished_at":_aware(str(observation["finished_at"])),
        "precondition_fingerprint":canonical_fingerprint(observation["precondition"]),
        "postcondition":{
            "verified":verified,
            "check":str(observation["postcondition_check"]),
            "observed":str(observation["postcondition_observed"]),
        },
        "rollback":{
            "required":required,
            "available":available,
            "performed":performed,
            "evidence":rollback_evidence,
        },
        "evidence":[str(x) for x in evidence],
        "result":result,
    }
