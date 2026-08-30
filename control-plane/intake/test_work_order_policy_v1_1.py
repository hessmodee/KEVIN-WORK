#!/usr/bin/env python3
import copy
import importlib.util
from datetime import datetime
from pathlib import Path

p=Path(__file__).with_name('work_order_policy_v1_1.py')
s=importlib.util.spec_from_file_location('work_order_policy_v1_1',p)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
NOW=datetime.fromisoformat('2026-08-29T20:45:00-06:00')

FORBIDDEN=[
 'permissions','arbitrary_shell','production_chat_tools','financial_transactions',
 'purchases','external_sends','credential_access','safety_weakening',
 'automatic_production_promotion'
]
SNAP={
 'support':{
  'semantic_hash':'support-v1','governance':{'ok':True,'never_self_authorize':FORBIDDEN},
  'benchmark':{'status':'PASS'}
 },
 'autonomy':{'semantic_hash':'autonomy-v1','state':'HEALTHY'}
}
CAT={'policy':{'candidate_only':True,'allow_production_mutation':False,'allow_arbitrary_shell':False},'missions':[{'id':'knowledge'}]}


def order(**kw):
 o={
  'schema':1,'kind':'kevin-work-order','id':'wo-12345678','idempotency_key':'idem-12345678',
  'created_at':'2026-08-29T20:44:00-06:00','expires_at':'2026-08-29T21:44:00-06:00',
  'authority_class':'GREEN','verb':'dispatch_mission','target':'knowledge',
  'precondition_fingerprint':m.current_precondition(SNAP)
 }
 o.update(kw);return o


def test_accepts_fresh_green_order():
 r=m.evaluate(order(),SNAP,{'processed':[],'cooldowns':[]},CAT,NOW)
 assert r['decision']=='ACCEPT_GREEN' and r['execute'] is True


def test_replay_is_non_executing():
 o=order();r=m.evaluate(o,SNAP,{'processed':[{'idempotency_key':o['idempotency_key']}],'cooldowns':[]},CAT,NOW)
 assert r=={'decision':'REPLAY','execute':False}


def test_precondition_mismatch_is_non_executing():
 o=order(precondition_fingerprint='0'*64);r=m.evaluate(o,SNAP,{'processed':[],'cooldowns':[]},CAT,NOW)
 assert r['decision']=='PRECONDITION_MISMATCH' and r['execute'] is False


def test_cooldown_blocks_without_consuming_idempotency():
 o=order(cooldown_key='family:knowledge')
 ledger={'processed':[],'cooldowns':[{'key':'family:knowledge','until':'2026-08-29T21:00:00-06:00'}]}
 r=m.evaluate(o,SNAP,ledger,CAT,NOW)
 assert r['decision']=='COOLDOWN' and r['execute'] is False
 assert ledger['processed']==[]


def test_expired_cooldown_releases_order():
 o=order(cooldown_key='family:knowledge')
 ledger={'processed':[],'cooldowns':[{'key':'family:knowledge','until':'2026-08-29T20:40:00-06:00'}]}
 assert m.evaluate(o,SNAP,ledger,CAT,NOW)['decision']=='ACCEPT_GREEN'


def test_governance_failure_blocks():
 bad=copy.deepcopy(SNAP);bad['support']['governance']['ok']=False
 assert m.evaluate(order(precondition_fingerprint=m.current_precondition(bad)),bad,{'processed':[]},CAT,NOW)['decision']=='BLOCKED_GOVERNANCE'


def test_missing_owner_lock_blocks():
 bad=copy.deepcopy(SNAP);bad['support']['governance']['never_self_authorize']=FORBIDDEN[:-1]
 assert m.evaluate(order(precondition_fingerprint=m.current_precondition(bad)),bad,{'processed':[]},CAT,NOW)['decision']=='BLOCKED_GOVERNANCE_DRIFT'


def test_unallowlisted_mission_is_rejected():
 r=m.evaluate(order(target='not-authorized'),SNAP,{'processed':[]},CAT,NOW)
 assert r['decision']=='TARGET_NOT_ALLOWLISTED' and r['execute'] is False


def test_catalog_authority_expansion_blocks():
 bad=copy.deepcopy(CAT);bad['policy']['allow_arbitrary_shell']=True
 r=m.evaluate(order(),SNAP,{'processed':[]},bad,NOW)
 assert r['decision']=='CATALOG_AUTHORITY_VIOLATION' and r['execute'] is False


def test_unknown_property_rejected():
 try:m.evaluate(order(shell='whoami'),SNAP,{'processed':[]},CAT,NOW)
 except ValueError as e:assert 'unknown properties' in str(e)
 else:raise AssertionError('unknown property accepted')


def test_wrong_exact_target_rejected():
 try:m.evaluate(order(verb='run_benchmark',target='something-else'),SNAP,{'processed':[]},CAT,NOW)
 except ValueError as e:assert 'target mismatch' in str(e)
 else:raise AssertionError('wrong exact target accepted')


def test_expired_order_rejected():
 r=m.evaluate(order(expires_at='2026-08-29T20:44:30-06:00'),SNAP,{'processed':[]},CAT,NOW)
 assert r['decision']=='EXPIRED' and r['execute'] is False


if __name__=='__main__':
 tests=[v for k,v in sorted(globals().items()) if k.startswith('test_') and callable(v)]
 for t in tests:t()
 print(f'PASS: {len(tests)} work-order policy tests')
