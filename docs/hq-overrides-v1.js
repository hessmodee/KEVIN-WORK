(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
if(!frame)return;
let core=null,doc=null,nwItems=[],nwIndex=0,nwTimer=null,nwRefreshTimer=null;
function esc(s){return String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
function normalizeStoryText(value){
  let text=String(value||'').replace(/\s+/g,' ').trim();
  const marker=' — ',i=text.lastIndexOf(marker);if(i<=0)return text;
  const source=text.slice(i+marker.length).trim();let before=text.slice(0,i).trim();if(!source)return text;
  for(const sep of [' - ',' — ',' | ',' · ']){const suffix=(sep+source).toLowerCase();if(before.toLowerCase().endsWith(suffix)){before=before.slice(0,before.length-suffix.length).trim();break}}
  return`${before}${marker}${source}`;
}
function signature(items){return items.map(x=>`${x.id||''}|${x.text||''}|${x.severity||''}`).join('\n')}
function paint(){
  const el=doc?.getElementById('hqNewswire');if(!el||!nwItems.length)return;
  const nodes=[...el.querySelectorAll('.nw-item')];if(!nodes.length)return;
  const i=((nwIndex%nodes.length)+nodes.length)%nodes.length;
  nodes.forEach((n,idx)=>n.classList.toggle('on',idx===i));
  const sev=(nodes[i]?.dataset?.sev||'normal').toLowerCase();
  el.className='newswire show'+(sev&&sev!=='normal'?' sev-'+sev:'');
}
function refreshNewswire(){
  if(!core||!doc||typeof core.newswireStories!=='function')return;
  let items=[];try{items=(core.newswireStories()||[]).map(x=>({...x,text:normalizeStoryText(x.text)})).filter(x=>x.text)}catch(_e){return}
  const seen=new Set();items=items.filter(x=>{const k=String(x.text).toLowerCase().replace(/\W+/g,'').slice(0,180);if(!k||seen.has(k))return false;seen.add(k);return true}).slice(0,18);
  if(!items.length)return;
  const currentId=nwItems[nwIndex]?.id,oldSig=signature(nwItems),newSig=signature(items);nwItems=items;
  let el=doc.getElementById('hqNewswire');
  if(!el){doc.getElementById('newswire')?.remove();el=doc.createElement('div');el.id='hqNewswire';el.className='newswire show';const anchor=doc.getElementById('attentionBanner');if(anchor)anchor.insertAdjacentElement('afterend',el);else doc.querySelector('.wrap')?.prepend(el)}
  if(oldSig!==newSig){
    nwIndex=Math.max(0,items.findIndex(x=>x.id===currentId));
    el.innerHTML='<div class="nw-label">NEWSWIRE</div><div class="nw-track">'+items.map((x,idx)=>{const text=esc(x.text),sev=esc(x.severity||'normal'),url=String(x.url||'');const inner=url?`<a href="${esc(url)}" target="_blank" rel="noopener" style="color:inherit;text-decoration:none;overflow:hidden;text-overflow:ellipsis">${text}</a>`:text;return`<div class="nw-item${idx===0?' on':''}" data-sev="${sev}">${inner}</div>`}).join('')+'</div>';
  }
  paint();
  if(items.length>1&&!nwTimer)nwTimer=setInterval(()=>{nwIndex=(nwIndex+1)%nwItems.length;paint()},7000);
}
function mirrorHash(){const h=core?.location?.hash||'#overview';if(location.hash!==h)history.replaceState(null,'',h)}
function install(){
  try{
    if(nwRefreshTimer){clearInterval(nwRefreshTimer);nwRefreshTimer=null}
    core=frame.contentWindow;doc=frame.contentDocument;if(!core||!doc)return;
    if(location.hash&&location.hash!==core.location.hash)core.location.hash=location.hash;
    core.addEventListener('hashchange',mirrorHash);
    refreshNewswire();
    nwRefreshTimer=setInterval(refreshNewswire,15000);
  }catch(e){console.error('Kevin HQ integration install failed',e)}
}
frame.addEventListener('load',install);
addEventListener('hashchange',()=>{try{if(core&&core.location.hash!==location.hash)core.location.hash=location.hash||'#overview'}catch(_e){}});
})();
