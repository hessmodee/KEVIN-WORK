from pathlib import Path

owner_path = Path('docs/hq-owner-refinement-v3.js')
test_path = Path('.github/scripts/test-hq-owner-invariants.cjs')
owner = owner_path.read_text(encoding='utf-8')
test = test_path.read_text(encoding='utf-8')


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'STOP {label}: expected exactly one anchor, found {count}')
    return text.replace(old, new, 1)

owner = replace_once(
    owner,
    "function activeWorkers(){return Object.values(cache.support?.active_workers||{}).reduce((n,v)=>n+(Number(v)||0),0)}\nfunction items()",
    "function activeWorkers(){return Object.values(cache.support?.active_workers||{}).reduce((n,v)=>n+(Number(v)||0),0)}\nfunction skillQueue(){return cache.engineering?.action?.skill_lab?.queue||{}}\nfunction skillRunning(){return Number(skillQueue().running)||0}\nfunction skillReady(){return Number(skillQueue().ready)||0}\nfunction skillBlocked(){return Number(skillQueue().blocked)||0}\nfunction items()",
    'skill queue helpers',
)

owner = replace_once(
    owner,
    "function priorities(){const x=mdSection('current live platform repair targets',4);return x.length?x:FALLBACK_PRIORITIES}",
    "function priorities(){let x=mdSection('current p0 blockers',4);if(!x.length)x=mdSection('current live platform repair targets',4);return x.length?x:FALLBACK_PRIORITIES}",
    'current P0 heading',
)
owner = replace_once(
    owner,
    "function ownerSkills(){const x=mdSection(\"tonight's owner-value skill wave\",6);if(!x.length)return FALLBACK_SKILLS;return x.map(([a,b])=>[a.replace(/@1\\b/g,'').replace(/[-_]+/g,' ').replace(/\\b\\w/g,c=>c.toUpperCase()),b])}",
    "function ownerSkills(){let x=mdSection('green development lane',6);if(!x.length)x=mdSection(\"tonight's owner-value skill wave\",6);if(!x.length)return FALLBACK_SKILLS;return x.map(([a,b])=>[a.replace(/@1\\b/g,'').replace(/[-_]+/g,' ').replace(/\\b\\w/g,c=>c.toUpperCase()),b])}",
    'current skill heading',
)

old_truth = "function truth(){const d=cache.dashboard||{},c=cache.continuation||{},aw=activeWorkers(),el=eligibleItems().length,bl=blockedItems().length;if(activeTask(d.current_task)||aw>0)return{state:'WORKING',cls:'working',title:d.current_task?.title||`${aw} active worker${aw===1?'':'s'}`,detail:d.current_task?.phase||'Evidence-producing execution is active.'};if(el>0)return{state:'ELIGIBLE WORK',cls:'ok',title:`${el} governed mission${el===1?'':'s'} ready`,detail:'Owner-approved work is available to begin.'};if(bl>0)return{state:'BLOCKED WORK',cls:'warn',title:`${bl} blocked owner item${bl===1?'':'s'}`,detail:'Useful work exists, but a tool, proof or prerequisite is missing.'};if(String(c.status||'').toUpperCase()==='IDLE_NO_ELIGIBLE_DEMAND')return{state:'TRUE IDLE',cls:'idle',title:'No eligible work in the current selector',detail:'No active mission is proven at this instant.'};return{state:'READY',cls:'ok',title:'Kevin is ready',detail:'No active execution is proven right now.'}}"
new_truth = "function truth(){const d=cache.dashboard||{},c=cache.continuation||{},aw=activeWorkers(),sr=skillRunning(),el=eligibleItems().length+skillReady(),bl=blockedItems().length+skillBlocked();if(activeTask(d.current_task)||aw>0||sr>0)return{state:'WORKING',cls:'working',title:d.current_task?.title||(sr>0?`${sr} Skill Lab job${sr===1?'':'s'} running`:`${aw} active worker${aw===1?'':'s'}`),detail:d.current_task?.phase||(sr>0?'Skill Lab is executing replayable capability proof.':'Evidence-producing execution is active.')};if(el>0)return{state:'ELIGIBLE WORK',cls:'ok',title:`${el} governed mission${el===1?'':'s'} ready`,detail:'Owner-approved work is available to begin.'};if(bl>0)return{state:'BLOCKED WORK',cls:'warn',title:`${bl} blocked owner item${bl===1?'':'s'}`,detail:'Useful work exists, but a tool, proof or prerequisite is missing.'};if(String(c.status||'').toUpperCase()==='IDLE_NO_ELIGIBLE_DEMAND')return{state:'TRUE IDLE',cls:'idle',title:'No eligible work across Supervisor or Skill Lab',detail:'No active execution, ready Skill Lab work or blocked owner work is proven at this instant.'};return{state:'READY',cls:'ok',title:'Kevin is ready',detail:'No active execution is proven right now.'}}"
owner = replace_once(owner, old_truth, new_truth, 'global truth calculation')

owner = replace_once(
    owner,
    "${stat('Active workers',activeWorkers(),activeWorkers()?'working':'')}${stat('Eligible queue',eligibleItems().length,eligibleItems().length?'ok':'')}${stat('Blocked',blockedItems().length,blockedItems().length?'warn':'ok')}",
    "${stat('Active execution',activeWorkers()+skillRunning(),activeWorkers()+skillRunning()?'working':'')}${stat('Eligible queue',eligibleItems().length+skillReady(),eligibleItems().length+skillReady()?'ok':'')}${stat('Blocked',blockedItems().length+skillBlocked(),blockedItems().length+skillBlocked()?'warn':'ok')}",
    'command counts',
)

owner = replace_once(
    owner,
    "if(blockedItems().length)out.push(['warn',`${blockedItems().length} owner-value item${blockedItems().length===1?' is':'s are'} blocked`,blockedItems()[0]?.next_action||blockedItems()[0]?.id||'Open System for details.']);",
    "if(blockedItems().length)out.push(['warn',`${blockedItems().length} owner-value item${blockedItems().length===1?' is':'s are'} blocked`,blockedItems()[0]?.next_action||blockedItems()[0]?.id||'Open System for details.']);if(skillBlocked()>0)out.push(['warn',`${skillBlocked()} Skill Lab job${skillBlocked()===1?' is':'s are'} blocked`,'A replayable skill request exists but cannot currently complete; inspect Engineering evidence for the prerequisite.']);",
    'Skill Lab blocked attention',
)

marker = "assert.ok(read('docs/hq-core-v7.html').length, 'core exists and is nonempty');"
assertions = """const ownerRefinement = read('docs/hq-owner-refinement-v3.js');
for (const token of ['function skillRunning()','function skillReady()','function skillBlocked()','aw>0||sr>0','eligibleItems().length+skillReady()','blockedItems().length+skillBlocked()','No eligible work across Supervisor or Skill Lab']) {
  assert.ok(ownerRefinement.includes(token), `owner global truth includes ${token}`);
}
assert.ok(ownerRefinement.includes("mdSection('current p0 blockers',4)"), 'owner priorities follow current task heading');
assert.ok(ownerRefinement.includes("mdSection('green development lane',6)"), 'owner skill wave follows current task heading');

""" + marker
if 'owner global truth includes' not in test:
    test = replace_once(test, marker, assertions, 'owner invariant test insertion')

owner_path.write_text(owner, encoding='utf-8')
test_path.write_text(test, encoding='utf-8')
print('PASS HQ Skill Lab global-truth repair applied once')
