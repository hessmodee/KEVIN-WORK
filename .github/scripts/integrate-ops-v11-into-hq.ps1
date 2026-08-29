$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
$utf8=New-Object System.Text.UTF8Encoding($false)

$index='docs/index.html'
$opsIndex='docs/ops/index.html'
$embed='docs/ops/embed.html'
$expectedIndex='1f2dd9af9a61086db8a8d0b52458c45520671982'
$expectedOps='1ebcb88292601e0eddc26f6dd98fec44c6e7caaf'

function Assert-Blob([string]$Path,[string]$Expected){
  $actual=(& git hash-object -- $Path).Trim()
  if($actual -cne $Expected){throw "Unexpected preimage for ${Path}: expected $Expected got $actual"}
  Write-Host "PASS preimage $Path $actual"
}
function Replace-Once([string]$Text,[string]$Old,[string]$New,[string]$Label){
  $count=([regex]::Matches($Text,[regex]::Escape($Old))).Count
  if($count -ne 1){throw "${Label} replacement count=$count"}
  return $Text.Replace($Old,$New)
}

Assert-Blob $index $expectedIndex
Assert-Blob $opsIndex $expectedOps
if(Test-Path -LiteralPath $embed){throw 'docs/ops/embed.html already exists; refusing non-idempotent integration patch'}

$text=[IO.File]::ReadAllText($index) -replace "`r`n","`n"

$css=@'
    .ops-v11-frame-shell{width:100%;min-width:0}
    .ops-v11-frame{display:block;width:100%;height:1160px;border:0;background:transparent;border-radius:18px;overflow:hidden}
    @media(max-width:900px){.ops-v11-frame{height:1500px}}
'@
$text=Replace-Once $text '  </style>' ($css+"`n  </style>") 'Ops iframe CSS'
$text=Replace-Once $text 'if(tab==="ops"){location.replace("./ops/");}' '' 'startup ops redirect'

$oldNav='function renderNav(){$("nav").innerHTML=TABS.map(([id,label])=>`<button class="navbtn ${tab===id?"on":""}" data-tab="${id}">${label}</button>`).join("");$("nav").onclick=e=>{const b=e.target.closest("[data-tab]");if(!b)return;if(b.dataset.tab==="ops"){location.href="./ops/";return;}tab=b.dataset.tab;location.hash=tab;renderNav();draw()}}'
$newNav='function renderNav(){$("nav").innerHTML=TABS.map(([id,label])=>`<button class="navbtn ${tab===id?"on":""}" data-tab="${id}">${label}</button>`).join("");$("nav").onclick=e=>{const b=e.target.closest("[data-tab]");if(!b)return;tab=b.dataset.tab;location.hash=tab;renderNav();draw()}}'
$text=Replace-Once $text $oldNav $newNav 'unified nav routing'

$opsPattern='(?s)function ops\(\)\{.*?\n\}\nfunction renderInspect\(\)\{'
$opsMatches=[regex]::Matches($text,$opsPattern)
if($opsMatches.Count -ne 1){throw "Ops function replacement count=$($opsMatches.Count)"}
$newOps=@'
function ops(){
 return`<div class="ops-v11-frame-shell"><iframe id="opsV11Frame" class="ops-v11-frame" title="Kevin HQ Operations Floor" src="./ops/embed.html?v=12" loading="eager"></iframe></div>`
}
function renderInspect(){
'@
$text=[regex]::Replace($text,$opsPattern,[System.Text.RegularExpressions.MatchEvaluator]{param($m)$newOps},1)

$oldDraw='function draw(){if(!S)return;applyChrome();if(tab==="overview")$("main").innerHTML=overview();if(tab==="ops")$("main").innerHTML=ops();if(tab==="talk")$("main").innerHTML=talk();if(tab==="activity")$("main").innerHTML=activity();if(tab==="system")$("main").innerHTML=system();if(tab==="build")$("main").innerHTML=roadmap();if(tab==="capabilities")$("main").innerHTML=capabilities();if(tab==="diagnostics")$("main").innerHTML=diagnostics();if(tab==="overview"||tab==="system")drawChart();if(tab==="ops"){renderInspect();$("opsMap").onclick=e=>{const b=e.target.closest("[data-id]");if(!b)return;selectedCrew=b.dataset.id;renderInspect()}}if(tab==="activity")$("main").onclick=e=>{const b=e.target.closest("[data-filter]");if(!b)return;activityFilter=b.dataset.filter;draw()}}'
$newDraw='function draw(){if(!S)return;applyChrome();if(tab==="overview")$("main").innerHTML=overview();if(tab==="ops")$("main").innerHTML=ops();if(tab==="talk")$("main").innerHTML=talk();if(tab==="activity")$("main").innerHTML=activity();if(tab==="system")$("main").innerHTML=system();if(tab==="build")$("main").innerHTML=roadmap();if(tab==="capabilities")$("main").innerHTML=capabilities();if(tab==="diagnostics")$("main").innerHTML=diagnostics();if(tab==="overview"||tab==="system")drawChart();if(tab==="activity")$("main").onclick=e=>{const b=e.target.closest("[data-filter]");if(!b)return;activityFilter=b.dataset.filter;draw()}}'
$text=Replace-Once $text $oldDraw $newDraw 'draw ops parent hooks'

$oldBoot='load();setInterval(load,15000);'
$newBoot=@'
addEventListener("message",e=>{
 if(e.origin!==location.origin||e.data?.type!=="kevin-ops-height")return;
 const frame=$("opsV11Frame"),h=Number(e.data.height||0);
 if(frame&&Number.isFinite(h)&&h>400&&h<3000)frame.style.height=Math.ceil(h)+"px";
});
addEventListener("hashchange",()=>{
 const next=(location.hash||"#overview").slice(1);
 if(!TABS.some(x=>x[0]===next)||next===tab)return;
 tab=next;renderNav();draw();
});
load();setInterval(load,15000);
'@
$text=Replace-Once $text $oldBoot $newBoot 'ops frame messaging and hash routing'

[IO.File]::WriteAllText($index,$text,$utf8)

$embedHtml=@'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta content="width=device-width,initial-scale=1" name="viewport"/>
<meta content="dark" name="color-scheme"/>
<title>Kevin HQ — Ops Floor embedded</title>
<link href="./ops-v11.css?v=11" rel="stylesheet"/>
<style>
html,body{background:transparent!important}
body{padding:0!important;background:none!important}
.wrap{max-width:none!important;margin:0!important}
.top,.news,.rail,.nav,.foot{display:none!important}
.card:first-of-type{margin-top:0}
</style>
</head>
<body>
<div class="wrap">
<div class="top">
<div class="brand"><div id="headerKevinProd"></div><div><div class="title">Kevin HQ</div><div class="subtitle">Chief of Staff · telemetry-backed Ops Floor v11</div></div></div>
<div class="chips"><span class="chip">HQ v11 · production</span><span class="chip ok" id="overallChip">LIVE</span></div>
</div>
<div class="news"><b>NEWSWIRE</b><span id="newsText">Loading Kevin telemetry…</span></div>
<div class="rail" id="serviceRail"></div>
<div class="nav"></div>
<section class="card">
<div class="ops-head"><div><div class="kicker">Operations Floor</div><div class="helper">Real topology · motion is telemetry-driven, never decorative busy-work</div></div><div class="helper">Kevin is the Chief of Staff · center badge = Kevin's current state</div></div>
<div class="topology" id="topology"><div class="gridline"></div>
<div class="hub" id="kevinHub"><div><div id="hubKevinProd"></div><h2>Kevin</h2><div class="role">Chief of Staff</div><div class="loop" id="kevinState">READY</div><div class="kevin-meta" id="kevinMeta"><div><b>Autonomy loop enabled</b></div><div>Waiting for telemetry…</div></div></div></div>
</div>
<div class="legend"><span><i style="background:#4f7dff"></i>Idle</span><span><i style="background:#68d8ce"></i>Ready</span><span><i style="background:#79c56a"></i>Working</span><span><i style="background:#f0c44f"></i>Thinking</span><span><i style="background:#b38cff"></i>Cooling</span><span><i style="background:#35c7e8"></i>Connecting</span><span><i style="background:#f06dbb"></i>Building</span><span><i style="background:#ff9a3d"></i>Degraded</span><span><i style="background:#e46f61"></i>Offline</span><span class="note">Owl outline = worker identity · lane + status = live state</span></div>
</section>
<div class="strip">
<div><div class="lbl">Active mission</div><div class="val" id="mission">—</div></div>
<div><div class="lbl">Current action</div><div class="val" id="action">—</div></div>
<div><div class="lbl">Recent event</div><div class="val" id="recent">—</div></div>
<div><div class="lbl">Evidence</div><div class="val" id="evidence">—</div></div>
<div><div class="lbl">Active workers</div><div class="val" id="activeWorkers">—</div><div class="subagents" id="subagents"></div></div>
</div>
<section class="card detail">
<div class="kicker">Selected worker</div><h3 id="selectedName">Kevin — Chief of Staff</h3>
<div class="detail-grid">
<div class="metric"><div class="kicker">Status</div><div class="big" id="selectedStatus">Loading…</div><div class="small" id="selectedDetail">Waiting for telemetry.</div></div>
<div class="metric"><div class="kicker">System load</div><div class="big" id="load">—</div><div class="small" id="loadDetail">—</div></div>
<div class="metric"><div class="kicker">Evidence age</div><div class="big" id="age">—</div><div class="small" id="benchmark">—</div></div>
</div>
</section>
<div class="foot"><span id="updated">Kevin HQ v11 · production</span><span>Internal Supervisor remains an implementation detail, not a separate coworker</span></div>
</div>
<script src="./ops-v11.js?v=11"></script>
<script>
(()=>{
 const send=()=>{try{parent.postMessage({type:'kevin-ops-height',height:Math.ceil(document.documentElement.scrollHeight)},location.origin)}catch(_e){}};
 addEventListener('load',()=>{send();setTimeout(send,100);setTimeout(send,700)});
 if('ResizeObserver'in window)new ResizeObserver(send).observe(document.body);
})();
</script>
</body>
</html>
'@
[IO.File]::WriteAllText($embed,$embedHtml,$utf8)

$redirect=@'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Kevin HQ — Ops Floor</title><meta http-equiv="refresh" content="0;url=../#ops"/></head><body><script>location.replace('../#ops')</script><noscript><a href="../#ops">Open Kevin HQ Ops Floor</a></noscript></body></html>
'@
[IO.File]::WriteAllText($opsIndex,$redirect,$utf8)

Write-Host 'PASS integrated Ops Floor v11 into shared Kevin HQ shell.'
