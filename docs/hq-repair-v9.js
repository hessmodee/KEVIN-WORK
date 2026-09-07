(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
if(!frame)return;

const REPLACEMENTS=[
  ['ΓÇö','—'],['ΓÇô','–'],['ΓÇó','•'],['ΓÇª','…'],['ΓÇÖ','’'],['ΓÇ£','“'],['ΓÇ¥','”'],
  ['ΓåÆ','→'],['ΓåÉ','←'],['Γåæ','↑'],['Γåô','↓'],['Ã—','×'],['┬╖','·'],['Â·','·'],['Â','']
];
let doc=null;
let observer=null;
let queued=false;
let navBound=null;

function cleanString(value){
  let s=String(value??'');
  for(const [from,to] of REPLACEMENTS)s=s.split(from).join(to);
  s=s.replace(/ΓÇ[\w\u0080-\uFFFF]*/g,'—').replace(/Γå[\w\u0080-\uFFFF]*/g,'→');
  return s;
}

function cleanText(root){
  if(!doc||!root)return;
  const walker=doc.createTreeWalker(root,NodeFilter.SHOW_TEXT);
  const nodes=[];
  let n;
  while((n=walker.nextNode()))nodes.push(n);
  for(const node of nodes){
    const raw=node.nodeValue||'';
    if(!raw.trim())continue;
    const next=cleanString(raw);
    if(next!==raw)node.nodeValue=next;
  }
}

function cleanStateLine(){
  const span=doc?.querySelector('#hqV3StateLine span');
  if(!span)return;
  let text=cleanString(span.textContent||'').trim();
  text=text.replace(/\s*[·•—-]\s*owner outcomes first\s*$/i,'').trim();
  if(text&&span.textContent!==text)span.textContent=text;
}

function repairNav(){
  const nav=doc?.querySelector('nav');
  if(!nav)return;
  // v3 is the single owner-facing nav authority. Do not rename, hide, or rebuild its buttons here.
  for(const button of nav.querySelectorAll('[data-tab]')){
    button.hidden=false;
    button.removeAttribute('aria-hidden');
    button.style.removeProperty('display');
  }
  if(navBound===nav)return;
  navBound=nav;
  nav.addEventListener('click',event=>{
    const button=event.target?.closest?.('[data-tab]');
    if(!button)return;
    const target=String(button.dataset.tab||'').toLowerCase();
    if(!['overview','ops','activity','capabilities','system'].includes(target))return;
    try{
      if(frame.contentWindow.location.hash!==`#${target}`)frame.contentWindow.location.hash=target;
    }catch(_e){}
  },true);
}

function repairHeader(){
  const version=doc?.querySelector('.version');
  if(version){
    version.textContent='HQ V9 · GROUND TRUTH';
    version.title='Owner-facing HQ. Runtime claims must come from evidence sources.';
  }
}

function apply(){
  if(!doc?.body)return;
  cleanText(doc.body);
  cleanStateLine();
  repairNav();
  repairHeader();
  doc.body.dataset.hqRepair='v9';
}

function schedule(){
  if(queued)return;
  queued=true;
  requestAnimationFrame(()=>{queued=false;apply();});
}

function bind(){
  try{doc=frame.contentDocument;if(!doc?.body)return;}catch(_e){return;}
  observer?.disconnect();
  observer=new MutationObserver(schedule);
  observer.observe(doc.body,{subtree:true,childList:true,characterData:true});
  frame.contentWindow?.addEventListener('hashchange',schedule);
  apply();
}

frame.addEventListener('load',bind);
if(frame.contentDocument?.readyState==='complete'||frame.contentDocument?.readyState==='interactive')bind();
})();
