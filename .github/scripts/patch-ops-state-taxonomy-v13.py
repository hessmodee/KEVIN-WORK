from pathlib import Path

js_path = Path('docs/ops/ops-v11.js')
css_path = Path('docs/ops/ops-v11.css')
embed_path = Path('docs/ops/embed.html')

js = js_path.read_text(encoding='utf-8')
css = css_path.read_text(encoding='utf-8')
embed = embed_path.read_text(encoding='utf-8')

def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly 1 match, found {count}')
    return text.replace(old, new, 1)

# JS: collapse visual state vocabulary to evidence-backed states only.
js = replace_once(js,
"const STATE_COLORS={\n idle:'#4f7dff',\n ready:'#68d8ce',\n working:'#79c56a',\n thinking:'#f0c44f',\n cooling:'#b38cff',\n connecting:'#35c7e8',\n building:'#f06dbb',\n degraded:'#ff9a3d',\n offline:'#e46f61'\n};",
"const STATE_COLORS={\n ready:'#68d8ce',\n working:'#79c56a',\n building:'#f06dbb',\n cooldown:'#b38cff',\n degraded:'#ff9a3d',\n offline:'#e46f61'\n};",
'STATE_COLORS')
js = replace_once(js,
"function stateColor(st){return STATE_COLORS[st]||STATE_COLORS.idle}\nfunction stateLabel(st){return ({idle:'IDLE',ready:'READY',thinking:'THINKING',working:'WORKING',building:'BUILDING',connecting:'CONNECTING',cooling:'COOLING',degraded:'DEGRADED',offline:'OFFLINE'})[st]||String(st||'').toUpperCase()}",
"function stateColor(st){return STATE_COLORS[st]||STATE_COLORS.degraded}\nfunction stateLabel(st){return ({ready:'READY',working:'WORKING',building:'BUILDING',cooldown:'COOLDOWN',degraded:'DEGRADED',offline:'OFFLINE'})[st]||String(st||'').toUpperCase()}",
'state helpers')
js = replace_once(js, "function kevinProd(mode='idle',small=false)", "function kevinProd(mode='ready',small=false)", 'Kevin default mode')
js = replace_once(js, "return recentlyRan(cronJob(s,'kevin-support-bridge-v1'),45000)?'connecting':'ready';", "return recentlyRan(cronJob(s,'kevin-support-bridge-v1'),45000)?'working':'ready';", 'Bridge state')
js = replace_once(js, "if(taskActive(t)&&/chat|reasoning|analysis|planning|conversation/.test(tt))return 'thinking';", "if(taskActive(t)&&/chat|reasoning|analysis|planning|conversation/.test(tt))return 'working';", 'Chat state')
js = replace_once(js, " return 'idle';\n}\n\nfunction kevinState", " return 'ready';\n}\n\nfunction kevinState", 'worker fallback')
js = replace_once(js,
" if(taskActive(t)){\n   if(/design forge|forge|build|builder|create|compile/.test(tt))return 'building';\n   if(/analysis|planning|reasoning|evaluate|evaluation|research|think/.test(tt))return 'thinking';\n   return 'working';\n }",
" if(taskActive(t)){\n   if(/design forge|forge|build|builder|create|compile/.test(tt))return 'building';\n   return 'working';\n }",
'Kevin active classification')
js = replace_once(js, " if((bw?.supervisor||0)>0)return 'thinking';", " if((bw?.supervisor||0)>0)return 'working';", 'Supervisor active state')
js = replace_once(js, " if(/THROTTLED|SATURATED|WAIT|COOL/i.test(s?.supervisor?.last_result||''))return 'cooling';", " if(/THROTTLED|SATURATED|WAIT|COOL/i.test(s?.supervisor?.last_result||''))return 'cooldown';", 'Cooldown state')
js = replace_once(js, " const active=['thinking','working','building','connecting'].includes(state),el=document.createElement('div');", " const active=['working','building'].includes(state),el=document.createElement('div');", 'Active line states')
js = replace_once(js, "const detail=/THROTTLED|SATURATED/i.test(sup.last_result||'')?'Autonomy engine is cooling after bounded recovery attempts.'", "const detail=/THROTTLED|SATURATED/i.test(sup.last_result||'')?'Recovery cooldown is active after bounded recovery attempts.'", 'Cooldown wording')
js = replace_once(js,
"[['Reader','ready'],['Night Forge',(s?.active_workers?.night_forge||0)>0?'active':'ready'],['Build Lab',(s?.active_workers?.design_forge||0)>0?'active':'ready'],['Ollama',d?.services?.ollama==='healthy'?'ready':''],['Bridge',workerState('bridge',d,s)==='connecting'?'sync':(d?.services?.bridge==='healthy'?'ready':'')],['Tick',d?.services?.tick==='healthy'?'ready':'']].forEach(([n,st])=>rail.insertAdjacentHTML('beforeend',`<div class=\"svc\"><i class=\"dot ${st}\"></i><b>${esc(n)}</b><span>${st==='active'?'ACTIVE':st==='sync'?'SYNC':st==='ready'?'READY':'CHECK'}</span></div>`));",
"[['Reader','ready'],['Night Forge',(s?.active_workers?.night_forge||0)>0?'active':'ready'],['Build Lab',(s?.active_workers?.design_forge||0)>0?'active':'ready'],['Ollama',d?.services?.ollama==='healthy'?'ready':''],['Bridge',workerState('bridge',d,s)==='working'?'active':(d?.services?.bridge==='healthy'?'ready':'')],['Tick',d?.services?.tick==='healthy'?'ready':'']].forEach(([n,st])=>rail.insertAdjacentHTML('beforeend',`<div class=\"svc\"><i class=\"dot ${st}\"></i><b>${esc(n)}</b><span>${st==='active'?'ACTIVE':st==='ready'?'READY':'CHECK'}</span></div>`));",
'Service rail Bridge')
js = replace_once(js, "if(['thinking','working','building','connecting'].includes(st))active.push(w);", "if(['working','building'].includes(st))active.push(w);", 'Active worker count')
js = replace_once(js, "const ks=kevinState(d,s),kmode=ks==='offline'?'disconnected':ks==='degraded'?'degraded':['working','building','thinking'].includes(ks)?'working':'idle';", "const ks=kevinState(d,s),kmode=ks==='offline'?'disconnected':ks==='degraded'?'degraded':['working','building'].includes(ks)?'working':'ready';", 'Kevin avatar mode')
js = replace_once(js, "if(w.key==='bridge')detail=`GitHub sync service: ${d?.services?.bridge||'unknown'}. CONNECTING is shown only around a recent Bridge run; otherwise a healthy Bridge is READY.`;", "if(w.key==='bridge')detail=`GitHub sync service: ${d?.services?.bridge||'unknown'}. A recent Bridge run is WORKING; otherwise a healthy Bridge is READY.`;", 'Bridge detail')
js = replace_once(js, "document.getElementById('headerKevinProd').innerHTML=kevinProd('idle',true);document.getElementById('hubKevinProd').innerHTML=kevinProd('idle',false);", "document.getElementById('headerKevinProd').innerHTML=kevinProd('ready',true);document.getElementById('hubKevinProd').innerHTML=kevinProd('ready',false);", 'Initial Kevin mode')

# CSS: remove dead/redundant status keys and animations; preserve identity colors.
css = replace_once(css,
" --idle:#4f7dff;--ready:#68d8ce;--working:#79c56a;--thinking:#f0c44f;--cooling:#b38cff;--connecting:#35c7e8;--building:#f06dbb;--degraded:#ff9a3d;--offline:#e46f61;",
" --ready:#68d8ce;--working:#79c56a;--building:#f06dbb;--cooldown:#b38cff;--degraded:#ff9a3d;--offline:#e46f61;",
'CSS state colors')
css = replace_once(css,
".dot{width:8px;height:8px;border-radius:50%;background:var(--idle)}.dot.ready{background:var(--ready);box-shadow:0 0 12px color-mix(in srgb,var(--ready) 55%,transparent)}.dot.active{background:var(--working);box-shadow:0 0 12px color-mix(in srgb,var(--working) 55%,transparent)}.dot.sync{background:var(--connecting);box-shadow:0 0 12px color-mix(in srgb,var(--connecting) 55%,transparent)}",
".dot{width:8px;height:8px;border-radius:50%;background:rgba(146,155,144,.55)}.dot.ready{background:var(--ready);box-shadow:0 0 12px color-mix(in srgb,var(--ready) 55%,transparent)}.dot.active{background:var(--working);box-shadow:0 0 12px color-mix(in srgb,var(--working) 55%,transparent)}",
'CSS service dots')
css = replace_once(css,
".worker.ready .owl{animation:glow 3.2s ease-in-out infinite}.worker.thinking .owl{animation:think 1.5s ease-in-out infinite}.worker.working .owl,.worker.building .owl{animation:bob 1.2s ease-in-out infinite}.worker.connecting .owl{animation:signal 1.15s ease-in-out infinite}.worker.cooling .owl{opacity:.68;animation:cool 3s ease-in-out infinite}.worker.offline{opacity:.55}.worker.degraded .owl{animation:shake 2.5s ease-in-out infinite}",
".worker.ready .owl{animation:glow 3.2s ease-in-out infinite}.worker.working .owl,.worker.building .owl{animation:bob 1.2s ease-in-out infinite}.worker.offline{opacity:.55}.worker.degraded .owl{animation:shake 2.5s ease-in-out infinite}",
'CSS worker animations')
css = replace_once(css,
".line{position:absolute;height:2px;background:linear-gradient(90deg,transparent,var(--statec),transparent);transform-origin:left center;opacity:.34;z-index:1;pointer-events:none}.line.active{opacity:.95;box-shadow:0 0 10px color-mix(in srgb,var(--statec) 42%,transparent);background:repeating-linear-gradient(90deg,var(--statec) 0 8px,transparent 8px 15px);background-size:30px 2px;animation:flow 1.2s linear infinite}.line.state-connecting.active{animation-duration:.95s}.line.state-building.active{animation-duration:1.1s}.line.state-working.active{animation-duration:1.25s}.line.state-thinking.active{animation-duration:1.45s}",
".line{position:absolute;height:2px;background:linear-gradient(90deg,transparent,var(--statec),transparent);transform-origin:left center;opacity:.34;z-index:1;pointer-events:none}.line.active{opacity:.95;box-shadow:0 0 10px color-mix(in srgb,var(--statec) 42%,transparent);background:repeating-linear-gradient(90deg,var(--statec) 0 8px,transparent 8px 15px);background-size:30px 2px;animation:flow 1.2s linear infinite}.line.state-building.active{animation-duration:1.1s}.line.state-working.active{animation-duration:1.25s}",
'CSS active lanes')
css = replace_once(css, ".kevin-avatar-prod.mode-idle .kv-eyes", ".kevin-avatar-prod.mode-ready .kv-eyes", 'Ready blink')
css = replace_once(css,
"@keyframes kvBlink{0%,91%,94%,100%{transform:scaleY(1)}92.5%{transform:scaleY(.08)}}@keyframes bob{0%,100%{transform:translateY(0)}50%{transform:translateY(-5px)}}@keyframes think{0%,100%{transform:translateY(0) rotate(-1deg)}50%{transform:translateY(-3px) rotate(2deg)}}@keyframes signal{0%,100%{filter:drop-shadow(0 0 4px var(--idc))}50%{filter:drop-shadow(0 0 16px var(--idc));transform:scale(1.04)}}@keyframes glow{0%,100%{filter:drop-shadow(0 0 4px var(--idc))}50%{filter:drop-shadow(0 0 11px var(--idc))}}@keyframes cool{0%,100%{opacity:.55}50%{opacity:.82}}@keyframes shake{0%,93%,100%{transform:translateX(0)}95%{transform:translateX(-2px)}97%{transform:translateX(2px)}}@keyframes flow{to{background-position:30px 0}}@keyframes pulseLine{0%,100%{opacity:.55}50%{opacity:1;box-shadow:0 0 14px color-mix(in srgb,var(--statec) 55%,transparent)}}",
"@keyframes kvBlink{0%,91%,94%,100%{transform:scaleY(1)}92.5%{transform:scaleY(.08)}}@keyframes bob{0%,100%{transform:translateY(0)}50%{transform:translateY(-5px)}}@keyframes glow{0%,100%{filter:drop-shadow(0 0 4px var(--idc))}50%{filter:drop-shadow(0 0 11px var(--idc))}}@keyframes shake{0%,93%,100%{transform:translateX(0)}95%{transform:translateX(-2px)}97%{transform:translateX(2px)}}@keyframes flow{to{background-position:30px 0}}",
'CSS keyframes cleanup')

# Embedded legend + cache keys.
embed = replace_once(embed, './ops-v11.css?v=12', './ops-v11.css?v=13', 'CSS cache key')
embed = replace_once(embed, './ops-v11.js?v=11', './ops-v11.js?v=13', 'JS cache key')
old_legend = '<div class="legend"><span><i style="background:#4f7dff"></i>Idle</span><span><i style="background:#68d8ce"></i>Ready</span><span><i style="background:#79c56a"></i>Working</span><span><i style="background:#f0c44f"></i>Thinking</span><span><i style="background:#b38cff"></i>Cooling</span><span><i style="background:#35c7e8"></i>Connecting</span><span><i style="background:#f06dbb"></i>Building</span><span><i style="background:#ff9a3d"></i>Degraded</span><span><i style="background:#e46f61"></i>Offline</span><span class="note">Owl outline = worker identity Â· lane + status = live state</span></div>'
new_legend = '<div class="legend"><span><i style="background:#68d8ce"></i>Ready</span><span><i style="background:#79c56a"></i>Working</span><span><i style="background:#f06dbb"></i>Building</span><span><i style="background:#b38cff"></i>Cooldown</span><span><i style="background:#ff9a3d"></i>Degraded</span><span><i style="background:#e46f61"></i>Offline</span><span class="note">Active lanes flow · Ready lanes stay quiet · status colors are evidence-backed</span></div>'
embed = replace_once(embed, old_legend, new_legend, 'Legend')

js_path.write_text(js, encoding='utf-8')
css_path.write_text(css, encoding='utf-8')
embed_path.write_text(embed, encoding='utf-8')

# Contract checks: the Ops visual state machine is exactly six evidence-backed states.
for token in ["idle:'#4f7dff'", "thinking:'#f0c44f'", "connecting:'#35c7e8'", "cooling:'#b38cff'"]:
    if token in js or token in css:
        raise SystemExit(f'removed state/color still present: {token}')
for token in ['#4f7dff', '#f0c44f', '#35c7e8']:
    if token in css or token in embed:
        raise SystemExit(f'removed palette color still present: {token}')
for label in ['>Idle</span>', '>Thinking</span>', '>Connecting</span>', '>Cooling</span>']:
    if label in embed:
        raise SystemExit(f'removed legend state still present: {label}')
for required in ["ready:'#68d8ce'", "working:'#79c56a'", "building:'#f06dbb'", "cooldown:'#b38cff'", "degraded:'#ff9a3d'", "offline:'#e46f61'", "return recentlyRan(cronJob(s,'kevin-support-bridge-v1'),45000)?'working':'ready';", "if((bw?.supervisor||0)>0)return 'working';", "return 'cooldown';", "const active=['working','building'].includes(state)"]:
    if required not in js:
        raise SystemExit(f'missing JS contract: {required}')
for required in ['>Ready</span>', '>Working</span>', '>Building</span>', '>Cooldown</span>', '>Degraded</span>', '>Offline</span>']:
    if required not in embed:
        raise SystemExit(f'missing legend contract: {required}')
print('PASS Ops state taxonomy v13: READY WORKING BUILDING COOLDOWN DEGRADED OFFLINE')
