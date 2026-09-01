from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.16.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.17.ps1')
EXPECTED_SRC_SHA256 = '2DBE9FD6A93779CCB26C6BA5A13EBE94EEA56F0BFB3052C58E08B65F2526F8AF'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA256:
    raise SystemExit(f'v1.3.16 source identity mismatch: {actual}')
text = raw.decode('utf-8')

def replace_once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)

replace_once("version='1.3.16'", "version='1.3.17'", 'state version')

old = "        'diagnose_benchmark_baseline_forge_anchor' { Assert-BenchmarkBaselineForgeAnchorDiagnosis $m }\n        default { throw 'operation not allowlisted' }"
new = "        'diagnose_benchmark_baseline_forge_anchor' { Assert-BenchmarkBaselineForgeAnchorDiagnosis $m }\n        'migrate_supervisor_forge_demand_gated_v17' { Assert-SupervisorForgeDemandGateMigration $m }\n        default { throw 'operation not allowlisted' }"
replace_once(old, new, 'typed-validation switch parity')

anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.16 SELFTEST PASS supervisor_forge_migration=fixed baseline_anchor=atomic mutex_protected=true demand_gate=true rollback=true arbitrary_shell=false authority_expansion=false'\n"
insert = anchor + "    Write-Host 'KEVIN MAINTENANCE v1.3.17 SELFTEST PASS operation_parity=fixed supervisor_forge_validation=true arbitrary_shell=false authority_expansion=false'\n"
replace_once(anchor, insert, 'v1.3.17 selftest marker')

OUT.write_text(text, encoding='utf-8', newline='')
sha = hashlib.sha256(OUT.read_bytes()).hexdigest().upper()
print('MAINT_V1317_GENERATED sha256=' + sha)
