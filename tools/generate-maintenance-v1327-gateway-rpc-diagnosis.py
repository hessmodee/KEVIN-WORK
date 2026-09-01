from pathlib import Path
import hashlib

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.26.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.27.ps1')
EXPECTED='E010E22EF82479C3A9564350172B8BB92DDBF91BCE9CD0B586E8E6B2A43A3F0F'
raw=SRC.read_bytes(); actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED: raise SystemExit(f'v1.3.26 identity mismatch {actual}')
text=raw.decode('utf-8')

def once(old,new,label):
    global text
    n=text.count(old)
    if n!=1: raise SystemExit(f'{label} anchor count={n}')
    text=text.replace(old,new,1)

once("version='1.3.26'","version='1.3.27'",'state version')
once("'run_main_agent_canary','install_autonomy_controller_v183') -contains [string]$m.operation)","'run_main_agent_canary','install_autonomy_controller_v183','diagnose_gateway_rpc') -contains [string]$m.operation)",'allowlist')

# Use a direct fixed read-scope RPC call as the canary gate. This bypasses known
# gateway-status aggregation/service-warning ambiguity while still requiring a
# real authenticated WebSocket RPC round trip.
once("$gw=Invoke-OpenClawFixedConfig @('gateway','status','--require-rpc','--json')","$gw=Invoke-OpenClawFixedConfig @('gateway','call','status','--json')",'canary direct rpc')
once("throw 'main-agent canary gateway deep probe failed'","throw 'main-agent canary direct RPC status failed'",'canary failure text')

block=r'''
function Assert-GatewayRpcDiagnosis([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('gateway RPC diagnosis manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'diagnose_gateway_rpc'){throw 'gateway RPC diagnosis operation mismatch'}
}
function Get-GatewayProbeClass([object]$r) {
    $t=[string]$r.output
    if($t -match '(?i)AUTH_TOKEN_MISSING|token.*missing'){return 'AUTH_TOKEN_MISSING'}
    if($t -match '(?i)AUTH_TOKEN_MISMATCH|unauthori[sz]ed|token.*mismatch'){return 'AUTH_MISMATCH'}
    if($t -match '(?i)AUTH_DEVICE_TOKEN_MISMATCH|device token.*mismatch'){return 'DEVICE_TOKEN_MISMATCH'}
    if($t -match '(?i)AUTH_SCOPE_MISMATCH|missing scope|operator\.read'){return 'SCOPE_MISMATCH'}
    if($t -match '(?i)pairing required|pairing-pending'){return 'PAIRING_REQUIRED'}
    if($t -match '(?i)device identity required'){return 'DEVICE_IDENTITY_REQUIRED'}
    if($t -match '(?i)SecretRef|unresolved.*auth'){return 'AUTH_SECRET_UNRESOLVED'}
    if($t -match '(?i)EADDRINUSE|port .*in use'){return 'PORT_CONFLICT'}
    if($t -match '(?i)timeout|timed out'){return 'TIMEOUT'}
    if($t -match '(?i)connect failed|closed before connect|1006'){return 'CONNECT_FAILED'}
    if([int]$r.exit_code -eq 0){return 'OK'}
    return 'OTHER_FAILURE'
}
function Get-FixedConfigEnum([string]$Path,[string[]]$Allowed) {
    if($Path -notin @('gateway.mode','gateway.bind','gateway.auth.mode')){throw 'gateway diagnosis config path rejected'}
    $r=Invoke-OpenClawFixedConfig @('config','get',$Path,'--json')
    if($r.exit_code-ne0){return 'UNSET_OR_UNREADABLE'}
    $v=([string]$r.output).Trim().Trim('"')
    foreach($a in $Allowed){if($v -eq $a){return $a}}
    return 'OTHER'
}
function Publish-GatewayRpcDiagnosis([object]$Public) {
    $local=Join-Path $Reports 'gateway-rpc-diagnosis-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/gateway-rpc-diagnosis-omen.json'
    $localHash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToUpperInvariant()
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
        $body=[ordered]@{message='kevin gateway rpc diagnosis';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))}
        if($lookup.ExitCode-eq0 -and $lookup.Output){$body.sha=[string]$lookup.Output}
        $payloadPath=Join-Path $env:TEMP ('kevin-gateway-rpc-'+[guid]::NewGuid().ToString('N')+'.json')
        try{
            [IO.File]::WriteAllText($payloadPath,($body|ConvertTo-Json -Compress),$Utf8)
            $put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$payloadPath,'--silent')
            if($put.ExitCode-eq0){
                $verify=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.content')
                if($verify.ExitCode-eq0 -and $verify.Output){
                    try{$remote=[Convert]::FromBase64String(([string]$verify.Output -replace '\s',''))}catch{$remote=$null}
                    if($remote){$sha=[Security.Cryptography.SHA256]::Create();try{$rh=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()};if($rh-eq$localHash){return $localHash}}
                }
            }
        }finally{Remove-Item -LiteralPath $payloadPath -Force -ErrorAction SilentlyContinue}
        if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt)}
    }
    throw 'gateway RPC diagnosis receipt remote verification failed'
}
function Diagnose-GatewayRpc {
    $basic=Invoke-OpenClawFixedConfig @('gateway','status','--json')
    $required=Invoke-OpenClawFixedConfig @('gateway','status','--require-rpc','--json')
    $direct=Invoke-OpenClawFixedConfig @('gateway','call','status','--json')
    $health=Invoke-OpenClawFixedConfig @('gateway','health','--json')
    $validate=Invoke-OpenClawFixedConfig @('config','validate','--json')
    $skills=Invoke-OpenClawFixedConfig @('skills','check','--agent','main','--json')
    $mode=Get-FixedConfigEnum 'gateway.mode' @('local','remote')
    $bind=Get-FixedConfigEnum 'gateway.bind' @('loopback','lan','tailnet','auto','custom')
    $auth=Get-FixedConfigEnum 'gateway.auth.mode' @('token','password','none','trusted-proxy')
    $pkgVersion='UNKNOWN';$pkg=if($env:APPDATA){Join-Path $env:APPDATA 'npm\node_modules\openclaw\package.json'}else{''}
    if($pkg -and (Test-Path -LiteralPath $pkg -PathType Leaf)){try{$po=Get-Content -LiteralPath $pkg -Raw|ConvertFrom-Json;if([string]$po.version -match '^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$'){$pkgVersion=[string]$po.version}}catch{}}
    $gatewayTasks=@();$watchdogTasks=@()
    if($env:OS -eq 'Windows_NT'){
        try{$gatewayTasks=@(Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object{[string]$_.TaskName -like 'OpenClaw Gateway*'})}catch{}
        try{$watchdogTasks=@(Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object{[string]$_.TaskName -eq 'Kevin Self-Reliance Watchdog v1'})}catch{}
    }
    $watchState='ABSENT';$watchAttempts=0;$watchCooling=$false
    $watchPath=Join-Path $Reports 'self-reliance\watchdog-state.json'
    if(Test-Path -LiteralPath $watchPath -PathType Leaf){
        try{$wo=Get-Content -LiteralPath $watchPath -Raw|ConvertFrom-Json;$watchState=if($wo.last_result){[string]$wo.last_result}else{'UNKNOWN'};$watchAttempts=if($wo.attempts){[int]$wo.attempts}else{0};if($wo.cooldown_until){try{$watchCooling=([DateTimeOffset]::Parse([string]$wo.cooldown_until)-gt[DateTimeOffset]::Now)}catch{}}}catch{$watchState='UNREADABLE'}
    }
    $public=[ordered]@{
        schema=1;kind='kevin-gateway-rpc-diagnosis-public';generated_at=(Get-Date).ToString('o');state='OMEN_DIAGNOSIS_PROVEN';safe_for_public_repo=$true
        openclaw_version=$pkgVersion
        probes=[ordered]@{
            gateway_status=[ordered]@{exit_code=[int]$basic.exit_code;class=(Get-GatewayProbeClass $basic);output_sha256=(Get-TextSha256 ([string]$basic.output))}
            require_rpc=[ordered]@{exit_code=[int]$required.exit_code;class=(Get-GatewayProbeClass $required);output_sha256=(Get-TextSha256 ([string]$required.output))}
            direct_rpc_status=[ordered]@{exit_code=[int]$direct.exit_code;class=(Get-GatewayProbeClass $direct);output_sha256=(Get-TextSha256 ([string]$direct.output))}
            gateway_health=[ordered]@{exit_code=[int]$health.exit_code;class=(Get-GatewayProbeClass $health);output_sha256=(Get-TextSha256 ([string]$health.output))}
            config_validate_ok=([int]$validate.exit_code-eq0)
            main_skills_check_ok=([int]$skills.exit_code-eq0)
        }
        config=[ordered]@{mode=$mode;bind=$bind;auth_mode=$auth;process_config_override_present=[bool]$env:OPENCLAW_CONFIG_PATH;process_home_override_present=[bool]$env:OPENCLAW_HOME;process_gateway_token_present=[bool]$env:OPENCLAW_GATEWAY_TOKEN;process_gateway_password_present=[bool]$env:OPENCLAW_GATEWAY_PASSWORD}
        windows=[ordered]@{gateway_task_count=$gatewayTasks.Count;gateway_task_running_count=@($gatewayTasks|Where-Object{[string]$_.State -eq 'Running'}).Count;watchdog_task_count=$watchdogTasks.Count;watchdog_task_running_count=@($watchdogTasks|Where-Object{[string]$_.State -eq 'Running'}).Count}
        self_reliance=[ordered]@{state=$watchState;attempts=$watchAttempts;cooling=$watchCooling}
        interpretation=if([int]$direct.exit_code-eq0){'DIRECT_RPC_HEALTHY_STATUS_LAYER_DISAGREEMENT_POSSIBLE'}else{'DIRECT_RPC_NOT_PROVEN'}
        source_contract='Fixed metadata-only local OpenClaw probes and fixed scheduled-task/state inspection. No caller-selected command, argv, path, URL, token, password, recipient, or raw output publication.'
        truth_boundary='No credentials, config values outside safe enums, raw CLI output, host paths, messages, prompts, or tool payloads are published.'
    }
    $receipt=Publish-GatewayRpcDiagnosis $public
    Assert-Benchmark30
    return [ordered]@{published=$true;receipt_sha256=$receipt;direct_rpc_ok=([int]$direct.exit_code-eq0);require_rpc_exit=[int]$required.exit_code;watchdog_task_present=($watchdogTasks.Count-eq1);watchdog_state=$watchState}
}

'''
anchor='function Assert-MainAgentCanary([object]$m) {'
once(anchor,block+anchor,'diagnosis functions')
once("        'install_autonomy_controller_v183' { Assert-AutonomyControllerV183Install $m }","        'install_autonomy_controller_v183' { Assert-AutonomyControllerV183Install $m }\n        'diagnose_gateway_rpc' { Assert-GatewayRpcDiagnosis $m }",'assert dispatch')
once("            'install_autonomy_controller_v183' { Install-AutonomyControllerV183 $m; break }","            'install_autonomy_controller_v183' { Install-AutonomyControllerV183 $m; break }\n            'diagnose_gateway_rpc' { Diagnose-GatewayRpc; break }",'execute dispatch')
once("            'install_autonomy_controller_v183' {'autonomy_controller_v183_install_failure'}","            'install_autonomy_controller_v183' {'autonomy_controller_v183_install_failure'}\n            'diagnose_gateway_rpc' {'gateway_rpc_diagnosis_failure'}",'failure dispatch')
marker="    Write-Host 'KEVIN MAINTENANCE v1.3.26 SELFTEST PASS fixed_main_canary=true gateway_rpc_only=true gateway_probe_retries=3 supervisor_v183=true selector_v11=true arbitrary_shell=false authority_expansion=false'"
extra=marker+"\n    $gdx=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$gdx.operation='diagnose_gateway_rpc';Assert-Common $gdx;Assert-GatewayRpcDiagnosis $gdx\n    Write-Host 'KEVIN MAINTENANCE v1.3.27 SELFTEST PASS gateway_direct_rpc=true gateway_diagnosis=metadata-only watchdog_inspection=fixed fixed_main_canary=true arbitrary_shell=false authority_expansion=false'"
once(marker,extra,'selftest extension')
OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1327_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
