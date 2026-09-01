from pathlib import Path
import re
import sys

path = Path(sys.argv[1] if len(sys.argv) > 1 else 'control-plane/maintenance/kevin-maintenance-runner-v1.3.17.ps1')
text = path.read_text(encoding='utf-8')

def between(start: str, end: str) -> str:
    a = text.find(start)
    if a < 0:
        raise SystemExit(f'missing start anchor: {start}')
    b = text.find(end, a + len(start))
    if b < 0:
        raise SystemExit(f'missing end anchor: {end}')
    return text[a:b]

common = between('function Assert-Common([object]$m) {', 'function Assert-Replace([object]$m) {')
needle = re.search(r"@\((.*?)\)\s*-contains\s*\[string\]\$m\.operation", common, re.S)
if not needle:
    raise SystemExit('could not extract Assert-Common operation allowlist')
common_ops = set(re.findall(r"'([a-z0-9_]+)'", needle.group(1)))

proc = between('function Process-Typed([object]$m) {', 'function Legacy-Stage(')
validation = proc.split('Assert-Governance', 1)[0]
execution = proc.split('$result=switch([string]$m.operation){', 1)
if len(execution) != 2:
    raise SystemExit('execution switch anchor missing')
execution = execution[1].split('Save-Attempt', 1)[0]

validation_ops = set(re.findall(r"(?m)^\s*'([a-z0-9_]+)'\s*\{", validation))
execution_ops = set(re.findall(r"(?m)^\s*'([a-z0-9_]+)'\s*\{", execution))

if common_ops != validation_ops or common_ops != execution_ops:
    print('ASSERT_COMMON_ONLY', sorted(common_ops - validation_ops - execution_ops))
    print('MISSING_VALIDATION', sorted(common_ops - validation_ops))
    print('EXTRA_VALIDATION', sorted(validation_ops - common_ops))
    print('MISSING_EXECUTION', sorted(common_ops - execution_ops))
    print('EXTRA_EXECUTION', sorted(execution_ops - common_ops))
    raise SystemExit('maintenance operation parity failed')

required = 'migrate_supervisor_forge_demand_gated_v17'
if required not in common_ops:
    raise SystemExit('required Supervisor/Forge migration operation absent')

print('MAINTENANCE_OPERATION_PARITY_PASS operations=' + str(len(common_ops)))
print('operations=' + ','.join(sorted(common_ops)))
