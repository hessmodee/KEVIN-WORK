#!/usr/bin/env python3
from copy import deepcopy
from typed_maintenance_policy import validate, decide
H='A'*64;B='B'*64
REPLACE={'schema':2,'kind':'kevin-typed-maintenance-manifest','id':'skill-lab-repair-001','authority_class':'GREEN','authority_delta':'NONE','production_effect':'NONE','owner_policy':'Kevin Owner Authorization v1','preauthorized':True,'operation':'replace_pinned_file','target_alias':'skill_lab_runner','source_path':'control-plane/skill-lab/kevin-skill-lab-v1.0.3.ps1','source_sha256':H,'expected_current_sha256':B,'expected_after_sha256':H}
UI={'schema':2,'kind':'kevin-typed-maintenance-manifest','id':'ui-restart-001','authority_class':'GREEN','authority_delta':'NONE','production_effect':'NONE','owner_policy':'Kevin Owner Authorization v1','preauthorized':True,'operation':'restart_ui_bridge','target_alias':'ui_bridge_runner','expected_current_sha256':H,'task_name':'Kevin UI Bridge v0.3','heartbeat_timeout_seconds':15}

def rejects(base,key,value):
    m=deepcopy(base);m[key]=value
    try:validate(m)
    except ValueError:return
    raise AssertionError((key,value))

def test_good_replace(): validate(REPLACE)
def test_good_ui(): validate(UI)
def test_shell_rejected(): rejects(REPLACE,'operation','shell')
def test_authority_expansion_rejected(): rejects(REPLACE,'authority_delta','ADD')
def test_production_effect_rejected(): rejects(REPLACE,'production_effect','YES')
def test_not_preauthorized_rejected(): rejects(REPLACE,'preauthorized',False)
def test_wrong_owner_policy_rejected(): rejects(REPLACE,'owner_policy','Kevin self-approved')
def test_supervisor_replace_rejected(): rejects(REPLACE,'target_alias','supervisor')
def test_package_source_rejected(): rejects(REPLACE,'source_path','inbox/maintenance/packages/anything.ps1')
def test_source_after_mismatch_rejected(): rejects(REPLACE,'source_sha256','C'*64)
def test_wrong_ui_task_rejected(): rejects(UI,'task_name','Anything Else')
def test_ui_timeout_low_rejected(): rejects(UI,'heartbeat_timeout_seconds',4)
def test_ui_timeout_high_rejected(): rejects(UI,'heartbeat_timeout_seconds',31)
def test_failure_budget_stops_fourth_attempt():
    d=decide(REPLACE,attempts=3,current_hash=B);assert not d.allowed and d.status=='BLOCKED_FAILURE_BUDGET'
def test_prior_proven_never_replays():
    d=decide(REPLACE,attempts=1,prior_status='PROVEN',current_hash=B);assert d.allowed and not d.mutate and d.status=='ALREADY_APPLIED_PROVEN'
def test_after_hash_is_verify_only():
    d=decide(REPLACE,attempts=0,current_hash=H);assert d.allowed and not d.mutate and d.status=='VERIFY_IDEMPOTENT'
def test_wrong_before_hash_blocks():
    d=decide(REPLACE,attempts=0,current_hash='C'*64);assert not d.allowed and d.status=='BLOCKED_PRECONDITION'
def test_expected_before_applies():
    d=decide(REPLACE,attempts=0,current_hash=B);assert d.allowed and d.mutate and d.status=='APPLY_TYPED_GREEN'

if __name__=='__main__':
    tests=[v for k,v in sorted(globals().items()) if k.startswith('test_') and callable(v)]
    for t in tests:t()
    print(f'PASS {len(tests)}/{len(tests)} typed maintenance policy cases')
