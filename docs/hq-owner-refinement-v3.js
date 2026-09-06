(()=>{
'use strict';
/* P0-2 chunked loader — concat part files, eval full body (ops_floor.primary truth bind) */
const PARTS=[
  './hq-owner-refinement-v3.p0-2.part01.js',
  './hq-owner-refinement-v3.p0-2.part02.js',
  './hq-owner-refinement-v3.p0-2.part03.js',
  './hq-owner-refinement-v3.p0-2.part04.js',
  './hq-owner-refinement-v3.p0-2.part05.js',
  './hq-owner-refinement-v3.p0-2.part06.js',
  './hq-owner-refinement-v3.p0-2.part07.js',
  './hq-owner-refinement-v3.p0-2.part08.js'
];
const bust='hqv3p02='+Date.now();
Promise.all(PARTS.map(p=>fetch(p+'?'+bust,{cache:'no-store'}).then(r=>{if(!r.ok)throw Error('P0-2 part fail '+p+' '+r.status);return r.text()})))
  .then(texts=>{(0,eval)(texts.join(''))})
  .catch(err=>{console.error('[hq P0-2 loader]',err);});
})();
