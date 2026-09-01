from pathlib import Path
import runpy
import hashlib

# Preserve the already-reviewed v1.3.16 generator as the canonical transformation,
# then apply one surgical syntax correction discovered by the Windows parser gate.
# This deterministic wrapper is also the trigger surface for the AST safety gate.
runpy.run_path('tools/generate-maintenance-v1316-supervisor-forge-demand-gate.py', run_name='__main__')

p = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.16.ps1')
text = p.read_text(encoding='utf-8')
bad = 'catch[System.Threading.AbandonedMutexException]'
good = 'catch [System.Threading.AbandonedMutexException]'
count = text.count(bad)
if count != 2:
    raise SystemExit(f'expected exactly two typed-catch syntax anchors, found {count}')
text = text.replace(bad, good)
if bad in text or text.count(good) != 2:
    raise SystemExit('typed-catch syntax repair invariant failed')
p.write_text(text, encoding='utf-8', newline='')
print('MAINT_V1316_TYPED_CATCH_FIXED', hashlib.sha256(p.read_bytes()).hexdigest().upper())
