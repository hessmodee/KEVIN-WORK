from pathlib import Path
import hashlib

SRC=Path('control-plane/autonomy/kevin-supervisor-v1.8.2.ps1')
OUT=Path('control-plane/autonomy/kevin-supervisor-v1.8.3.ps1')
EXPECTED='9EB3493A91B3B91AFCE05985D368849A98899C2F592C1B12D6EF94471190EE2C'
raw=SRC.read_bytes()
actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED:
    raise SystemExit(f'v1.8.2 identity mismatch {actual}')
text=raw.decode('utf-8')

def once(old,new,label):
    global text
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'{label} anchor count={n}')
    text=text.replace(old,new,1)

once('# Kevin Supervisor v1.8.2 Governed Autonomy Continuation Controller',
     '# Kevin Supervisor v1.8.3 Governed Autonomy Continuation Controller',
     'header')
once("version = '1.8.2'","version = '1.8.3'",'state version')
old="""        $gw = Invoke-OpenClaw @('gateway', 'status', '--deep', '--require-rpc')
        if ($gw.exit_code -ne 0) { throw 'gateway deep probe failed' }
        $message = 'KEVIN_AUTONOMY_CONTINUATION_V1."""
new="""        $gw = $null
        for ($probeAttempt = 1; $probeAttempt -le 3; $probeAttempt++) {
            $gw = Invoke-OpenClaw @('gateway', 'status', '--require-rpc', '--json')
            if ($gw.exit_code -eq 0) { break }
            if ($probeAttempt -lt 3) { Start-Sleep -Milliseconds (500 * $probeAttempt) }
        }
        if ($null -eq $gw -or $gw.exit_code -ne 0) { throw 'gateway RPC probe failed after bounded retries' }
        $mainCheck = Invoke-OpenClaw @('skills', 'check', '--agent', 'main', '--json')
        if ($mainCheck.exit_code -ne 0) { throw 'fixed main agent preflight failed' }
        $message = 'KEVIN_AUTONOMY_CONTINUATION_V1."""
once(old,new,'rpc-only main preflight')
once("$r = Invoke-OpenClaw @('agent', '--json', '--message', $message)",
     "$r = Invoke-OpenClaw @('agent', '--agent', 'main', '--json', '--message', $message)",
     'agent selector')
once("Write-Host 'KEVIN SUPERVISOR v1.8 SELFTEST PASS selector_first=true gateway_agent=true no_forge_dispatch=true anti_spin=true arbitrary_shell=false authority_expansion=false'",
     "Write-Host 'KEVIN SUPERVISOR v1.8.3 SELFTEST PASS selector_first=true gateway_agent=fixed-main gateway_rpc_only=true gateway_probe_retries=3 main_preflight=true no_forge_dispatch=true anti_spin=true arbitrary_shell=false authority_expansion=false'",
     'selftest marker')
OUT.write_text(text,encoding='utf-8',newline='')
print('SUPERVISOR_V183_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
