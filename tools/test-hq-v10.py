from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
index=(ROOT/'docs/index.html').read_text(encoding='utf-8')
hq=(ROOT/'docs/hq-owner-console-v10.js').read_text(encoding='utf-8')
ops=(ROOT/'docs/ops/ops-live-truth-v2.js').read_text(encoding='utf-8')
embed=(ROOT/'docs/ops/embed.html').read_text(encoding='utf-8')
sw=(ROOT/'docs/sw.js').read_text(encoding='utf-8')

# Production execution surface: retired compatibility markers may remain inside comments,
# but no retired owner layer may execute alongside V10.
active_index=re.sub(r'<!--.*?-->','',index,flags=re.S)
active_scripts=re.findall(r'<script\s+src="\.\/([^"?]+)',active_index)
assert active_scripts==['hq-evidence-adapter-v1.js','hq-overrides-v1.js','hq-owner-console-v10.js'],active_scripts
assert 'RETIRED LAYER COMPATIBILITY MARKERS — NOT LOADED OR EXECUTED' in index
assert '#ops' in index
assert "[['overview','LIVE'],['ops','OPS FLOOR'],['capabilities','SKILLS'],['system','SYSTEM']]" in hq
assert '24-hour computer telemetry' in hq
assert 'hover for exact timestamp and values' in hq
assert 'No active execution right now.' in hq
assert "if(task||workers>0)" in ops
assert "if(q>0)return{state:'ready',label:'ARMED'" in ops
assert "label:'WORKING'" in ops
assert 'ops-live-truth-v2.js' in embed
assert "kevin-hq-shell-v6" in sw
assert 'hq-owner-console-v10.js' in sw
assert 'ops/ops-live-truth-v2.js' in sw
print('KEVIN HQ V10 LIVE TRUTH SELFTEST PASS tabs=4 work_truth=machine_evidence telemetry=24h_hover ops_armed_not_working=true retired_layers_not_executed=true')
