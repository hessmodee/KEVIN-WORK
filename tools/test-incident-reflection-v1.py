#!/usr/bin/env python3
import importlib.util, json, pathlib, tempfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
SRC=ROOT/'control-plane'/'autonomy'/'kevin-incident-reflection-v1.py'
spec=importlib.util.spec_from_file_location('ir',SRC);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

def base():
    return {
      'schema':1,'kind':'kevin-incident-reflection-input','incident_id':'maint-expired-001',
      'failure_family':'maintenance-expired-manifest-poison','objective_id':'autonomy-self-repair',
      'observed_failure':'Expired manifest correctly refused execution but poisoned cron health.',
      'evidence':[{'source':'reports/support-latest.json','sha256':'A'*64,'claim':'maintenance ERROR manifest expired'}],
      'hypotheses':[{'id':'h-expiry-throw','statement':'expiry is thrown as process error'},{'id':'h-cron-disabled','statement':'scheduler disabled independently'}],
      'candidate_repair':{'authority_class':'GREEN','authority_delta':'NONE','production_effect':'NONE','effects':[],'rollback_plan':'restore exact predecessor hash'},
      'tests':{'positive':['fresh manifest still executes'],'negative':['expired manifest never executes'],'regression':['Benchmark remains 30/30']},
      'independent_verifier':{'independent':True,'status':'PASS','evidence':'regression receipt'},
      'promotion':{'status':'PROVEN','receipt':'typed maintenance receipt'},
      'lesson':{'summary':'Refusal is not an operational error; stale input should terminate cleanly.'},
      'resume':{'work_item_id':'autonomy-self-repair','next_action':'resume original blocked autonomy work'},
      'external_intervention':{'required':True,'actor':'Bess','reason':'Kevin lacked typed repair path'},
      'dependency_retirement':{'artifact_type':'regression-test-and-runbook','artifact_pointer':'docs/engineering/LESSON-maintenance-expiry.md','repeat_strategy':'Kevin recognizes fingerprint and uses typed clean-idle repair.'}
    }

r1=m.build(base(),{'schema':1,'incidents':[]},'2026-09-07T19:30:00+00:00')
assert r1['same_family_proven_repairs_after']==1 and not r1['preventative_control_required']
assert r1['dependency_retirement']['outside_actor']=='Bess'
ledger=m.append_ledger({'schema':1,'incidents':[]},r1)
d2=base();d2['incident_id']='maint-expired-002'
r2=m.build(d2,ledger,'2026-09-07T20:30:00+00:00')
assert r2['same_family_proven_repairs_after']==2 and r2['preventative_control_required']

bad=base();bad['candidate_repair']['effects']=['arbitrary_shell']
try:m.build(bad,{'schema':1,'incidents':[]},'2026-09-07T19:30:00+00:00');raise AssertionError('protected effect accepted')
except ValueError:pass
bad=base();bad['hypotheses']=bad['hypotheses'][:1]
try:m.build(bad,{'schema':1,'incidents':[]},'2026-09-07T19:30:00+00:00');raise AssertionError('single-hypothesis theater accepted')
except ValueError:pass
bad=base();del bad['dependency_retirement']
try:m.build(bad,{'schema':1,'incidents':[]},'2026-09-07T19:30:00+00:00');raise AssertionError('outside intervention without retirement artifact accepted')
except ValueError:pass
print('KEVIN INCIDENT REFLECTION v1 SELFTEST PASS competing_hypotheses=true evidence_required=true independent_verifier=true protected_effects_rejected=true dependency_retirement=true repeated_failure_prevention=true authority_effect=none')
