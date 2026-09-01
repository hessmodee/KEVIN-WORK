from pathlib import Path
import re

PATH = Path('docs/hq-truth-v2.js')
text = PATH.read_text(encoding='utf-8').replace('\r\n','\n')

# Production HQ loads hq-truth-v2.js. Patch that exact file, not an unused shadow copy.
if "desired:{label:'Desired state'" not in text:
    anchor = "  control:{label:'Control plane',path:'reports/control-plane-latest.json',kind:'event',claim:'latest typed outcome'},\n"
    if text.count(anchor) != 1:
        raise SystemExit('SOURCE anchor mismatch')
    text = text.replace(anchor, anchor +
        "  desired:{label:'Desired state',path:'control-plane/desired-state-v1.json',kind:'checkpoint',claim:'owner-approved core identities'},\n"
        "  workItems:{label:'Autonomy work items',path:'inbox/autonomy/work-items.json',kind:'checkpoint',claim:'blocked / eligible owner work'},\n", 1)

helpers = r'''function workItem(id){return (cache.workItems?.items||[]).find(x=>String(x.id||'')===id)||null}
function liveCoreDrift(s,desired){
  const expected=desired?.core_hashes||{},observed=s?.hashes||{};
  const keys=['supervisor','benchmark','forge','goal_os','support_bridge','maintenance_runner'].filter(k=>expected[k]&&observed[k]&&String(expected[k]).toUpperCase()!==String(observed[k]).toUpperCase());
  return{count:keys.length,keys};
}
function forgeBlocked(){const w=workItem('finish-forge-v40-runtime-convergence');return !!w&&(w.blocked===true||String(w.status||'').toUpperCase()==='BLOCKED')}
function forgeActive(d,s){const t=d?.current_task||{};const tag=[t.id,t.title,t.category,t.source].join(' ');return (taskActive(t)&&/forge/i.test(tag))||Number(s?.active_workers?.design_forge||0)>0||Number(s?.active_workers?.night_forge||0)>0}
'''

if 'function liveCoreDrift(' not in text:
    marker='function autonomyTruth(a){'
    if text.count(marker)!=1:
        raise SystemExit('autonomyTruth marker mismatch')
    text=text.replace(marker,helpers+marker,1)

new_autonomy = r'''function autonomyTruth(a){
  if(!a)return{headline:'UNKNOWN',detail:'Autonomy snapshot missing',cls:'bad'};
  const st=sourceState('autonomy',a),live=liveCoreDrift(cache.support||{},cache.desired||{}),reported=Number(a.drift_count||0);
  if(st.state==='STALE')return{headline:'STALE EVIDENCE',detail:`${ageText(st.age)} old · last ${a.state||'unknown'}`,cls:'bad'};
  if(cache.desired&&cache.support&&reported!==live.count)return{headline:'RECONCILE',detail:`autonomy reports drift ${reported} · live desired/support comparison ${live.count}`,cls:'warn'};
  if(live.count===1&&live.keys[0]==='forge'&&forgeBlocked())return{headline:'KNOWN DRIFT',detail:`Forge trust pin intentionally held while replacement lane is blocked · ${a?.work_conserving?.status||'selection unknown'}`,cls:'neutral'};
  const v=String(a.state||'UNKNOWN').toUpperCase();
  return{headline:v,detail:`live drift ${live.count} · ${a?.work_conserving?.status||'selection unknown'}`,cls:v==='HEALTHY'?'ok':v==='NEEDS_REVIEW'?'warn':'neutral'};
}'''
text,n=re.subn(r'function autonomyTruth\(a\)\{.*?\n\}',new_autonomy,text,count=1,flags=re.S)
if n!=1:
    raise SystemExit('autonomyTruth replacement mismatch')

new_issues = r'''function issueRows(){
  const d=cache.dashboard||{},s=cache.support||{},e=cache.engineering||{},a=cache.autonomy||{},c=cache.control||{},out=[];
  const ev=s.latest_evaluation||{},it=Number(ev.iteration||0),fail=Number(ev.failure_count||0),sec=Number(ev.security_finding_count||0),reject=String(ev.verdict||'').toUpperCase()==='REJECT'&&(it>=10||fail>=3||sec>0),blocked=forgeBlocked(),recentReject=ageSec(ev.at)<=900;
  if(blocked&&(forgeActive(d,s)||(reject&&recentReject))){
    out.push({sev:'bad',title:'Blocked Forge is still producing work',detail:`${ev.mission||'forge'} · iteration ${it||'?'} · failures ${fail} · security ${sec}. Admission must stop until materially new evidence exists.`});
  }else if(reject&&!blocked){
    out.push({sev:'bad',title:'Forge failure family is repeating',detail:`${ev.mission||'forge'} · iteration ${it||'?'} · failures ${fail} · security ${sec}.`});
  }
  if(taskActive(d.current_task)&&activeWorkers(s)===0){
    out.push({sev:'warn',title:'Current-work telemetry conflicts',detail:`Dashboard says “${d.current_task?.title||d.current_task?.id||'task'}” is active while Support reports 0 active workers.`});
  }
  const hb=Number(e?.action?.ui_bridge?.heartbeat_age_seconds);
  if(Number.isFinite(hb)&&hb>60)out.push({sev:'bad',title:'UI Bridge heartbeat is not fresh',detail:`Heartbeat ${ageText(hb)} old.`});
  if(String(e?.request?.status||'').toUpperCase()==='REJECTED'&&/expired/i.test(String(e?.request?.detail||'')))out.push({sev:'warn',title:'Engineering Relay slot is expired',detail:`${e?.request?.id||'request'} should be retired instead of resurfaced.`});
  const ast=sourceState('autonomy',a),live=liveCoreDrift(s,cache.desired||{}),reported=Number(a?.drift_count||0),knownForgeOnly=live.count===1&&live.keys[0]==='forge'&&blocked;
  if(ast.state==='FRESH'&&cache.desired&&reported!==live.count)out.push({sev:'warn',title:'Autonomy drift telemetry is stale',detail:`Autonomy reports ${reported}; current desired-state vs live Support has ${live.count} mismatch(es): ${live.keys.join(', ')||'none'}.`});
  if(cache.desired&&live.count>0&&!knownForgeOnly)out.push({sev:'warn',title:'Live desired-state mismatch',detail:`Current mismatches: ${live.keys.join(', ')}.`});
  if(String(c?.status||'').toUpperCase()==='DUPLICATE_IGNORED')out.push({sev:'neutral',title:'Latest control receipt is terminal duplicate',detail:`${c?.request?.id||'request'} is not active work.`});
  if(!out.length)out.push({sev:'ok',title:'No high-signal contradiction detected',detail:'Current sanitized sources expose no major contradiction.'});
  return out.slice(0,6);
}'''
text,n=re.subn(r'function issueRows\(\)\{.*?\n\}',new_issues,text,count=1,flags=re.S)
if n!=1:
    raise SystemExit('issueRows replacement mismatch')

PATH.write_text(text,encoding='utf-8',newline='\n')
print('HQ_TRUTH_CURRENT_STATE_V3_PATCHED', PATH)
