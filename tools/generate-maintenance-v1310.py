from pathlib import Path

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.9.ps1')
DST=Path('control-plane/maintenance/generated/kevin-maintenance-runner-v1.3.10.ps1')
text=SRC.read_text(encoding='utf-8')

def once(old,new):
    global text
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'expected exactly one marker, got {n}: {old!r}')
    text=text.replace(old,new,1)

once("version='1.3.9'","version='1.3.10'")
once("@('config','set',$modePath,'propose','--dry-run','--json')","@('config','set',$modePath,'propose','--dry-run')")
once("@('config','set',$approvalPath,'pending','--dry-run','--json')","@('config','set',$approvalPath,'pending','--dry-run')")
once(
    "    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS reader_canary=2_trials fixed_reader_prompt=true exact_tool_calls=1 semantic_categories=6 privacy_gate=true workshop_guardrails=propose_pending arbitrary_shell=false authority_expansion=false max_attempts=3'",
    "    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS compatibility=v1.3.10'\n    Write-Host 'KEVIN MAINTENANCE v1.3.10 SELFTEST PASS workshop_dry_run_raw_string=true workshop_guardrails=propose_pending reader_canary=2_trials fixed_reader_prompt=true exact_tool_calls=1 semantic_categories=6 privacy_gate=true arbitrary_shell=false authority_expansion=false max_attempts=3'"
)

DST.parent.mkdir(parents=True,exist_ok=True)
DST.write_text(text,encoding='utf-8',newline='\n')
print(DST)
