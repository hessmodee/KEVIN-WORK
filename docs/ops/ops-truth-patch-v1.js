(()=>{
'use strict';
const RAW='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/';
const WAIT=/yield|cooldown|wait|skip|queued|idle|armed|complete|completed|done|stopped|failed/i;
const COOL=/THROTTLED|SATURATED|WAIT|COOL/i;
const COLORS={READY:'#244f8f',ARMED:'#68d8ce',WORKING:'#79c56a',BUILDING:'#f06dbb',COOLDOWN:'#b38cff',DEGRADED:'#ff9a3d',OFFLINE:'#e46f61'};
let lastGood=null,lastStates=['READY'],refreshing=false,guarding=false,observer=null,statusObserver=null;
function norm(v){return String(v??'').toLowerCase()}
function ms(v){const n=Number(v);return Number.isFinite(n)?n:0}
function parseTimestamp(v){if(!v)return NaN;const s=String(v).trim().replace(/(\.\d{3})\d+(?=(?:Z|[+-]\d{2}:\d{2})$)/,'$1');const t=Date.parse(s);return Number.isFinite(t)?t:NaN}
function ageSeconds(v){const t=parseTimestamp(v);return Number.isFinite(t)?Math.max(0,(Date.now()-t)/1000):Infinity}
function taskActive(t){return !!(t&&Object.keys(t).length&&!WAIT.test(String(t.phase||'')))}
function supportJobs(s){const c=s?.cron;return Array.isArray(c)?c:(c?.jobs||[])}
function job(s,key){return supportJobs(s).find(j=>j?.declaration_key===key)||null}
function livePulseHealthy(s){const j=job(s,'kevin-hq-live-pulse-v15'),at=ms(j?.last_run_at_ms);return !!(j?.enabled&&norm(j?.last_status)==='ok'&&norm(j?.last_run_status||j?.last_status)==='ok'&&Number(j?.consecutive_errors||0)===0&&at>0&&Math.max(0,Date.now()-at)<=180000)}
function normalizedEvidenceAgeMs(d,s){const vals=[parseTimestamp(d?.generated_at),parseTimestamp(s?.generated_at),ms(job(s,'kevin-hq-live-pulse-v15')?.last_run_at_ms)].filter(v=>Number.isFinite(v)&&v>0);return vals.length?Math.max(0,Date.now()-Math.max(...vals)):Infinity}
function explicitActiveStates(d,s){
 const out=new Set(),aw=ageSeconds(s?.generated_at)<=600?s?.active_workers||{}:{},t=ageSeconds(d?.generated_at)<=600?d?.current_task||null:null,tt=`${norm(t?.id)} ${norm(t?.title)} ${norm(t?.category)} ${norm(t?.phase)} ${norm(t?.source)}`;
 if(Number(aw?.design_forge||0)>0)out.add('BUILDING');
 if(Number(aw?.night_forge||0)>0||Number(aw?.supervisor||0)>0||Number(aw?.benchmark||0)>0)out.add('WORKING');
 if(taskActive(t)){
   if(/design[- ]forge|build lab|candidate|prototype|builder|mission factory/.test(tt))out.add('BUILDING');
   else out.add('WORKING');
 }
 return ['BUILDING','WORKING'].filter(x=>out.has(x));
}
function installBaseLivenessOverride(){
 window.telemetryAgeMs=(d,s)=>normalizedEvidenceAgeMs(d,s);
 window.telemetryOffline=(d,s)=>{
   if(explicitActiveStates(d,s).length)return false;
   if(ageSeconds(s?.generated_at)<=600&&livePulseHealthy(s))return false;
   return normalizedEvidenceAgeMs(d,s)>15*60*1000;
 };
}
function fallbackStates(d,s){
 const active=explicitActiveStates(d,s);if(active.length)return active;
 if(window.telemetryOffline(d,s))return ['OFFLINE'];
 const health=norm(d?.health?.overall||d?.status);
 if((health&& !['healthy','ready'].includes(health))||s?.governance?.ok===false)return ['DEGRADED'];
 if(['bridge','tick','ollama','gateway'].some(k=>d?.services?.[k]&&norm(d.services[k])!=='healthy'))return ['DEGRADED'];
 if(COOL.test(String(s?.supervisor?.last_result||'')))return ['COOLDOWN'];
 const sj=job(s,'kevin-supervisor-v1');if(sj?.enabled&&norm(sj?.last_status)==='ok')return ['ARMED'];
 return ['READY'];
}
function authoritativeStates(d,s){
 const explicit=explicitActiveStates(d,s);if(explicit.length)return explicit;
 let states=[];
 try{if(typeof window.kevinStates==='function')states=(window.kevinStates(d,s)||[]).map(x=>String(x).toUpperCase())}catch(_e){}
 states=states.filter(x=>COLORS[x]);
 if(!states.length)states=fallbackStates(d,s);
 if(states.some(x=>x==='BUILDING'||x==='WORKING'))return ['BUILDING','WORKING'].filter(x=>states.includes(x));
 if(states.length===1&&states[0]==='READY'){
   const sj=job(s,'kevin-supervisor-v1');if(sj?.enabled&&norm(sj?.last_status)==='ok')return ['ARMED'];
 }
 return [states[0]||'READY'];
}
function primaryState(states){for(const s of ['BUILDING','WORKING','ARMED','COOLDOWN','DEGRADED','OFFLINE','READY'])if(states.includes(s))return s;return 'READY'}
function sameStates(a,b){return a.length===b.length&&a.every((x,i)=>x===b[i])}
function renderAuthoritative(states,d,s){
 const clean=(states||['READY']).filter(x=>COLORS[x]);if(!clean.length)clean.push('READY');lastStates=clean;
 guarding=true;
 try{
   const badge=document.getElementById('kevinState');
   if(badge){
     const current=[...badge.querySelectorAll('.loop')].map(x=>x.textContent.trim().toUpperCase());
     if(!sameStates(current,clean)){
       badge.className='kevin-states';
       badge.innerHTML=clean.map(st=>`<span class="loop state-${st.toLowerCase()}" style="--kstatec:${COLORS[st]}">${st}</span>`).join('<span class="state-plus">+</span>');
     }
   }
   const hub=document.getElementById('kevinHub');
   if(hub){
     hub.classList.remove('truth-active','truth-building','truth-working','truth-armed','truth-ready','truth-cooldown','truth-idle','truth-degraded','truth-offline');
     if(clean.includes('BUILDING')||clean.includes('WORKING'))hub.classList.add('truth-active');
     if(clean.includes('BUILDING'))hub.classList.add('truth-building');
     if(clean.includes('WORKING'))hub.classList.add('truth-working');
     if(clean.length===1)hub.classList.add('truth-'+clean[0].toLowerCase());
     hub.dataset.authoritativeStates=clean.join('+');
   }
   const selected=document.getElementById('selectedName')?.textContent||'';
   if(/^Kevin\b/i.test(selected)){
     const status=document.getElementById('selectedStatus');
     if(status){const wanted=clean.join(' + ');if(status.textContent!==wanted)status.textContent=wanted;}
   }
   window.__kevinTruth={states:[...clean],primary:primaryState(clean),at:Date.now(),data:lastGood};
   try{window.top.postMessage({type:'kevin-ops-state',state:primaryState(clean),states:[...clean],color:COLORS[primaryState(clean)]},location.origin)}catch(_e){}
 }finally{guarding=false}
}
function ensureAuthority(){if(guarding||!lastGood)return;renderAuthoritative(lastStates,lastGood.d,lastGood.s)}
function installGuard(){
 const badge=document.getElementById('kevinState');
 if(badge&&!observer){observer=new MutationObserver(()=>{if(!guarding&&lastGood)queueMicrotask(ensureAuthority)});observer.observe(badge,{childList:true,subtree:true,characterData:true});}
 const status=document.getElementById('selectedStatus');
 if(status&&!statusObserver){statusObserver=new MutationObserver(()=>{if(!guarding&&lastGood&&/^Kevin\b/i.test(document.getElementById('selectedName')?.textContent||''))queueMicrotask(ensureAuthority)});statusObserver.observe(status,{childList:true,subtree:true,characterData:true});}
}
async function refreshTruth(){
 if(refreshing)return;refreshing=true;
 try{
   const bust=Date.now();
   const [dr,sr]=await Promise.all([fetch(`${RAW}dashboard-state.json?ts=${bust}`,{cache:'no-store'}),fetch(`${RAW}support-latest.json?ts=${bust}`,{cache:'no-store'})]);
   if(!dr.ok||!sr.ok)throw new Error('telemetry refresh');
   const [d,s]=await Promise.all([dr.json(),sr.json()]);
   lastGood={d,s};renderAuthoritative(authoritativeStates(d,s),d,s);
   const age=document.getElementById('age'),ageMs=normalizedEvidenceAgeMs(d,s);if(age&&Number.isFinite(ageMs))age.textContent=ageMs<60000?`${Math.max(0,Math.round(ageMs/1000))} sec`:`${Math.max(0,Math.round(ageMs/60000))} min`;
 }catch(_e){
   // A refresh failure is not evidence that Kevin is offline. Preserve the last proven state.
   if(lastGood)renderAuthoritative(lastStates,lastGood.d,lastGood.s);
 }finally{refreshing=false;installGuard()}
}
installBaseLivenessOverride();
addEventListener('load',()=>{installGuard();setTimeout(refreshTruth,120);setTimeout(refreshTruth,900)});
setInterval(refreshTruth,2500);
})();
