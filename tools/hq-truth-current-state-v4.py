from pathlib import Path
import re

PATH = Path('docs/hq-truth-v2.js')
text = PATH.read_text(encoding='utf-8').replace('\r\n','\n')

# This patch targets the exact production file loaded by docs/index.html.
# It does NOT suppress the real blocked-Forge incident. It repairs only:
# 1) cross-snapshot worker contradictions where Support predates Dashboard; and
# 2) terminal expired Engineering Relay envelopes being surfaced as owner Attention.

helper = r'''function workTelemetryConflict(d,s){
  if(!taskActive(d?.current_task)||activeWorkers(s)!==0)return false;
  const ds=sourceState('dashboard',d),ss=sourceState('support',s);
  if(ds.state!=='FRESH'||ss.state!=='FRESH')return false;
  const dashAt=parseTs(tsOf(d)),supportAt=parseTs(tsOf(s));
  if(!Number.isFinite(dashAt)||!Number.isFinite(supportAt))return false;
  // A Support snapshot older than Dashboard cannot disprove work that Dashboard observed later.
  return supportAt>=dashAt;
}
'''

if 'function workTelemetryConflict(' not in text:
    anchor = "function forgeActive(d,s){const t=d?.current_task||{};const tag=[t.id,t.title,t.category,t.source].join(' ');return (taskActive(t)&&/forge/i.test(tag))||Number(s?.active_workers?.design_forge||0)>0||Number(s?.active_workers?.night_forge||0)>0}\n"
    if text.count(anchor) != 1:
        raise SystemExit('forgeActive helper anchor mismatch')
    text = text.replace(anchor, anchor + helper, 1)

old_conflict = "  if(taskActive(d.current_task)&&activeWorkers(s)===0){\n    out.push({sev:'warn',title:'Current-work telemetry conflicts',detail:`Dashboard says “${d.current_task?.title||d.current_task?.id||'task'}” is active while Support reports 0 active workers.`});\n  }"
new_conflict = "  if(workTelemetryConflict(d,s)){\n    out.push({sev:'warn',title:'Current-work telemetry conflicts',detail:`Dashboard says “${d.current_task?.title||d.current_task?.id||'task'}” is active and an equally-new or newer Support snapshot still reports 0 active workers.`});\n  }"
if old_conflict in text:
    text = text.replace(old_conflict, new_conflict, 1)
elif new_conflict not in text:
    raise SystemExit('current-work conflict anchor mismatch')

expired = "  if(String(e?.request?.status||'').toUpperCase()==='REJECTED'&&/expired/i.test(String(e?.request?.detail||'')))out.push({sev:'warn',title:'Engineering Relay slot is expired',detail:`${e?.request?.id||'request'} should be retired instead of resurfaced.`});\n"
if expired in text:
    text = text.replace(expired, '', 1)

# Exact production invariants.
required = [
    'function workTelemetryConflict(d,s)',
    'return supportAt>=dashAt;',
    'Blocked Forge is still producing work',
    'KNOWN DRIFT',
    'Current-work telemetry conflicts',
]
for r in required:
    if r not in text:
        raise SystemExit('missing invariant: ' + r)
if 'Engineering Relay slot is expired' in text:
    raise SystemExit('terminal expired relay still exposed as owner Attention')

PATH.write_text(text, encoding='utf-8', newline='\n')
print('HQ_TRUTH_CURRENT_STATE_V4_PATCHED', PATH)
