(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
if(!frame)return;
const RAW='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/';
const EXPECTED=[
  ['self-heal','Self-heal'],
  ['self-maintenance','Self-maintain'],
  ['blocked-work-recovery','Recover blockers'],
  ['knowledge-integrity','Protect knowledge'],
  ['self-improvement','Self-improve'],
  ['capability-growth','Learn & grow'],
  ['owner-value-scan','Create owner value']
];
const EXPECTED_STANDING=new Set([
  'platform-self-heal-watch-v1',
  'runtime-self-maintenance-audit-v1',
  'blocked-work-recovery-v1',
  'knowledge-integrity-sweep-v1',
  'capability-gap-growth-v1',
  'owner-value-opportunity-scan-v1'
]);
let core=null,doc=null,bound=null,busy=false,taskMd='',catalog=null,policy=null,work=null,pending=false;
const esc=v=>String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
async function text(path){const r=await fetch(`${RAW}${path}?hqg=${Date.now()}`,{cache:'no-store'});if(!r.ok)throw Error(path);return r.text()}
async function json(path){const r=await fetch(`${RAW}${path}?hqg=${Date.now()}`,{cache:'no-store'});if(!r.ok)throw Error(path);return r.json()}
function clean(v){return String(v||'').replace(/\*\*/g,'').replace(/`/g,'').trim()}
function section(needle,limit=12){
  const lines=String(taskMd||'').split(/\r?\n/);let on=false,out=[];
  for(const raw of lines){
    const line=raw.trim();
    if(/^##\s+/.test(line)){
      if(on)break;
      on=line.toLowerCase().includes(String(needle).toLowerCase());
      continue;
    }
    if(!on)continue;
    const n=line.match(/^\d+\.\s+(.+)$/);if(!n)continue;
    const body=n[1].trim();let title='',detail='';
    let m=body.match(/^\*\*(.+?)[.]?\*\*\s*(.*)$/);
    if(m){title=clean(m[1]).replace(/[.:;]+$/,'');detail=clean(m[2]).replace(/^[—–:-]+\s*/,'')}
    else if((m=body.match(/^`([^`]+)`\s*[—–-]\s*(.+)$/))){title=clean(m[1]);detail=clean(m[2])}
    else if((m=body.match(/^(.+?)\s+[—–-]\s+(.+)$/))){title=clean(m[1]);detail=clean(m[2])}
    else if((m=body.match(/^([^:]+):\s+(.+)$/))){title=clean(m[1]);detail=clean(m[2])}
    else{title=clean(body);detail=''}
    if(title){out.push([title,detail]);if(out.length>=limit)break}
  }
  return out;
}
function styles(){
  if(!doc||doc.getElementById('hqGrowthV1Style'))return;
  const st=doc.createElement('style');st.id='hqGrowthV1Style';st.textContent=`
#hqGrowthV1{overflow:hidden;background:radial-gradient(560px 210px at 100% 0,rgba(127,200,191,.08),transparent 62%),linear-gradient(180deg,rgba(24,31,23,.97),rgba(17,22,16,.98))}
.v4growthTop{display:flex;align-items:flex-start;justify-content:space-between;gap:14px}.v4growthState{flex:0 0 auto;display:inline-flex;align-items:center;gap:7px;padding:7px 9px;border-radius:999px;border:1px solid rgba(215,176,111,.3);background:rgba(215,176,111,.08);color:#efd9ae;font:800 9px/1 ui-monospace,monospace;letter-spacing:.06em}.v4growthState.live{border-color:rgba(169,201,154,.34);background:rgba(169,201,154,.09);color:#dcebd5}.v4growthState.bad{border-color:rgba(220,123,107,.38);background:rgba(220,123,107,.08);color:#f1b6ac}.v4growthState i{width:7px;height:7px;border-radius:50%;background:currentColor;box-shadow:0 0 12px currentColor}.v4growthGrid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:7px;margin-top:12px}.v4growthPill{display:flex;align-items:center;gap:8px;min-height:34px;padding:8px 9px;border:1px solid var(--line);border-radius:11px;background:rgba(255,255,255,.018)}.v4growthPill i{width:7px;height:7px;border-radius:50%;background:var(--v3ok)}.v4growthPill.off i{background:var(--v3bad)}.v4growthPill b{font-size:10px}.v4path{margin-top:12px;padding:11px 12px;border-radius:12px;border:1px solid rgba(127,200,191,.17);background:rgba(127,200,191,.025)}.v4path b{display:block;font-size:10px;color:#cdece7;text-transform:uppercase;letter-spacing:.08em}.v4path span{display:block;margin-top:5px;color:var(--muted);font-size:10px;line-height:1.45}.v4truth{margin-top:8px;color:var(--muted);font-size:9px;line-height:1.4}.v4truth strong{color:var(--fg);font-weight:700}@media(min-width:760px){.v4growthGrid{grid-template-columns:repeat(7,minmax(0,1fr))}}@media(max-width:620px){.v4growthTop{display:block}.v4growthState{margin-top:10px}.v4growthGrid{grid-template-columns:1fr 1fr}}
  `;doc.head.appendChild(st);
}
function cardByKey(key){
  const page=doc?.querySelector('[data-hq-v3="overview"]');if(!page)return null;
  return [...page.querySelectorAll('.v3card')].find(c=>String(c.querySelector('.v3head .k')?.textContent||'').trim().toUpperCase()===key)||null;
}
function rewritePriorities(){
  const rows=section('current live platform repair targets',8);if(!rows.length)return;
  const card=cardByKey('NEXT');if(!card)return;
  card.querySelectorAll(':scope>.v3row').forEach(x=>x.remove());
  card.insertAdjacentHTML('beforeend',rows.map((x,i)=>`<div class="v3row"><i>${i+1}</i><div><b>${esc(x[0])}</b>${x[1]?`<div class="h">${esc(x[1])}</div>`:''}</div></div>`).join(''));
  const h=card.querySelector('.v3head .h');if(h)h.textContent='Live priorities parsed from the canonical current owner task.';
}
function rewriteSkills(){
  const rows=section('owner-value skill wave',6);if(!rows.length)return;
  const card=cardByKey('OWNER VALUE');if(!card)return;
  const grid=card.querySelector('.v3skills');if(!grid)return;
  grid.innerHTML=rows.map(x=>`<div><b>${esc(x[0].replace(/@1$/,''))}</b><span>${esc(x[1])}</span></div>`).join('');
  const h=card.querySelector('.v3head .h');if(h)h.textContent='Current job, vehicles, business, creator income, crypto research and home — not stale construction defaults.';
}
function sourceState(){
  const programs=new Set(Array.isArray(policy?.programs)?policy.programs:[]);
  const standing=new Set(Array.isArray(catalog?.standing_work)?catalog.standing_work.map(x=>String(x?.id||'')):[]);
  const allPrograms=EXPECTED.every(([id])=>programs.has(id));
  const allStanding=[...EXPECTED_STANDING].every(id=>standing.has(id));
  return {ready:allPrograms&&allStanding,programs,standing};
}
function activeGrowthEvidence(){
  const items=Array.isArray(work?.items)?work.items:[];
  return items.find(x=>{
    const p=String(x?.program||'');if(!EXPECTED.some(([id])=>id===p))return false;
    const active=/^(RUNNING|WORKING|ACTIVE)$/i.test(String(x?.status||''));
    const lease=Boolean(x?.lease_id||x?.lease?.id||x?.lease?.lease_id);
    const evidence=Boolean(x?.machine_evidence||x?.evidence_receipt||x?.receipt||x?.checkpoint?.evidence);
    return active&&lease&&evidence;
  })||null;
}
function growthCard(){
  const page=doc?.querySelector('[data-hq-v3="overview"]');if(!page)return;
  const src=sourceState(),live=activeGrowthEvidence();
  let status='SOURCE CONTRACT INCOMPLETE',cls='bad';
  if(src.ready){status='SOURCE READY · LIVE CROSSING PENDING';cls=''}
  if(src.ready&&live){status='LIVE EVIDENCE SEEN';cls='live'}
  const pills=EXPECTED.map(([id,label])=>`<div class="v4growthPill ${src.programs.has(id)?'':'off'}"><i></i><b>${esc(label)}</b></div>`).join('');
  const html=`<section id="hqGrowthV1" class="v3card"><div class="v4growthTop"><div class="v3head"><div class="k">CONTINUOUS GROWTH</div><h2>Kevin’s self-reliance engine</h2><div class="h">Persistent, proactive growth without fake work or self-widening authority.</div></div><div class="v4growthState ${cls}"><i></i>${esc(status)}</div></div><div class="v4growthGrid">${pills}</div><div class="v4path"><b>Next production crossing</b><span>Desktop tools → Work Supply → capability-aware routing → mission leases/checkpoints → recurring scheduler windows → replayed owner outcomes.</span></div><div class="v4truth"><strong>Truth boundary:</strong> source policy and CI readiness are not 24/7 runtime proof. HQ only upgrades this card to LIVE when a growth occurrence carries active status, a lease and machine evidence.</div></section>`;
  const existing=doc.getElementById('hqGrowthV1');
  if(existing){existing.outerHTML=html;return}
  const stats=page.querySelector(':scope>.v3stats');if(stats)stats.insertAdjacentHTML('afterend',html);else page.insertAdjacentHTML('afterbegin',html);
}
function render(){if(pending)return;pending=true;requestAnimationFrame(()=>{pending=false;if(!doc)return;styles();if((core?.location?.hash||'#overview').toLowerCase()!=='#overview')return;rewritePriorities();rewriteSkills();growthCard()})}
function bind(){
  try{const w=frame.contentWindow,d=frame.contentDocument;if(!w||!d||!/hq-core-v7\.html/.test(String(d.location?.href||'')))return false;core=w;doc=d}catch(_e){return false}
  if(bound===doc){render();return true}bound=doc;styles();render();
  const main=doc.getElementById('main');if(main&&'MutationObserver'in window){new MutationObserver(render).observe(main,{childList:true,subtree:false})}
  core.addEventListener('hashchange',()=>setTimeout(render,0));return true;
}
async function refresh(){
  if(busy)return;busy=true;
  try{
    const jobs=[text('inbox/CURRENT_TASK.md'),json('control-plane/autonomy/standing-work-supply-v1.json'),json('control-plane/autonomy/continuous-growth-policy-v1.json'),json('inbox/autonomy/work-items.json')];
    const got=await Promise.allSettled(jobs);
    if(got[0].status==='fulfilled')taskMd=got[0].value;
    if(got[1].status==='fulfilled')catalog=got[1].value;
    if(got[2].status==='fulfilled')policy=got[2].value;
    if(got[3].status==='fulfilled')work=got[3].value;
  }finally{busy=false;bind();render()}
}
frame.addEventListener('load',()=>{bind();refresh()});
setTimeout(()=>{bind();refresh()},0);
setInterval(refresh,12000);
})();
