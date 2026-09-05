'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const core=fs.readFileSync('docs/hq-core-v7.html','utf8');
// Compile every actual inline script, not a duplicate implementation.
for(const match of core.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g))new vm.Script(match[1]);
const newsCode=core.slice(core.indexOf('function reportFresh('),core.indexOf('function paintNewswire('));
const now=Date.now(),at=new Date(now).toISOString();
const fixture={Date,URL,HQ_SUPPORT:{generated_at:at,benchmark:{status:'FAIL_CRITICAL_REGRESSION',regression:{passed:29,total:30,critical_failures:1,failed:[{id:'R04'}]}}},EXT_NEWS:{generated_at:at,headlines:['local','national','world','top'].flatMap(category=>Array.from({length:4},(_,i)=>({category,title:`${category} story ${i}`,url:'https://example.test/article'})))},deriveNewswire:()=>[{id:'roadmap',text:'Next: Prove System Reader E2E'},{id:'health',text:'all checks passed'}]};
vm.createContext(fixture);vm.runInContext(newsCode,fixture);
let stories=vm.runInContext('newswireStories()',fixture);
assert.match(stories[0].text,/29\/30.*R04/);
assert.deepEqual(Array.from(stories.slice(1,4),x=>x.text.split(' · ')[0]),['LOCAL','NATIONAL','INTERNATIONAL']);
assert.ok(!stories.some(x=>/Prove System Reader|all checks passed/.test(x.text)));
fixture.EXT_NEWS.generated_at=new Date(now-7*3600000).toISOString();
stories=vm.runInContext('newswireStories()',fixture);
assert.ok(stories.some(x=>x.id==='news-stale'));
assert.ok(!stories.some(x=>x.id.startsWith('news-local')),'expired headlines are not current news');
fixture.EXT_NEWS.generated_at=new Date(now+3600000).toISOString();
assert.ok(vm.runInContext('newswireStories()',fixture).some(x=>x.id==='news-stale'),'future dates are rejected');
fixture.EXT_NEWS.generated_at=at;
fixture.EXT_NEWS.headlines=[{category:'local',title:'untrusted URL',url:'javascript:alert(1)'}];
stories=vm.runInContext('newswireStories()',fixture);
assert.equal(stories.find(x=>x.text.includes('untrusted')).url,'');
assert.ok(stories.some(x=>x.id==='news-incomplete'));
fixture.HQ_SUPPORT.generated_at=new Date(now-3600000).toISOString();
assert.ok(vm.runInContext('newswireStories()',fixture).some(x=>x.id==='kevin-status-unverified'));

const source=fs.readFileSync('docs/ops/ops-v11.js','utf8');
const scope={Date,window:{}};vm.createContext(scope);
vm.runInContext(source.slice(0,source.indexOf('\ndocument.getElementById(\'headerKevinProd\')')),scope);
const d={generated_at:at,services:{tick:'healthy',bridge:'healthy',ollama:'healthy'}},s={generated_at:at,active_workers:{},cron:{jobs:[{declaration_key:'kevin-hq-live-pulse-v15',last_run_at_ms:now-1000}]},benchmark:{status:'PASS'}};
for(const key of ['reader','staging','chat','tick','benchmark','build','night']){
  scope.d=d;scope.s=s;scope.key=key;
  assert.equal(vm.runInContext('workerState(key,d,s)',scope),'ready',`${key} idle is ready`);
}
for(const key of ['reader','staging','chat','tick']){
  s.active_workers={[key]:1};scope.key=key;
  assert.equal(vm.runInContext('workerState(key,d,s)',scope),'working',`${key} honors real counter`);
}
s.active_workers={};
for(const phase of ['completed','failed','queued','cooldown'])for(const key of ['benchmark','build','night','reader','staging','chat']){
  d.current_task={title:key==='night'?'Night Forge':key,phase};scope.key=key;
  assert.equal(vm.runInContext('workerState(key,d,s)',scope),'ready',`${key} ${phase} is not work`);
}
d.current_task={title:'Reader task',phase:'executing'};scope.key='reader';
assert.equal(vm.runInContext('workerState(key,d,s)',scope),'working');
d.generated_at=new Date(now-3600000).toISOString();
assert.equal(vm.runInContext('workerState(key,d,s)',scope),'ready','fresh Support does not make an old Dashboard task current');
console.log('PASS news freshness/categories/R04/URL safety and real worker/terminal/stale attribution');

// Phase B: Night Forge Disabled must not report READY
s.public_truth={night_forge_task_state:'Disabled'};
scope.key='night';scope.s=s;scope.d=d;
assert.equal(vm.runInContext('workerState(key,d,s)',scope),'disabled','Disabled Night Forge is not READY');
assert.equal(vm.runInContext('nightForgeHidden(s)',scope),true,'Disabled Night Forge is hidden');
s.public_truth={night_forge_task_state:'Ready'};
assert.equal(vm.runInContext('workerState(key,d,s)',scope),'ready','Ready Night Forge idle stays ready');
assert.equal(vm.runInContext('nightForgeHidden(s)',scope),false,'Ready Night Forge is not hidden');
delete s.public_truth;
console.log('PASS Night Forge Disabled hide/truth (Phase B)');

const truthSource=fs.readFileSync('docs/hq-truth-v2.js','utf8');
let truthCode=truthSource.replace("const frame=document.getElementById('kevinCore');",'const frame={};');
const stop="frame.addEventListener('load',()=>{bind();refresh()});";
assert.ok(truthCode.includes(stop));
truthCode=truthCode.replace(stop,"globalThis.testTruth={setCache:x=>cache=x,autonomyTruth,issueRows};return;"+stop);
const truthScope={Date,document:{getElementById:()=>({})},window:{},setTimeout:()=>0,setInterval:()=>0};
vm.createContext(truthScope);vm.runInContext(truthCode,truthScope);
const oldAudit={generated_at:new Date(now-7200000).toISOString(),state:'NEEDS_REVIEW'};
truthScope.testTruth.setCache({autonomy:oldAudit,continuation:{generated_at:at,status:'IDLE_NO_ELIGIBLE_DEMAND',version:'1.8.8',eligible_count:0,outcome_proven:false}});
assert.equal(truthScope.testTruth.autonomyTruth(oldAudit).headline,'NO ELIGIBLE WORK');
assert.ok(truthScope.testTruth.issueRows().some(x=>x.title==='Full autonomy audit needs refresh'),'old full audit remains visible');
truthScope.testTruth.setCache({continuation:{generated_at:oldAudit.generated_at,status:'IDLE_NO_ELIGIBLE_DEMAND'}});
assert.equal(truthScope.testTruth.autonomyTruth(oldAudit).headline,'STALE SELECTION');
console.log('PASS current Supervisor selection is distinct from old full reconciliation and outcome proof');

