from pathlib import Path

src=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.31.ps1')
dst=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.32.ps1')
s=src.read_text(encoding='utf-8')

def once(old,new,label):
    global s
    n=s.count(old)
    if n!=1:
        raise SystemExit(f'{label}: expected one anchor, got {n}')
    s=s.replace(old,new,1)

once("version='1.3.31'","version='1.3.32'",'state-version')
old="""    foreach($pid in @($conns|Select-Object -ExpandProperty OwningProcess -Unique)){
        if(-not$pid){continue}
        $p=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$pid) -ErrorAction SilentlyContinue
        $cmd=if($p){[string]$p.CommandLine}else{''}
        if($cmd -notmatch '(?i)openclaw.*dist[\\\\/].*index\\.js.*(?:^|\\s)gateway(?:\\s|$)'){throw 'Port 18789 listener is not recognized as fixed OpenClaw Gateway'}
        Stop-Process -Id ([int]$pid) -Force -ErrorAction Stop
    }"""
new="""    foreach($listenerPid in @($conns|Select-Object -ExpandProperty OwningProcess -Unique)){
        if(-not$listenerPid){continue}
        $p=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$listenerPid) -ErrorAction SilentlyContinue
        $cmd=if($p){[string]$p.CommandLine}else{''}
        if($cmd -notmatch '(?i)openclaw.*dist[\\\\/].*index\\.js.*(?:^|\\s)gateway(?:\\s|$)'){throw 'Port 18789 listener is not recognized as fixed OpenClaw Gateway'}
        Stop-Process -Id ([int]$listenerPid) -Force -ErrorAction Stop
    }"""
once(old,new,'listener-pid-loop')
once("    Write-Host 'KEVIN MAINTENANCE v1.3.31 SELFTEST PASS watchdog_operational_proof=fixed gateway_detail=fixed windows_lkg=2026.6.34 integrity_pinned=true keeper_topology_preserved=true safe_config_backup_required=true rollback=true gateway_rpc_postcondition=true main_skills_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'",
     "    Write-Host 'KEVIN MAINTENANCE v1.3.31 SELFTEST PASS watchdog_operational_proof=fixed gateway_detail=fixed windows_lkg=2026.6.34 integrity_pinned=true keeper_topology_preserved=true safe_config_backup_required=true rollback=true gateway_rpc_postcondition=true main_skills_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'\n    $stopFn=(Get-Command Stop-FixedGatewayListener).ScriptBlock.ToString();if($stopFn -match 'foreach\\(\\$pid\\b'){throw 'read-only PID automatic variable collision retained'};if($stopFn -notmatch '\\$listenerPid'){throw 'listenerPid fixed variable missing'}\n    Write-Host 'KEVIN MAINTENANCE v1.3.32 SELFTEST PASS gateway_listener_pid_collision=false fixed_listener_identity_check=true rollback=true arbitrary_shell=false authority_expansion=false'",
     'selftest-marker')
dst.write_text(s,encoding='utf-8',newline='\n')
print(dst)
