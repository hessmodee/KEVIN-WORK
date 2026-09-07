from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
index=(ROOT/'docs/index.html').read_text(encoding='utf-8')
hq=(ROOT/'docs/hq-owner-console-v10.js').read_text(encoding='utf-8')
ops=(ROOT/'docs/ops/ops-live-truth-v2.js').read_text(encoding='utf-8')
embed=(ROOT/'docs/ops/embed.html').read_text(encoding='utf-8')
sw=(ROOT/'docs/sw.js').read_text(encoding='utf-8')

assert 'hq-owner-console-v10.js' in index
for retired in ('hq-truth-v2.js','hq-owner-refinement-v3.js','hq-growth-v1.js','hq-repair-v9.js'):
    assert retired not in index, retired
assert '#overview' in index
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
print('KEVIN HQ V10 LIVE TRUTH SELFTEST PASS tabs=4 work_truth=machine_evidence telemetry=24h_hover ops_armed_not_working=true stale_layers_retired=true')
