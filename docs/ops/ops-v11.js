const RAW='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/';

const STATE_COLORS={
 ready:'#68d8ce',
 working:'#79c56a',
 building:'#f06dbb',
 cooldown:'#b38cff',
 degraded:'#ff9a3d',
 disabled:'#81887f',
 offline:'#e46f61'
};

const WORKERS=[
 {key:'ollama',name:'Ollama',role:'Local inference',c:'#7fe38d'},
 {key:'bridge',name:'Bridge',role:'GitHub sync',c:'#4ad3ff'},
 {key:'tick',name:'Tick',role:'Health + telemetry',c:'#f56bd0'},
 {key:'build',name:'Build Lab',role:'Candidate design',c:'#ff9a3d'},
 {key:'benchmark',name:'Benchmark',role:'Regression + fitness',c:'#68d8ce'},
 {key:'staging',name:'Staging',role:'Policy-gated champion',c:'#ffe06b'},
 {key:'night',name:'Night Forge',role:'QA gate',c:'#b38cff'},
 {key:'reader',name:'Reader',role:'Read-only senses',c:'#ff6f61'},
 {key:'chat',name:'Chat',role:'Reasoning lane',c:'#9bb3ff'}
];

function esc(s){return String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
function norm(v){return String(v||'').toLowerCase()}
function stateColor(st){return STATE_COLORS[st]||STATE_COLORS.degraded}
function stateLabel(st){return ({ready:'READY',working:'WORKING',building:'BUILDING',cooldown:'COOLDOWN',degraded:'DEGRADED',disabled:'DISABLED',offline:'OFFLINE'})[st]||String(st||'').toUpperCase()}
function nightForgeTaskState(s){return String(s?.public_truth?.night_forge_task_state||'').trim()}
function nightForgeHidden(s){const st=nightForgeTaskState(s).toLowerCase();return st==='disabled'||st==='absent'}
function owl(c,id='worker'){
 const safe=String(id||'worker').replace(/[^a-z0-9_-]/gi,'-');
 const mid=`owl-cut-${safe}`;
 return `<svg class="owl" viewBox="0 0 120 120" aria-hidden="true"><defs><mask id="${mid}"><rect width="120" height="120" fill="white"/><circle cx="46" cy="50" r="7.5" fill="black"/><circle cx="74" cy="50" r="7.5" fill="black"/></mask></defs><path class="owl-body" d="M27 48 Q20 36 23 19 Q32 25 40 25 Q49 18 60 18 Q71 18 80 25 Q89 25 97 19 Q100 36 93 48 Q100 55 97 67 Q94 79 84 88 Q74 98 60 98 Q46 98 36 88 Q26 79 23 67 Q20 55 27 48Z" mask="url(#${mid})" fill="none" stroke="${c}" stroke-width="4.2" stroke-linecap="round" stroke-linejoin="round"/><g class="owl-feet" fill="none" stroke="${c}" stroke-width="4" stroke-linecap="round"><path d="M42 101 Q47 106 52 101 M45 105 L43 109 M49 105 L50 109"/><path d="M68 101 Q73 106 78 101 M71 105 L70 109 M75 105 L77 109"/></g></svg>`
}
function kevinProd(mode='ready',small=false){return `<div class="kevin-avatar-prod ${small?'small':''} mode-${mode}"><svg viewBox="0 0 120 120" aria-label="Kevin owl avatar"><circle class="kv-ring kv-detail5" cx="60" cy="59" r="53"/><ellipse class="kv-body" cx="60" cy="74" rx="38" ry="38"/><path class="kv-wing" d="M34 60 C27 64 24 74 25 86 C26 97 32 104 41 104 C40 94 39 82 40 72 C41 66 39 62 34 60 Z"/><path class="kv-wing" d="M86 60 C93 64 96 74 95 86 C94 97 88 104 79 104 C80 94 81 82 80 72 C79 66 81 62 86 60 Z"/><path class="kv-head" d="M26 48 Q19 35 22 19 Q31 25 40 25 Q49 18 60 18 Q71 18 80 25 Q89 25 98 19 Q101 35 94 48 Q100 56 97 66 Q94 78 84 86 Q74 94 60 94 Q46 94 36 86 Q26 78 23 66 Q20 56 26 48Z"/><ellipse class="kv-face" cx="44" cy="49" rx="22" ry="24"/><ellipse class="kv-face" cx="76" cy="49" rx="22" ry="24"/><path class="kv-face" d="M37 61 Q60 55 83 61 Q82 80 72 88 Q60 94 48 88 Q38 80 37 61Z"/><g class="kv-eyes"><circle class="kv-eye-white" cx="43" cy="48" r="15"/><circle class="kv-eye-white" cx="77" cy="48" r="15"/><circle class="kv-eye" cx="43" cy="50" r="7"/><circle class="kv-eye" cx="77" cy="50" r="7"/><circle class="kv-hi" cx="40.5" cy="46.5" r="2.1"/><circle class="kv-hi" cx="74.5" cy="46.5" r="2.1"/></g><g class="kv-xeyes"><path d="M35 40 L51 56 M51 40 L35 56 M69 40 L85 56 M85 40 L69 56" fill="none" stroke="#2a2724" stroke-width="4" stroke-linecap="round"/></g><path class="kv-beak" d="M54 60 Q60 56 66 60 L60 70 Z"/><path class="kv-brow kv-detail2" d="M32 35 Q42 29 51 35 M69 35 Q78 29 88 35"/><g class="kv-feather kv-detail3"><path d="M43 76 Q49 83 55 76"/><path d="M55 76 Q61 83 67 76"/><path d="M67 76 Q73 83 79 76"/><path d="M49 88 Q55 95 61 88"/><path d="M61 88 Q67 95 73 88"/></g><g class="kv-wingline kv-detail4"><path d="M29 77 Q34 73 38 77"/><path d="M29 90 Q34 86 39 90"/><path d="M91 77 Q86 73 82 77"/><path d="M91 90 Q86 86 81 90"/></g><ellipse class="kv-foot" cx="47" cy="108" rx="9" ry="5"/><ellipse class="kv-foot" cx="73" cy="108" rx="9" ry="5"/><circle class="kv-foot" cx="41" cy="110" r="2.5"/><circle class="kv-foot" cx="53" cy="110" r="2.5"/><circle class="kv-foot" cx="67" cy="110" r="2.5"/><circle class="kv-foot" cx="79" cy="110" r="2.5"/><g class="kv-bandage"><rect x="27" y="29" width="22" height="9" rx="3" fill="#eee1c7" stroke="#cdbb98" stroke-width="1.2" transform="rotate(-13 38 34)"/><path d="M32 29 L44 38 M44 29 L32 38" stroke="#c5ad83" stroke-width="1"/></g><ellipse class="kv-bruise" cx="88" cy="67" rx="7" ry="4" fill="rgba(118,80,136,.55)"/><g class="kv-bonk" fill="none" stroke="#d5ad68" stroke-width="2.4" stroke-linecap="round"><path d="M91 20 L96 13 M100 24 L108 21 M97 31 L103 37"/><circle cx="102" cy="14" r="2" fill="#d5ad68" stroke="none"/></g></svg></div>`}

function msOf(v){const n=Number(v||0);return Number.isFinite(n)?n:0}
function cronJob(s,key){return (s?.cron?.jobs||[]).find(j=>j?.declaration_key===key)||null}
function recentlyRan(job,withinMs){const at=msOf(job?.last_run_at_ms);return at>0 && Math.abs(Date.now()-at)<=withinMs}
function taskActive(t){if(!t)return false;const p=norm(t.phase);return !/yield|cooldown|wait|skip|queued|idle|armed|complete|completed|done|stopped|failed|rejected|cancelled/.test(p)}
function taskText(t){return `${norm(t?.id)} ${norm(t?.title)} ${norm(t?.category)} ${norm(t?.phase)} ${norm(t?.source)}`}
function telemetryAgeMs(d,s){const vals=[d?.generated_at,s?.generated_at].map(v=>Date.parse(v||'')).filter(Number.isFinite);return vals.length?Math.max(0,Date.now()-Math.max(...vals)):Infinity}
function telemetryOffline(d,s){return telemetryAgeMs(d,s)>15*60*1000}


function clampPct(v){const n=Number(v);return Number.isFinite(n)?Math.max(0,Math.min(100,Math.round(n))):null}
function progressFromObject(o){
 if(!o||typeof o!=='object')return null;
 for(const k of ['progress_pct','percent','pct']){const p=clampPct(o[k]);if(p!==null)return p}
 const done=Number(o.completed??o.done),total=Number(o.total);
 if(Number.isFinite(done)&&Number.isFinite(total)&&total>0&&done>=0)return clampPct((done/total)*100);
 return null;
}
function taskMatchesWorker(key,t){
 const tt=taskText(t);
 if(key==='build')return /design forge|forge|build|builder|mission factory/.test(tt);
 if(key==='night')return /night[- ]forge|night forge|qa\/regression/.test(tt);
 if(key==='benchmark')return /benchmark|regression/.test(tt);
 if(key==='reader')return /reader|read-only|research|source review/.test(tt);
 if(key==='staging')return /staging|promotion|champion/.test(tt);
 if(key==='chat')return /chat|reasoning|analysis|planning|conversation/.test(tt);
 if(key==='ollama')return taskActive(t);
 return false;
}
function workerProgress(key,state,d,s){
 if(!['working','building'].includes(state))return null;
 const candidates=[s?.worker_progress?.[key],d?.worker_progress?.[key],d?.ops_floor?.progress?.[key]];
 for(const c of candidates){const p=progressFromObject(c);if(p!==null)return {percent:p,measured:true,detail:'Explicit worker progress telemetry'}}
 const t=d?.current_task||null;
 if(taskActive(t)&&taskMatchesWorker(key,t)){
   const p=progressFromObject(t);
   if(p!==null)return {percent:p,measured:true,detail:'Confirmed task checkpoints'};
   return {percent:0,measured:false,detail:'Active; no completed progress checkpoint has been reported yet'};
 }
 if(key==='bridge'||key==='tick')return {percent:100,measured:true,detail:'Most recent scheduled cycle completed'};
 return {percent:0,measured:false,detail:'Active; awaiting explicit progress telemetry'};
}


function workerState(key,d,s){
 const fresh=x=>{const age=Date.now()-Date.parse(x?.generated_at||'');return Number.isFinite(age)&&age>=-60000&&age<=600000};
 const bw=fresh(s)?s?.active_workers||{}:{};
 const t=fresh(d)?d?.current_task||null:null;
 const tt=taskText(t);
 if(telemetryOffline(d,s)) return 'offline';
 if(key==='bridge'){
   if(norm(d?.services?.bridge)!=='healthy')return 'degraded';
   return Number(bw.bridge)>0?'working':'ready';
 }
 if(key==='tick'){
   if(norm(d?.services?.tick)!=='healthy')return 'degraded';
   return Number(bw.tick)>0?'working':'ready';
 }
 if(key==='ollama'){
   if(norm(d?.services?.ollama)!=='healthy')return 'degraded';
   return taskActive(t)&&Number(d?.system?.gpu_pct||0)>=20?'working':'ready';
 }
 if(key==='benchmark'){
   if((bw?.benchmark||0)>0||(taskActive(t)&&/benchmark/.test(tt)))return 'working';
   return norm(s?.benchmark?.status)==='pass'?'ready':'degraded';
 }
 if(key==='build'){
   if((bw?.design_forge||0)>0||(taskActive(t)&&/design forge|forge|build|builder/.test(tt)))return 'building';
   return 'ready';
 }
 if(key==='night'){
   const nfts=nightForgeTaskState(s).toLowerCase();
   if(nfts==='disabled'||nfts==='absent')return 'disabled';
   if((bw?.night_forge||0)>0||nfts==='running'||(taskActive(t)&&/night[- ]forge|night forge|qa\/regression/.test(tt)))return 'working';
   return 'ready';
 }
 if(key==='reader'){
   if(Number(bw.reader)>0||(taskActive(t)&&/reader|read-only|research|source review/.test(tt)))return 'working';
   return 'ready';
 }
 if(key==='staging'){
   if(Number(bw.staging)>0||(taskActive(t)&&/staging|promotion|champion/.test(tt)))return 'working';
   return 'ready';
 }
 if(key==='chat'){
   if(Number(bw.chat)>0||(taskActive(t)&&/chat|reasoning|analysis|planning|conversation/.test(tt)))return 'working';
   return 'ready';
 }
 return 'ready';
}

function kevinStates(d,s){
 if(telemetryOffline(d,s))return ['offline'];
 const health=norm(d?.health?.overall||d?.status);
 if(health && health!=='healthy' && health!=='ready')return ['degraded'];
 if(['bridge','tick','ollama','gateway'].some(k=>d?.services?.[k]&&norm(d.services[k])!=='healthy'))return ['degraded'];
 const active=new Set();
 for(const w of WORKERS){
   if(['bridge','tick'].includes(w.key))continue;
   const st=workerState(w.key,d,s);
   if(st==='building')active.add('building');
   else if(st==='working')active.add('working');
 }
 if(Number(s?.active_workers?.supervisor||0)>0)active.add('working');
 if(active.size){
   const out=[];
   if(active.has('building'))out.push('building');
   if(active.has('working'))out.push('working');
   return out;
 }
 if(/THROTTLED|SATURATED|WAIT|COOL/i.test(s?.supervisor?.last_result||''))return ['cooldown'];
 return ['ready'];
}
function kevinState(d,s){return kevinStates(d,s)[0]}

function ringPositions(topology,count){
 const W=topology.clientWidth,H=topology.clientHeight,cx=W/2,cy=H/2,r=Math.min(W,H)*0.38,start=-90;
 return Array.from({length:count},(_,i)=>{const ang=(start+i*(360/count))*Math.PI/180;return{x:cx+r*Math.cos(ang),y:cy+r*Math.sin(ang),ang}})
}
function lineBetween(topology,from,to,state){
 const sx=from.x,sy=from.y,ex=to.x,ey=to.y,dx=ex-sx,dy=ey-sy,dist=Math.hypot(dx,dy)||1;
 const startTrim=96,endTrim=56,x1=sx+dx*(startTrim/dist),y1=sy+dy*(startTrim/dist),x2=ex-dx*(endTrim/dist),y2=ey-dy*(endTrim/dist);
 const len=Math.max(0,Math.hypot(x2-x1,y2-y1)),ang=Math.atan2(y2-y1,x2-x1)*180/Math.PI;
 const active=['working','building'].includes(state),el=document.createElement('div');
 el.className=`line state-${state}${active?' active':''}`;
 el.style.cssText=`left:${x1}px;top:${y1}px;width:${len}px;transform:rotate(${ang}deg);--statec:${stateColor(state)}`;
 topology.appendChild(el)
}
function renderKevinCenter(d,s,states){
 const sup=s?.supervisor||{},badge=document.getElementById('kevinState'),list=Array.isArray(states)?states:[states];
 badge.className='kevin-states';
 badge.innerHTML=list.map(st=>`<span class="loop state-${st}" style="--kstatec:${stateColor(st)}">${stateLabel(st)}</span>`).join('<span class="state-plus">+</span>');
 const mission=sup?.last_mission||'No mission selected',cycle=sup?.cycle??'—';
 document.getElementById('kevinMeta').innerHTML=`<div><b>Autonomy loop enabled</b> · cycle ${esc(cycle)}</div><div>${esc(mission)}${sup?.last_result?' · '+esc(sup.last_result):''}</div>`;
}

async function load(){
 let d={},s={};
 try{[d,s]=await Promise.all([fetch(RAW+'dashboard-state.json?'+Date.now()).then(r=>r.json()),fetch(RAW+'support-latest.json?'+Date.now()).then(r=>r.json())])}catch(e){document.getElementById('newsText').textContent='Telemetry fetch failed: '+e.message;document.getElementById('kevinState').innerHTML='<span class="loop state-offline" style="--kstatec:#e46f61">OFFLINE</span>';return}
 const overall=norm(d?.health?.overall||d?.status||'unknown'),chip=document.getElementById('overallChip');
 chip.textContent=overall==='healthy'?'HEALTHY':overall.toUpperCase();chip.className='chip '+(overall==='healthy'?'ok':'');
 const sup=s?.supervisor||{},rec=s?.recovery||{},bench=s?.benchmark||{};
 const detail=/THROTTLED|SATURATED/i.test(sup.last_result||'')?'Recovery cooldown is active after bounded recovery attempts.':(sup.last_result?`Mission ${sup.last_mission||'—'} · ${sup.last_result}`:'Control plane healthy.');
 document.getElementById('newsText').textContent=`Chief of Staff | ${detail}`;
 const rail=document.getElementById('serviceRail');rail.innerHTML='';
 [['Reader','ready'],['Night Forge',(s?.active_workers?.night_forge||0)>0?'active':'ready'],['Build Lab',(s?.active_workers?.design_forge||0)>0?'active':'ready'],['Ollama',d?.services?.ollama==='healthy'?'ready':''],['Bridge',workerState('bridge',d,s)==='working'?'active':(d?.services?.bridge==='healthy'?'ready':'')],['Tick',d?.services?.tick==='healthy'?'ready':'']].filter(([n])=>n!=='Night Forge'||!nightForgeHidden(s)).forEach(([n,st])=>rail.insertAdjacentHTML('beforeend',`<div class="svc"><i class="dot ${st}"></i><b>${esc(n)}</b><span>${st==='active'?'ACTIVE':st==='ready'?'READY':'CHECK'}</span></div>`));
 const top=document.getElementById('topology');top.querySelectorAll('.worker,.line').forEach(x=>x.remove());
 const visibleWorkers=WORKERS.filter(w=>w.key!=='night'||!nightForgeHidden(s));
 const center={x:top.clientWidth/2,y:top.clientHeight/2},positions=ringPositions(top,visibleWorkers.length),active=[];
 visibleWorkers.forEach((w,i)=>{const st=workerState(w.key,d,s),p=positions[i];if(['working','building'].includes(st))active.push({w,st});lineBetween(top,center,p,st);const prog=workerProgress(w.key,st,d,s),el=document.createElement('div');el.className=`worker ${st}`;el.style.cssText=`left:${(p.x/top.clientWidth)*100}%;top:${(p.y/top.clientHeight)*100}%;--idc:${w.c};--statec:${stateColor(st)}`;const progressHtml=prog?`<div class="worker-progress ${prog.measured?'measured':'checkpoint-wait'}" title="${esc(prog.detail)}"><div class="worker-progress-fill" style="width:${prog.percent}%"></div><span>${prog.percent}%</span></div>`:'';el.innerHTML=`<div class="box">${owl(w.c,w.key)}<div class="worker-copy"><b>${w.name}</b><small>${w.role}</small><span class="state">${stateLabel(st)}</span></div></div>${progressHtml}`;el.onclick=()=>selectWorker(w,st,d,s);top.appendChild(el)});
 window.__kevinLaneSnapshot={dashboard:d,support:s};
 const kstates=kevinStates(d,s),ks=kstates[0],kmode=ks==='offline'?'disconnected':ks==='degraded'?'degraded':kstates.some(x=>['working','building'].includes(x))?'working':'ready';
 document.getElementById('headerKevinProd').innerHTML=kevinProd(kmode,true);document.getElementById('hubKevinProd').innerHTML=kevinProd(kmode,false);renderKevinCenter(d,s,kstates);
 const liveTask=taskActive(d?.current_task)?d.current_task:null;
 document.getElementById('mission').textContent=liveTask?(liveTask.title||liveTask.id||'Active task'):(sup.last_mission?`${sup.last_mission} · cycle ${sup.cycle??'—'}`:'No active mission');
 document.getElementById('action').textContent=liveTask?`${liveTask.phase||'active'} · ${kstates.map(stateLabel).join(' + ')}`:(/THROTTLED|SATURATED/i.test(sup.last_result||'')?'Recovery cooldown':(sup.last_result||'Ready for work'));
 document.getElementById('recent').textContent=rec.last_brief?`Recovery ${rec.round||'—'} · ${rec.last_brief}`:(sup.last_result||'—');
 document.getElementById('evidence').textContent=bench.status?`Benchmark ${bench.status} ${bench.regression?.passed||0}/${bench.regression?.total||0}`:'HQ state snapshot';
 document.getElementById('activeWorkers').textContent=active.length?`${active.length} active · ${active.map(a=>a.w.name).join(', ')}`:'0 active · available lanes ready';document.getElementById('activeWorkers').title=active.map(a=>`${a.w.name}: ${stateLabel(a.st)}`).join(' · ');document.getElementById('subagents').innerHTML=active.map(a=>owl(a.w.c,a.w.key+'-sub').replace('class="owl"',`class="subowl ${a.st}"`)).join('');
 const at=new Date(d.generated_at||s.generated_at||Date.now()),age=Math.max(0,Math.round((Date.now()-at)/60000));document.getElementById('age').textContent=age+' min';document.getElementById('benchmark').textContent=bench.status?`Benchmark ${bench.status} · ${bench.regression?.passed||0}/${bench.regression?.total||0} · critical ${bench.regression?.critical_failures||0}`:'Benchmark unavailable';
 document.getElementById('load').textContent=`RAM ${d?.system?.memory_pct??'—'}% · CPU ${d?.system?.cpu_pct??'—'}%`;document.getElementById('loadDetail').textContent=`GPU ${d?.system?.gpu||'—'} ${d?.system?.gpu_pct??'—'}% · Brain ${d?.brain?.name||'—'}`;
 document.getElementById('selectedStatus').textContent=`${kstates.map(stateLabel).join(' + ')} · cycle ${sup.cycle??'—'}`;document.getElementById('selectedDetail').textContent=`Kevin aggregate state from live worker lanes. ${detail}`;document.getElementById('updated').textContent=`Kevin HQ · telemetry ${at.toLocaleTimeString()} · schema ${d.schema??'—'}`;
}
function workerEvidenceDetail(key,d,s){
 const jobs=s?.cron?.jobs||[],j=jobs.find(x=>x.declaration_key===(key==='tick'?'kevin-hq-live-pulse-v15':'kevin-support-bridge-v1'));
 const stamp=value=>{const t=Number(value);return t>0?new Date(t).toLocaleString():'not reported'};
 if(key==='tick'||key==='bridge')return `${key==='tick'?'Health and telemetry':'GitHub sync'} is a scheduled service. Last run: ${stamp(j?.last_run_at_ms)}; result: ${j?.last_run_status||j?.last_status||'unknown'}. A completed cycle is not a currently running task.`;
 const state=workerState(key,d,s),working=state==='working'||state==='building';
 const reports={reader:'Reader has an isolated read-only tool path. Its historical E2E receipt and main-chat access are separate proofs.',staging:'Staging validates candidates through policy gates. No active candidate means no staging work.',chat:'Chat responds to owner conversations. Private chat activity is not published as a live worker counter.'};
 if(reports[key])return `${reports[key]} ${working?'Current execution is attributed to this lane.':'No current execution is attributed to this lane; READY alone does not prove tool access or autonomous use.'}`;
 return '';
}
function selectWorker(w,st,d,s){document.getElementById('selectedName').textContent=`${w.name} — ${w.role}`;document.getElementById('selectedStatus').textContent=stateLabel(st);let detail='Telemetry-backed worker state.';if(w.key==='benchmark')detail=`Regression ${s?.benchmark?.regression?.passed||0}/${s?.benchmark?.regression?.total||0}, critical failures ${s?.benchmark?.regression?.critical_failures||0}.`;if(w.key==='bridge')detail=`GitHub sync service: ${d?.services?.bridge||'unknown'}. A recent Bridge run is WORKING; otherwise a healthy Bridge is READY.`;if(w.key==='build')detail=`Design Forge workers active: ${s?.active_workers?.design_forge||0}.`;if(w.key==='ollama')detail=`Primary local inference service: ${d?.services?.ollama||'unknown'}.`;document.getElementById('selectedDetail').textContent=detail}

document.getElementById('headerKevinProd').innerHTML=kevinProd('ready',true);document.getElementById('hubKevinProd').innerHTML=kevinProd('ready',false);load();setInterval(load,30000);addEventListener('resize',()=>load());

