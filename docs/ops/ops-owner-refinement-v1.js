(()=>{
'use strict';
const READY='#244f8f',ARMED='#68d8ce';
const COLORS={READY,ARMED,WORKING:'#79c56a',BUILDING:'#f06dbb',COOLDOWN:'#b38cff',DEGRADED:'#ff9a3d',OFFLINE:'#e46f61'};
const DEFS=[
 ['READY',READY,'Available and healthy; no active job right now.'],
 ['ARMED',ARMED,'Autonomy is enabled; waiting between governed work cycles.'],
 ['WORKING',COLORS.WORKING,'A real task is executing now.'],
 ['BUILDING',COLORS.BUILDING,'Build Lab / Forge is creating or testing a candidate.'],
 ['COOLDOWN',COLORS.COOLDOWN,'Bounded pause after throttling, retry, or recovery.'],
 ['DEGRADED',COLORS.DEGRADED,'Still online, but a health or evidence issue needs attention.'],
 ['OFFLINE',COLORS.OFFLINE,'Telemetry is stale or the component is unreachable.']
];
function svgEl(name,attrs={}){const e=document.createElementNS('http://www.w3.org/2000/svg',name);for(const [k,v] of Object.entries(attrs))e.setAttribute(k,String(v));return e}
function refineOwl(worker){
 const svg=worker.querySelector('svg.owl');if(!svg||svg.dataset.ownerRefined==='1')return;svg.dataset.ownerRefined='1';
 const oldFeet=svg.querySelector('.owl-feet');if(oldFeet)oldFeet.remove();
 const mask=svg.querySelector('mask');if(mask&&!mask.querySelector('.owl-beak-cutout'))mask.appendChild(svgEl('path',{class:'owl-beak-cutout',d:'M53 61 L67 61 L60 71 Z',fill:'black'}));
 const eyes=svgEl('g',{class:'owl-eyes'});[[46,49],[74,49]].forEach(([x,y])=>{eyes.appendChild(svgEl('circle',{class:'owl-eye-white',cx:x,cy:y,r:12.5}));eyes.appendChild(svgEl('circle',{class:'owl-eye',cx:x,cy:y+1,r:5.8}));eyes.appendChild(svgEl('circle',{class:'owl-eye-hi',cx:x-2.2,cy:y-2,r:1.8}))});svg.appendChild(eyes);
 svg.appendChild(svgEl('path',{class:'owl-beak',d:'M53 61 L67 61 L60 71 Z'}));
 const feet=svgEl('g',{class:'owl-feet-kevin'});feet.appendChild(svgEl('ellipse',{cx:47,cy:106,rx:8.5,ry:4.5}));feet.appendChild(svgEl('ellipse',{cx:73,cy:106,rx:8.5,ry:4.5}));[[41,108.5],[53,108.5],[67,108.5],[79,108.5]].forEach(([x,y])=>feet.appendChild(svgEl('circle',{cx:x,cy:y,r:2.35})));svg.appendChild(feet)
}
function guide(){const section=document.querySelector('.topology')?.closest('section.card');if(!section)return;const legacy=section.querySelector('.legend');if(legacy)legacy.classList.add('owner-compact');let g=section.querySelector('.owner-status-guide');if(g)return;g=document.createElement('div');g.className='owner-status-guide';g.setAttribute('aria-label','Kevin status definitions');g.innerHTML=DEFS.map(([n,c,d])=>`<div class="owner-status-item"><i style="background:${c};color:${c}"></i><b>${n}</b><span>${d}</span></div>`).join('');(legacy||section).insertAdjacentElement(legacy?'afterend':'beforeend',g)}
function refine(){document.querySelectorAll('.worker-progress').forEach(x=>x.remove());document.querySelectorAll('.worker').forEach(w=>{refineOwl(w);if(w.classList.contains('ready'))w.style.setProperty('--statec',READY)});document.querySelectorAll('.line.state-ready').forEach(x=>x.style.setProperty('--statec',READY));guide()}
addEventListener('load',()=>{refine();setTimeout(refine,250);setTimeout(refine,900)});const topology=document.getElementById('topology');if(topology&&'MutationObserver'in window)new MutationObserver(refine).observe(topology,{childList:true,subtree:true});setInterval(refine,700);
})();
