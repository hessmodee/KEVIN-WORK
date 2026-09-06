(()=>{
'use strict';
/* P2-ops-fun-celebration-guard: busy→idle + PASS/PROVEN only */
const ACTIVE='#ffd166';
const BLINK_RATES=[4.7,5.3,6.1,5.8,6.7,4.9,7.2,5.6,6.4];
const BLINK_DELAYS=[-0.4,-2.7,-1.3,-4.1,-3.2,-0.9,-5.4,-2.1,-4.7];
let selected='KEVIN',baseRefreshing=false,lastBusy=null,lastCelebrationProof='',gazeQueue=[],gazeSignature='';
function el(name,attrs={}){const n=document.createElementNS('http://www.w3.org/2000/svg',name);for(const [k,v] of Object.entries(attrs))n.setAttribute(k,String(v));return n}
function workerName(w){return w.querySelector('.worker-copy b')?.textContent?.trim()||'Worker'}
function workerRole(w){return w.querySelector('.worker-copy small')?.textContent?.trim()||'Worker lane'}
function stateOf(w){for(const s of ['building','working','active','degraded','offline','cooldown','ready'])if(w.classList.contains(s))return s.toUpperCase();return 'READY'}
function shownState(w){return w.querySelector('.worker-copy .state')?.textContent?.trim().toUpperCase()||stateOf(w)}
function replaceEyes(w,i){
 const svg=w.querySelector('svg.owl');if(!svg)return;const existing=svg.querySelector('.owl-eyes');
 w.style.setProperty('--blink-rate',`${BLINK_RATES[i%BLINK_RATES.length]}s`);w.style.setProperty('--blink-delay',`${BLINK_DELAYS[i%BLINK_DELAYS.length]}s`);
 if(existing?.dataset?.funOutline==='1')return;
 existing?.remove();const g=el('g',{class:'owl-eyes','data-fun-outline':'1'});[[46,50],[74,50]].forEach(([x,y])=>g.appendChild(el('circle',{class:'owl-eye-outline',cx:x,cy:y,r:10.5,fill:'none'})));svg.appendChild(g)
}
function ensureActiveDefinition(){const g=document.querySelector('.owner-status-guide');if(!g||g.querySelector('[data-owner-active="1"]'))return;const d=document.createElement('div');d.className='owner-status-item owner-active';d.dataset.ownerActive='1';d.innerHTML=`<i style="background:${ACTIVE};color:${ACTIVE}"></i><b>ACTIVE</b><span>A worker lane is awake and participating in the current cycle; ACTIVE is not the same as a task actively executing.</span>`;const armed=[...g.children].find(x=>x.querySelector('b')?.textContent==='ARMED');armed?.insertAdjacentElement('afterend',d)||g.appendChild(d)}
function freshness(){const age=document.getElementById('age')?.textContent?.trim()||'—';return `Ops refresh ≤4s · source evidence age ${age}`}
function detailFor(w){const name=workerName(w),state=stateOf(w);const snapshot=window.__kevinLaneSnapshot,key={Reader:'reader',Staging:'staging',Chat:'chat',Tick:'tick',Bridge:'bridge'}[name];if(snapshot&&key&&typeof window.workerEvidenceDetail==='function')return window.workerEvidenceDetail(key,snapshot.dashboard,snapshot.support)+' '+freshness()+'.';if(name==='Bridge')return `GitHub sync lane. ACTIVE means it recently participated in a sync cycle; WORKING means task execution is currently attributed to it. ${freshness()}.`;if(name==='Benchmark')return `${document.getElementById('benchmark')?.textContent||'Benchmark telemetry unavailable'}. ${freshness()}.`;return `${state} is taken from the current worker lane state. ${freshness()}.`}
function paint(){document.getElementById('kevinHub')?.classList.toggle('owner-selected',selected==='KEVIN');document.querySelectorAll('.worker').forEach(w=>w.classList.toggle('owner-selected',workerName(w)===selected))}
function kevinStateText(){const states=[...document.querySelectorAll('#kevinState .loop')].map(x=>x.textContent.trim()).filter(Boolean);return states.length?states.join(' + '):'READY'}
function selectKevin(){selected='KEVIN';const n=document.getElementById('selectedName'),s=document.getElementById('selectedStatus'),d=document.getElementById('selectedDetail');if(n)n.textContent='Kevin — Chief of Staff';if(s)s.textContent=kevinStateText();if(d)d.textContent=`Kevin aggregate state from the live worker lanes. ${freshness()}. Click any worker to inspect it, then click Kevin to return here.`;paint()}
function selectWorker(w){selected=workerName(w);const n=document.getElementById('selectedName'),s=document.getElementById('selectedStatus'),d=document.getElementById('selectedDetail');if(n)n.textContent=`${selected} — ${workerRole(w)}`;if(s)s.textContent=stateOf(w);if(d)d.textContent=detailFor(w);paint()}
function bindSelection(){
 const hub=document.getElementById('kevinHub');if(hub&&!hub.dataset.funSelectable){hub.dataset.funSelectable='1';hub.tabIndex=0;hub.setAttribute('role','button');hub.setAttribute('aria-label','Select Kevin, Chief of Staff');hub.addEventListener('click',selectKevin);hub.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();selectKevin()}})}
 document.querySelectorAll('.worker').forEach(w=>{if(w.dataset.funSelectable)return;w.dataset.funSelectable='1';w.tabIndex=0;w.setAttribute('role','button');w.setAttribute('aria-label',`Select ${workerName(w)}`);const choose=()=>setTimeout(()=>selectWorker(w),0);w.addEventListener('click',choose);w.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();choose()}})})
}
function renderSelection(){if(selected==='KEVIN'){selectKevin();return}const w=[...document.querySelectorAll('.worker')].find(x=>workerName(x)===selected);if(w)selectWorker(w);else selectKevin()}
function addFreshness(){const head=document.querySelector('.ops-head');if(!head)return;let x=head.querySelector('.owner-live-age');if(!x){x=document.createElement('div');x.className='helper owner-live-age';head.appendChild(x)}x.innerHTML=`<strong>LIVE</strong> · ${freshness()}`}
function activeWorkers(){return [...document.querySelectorAll('.worker')].filter(w=>w.offsetParent!==null&&['WORKING','BUILDING'].includes(stateOf(w))&&shownState(w)===stateOf(w))}
function shuffled(a){for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a}
function gaze(x,y){document.querySelectorAll('#hubKevinProd .kv-eye,#hubKevinProd .kv-hi').forEach(e=>e.style.transform=`translate(${x.toFixed(2)}px,${y.toFixed(2)}px)`);try{window.top.postMessage({type:'kevin-ops-gaze',x,y},location.origin)}catch(_e){}}
function gazeTick(){
 const current=activeWorkers(),names=current.map(workerName).sort(),sig=names.join('|');
 if(!names.length){gazeQueue=[];gazeSignature='';gaze(0,0);return}
 if(sig!==gazeSignature||!gazeQueue.length){gazeSignature=sig;gazeQueue=[...shuffled([...names]),null]}
 const targetName=gazeQueue.shift();if(!targetName){gaze(0,0);return}
 const target=activeWorkers().find(w=>workerName(w)===targetName);if(!target){gazeQueue=[];gazeSignature='';gaze(0,0);return}
 const h=document.getElementById('kevinHub')?.getBoundingClientRect(),r=target.getBoundingClientRect();if(!h){gaze(0,0);return}
 const dx=r.left+r.width/2-(h.left+h.width/2),dy=r.top+r.height/2-(h.top+h.height/2),m=Math.hypot(dx,dy)||1;gaze(4.4*dx/m,3.2*dy/m)
}
function successfulProof(){return `${document.getElementById('recent')?.textContent||''} ${document.getElementById('evidence')?.textContent||''} ${document.getElementById('kevinMeta')?.textContent||''}`.toUpperCase()}
/* P2 celebration guard: busy→idle + PASS/PROVEN only — never on ARMED/READY/STALE/unmet FIND_WOLF */
function celebrationAllowed(prevBusy,busy,proof){
  if(!(prevBusy!==null&&prevBusy>0&&busy===0))return false;
  if(!proof||proof===lastCelebrationProof)return false;
  if(/\bSTALE\b/.test(proof))return false;
  if(/\b(ARMED|READY|SCHEDULED)\b/.test(proof)&&!/(PASS|SUCCESS|PROVEN|DONE|COMPLETED|RECOVERY_PASS)/.test(proof))return false;
  if(/FIND_WOLF|CLOSE NOT/.test(proof)&&!/(PASS|PROVEN|DONE|COMPLETED|RECOVERY_PASS|CLOSE\s*(OK|EVIDENCE)|RECEIPT)/.test(proof))return false;
  return /(PASS|SUCCESS|PROVEN|DONE|COMPLETED|RECOVERY_PASS)/.test(proof);
}
function celebrate(){const hub=document.getElementById('kevinHub'),av=document.querySelector('#hubKevinProd .kevin-avatar-prod');if(!hub||!av)return;hub.classList.remove('owner-celebrate');av.classList.remove('owner-victory');void av.offsetWidth;hub.classList.add('owner-celebrate');av.classList.add('owner-victory');try{window.top.postMessage({type:'kevin-ops-celebrate',duration:1700},location.origin)}catch(_e){};setTimeout(()=>{hub.classList.remove('owner-celebrate');av.classList.remove('owner-victory')},1750)}
function checkCompletion(){const busy=activeWorkers().length,proof=successfulProof();if(celebrationAllowed(lastBusy,busy,proof)){lastCelebrationProof=proof;celebrate()}lastBusy=busy}
async function refreshBase(){if(baseRefreshing||typeof window.load!=='function')return;baseRefreshing=true;try{await window.load()}catch(_e){}finally{baseRefreshing=false;setTimeout(polish,0)}}
function polish(){document.querySelectorAll('.worker').forEach((w,i)=>replaceEyes(w,i));ensureActiveDefinition();bindSelection();addFreshness();renderSelection();checkCompletion()}
addEventListener('load',()=>{polish();setTimeout(polish,300);setTimeout(polish,1000)});const top=document.getElementById('topology');if(top&&'MutationObserver'in window)new MutationObserver(polish).observe(top,{childList:true,subtree:true});setInterval(polish,850);setInterval(refreshBase,4000);setInterval(gazeTick,1100);
})();
