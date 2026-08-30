from pathlib import Path
p=Path('docs/ops/ops-v11.js')
s=p.read_text(encoding='utf-8')
old="for(const w of WORKERS){\n   const st=workerState(w.key,d,s);"
new="for(const w of WORKERS){\n   if(['bridge','tick'].includes(w.key))continue;\n   const st=workerState(w.key,d,s);"
if s.count(old)!=1: raise SystemExit(f'aggregate anchor count={s.count(old)}')
s=s.replace(old,new,1)
if "if(['bridge','tick'].includes(w.key))continue;" not in s: raise SystemExit('housekeeping exclusion missing')
p.write_text(s,encoding='utf-8')
print('AGGREGATE_REFINE_OK')
