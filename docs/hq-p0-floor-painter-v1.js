(() => {
'use strict';
/** P0 OPS FLOOR painter loader — MCP size workaround; chunks are exact base64 of painter source */
const N=16;
async function load() {
  const texts=[];
  for (let i=1;i<=N;i++) {
    const id=String(i).padStart(2,'0');
    const url=new URL(`./hq-p0-floor-painter-v1.b64.${id}.txt`, document.currentScript.src);
    const res=await fetch(url, {cache:'no-store'});
    if(!res.ok) throw new Error('P0 painter b64 chunk '+id+' HTTP '+res.status);
    texts.push(await res.text());
  }
  const b64=texts.join('').replace(/\s+/g,'');
  const bin=atob(b64);
  const bytes=new Uint8Array(bin.length);
  for(let i=0;i<bin.length;i++) bytes[i]=bin.charCodeAt(i);
  const code=new TextDecoder('utf-8').decode(bytes);
  (0, eval)(code);
}
load().catch(err => {
  console.error('[hq-p0-floor-painter] load failed', err);
  try { window.__hqP0FloorPainterLoadError=String(err&&err.message||err); } catch(_){}
});
})();
