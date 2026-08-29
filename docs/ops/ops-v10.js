const RAW='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/';

const WORKERS=[
 {key:'ollama',name:'Ollama',role:'Local inference',c:'#7fe38d'},
 {key:'bridge',name:'Bridge',role:'GitHub sync',c:'#4ad3ff'},
 {key:'tick',name:'Tick',role:'Health + telemetry',c:'#f56bd0'},
 {key:'build',name:'Build Lab',role:'Design Forge v3.6',c:'#ff9a3d'},
 {key:'benchmark',name:'Benchmark',role:'Regression + fitness',c:'#68d8ce'},
 {key:'staging',name:'Staging',role:'Policy-gated champion',c:'#ffe06b'},
 {key:'night',name:'Night Forge',role:'QA gate',c:'#b38cff'},
 {key:'reader',name:'Reader',role:'Read-only senses',c:'#ff6f61'},
 {key:'chat',name:'Chat',role:'Reasoning lane',c:'#9bb3ff'}
];

function esc(s){return String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
function owl(c){return `<svg class="owl" viewBox="0 0 120 120" aria-hidden="true"><path d="M27 48 Q20 36 23 19 Q32 25 40 25 Q49 18 60 18 Q71 18 80 25 Q89 25 97 19 Q100 36 93 48 Q100 55 97 67 Q94 79 84 88 Q74 98 60 98 Q46 98 36 88 Q26 79 23 67 Q20 55 27 48Z" fill="none" stroke="${c}" stroke-width="4.2" stroke-linecap="round" stroke-linejoin="round"/></svg>`}
function kevinProd(mode='idle',small=false){return `<div class="kevin-avatar-prod ${small?'small':''} mode-${mode}"><svg viewBox="0 0 120 120" aria-label="Kevin owl avatar"><circle class="kv-ring kv-detail5" cx="60" cy="59" r="53"/><ellipse class="kv-body" cx="60" cy="74" rx="38" ry="38"/><path class="kv-wing" d="M34 60 C27 64 24 74 25 86 C26 97 32 104 41 104 C40 94 39 82 40 72 C41 66 39 62 34 60 Z"/><path class="kv-wing" d="M86 60 C93 64 96 74 95 86 C94 97 88 104 79 104 C80 94 81 82 80 72 C79 66 81 62 86 60 Z"/><path class="kv-head" d="M26 48 Q19 35 22 19 Q31 25 40 25 Q49 18 60 18 Q71 18 80 25 Q89 25 98 19 Q101 35 94 48 Q100 56 97 66 Q94 78 84 86 Q74 94 60 94 Q46 94 36 86 Q26 78 23 66 Q20 56 26 48Z"/><ellipse class="kv-face" cx="44" cy="49" rx="22" ry="24"/><ellipse class="kv-face" cx="76" cy="49" rx="22" ry="24"/><path class="kv-face" d="M37 61 Q60 55 83 61 Q82 80 72 88 Q60 94 48 88 Q38 80 37 61Z"/><g class="kv-eyes"><circle class="kv-eye-white" cx="43" cy="48" r="15"/><circle class="kv-eye-white" cx="77" cy="48" r="15"/><circle class="kv-eye" cx="43" cy="50" r="7"/><circle class="kv-eye" cx="77" cy="50" r="7"/><circle class="kv-hi" cx="40.5" cy="46.5" r="2.1"/><circle class="kv-hi" cx="74.5" cy="46.5" r="2.1"/></g><g class="kv-xeyes"><path d="M35 40 L51 56 M51 40 L35 56 M69 40 L85 56 M85 40 L69 56" fill="none" stroke="#2a2724" stroke-width="4" stroke-linecap="round"/></g><path class="kv-beak" d="M54 60 Q60 56 66 60 L60 70 Z"/><path class="kv-brow kv-detail2" d="M32 35 Q42 29 51 35 M69 35 Q78 29 88 35"/><g class="kv-feather kv-detail3"><path d="M43 76 Q49 83 55 76"/><path d="M55 76 Q61 83 67 76"/><path d="M67 76 Q73 83 79 76"/><path d="M49 88 Q55 95 61 88"/><path d="M61 88 Q67 95 73 88"/></g><g class="kv-wingline kv-detail4"><path d="M29 77 Q34 73 38 77"/><path d="M29 90 Q34 86 39 90"/><path d="M91 77 Q86 73 82 77"/><path d="M91 90 Q86 86 81 90"/></g><ellipse class="kv-foot" cx="47" cy="108" rx="9" ry="5"/><ellipse class="kv-foot" cx="73" cy="108" rx="9" ry="5"/><circle class="kv-foot" cx="41" cy="110" r="2.5"/><circle class="kv-foot" cx="53" cy="110" r="2.5"/><circle class="kv-foot" cx="67" cy="110" r="2.5"/><circle class="kv-foot" cx="79" cy="110" r="2.5"/><g class="kv-bandage"><rect x="27" y="29" width="22" height="9" rx="3" fill="#eee1c7" stroke="#cdbb98" stroke-width="1.2" transform="rotate(-13 38 34)"/><path d="M32 29 L44 38 M44 29 L32 38" stroke="#c5ad83" stroke-width="1"/></g><ellipse class="kv-bruise" cx="88" cy="67" rx="7" ry="4" fill="rgba(118,80,136,.55)"/><g class="kv-bonk" fill="none" stroke="#d5ad68" stroke-width="2.4" stroke-linecap="round"><path d="M91 20 L96 13 M100 24 L108 21 M97 31 L103 37"/><circle cx="102" cy="14" r="2" fill="#d5ad68" stroke="none"/></g></svg></div>`}
function norm(v){return String(v||'').toLowerCase()}
function stateColor(st){return ({idle:'#69716a',ready:'#79c56a',working:'#79c56a',thinking:'#f0b74e',cooling:'#f0b74e',connecting:'#59b6ef',building:'#ff9a3d',degraded:'#e46f61',offline:'#353b36'})[st]||'#69716a'}
function workerState(key,d,s){
 const sup=s?.supervisor||{}, bw=s?.active_workers||{};
 if(key==='bridge') return d?.services?.bridge==='healthy'?'connecting':'degraded';
 if(key==='tick') return d?.services?.tick==='healthy'?'ready':'degraded';
 if(key==='ollama') return d?.services?.ollama==='healthy'?'ready':'degraded';
 if(key==='benchmark') return bw?.benchmark>0?'working':(s?.benchmark?.status==='PASS'?'ready':'degraded');
 if(key==='build') return bw?.design_forge>0?'building':(sup?.last_mission==='forge-v4'&&sup?.last_result&&!/THROTTLED|WAIT|BLOCK/i.test(sup.last_result)?'thinking':'ready');
 if(key==='night') return bw?.night_forge>0?'working':'ready';
 if(key==='reader') return 'ready';
 if(key==='staging') return 'ready';
 if(key==='chat') return d?.current_task?'thinking':'ready';
 return 'ready';
}
function stateLabel(st){return ({idle:'IDLE',ready:'READY',thinking:'THINKING',working:'WORKING',building:'BUILDING',connecting:'SYNCING',cooling:'COOLING',degraded:'DEGRADED',offline:'OFFLINE'})[st]||st.toUpperCase()}
function ringPositions(topology,count){
 const W=topology.clientWidth,H=topology.clientHeight;
 const cx=W/2, cy=H/2;
 const r=Math.min(W,H)*0.38;
 const start=-90;
 return Array.from({length:count},(_,i)=>{
   const ang=(start + i*(360/count))*Math.PI/180;
   return {x:cx + r*Math.cos(ang), y:cy + r*Math.sin(ang), ang};
 });
}
function lineBetween(topology,from,to,state){
 const sx=from.x, sy=from.y, ex=to.x, ey=to.y;
 const dx=ex-sx, dy=ey-sy, dist=Math.hypot(dx,dy) || 1;
 const startTrim=88, endTrim=54;
 const x1=sx + dx*(startTrim/dist), y1=sy + dy*(startTrim/dist);
 const x2=ex - dx*(endTrim/dist), y2=ey - dy*(endTrim/dist);
 const len=Math.max(0, Math.hypot(x2-x1,y2-y1));
 const ang=Math.atan2(y2-y1,x2-x1)*180/Math.PI;
 const el=document.createElement('div');
 const active=['thinking','working','building','connecting'].includes(state);
 el.className=`line state-${state}${active?' active':''}`;
 el.style.cssText=`left:${x1}px;top:${y1}px;width:${len}px;transform:rotate(${ang}deg);--statec:${stateColor(state)}`;
 topology.appendChild(el);
}
function centerMissionControl(s){
 const sup=s?.supervisor||{};
 const state=/THROTTLED|WAIT/i.test(sup?.last_result||'')?'COOLING':'READY';
 const cycle=sup?.cycle ?? '—';
 const detail=sup?.last_result || 'Mission control ready';
 const mission=sup?.last_mission || '—';
 const mc=document.getElementById('missionControlInfo');
 mc.innerHTML=`<div class="mc-title">Mission Control</div><div class="mc-row"><span class="mc-badge ${state.toLowerCase()}">${state}</span><span class="mc-text">cycle ${cycle} · ${esc(mission)}</span></div><div class="mc-detail">${esc(detail)}</div>`;
}
async function load(){
 let d={},s={};
 try{[d,s]=await Promise.all([fetch(RAW+'dashboard-state.json?'+Date.now()).then(r=>r.json()),fetch(RAW+'support-latest.json?'+Date.now()).then(r=>r.json())])}catch(e){document.getElementById('newsText').textContent='Telemetry fetch failed: '+e.message;return}
 const overall=norm(d?.health?.overall||d?.status||'unknown');
 const chip=document.getElementById('overallChip');chip.textContent=overall==='healthy'?'READY · OK':overall.toUpperCase();chip.className='chip '+(overall==='healthy'?'ok':'');
 const sup=s?.supervisor||{}, rec=s?.recovery||{}, bench=s?.benchmark||{};
 const detail=/THROTTLED/i.test(sup.last_result||'')?'Strategic missions cooling; recovery throttle is preventing duplicate work.':(sup.last_result?`Mission ${sup.last_mission||'—'} · ${sup.last_result}`:'Control plane healthy.');
 document.getElementById('newsText').textContent=`Chief of Staff | ${detail}`;
 const rail=document.getElementById('serviceRail');rail.innerHTML='';
 [['Reader','ready'],['Night Forge',(s?.active_workers?.night_forge||0)>0?'active':'ready'],['Build Lab',(s?.active_workers?.design_forge||0)>0?'active':'ready'],['Ollama',d?.services?.ollama==='healthy'?'ready':''],['Bridge',d?.services?.bridge==='healthy'?'sync':''],['Tick',d?.services?.tick==='healthy'?'ready':'']].forEach(([n,st])=>rail.insertAdjacentHTML('beforeend',`<div class="svc"><i class="dot ${st}"></i><b>${esc(n)}</b><span>${st==='active'?'ACTIVE':st==='sync'?'SYNC':st==='ready'?'READY':'CHECK'}</span></div>`));
 const top=document.getElementById('topology');top.querySelectorAll('.worker,.line').forEach(x=>x.remove());
 const center={x:top.clientWidth/2,y:top.clientHeight/2};
 const positions=ringPositions(top,WORKERS.length);
 let active=[];
 WORKERS.forEach((w,i)=>{
   const st=workerState(w.key,d,s);
   const p=positions[i];
   if(['thinking','working','building','connecting'].includes(st)) active.push(w);
   lineBetween(top,center,p,st);
   const el=document.createElement('div');
   el.className=`worker ${st}`;
   el.style.cssText=`left:${(p.x/top.clientWidth)*100}%;top:${(p.y/top.clientHeight)*100}%;--idc:${w.c};--statec:${stateColor(st)}`;
   el.innerHTML=`${owl(w.c)}<div class="box"><b>${w.name}</b><small>${w.role}</small><span class="state">${stateLabel(st)}</span></div>`;
   el.onclick=()=>selectWorker(w,st,d,s);
   top.appendChild(el);
 });
 const kstate=active.length?'WORKING':(/THROTTLED|WAIT/i.test(sup.last_result||'')?'COOLING':'READY');
 document.getElementById('kevinState').textContent=kstate==='WORKING'?'LOOP ACTIVE':kstate;
 const kmode=overall!=='healthy'?'degraded':(active.length?'working':'idle');
 document.getElementById('headerKevinProd').innerHTML=kevinProd(kmode,true);
 document.getElementById('hubKevinProd').innerHTML=kevinProd(kmode,false);
 centerMissionControl(s);
 document.getElementById('mission').textContent=sup.last_mission?`${sup.last_mission} · cycle ${sup.cycle??'—'}`:'No active mission';
 document.getElementById('action').textContent=/THROTTLED/i.test(sup.last_result||'')?'Recovery cooldown':(sup.last_result||'Ready for work');
 document.getElementById('recent').textContent=rec.last_brief?`Recovery ${rec.round||'—'} · ${rec.last_brief}`:(sup.last_result||'—');
 document.getElementById('evidence').textContent=bench.status?`Benchmark ${bench.status} ${bench.regression?.passed||0}/${bench.regression?.total||0}`:'HQ state snapshot';
 document.getElementById('activeWorkers').textContent=active.length?`${active.length} active`:'0 active · available lanes ready';
 document.getElementById('subagents').innerHTML=active.map(w=>owl(w.c).replace('class="owl"','class="subowl"')).join('');
 const at=new Date(d.generated_at||s.generated_at||Date.now()),age=Math.max(0,Math.round((Date.now()-at)/60000));document.getElementById('age').textContent=age+' min';document.getElementById('benchmark').textContent=bench.status?`Benchmark ${bench.status} · ${bench.regression?.passed||0}/${bench.regression?.total||0} · critical ${bench.regression?.critical_failures||0}`:'Benchmark unavailable';
 document.getElementById('load').textContent=`RAM ${d?.system?.memory_pct??'—'}% · CPU ${d?.system?.cpu_pct??'—'}%`;document.getElementById('loadDetail').textContent=`GPU ${d?.system?.gpu||'—'} ${d?.system?.gpu_pct??'—'}% · Brain ${d?.brain?.name||'—'}`;
 document.getElementById('selectedStatus').textContent=`${kstate} · cycle ${sup.cycle??'—'}`;document.getElementById('selectedDetail').textContent=detail;document.getElementById('updated').textContent=`Kevin HQ · telemetry ${at.toLocaleTimeString()} · schema ${d.schema??'—'}`;
}
function selectWorker(w,st,d,s){document.getElementById('selectedName').textContent=`${w.name} — ${w.role}`;document.getElementById('selectedStatus').textContent=stateLabel(st);let detail='Telemetry-backed worker state.';if(w.key==='benchmark')detail=`Regression ${s?.benchmark?.regression?.passed||0}/${s?.benchmark?.regression?.total||0}, critical failures ${s?.benchmark?.regression?.critical_failures||0}.`;if(w.key==='bridge')detail=`GitHub sync service: ${d?.services?.bridge||'unknown'}.`;if(w.key==='build')detail=`Design Forge workers active: ${s?.active_workers?.design_forge||0}.`;if(w.key==='ollama')detail=`Primary local inference service: ${d?.services?.ollama||'unknown'}.`;document.getElementById('selectedDetail').textContent=detail}

document.getElementById('headerKevinProd').innerHTML=kevinProd('idle',true);document.getElementById('hubKevinProd').innerHTML=kevinProd('idle',false);load();setInterval(load,60000);addEventListener('resize',()=>load());
