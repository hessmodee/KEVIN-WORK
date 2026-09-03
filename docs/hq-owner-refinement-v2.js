(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
if(!frame)return;
let core=null,doc=null,boundDoc=null,observer=null,refinePending=false,lastStates=['READY'];
const STATE_COLORS={READY:1,ARMED:1,WORKING:1,BUILDING:1,COOLDOWN:1,DEGRADED:1,OFFLINE:1};

function parseTimestamp(v){
 if(!v)return NaN;
 const s=String(v).trim().replace(/(\.\d{3})\d+(?=(?:Z|[+-]\d{2}:\d{2})$)/,'$1');
 const t=Date.parse(s);return Number.isFinite(t)?t:NaN;
}
function ageSeconds(v){const t=parseTimestamp(v);return Number.isFinite(t)?Math.max(0,(Date.now()-t)/1000):Infinity}
function taskActive(t){if(!t)return false;const p=String(t.phase||'').toLowerCase();return !/(yield|cooldown|wait|skip|queued|idle|armed|complete|completed|done|stopped|failed)/.test(p)}
function jobs(s){const c=s?.cron;return Array.isArray(c)?c:(c?.jobs||[])}
function job(s,key){return jobs(s).find(x=>x?.declaration_key===key)||null}
function livePulseHealthy(s){const j=job(s,'kevin-hq-live-pulse-v15'),at=Number(j?.last_run_at_ms||0);return !!(j?.enabled&&String(j?.last_status||'').toLowerCase()==='ok'&&String(j?.last_run_status||j?.last_status||'').toLowerCase()==='ok'&&Number(j?.consecutive_errors||0)===0&&at>0&&Math.max(0,Date.now()-at)<=180000)}
function evidenceAgeMs(d,s){const vals=[parseTimestamp(d?.generated_at),parseTimestamp(s?.generated_at),Number(job(s,'kevin-hq-live-pulse-v15')?.last_run_at_ms||0)].filter(v=>Number.isFinite(v)&&v>0);return vals.length?Math.max(0,Date.now()-Math.max(...vals)):Infinity}
function activeStates(d,s){const out=new Set(),aw=ageSeconds(s?.generated_at)<=600?s?.active_workers||{}:{},t=ageSeconds(d?.generated_at)<=600?d?.current_task||null:null,tt=`${String(t?.id||'').toLowerCase()} ${String(t?.title||'').toLowerCase()} ${String(t?.category||'').toLowerCase()} ${String(t?.phase||'').toLowerCase()} ${String(t?.source||'').toLowerCase()}`;if(Number(aw?.design_forge||0)>0)out.add('BUILDING');if(Number(aw?.night_forge||0)>0||Number(aw?.supervisor||0)>0||Number(aw?.benchmark||0)>0)out.add('WORKING');if(taskActive(t)){if(/design[- ]forge|build lab|candidate|prototype|builder|mission factory/.test(tt))out.add('BUILDING');else out.add('WORKING')}return ['BUILDING','WORKING'].filter(x=>out.has(x))}
function classifyStates(d,s){const active=activeStates(d,s);if(active.length)return active;const offline=!(ageSeconds(s?.generated_at)<=600&&livePulseHealthy(s))&&evidenceAgeMs(d,s)>15*60*1000;if(offline)return ['OFFLINE'];const health=String(d?.health?.overall||d?.status||'').toLowerCase();if((health&&!['healthy','ready'].includes(health))||s?.governance?.ok===false)return ['DEGRADED'];if(['bridge','tick','ollama','gateway'].some(k=>d?.services?.[k]&&String(d.services[k]).toLowerCase()!=='healthy'))return ['DEGRADED'];const lr=String(s?.supervisor?.last_result||'').toUpperCase();if(/THROTTLED|SATURATED|COOLDOWN|WAIT/.test(lr))return ['COOLDOWN'];const sj=job(s,'kevin-supervisor-v1');if(sj?.enabled&&String(sj?.last_status||'').toLowerCase()==='ok')return ['ARMED'];return ['READY']}
function normalizeStates(input){const arr=(Array.isArray(input)?input:[input]).map(x=>String(x||'').toUpperCase()).filter(x=>STATE_COLORS[x]);if(arr.includes('BUILDING')||arr.includes('WORKING'))return ['BUILDING','WORKING'].filter(x=>arr.includes(x));return [arr[0]||'READY']}
function primaryState(states){for(const s of ['BUILDING','WORKING','ARMED','COOLDOWN','DEGRADED','OFFLINE','READY'])if(states.includes(s))return s;return 'READY'}
function label(s){return s.toLowerCase()}
function setText(el,text){if(el&&el.textContent!==text)el.textContent=text}

function installStyles(){
 if(!doc||doc.getElementById('ownerRefineStyleV2'))return;
 const st=doc.createElement('style');st.id='ownerRefineStyleV2';st.textContent=`
 #hqHandoverCard{margin:0 0 12px!important;border-color:rgba(131,167,187,.32)!important;background:linear-gradient(135deg,rgba(33,58,79,.28),rgba(18,23,17,.98))!important;box-shadow:0 14px 40px rgba(0,0,0,.16)!important}
 #hqHandoverCard .section-head{margin-bottom:8px!important}#hqHandoverCard .k{color:#b9d5e6!important}
 #headerKevin .kevin-avatar{will-change:transform,filter}#headerKevin .kevin-avatar.owner-sync-working{animation:ownerHeaderWork 2s ease-in-out infinite}#headerKevin .kevin-avatar.owner-sync-building{animation:ownerHeaderBuild 1.05s ease-in-out infinite}#headerKevin .kevin-avatar.owner-sync-armed{animation:ownerHeaderArmed 3.6s ease-in-out infinite}#headerKevin .kevin-avatar.owner-sync-cooldown{filter:saturate(.8)}#headerKevin .kevin-avatar.owner-sync-degraded{filter:saturate(.72)}#headerKevin .kevin-avatar.owner-sync-offline{filter:grayscale(.65) saturate(.4);opacity:.62}
 @keyframes ownerHeaderWork{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}@keyframes ownerHeaderBuild{0%,100%{transform:translateY(0) rotate(-2deg)}50%{transform:translateY(-4px) rotate(2deg)}}@keyframes ownerHeaderArmed{0%,100%{transform:scale(1)}50%{transform:scale(1.018)}}
 `;doc.head.appendChild(st);
}
function installCoreTimestampParser(){if(core)core.parseAt=v=>{const t=parseTimestamp(v);return Number.isFinite(t)?new Date(t):null}}
function syncHeader(states){
 lastStates=normalizeStates(states);if(!doc)return;
 const av=doc.querySelector('#headerKevin .kevin-avatar');if(!av)return;
 const primary=primaryState(lastStates);
 [...av.classList].filter(c=>c.startsWith('owner-sync-')||c.startsWith('mode-')).forEach(c=>av.classList.remove(c));
 av.classList.add('owner-sync-'+label(primary));
 av.classList.add(primary==='OFFLINE'?'mode-disconnected':primary==='DEGRADED'?'mode-degraded':(primary==='BUILDING'||primary==='WORKING')?'mode-working':'mode-idle');
 const el=doc.getElementById('owlLabel');if(el){const lvl=av.dataset.level||'—';setText(el,`Evolution ${lvl}/5 · ${lastStates.map(label).join(' + ')}`)}
}
function streamlineNav(){if(!doc)return;doc.querySelectorAll('[data-tab="talk"]').forEach(x=>x.remove());if((core?.location?.hash||'').toLowerCase()==='#talk')core.location.hash='#overview'}
function fixReaderLabel(){if(!doc)return;doc.querySelectorAll('.service-chip').forEach(chip=>{const b=chip.querySelector('b'),span=chip.querySelector('span');if(b?.textContent.trim()==='Reader'&&span?.textContent.trim().toUpperCase()==='GREEN')setText(span,'READY')})}
function moveHandoverToTop(){if(!doc||!core||(core.location.hash||'#overview').slice(1)!=='overview')return;const main=doc.getElementById('main'),hero=main?.querySelector('.hero'),card=doc.getElementById('hqHandoverCard');if(!main||!hero||!card)return;if(card.nextElementSibling!==hero)main.insertBefore(card,hero);setText(card.querySelector('.k'),'AI HANDOVER · SHARE KEVIN');setText(card.querySelector('.h'),'Copy the current handover when another AI or engineer needs Kevin’s goals, proof state, blockers, and next actions.');setText(card.querySelector('#hqCopyHandover'),'COPY KEVIN HANDOVER')}
function removeOverviewDuplicateChart(){if(!doc||!core||(core.location.hash||'#overview').slice(1)!=='overview')return;const chart=doc.getElementById('chartWrap'),card=chart?.closest('.card');if(card)card.remove()}
function refine(){if(!doc||!core)return;installStyles();installCoreTimestampParser();streamlineNav();fixReaderLabel();moveHandoverToTop();removeOverviewDuplicateChart();syncHeader(lastStates)}
function scheduleRefine(){if(refinePending)return;refinePending=true;requestAnimationFrame(()=>{refinePending=false;refine()})}
function getRealCore(){try{const nextCore=frame.contentWindow,nextDoc=frame.contentDocument;if(!nextCore||!nextDoc)return null;const href=String(nextDoc.location?.href||'');if(!href||href==='about:blank'||!/(?:^|\/)hq-core-v7\.html(?:[?#]|$)/.test(href))return null;return {core:nextCore,doc:nextDoc}}catch(_e){return null}}
function bind(){
 const target=getRealCore();if(!target)return false;core=target.core;doc=target.doc;
 if(boundDoc===doc){scheduleRefine();return true}
 boundDoc=doc;if(observer){observer.disconnect();observer=null}
 installStyles();installCoreTimestampParser();refine();
 const main=doc.getElementById('main'),nav=doc.getElementById('nav'),rail=doc.getElementById('serviceRail');
 if('MutationObserver'in window){observer=new MutationObserver(scheduleRefine);[main,nav,rail].filter(Boolean).forEach(x=>observer.observe(x,{childList:true}))}
 core.addEventListener('hashchange',scheduleRefine);
 return true;
}
async function refreshTruth(){
 if(!bind())return;
 try{const b=Date.now(),base='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/';const [dr,sr]=await Promise.all([fetch(`${base}dashboard-state.json?ts=${b}`,{cache:'no-store'}),fetch(`${base}support-latest.json?ts=${b}`,{cache:'no-store'})]);if(!dr.ok||!sr.ok)throw new Error('telemetry');const [d,s]=await Promise.all([dr.json(),sr.json()]);syncHeader(classifyStates(d,s))}catch(_e){}
}
window.addEventListener('message',e=>{if(e.origin!==location.origin||e.data?.type!=='kevin-ops-state')return;syncHeader(e.data.states||e.data.state||'READY')});
frame.addEventListener('load',()=>{bind();refreshTruth()});
setTimeout(()=>{bind();refreshTruth()},0);
setInterval(refreshTruth,15000);
})();
