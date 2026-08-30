(()=>{
'use strict';
const RAW='https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/';
const WAIT=/yield|cooldown|wait|skip|queued|idle|armed|complete|completed|done|stopped/i;
const COOL=/THROTTLED|SATURATED|WAIT|COOL/i;
let styleInstalled=false;
function norm(v){return String(v??'').toLowerCase()}
function ms(v){const n=Number(v);return Number.isFinite(n)?n:0}
function taskActive(t){return !!(t&&Object.keys(t).length&&!WAIT.test(String(t.phase||'')))}
function recentIso(v,seconds){const t=Date.parse(v||'');return Number.isFinite(t)&&Date.now()>=t&&(Date.now()-t)<=seconds*1000}
function supportJobs(s){const c=s?.cron;return Array.isArray(c)?c:(c?.jobs||[])}
function supervisorJob(s){return supportJobs(s).find(j=>j?.declaration_key==='kevin-supervisor-v1')||null}
function recentSupervisorCycle(s){const j=supervisorJob(s);const at=ms(j?.last_run_at_ms);return at>0&&Math.abs(Date.now()-at)<=10*60*1000}
function recentEngineering(d){return (d?.activity||[]).some(e=>['task_start','task_finish','task_progress'].includes(String(e?.event||''))&&['forge','supervisor','benchmark','skill-lab','engineering'].includes(norm(e?.component))&&recentIso(e?.at,15*60))}
function freshNext(s){const t=Date.parse(s?.supervisor?.next_eligible_at||'');if(!Number.isFinite(t))return false;const delta=t-Date.now();return delta>=-5*60*1000&&delta<=15*60*1000}
function classify(d,s){
  const generated=[Date.parse(d?.generated_at||''),Date.parse(s?.generated_at||'')].filter(Number.isFinite);
  const freshest=generated.length?Math.max(...generated):0;
  if(!freshest||Date.now()-freshest>15*60*1000)return {state:'OFFLINE',active:false,evidence:'Telemetry stale'};
  const health=norm(d?.health?.overall||d?.status);
  if(health&& !['healthy','ready'].includes(health))return {state:'DEGRADED',active:false,evidence:`Health ${health}`};
  const t=d?.current_task||null;
  if(taskActive(t))return {state:'ACTIVE',active:true,evidence:'Active current task',task:t};
  const sup=s?.supervisor||{},last=String(sup.last_result||'');
  if(COOL.test(last))return {state:'COOLDOWN',active:false,evidence:last||'Supervisor cooldown'};
  const job=supervisorJob(s),armed=!!(job&&job.enabled===true&&norm(job.last_status)==='ok');
  if(armed&&(recentEngineering(d)||freshNext(s)||recentSupervisorCycle(s))){
    const why=[];if(recentEngineering(d))why.push('recent engineering');if(freshNext(s))why.push('next cycle');if(recentSupervisorCycle(s))why.push('recent supervisor cycle');
    return {state:'ARMED',active:false,evidence:why.join(' · ')||'Supervisor armed'};
  }
  return {state:'IDLE',active:false,evidence:'No active or armed-work evidence'};
}
function installStyle(){if(styleInstalled)return;styleInstalled=true;const st=document.createElement('style');st.textContent=`
#kevinHub.truth-armed .hub-inner{animation:hqArmedPulse 3.6s ease-in-out infinite;box-shadow:0 0 0 1px rgba(104,216,206,.18),0 0 32px rgba(104,216,206,.08)}
#kevinHub.truth-active .hub-inner{animation:hqActiveBob 2s ease-in-out infinite}
#kevinHub.truth-cooldown .hub-inner{filter:saturate(.8)}
@keyframes hqArmedPulse{0%,100%{transform:scale(1);box-shadow:0 0 0 1px rgba(104,216,206,.15),0 0 18px rgba(104,216,206,.05)}50%{transform:scale(1.015);box-shadow:0 0 0 2px rgba(104,216,206,.26),0 0 36px rgba(104,216,206,.12)}}
@keyframes hqActiveBob{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}
.truth-note{font-size:10px;opacity:.8;margin-top:4px}
`;document.head.appendChild(st)}
function labelClass(state){return ({ACTIVE:'working',ARMED:'ready',COOLDOWN:'cooldown',DEGRADED:'degraded',OFFLINE:'offline',IDLE:'ready'})[state]||'ready'}
function newestActivity(d){return [...(d?.activity||[])].sort((a,b)=>Date.parse(b?.at||0)-Date.parse(a?.at||0))[0]||null}
function fmtNext(s){const v=s?.supervisor?.next_eligible_at;if(!v)return '';const t=Date.parse(v);if(!Number.isFinite(t))return '';const sec=Math.round((t-Date.now())/1000);if(sec<=0&&sec>=-300)return 'next cycle due now';if(sec>0&&sec<3600)return `next cycle in ${Math.ceil(sec/60)}m`;return ''}
function apply(d,s){
  installStyle();const c=classify(d,s),sup=s?.supervisor||{},hub=document.getElementById('kevinHub');
  if(hub){hub.classList.remove('truth-active','truth-armed','truth-cooldown','truth-idle','truth-degraded','truth-offline');hub.classList.add('truth-'+c.state.toLowerCase())}
  const badge=document.getElementById('kevinState');if(badge){const cls=labelClass(c.state);badge.className='kevin-states';badge.innerHTML=`<span class="loop state-${cls}" style="--kstatec:${c.state==='ACTIVE'?'#79c56a':c.state==='COOLDOWN'?'#b38cff':c.state==='DEGRADED'?'#ff9a3d':c.state==='OFFLINE'?'#e46f61':'#68d8ce'}">${c.state}</span>`}
  const meta=document.getElementById('kevinMeta');if(meta){const mission=sup.last_mission||'No mission selected',next=fmtNext(s);meta.innerHTML=`<div><b>${c.state==='ACTIVE'?'Executing now':c.state==='ARMED'?'Autonomy armed':c.state==='COOLDOWN'?'Cooling safely':'Autonomy loop enabled'}</b> · cycle ${sup.cycle??'—'}</div><div>${mission}${sup.last_result?' · '+sup.last_result:''}${next?' · '+next:''}</div><div class="truth-note">Evidence: ${c.evidence}</div>`}
  const mission=document.getElementById('mission'),action=document.getElementById('action'),recent=document.getElementById('recent'),evidence=document.getElementById('evidence');
  const t=c.task||d?.current_task||null,ev=newestActivity(d),next=fmtNext(s);
  if(mission)mission.textContent=c.state==='ACTIVE'?(t?.title||t?.id||sup.last_mission||'Active task'):c.state==='ARMED'?`ARMED · ${sup.last_mission||'autonomous queue'}`:c.state;
  if(action)action.textContent=c.state==='ACTIVE'?(t?.phase||t?.category||'Executing'):c.state==='ARMED'?(next||sup.last_result||'Waiting between governed cycles'):(sup.last_result||c.evidence);
  if(recent)recent.textContent=ev?(ev.detail||ev.event||ev.label||'Recent telemetry event'):(sup.last_result||'No recent event');
  if(evidence)evidence.textContent=`${c.evidence} · cycle ${sup.cycle??'—'}`;
}
async function loadTruth(){try{const bust=Date.now();const [d,s]=await Promise.all([fetch(`${RAW}dashboard-state.json?ts=${bust}`,{cache:'no-store'}).then(r=>r.json()),fetch(`${RAW}support-latest.json?ts=${bust}`,{cache:'no-store'}).then(r=>r.json())]);apply(d,s)}catch(_e){}}
addEventListener('load',()=>{setTimeout(loadTruth,300);setTimeout(loadTruth,1200)});setInterval(loadTruth,5000);
})();
