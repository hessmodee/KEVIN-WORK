from pathlib import Path
import re

SRC=Path('docs/hq-truth-v1.js')
DST=Path('docs/generated/hq-truth-v2.js')
text=SRC.read_text(encoding='utf-8')
control=" control:{label:'Control-plane receipt',path:REPORT+'control-plane-latest.json',kind:'event',claim:'latest typed work-order outcome'},"
if text.count(control)!=1:
    raise SystemExit('control source marker mismatch')
text=text.replace(control,control+"\n forgeEpoch:{label:'Forge runtime epoch',path:REPORT+'forge-runtime-epoch.json',kind:'event',claim:'current Forge activation / supersession boundary'},",1)
new_issues=r'''function issues(){
 const s=cache.support||{},e=cache.engineering||{},a=cache.autonomy||{},c=cache.control||{},epoch=cache.forgeEpoch||{};
 const out=[],ev=s.latest_evaluation||{};
 const reject=String(ev.verdict||'').toUpperCase()==='REJECT'&&Number(ev.failure_count||0)>=3;
 const epochState=String(epoch.state||'').toUpperCase();
 const epochMatches=epochState==='OMEN_PROVEN'&&String(epoch.forge_sha256||'').toUpperCase()===String(s?.hashes?.forge||'').toUpperCase();
 const activated=parseTs(epoch.activated_at||epoch.generated_at),evAt=parseTs(ev.at);
 const evalCurrent=!epochMatches||!Number.isFinite(activated)||!Number.isFinite(evAt)||evAt>=activated;
 if(reject&&evalCurrent)out.push({sev:'bad',title:'Forge failure family still repeating',detail:`${ev.mission||'forge'} · iteration ${ev.iteration??'?'} · failures ${ev.failure_count} · security findings ${ev.security_finding_count??0}. This is diagnostic evidence, not progress.`});
 if(String(e?.request?.status||'').toUpperCase()==='REJECTED'&&/expired/i.test(e?.request?.detail||''))out.push({sev:'warn',title:'Engineering Relay slot is expired',detail:`${e.request.id||'request'} is still being surfaced as REJECTED/expired. Scheduler health does not make this slot useful.`});
 const hb=Number(e?.action?.ui_bridge?.heartbeat_age_seconds);if(Number.isFinite(hb)&&hb>60)out.push({sev:'bad',title:'Interactive UI Bridge is not freshly proven',detail:`Task/hash may exist, but heartbeat is ${ageText(hb)} old.`});
 const autonomyState=sourceState('autonomy',a);if(autonomyState.state==='FRESH'&&Number(a?.drift_count||0)>0)out.push({sev:'warn',title:'Desired-state drift requires deliberate review',detail:`Fresh autonomy reports ${a.drift_count} drift item(s); do not cosmetically repin trust anchors.`});
 if(String(c?.status||'').toUpperCase()==='DUPLICATE_IGNORED')out.push({sev:'neutral',title:'Latest control-plane receipt is terminal duplicate',detail:`${c?.request?.id||'request'} · idempotency key already processed. It should not be presented as active work.`});
 if(!out.length)out.push({sev:'ok',title:'No high-signal contradiction detected',detail:'Current truth sources do not expose a known major contradiction.'});return out.slice(0,6)
}'''
pat=r"function issues\(\)\{.*?\}\nfunction recentProof\(\)"
m=re.search(pat,text,re.S)
if not m:
    raise SystemExit('issues function marker mismatch')
text=text[:m.start()]+new_issues+'\nfunction recentProof()'+text[m.end():]
DST.parent.mkdir(parents=True,exist_ok=True)
DST.write_text(text,encoding='utf-8',newline='\n')
print(DST)
