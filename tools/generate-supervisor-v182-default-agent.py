from pathlib import Path
import hashlib
import subprocess
import sys

subprocess.run([sys.executable, 'tools/generate-supervisor-v181-first-state-fix.py'], check=True)
p = Path('control-plane/autonomy/kevin-supervisor-v1.8.1.ps1')
text = p.read_text(encoding='utf-8')
old = "$r = Invoke-OpenClaw @('agent', '--agent', 'main', '--json', '--message', $message)"
new = "$r = Invoke-OpenClaw @('agent', '--json', '--message', $message)"
if text.count(old) != 1:
    raise SystemExit(f'default-agent anchor count={text.count(old)}')
text = text.replace(old, new, 1)
text = text.replace('# Kevin Supervisor v1.8 Governed Autonomy Continuation Controller', '# Kevin Supervisor v1.8.2 Governed Autonomy Continuation Controller', 1)
text = text.replace("version = '1.8'", "version = '1.8.2'", 1)
out = Path('control-plane/autonomy/kevin-supervisor-v1.8.2.ps1')
out.write_text(text, encoding='utf-8', newline='')
print('SUPERVISOR_V182_GENERATED supervisor_sha256=' + hashlib.sha256(out.read_bytes()).hexdigest().upper())
