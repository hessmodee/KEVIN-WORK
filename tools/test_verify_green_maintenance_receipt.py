from copy import deepcopy
from verify_green_maintenance_receipt import verify

BASE={
 "schema":1,"kind":"kevin-green-maintenance-receipt","receipt_id":"receipt-0001","idempotency_key":"idem-00000001","action":"run_benchmark","target":"kevin-benchmark-v1","authority_class":"GREEN",
 "started_at":"2026-08-30T02:00:00-06:00","finished_at":"2026-08-30T02:01:00-06:00","precondition_fingerprint":"A"*64,
 "postcondition":{"verified":True,"check":"benchmark terminal history PASS","observed":"30/30 PASS; critical_failures=0"},
 "rollback":{"required":False,"available":False,"performed":False,"evidence":""},"evidence":["support snapshot after action","benchmark terminal history"],"result":"PASS"
}

def reject(name,mutate):
    x=deepcopy(BASE); mutate(x); errs=verify(x); assert errs, name

def test_all():
    assert verify(deepcopy(BASE))==[]
    reject("authority",lambda x:x.__setitem__("authority_class","RED"))
    reject("action",lambda x:x.__setitem__("action","powershell"))
    reject("fingerprint",lambda x:x.__setitem__("precondition_fingerprint","bad"))
    reject("pass_without_postcondition",lambda x:x["postcondition"].__setitem__("verified",False))
    reject("rollback_unavailable",lambda x:x["rollback"].update(required=True,available=False))
    reject("rolled_back_without_performed",lambda x:x.update(result="ROLLED_BACK"))
    reject("rollback_no_evidence",lambda x:(x.update(result="ROLLED_BACK"),x["rollback"].update(required=True,available=True,performed=True,evidence="")))
    reject("fail_claims_verified",lambda x:x.update(result="FAIL"))
    reject("time_order",lambda x:x.update(finished_at="2026-08-30T01:59:00-06:00"))
    reject("missing_evidence",lambda x:x.__setitem__("evidence",[]))
    reject("extra_field",lambda x:x.__setitem__("command","rm -rf /"))
    print("PASS 12 GREEN receipt contract cases")

if __name__=="__main__": test_all()
