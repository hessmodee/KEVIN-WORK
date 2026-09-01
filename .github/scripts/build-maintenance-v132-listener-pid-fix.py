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

once("function Invoke-NpmFixed([string[]]$Args,[int]$Timeout=600) {$npm=Get-Command npm.cmd -ErrorAction SilentlyContinue;if(-not$npm){$npm=Get-Command npm -ErrorAction SilentlyContinue};if(-not$npm){throw 'npm unavailable'};return Invoke-FixedNativeBounded ([string]$npm.Source) $Args $Timeout}",
"""function Invoke-NpmFixed([string[]]$Args,[int]$Timeout=600) {
    $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not$node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not$node){throw 'node unavailable for fixed npm runtime'}
    $npmCli=Join-Path (Split-Path -Parent ([string]$node.Source)) 'node_modules\\npm\\bin\\npm-cli.js'
    if(-not(Test-Path -LiteralPath $npmCli -PathType Leaf)){throw 'fixed npm-cli.js unavailable beside Node runtime'}
    return Invoke-FixedNativeBounded ([string]$node.Source) (@($npmCli)+@($Args)) $Timeout
}""",
'native-npm-runtime')

once("    $changed=$false;$launcher=''",
     "    $versionTransitionAttempted=$false;$launcher=''",
     'transition-flag')
once("        if($before-ne$GatewayLkgVersion){Install-ExactOpenClaw $GatewayLkgVersion;$changed=$true}",
     "        if($before-ne$GatewayLkgVersion){$versionTransitionAttempted=$true;Install-ExactOpenClaw $GatewayLkgVersion}",
     'transition-attempt')
once("        $primary=$_.Exception.Message;try{Copy-Item -LiteralPath $savedConfig -Destination $config -Force}catch{};if($changed){try{Assert-NpmIntegrity $GatewayRejectedVersion $GatewayRejectedIntegrity;Install-ExactOpenClaw $GatewayRejectedVersion}catch{}}\n        try{$null=Start-AuthoritativeGateway $top}catch{};try{Assert-Benchmark30}catch{};throw ('OpenClaw Windows LKG recovery rollback completed: '+$primary)",
"""        $primary=$_.Exception.Message;$packageRollbackOk=$true
        try{Copy-Item -LiteralPath $savedConfig -Destination $config -Force}catch{}
        if($versionTransitionAttempted){
            try{Assert-NpmIntegrity $GatewayRejectedVersion $GatewayRejectedIntegrity;Install-ExactOpenClaw $GatewayRejectedVersion;if((Get-InstalledOpenClawVersion)-ne$before){throw 'starting OpenClaw version not restored'}}catch{$packageRollbackOk=$false}
        }
        try{$null=Start-AuthoritativeGateway $top}catch{};try{Assert-Benchmark30}catch{}
        if(-not$packageRollbackOk){throw ('OpenClaw Windows LKG recovery AND exact package rollback failed after: '+$primary)}
        throw ('OpenClaw Windows LKG recovery rollback completed: '+$primary)""",
     'partial-install-rollback')

once("    Write-Host 'KEVIN MAINTENANCE v1.3.31 SELFTEST PASS watchdog_operational_proof=fixed gateway_detail=fixed windows_lkg=2026.6.34 integrity_pinned=true keeper_topology_preserved=true safe_config_backup_required=true rollback=true gateway_rpc_postcondition=true main_skills_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'",
     "    Write-Host 'KEVIN MAINTENANCE v1.3.31 SELFTEST PASS watchdog_operational_proof=fixed gateway_detail=fixed windows_lkg=2026.6.34 integrity_pinned=true keeper_topology_preserved=true safe_config_backup_required=true rollback=true gateway_rpc_postcondition=true main_skills_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'\n    $stopFn=(Get-Command Stop-FixedGatewayListener).ScriptBlock.ToString();if($stopFn -match 'foreach\\(\\$pid\\b'){throw 'read-only PID automatic variable collision retained'};if($stopFn -notmatch '\\$listenerPid'){throw 'listenerPid fixed variable missing'}\n    $npmFn=(Get-Command Invoke-NpmFixed).ScriptBlock.ToString();if($npmFn -match 'npm\\.cmd'){throw 'batch npm launcher retained'};if($npmFn -notmatch 'npm-cli\\.js'){throw 'fixed npm-cli.js runtime missing'}\n    $repairFn=(Get-Command Repair-OpenClawWindowsLkg).ScriptBlock.ToString();if($repairFn -notmatch 'versionTransitionAttempted'){throw 'partial install rollback flag missing'};if($repairFn -notmatch 'starting OpenClaw version not restored'){throw 'exact starting-version rollback verification missing'}\n    Write-Host 'KEVIN MAINTENANCE v1.3.32 SELFTEST PASS gateway_listener_pid_collision=false native_npm_cli=true partial_install_rollback=true fixed_listener_identity_check=true rollback=true arbitrary_shell=false authority_expansion=false'",
     'selftest-marker')
dst.write_text(s,encoding='utf-8',newline='\n')
print(dst)
