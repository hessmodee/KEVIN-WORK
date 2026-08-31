(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
let core=null,doc=null,observer=null,refreshing=false,lastOpsState='READY',hooked=false;
const STATE_COLORS={READY:'#244f8f',ARMED:'#68d8ce',WORKING:'#79c56a',BUILDING:'#f06dbb',COOLDOWN:'#b38cff',DEGRADED:'#ff9a3d',OFFLINE:'#e46f61'};
function installStyles(){
 if(!doc||doc.getElementById('ownerRefineStyle'))return;
 const st=doc.createElement('style');st.id='ownerRefineStyle';st.textContent=`
 #hqHandoverCard{margin:0 0 12px!important;border-color:rgba(131,167,187,.32)!important;background:linear-gradient(135deg,rgba(33,58,79,.28),rgba(18,23,17,.98))!important;box-shadow:0 14px 40px rgba(0,0,0,.16)!important}
 #hqHandoverCard .section-head{margin-bottom:8px!important}#hqHandoverCard .k{color:#b9d5e6!important}
 #headerKevin .kevin-avatar{will-change:transform,filter}#headerKevin .kevin-avatar.owner-sync-working{animation:ownerHeaderWork 2s ease-in-out infinite}#headerKevin .kevin-avatar.owner-sync-building{animation:ownerHeaderBuild 1.05s ease-in-out infinite}#headerKevin .kevin-avatar.owner-sync-armed{animation:ownerHeaderArmed 3.6s ease-in-out infinite}#headerKevin .kevin-avatar.owner-sync-cooldown{filter:saturate(.8)}#headerKevin .kevin-avatar.owner-sync-degraded{filter:saturate(.72)}#headerKevin .kevin-avatar.owner-sync-offline{filter:grayscale(.65) saturate(.4);opacity:.62}
 #headerKevin .kevin-avatar.owner-sync-working .kv-eyes,#headerKevin .kevin-avatar.owner-sync-building .kv-eyes{transform-origin:60px 48px;animation:ownerHeaderBlink 3.8s ease-in-out infinite}
 @keyframes ownerHeaderBlink{0%,89%,93%,100%{transform:scaleY(1)}91%{transform:scaleY(.06)}}
 @keyframes ownerHeaderWork{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}
 @keyframes ownerHeaderBuild{0%,100%{transform:translateY(0) rotate(-2deg)}50%{transform:translateY(-4px) rotate(2deg)}}
 @keyframes ownerHeaderArmed{0%,100%{transform:scale(1);filter:drop-shadow(0 0 4px rgba(104,216,206,.12))}50%{transform:scale(1.018);filter:drop-shadow(0 0 13px rgba(104,216,206,.28))}}
 `;doc.head.appendChild(st);
}
function parseTimestamp(v){if(!v)return NaN;const s=String(v).trim().replace(/(\.\d{3})\d+(?=(?:Z|[+-]\d{2}:\d{2})$)/,'$1');const t=Date.parse(s);return Number.isFinite(t)?t:NaN}
function ageSeconds(v){const t=parseTimestamp(v);return Number.isFinite(t)?Math.max(0,(Date.now()-t)/1000):Infinity}
function taskActive(t){if(!t)return false;const p=String(t.phase||'').toLowerCase();return !/(yield|cooldown|wait|skip|queued|idle|armed|complete|done|failed)/.test(p)}
function classify(d,s){
 if(!d||ageSeconds(d.generated_at)>180||!s||ageSeconds(s.generated_at)>480)return 'OFFLINE';
 const health=String(d?.health?.overall||'').toLowerCase();if(health!=='healthy'||s?.governance?.ok===false)return 'DEGRADED';
 const t=d.current_task;if(taskActive(t)){const sig=`${t?.id||''} ${t?.title||''} ${t?.phase||''}`.toLowerCase();return /(forge|build lab|design|candidate|prototype)/.test(sig)?'BUILDING':'WORKING'}
 const lr=String(s?.supervisor?.last_result||'').toUpperCase();if(/THROTTLED|SATURATED|COOLDOWN/.test(lr))return 'COOLDOWN';
 const sj=(s?.cron?.jobs||[]).find(x=>x.declaration_key==='kevin-supervisor-v1');if(sj?.enabled&&sj?.last_status==='ok')return 'ARMED';return 'READY';
}
async function refreshTruth(){
 try{const b=Date.now(),base='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/';const [dr,sr]=await Promise.all([fetch(`${base}dashboard-state.json?ts=${b}`,{cache:'no-store'}),fetch(`${base}support-latest.json?ts=${b}`,{cache:'no-store'})]);if(!dr.ok||!sr.ok)throw new Error('telemetry');syncHeader(classify(await dr.json(),await sr.json()))}catch(_e){}
}
function stateLabel(s){return s==='WORKING'?'working':s==='BUILDING'?'building':s==='ARMED'?'armed':s==='COOLDOWN'?'cooldown':s==='DEGRADED'?'degraded':s==='OFFLINE'?'offline':'ready'}
function syncHeader(state){
 lastOpsState=STATE_COLORS[state]?state:'READY';if(!doc)return;const av=doc.querySelector('#headerKevin .kevin-avatar');if(!av)return;
 [...av.classList].filter(c=>c.startsWith('owner-sync-')).forEach(c=>av.classList.remove(c));av.classList.add('owner-sync-'+stateLabel(lastOpsState));
 const label=doc.getElementById('owlLabel');if(label){const lvl=av.dataset.level||'—';label.textContent=`Evolution ${lvl}/5 · ${stateLabel(lastOpsState)}`}
}
function streamlineNav(){if(!doc)return;doc.querySelectorAll('[data-tab="talk"]').forEach(x=>x.remove());if((core?.location?.hash||'').toLowerCase()==='#talk')core.location.hash='#overview'}
function fixReaderLabel(){if(!doc)return;doc.querySelectorAll('.service-chip').forEach(chip=>{const b=chip.querySelector('b'),span=chip.querySelector('span');if(b?.textContent.trim()==='Reader'&&span?.textContent.trim().toUpperCase()==='GREEN')span.textContent='READY'})}
function moveHandoverToTop(){
 if(!doc||!core)return;const overview=(core.location.hash||'#overview').slice(1)==='overview';if(!overview)return;const main=doc.getElementById('main'),hero=main?.querySelector('.hero'),card=doc.getElementById('hqHandoverCard');if(!main||!hero||!card)return;
 if(card.nextElementSibling!==hero)main.insertBefore(card,hero);const title=card.querySelector('.k');if(title)title.textContent='AI HANDOVER · SHARE KEVIN';const help=card.querySelector('.h');if(help)help.textContent='Always fetches the newest AI-HANDOVER.md so another AI can resume Kevin with goals, plans, proof state, blockers, and next actions.';const copy=card.querySelector('#hqCopyHandover');if(copy)copy.textContent='COPY KEVIN HANDOVER'
}
function removeOverviewDuplicateChart(){if(!doc||!core||(core.location.hash||'#overview').slice(1)!=='overview')return;const chart=doc.getElementById('chartWrap'),card=chart?.closest('.card');if(card)card.remove()}
function refine(){installStyles();streamlineNav();fixReaderLabel();moveHandoverToTop();removeOverviewDuplicateChart();syncHeader(lastOpsState)}
function hook(){
 if(hooked)return;hooked=true;core=frame.contentWindow;doc=frame.contentDocument;installStyles();refine();
 const main=doc.getElementById('main'),nav=doc.getElementById('nav'),rail=doc.getElementById('serviceRail');if('MutationObserver'in window){observer=new MutationObserver(refine);[main,nav,rail].filter(Boolean).forEach(x=>observer.observe(x,{childList:true,subtree:true}))}
 setInterval(refine,650);setInterval(async()=>{if(refreshing||!core||typeof core.load!=='function')return;refreshing=true;try{await core.load()}catch(_e){}finally{refreshing=false}},5000);refreshTruth();setInterval(refreshTruth,3000)
}
window.addEventListener('message',e=>{if(e.origin!==location.origin||e.data?.type!=='kevin-ops-state')return;syncHeader(String(e.data.state||'READY').toUpperCase())});
frame.addEventListener('load',hook);if(frame.contentDocument?.readyState==='complete')hook();
})();
