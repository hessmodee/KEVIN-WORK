(()=>{
'use strict';
// Kevin HQ evidence precedence adapter v2.
// Reconciles known stale/derived Support fields only when a fresher independently
// qualified source proves a narrower current fact. Raw repository evidence is never
// rewritten; superseded values remain attached as legacy/last-operation context.

const originalFetch=window.fetch.bind(window);
const EXPECTED_CRON=new Set([
  'kevin-engineering-relay-v1','kevin-skill-lab-v1','kevin-supervisor-v1',
  'kevin-benchmark-v1','kevin-support-bridge-v1','kevin-maintenance-intake-v1'
]);
const TOOLSET_SHA='564D5607031E853D56F7327E93D6DC81E236F4CDAB2B4478B29FB38925D726CD';
const MAX_CANARY_AGE_MS=30*60*1000;
const MAX_ENGINEERING_AGE_MS=6*60*1000;
const MAX_CONTINUATION_AGE_MS=15*60*1000;

function parseTs(v){
  if(!v)return NaN;
  const t=Date.parse(String(v).replace(/(\.\d{3})\d+(?=(?:Z|[+-]\d{2}:\d{2})$)/,'$1'));
  return Number.isFinite(t)?t:NaN;
}
function fresh(ts,max){
  const t=parseTs(ts);
  return Number.isFinite(t)&&Date.now()-t>=0&&Date.now()-t<=max;
}
function exactFiveCanary(c){
  return !!c&&fresh(c.generated_at,MAX_CANARY_AGE_MS)&&
    c.state==='OMEN_PROVEN'&&c.status==='ok'&&Number(c.agent_exit_code)===0&&
    c.agent==='fixed:main'&&Number(c.visible_tool_count)===5&&Number(c.visible_kevin_tool_count)===5&&
    c.has_kevin_system_status===true&&c.visible_tool_names_sha256===TOOLSET_SHA&&
    c.canary_shape?.transcript?.present===true&&c.canary_shape?.transcript?.complete===true&&
    c.canary_shape?.transcript?.provider==='ollama-chat-16k'&&c.canary_shape?.transcript?.model_id==='qwen2.5:14b';
}
function engineeringCronMap(e){
  if(!e||!fresh(e.generated_at,MAX_ENGINEERING_AGE_MS))return null;
  const rows=e?.action?.cron;
  if(!Array.isArray(rows))return null;
  return new Map(rows.map(x=>[x.declaration_key,x]));
}
function cronRowHealthy(row){
  return !!row&&row.enabled===true&&String(row.last_status||'').toLowerCase()==='ok'&&Number(row.consecutive_errors||0)===0;
}
function healthyEngineeringCron(e){
  const by=engineeringCronMap(e);
  if(!by||[...EXPECTED_CRON].some(k=>!by.has(k)))return false;
  return [...EXPECTED_CRON].every(k=>cronRowHealthy(by.get(k)));
}
function healthyDeclaredCron(e,key){
  const by=engineeringCronMap(e);
  return !!by&&cronRowHealthy(by.get(key));
}
function freshContinuation(c){
  return !!c&&c.kind==='kevin-autonomy-continuation-public'&&
    fresh(c.generated_at,MAX_CONTINUATION_AGE_MS)&&
    typeof c.status==='string'&&c.status.length>0;
}
async function rawJson(url){
  const r=await originalFetch(url,{cache:'no-store'});
  if(!r.ok)throw new Error(`${url} ${r.status}`);
  return r.json();
}
function sibling(url,path){
  const u=new URL(url,location.href);
  const marker='/reports/';
  const at=u.pathname.indexOf(marker);
  if(at>=0)u.pathname=u.pathname.slice(0,at+1)+path;
  else u.pathname='/hessmodee/KEVIN-WORK/main/'+path;
  u.search=`hqev=${Date.now()}`;
  return u.toString();
}
function jsonResponse(body,base){
  return new Response(JSON.stringify(body),{
    status:base.status,
    statusText:base.statusText,
    headers:{'Content-Type':'application/json','X-Kevin-HQ-Evidence':'qualified-precedence-v2'}
  });
}
function reconcileSupervisor(body,continuation){
  if(!freshContinuation(continuation))return false;
  const old=body.supervisor||{};
  const previous={
    cycle:old.cycle??null,
    last_mission:old.last_mission??'',
    last_result:old.last_result??'',
    evidence_at:old.at||body.generated_at||null
  };
  body.supervisor={
    ...old,
    last_mission:continuation.selected_id||'',
    last_result:continuation.status,
    current_status:continuation.status,
    eligible_count:Number.isFinite(Number(continuation.eligible_count))?Number(continuation.eligible_count):null,
    same_fingerprint_turns:Number.isFinite(Number(continuation.same_fingerprint_turns))?Number(continuation.same_fingerprint_turns):null,
    outcome_proven:continuation.outcome_proven===true,
    evidence_source:'reports/autonomy-continuation-latest.json',
    evidence_at:continuation.generated_at,
    legacy_support_snapshot:previous,
    truth_boundary:'Scheduled selection evidence only; a completed model turn is not an owner outcome.'
  };
  return true;
}
function reconcileMaintenanceScheduler(body,engineering){
  if(!healthyDeclaredCron(engineering,'kevin-maintenance-intake-v1'))return false;
  const old=body.maintenance||{};
  const oldAt=parseTs(old.at);
  const engAt=parseTs(engineering.generated_at);
  if(Number.isFinite(oldAt)&&Number.isFinite(engAt)&&engAt<oldAt)return false;
  const oldStatus=String(old.status||'UNKNOWN');
  body.maintenance={
    ...old,
    status:'SCHEDULER_HEALTHY',
    scheduler_ok:true,
    scheduler_status:'ok',
    scheduler_consecutive_errors:0,
    scheduler_evidence_source:'reports/engineering/latest.json',
    scheduler_evidence_at:engineering.generated_at,
    last_operation_status:oldStatus,
    last_operation_detail:String(old.detail||''),
    detail:oldStatus&&oldStatus!=='SCHEDULER_HEALTHY'
      ?`Scheduler healthy now; last typed operation state was ${oldStatus}.`
      :'Maintenance scheduler is healthy.',
    truth_boundary:'Scheduler health is current Engineering cron evidence. Last typed operation state is retained separately and is not rewritten as success.'
  };
  return true;
}
async function adaptSupport(url,init){
  const base=await originalFetch(url,init);
  if(!base.ok)return base;
  const body=await base.clone().json();
  const [eng,canary,continuation]=await Promise.all([
    rawJson(sibling(url,'reports/engineering/latest.json')).catch(()=>null),
    rawJson(sibling(url,'reports/main-agent-canary-omen.json')).catch(()=>null),
    rawJson(sibling(url,'reports/autonomy-continuation-latest.json')).catch(()=>null)
  ]);
  body.hq_evidence_precedence=body.hq_evidence_precedence||{};
  if(healthyEngineeringCron(eng)){
    body.cron={
      ok:true,
      jobs:eng.action.cron,
      evidence_source:'reports/engineering/latest.json',
      evidence_at:eng.generated_at,
      supersedes:'support cron parser output when fresh Engineering proves all canonical jobs enabled, ok, and zero-error'
    };
    body.hq_evidence_precedence.cron='engineering/latest.json';
  }
  if(reconcileMaintenanceScheduler(body,eng)){
    body.hq_evidence_precedence.maintenance_scheduler='engineering/latest.json';
  }
  if(reconcileSupervisor(body,continuation)){
    body.hq_evidence_precedence.supervisor='autonomy-continuation-latest.json';
  }
  if(exactFiveCanary(canary)){
    body.public_truth=body.public_truth||{};
    body.public_truth.desktop_tool_inventory_count=5;
    body.public_truth.desktop_tool_inventory_status='PROVEN_VISIBLE_FIXED_MAIN';
    body.public_truth.desktop_tool_inventory_source='main-agent-canary-omen';
    body.public_truth.desktop_tool_inventory_evidence_at=canary.generated_at;
    body.public_truth.desktop_tool_inventory_sha256=canary.visible_tool_names_sha256;
    body.hq_evidence_precedence.desktop_tools='main-agent-canary-omen.json';
  }
  return jsonResponse(body,base);
}
async function adaptDashboard(url,init){
  const base=await originalFetch(url,init);
  if(!base.ok)return base;
  const body=await base.clone().json();
  const canary=await rawJson(sibling(url,'reports/main-agent-canary-omen.json')).catch(()=>null);
  if(exactFiveCanary(canary)){
    body.brain=body.brain||{};
    body.brain.name='Qwen 2.5 14B';
    body.brain.context='16K';
    body.brain.tools=true;
    body.brain.evidence_source='reports/main-agent-canary-omen.json';
    body.brain.evidence_at=canary.generated_at;
    body.brain.provider='ollama-chat-16k';
    body.hq_evidence_precedence={...(body.hq_evidence_precedence||{}),brain:'main-agent-canary-omen.json'};
  }
  return jsonResponse(body,base);
}

window.fetch=async function(input,init){
  const url=typeof input==='string'?input:input?.url||'';
  try{
    if(/\/reports\/support-latest\.json(?:[?#]|$)/.test(url))return await adaptSupport(url,init);
    if(/\/reports\/dashboard-state\.json(?:[?#]|$)/.test(url))return await adaptDashboard(url,init);
  }catch(error){
    console.warn('Kevin HQ evidence adapter fail-closed:',error?.message||error);
  }
  return originalFetch(input,init);
};

window.__kevinEvidenceAdapterV2={
  exactFiveCanary,healthyEngineeringCron,healthyDeclaredCron,freshContinuation,
  reconcileSupervisor,reconcileMaintenanceScheduler,TOOLSET_SHA
};
})();