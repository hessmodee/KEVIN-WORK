(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
let doc=null,lastGaze={x:0,y:0};
function install(){doc=frame.contentDocument;if(!doc)return;let st=doc.getElementById('ownerFunV2Style');if(!st){st=doc.createElement('style');st.id='ownerFunV2Style';st.textContent=`
.service-chip.owner-active{border-color:rgba(255,209,102,.42)!important;background:rgba(255,209,102,.08)!important}.service-chip.owner-active .led{background:#ffd166!important;box-shadow:0 0 12px rgba(255,209,102,.5)!important}.service-chip.owner-active span{color:#ffe39a!important}.st.owner-active{color:#ffe39a!important;background:rgba(255,209,102,.14)!important}
#headerKevin .kevin-avatar.owner-header-victory{transform-origin:50% 82%;animation:ownerHeaderVictory 1.55s cubic-bezier(.22,.8,.28,1) 1!important}
@keyframes ownerHeaderVictory{0%{transform:translateY(0) rotate(0) scale(1)}18%{transform:translateY(-7px) rotate(-7deg) scale(1.03)}45%{transform:translateY(-12px) rotate(185deg) scale(1.05)}72%{transform:translateY(-6px) rotate(360deg) scale(1.02)}88%{transform:translateY(1px) rotate(367deg) scale(.99)}100%{transform:translateY(0) rotate(360deg) scale(1)}}
`;doc.head.appendChild(st)}markActive();applyGaze(lastGaze.x,lastGaze.y)}
function markActive(){if(!doc)return;doc.querySelectorAll('.service-chip').forEach(c=>c.classList.toggle('owner-active',c.querySelector('span')?.textContent?.trim().toUpperCase()==='ACTIVE'));doc.querySelectorAll('.st').forEach(c=>c.classList.toggle('owner-active',c.textContent.trim().toUpperCase()==='ACTIVE'))}
function applyGaze(x,y){lastGaze={x:Number(x)||0,y:Number(y)||0};if(!doc)return;doc.querySelectorAll('#headerKevin .kv-eye,#headerKevin .kv-hi').forEach(e=>e.style.transform=`translate(${lastGaze.x.toFixed(2)}px,${lastGaze.y.toFixed(2)}px)`)}
function celebrate(ms=1700){if(!doc)return;const a=doc.querySelector('#headerKevin .kevin-avatar');if(!a)return;a.classList.remove('owner-header-victory');void a.offsetWidth;a.classList.add('owner-header-victory');setTimeout(()=>a.classList.remove('owner-header-victory'),Number(ms)||1700)}
window.addEventListener('message',e=>{if(e.origin!==location.origin)return;if(e.data?.type==='kevin-ops-gaze')applyGaze(e.data.x,e.data.y);if(e.data?.type==='kevin-ops-celebrate')celebrate(e.data.duration)});
frame.addEventListener('load',()=>{install();setTimeout(install,250);setTimeout(install,900)});setInterval(()=>{if(frame.contentDocument!==doc)install();else{markActive();applyGaze(lastGaze.x,lastGaze.y)}},700);
})();
