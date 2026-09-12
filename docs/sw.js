/* Kevin HQ resilient app shell v8
 * Scope: GitHub Pages /KEVIN-WORK/
 * Public static assets + sanitized public telemetry only.
 * Network remains authoritative; cache is outage fallback, never proof of freshness.
 * Historical proof compatibility marker only: kevin-hq-shell-v4, kevin-hq-shell-v6, kevin-hq-shell-v7, kevin-hq-shell-v8
 * v9 busts the v8 cache so SKILLS/SYSTEM pick up toolsChip after query-strip.
 * v10 + P0 painter b64.01-16 shell entries (skill_lab + painted_hint VERIFYING honesty).
 */
'use strict';

const VERSION='kevin-hq-shell-v15';
const SHELL_CACHE=`${VERSION}-static`;
const DATA_CACHE=`${VERSION}-public-data`;
const BASE='/KEVIN-WORK/';
const SHELL=[
  BASE,
  `${BASE}index.html`,
  `${BASE}hq-core-v7.html`,
  `${BASE}hq-evidence-adapter-v1.js`,
  `${BASE}hq-overrides-v1.js`,
  `${BASE}hq-owner-console-v10.js`,
  `${BASE}hq-p1-ground-truth-v1.js`,
  `${BASE}hq-p0-floor-painter-v1.js`,
  `${BASE}hq-p0-floor-painter-v1.b64.16.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.15.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.14.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.13.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.12.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.11.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.10.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.09.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.08.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.07.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.06.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.05.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.04.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.03.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.02.txt`,
  `${BASE}hq-p0-floor-painter-v1.b64.01.txt`,
  `${BASE}hq-growth-v1.js`,
  `${BASE}ops/index.html`,
  `${BASE}ops/embed.html`,
  `${BASE}ops/app.js`,
  `${BASE}ops/style.css`,
  `${BASE}ops/ops-v11.css`,
  `${BASE}ops/ops-v11.js`
];

function normalizedRequest(request){
  const u=new URL(request.url);
  if(u.hostname==='raw.githubusercontent.com' && u.pathname.startsWith('/hessmodee/KEVIN-WORK/main/')){
    u.search='';
    return new Request(u.toString(),{method:'GET',mode:'cors',credentials:'omit'});
  }
  if(u.origin===self.location.origin && u.pathname.startsWith(BASE)){
    u.search='';
    return new Request(u.toString(),{method:'GET',credentials:'same-origin'});
  }
  return request;
}

async function cacheShell(){
  const cache=await caches.open(SHELL_CACHE);
  await Promise.allSettled(SHELL.map(async path=>{
    const req=new Request(path,{cache:'reload'});
    const res=await fetch(req);
    if(res.ok) await cache.put(normalizedRequest(req),res.clone());
  }));
}

self.addEventListener('install',event=>{
  event.waitUntil(cacheShell().then(()=>self.skipWaiting()));
});

self.addEventListener('activate',event=>{
  event.waitUntil((async()=>{
    for(const key of await caches.keys()){
      if(key!==SHELL_CACHE && key!==DATA_CACHE && key.startsWith('kevin-hq-')) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

async function networkFirst(request,cacheName){
  const key=normalizedRequest(request);
  const cache=await caches.open(cacheName);
  try{
    const res=await fetch(request);
    if(res && res.ok) await cache.put(key,res.clone());
    if(res && (res.ok || res.type==='opaque')) return res;
    const fallback=await cache.match(key,{ignoreSearch:true});
    return fallback || res;
  }catch(err){
    const fallback=await cache.match(key,{ignoreSearch:true});
    if(fallback) return fallback;
    throw err;
  }
}

self.addEventListener('fetch',event=>{
  const req=event.request;
  if(req.method!=='GET') return;
  const u=new URL(req.url);
  const local=u.origin===self.location.origin && u.pathname.startsWith(BASE);
  const sanitizedRepoData=u.hostname==='raw.githubusercontent.com' && u.pathname.startsWith('/hessmodee/KEVIN-WORK/main/');
  if(!local && !sanitizedRepoData) return;

  if(req.mode==='navigate'){
    event.respondWith((async()=>{
      try{
        const res=await fetch(req);
        if(res.ok){
          const cache=await caches.open(SHELL_CACHE);
          await cache.put(normalizedRequest(req),res.clone());
          return res;
        }
        const cached=await caches.match(normalizedRequest(req),{ignoreSearch:true});
        if(cached) return cached;
        const root=await caches.match(new Request(`${self.location.origin}${BASE}index.html`),{ignoreSearch:true});
        return root || res;
      }catch(err){
        const cached=await caches.match(normalizedRequest(req),{ignoreSearch:true});
        if(cached) return cached;
        const root=await caches.match(new Request(`${self.location.origin}${BASE}index.html`),{ignoreSearch:true});
        if(root) return root;
        throw err;
      }
    })());
    return;
  }

  if(sanitizedRepoData){
    event.respondWith(networkFirst(req,DATA_CACHE));
    return;
  }

  if(/\.(?:html|js|css|json)$/i.test(u.pathname) || u.pathname.endsWith('/')){
    event.respondWith(networkFirst(req,SHELL_CACHE));
  }
});
