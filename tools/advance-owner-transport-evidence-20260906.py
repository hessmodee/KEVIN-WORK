#!/usr/bin/env python3
import json
from pathlib import Path

path=Path('inbox/autonomy/work-items.json')
data=json.loads(path.read_text(encoding='utf-8'))
assert data.get('schema')==1 and data.get('kind')=='kevin-work-items'
hits=[x for x in data.get('items',[]) if x.get('id')=='owner-west-motor-transport-dispatch-template-v1']
assert len(hits)==1
item=hits[0]
assert item.get('program')=='owner-value-skills'
assert item.get('authority_class')=='GREEN'
assert item.get('status')=='OPEN'
assert item.get('blocked') is False
assert item.get('dependencies_ready') is True
assert item.get('material_new_evidence') is True
marker='Fresh HESS-PC platform evidence after the three historical fixed-main turns'
criteria=list(item.get('acceptance_criteria') or [])
if not any(marker in str(x) for x in criteria):
    criteria.append(
        'Fresh HESS-PC platform evidence after the three historical fixed-main turns proves Supervisor v1.8.10 is installed, Benchmark is 30/30 critical 0, fixed:main sees the exact-five Kevin tool surface on local Qwen 14B/16K, and owner-value-skills are capability-routed to Skill Lab. This is material new evidence: the next scheduled selection must route to Skill Lab with turn_charged=false; the three historical model turns remain preserved and remain explicitly not outcome proof.'
    )
item['acceptance_criteria']=criteria
item['next_action']='On the next scheduled Supervisor cycle, select this item from the changed material fingerprint and route it to Skill Lab with turn_charged=false. Skill Lab v1.0.7 then requires that fresh route receipt before autonomously compiling the fixed GREEN transport-board recipe, executing proven spreadsheet/text primitives, and recording owner-work outcome proof.'
pointers=list(item.get('evidence_pointers') or [])
for p in ['reports/main-agent-canary-omen.json','reports/autonomy-continuation-latest.json','reports/engineering/latest.json']:
    if p not in pointers:pointers.append(p)
item['evidence_pointers']=pointers
path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8',newline='\n')
print('OWNER_TRANSPORT_MATERIAL_EVIDENCE_AMENDMENT_READY history_preserved=true authority_delta=none')
