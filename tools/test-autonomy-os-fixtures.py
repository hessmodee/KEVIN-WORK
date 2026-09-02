"""Deterministic admission regressions; never change or depend on the live queue."""
from copy import deepcopy
from pathlib import Path
import datetime as dt
import importlib.util
import json
import sys

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('kevin_selector_fixture', root / 'control-plane/autonomy/kevin-work-selector-v1.1.py')
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
programs = {'schema': 1, 'kind': 'kevin-standing-program-registry', 'programs': [{'id': 'fixture', 'base_priority': 100}]}
families = {'schema': 1, 'kind': 'kevin-failure-family-registry', 'policy': {'max_material_attempts': 3, 'rename_does_not_reset_budget': True, 'request_id_does_not_reset_budget': True, 'iteration_does_not_reset_budget': True, 'reopen_requires_material_new_evidence': True}, 'families': [{'id': 'held-family', 'state': 'BLOCKED', 'attempts': 3}]}
state = {'schema': 1, 'wip': {'production': 0, 'staging': 0, 'research': 0}}
now = dt.datetime(2026, 9, 2, tzinfo=dt.timezone.utc)
base = {'program': 'fixture', 'authority_class': 'GREEN', 'status': 'READY', 'lane': 'production', 'acceptance_criteria': ['Fixed semantic outcome'], 'dependencies_ready': True}
held = dict(base, id='held-item', failure_family='held-family', blocked=True, dependencies_ready=False, failure_attempts=3, cooldown_until='2026-09-03T00:00:00Z')
ready = dict(base, id='independent-item', lane='staging')
complete = dict(base, id='completed-item', status='COMPLETE', owner_value=5)
items = {'schema': 1, 'kind': 'kevin-work-items', 'items': [held, ready, complete]}
before = deepcopy(items)
result = module.select(programs, items, state, families, now)
assert result['selection']['id'] == 'independent-item'
assert result['wip']['production'] == 0
blocked = {row['id']: row['reasons'] for row in result['blocked']}
assert {'DEPENDENCY_BLOCKED', 'EXPLICITLY_BLOCKED', 'COOLING_DOWN', 'FAILURE_BUDGET_EXHAUSTED', 'FAILURE_FAMILY_BLOCKED'} <= set(blocked['held-item'])
assert 'NOT_OPEN_OR_READY' in blocked['completed-item']
assert items == before
renamed = dict(held, id='renamed-item', blocked=False, dependencies_ready=True, failure_attempts=0, cooldown_until=None)
changed = module.select(programs, {'schema': 1, 'kind': 'kevin-work-items', 'items': [renamed, ready]}, state, families, now)
assert changed['selection']['id'] == 'independent-item'
assert 'FAILURE_FAMILY_BLOCKED' in changed['blocked'][0]['reasons']
owner_wait = dict(ready, owner_checkpoint_required=True)
waiting = module.select(programs, {'schema': 1, 'kind': 'kevin-work-items', 'items': [held, owner_wait, complete]}, state, families, now)
assert waiting['selection'] is None
assert all(row['reasons'] for row in waiting['blocked'])
Path('work-selection-proof.json').write_text(json.dumps({'fixture_only': True, 'result': result, 'checks': ['blocked_frees_wip', 'independent_selected', 'complete_rejected', 'rename_cannot_reopen', 'owner_checkpoint_held', 'input_unchanged']}, indent=2) + '\n')
print('AUTONOMY_OS_FIXTURES_PASS blocked_frees_wip=true independent_selected=true complete_rejected=true rename_cannot_reopen=true owner_checkpoint_held=true input_unchanged=true')
