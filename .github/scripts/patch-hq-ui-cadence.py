#!/usr/bin/env python3
from pathlib import Path

root=Path(__file__).resolve().parents[2]
js=root/'docs'/'hq-truth-v2.js'
index=root/'docs'/'index.html'
hq3=root/'docs'/'hq-owner-refinement-v3.js'
text=js.read_text(encoding='utf-8')
old_src="engineering:{label:'Engineering',path:'reports/engineering/latest.json',kind:'periodic',fresh:300,delayed:720,claim:'relay / skills / UI Bridge'},"
new_src="engineering:{label:'Engineering',path:'reports/engineering/latest.json',kind:'periodic',fresh:180,delayed:360,claim:'relay / skills / UI Bridge'},"
old="""  const hb=Number(e?.action?.ui_bridge?.heartbeat_age_seconds)+ageSec(e.generated_at);
  if(Number.isFinite(hb)&&hb>60)out.push({sev:'bad',title:'UI Bridge heartbeat is not fresh',detail:`Heartbeat ${ageText(hb)} old.`});"""
new="""  const engState=sourceState('engineering',e),hbSample=Number(e?.action?.ui_bridge?.heartbeat_age_seconds);
  if(!Number.isFinite(hbSample))out.push({sev:'warn',title:'UI Bridge liveness evidence is unavailable',detail:'Latest Engineering sample does not contain a usable UI Bridge heartbeat age.'});
  else if(hbSample>60)out.push({sev:'bad',title:'UI Bridge heartbeat was stale at last engineering sample',detail:`Sampled heartbeat ${ageText(hbSample)} old when Engineering published.`});
  else if(engState.state!=='FRESH')out.push({sev:engState.state==='STALE'?'bad':'warn',title:'UI Bridge liveness evidence is delayed',detail:`Engineering evidence ${ageText(engState.age)} old; the last sampled UI heartbeat itself was fresh (${ageText(hbSample)}).`});"""

changed=False
if old_src in text:
    if text.count(old_src)!=1:
        raise SystemExit(f'engineering source cadence anchor mismatch count={text.count(old_src)}')
    text=text.replace(old_src,new_src)
    changed=True
elif text.count(new_src)!=1:
    raise SystemExit(f'engineering cadence is neither old nor desired; desired count={text.count(new_src)}')

if old in text:
    if text.count(old)!=1:
        raise SystemExit(f'UI issue predicate anchor mismatch count={text.count(old)}')
    text=text.replace(old,new)
    changed=True
elif text.count(new)!=1:
    raise SystemExit(f'UI issue predicate is neither old nor desired; desired count={text.count(new)}')

if "+ageSec(e.generated_at)" in text:
    raise SystemExit('heartbeat extrapolation bug remains')
if changed:
    js.write_text(text,encoding='utf-8',newline='\n')

idx=index.read_text(encoding='utf-8')
old_q='<script src="./hq-truth-v2.js?v=3"></script>'
new_q='<script src="./hq-truth-v2.js?v=4"></script>'
if old_q in idx:
    if idx.count(old_q)!=1:
        raise SystemExit(f'index cache-bust anchor mismatch count={idx.count(old_q)}')
    idx=idx.replace(old_q,new_q)
    index.write_text(idx,encoding='utf-8',newline='\n')
    changed=True
elif idx.count(new_q)!=1:
    raise SystemExit(f'index cache-bust is neither old nor desired; desired count={idx.count(new_q)}')

# Command Center v3 originally parsed only numbered items that used an em-dash/colon
# delimiter. CURRENT_TASK legitimately uses the common "**Title.** Detail" form for P0
# repair targets, causing HQ to fall back to canned priorities. Accept both forms so HQ
# really follows the canonical current task instead of silently presenting a fallback.
h3=hq3.read_text(encoding='utf-8')
old_md="""function mdSection(needle,limit){const lines=String(taskMd||'').split(/\\r?\\n/);let on=false,out=[];for(const raw of lines){const line=raw.trim();if(/^##\\s+/.test(line)){if(on)break;on=line.toLowerCase().includes(needle.toLowerCase());continue}if(!on)continue;const m=line.match(/^\\d+\\.\\s+(?:\\*\\*)?(.+?)(?:\\*\\*)?(?:\\s+[—–-]\\s+|:\\s+)(.+)$/);if(!m)continue;out.push([m[1].replace(/[\\*`]/g,'').trim(),m[2].replace(/\\*\\*/g,'').trim()]);if(out.length>=limit)break}return out}"""
new_md="""function mdSection(needle,limit){const lines=String(taskMd||'').split(/\\r?\\n/);let on=false,out=[];for(const raw of lines){const line=raw.trim();if(/^##\\s+/.test(line)){if(on)break;on=line.toLowerCase().includes(needle.toLowerCase());continue}if(!on)continue;let m=line.match(/^\\d+\\.\\s+(?:\\*\\*)?(.+?)(?:\\*\\*)?(?:\\s+[—–-]\\s+|:\\s+)(.+)$/);if(!m){const b=line.match(/^\\d+\\.\\s+\\*\\*(.+?)\\*\\*\\s+(.+)$/);if(b)m=[b[0],b[1].replace(/\\.$/,'').trim(),b[2]]}if(!m)continue;out.push([m[1].replace(/[\\*`]/g,'').trim(),m[2].replace(/\\*\\*/g,'').trim()]);if(out.length>=limit)break}return out}"""
if old_md in h3:
    if h3.count(old_md)!=1:
        raise SystemExit(f'HQ v3 mdSection old anchor mismatch count={h3.count(old_md)}')
    h3=h3.replace(old_md,new_md)
    hq3.write_text(h3,encoding='utf-8',newline='\n')
    changed=True
elif h3.count(new_md)!=1:
    raise SystemExit(f'HQ v3 mdSection is neither old nor desired; desired count={h3.count(new_md)}')

print(f'HQ_UI_CADENCE_PATCH_PASS engineering_fresh=180 delayed=360 extrapolation=false cache=v4 current_task_parser=live changed={str(changed).lower()}')