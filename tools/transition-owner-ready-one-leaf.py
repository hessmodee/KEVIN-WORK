#!/usr/bin/env python3
from pathlib import Path
import json,re
P=Path('inbox/autonomy/work-items.json')
TARGET='owner-west-motor-transport-dispatch-template-v1'
raw=P.read_bytes()
text=raw.decode('utf-8-sig')
data=json.loads(text)
hits=[x for x in data.get('items',[]) if x.get('id')==TARGET]
assert len(hits)==1
item=hits[0]
expected={'program':'owner-value-skills','authority_class':'GREEN','status':'OPEN','lane':'production','work_type':'execution','priority':'high','owner_value':5,'dependencies_ready':True,'blocked':False,'failure_attempts':0,'material_new_evidence':True}
for k,v in expected.items(): assert item.get(k)==v,(k,item.get(k),v)
assert item.get('produces_owner_deliverable') is True
assert item.get('reuses_proven_capability') is True
needle='"id":  "'+TARGET+'"'
start=text.find(needle)
assert start>=0
next_id=text.find('"id":',start+len(needle))
block=text[start: next_id if next_id>=0 else len(text)]
pat=r'("status"\s*:\s*)"OPEN"'
newblock,n=re.subn(pat,r'\1"READY"',block,count=1)
assert n==1
newtext=text[:start]+newblock+text[(next_id if next_id>=0 else len(text)):]
# Prove exactly the one semantic leaf changed.
a=json.loads(text); b=json.loads(newtext)
ah=[x for x in a['items'] if x.get('id')==TARGET][0]; bh=[x for x in b['items'] if x.get('id')==TARGET][0]
assert ah['status']=='OPEN' and bh['status']=='READY'
bh2=dict(bh); bh2['status']='OPEN'; assert ah==bh2
ax=[x for x in a['items'] if x.get('id')!=TARGET]; bx=[x for x in b['items'] if x.get('id')!=TARGET]; assert ax==bx
ac=dict(a); bc=dict(b); ac['items']=[]; bc['items']=[]; assert ac==bc
# Preserve original BOM/newline/formatting bytes except literal OPEN->READY in target block.
out=(b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'') + newtext.encode('utf-8')
if raw.startswith(b'\xef\xbb\xbf'): out=out[:3]+out[6:] if out[3:6]==b'\xef\xbb\xbf' else out
P.write_bytes(out)
print('OWNER_READY_ONE_LEAF_PROVEN history_reset=false completion=false authority_delta=NONE')
