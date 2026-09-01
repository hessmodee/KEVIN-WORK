from pathlib import Path
import hashlib

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.20.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.21.ps1')
EXPECTED='737F40049FEA0C16EB8DC17FAA8DBCEE0DE2E7E1CCF7D5DCD353F63EF23DE1AD'
raw=SRC.read_bytes()
actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED:
    raise SystemExit(f'v1.3.20 source identity mismatch: {actual}')
text=raw.decode('utf-8')
if text.count("version='1.3.20'")!=1:
    raise SystemExit('version anchor mismatch')
text=text.replace("version='1.3.20'","version='1.3.21'",1)
needle="Invoke-OpenClawFixedConfig @('cron'"
count=text.count(needle)
if count!=4:
    raise SystemExit(f'expected exactly four continuation cron invocations, found {count}')
text=text.replace(needle,"Invoke-OpenClawFixedConfig @('automations'")
old="Write-Host 'KEVIN MAINTENANCE v1.3.20 SELFTEST PASS native_automation=fixed cadence=5m system_event=true main_session=true arbitrary_shell=false authority_expansion=false'"
if text.count(old)!=1:
    raise SystemExit('v1.3.20 selftest marker mismatch')
new=old+"\n    Write-Host 'KEVIN MAINTENANCE v1.3.21 SELFTEST PASS canonical_automations_cli=true noninteractive_scheduler_adapter=fixed arbitrary_shell=false authority_expansion=false'"
text=text.replace(old,new,1)
OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1321_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
