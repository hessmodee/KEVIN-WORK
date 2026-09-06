(()=>{
'use strict';
/* P0-2: base64 chunk loader → eval full hq-owner-refinement-v3 (ops_floor.primary truth) */
const PARTS=[
  './hq-p0-2.b64.01.txt',
  './hq-p0-2.b64.02.txt',
  './hq-p0-2.b64.03.txt',
  './hq-p0-2.b64.04.txt',
  './hq-p0-2.b64.05.txt',
  './hq-p0-2.b64.06.txt',
  './hq-p0-2.b64.07.txt',
  './hq-p0-2.b64.08.txt',
  './hq-p0-2.b64.09.txt',
  './hq-p0-2.b64.10.txt',
  './hq-p0-2.b64.11.txt',
  './hq-p0-2.b64.12.txt',
  './hq-p0-2.b64.13.txt',
  './hq-p0-2.b64.14.txt',
  './hq-p0-2.b64.15.txt',
  './hq-p0-2.b64.16.txt',
  './hq-p0-2.b64.17.txt',
  './hq-p0-2.b64.18.txt',
  './hq-p0-2.b64.19.txt',
  './hq-p0-2.b64.20.txt',
  './hq-p0-2.b64.21.txt',
  './hq-p0-2.b64.22.txt',
  './hq-p0-2.b64.23.txt',
  './hq-p0-2.b64.24.txt',
  './hq-p0-2.b64.25.txt',
  './hq-p0-2.b64.26.txt',
  './hq-p0-2.b64.27.txt',
  './hq-p0-2.b64.28.txt',
  './hq-p0-2.b64.29.txt',
  './hq-p0-2.b64.30.txt',
  './hq-p0-2.b64.31.txt',
  './hq-p0-2.b64.32.txt',
  './hq-p0-2.b64.33.txt',
  './hq-p0-2.b64.34.txt',
  './hq-p0-2.b64.35.txt',
  './hq-p0-2.b64.36.txt',
  './hq-p0-2.b64.37.txt',
  './hq-p0-2.b64.38.txt',
  './hq-p0-2.b64.39.txt',
  './hq-p0-2.b64.40.txt',
  './hq-p0-2.b64.41.txt',
  './hq-p0-2.b64.42.txt',
  './hq-p0-2.b64.43.txt',
  './hq-p0-2.b64.44.txt',
  './hq-p0-2.b64.45.txt',
  './hq-p0-2.b64.46.txt',
  './hq-p0-2.b64.47.txt',
  './hq-p0-2.b64.48.txt',
  './hq-p0-2.b64.49.txt'
];
const bust='hqv3p02='+Date.now();
Promise.all(PARTS.map(p=>fetch(p+'?'+bust,{cache:'no-store'}).then(r=>{if(!r.ok)throw Error('P0-2 b64 fail '+p+' '+r.status);return r.text()})))
  .then(texts=>{
    const bin=atob(texts.join('').replace(/\s+/g,''));
    (0,eval)(bin);
  })
  .catch(err=>{console.error('[hq P0-2 loader]',err);});
})();
