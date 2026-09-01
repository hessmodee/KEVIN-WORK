(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
if(!frame)return;

const BASE='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/';
const SOURCES={
  dashboard:{label:'Live dashboard',path:'reports/dashboard-state.json',kind:'periodic',fresh:120,delayed:360,claim:'current task / services / load'},
  support:{label:'Support',path:'reports/support-latest.json',kind:'periodic',fresh:360,delayed:900,claim:'platform / benchmark / workers'},
  engineering:{label:'Engineering',path:'reports/engineering/latest.json',kind:'periodic',fresh:300,delayed:720,claim:'relay / skills / UI Bridge'},
  autonomy:{label:'Autonomy',path:'reports/autonomy-latest.json',kind:'periodic',fresh:900,delayed:1800,claim:'work selection / drift'},
  control:{label:'Control plane',path:'reports/control-plane-latest.json',kind:'event',claim:'latest typed outcome'},
  desired:{label:'Desired state',path:'control-plane/desired-state-v1.json',kind:'checkpoint',claim:'owner-approved core identities'},
  workItems:{label:'Autonomy work items',path:'inbox/autonomy/work-items.json',kind:'checkpoint',claim:'blocked / eligible owner work'},
  transfer:{label:'Responsibility',path:'reports/responsibility-transfer-latest.json',kind:'checkpoint',claim:'T0-T5 checkpoint'},
  master:{label:'Autonomy scorecard',path:'reports/autonomy-master-scorecard.json',kind:'checkpoint',claim:'proof / transfer lanes'}
};

let cache={};
let lastFetch=0;
let lastFingerprint='';
let boundDoc=null;
let observer=null;
let refreshing=false;

const esc=v=>String(v??'').replace(/[&<>"']/g,m=>({
  '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
}[m]));

function parseTs(v){
  if(!v)return NaN;
  const s=String(v).trim().replace(/(\.\d{3})\d+(?=(?:Z|[+-]\d{2}:\d{2})$)/,'$1');
  const t=Date.parse(s);
  return Number.isFinite(t)?t:NaN;
}
function tsOf(x){return x?.generated_at||x?.at||x?.updated_at||x?.sync?.last||null}
function ageSec(v){const t=parseTs(v);return Number.isFinite(t)?Math.max(0,(Date.now()-t)/1000):Infinity}
function ageText(s){
  if(!Number.isFinite(s))return'unknown';
  if(s<60)return`${Math.round(s)}s`;
  if(s<3600)return`${Math.round(s/60)}m`;
  if(s<86400)return`${(s/3600).toFixed(s<7200?1:0)}h`;
  return`${(s/86400).toFixed(1)}d`;
}
function sourceState(k,obj){
  const d=SOURCES[k],a=ageSec(tsOf(obj));
  if(!obj)return{state:'MISSING',cls:'bad',age:a};
  if(d.kind==='checkpoint')return{state:'CHECKPOINT',cls:'neutral',age:a};
  if(d.kind==='event')return{state:a<=1800?'RECENT':'HISTORICAL',cls:a<=1800?'ok':'neutral',age:a};
  if(a<=d.fresh)return{state:'FRESH',cls:'ok',age:a};
  if(a<=d.delayed)return{state:'DELAYED',cls:'warn',age:a};
  return{state:'STALE',cls:'bad',age:a};
}
async function fetchJson(path){
  const r=await fetch(`${BASE}${path}?hqtruth=${Date.now()}`,{cache:'no-store'});
  if(!r.ok)throw new Error(`${path} ${r.status}`);
  return r.json();
}
function activeWorkers(s){return Object.values(s?.active_workers||{}).reduce((n,v)=>n+(Number(v)||0),0)}
function taskActive(t){
  if(!t)return false;
  return !/(done|complete|completed|failed|stopped|idle|queued|wait|cooldown|yield)/.test(String(t.phase||'').toLowerCase());
}
function workTruth(d,s){
  const t=d?.current_task,n=activeWorkers(s);
  if(taskActive(t))return{headline:t.title||t.id||'Active task',detail:`${t.phase||'active'} · ${t.source||'runtime'}`,cls:'working'};
  if(n>0)return{headline:`${n} active worker${n===1?'':'s'}`,detail:'Support reports active execution',cls:'working'};
  return{headline:'No active worker',detail:'Schedules and last_mission are not counted as work.',cls:'neutral'};
}
function platformTruth(s,d){
  const b=s?.benchmark||{};
  const badSvc=Object.values(d?.services||{}).some(v=>v&&String(v).toLowerCase()!=='healthy');
  const ok=s?.governance?.ok!==false&&s?.cron?.ok!==false&&String(b.status||'').toUpperCase()==='PASS'&&Number(b?.regression?.critical_failures||0)===0&&!badSvc;
  return{headline:ok?'HEALTHY':'DEGRADED',detail:`Benchmark ${b?.regression?.passed??'?'}/${b?.regression?.total??'?'} · critical ${b?.regression?.critical_failures??'?'}`,cls:ok?'ok':'bad'};
}
function workItem(id){return (cache.workItems?.items||[]).find(x=>String(x.id||'')===id)||null}
function liveCoreDrift(s,desired){
  const expected=desired?.core_hashes||{},observed=s?.hashes||{};
  const keys=['supervisor','benchmark','forge','goal_os','support_bridge','maintenance_runner'].filter(k=>expected[k]&&observed[k]&&String(expected[k]).toUpperCase()!==String(observed[k]).toUpperCase());
  return{count:keys.length,keys};
}
function forgeBlocked(){const w=workItem('finish-forge-v40-runtime-convergence');return !!w&&(w.blocked===true||String(w.status||'').toUpperCase()==='BLOCKED')}
function forgeActive(d,s){const t=d?.current_task||{};const tag=[t.id,t.title,t.category,t.source].join(' ');return (taskActive(t)&&/forge/i.test(tag))||Number(s?.active_workers?.design_forge||0)>0||Number(s?.active_workers?.night_forge||0)>0}
function autonomyTruth(a){
  if(!a)return{headline:'UNKNOWN',detail:'Autonomy snapshot missing',cls:'bad'};
  const st=sourceState('autonomy',a),live=liveCoreDrift(cache.support||{},cache.desired||{}),reported=Number(a.drift_count||0);
  if(st.state==='STALE')return{headline:'STALE EVIDENCE',detail:`${ageText(st.age)} old · last ${a.state||'unknown'}`,cls:'bad'};
  if(cache.desired&&cache.support&&reported!==live.count)return{headline:'RECONCILE',detail:`autonomy reports drift ${reported} · live desired/support comparison ${live.count}`,cls:'warn'};
  if(live.count===1&&live.keys[0]==='forge'&&forgeBlocked())return{headline:'KNOWN DRIFT',detail:`Forge trust pin intentionally held while replacement lane is blocked · ${a?.work_conserving?.status||'selection unknown'}`,cls:'neutral'};
  const v=String(a.state||'UNKNOWN').toUpperCase();
  return{headline:v,detail:`live drift ${live.count} · ${a?.work_conserving?.status||'selection unknown'}`,cls:v==='HEALTHY'?'ok':v==='NEEDS_REVIEW'?'warn':'neutral'};
}
function benchmarkTruth(s){
  const b=s?.benchmark||{};
  const ok=String(b.status||'').toUpperCase()==='PASS'&&Number(b?.regression?.critical_failures||0)===0;
  return{headline:ok?`${b?.regression?.passed??'?'} / ${b?.regression?.total??'?'}`:'NOT PASS',detail:`critical ${b?.regression?.critical_failures??'?'} · ${ageText(ageSec(b.at))} old`,cls:ok?'ok':'bad'};
}
function skillTruth(e){
  const c=e?.action?.composite_skills||{};
  return{headline:String(c.proven_count??'?'),detail:c.latest_proven?.key?`latest ${c.latest_proven.key}`:'No latest proven composite',cls:Number(c.proven_count)>0?'ok':'neutral'};
}
function dataTruth(){
  let fresh=0,total=0,problem=0;
  for(const[k,d]of Object.entries(SOURCES)){
    if(d.kind!=='periodic')continue;
    total++;
    const s=sourceState(k,cache[k]);
    if(s.state==='FRESH')fresh++;
    if(['STALE','MISSING'].includes(s.state))problem++;
  }
  return{headline:`${fresh}/${total} FRESH`,detail:problem?'Periodic evidence has stale/missing sources.':'Periodic evidence is inside freshness windows.',cls:problem?'bad':fresh===total?'ok':'warn'};
}
function issueRows(){
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
}
function proofRows(){
  const s=cache.support||{},e=cache.engineering||{},c=cache.control||{},out=[];
  if(s?.maintenance?.status)out.push({title:'Maintenance',value:s.maintenance.status,detail:`${s.maintenance.manifest_id||'—'} · ${ageText(ageSec(s.maintenance.at))} old`});
  if(s?.benchmark?.status)out.push({title:'Benchmark',value:`${s.benchmark.status} ${s?.benchmark?.regression?.passed??'?'}/${s?.benchmark?.regression?.total??'?'}`,detail:`critical ${s?.benchmark?.regression?.critical_failures??'?'}`});
  const p=e?.action?.composite_skills?.latest_proven;
  if(p)out.push({title:'Skill Lab',value:p.key,detail:`PROVEN · ${ageText(ageSec(p.proven_at))} old`});
  if(c?.status&&c.status!=='DUPLICATE_IGNORED')out.push({title:'Control plane',value:c.status,detail:c?.request?.verb||'—'});
  return out.slice(0,4);
}
function laneRows(){
  const t=cache.transfer||{},m=cache.master||{},byId=Object.fromEntries((m.lanes||[]).map(x=>[x.id,x]));
  const ids=['work-selection','hq-direct-chat','reader','skill-learning','staging','gmail','telegram'];
  const map={'work-selection':'autonomy_work_selection','hq-direct-chat':'hq_direct_chat',reader:'reader','skill-learning':'skill_lab_runtime',staging:'staging_validation',gmail:'gmail_owner_communication',telegram:'telegram_owner_communication'};
  return ids.map(id=>{
    const l=byId[id]||{};
    return{id,proof:l.proof||'CHECKPOINT NOT SET',transfer:l.transfer||t?.baseline?.[map[id]]||'?',detail:l.blocker||l.next_evidence||'No checkpoint detail'};
  });
}
function metric(label,x){
  return`<div class="hqtc-metric ${esc(x.cls)}"><div class="hqtc-k">${esc(label)}</div><div class="hqtc-v">${esc(x.headline)}</div><div class="hqtc-h">${esc(x.detail)}</div></div>`;
}
function installStyles(d){
  if(d.getElementById('hqTruthStyleV2'))return;
  const st=d.createElement('style');
  st.id='hqTruthStyleV2';
  st.textContent=`
#hqTruthConsole{margin:18px 0 0;padding:15px 17px;border-radius:16px;border:1px solid rgba(104,216,206,.20);background:linear-gradient(135deg,rgba(22,40,43,.90),rgba(18,23,17,.97));box-shadow:0 12px 34px rgba(0,0,0,.14);font-family:inherit;scroll-margin-top:60px}
.hqtc-top{display:flex;gap:12px;justify-content:space-between;align-items:flex-start;flex-wrap:wrap}.hqtc-title{font-size:14px;font-weight:760}.hqtc-sub,.hqtc-refresh,.hqtc-h{color:var(--muted,#969d92)}.hqtc-sub{font-size:10px;margin-top:3px;max-width:720px}.hqtc-refresh{font-size:9px;font-variant-numeric:tabular-nums}
.hqtc-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:7px;margin-top:11px}@media(min-width:900px){.hqtc-grid{grid-template-columns:repeat(6,minmax(0,1fr))}}
.hqtc-metric{padding:9px 10px;border:1px solid rgba(255,255,255,.07);border-radius:11px;background:rgba(255,255,255,.022);min-width:0}.hqtc-metric.ok{border-color:rgba(143,170,130,.28)}.hqtc-metric.warn{border-color:rgba(213,173,104,.32)}.hqtc-metric.bad{border-color:rgba(211,109,91,.36)}.hqtc-metric.working{border-color:rgba(104,216,206,.34)}
.hqtc-k{font-size:8px;letter-spacing:.12em;text-transform:uppercase;color:var(--muted,#969d92)}.hqtc-v{font-size:14px;font-weight:760;margin-top:3px;overflow-wrap:anywhere}.hqtc-h{font-size:9px;line-height:1.35;margin-top:3px}
.hqtc-columns{display:grid;grid-template-columns:1fr;gap:9px;margin-top:9px}@media(min-width:900px){.hqtc-columns{grid-template-columns:1.15fr .85fr}}.hqtc-box{border:1px solid rgba(255,255,255,.065);border-radius:11px;padding:9px 11px}.hqtc-box h4{font-size:9px;letter-spacing:.12em;text-transform:uppercase;color:var(--muted,#969d92);margin:0 0 5px}
.hqtc-item{padding:6px 0;border-top:1px solid rgba(255,255,255,.055)}.hqtc-item:first-of-type{border-top:0}.hqtc-item b{font-size:11px}.hqtc-item div{font-size:9px;color:var(--muted,#969d92);line-height:1.4;margin-top:2px}.hqtc-item.bad b{color:#f1b3a8}.hqtc-item.warn b{color:#efd9ae}.hqtc-item.ok b{color:#dcebd5}
.hqtc-detail{margin-top:9px;border-top:1px solid rgba(255,255,255,.065);padding-top:8px}.hqtc-detail summary{cursor:pointer;user-select:none;font-size:9px;color:var(--muted,#969d92);letter-spacing:.08em;text-transform:uppercase;padding:3px 0}
.hqtc-source{display:grid;grid-template-columns:minmax(130px,1fr) 55px 72px minmax(150px,1fr);gap:7px;align-items:center;padding:6px 0;border-top:1px solid rgba(255,255,255,.05);font-size:9px}.hqtc-source span:first-child{display:flex;flex-direction:column}.hqtc-source small,.hqtc-source time{color:var(--muted,#969d92)}.hqtc-source code{font-size:8px;color:#b9d5e6;overflow:hidden;text-overflow:ellipsis}.hqtc-source time{grid-column:1/-1;font-size:8px}
.hqtc-pill{justify-self:start;border-radius:999px;padding:3px 6px;font-size:8px}.hqtc-pill.ok{background:rgba(143,170,130,.16);color:#dcebd5}.hqtc-pill.warn{background:rgba(213,173,104,.15);color:#efd9ae}.hqtc-pill.bad{background:rgba(211,109,91,.16);color:#f1b3a8}.hqtc-pill.neutral{background:rgba(255,255,255,.06);color:var(--muted,#969d92)}
.hqtc-lanes{display:grid;grid-template-columns:1fr;gap:5px;margin-top:7px}@media(min-width:800px){.hqtc-lanes{grid-template-columns:repeat(2,minmax(0,1fr))}}.hqtc-lane{padding:7px;border:1px solid rgba(255,255,255,.055);border-radius:8px}.hqtc-lane b{font-size:10px}.hqtc-lane span{float:right;font-size:8px;color:#b9d5e6}.hqtc-lane div{clear:both;font-size:8px;color:var(--muted,#969d92);margin-top:3px;line-height:1.35}
@media(max-width:650px){#hqTruthConsole{padding:13px}.hqtc-source{grid-template-columns:1fr auto auto}.hqtc-source code,.hqtc-source time{grid-column:1/-1}}
`;
  d.head.appendChild(st);
}
function ensureHost(){
  let d;
  try{d=frame.contentDocument}catch(_e){return null}
  if(!d?.body)return null;
  installStyles(d);
  const main=d.getElementById('main');
  if(!main)return null;
  let host=d.getElementById('hqTruthConsole');
  if(!host){
    host=d.createElement('section');
    host.id='hqTruthConsole';
    main.insertAdjacentElement('afterend',host);
  }else if(host.previousElementSibling!==main){
    main.insertAdjacentElement('afterend',host);
  }
  return host;
}
function detailsState(host){
  const out={};
  host?.querySelectorAll('details[data-key]').forEach(x=>{out[x.dataset.key]=x.open});
  return out;
}
function restoreDetails(host,state){
  host?.querySelectorAll('details[data-key]').forEach(x=>{
    if(Object.prototype.hasOwnProperty.call(state,x.dataset.key))x.open=!!state[x.dataset.key];
  });
}
function sourceRows(){
  return Object.entries(SOURCES).map(([k,d])=>{
    const obj=cache[k],st=sourceState(k,obj);
    return`<div class="hqtc-source" data-source="${esc(k)}"><span><b>${esc(d.label)}</b><small>${esc(d.claim)}</small></span><span class="hqtc-age">${esc(ageText(st.age))}</span><span class="hqtc-pill ${esc(st.cls)}">${esc(st.state)}</span><code>${esc(d.path)}</code><time>${esc(tsOf(obj)||'—')}</time></div>`;
  }).join('');
}
function currentFingerprint(){
  const pairs=Object.keys(SOURCES).map(k=>{
    const x=cache[k];
    return[k,[
      tsOf(x),
      x?.state,
      x?.status,
      x?.drift_count,
      x?.latest_evaluation?.iteration,
      x?.maintenance?.status
    ]];
  });
  return JSON.stringify(Object.fromEntries(pairs));
}
function render(force=false){
  const host=ensureHost();
  if(!host)return;
  const fingerprint=currentFingerprint();
  if(!force&&fingerprint===lastFingerprint){
    updateAges();
    return;
  }

  const open=detailsState(host);
  const s=cache.support||{},d=cache.dashboard||{},e=cache.engineering||{},a=cache.autonomy||{};
  const truth={
    platform:platformTruth(s,d),
    work:workTruth(d,s),
    autonomy:autonomyTruth(a),
    bench:benchmarkTruth(s),
    skills:skillTruth(e),
    data:dataTruth()
  };
  const issues=issueRows(),proof=proofRows(),lanes=laneRows();

  host.innerHTML=`
<div class="hqtc-top">
  <div><div class="hqtc-title">HQ Truth</div><div class="hqtc-sub">Bottom-mounted observability. It does not redraw tab content or control Kevin.</div></div>
  <div class="hqtc-refresh">updated ${new Date(lastFetch||Date.now()).toLocaleTimeString()}</div>
</div>
<div class="hqtc-grid">${metric('Platform',truth.platform)}${metric('Work now',truth.work)}${metric('Autonomy',truth.autonomy)}${metric('Benchmark',truth.bench)}${metric('Proven skills',truth.skills)}${metric('Data quality',truth.data)}</div>
<div class="hqtc-columns">
  <div class="hqtc-box"><h4>Attention</h4>${issues.map(x=>`<div class="hqtc-item ${esc(x.sev)}"><b>${esc(x.title)}</b><div>${esc(x.detail)}</div></div>`).join('')}</div>
  <div class="hqtc-box"><h4>Recent proof</h4>${proof.length?proof.map(x=>`<div class="hqtc-item ok"><b>${esc(x.title)} · ${esc(x.value)}</b><div>${esc(x.detail)}</div></div>`).join(''):'<div class="hqtc-item"><b>No current proof item</b></div>'}</div>
</div>
<details class="hqtc-detail" data-key="lanes"><summary>Proof / responsibility lanes</summary><div class="hqtc-lanes">${lanes.map(l=>`<div class="hqtc-lane"><b>${esc(l.id.replace(/-/g,' '))}</b><span>${esc(l.transfer)} · ${esc(l.proof)}</span><div>${esc(l.detail)}</div></div>`).join('')}</div></details>
<details class="hqtc-detail" data-key="sources"><summary>Source ledger</summary><div>${sourceRows()}</div></details>`;

  restoreDetails(host,open);
  lastFingerprint=fingerprint;
}
function updateAges(){
  const host=ensureHost();
  if(!host)return;
  const r=host.querySelector('.hqtc-refresh');
  if(r)r.textContent=`updated ${new Date(lastFetch||Date.now()).toLocaleTimeString()}`;
  host.querySelectorAll('[data-source]').forEach(row=>{
    const k=row.dataset.source,obj=cache[k],st=sourceState(k,obj);
    const age=row.querySelector('.hqtc-age'),pill=row.querySelector('.hqtc-pill');
    if(age)age.textContent=ageText(st.age);
    if(pill){pill.textContent=st.state;pill.className=`hqtc-pill ${st.cls}`}
  });
}
async function refresh(){
  if(refreshing)return;
  refreshing=true;
  try{
    const entries=await Promise.all(Object.entries(SOURCES).map(async([k,d])=>{
      try{return[k,await fetchJson(d.path)]}catch(_e){return[k,null]}
    }));
    cache=Object.fromEntries(entries);
    lastFetch=Date.now();
    render();
  }finally{
    refreshing=false;
  }
}
function bind(){
  let d,w;
  try{d=frame.contentDocument;w=frame.contentWindow}catch(_e){return}
  if(!d?.body||boundDoc===d)return;
  boundDoc=d;
  if(observer)observer.disconnect();
  ensureHost();
  render(true);
  const main=d.getElementById('main');
  if(main&&'MutationObserver'in window){
    observer=new MutationObserver(()=>ensureHost());
    observer.observe(main,{childList:true});
  }
  w?.addEventListener('hashchange',()=>ensureHost());
}
frame.addEventListener('load',()=>{bind();refresh()});
setTimeout(()=>{bind();refresh()},0);
setInterval(refresh,30000);
setInterval(updateAges,30000);
})();
