#!/usr/bin/env python3
import importlib.util
from datetime import datetime
from pathlib import Path

p=Path(__file__).with_name('scheduler_policy_v0_2.py')
s=importlib.util.spec_from_file_location('scheduler_policy_v0_2',p)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
NOW=datetime.fromisoformat('2026-08-29T19:30:00-06:00')

CAT={
 'policy':{'candidate_only':True,'allow_production_mutation':False,'allow_arbitrary_shell':False,'mission_repeat_cooldown_minutes':30},
 'missions':[
  {'id':'checkpoint-resume','priority':100},
  {'id':'knowledge-provenance','priority':95},
  {'id':'telemetry-quality','priority':92},
 ]
}

def test_local_failure_moves_to_other_mission():
 st={'recent':[],'failure_cooldowns':[{'mission_id':'checkpoint-resume','family':'candidate-output-contract','cooldown_until':'2026-08-29T20:30:00-06:00'}]}
 r=m.pick_mission(CAT,st,NOW)
 assert r['state']=='SELECTED' and r['selected_mission']=='knowledge-provenance'
 assert r['evidence'][0]['reason']=='mission-family:candidate-output-contract'

def test_global_pipeline_failure_blocks_all_worker_missions():
 st={'recent':[],'failure_cooldowns':[{'mission_id':'checkpoint-resume','family':'review-output-contract','cooldown_until':'2026-08-29T20:30:00-06:00'}]}
 r=m.pick_mission(CAT,st,NOW)
 assert r['state']=='PIPELINE_COOLING' and r['selected_mission'] is None
 assert all(x['reason']=='global-family:review-output-contract' for x in r['evidence'])

def test_expired_failure_cooldown_releases_mission():
 st={'recent':[],'failure_cooldowns':[{'mission_id':'checkpoint-resume','family':'candidate-output-contract','cooldown_until':'2026-08-29T19:29:00-06:00'}]}
 r=m.pick_mission(CAT,st,NOW)
 assert r['selected_mission']=='checkpoint-resume'

def test_repeat_cooldown_moves_to_next_mission():
 st={'recent':[{'mission_id':'checkpoint-resume','at':'2026-08-29T19:20:00-06:00'}],'failure_cooldowns':[]}
 r=m.pick_mission(CAT,st,NOW)
 assert r['selected_mission']=='knowledge-provenance'

def test_suggested_mission_wins_when_eligible():
 r=m.pick_mission(CAT,{'recent':[],'failure_cooldowns':[]},NOW,suggested='telemetry-quality')
 assert r['selected_mission']=='telemetry-quality'

def test_third_failure_records_scoped_cooldown_only():
 st={'recent':[],'failure_cooldowns':[]}
 a=m.record_failure(st,'checkpoint-resume','candidate-output-contract',2,'2026-08-29T20:30:00-06:00')
 assert a==st
 b=m.record_failure(st,'checkpoint-resume','candidate-output-contract',3,'2026-08-29T20:30:00-06:00')
 assert len(b['failure_cooldowns'])==1 and b['failure_cooldowns'][0]['mission_id']=='checkpoint-resume'

def test_authority_expansion_rejected():
 bad={**CAT,'policy':{**CAT['policy'],'allow_arbitrary_shell':True}}
 try:m.pick_mission(bad,{'recent':[],'failure_cooldowns':[]},NOW)
 except ValueError as e: assert 'arbitrary shell' in str(e)
 else: raise AssertionError('unsafe catalog accepted')

if __name__=='__main__':
 tests=[v for k,v in sorted(globals().items()) if k.startswith('test_') and callable(v)]
 for t in tests:t()
 print(f'PASS: {len(tests)} scheduler policy tests')
