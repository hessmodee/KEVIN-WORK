#!/usr/bin/env python3
from datetime import datetime, timedelta, timezone

from dispatcher_state_v0_2 import record_evaluation, record_failure, record_success, upgrade_state


def main():
    now=datetime(2026,8,30,tzinfo=timezone.utc)
    until=(now+timedelta(minutes=30)).isoformat()

    legacy={"schema":1,"queue_index":2,"last_mission":"knowledge","last_result":"INFRA_FAILURE","failure_family":"review-output-contract","attempts":3,"cooldown_until":until,"recent":[]}
    s=upgrade_state(legacy)
    assert s["schema"]==2
    assert s["failure_attempts"][0]["attempts"]==3
    assert s["failure_cooldowns"][0]["scope"]=="pipeline"

    s=upgrade_state({"schema":1,"recent":[]})
    for _ in range(3):
        s=record_failure(s,"knowledge","candidate-output-contract",until)
    assert s["failure_cooldowns"][-1]["scope"]=="mission"
    assert s["failure_cooldowns"][-1]["mission_id"]=="knowledge"

    other=record_failure(s,"operator","candidate-output-contract",None)
    counts={(x["mission_id"],x["family"]):x["attempts"] for x in other["failure_attempts"]}
    assert counts[("knowledge","candidate-output-contract")]==3
    assert counts[("operator","candidate-output-contract")]==1

    g=upgrade_state({"schema":2,"failure_attempts":[],"failure_cooldowns":[],"recent":[]})
    for _ in range(3):
        g=record_failure(g,"forge-v4","runtime-transport",until)
    assert g["failure_cooldowns"][-1]["scope"]=="pipeline"

    # A REJECT is failure evidence, not semantic success. It must never erase
    # accumulated mission history through record_success().
    try:
        record_success(s,"knowledge","REJECT",now.isoformat())
    except ValueError as e:
        assert "semantically successful" in str(e)
    else:
        raise AssertionError("REJECT incorrectly cleared failure evidence")

    # Evaluator rejections accumulate across recovery/planning cycles and cool
    # the mission after the bounded threshold.
    r=upgrade_state({"schema":2,"failure_attempts":[],"failure_cooldowns":[],"recent":[]})
    r=record_evaluation(r,"forge-v4","REJECT","candidate-evaluation",now.isoformat(),until)
    r=record_evaluation(r,"forge-v4","REJECT","candidate-evaluation",now.isoformat(),until)
    assert next(x for x in r["failure_attempts"] if x["mission_id"]=="forge-v4")["attempts"]==2
    assert not r["failure_cooldowns"]
    r=record_evaluation(r,"forge-v4","REJECT","candidate-evaluation",now.isoformat(),until)
    assert next(x for x in r["failure_attempts"] if x["mission_id"]=="forge-v4")["attempts"]==3
    assert r["failure_cooldowns"][-1]["scope"]=="mission"
    assert r["recent"][-1]["result"]=="REJECT"

    # A later semantically successful evaluator verdict can clear only that
    # mission's local failure evidence; independent mission evidence remains.
    r=record_failure(r,"knowledge","candidate-output-contract",until)
    cleared=record_evaluation(r,"forge-v4","PASS","candidate-evaluation",now.isoformat())
    assert not any(x.get("mission_id")=="forge-v4" for x in cleared["failure_attempts"])
    assert any(x.get("mission_id")=="knowledge" for x in cleared["failure_attempts"])
    assert not any(x.get("mission_id")=="forge-v4" and x.get("scope")!="pipeline" for x in cleared["failure_cooldowns"])
    assert cleared["recent"][-1]["result"]=="PASS"

    try:
        record_evaluation(cleared,"forge-v4","MAYBE","candidate-evaluation",now.isoformat())
    except ValueError as e:
        assert "unknown evaluator verdict" in str(e)
    else:
        raise AssertionError("unknown evaluator verdict accepted")

    # Never manufacture a success while migrating state.
    plain=upgrade_state({"schema":1,"last_result":"","recent":[]})
    assert plain["recent"]==[] and plain["last_result"]==""

    print('PASS: scoped dispatcher state migration/evaluation tests')


if __name__=='__main__':
    main()
