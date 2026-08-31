(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
if(!frame)return;
const BASE='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/';
let lastKey='';
function esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
function taskActive(t){if(!t)return false;const p=String(t.phase||'').toLowerCase();return !/(done|complete|completed|failed|stopped|idle|queued|wait|cooldown|yield)/.test(p)}
function activeWorkerCount(s){return Object.values(s?.active_workers||{}).reduce((n,v)=>n+(Number(v)||0),0)}
async function get(name){const r=await fetch(`${BASE}${name}?truth2=${Date.now()}`,{cache:'no-store'});if(!r.ok)throw new Error(name);return r.json()}
function attentionBox(){try{const d=frame.contentDocument;const box=d?.querySelector('#hqTruthConsole .hqtc-columns .hqtc-box');return box||null}catch(_e){return null}}
function removeOld(box){box?.querySelectorAll('[data-hq-truth-patch="v2"]').forEach(x=>x.remove())}
function add(box,sev,title,detail){const el=box.ownerDocument.createElement('div');el.className=`hqtc-item ${sev}`;el.dataset.hqTruthPatch='v2';el.innerHTML=`<b>${esc(title)}</b><div>${esc(detail)}</div>`;const h=box.querySelector('h4');if(h?.nextSibling)box.insertBefore(el,h.nextSibling);else box.appendChild(el)}
async function run(){let d,s;try{[d,s]=await Promise.all([get('dashboard-state.json'),get('support-latest.json')])}catch(_e){return}const box=attentionBox();if(!box)return;removeOld(box);const ev=s?.latest_evaluation||{},iteration=Number(ev.iteration||0),verdict=String(ev.verdict||'').toUpperCase(),sec=Number(ev.security_finding_count||0);if(verdict==='REJECT'&&(iteration>=10||sec>0))add(box,'bad','Repeated Forge rejection is not progress',`${ev.mission||'forge'} · iteration ${iteration||'?'} · latest verdict REJECT · security findings ${sec}. Failure counters may reset; high repeated rejected iteration remains an attention condition until demand/cooldown behavior changes.`);const active=taskActive(d?.current_task),workers=activeWorkerCount(s);if(active&&workers===0)add(box,'warn','Telemetry sources disagree about active work',`Dashboard reports active task “${d.current_task?.title||d.current_task?.id||'task'}” (${d.current_task?.phase||'active'}) while Support reports 0 active workers. Treat current-work truth as CONFLICTING until the collectors converge.`);lastKey=`${d?.generated_at}|${s?.generated_at}`}
frame.addEventListener('load',()=>setTimeout(run,1200));setInterval(run,20000);setTimeout(run,1800);
})();
