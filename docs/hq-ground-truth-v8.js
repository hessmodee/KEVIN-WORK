(()=>{
'use strict';
const frame=document.getElementById('kevinCore');
if(!frame)return;

const CODE_LABELS={
  WAITING_ITEM_BUDGETS:'Waiting for retry window',
  NO_ELIGIBLE_MISSION:'No eligible mission available',
  IDLE_NO_ELIGIBLE_DEMAND:'No eligible work available',
  NOT_PROVEN:'Not yet proven',
  IN_PROGRESS:'In progress',
  NEEDS_HELP:'Needs attention',
  CLOSE_CANDIDATE:'Close candidate',
  ALREADY_APPLIED_PROVEN:'Applied and proven',
  DUPLICATE_IGNORED:'Duplicate already handled',
  STALE_SELECTION:'Selection evidence is stale'
};
const MOJIBAKE=new Map([
  ['ΓÇö','—'],['ΓÇô','–'],['ΓÇó','•'],['ΓÇª','…'],['ΓÇÖ','’'],['ΓÇ£','“'],['ΓÇ¥','”'],
  ['ΓåÆ','→'],['ΓåÉ','←'],['Γåæ','↑'],['Γåô','↓'],['Ã—','×'],['Â·','·'],['Â','']
]);
const PRESERVE_CODES=new Set(['CPU','GPU','RAM','HQ','UI','AI','PNG','JSON','PASS','FAIL','GREEN','READY','LIVE','LOCAL']);
let doc=null,observer=null,queued=false;

const styleText=`
  .hq-v8-hidden{display:none!important}
  .hq-v8-raw{cursor:help}
  nav .navbtn{transition:opacity .15s ease,border-color .15s ease,background .15s ease}
  body.hq-v8-ready .version{letter-spacing:.08em}
  .hq-v8-note{margin-top:8px;color:var(--muted);font-size:10px;line-height:1.45}
`;

function titleCase(s){
  return String(s||'').toLowerCase().replace(/\b\w/g,c=>c.toUpperCase());
}
function humanCode(raw){
  if(CODE_LABELS[raw])return CODE_LABELS[raw];
  if(PRESERVE_CODES.has(raw))return raw;
  let s=raw;
  // Remove machine/test prefixes from owner-facing labels but keep the original in title.
  s=s.replace(/^(?:P\d+(?:\.\d+)?|T\d+(?:\.\d+)?|META)[_\-.]+/i,'');
  s=s.replace(/_/g,' ').replace(/\s+/g,' ').trim();
  if(!s)return raw;
  return titleCase(s)
    .replace(/\bPng\b/g,'PNG')
    .replace(/\bUi\b/g,'UI')
    .replace(/\bAi\b/g,'AI')
    .replace(/\bJson\b/g,'JSON');
}
function cleanString(input){
  let s=String(input??'');
  for(const[a,b]of MOJIBAKE)s=s.split(a).join(b);
  // Any surviving common mojibake marker should be rendered as a neutral separator, never garbage glyphs.
  s=s.replace(/ΓÇ[\w\u0080-\uFFFF]*/g,'—').replace(/Γå[\w\u0080-\uFFFF]*/g,'→');
  s=s.replace(/\b([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+)\b/g,(m,code)=>humanCode(code));
  return s;
}
function rememberRaw(el,raw){
  if(!el||!raw||el.dataset?.hqV8Raw)return;
  try{
    el.dataset.hqV8Raw=raw.slice(0,500);
    el.classList.add('hq-v8-raw');
    if(!el.getAttribute('title'))el.setAttribute('title',`Machine value: ${raw.slice(0,300)}`);
  }catch{}
}
function cleanTextNodes(root){
  const walker=doc.createTreeWalker(root,NodeFilter.SHOW_TEXT);
  const nodes=[]; let n;
  while((n=walker.nextNode()))nodes.push(n);
  for(const node of nodes){
    const raw=node.nodeValue||'';
    if(!raw.trim())continue;
    const cleaned=cleanString(raw);
    if(cleaned!==raw){rememberRaw(node.parentElement,raw.trim());node.nodeValue=cleaned;}
  }
}
function navButtons(){return [...doc.querySelectorAll('nav .navbtn, nav button, nav a')];}
function navByText(label){return navButtons().find(x=>x.textContent.trim().toUpperCase()===label);}
function configureNav(){
  const command=navByText('COMMAND');
  if(command){command.classList.add('hq-v8-hidden');command.setAttribute('aria-hidden','true');}
  const work=navByText('WORK LOG');
  if(work){work.textContent='WORK';work.setAttribute('aria-label','Work, outcomes and evidence');}
  const system=navByText('SYSTEM');
  if(system){system.textContent='DIAGNOSTICS';system.setAttribute('aria-label','Diagnostics and technical platform details');}
  const ops=navByText('OPS FLOOR');
  if(ops)ops.setAttribute('aria-label','Ops Floor, Kevin current state and workers');
  const skills=navByText('SKILLS');
  if(skills)skills.setAttribute('aria-label','Skills and proven capabilities');
}
function headingCard(text){
  const target=[...doc.querySelectorAll('h1,h2,h3,.v,.mission-copy,.section-head *')]
    .find(x=>x.textContent.trim().toLowerCase()===text.toLowerCase());
  return target?.closest('.card')||null;
}
function currentRoute(){
  const h=(frame.contentWindow?.location?.hash||'').toLowerCase();
  if(h.includes('capabilities'))return'skills';
  if(h.includes('activity'))return'work';
  if(h.includes('system'))return'diagnostics';
  if(h.includes('ops'))return'ops';
  return'other';
}
function dedupeView(){
  const route=currentRoute();
  // Owner priority cards are useful planning context, but they belong on the Ops/Work side,
  // not repeated under the competency ledger. Skills should answer only "what can Kevin prove?".
  if(route==='skills'){
    const dup=headingCard('What Kevin should become useful at');
    if(dup)dup.classList.add('hq-v8-hidden');
  }
}
function fixHeader(){
  const v=doc.querySelector('.version');
  if(v){v.textContent='HQ V8 · GROUND TRUTH';v.setAttribute('title','Owner-facing HQ shell. Freshness is determined by the evidence sources, not this label.');}
  // Never let a static decorative word "LIVE" override source freshness.
  for(const el of [...doc.querySelectorAll('.version,.pill,.head-right *')]){
    if(/\bLIVE\b/i.test(el.textContent||'')) el.textContent=(el.textContent||'').replace(/\bLIVE\b/gi,'GROUND TRUTH');
  }
}
function annotateNews(){
  // The Newswire generator now excludes obituaries/death notices at publication time.
  // This is only a visible policy hint; it is not a client-side substitute for source filtering.
  const rail=[...doc.querySelectorAll('*')].find(x=>/^NEWSWIRE$/i.test(x.textContent.trim())&&x.children.length===0);
  if(rail&&!rail.getAttribute('title'))rail.setAttribute('title','Public headlines filtered for owner usefulness; obituaries and death notices are excluded at the feed generator.');
}
function apply(){
  if(!doc?.body)return;
  configureNav();
  fixHeader();
  cleanTextNodes(doc.body);
  dedupeView();
  annotateNews();
  doc.body.classList.add('hq-v8-ready');
}
function schedule(){if(queued)return;queued=true;requestAnimationFrame(()=>{queued=false;apply();});}
function bind(){
  try{doc=frame.contentDocument;if(!doc?.body)return;}catch{return;}
  if(!doc.getElementById('hqGroundTruthV8Style')){
    const s=doc.createElement('style');s.id='hqGroundTruthV8Style';s.textContent=styleText;doc.head.appendChild(s);
  }
  observer?.disconnect();
  observer=new MutationObserver(schedule);
  observer.observe(doc.body,{subtree:true,childList:true,characterData:true});
  frame.contentWindow?.addEventListener('hashchange',schedule);
  apply();
}
frame.addEventListener('load',bind);
if(frame.contentDocument?.readyState==='complete'||frame.contentDocument?.readyState==='interactive')bind();
})();
