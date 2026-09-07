(()=>{
'use strict';
const RAW='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/';
const PATHS={dashboard:'reports/dashboard-state.json',engineering:'reports/engineering/latest.json',support:'reports/support-latest.json',continuation:'reports/autonomy-continuation-latest.json',work:'inbox/autonomy/work-items.json'};
const TERMINAL=new Set(['COMPLETE','COMPLETED','DONE','CLOSED','PROVEN','OMEN_PROVEN','REPEATEDLY_PROVEN','RETIRED','SUPERSEDED']);
const cache={};let busy=false,timer=null,paintTimer=null;
function parseTs(v){if(!v)return NaN;const t=Date.parse(String(v).replace(/(\.\d{3})\d+(?=(?:Z|[+-]\d{2}:\d{2})$)/,'$1'));return Number.isFinite(t)?t:NaN}
function age(v){const t=parseTs(v);return Number.isFinite(t)?Math.max(0,(Date.now()-t)/1000):Infinity}
function fresh(o,n){return age(o?.generated_at||o?.at||o?.updated_at)<=n}
function activeTask(t){return!!t&&!/(done|complete|completed|failed|stopped|idle|queued|wait|cooldown|yield|skip|cancel|reject)/i.test(String(t.phase||t.status||''))}
function eligible(){const xs=Array.isArray(cache.work?.items)?cache.work.items:[];return xs.filter(x=>!TERMINAL.has(String(x?.status||'').toUpperCase())&&x?.blocked!==true&&x?.dependencies_ready!==false&&String(x?.status||'').toUpperCase()!=='BLOCKED'&&String(x?.authority_class||'GREEN').toUpperCase()==='GREEN')}
function activeWorkers(){if(!fresh(cache.support,360))return 0;return Object.values(cache.support?.active_workers||{}).reduce((n,v)=>n+(Number(v)||0),0)}
function truth(){const task=fresh(cache.dashboard,180)&&activeTask(cache.dashboard?.current_task)?cache.dashboard.current_task:null,workers=activeWorkers(),q=eligible().length;if(!fresh(cache.dashboard,180))return{state:'offline',label:'UNVERIFIED',detail:'Dashboard telemetry is stale.',task:null,workers,q};if(task||workers>0)return{state:'working',label:'WORKING',detail:task?String(task.title||task.id||'governed task'):`${workers} active worker${workers===1?'':'s'}`,task,workers,q};if(q>0)return{state:'ready',label:'ARMED',detail:`No active execution · ${q} eligible mission${q===1?'':'s'}`,task:null,workers:0,q};return{state:'ready',label:'READY',detail:'No active execution · no eligible mission',task:null,workers:0,q}}
async function get(path){const r=await fetch(`${RAW}${path}?opsv2=${Date.now()}`,{cache:'no-store'});if(!r.ok)throw Error(path);return r.json()}
async function refresh(){if(busy)return;busy=true;try{const rows=await Promise.all(Object.entries(PATHS).map(async([k,p])=>{try{return[k,await get(p)]}catch{return[k,null]}}));for(const[k,v]of rows)if(v)cache[k]=v;paint()}finally{busy=false}}
function setText(id,v){const el=document.getElementById(id);if(el)el.textContent=v}
function paint(){const t=truth(),c=cache.continuation||{},badge=document.getElementById('kevinState'),meta=document.getElementById('kevinMeta');if(badge){badge.className='kevin-states';badge.innerHTML=`<span class="loop state-${t.state}" style="--kstatec:${t.state==='working'?'#79c56a':t.state==='offline'?'#e46f61':'#68d8ce'}">${t.label}</span>`}if(meta){meta.innerHTML=`<div><b>${t.label==='WORKING'?'Live execution':'Autonomy ready'}</b></div><div>${t.detail}</div>`}setText('mission',t.task?String(t.task.title||t.task.id||'Active governed task'):'No active mission');setText('action',t.task?String(t.task.phase||'Executing'):(c.selected_id?`Last attempt: ${String(c.selected_id).replace(/[-_]+/g,' ')}`:'Standing by'));setText('recent',c.status?String(c.status).replaceAll('_',' '):'No recent continuation status');setText('activeWorkers',`${t.workers} active · ${t.q} eligible`);const hub=document.querySelector('#hubKevinProd .kevin-avatar-prod,#kevinHub .kevin-avatar-prod');if(hub){hub.classList.remove('mode-working','mode-ready','mode-degraded','mode-disconnected');hub.classList.add(t.state==='working'?'mode-working':t.state==='offline'?'mode-disconnected':'mode-ready')}
 const chip=document.getElementById('overallChip');if(chip){chip.textContent=t.label==='WORKING'?'LIVE WORK':t.label;chip.className='chip '+(t.state==='working'?'ok':'')}
}
function start(){refresh();if(timer)clearInterval(timer);if(paintTimer)clearInterval(paintTimer);timer=setInterval(refresh,8000);paintTimer=setInterval(paint,1000)}
addEventListener('load',start);if(document.readyState==='interactive'||document.readyState==='complete')start();
})();
