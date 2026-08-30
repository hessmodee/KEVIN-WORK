#!/usr/bin/env python3
from copy import deepcopy
from skill_lab_recovery_model import canonical_hash, descriptor, reconcile

MANIFEST={
  "schema":1,"kind":"kevin-composite-skill","id":"recovery-demo","version":"1","authority":"GREEN","name":"Recovery demo",
  "steps":[
    {"operation":"create_text","payload":{"filename":"proof.txt","content":"hello"}},
    {"operation":"ui_notepad_write","payload":{"filename":"ui-proof.txt","content":"hello ui","app":"notepad"}},
  ]
}

def base_state(index=0,current="",attempts=0):
    return {"manifest":deepcopy(MANIFEST),"step_index":index,"current_order_id":current,"recovery_attempts":attempts,"step_results":[]}

def order(index=0, state="READY", mutate=None):
    d=descriptor(MANIFEST,index)
    o={"schema":1,"kind":"kevin-green-work-order","id":d["id"],"semantic_key":d["semantic_key"],"authority":"GREEN","operation":d["operation"],"payload":deepcopy(MANIFEST["steps"][index]["payload"])}
    if state=="DONE":
        o["status"]="DONE";o["result"]={"status":"DONE","completed_at":"2026-08-30T10:00:00-06:00","output_name":"proof.txt" if index==0 else "ui-proof.txt","sha256":"A"*64,"bytes":5}
        if index==1:o["result"].update({"screenshot_name":"proof.png","screenshot_sha256":"B"*64})
    if mutate: mutate(o)
    return {"state":state,"order":o}

def test_new_step_enqueues_once():
    r=reconcile(base_state(),[])
    assert r.action=="ENQUEUE" and r.enqueue

def test_crash_after_queue_write_before_state_link_adopts_ready():
    r=reconcile(base_state(),[order(0,"READY")])
    assert r.action=="ADOPT" and r.adopt and not r.enqueue

def test_crash_after_operator_done_before_state_link_consumes_done():
    r=reconcile(base_state(),[order(0,"DONE")])
    assert r.action=="CONSUME" and r.consume and not r.enqueue

def test_existing_running_order_is_adopted_not_duplicated():
    r=reconcile(base_state(),[order(0,"RUNNING")])
    assert r.action=="ADOPT" and not r.enqueue

def test_linked_ready_waits_by_adopting_same_order():
    d=descriptor(MANIFEST,0)
    r=reconcile(base_state(current=d["id"]),[order(0,"READY")])
    assert r.action=="ADOPT" and not r.enqueue

def test_conflicting_same_id_hard_fails():
    def mutate(o):o["payload"]["content"]="evil"
    r=reconcile(base_state(),[order(0,"READY",mutate)])
    assert r.fail and "fingerprint" in r.reason

def test_wrong_semantic_key_hard_fails():
    def mutate(o):o["semantic_key"]="skill:other:1:step:1"
    r=reconcile(base_state(),[order(0,"READY",mutate)])
    assert r.fail

def test_operator_failed_is_terminal_with_evidence_path():
    r=reconcile(base_state(),[order(0,"FAILED")])
    assert r.fail and r.action=="FAIL"

def test_invalid_done_evidence_fails_closed():
    def mutate(o):o["result"]["sha256"]="bad"
    r=reconcile(base_state(),[order(0,"DONE",mutate)])
    assert r.fail and "DONE evidence" in r.reason

def test_ui_done_requires_screenshot_evidence():
    def mutate(o):o["result"].pop("screenshot_sha256")
    r=reconcile(base_state(index=1),[order(1,"DONE",mutate)])
    assert r.fail

def test_fresh_missing_linked_order_waits():
    d=descriptor(MANIFEST,0)
    r=reconcile(base_state(current=d["id"]),[],age_minutes=2)
    assert r.action=="WAIT" and not r.enqueue

def test_stale_missing_linked_order_requeues_same_deterministic_id():
    d=descriptor(MANIFEST,0)
    r=reconcile(base_state(current=d["id"],attempts=0),[],age_minutes=16)
    assert r.action=="REENQUEUE" and r.enqueue and r.recovery_attempts==1

def test_stale_recovery_is_bounded_after_three_attempts():
    d=descriptor(MANIFEST,0)
    r=reconcile(base_state(current=d["id"],attempts=3),[],age_minutes=999)
    assert r.fail and r.recovery_attempts==4

def test_completed_step_never_replayed():
    d=descriptor(MANIFEST,0)
    s=base_state();s["step_results"]=[{"order_id":d["id"]}]
    r=reconcile(s,[order(0,"DONE")])
    assert r.fail and "replay" in r.reason

def test_second_step_has_distinct_deterministic_identity():
    a=descriptor(MANIFEST,0);b=descriptor(MANIFEST,1)
    assert a["id"].endswith("s01") and b["id"].endswith("s02") and a["id"]!=b["id"]

def test_payload_fingerprint_is_property_order_independent():
    a={"filename":"x.txt","content":"a"};b={"content":"a","filename":"x.txt"}
    assert canonical_hash(a)==canonical_hash(b)

def test_unknown_primitive_fails_closed():
    m=deepcopy(MANIFEST);m["steps"][0]["operation"]="shell"
    try: descriptor(m,0)
    except ValueError: pass
    else: raise AssertionError("shell operation accepted")

def test_more_than_one_queue_record_fails_closed():
    r=reconcile(base_state(),[order(0,"READY"),order(0,"DONE")])
    assert r.fail and "duplicate queue" in r.reason

def test_state_link_to_wrong_step_id_fails_closed():
    r=reconcile(base_state(current="skill-recovery-demo-1-s99"),[])
    assert r.fail

if __name__=='__main__':
    tests=[v for k,v in sorted(globals().items()) if k.startswith('test_') and callable(v)]
    for t in tests:t()
    print(f"PASS {len(tests)}/{len(tests)} Skill Lab recovery model cases")
