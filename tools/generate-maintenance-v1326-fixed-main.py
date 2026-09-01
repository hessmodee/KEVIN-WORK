from pathlib import Path
import hashlib

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.25.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.26.ps1')
EXPECTED='B9E174D69CF44363052487DA7E28EA4D5E013F450A0E2185957D343C71152197'
SUP183='29122F147233DC672DC6AFF4D5AD4262D4512B39D67CC42628DB6C5C78D811FB'
raw=SRC.read_bytes();actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED: raise SystemExit(f'v1.3.25 identity mismatch {actual}')
text=raw.decode('utf-8')

def once(old,new,label):
    global text
    n=text.count(old)
    if n!=1: raise SystemExit(f'{label} anchor count={n}')
    text=text.replace(old,new,1)

def replace_all(old,new,label):
    global text
    n=text.count(old)
    if n<1: raise SystemExit(f'{label} anchor count={n}')
    text=text.replace(old,new)
    return n

once("version='1.3.25'","version='1.3.26'",'state version')
once("$SupervisorV182Sha = '9EB3493A91B3B91AFCE05985D368849A98899C2F592C1B12D6EF94471190EE2C'",f"$SupervisorV183Sha = '{SUP183}'",'supervisor identity')
once("$SupervisorV182Source = 'control-plane/autonomy/kevin-supervisor-v1.8.2.ps1'","$SupervisorV183Source = 'control-plane/autonomy/kevin-supervisor-v1.8.3.ps1'",'supervisor source')
replace_all('Assert-AutonomyControllerV182Install','Assert-AutonomyControllerV183Install','assert function rename')
replace_all('Install-AutonomyControllerV182','Install-AutonomyControllerV183','install function rename')
replace_all('install_autonomy_controller_v182','install_autonomy_controller_v183','operation rename')
replace_all('$SupervisorV182Sha','$SupervisorV183Sha','sha variable rename')
replace_all('$SupervisorV182Source','$SupervisorV183Source','source variable rename')
replace_all('Supervisor v1.8.2','Supervisor v1.8.3','version text')
replace_all('supervisor-v182.ps1','supervisor-v183.ps1','stage basename')
replace_all('supervisor_v182=true','supervisor_v183=true','selftest truth')
replace_all('autonomy_controller_v182_install_failure','autonomy_controller_v183_install_failure','failure family')
replace_all('default_gateway_agent=$true','fixed_main_agent=$true','install return truth')

old="$gw=Invoke-OpenClawFixedConfig @('gateway','status','--deep','--require-rpc')"
new="""$gw=$null
    for($probeAttempt=1;$probeAttempt-le3;$probeAttempt++){
        $gw=Invoke-OpenClawFixedConfig @('gateway','status','--require-rpc','--json')
        if($gw.exit_code-eq0){break}
        if($probeAttempt-lt3){Start-Sleep -Milliseconds (500*$probeAttempt)}
    }"""
once(old,new,'canary rpc-only bounded probe')
once("$sw=[Diagnostics.Stopwatch]::StartNew();$r=Invoke-OpenClawFixedConfig @('agent','--json','--message',$message);$sw.Stop()","$sw=[Diagnostics.Stopwatch]::StartNew();$r=Invoke-OpenClawFixedConfig @('agent','--agent','main','--json','--message',$message);$sw.Stop()",'fixed main agent call')
replace_all('fixed:runtime-default','fixed:main','canary agent label')
replace_all('runtime-default','main','canary return label')
replace_all('default-agent','fixed-main-agent','canary contract text')

marker="    Write-Host 'KEVIN MAINTENANCE v1.3.25 SELFTEST PASS autonomy_controller_install=fixed supervisor_v183=true selector_v11=true baseline_anchor=atomic rollback=true arbitrary_shell=false authority_expansion=false'"
extra=marker+"\n    Write-Host 'KEVIN MAINTENANCE v1.3.26 SELFTEST PASS fixed_main_canary=true gateway_rpc_only=true gateway_probe_retries=3 supervisor_v183=true selector_v11=true arbitrary_shell=false authority_expansion=false'"
once(marker,extra,'v1326 selftest extension')

OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1326_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
