from pathlib import Path
import re

embed_p=Path('docs/ops/embed.html')
js_p=Path('docs/ops/ops-v11.js')
css_p=Path('docs/ops/ops-v11.css')
index_p=Path('docs/index.html')
embed=embed_p.read_text(encoding='utf-8')
js=js_p.read_text(encoding='utf-8')
css=css_p.read_text(encoding='utf-8')
index=index_p.read_text(encoding='utf-8')

def once(text, old, new, label):
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'{label}: expected 1 match, found {n}')
    return text.replace(old,new,1)

# Shared HQ title: use the same stencil family as Kevin's center wordmark.
old_h1="h1{font-family:Georgia,serif;font-size:35px;font-weight:500;letter-spacing:-.03em;margin:0}"
new_h1="h1{font-family:'Stencil Std','Stencil','Copperplate','Impact',sans-serif;font-size:34px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;margin:0}"
index=once(index,old_h1,new_h1,'shared HQ stencil title')

# Force a fresh embedded Ops document as well as fresh inner CSS/JS.
index,n=re.subn(r"ops/embed\.html(?:\?v=\d+)?","ops/embed.html?v=14",index)
if n<1:
    raise SystemExit('shared HQ Ops iframe source was not found')
embed=re.sub(r"ops-v11\.css\?v=\d+","ops-v11.css?v=14",embed)
embed=re.sub(r"ops-v11\.js\?v=\d+","ops-v11.js?v=14",embed)

old_hub='<div class="hub" id="kevinHub"><div><div id="hubKevinProd"></div><h2>Kevin</h2><div class="role">Chief of Staff</div><div class="loop" id="kevinState">READY</div><div class="kevin-meta" id="kevinMeta"><div><b>Autonomy loop enabled</b></div><div>Waiting for telemetryâ€¦</div></div></div></div>'
new_hub='<div class="hub" id="kevinHub"><div class="hub-inner"><h2>Kevin</h2><div class="role">Chief of Staff</div><div id="hubKevinProd"></div><div class="kevin-states" id="kevinState" aria-live="polite"><span class="loop state-ready" style="--kstatec:#68d8ce">READY</span></div><div class="kevin-meta" id="kevinMeta"><div><b>Autonomy loop enabled</b></div><div>Waiting for telemetryâ€¦</div></div></div></div>'
embed=once(embed,old_hub,new_hub,'center Kevin ordering')
old_note='<span class="note">Active lanes flow · Ready lanes stay quiet · status colors are evidence-backed</span>'
new_note='<span class="note">WORKING = moving bars · BUILDING = moving dots · Ready lanes stay quiet · colors are evidence-backed</span>'
embed=once(embed,old_note,new_note,'lane legend truth note')

# Worker owl: feet + true eye cutouts via SVG mask. Body fills only when CSS says the lane is active.
old_owl=re.search(r"function owl\(c\)\{return `.*?</svg>`\}",js)
if not old_owl:
    raise SystemExit('owl function not found')
new_owl=r'''function owl(c,id='worker'){
 const safe=String(id||'worker').replace(/[^a-z0-9_-]/gi,'-');
 const mid=`owl-cut-${safe}`;
 return `<svg class="owl" viewBox="0 0 120 120" aria-hidden="true"><defs><mask id="${mid}"><rect width="120" height="120" fill="white"/><circle cx="46" cy="50" r="7.5" fill="black"/><circle cx="74" cy="50" r="7.5" fill="black"/></mask></defs><path class="owl-body" d="M27 48 Q20 36 23 19 Q32 25 40 25 Q49 18 60 18 Q71 18 80 25 Q89 25 97 19 Q100 36 93 48 Q100 55 97 67 Q94 79 84 88 Q74 98 60 98 Q46 98 36 88 Q26 79 23 67 Q20 55 27 48Z" mask="url(#${mid})" fill="none" stroke="${c}" stroke-width="4.2" stroke-linecap="round" stroke-linejoin="round"/><g class="owl-feet" fill="none" stroke="${c}" stroke-width="4" stroke-linecap="round"><path d="M42 101 Q47 106 52 101 M45 105 L43 109 M49 105 L50 109"/><path d="M68 101 Q73 106 78 101 M71 105 L70 109 M75 105 L77 109"/></g></svg>`
}'''
js=js[:old_owl.start()]+new_owl+js[old_owl.end():]

# Replace single Kevin-state priority with evidence-backed aggregate active states.
start=js.find('function kevinState(d,s){')
end=js.find('\nfunction ringPositions',start)
if start<0 or end<0:
    raise SystemExit('Kevin state function boundary not found')
new_states=r'''function kevinStates(d,s){
 if(telemetryOffline(d,s))return ['offline'];
 const health=norm(d?.health?.overall||d?.status);
 if(health && health!=='healthy' && health!=='ready')return ['degraded'];
 if(['bridge','tick','ollama','gateway'].some(k=>d?.services?.[k]&&norm(d.services[k])!=='healthy'))return ['degraded'];
 const active=new Set();
 for(const w of WORKERS){
   const st=workerState(w.key,d,s);
   if(st==='building')active.add('building');
   else if(st==='working')active.add('working');
 }
 if(Number(s?.active_workers?.supervisor||0)>0)active.add('working');
 if(active.size){
   const out=[];
   if(active.has('building'))out.push('building');
   if(active.has('working'))out.push('working');
   return out;
 }
 if(/THROTTLED|SATURATED|WAIT|COOL/i.test(s?.supervisor?.last_result||''))return ['cooldown'];
 return ['ready'];
}
function kevinState(d,s){return kevinStates(d,s)[0]}
'''
js=js[:start]+new_states+js[end:]

old_render=re.search(r"function renderKevinCenter\(d,s,state\)\{.*?\n\}",js,re.S)
if not old_render:
    raise SystemExit('renderKevinCenter not found')
new_render=r'''function renderKevinCenter(d,s,states){
 const sup=s?.supervisor||{},badge=document.getElementById('kevinState'),list=Array.isArray(states)?states:[states];
 badge.className='kevin-states';
 badge.innerHTML=list.map(st=>`<span class="loop state-${st}" style="--kstatec:${stateColor(st)}">${stateLabel(st)}</span>`).join('<span class="state-plus">+</span>');
 const mission=sup?.last_mission||'No mission selected',cycle=sup?.cycle??'—';
 document.getElementById('kevinMeta').innerHTML=`<div><b>Autonomy loop enabled</b> · cycle ${esc(cycle)}</div><div>${esc(mission)}${sup?.last_result?' · '+esc(sup.last_result):''}</div>`;
}'''
js=js[:old_render.start()]+new_render+js[old_render.end():]

# Fetch-failure badge becomes a proper badge inside the aggregate container.
js=once(js,"document.getElementById('kevinState').textContent='OFFLINE';document.getElementById('kevinState').style.setProperty('--kstatec',stateColor('offline'));return","document.getElementById('kevinState').innerHTML='<span class=\"loop state-offline\" style=\"--kstatec:#e46f61\">OFFLINE</span>';return",'offline badge fallback')

old_worker_loop="WORKERS.forEach((w,i)=>{const st=workerState(w.key,d,s),p=positions[i];if(['working','building'].includes(st))active.push(w);lineBetween(top,center,p,st);const el=document.createElement('div');el.className=`worker ${st}`;el.style.cssText=`left:${(p.x/top.clientWidth)*100}%;top:${(p.y/top.clientHeight)*100}%;--idc:${w.c};--statec:${stateColor(st)}`;el.innerHTML=`${owl(w.c)}<div class=\"box\"><b>${w.name}</b><small>${w.role}</small><span class=\"state\">${stateLabel(st)}</span></div>`;el.onclick=()=>selectWorker(w,st,d,s);top.appendChild(el)});"
new_worker_loop="WORKERS.forEach((w,i)=>{const st=workerState(w.key,d,s),p=positions[i];if(['working','building'].includes(st))active.push({w,st});lineBetween(top,center,p,st);const el=document.createElement('div');el.className=`worker ${st}`;el.style.cssText=`left:${(p.x/top.clientWidth)*100}%;top:${(p.y/top.clientHeight)*100}%;--idc:${w.c};--statec:${stateColor(st)}`;el.innerHTML=`<div class=\"box\">${owl(w.c,w.key)}<div class=\"worker-copy\"><b>${w.name}</b><small>${w.role}</small><span class=\"state\">${stateLabel(st)}</span></div></div>`;el.onclick=()=>selectWorker(w,st,d,s);top.appendChild(el)});"
js=once(js,old_worker_loop,new_worker_loop,'compact worker card render')

old_ks="const ks=kevinState(d,s),kmode=ks==='offline'?'disconnected':ks==='degraded'?'degraded':['working','building'].includes(ks)?'working':'ready';\n document.getElementById('headerKevinProd').innerHTML=kevinProd(kmode,true);document.getElementById('hubKevinProd').innerHTML=kevinProd(kmode,false);renderKevinCenter(d,s,ks);"
new_ks="const kstates=kevinStates(d,s),ks=kstates[0],kmode=ks==='offline'?'disconnected':ks==='degraded'?'degraded':kstates.some(x=>['working','building'].includes(x))?'working':'ready';\n document.getElementById('headerKevinProd').innerHTML=kevinProd(kmode,true);document.getElementById('hubKevinProd').innerHTML=kevinProd(kmode,false);renderKevinCenter(d,s,kstates);"
js=once(js,old_ks,new_ks,'aggregate Kevin state render')

old_strip="document.getElementById('mission').textContent=sup.last_mission?`${sup.last_mission} · cycle ${sup.cycle??'—'}`:'No active mission';\n document.getElementById('action').textContent=taskActive(d?.current_task)?(d.current_task.phase||d.current_task.title||stateLabel(ks)):(/THROTTLED|SATURATED/i.test(sup.last_result||'')?'Recovery cooldown':(sup.last_result||'Ready for work'));"
new_strip="const liveTask=taskActive(d?.current_task)?d.current_task:null;\n document.getElementById('mission').textContent=liveTask?(liveTask.title||liveTask.id||'Active task'):(sup.last_mission?`${sup.last_mission} · cycle ${sup.cycle??'—'}`:'No active mission');\n document.getElementById('action').textContent=liveTask?`${liveTask.phase||'active'} · ${kstates.map(stateLabel).join(' + ')}`:(/THROTTLED|SATURATED/i.test(sup.last_result||'')?'Recovery cooldown':(sup.last_result||'Ready for work'));"
js=once(js,old_strip,new_strip,'truthful live mission strip')

old_active="document.getElementById('activeWorkers').textContent=active.length?`${active.length} active`:'0 active · available lanes ready';document.getElementById('subagents').innerHTML=active.map(w=>owl(w.c).replace('class=\"owl\"','class=\"subowl\"')).join('');"
new_active="document.getElementById('activeWorkers').textContent=active.length?`${active.length} active · ${active.map(a=>a.w.name).join(', ')}`:'0 active · available lanes ready';document.getElementById('activeWorkers').title=active.map(a=>`${a.w.name}: ${stateLabel(a.st)}`).join(' · ');document.getElementById('subagents').innerHTML=active.map(a=>owl(a.w.c,a.w.key+'-sub').replace('class=\"owl\"',`class=\"subowl ${a.st}\"`)).join('');"
js=once(js,old_active,new_active,'valuable active worker summary')
old_sel="document.getElementById('selectedStatus').textContent=`${stateLabel(ks)} · cycle ${sup.cycle??'—'}`;document.getElementById('selectedDetail').textContent=`Kevin state. ${detail}`;"
new_sel="document.getElementById('selectedStatus').textContent=`${kstates.map(stateLabel).join(' + ')} · cycle ${sup.cycle??'—'}`;document.getElementById('selectedDetail').textContent=`Kevin aggregate state from live worker lanes. ${detail}`;"
js=once(js,old_sel,new_sel,'aggregate selected Kevin status')

# Ops CSS: same stencil wordmark, name above portrait, compact cards, active-fill owls, and distinct lane motion.
css=once(css,".title{font-family:Georgia,serif;font-size:36px;letter-spacing:-.03em}",".title{font-family:'Stencil Std','Stencil','Copperplate','Impact',sans-serif;font-size:34px;font-weight:700;letter-spacing:.07em;text-transform:uppercase}",'standalone stencil title')
old_hub_css=".hub{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:270px;height:270px;border-radius:50%;display:grid;place-items:center;text-align:center;border:1px solid rgba(240,183,78,.35);background:radial-gradient(circle,rgba(240,183,78,.10),rgba(13,18,13,.97) 66%);box-shadow:0 0 55px rgba(240,183,78,.08);z-index:5}.hub:before,.hub:after{content:\"\";position:absolute;border-radius:50%;border:1px dashed rgba(240,183,78,.18)}.hub:before{inset:-22px}.hub:after{inset:-44px}.hub h2{font-family:'Stencil Std','Stencil','Copperplate','Impact',sans-serif;font-size:30px;letter-spacing:.08em;margin:2px 0 0;text-transform:uppercase}.role{font-size:11px;color:#d7b56a;margin-top:2px}.loop{--kstatec:var(--ready);display:inline-flex;margin-top:8px;padding:6px 11px;border-radius:999px;border:1px solid color-mix(in srgb,var(--kstatec) 50%,transparent);color:var(--kstatec);background:color-mix(in srgb,var(--kstatec) 8%,transparent);font-size:10px;font-weight:800;letter-spacing:.11em;text-transform:uppercase;box-shadow:0 0 14px color-mix(in srgb,var(--kstatec) 13%,transparent)}.kevin-meta{width:218px;margin:9px auto 0;padding-top:8px;border-top:1px solid rgba(255,255,255,.08);font-size:9.5px;line-height:1.45;color:var(--muted)}.kevin-meta b{color:var(--fg);font-weight:650}"
new_hub_css=".hub{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:270px;height:270px;border-radius:50%;display:grid;place-items:center;text-align:center;border:1px solid rgba(240,183,78,.35);background:radial-gradient(circle,rgba(240,183,78,.10),rgba(13,18,13,.97) 66%);box-shadow:0 0 55px rgba(240,183,78,.08);z-index:5}.hub:before,.hub:after{content:\"\";position:absolute;border-radius:50%;border:1px dashed rgba(240,183,78,.18)}.hub:before{inset:-22px}.hub:after{inset:-44px}.hub-inner{position:relative;z-index:1;display:flex;flex-direction:column;align-items:center}.hub h2{font-family:'Stencil Std','Stencil','Copperplate','Impact',sans-serif;font-size:24px;letter-spacing:.09em;margin:0;text-transform:uppercase}.role{font-size:10.5px;color:#d7b56a;margin:1px 0 4px}.hub #hubKevinProd{margin-top:2px}.kevin-states{display:flex;align-items:center;justify-content:center;gap:5px;min-height:27px;margin-top:3px;flex-wrap:wrap}.state-plus{font-size:11px;color:var(--muted);font-weight:800}.loop{--kstatec:var(--ready);display:inline-flex;margin-top:0;padding:5px 9px;border-radius:999px;border:1px solid color-mix(in srgb,var(--kstatec) 50%,transparent);color:var(--kstatec);background:color-mix(in srgb,var(--kstatec) 8%,transparent);font-size:9.5px;font-weight:800;letter-spacing:.10em;text-transform:uppercase;box-shadow:0 0 14px color-mix(in srgb,var(--kstatec) 13%,transparent)}.kevin-meta{width:218px;margin:7px auto 0;padding-top:7px;border-top:1px solid rgba(255,255,255,.08);font-size:9.2px;line-height:1.4;color:var(--muted)}.kevin-meta b{color:var(--fg);font-weight:650}"
css=once(css,old_hub_css,new_hub_css,'hub composition')

old_worker_css=".worker{position:absolute;width:164px;text-align:center;transform:translate(-50%,-50%);z-index:3}.worker .owl{width:50px;height:56px;margin:0 auto 6px;filter:drop-shadow(0 0 9px color-mix(in srgb,var(--idc) 55%,transparent))}.worker .box{padding:8px 10px;border:1px solid color-mix(in srgb,var(--idc) 45%,transparent);border-radius:18px;background:rgba(12,18,12,.94);box-shadow:0 0 22px color-mix(in srgb,var(--idc) 10%,transparent)}.worker b{font-size:13px}.worker small{display:block;color:var(--muted);font-size:10px;margin-top:3px}.worker .state{display:inline-block;margin-top:5px;color:var(--statec);border-color:color-mix(in srgb,var(--statec) 45%,transparent);background:color-mix(in srgb,var(--statec) 7%,transparent);padding:4px 8px}.worker.ready .owl{animation:glow 3.2s ease-in-out infinite}.worker.working .owl,.worker.building .owl{animation:bob 1.2s ease-in-out infinite}.worker.offline{opacity:.55}.worker.degraded .owl{animation:shake 2.5s ease-in-out infinite}"
new_worker_css=".worker{position:absolute;width:150px;text-align:left;transform:translate(-50%,-50%);z-index:3}.worker .box{width:146px;min-height:72px;margin:auto;padding:7px 8px;display:flex;align-items:center;gap:8px;border:1px solid color-mix(in srgb,var(--idc) 45%,transparent);border-radius:13px;background:rgba(12,18,12,.94);box-shadow:0 0 20px color-mix(in srgb,var(--idc) 10%,transparent)}.worker .owl{width:50px;height:57px;flex:0 0 50px;margin:0;overflow:visible;filter:drop-shadow(0 0 9px color-mix(in srgb,var(--idc) 55%,transparent))}.worker-copy{min-width:0;flex:1}.worker b{display:block;font-size:12.5px;white-space:nowrap}.worker small{display:block;color:var(--muted);font-size:9px;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.worker .state{display:inline-block;margin-top:4px;color:var(--statec);border-color:color-mix(in srgb,var(--statec) 45%,transparent);background:color-mix(in srgb,var(--statec) 7%,transparent);padding:3px 6px;font-size:8.5px}.worker .owl-body{fill:transparent;stroke:var(--idc);transition:fill .22s ease,filter .22s ease}.worker .owl-feet{stroke:var(--idc)}.worker.working .owl-body,.worker.building .owl-body{fill:var(--idc)}.worker.working .owl,.worker.building .owl{animation:bob 1.2s ease-in-out infinite;filter:drop-shadow(0 0 12px color-mix(in srgb,var(--idc) 72%,transparent))}.worker.ready .owl{animation:glow 3.2s ease-in-out infinite}.worker.offline{opacity:.55}.worker.degraded .owl{animation:shake 2.5s ease-in-out infinite}.worker.degraded .owl-body{fill:color-mix(in srgb,var(--idc) 28%,transparent)}"
css=once(css,old_worker_css,new_worker_css,'compact owl worker cards')

old_line_css=".line{position:absolute;height:2px;background:linear-gradient(90deg,transparent,var(--statec),transparent);transform-origin:left center;opacity:.34;z-index:1;pointer-events:none}.line.active{opacity:.95;box-shadow:0 0 10px color-mix(in srgb,var(--statec) 42%,transparent);background:repeating-linear-gradient(90deg,var(--statec) 0 8px,transparent 8px 15px);background-size:30px 2px;animation:flow 1.2s linear infinite}.line.state-building.active{animation-duration:1.1s}.line.state-working.active{animation-duration:1.25s}"
new_line_css=".line{position:absolute;height:2px;background:linear-gradient(90deg,transparent,var(--statec),transparent);transform-origin:left center;opacity:.34;z-index:1;pointer-events:none}.line.active{opacity:.98;box-shadow:0 0 10px color-mix(in srgb,var(--statec) 42%,transparent)}.line.state-working.active{height:4px;background:repeating-linear-gradient(90deg,var(--statec) 0 11px,transparent 11px 18px);background-size:36px 4px;animation:flowWorking 1.15s linear infinite}.line.state-building.active{height:7px;background:radial-gradient(circle at 3.5px 3.5px,var(--statec) 0 3px,transparent 3.2px) 0 0/16px 7px repeat-x;animation:flowBuilding .95s linear infinite;filter:drop-shadow(0 0 5px color-mix(in srgb,var(--statec) 55%,transparent))}"
css=once(css,old_line_css,new_line_css,'distinct lane animations')
css=once(css,".subowl{width:20px;height:25px}",".subowl{width:22px;height:27px}.subowl.working .owl-body,.subowl.building .owl-body{fill:currentColor}",'active mini owl size')
css=css.replace("@keyframes flow{to{background-position:30px 0}}","@keyframes flowWorking{to{background-position:36px 0}}@keyframes flowBuilding{to{background-position:16px 0}}")
css=css.replace("@media(max-width:900px){.topology{min-height:820px}.worker{width:140px}","@media(max-width:900px){.topology{min-height:820px}.worker{width:138px}.worker .box{width:136px}.worker .owl{width:46px;height:53px;flex-basis:46px}")

# Contract checks before writing.
for stale in ['Idle</span>','Thinking</span>','Connecting</span>','Cooling</span>']:
    if stale in embed:
        raise SystemExit(f'stale state legend survived: {stale}')
for needed in ['WORKING = moving bars','BUILDING = moving dots','kevin-states','hub-inner']:
    if needed not in embed:
        raise SystemExit(f'embed invariant missing: {needed}')
for needed in ['function kevinStates','active.push({w,st})','owl-feet','owl-cut-','structured']:
    if needed == 'structured':
        continue
    if needed not in js:
        raise SystemExit(f'JS invariant missing: {needed}')
for needed in ['flowWorking','flowBuilding','radial-gradient(circle at 3.5px 3.5px','worker-copy','owl-body']:
    if needed not in css:
        raise SystemExit(f'CSS invariant missing: {needed}')
if "font-family:'Stencil Std','Stencil','Copperplate','Impact'" not in index:
    raise SystemExit('shared HQ stencil font missing')
if 'ops/embed.html?v=14' not in index:
    raise SystemExit('Ops iframe cache bump missing')

embed_p.write_text(embed,encoding='utf-8')
js_p.write_text(js,encoding='utf-8')
css_p.write_text(css,encoding='utf-8')
index_p.write_text(index,encoding='utf-8')
print('PATCH_OPS_V14_OK')
