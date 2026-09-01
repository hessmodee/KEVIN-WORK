from pathlib import Path
import hashlib
import subprocess
import sys

subprocess.run([sys.executable, 'tools/generate-supervisor-v18-autonomy-controller.py'], check=True)
p = Path('control-plane/autonomy/kevin-supervisor-v1.8.ps1')
text = p.read_text(encoding='utf-8')
old = "$same = ([string]$st.last_fingerprint -eq $finger)"
new = "$lastFingerprint = if ($st.PSObject.Properties.Name -contains 'last_fingerprint') { [string]$st.last_fingerprint } else { '' }\n        $same = ($lastFingerprint -eq $finger)"
if text.count(old) != 1:
    raise SystemExit(f'first-state anchor count={text.count(old)}')
text = text.replace(old, new, 1)
out = Path('control-plane/autonomy/kevin-supervisor-v1.8.1.ps1')
out.write_text(text, encoding='utf-8', newline='')
print('SUPERVISOR_V181_GENERATED supervisor_sha256=' + hashlib.sha256(out.read_bytes()).hexdigest().upper())
