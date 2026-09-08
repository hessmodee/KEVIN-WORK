#!/usr/bin/env python3
from __future__ import annotations
import importlib.util, json, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def load_module(name,path):
    spec=importlib.util.spec_from_file_location(name,path); mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod); return mod
mat=load_module('standing_materializer',ROOT/'control-plane/autonomy/kevin-standing-work-materializer-v1.py')
inc=load_module('incident_reflection',ROOT/'control-plane/autonomy/kevin-incident-reflection-v1.py')
mat.selftest()
# Real catalog integration: preserve every existing work item and add only bounded GREEN due instances.
catalog=json.loads((ROOT/'control-plane/autonomy/standing-work-supply-v1.json').read_text())
items=json.loads((ROOT/'inbox/autonomy/work-items.json').read_text())
now=mat.parse_time('2026-09-08T00:50:00Z')
out=mat.materialize(catalog,items,now,max_new=8)
assert out['items'][:len(items['items'])]==items['items']
new=out['items'][len(items['items']):]
assert 1 <= len(new) <= 8
protected=set(catalog['policy']['never_auto_authorize'])
for row in new:
    assert row['authority_class']=='GREEN'
    assert row['standing_parent_id']
    assert row['standing_due_slot']
    assert not (set(row.get('effects',[])) & protected)
    assert row['lane'] in {'production','staging','research','skill-lab'}
assert out['materialization']['history_preserved'] is True
# Incident/reflection contract: outside intervention must leave a dependency-retirement artifact.
base={
  'schema':1,'kind':'kevin-incident-reflection-input','incident_id':'maint-expiry-001',
  'failure_family':'maintenance-expired-manifest-poison','objective_id':'maintenance-hardening-v1',
  'observed_failure':'Expired request caused scheduler failure.','authority_effect':'NONE',
  'evidence':[{'source':'reports/engineering/latest.json','claim':'cron failure observed'}],
  'hypotheses':[{'id':'expired-input','statement':'expired input reaches hard throw'},{'id':'cron-backoff','statement':'scheduler backoff prevents recovery'}],
  'candidate_repair':{'authority_class':'GREEN','authority_delta':'NONE','production_effect':'NONE','effects':[],'rollback_plan':'restore exact previous hash'},
  'tests':{'positive':['expired valid input exits clean idle'],'negative':['malformed input remains rejected'],'regression':['parent maintenance selftest and Benchmark 30/30']},
  'independent_verifier':{'independent':True,'status':'PASS','name':'windows-ci'},
  'promotion':{'status':'PROVEN'},
  'lesson':{'summary':'stale governed input should refuse execution without poisoning cron'},
  'resume':{'work_item_id':'maintenance-hardening-v1','next_action':'resume original autonomy objective'},
  'external_intervention':{'required':True,'actor':'bess','reason':'Kevin lacked this repair recipe'},
  'dependency_retirement':{'artifact_type':'regression-test','artifact_pointer':'.github/workflows/maintenance-v1351-expired-idle-proof.yml','repeat_strategy':'classify expired canonical manifest before execution and clean-idle it'}
}
ledger={'schema':1,'kind':'kevin-incident-ledger','incidents':[]}
record=inc.build(base,ledger,'2026-09-08T00:50:00Z')
assert record['dependency_retirement']['outside_actor']=='bess'
assert record['authority_effect']=='NONE_RECORDER_ONLY'
ledger2=inc.append_ledger(ledger,record)
base2=json.loads(json.dumps(base)); base2['incident_id']='maint-expiry-002'
record2=inc.build(base2,ledger2,'2026-09-08T01:00:00Z')
assert record2['preventative_control_required'] is True
bad=json.loads(json.dumps(base)); bad['candidate_repair']['effects']=['arbitrary_shell']
try: inc.build(bad,ledger,'2026-09-08T00:50:00Z')
except ValueError: pass
else: raise AssertionError('protected-effect incident candidate was accepted')
print('KEVIN AUTONOMY NEXTLEVEL v1 TEST PASS standing_supply=true history_preserved=true incident_reflection=true dependency_retirement=true repeat_prevention=true authority_expansion=false')
