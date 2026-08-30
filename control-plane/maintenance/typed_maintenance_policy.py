#!/usr/bin/env python3
"""Independent policy model for Kevin typed GREEN maintenance v1.2."""
from dataclasses import dataclass
import re

OWNER_POLICY = 'Kevin Owner Authorization v1'
HASH = re.compile(r'^[A-Fa-f0-9]{64}$')
ID = re.compile(r'^[A-Za-z0-9._-]{6,96}$')
SKILL_SOURCE = re.compile(r'^control-plane/skill-lab/[A-Za-z0-9._-]+\.ps1$')
MAX_ATTEMPTS = 3

@dataclass(frozen=True)
class Decision:
    allowed: bool
    mutate: bool
    status: str
    reason: str


def validate(m: dict) -> None:
    if m.get('schema') != 2 or m.get('kind') != 'kevin-typed-maintenance-manifest': raise ValueError('schema')
    if not ID.fullmatch(str(m.get('id',''))): raise ValueError('id')
    if m.get('authority_class') != 'GREEN': raise ValueError('authority')
    if m.get('authority_delta') != 'NONE': raise ValueError('authority_delta')
    if m.get('production_effect') != 'NONE': raise ValueError('production_effect')
    if m.get('owner_policy') != OWNER_POLICY: raise ValueError('owner_policy')
    if m.get('preauthorized') is not True: raise ValueError('preauthorized')
    op=m.get('operation')
    if op not in {'replace_pinned_file','restart_ui_bridge'}: raise ValueError('operation')
    if op == 'replace_pinned_file':
        if m.get('target_alias') != 'skill_lab_runner': raise ValueError('target_alias')
        if not SKILL_SOURCE.fullmatch(str(m.get('source_path',''))): raise ValueError('source_path')
        for k in ('source_sha256','expected_current_sha256','expected_after_sha256'):
            if not HASH.fullmatch(str(m.get(k,''))): raise ValueError(k)
        if m['source_sha256'].upper()!=m['expected_after_sha256'].upper(): raise ValueError('source_after')
    else:
        if m.get('target_alias') != 'ui_bridge_runner': raise ValueError('target_alias')
        if not HASH.fullmatch(str(m.get('expected_current_sha256',''))): raise ValueError('expected_current_sha256')
        if m.get('task_name') != 'Kevin UI Bridge v0.3': raise ValueError('task_name')
        t=m.get('heartbeat_timeout_seconds')
        if not isinstance(t,int) or not 5 <= t <= 30: raise ValueError('heartbeat_timeout_seconds')


def decide(m: dict, *, attempts: int, prior_status: str='', current_hash: str='') -> Decision:
    try: validate(m)
    except ValueError as e: return Decision(False,False,'REJECTED',str(e))
    if prior_status == 'PROVEN': return Decision(True,False,'ALREADY_APPLIED_PROVEN','idempotent completion')
    if attempts >= MAX_ATTEMPTS: return Decision(False,False,'BLOCKED_FAILURE_BUDGET','three attempts exhausted')
    if m['operation']=='replace_pinned_file' and current_hash:
        after=m['expected_after_sha256'].upper();before=m['expected_current_sha256'].upper();cur=current_hash.upper()
        if cur == after: return Decision(True,False,'VERIFY_IDEMPOTENT','already at after hash')
        if cur != before: return Decision(False,False,'BLOCKED_PRECONDITION','expected-current mismatch')
    return Decision(True,True,'APPLY_TYPED_GREEN','fixed owner-preauthorized operation')
