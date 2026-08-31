(()=>{
'use strict';
const READY='#244f8f',ARMED='#68d8ce';
const COLORS={READY,ARMED,WORKING:'#79c56a',BUILDING:'#f06dbb',COOLDOWN:'#b38cff',DEGRADED:'#ff9a3d',OFFLINE:'#e46f61'};
let telemetryState=null,lastPost='';
const DEFS=[
 ['READY',READY,'Available and healthy; no active job right now.'],
 ['ARMED',ARMED,'Autonomy is enabled; waiting between governed work cycles.'],
 ['WORKING',COLORS.WORKING,'A real task is executing now.'],
 ['BUILDING',COLORS.BUILDING,'Build Lab / Forge is creating or testing a candidate.'],
 ['COOLDOWN',COLORS.COOLDOWN,'Bounded pause after throttling, retry, or recovery.'],
 ['DEGRADED',COLORS.DEGRADED,'Still online, but a health or evidence issue needs attention.'],
 ['OFFLINE',COLORS.OFFLINE,'Telemetry is stale or the component is unreachable.']
];
function svgEl(name,attrs={}){const e=document.createElementNS('http://www.w3.org/2000/svg',name);for(const [k,v] of Object.entries(attrs))e.setAttribute(k,String(v));return e}
function refineOwl(worker){
 const svg=worker.querySelector('svg.owl');if(!svg||svg.dataset.ownerRefined==='1')return;
 svg.dataset.ownerRefined='1';
 const oldFeet=svg.querySelector('.owl-feet');if(oldFeet)oldFeet.remove();
 const eyes=svgEl('g',{class:'owl-eyes'});
 [[46,49],[74,49]].forEach(([x,y])=>{eyes.appendChild(svgEl('circle',{class:'owl-eye-white',cx:x,cy:y,r:12.5}));eyes.appendChild(svgEl('circle',{class:'owl-eye',cx:x,cy:y+1,r:5.8}));eyes.appendChild(svgEl('circle',{class:'owl-eye-hi',cx:x-2.2,cy:y-2,r:1.8}))});
 svg.appendChild(eyes);
 const feet=svgEl('g',{class:'owl-feet-kevin'});feet.appendChild(svgEl('ellipse',{cx:47,cy:106,rx:8.5,ry:4.5}));feet.appendChild(svgEl('ellipse',{cx:73,cy:106,rx:8.5,ry:4.5}));[[41,108.5],[53,108.5],[67,108.5],[79,108.5]].forEach(([x,y])=>feet.appendChild(svgEl('circle',{cx:x,cy:y,r:2.35})));svg.appendChild(feet)
}
function ageSeconds(v){if(!v)return Infinity;const t=Date.parse(v);return Number.isFinite(t)?Math.max(0,(Date.now()-t)/1000):Infinity}
function taskActive(t){if(!t)return false;const p=String(t.phase||'').toLowerCase();return !/(yield|cooldown|wait|skip|queued|idle|armed|complete|done|failed)/.test(p)}
function classify(d,s){
 if(!d||ageSeconds(d.generated_at)>180||!s||ageSeconds(s.generated_at)>360)return 'OFFLINE';
 if(String(d?.health?.overall||s?.governance?.ok?'healthy':'').toLowerCase()!=='healthy'||s?.governance?.ok===false)return 'DEGRADED';
 const t=d.current_task;
 if(taskActive(t)){
   const signature=`${t?.id||''} ${t?.title||''} ${t?.phase||''}`.toLowerCase();
   return /(forge|build lab|design|candidate|prototype)/.test(signature)?'BUILDING':'WORKING';
 }
 const lr=String(s?.supervisor?.last_result||'').toUpperCase();if(/THROTTLED|SATURATED|COOLDOWN/.test(lr))return 'COOLDOWN';
 const sj=(s?.cron?.jobs||[]).find(x=>x.declaration_key==='kevin-supervisor-v1');
 if(sj?.enabled&&sj?.last_status==='ok')return 'ARMED';
 return 'READY';
}
async function refreshTelemetry(){
 try{const b=Date.now(),base='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/';const [dr,sr]=await Promise.all([fetch(`${base}dashboard-state.json?ts=${b}`,{cache:'no-store'}),fetch(`${base}support-latest.json?ts=${b}`,{cache:'no-store'})]);if(!dr.ok||!sr.ok)throw new Error('telemetry fetch');telemetryState=classify(await dr.json(),await sr.json());refine()}catch(_e){if(!telemetryState)telemetryState='OFFLINE'}
}
function fallbackState(){
 const hub=document.getElementById('kevinHub');if(!hub)return 'READY';if(hub.classList.contains('truth-active'))return 'WORKING';if(hub.classList.contains('truth-armed'))return 'ARMED';if(hub.classList.contains('truth-cooldown'))return 'COOLDOWN';if(hub.classList.contains('truth-degraded'))return 'DEGRADED';if(hub.classList.contains('truth-offline'))return 'OFFLINE';return 'READY'
}
function guide(){const section=document.querySelector('.topology')?.closest('section.card');if(!section)return;const legacy=section.querySelector('.legend');if(legacy)legacy.classList.add('owner-compact');let g=section.querySelector('.owner-status-guide');if(g)return;g=document.createElement('div');g.className='owner-status-guide';g.setAttribute('aria-label','Kevin status definitions');g.innerHTML=DEFS.map(([n,c,d])=>`<div class="owner-status-item"><i style="background:${c};color:${c}"></i><b>${n}</b><span>${d}</span></div>`).join('');(legacy||section).insertAdjacentElement(legacy?'afterend':'beforeend',g)}
function applyTruth(){
 const state=telemetryState||fallbackState(),badge=document.getElementById('kevinState'),hub=document.getElementById('kevinHub');
 if(badge){const span=badge.querySelector('.loop')||badge;if(span.textContent.trim()!==state)span.textContent=state;span.style.setProperty('--kstatec',COLORS[state]||READY)}
 if(hub)hub.dataset.ownerState=state;
 if(lastPost!==state){lastPost=state;try{window.top.postMessage({type:'kevin-ops-state',state,color:COLORS[state]||READY},location.origin)}catch(_e){}}
}
function refine(){document.querySelectorAll('.worker-progress').forEach(x=>x.remove());document.querySelectorAll('.worker').forEach(w=>{refineOwl(w);if(w.classList.contains('ready'))w.style.setProperty('--statec',READY)});document.querySelectorAll('.line.state-ready').forEach(x=>x.style.setProperty('--statec',READY));guide();applyTruth()}
addEventListener('load',()=>{refine();refreshTelemetry();setTimeout(refine,250);setTimeout(refine,900)});
const topology=document.getElementById('topology');if(topology&&'MutationObserver'in window)new MutationObserver(refine).observe(topology,{childList:true,subtree:true});
setInterval(refine,700);setInterval(refreshTelemetry,5000);
})();
