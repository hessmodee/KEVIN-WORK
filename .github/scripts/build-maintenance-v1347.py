#!/usr/bin/env python3
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parents[2]
src = root / 'control-plane' / 'maintenance' / 'kevin-maintenance-runner-v1.3.46.ps1'
out = root / 'control-plane' / 'maintenance' / 'kevin-maintenance-runner-v1.3.47.ps1'
text = src.read_text(encoding='utf-8-sig')
repls = [
    ("version='1.3.46'", "version='1.3.47'"),
    ("$old='3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E'", "$old='AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D'"),
    ("$new='AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D'", "$new='82C47FAD288CA6FFD69EEF5678C8262065F04C739AACCACEE889005486A5FA15'"),
    ("installed Maintenance identity is not qualified v1.3.45 actual=", "installed Maintenance identity is not qualified v1.3.46 actual="),
    ("KEVIN MAINTENANCE v1.3.46 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=fixed_v18_cas_rollback arbitrary_shell=false authority_expansion=false", "KEVIN MAINTENANCE v1.3.46 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=fixed_v18_cas_rollback arbitrary_shell=false authority_expansion=false'\n    Write-Host 'KEVIN MAINTENANCE v1.3.47 SELFTEST PASS desired_state_sync=current_maintenance_identity_v1346 arbitrary_shell=false authority_expansion=false")
]
for old, new in repls:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'anchor count mismatch for {old[:80]!r}: {count}')
    text = text.replace(old, new)
# The replacement above intentionally inserted quote framing around the old selftest marker; normalize exact PowerShell lines.
text = text.replace("Write-Host 'KEVIN MAINTENANCE v1.3.46 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=fixed_v18_cas_rollback arbitrary_shell=false authority_expansion=false'\n    Write-Host 'KEVIN MAINTENANCE v1.3.47 SELFTEST PASS desired_state_sync=current_maintenance_identity_v1346 arbitrary_shell=false authority_expansion=false'", "Write-Host 'KEVIN MAINTENANCE v1.3.46 SELFTEST PASS cron_get_wrapper=true ui_watchdog_ps1_stage=true autonomy_blocker_truth=true desired_state_sync=fixed_v18_cas_rollback arbitrary_shell=false authority_expansion=false'\n    Write-Host 'KEVIN MAINTENANCE v1.3.47 SELFTEST PASS desired_state_sync=current_maintenance_identity_v1346 arbitrary_shell=false authority_expansion=false'")
out.write_text(text, encoding='utf-8', newline='\n')
sha = hashlib.sha256(out.read_bytes()).hexdigest().upper()
print(f'BUILT {out.relative_to(root)} SHA256={sha}')
