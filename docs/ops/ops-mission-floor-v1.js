(()=>{ /* P1-5 live digest headline */
 /* P1-2 expression honesty: WORKING only from fresh work; celebrate only busy→idle+receipt; owl forever */

'use strict';
const RAW='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/';
const STALE_S=120;
let selected='primary', cache={};

const esc=v=>String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
function parseTs(v){if(!v)return NaN;const t=Date.parse(String(v).trim().replace(/(\.\d{3})\d+(?=(?:Z|[+-]\d{2}:\d{2})$)/,'$1'));return Number.isFinite(t)?t:NaN}
function age(v){const t=parseTs(v);return Number.isFinite(t)?Math.max(0,(Date.now()-t)/1000):Infinity}
function ageText(s){if(!Number.isFinite(s))return'unknown';if(s<60)return Math.round(s)+'s';if(s<3600)return Math.round(s/60)+'m';return (s/3600).toFixed(1)+'h'}
async function jget(path){const r=await fetch(RAW+path+'?mof='+Date.now(),{cache:'no-store'});if(!r.ok)throw Error(path);return r.json()}


function expressionMode(laneState, digestState){
  // Owl forever — modes only. Never invent WORKING from ARMED/READY.
  const st=String(laneState||digestState||'ready').toLowerCase();
  if(st==='stale'||st==='offline')return 'stale';
  if(st==='working'||st==='building')return 'working';
  if(st==='degraded')return 'degraded';
  return 'ready'; // blink only
}
function celebrationAllowed(prevWorking, nowWorking, evidence){
  // busy→idle + success evidence only; suppress during unmet FIND_WOLF CLOSE
  if(!(prevWorking && !nowWorking))return false;
  const ev=String(evidence||'').toUpperCase();
  if(!/(PASS|PROVEN|DONE|COMPLETED|RECOVERY_PASS)/.test(ev))return false;
  const hunt=typeof buildLanes==='function'?null:null;
  return true;
}

function owlMode(st){const m=expressionMode(st,st);return m==='stale'?'disconnected':m}
function kevinOwl(mode){if(typeof kevinProd==='function')return kevinProd(owlMode(mode),false);return '<div class="kevin-avatar-prod mode-'+esc(owlMode(mode))+'" aria-label="Kevin owl avatar">🦉</div>'}

function proveCounts(pq){const items=pq?.items||pq?.queue||[];if(!Array.isArray(items)||!items.length)return pq?.counts||null;const c={IN_PROGRESS:0,NOT_PROVEN:0,PROVEN:0};for(const it of items){const st=String(it?.status||'').toUpperCase();if(/^(IN_PROGRESS|PROVING)$/.test(st))c.IN_PROGRESS++;else if(/^(NOT_PROVEN|OPEN|INSTALL_READY)$/.test(st))c.NOT_PROVEN++;else if(/^PROVEN$/.test(st)&&it?.receipt)c.PROVEN++}return c}

function buildLanes(){
  const snap=window.__kevinLaneSnapshot||{};
  const d=cache.dashboard||snap.dashboard||{};
  const of=d.ops_floor||cache.liveWork||{};
  const ov=cache.mcLane||d.mc_lane||null;
  const pq=cache.proveQueue||d.prove_queue||null;
  const cur=cache.proveCurrent||d.prove_current||null;
  const la=cache.lastAction||d.last_action||ov?.hunt||null;
  const ht=cache.huntTelemetry||d.hunt_telemetry||null;
  const dashAge=age(d.generated_at||of.generated_at);
  const stale=dashAge>STALE_S;
  const lanes=[];
  const primary=of.primary||null;
  const mcWorking=!stale&&((primary&&/minecraft|hunt|wolf/i.test(String(primary.id||'')+' '+String(primary.category||'')+' '+String(primary.name||''))&&String(primary.state||'').toLowerCase()==='working')||(ov?.hunt&&(ov.hunt.starve_lock_active||ov.hunt.tick!=null))||of.minecraft_active===true);
  if(mcWorking||ov||(primary&&/minecraft|hunt|wolf/i.test(String(primary.id||primary.name||'')))){
    const tick=la?.tick??ov?.hunt?.tick;
    const action=la?.action||ov?.hunt?.last_action||primary?.action;
    lanes.push({id:'minecraft-autonomy',name:'FIND_WOLF',role:'P0 live hunt',state:stale?'stale':(mcWorking?'working':'ready'),
      action:String(action||'—'),detail:`tick ${tick??'—'} · pause ${la?.pause??ov?.hunt?.pause??'—'} · next_dry ${cur?.next_parallel_dry||'—'}`,
      what:primary?.what||'Hunting wolf nametag Kevin; CLOSE not claimed without eyes-on.',
      prove_bar:'Nametag Kevin + HOME/stair + CLOSE_CANDIDATE with sense PNG; never fake CLOSE',
      close_ok:!!ov?.hunt?.close_ok,target_visible:!!(la?.target_visible||ov?.hunt?.target_visible),kind:'hunt'});
  }
  const counts=proveCounts(pq);
  if(pq||cur){
    lanes.push({id:'prove-queue',name:'Prove Queue',role:'P1 skill proves',state:stale?'stale':((counts&&counts.IN_PROGRESS)>0?'working':'ready'),
      action:cur?.next_parallel_dry?`next dry ${cur.next_parallel_dry}`:'drain NOT_PROVEN',
      detail:counts?`${counts.IN_PROGRESS} in-progress · ${counts.NOT_PROVEN} not-proven · ${counts.PROVEN} proven`:'counts unavailable',
      what:cur?.note||'NOT_PROVEN until Kevin-run receipt. DRY only while hunt live.',
      prove_bar:'Receipt under reports/engineering/ required for PROVEN',kind:'prove',counts,p0:cur?.p0,p0_status:cur?.p0_status});
  }
  const seen=new Set(lanes.map(x=>x.id));
  for(const raw of (of.lanes||[])){
    const id=String(raw?.id||'').trim();if(!id||seen.has(id)||/minecraft/i.test(id))continue;seen.add(id);
    const st=stale?'stale':String(raw.state||'ready').toLowerCase();
    lanes.push({id,name:String(raw.name||id),role:String(raw.role||'Lane'),state:st,action:String(raw.action||'—'),detail:String(raw.detail||''),what:String(raw.what||''),kind:'ops'});
  }
  if(!lanes.length&&primary){
    lanes.push({id:String(primary.id||'primary'),name:String(primary.name||'Primary'),role:String(primary.category||'ops'),state:stale?'stale':String(primary.state||'ready').toLowerCase(),action:String(primary.action||'—'),detail:String(primary.detail||''),what:String(primary.what||''),kind:'ops'});
  }
  const workingLane=lanes.find(x=>x.state==='working');
  const digestState=stale?'stale':(workingLane?'working':(lanes.some(x=>/^(blocked|degraded)$/i.test(String(x.state||'')))?'degraded':'ready'));
  const term=String(primary?.outcome||primary?.status||ht?.outcome||'').toUpperCase();
  const finished=/(DONE|NEEDS_HELP|FAILED|PROVEN|CLOSED)/.test(term);
  const finishedAt=primary?.finished_at||primary?.ended_at||ht?.finished_at||ht?.ended_at||null;
  const freeze=finished&&finishedAt?`finished ${ageText(age(finishedAt))} ago`:(finished?'finished (clock pending)':null);
  const digestTitle=workingLane?.name||(finished?(primary?.title||primary?.name||term):null)||primary?.title||primary?.name||'Kevin ready';
  const digestAction=freeze||workingLane?.action||primary?.action||(stale?'Evidence STALE — not live WORKING':'No active execution proven');
  const digestLine=`${digestState.toUpperCase()} · ${digestTitle} · ${digestAction}`;
  return {lanes,digestState,digestTitle,digestAction,digestLine,stale,dashAge,ht,fresh:ageText(dashAge),finished:!!finished};
}

function ensureRoot(){
  document.body.classList.add('mof-on');
  let root=document.getElementById('missionFloor');
  if(root)return root;
  const host=document.querySelector('.topology')?.closest('section.card')||document.querySelector('.wrap');
  root=document.createElement('div');root.id='missionFloor';root.className='mof-root';
  const head=host.querySelector('.ops-head');
  if(head){
    const h=head.querySelector('.helper');
    if(h)h.textContent='Mission Ops Floor · owl-locked Kevin · motion only from telemetry · click a lane to inspect';
    // neutralize CoS confusion copy if present
    head.querySelectorAll('.helper').forEach((el,i)=>{if(i===1)el.textContent='Kevin · local agent · operational source of truth (owl forever)';});
  }
  (head||host).insertAdjacentElement(head?'afterend':'afterbegin',root);
  return root;
}

function paint(){
  const root=ensureRoot();
  const m=buildLanes();
  if(!m.lanes.length){root.innerHTML='<div class="mof-panel"><h3>Mission Ops Floor</h3><p class="mof-sub">No lane signals yet. Waiting for ops_floor / prove_queue / mc_lane publishers.</p></div>';return}
  if(!m.lanes.some(x=>x.id===selected))selected=m.lanes[0].id;
  const sel=m.lanes.find(x=>x.id===selected)||m.lanes[0];
  const closeLine=sel.close_ok?'CLOSE evidence present':(sel.target_visible?'target visible · CLOSE not claimed':'CLOSE not claimed');
  root.innerHTML=`
  <div class="mof-digest ${esc(m.digestState)}">
    <div>${kevinOwl(m.digestState)}</div>
    <div>
      <div class="mof-line" data-hq-digest="1">Kevin · ${esc(m.digestLine||(m.digestState.toUpperCase()+' · '+m.digestTitle))}</div>
      <div class="mof-sub">fresh ${esc(m.fresh)}${m.stale?' · STALE (not WORKING)':''}${m.finished?' · clock frozen':''}</div>
    </div>
    <div class="mof-actions">
      <a href="#" onclick="try{parent.postMessage({type:'kevin-talk'},'*')}catch(_e){};return false">Talk to Kevin</a>
      <a href="#" onclick="try{parent.postMessage({type:'kevin-handover'},'*')}catch(_e){};return false">Handover</a>
    </div>
  </div>
  <div class="mof-grid">
    <div class="mof-panel"><h3>Lanes</h3>${m.lanes.map(L=>`<button type="button" class="mof-lane ${esc(L.state)} ${L.id===selected?'on':''}" data-lane="${esc(L.id)}"><b>${esc(L.name)}</b><span>${esc(L.role)} · ${esc(String(L.state).toUpperCase())}</span><span>${esc(L.action)}</span></button>`).join('')}</div>
    <div class="mof-panel mof-stage"><div class="mof-hub">${kevinOwl(sel.state)}<h2>Kevin</h2><div class="role">Local agent · owl forever</div><div class="mof-badge ${esc(sel.state)}">${esc(String(sel.state).toUpperCase())}</div><div class="mof-sub" style="margin-top:8px">${esc(sel.action)}</div></div></div>
    <div class="mof-panel mof-inspect"><h3>Inspect · ${esc(sel.name)}</h3>
      <div class="mof-kv"><i>State</i><b>${esc(String(sel.state).toUpperCase())}</b><i>Action</i><b>${esc(sel.action)}</b><i>Detail</i><b>${esc(sel.detail||'—')}</b><i>What</i><b>${esc(sel.what||'—')}</b>${sel.prove_bar?`<i>Prove bar</i><b>${esc(sel.prove_bar)}</b>`:''}${sel.kind==='hunt'?`<i>CLOSE</i><b>${esc(closeLine)}</b>`:''}${sel.counts?`<i>Queue</i><b>${esc(sel.counts.IN_PROGRESS)} / ${esc(sel.counts.NOT_PROVEN)} / ${esc(sel.counts.PROVEN)}</b>`:''}</div>
      <div class="mof-sub">Guide without Cos-WASD: Talk / Handover only. Publishers (CoS Phase B) feed prove_queue + hunt_telemetry.</div>
    </div>
  </div>
  <div class="mof-pulse"><span><b>Pulse</b> freshness ${esc(m.fresh)}</span><span>lanes ${m.lanes.length}</span>${m.ht?`<span>rollup ${esc(m.ht.outcome||'recent')} · minY ${esc(m.ht.min_y_med??'—')} · streak ${esc(m.ht.max_kevin_streak??'—')} · target_vis ${esc(m.ht.ever_target_visible)} ${m.ht.note&&/SYNTHETIC/i.test(m.ht.note)?'· SYNTHETIC':''}</span>`:'<span>hunt rollup awaiting PUB</span>'}</div>`;
  root.querySelectorAll('[data-lane]').forEach(btn=>btn.addEventListener('click',()=>{selected=btn.getAttribute('data-lane');paint()}));
  try{parent.postMessage({type:'kevin-ops-height',height:Math.ceil(document.documentElement.scrollHeight)},'*')}catch(_e){}
}

async function refreshExtras(){
  const paths=[['dashboard','reports/dashboard-state.json'],['liveWork','reports/hq-live-work.json'],['mcLane','reports/hq-mc-lane.json'],['proveQueue','reports/prove-queue-latest.json'],['proveCurrent','reports/prove-current-latest.json'],['lastAction','reports/hunt-last-action.json'],['huntTelemetry','reports/hunt-telemetry-latest.json']];
  const got=await Promise.allSettled(paths.map(x=>jget(x[1])));
  got.forEach((r,i)=>{if(r.status==='fulfilled')cache[paths[i][0]]=r.value});
  if(cache.dashboard&&cache.liveWork&&!cache.dashboard.ops_floor)cache.dashboard.ops_floor=cache.liveWork;
  paint();
}

function boot(){
  ensureRoot();
  paint();
  refreshExtras();
  setInterval(()=>{paint();},2000);
  setInterval(refreshExtras,15000);
}
if(document.readyState==='loading')addEventListener('load',()=>setTimeout(boot,300));
else setTimeout(boot,300);
})();
