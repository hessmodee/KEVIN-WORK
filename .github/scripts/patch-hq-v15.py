from pathlib import Path
import re

INDEX=Path('docs/index.html')
EMBED=Path('docs/ops/embed.html')
JS=Path('docs/ops/ops-v11.js')
CSS=Path('docs/ops/ops-v11.css')

index=INDEX.read_text(encoding='utf-8')
embed=EMBED.read_text(encoding='utf-8')
js=JS.read_text(encoding='utf-8')
css=CSS.read_text(encoding='utf-8')

MOJIBAKE={
    'â€”':'—','â€“':'–','â€¦':'…','Â·':'·','â€¢':'•','â†’':'→','â†':'←',
    'â€œ':'“','â€':'”','â€™':'’','â€˜':'‘','Ã—':'×','Â°':'°','Â°F':'°F','Â':'',
}
def clean(s):
    for a,b in MOJIBAKE.items(): s=s.replace(a,b)
    return s

index,embed,js,css=map(clean,(index,embed,js,css))

# Cache-bust the embedded Ops document and its assets.
index,n=re.subn(r'ops/embed\.html(?:\?v=\d+)?','ops/embed.html?v=15',index)
if n<1: raise SystemExit('Ops iframe reference not found')
embed,n1=re.subn(r'ops-v11\.css\?v=\d+','ops-v11.css?v=15',embed)
embed,n2=re.subn(r'ops-v11\.js\?v=\d+','ops-v11.js?v=15',embed)
if n1<1 or n2<1: raise SystemExit('Ops inner cache references not found')

# Evidence-backed progress helpers. Percentages come from explicit completed/total or explicit pct fields.
progress_helpers=r'''
function clampPct(v){const n=Number(v);return Number.isFinite(n)?Math.max(0,Math.min(100,Math.round(n))):null}
function progressFromObject(o){
 if(!o||typeof o!=='object')return null;
 for(const k of ['progress_pct','percent','pct']){const p=clampPct(o[k]);if(p!==null)return p}
 const done=Number(o.completed??o.done),total=Number(o.total);
 if(Number.isFinite(done)&&Number.isFinite(total)&&total>0&&done>=0)return clampPct((done/total)*100);
 return null;
}
function taskMatchesWorker(key,t){
 const tt=taskText(t);
 if(key==='build')return /design forge|forge|build|builder|mission factory/.test(tt);
 if(key==='night')return /night[- ]forge|night forge|qa\/regression/.test(tt);
 if(key==='benchmark')return /benchmark|regression/.test(tt);
 if(key==='reader')return /reader|read-only|research|source review/.test(tt);
 if(key==='staging')return /staging|promotion|champion/.test(tt);
 if(key==='chat')return /chat|reasoning|analysis|planning|conversation/.test(tt);
 if(key==='ollama')return taskActive(t);
 return false;
}
function workerProgress(key,state,d,s){
 if(!['working','building'].includes(state))return null;
 const candidates=[s?.worker_progress?.[key],d?.worker_progress?.[key],d?.ops_floor?.progress?.[key]];
 for(const c of candidates){const p=progressFromObject(c);if(p!==null)return {percent:p,measured:true,detail:'Explicit worker progress telemetry'}}
 const t=d?.current_task||null;
 if(taskActive(t)&&taskMatchesWorker(key,t)){
   const p=progressFromObject(t);
   if(p!==null)return {percent:p,measured:true,detail:'Confirmed task checkpoints'};
   return {percent:0,measured:false,detail:'Active; no completed progress checkpoint has been reported yet'};
 }
 if(key==='bridge'||key==='tick')return {percent:100,measured:true,detail:'Most recent scheduled cycle completed'};
 return {percent:0,measured:false,detail:'Active; awaiting explicit progress telemetry'};
}
'''
marker="function telemetryOffline(d,s){return telemetryAgeMs(d,s)>15*60*1000}\n"
if progress_helpers.strip() not in js:
    if marker not in js: raise SystemExit('telemetryOffline insertion marker missing')
    js=js.replace(marker,marker+'\n'+progress_helpers+'\n',1)

old_worker="WORKERS.forEach((w,i)=>{const st=workerState(w.key,d,s),p=positions[i];if(['working','building'].includes(st))active.push({w,st});lineBetween(top,center,p,st);const el=document.createElement('div');el.className=`worker ${st}`;el.style.cssText=`left:${(p.x/top.clientWidth)*100}%;top:${(p.y/top.clientHeight)*100}%;--idc:${w.c};--statec:${stateColor(st)}`;el.innerHTML=`<div class=\"box\">${owl(w.c,w.key)}<div class=\"worker-copy\"><b>${w.name}</b><small>${w.role}</small><span class=\"state\">${stateLabel(st)}</span></div></div>`;el.onclick=()=>selectWorker(w,st,d,s);top.appendChild(el)});"
new_worker="WORKERS.forEach((w,i)=>{const st=workerState(w.key,d,s),p=positions[i];if(['working','building'].includes(st))active.push({w,st});lineBetween(top,center,p,st);const prog=workerProgress(w.key,st,d,s),el=document.createElement('div');el.className=`worker ${st}`;el.style.cssText=`left:${(p.x/top.clientWidth)*100}%;top:${(p.y/top.clientHeight)*100}%;--idc:${w.c};--statec:${stateColor(st)}`;const progressHtml=prog?`<div class=\"worker-progress ${prog.measured?'measured':'checkpoint-wait'}\" title=\"${esc(prog.detail)}\"><div class=\"worker-progress-fill\" style=\"width:${prog.percent}%\"></div><span>${prog.percent}%</span></div>`:'';el.innerHTML=`<div class=\"box\">${owl(w.c,w.key)}<div class=\"worker-copy\"><b>${w.name}</b><small>${w.role}</small><span class=\"state\">${stateLabel(st)}</span></div></div>${progressHtml}`;el.onclick=()=>selectWorker(w,st,d,s);top.appendChild(el)});"
if old_worker not in js: raise SystemExit('worker render contract missing')
js=js.replace(old_worker,new_worker,1)

# Thin identity-color progress bar matching each worker card.
progress_css=".worker-progress{position:relative;width:146px;height:11px;margin:4px auto 0;border:1px solid color-mix(in srgb,var(--idc) 48%,transparent);border-radius:999px;overflow:hidden;background:rgba(5,9,5,.9);box-shadow:0 0 10px color-mix(in srgb,var(--idc) 10%,transparent);text-align:center}.worker-progress-fill{position:absolute;inset:0 auto 0 0;background:color-mix(in srgb,var(--idc) 58%,transparent);box-shadow:0 0 8px color-mix(in srgb,var(--idc) 35%,transparent);transition:width .35s ease}.worker-progress span{position:relative;z-index:1;display:block;font-size:7.5px;line-height:9px;font-weight:800;color:#f7f4ec;text-shadow:0 1px 2px #000;letter-spacing:.03em}.worker-progress.checkpoint-wait .worker-progress-fill{opacity:.35}"
if '.worker-progress{' not in css:
    anchor=".worker.degraded .owl-body{fill:color-mix(in srgb,var(--idc) 28%,transparent)}"
    if anchor not in css: raise SystemExit('progress CSS anchor missing')
    css=css.replace(anchor,anchor+'\n'+progress_css,1)
css=css.replace('.worker .box{width:136px}', '.worker .box{width:136px}.worker-progress{width:136px}')

# Correct stale Forge attention: only latest completed Design Forge outcomes count.
new_attention=r'''function deriveAttention(){
  const completedForge=sortedActivity().filter(e=>{
    const task=String(e.task_id||'').toLowerCase();
    const detail=String(e.detail||'').toLowerCase();
    const event=String(e.event||'').toLowerCase();
    const result=String(e.result||'').toLowerCase().trim();
    return event==='task_finish' && (task==='design-forge'||detail.includes('design forge')) && !!result;
  });
  const latestForgePass=completedForge.length && completedForge[0].result && String(completedForge[0].result).toLowerCase()==='pass';
  if(S?.attention && typeof S.attention.level==='string'){
    let items=Array.isArray(S.attention.items)?S.attention.items:[];
    items=items.filter(i=>!(latestForgePass && String(i?.id||'')==='design_forge_streak'));
    const level=items.some(i=>String(i?.level||'').toLowerCase()==='fail')?'fail':(items.length?'caution':'none');
    if(items.length)return {level,items};
  }
  const items=[];
  const push=(id,label,level)=>items.push({id,label,level});
  const health=S?.health||{};
  const overall=String(health.overall||'').toLowerCase();
  const fails=Number(health.failed_checks||0);
  if((overall && overall!=='healthy') || fails>0){
    push('health', fails>0?`${fails} check(s) failed`:'System health is not healthy', fails>0?'fail':(overall==='degraded'?'caution':'fail'));
  }
  const svc=S?.services||{};
  const ollama=String(svc.ollama||'').toLowerCase();
  if(ollama && ollama!=='healthy')push('ollama','Ollama is not healthy',['unhealthy','fail','failed','down'].includes(ollama)?'fail':'caution');
  const gateway=String(svc.gateway||'').toLowerCase();
  if(gateway && gateway!=='healthy')push('gateway','Gateway is not healthy',['unhealthy','fail','failed','down'].includes(gateway)?'fail':'caution');
  if(completedForge.length>=3 && completedForge.slice(0,3).every(e=>['fail','failed'].includes(String(e.result||'').toLowerCase()))){
    push('design_forge_streak','Design Forge failed 3 completed runs in a row','fail');
  }
  const running=typeof S?.execution?.running==='boolean'?S.execution.running:isExecuting();
  const active=!!(S?.campaign?.active || S?.current_task);
  const phase=String(S?.execution?.phase || S?.current_task?.phase || '');
  if(!running && active && /fail|blocked/i.test(phase))push('campaign_blocked',/fail/i.test(phase)?'Active campaign failed':'Active campaign is blocked','fail');
  let level='none';
  if(items.some(i=>i.level==='fail'))level='fail';else if(items.length)level='caution';
  return {level,items:items.map(i=>({id:i.id,label:i.label,level:i.level}))};
}
'''
pat=re.compile(r'function deriveAttention\(\)\{.*?\n\}\nfunction renderAttention\(\)\{',re.S)
m=pat.search(index)
if not m: raise SystemExit('deriveAttention function boundary missing')
index=index[:m.start()]+new_attention+'function renderAttention(){'+index[m.end():]

# Add external news feed state.
index=index.replace('let S=null,tab=', 'let S=null,EXT_NEWS=null,tab=', 1)

new_newswire=r'''function newswireStories(){
  const out=[];
  const add=x=>{if(x&&x.text)out.push(x)};
  const attention=deriveAttention();
  for(const a of (attention.items||[])) add({id:'kevin-attn-'+String(a.id||''),text:'KEVIN · '+String(a.label||a.id||'Needs attention'),severity:attention.level==='fail'?'fail':'caution'});
  for(const i of deriveNewswire()){
    if(['mission','health','verified','roadmap'].includes(String(i.id||''))) add({...i,text:'KEVIN · '+i.text});
  }
  const ext=EXT_NEWS||{};
  const generated=Date.parse(ext.generated_at||'');
  const fresh=Number.isFinite(generated) && (Date.now()-generated)<6*60*60*1000;
  if(fresh && ext?.weather?.summary)add({id:'public-weather',text:'WEATHER · '+ext.weather.summary,severity:'normal'});
  const labels={local:'LOCAL',national:'U.S.',world:'WORLD',top:'TOP'};
  if(fresh){
    for(const h of (ext.headlines||[])){
      const cat=String(h.category||'top').toLowerCase();
      const label=labels[cat]||'TOP';
      const source=String(h.source||'').trim();
      add({id:'news-'+cat+'-'+String(h.title||'').slice(0,80),text:`${label} · ${h.title}${source?' — '+source:''}`,severity:'normal',url:h.url||''});
    }
  }
  if(!out.some(x=>x.id==='public-weather')){
    const wx=String(S?.weather?.summary||'').trim();
    if(wx)add({id:'weather-fallback',text:'WEATHER · '+wx,severity:'normal'});
  }
  if(freshness().disconnected && !out.some(i=>i.id==='disconnected'))out.unshift({id:'disconnected',text:'KEVIN · Telemetry lost · showing last known snapshot',severity:'disconnected'});
  const seen=new Set();
  return out.filter(x=>{const k=String(x.text||'').toLowerCase().replace(/\W+/g,'').slice(0,180);if(!k||seen.has(k))return false;seen.add(k);return true}).slice(0,18);
}
'''
pat2=re.compile(r'function newswireStories\(\)\{.*?\n\}\nfunction paintNewswire\(\)\{',re.S)
m=pat2.search(index)
if not m: raise SystemExit('newswireStories boundary missing')
index=index[:m.start()]+new_newswire+'function paintNewswire(){'+index[m.end():]

# External public feed fetch is non-fatal; Kevin telemetry always remains primary.
fetch_news=r'''async function fetchExternalNewswire(){
  const bust=Date.now();
  const url=`https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/reports/newswire-latest.json?ts=${bust}`;
  const r=await fetch(url,{cache:'no-store'});
  if(!r.ok)throw new Error('newswire '+r.status);
  return await r.json();
}
'''
if 'async function fetchExternalNewswire()' not in index:
    marker='async function load(){'
    if marker not in index: raise SystemExit('load marker missing')
    index=index.replace(marker,fetch_news+'\n'+marker,1)

old_load="async function load(){\n try{\n  S=await fetchState();\n  renderNav();\n  draw();"
new_load="async function load(){\n try{\n  const pair=await Promise.all([fetchState(),fetchExternalNewswire().catch(()=>null)]);\n  S=pair[0];EXT_NEWS=pair[1];\n  renderNav();\n  draw();"
if old_load not in index: raise SystemExit('load body contract missing')
index=index.replace(old_load,new_load,1)

# One more scrub after generated text edits.
index,embed,js,css=map(clean,(index,embed,js,css))

# Fail if common mojibake signatures remain in production UI sources.
for name,text in [('index',index),('embed',embed),('js',js),('css',css)]:
    bad=[x for x in ('â€','â€”','â€¦','Â·','Ã—','\ufffd') if x in text]
    if bad: raise SystemExit(f'{name}: mojibake remains {bad}')

INDEX.write_text(index,encoding='utf-8',newline='\n')
EMBED.write_text(embed,encoding='utf-8',newline='\n')
JS.write_text(js,encoding='utf-8',newline='\n')
CSS.write_text(css,encoding='utf-8',newline='\n')
print('HQ_V15_PATCH_OK')
