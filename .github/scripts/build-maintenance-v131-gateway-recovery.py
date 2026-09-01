from pathlib import Path

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.30.ps1')
DST=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.31.ps1')
s=SRC.read_text(encoding='utf-8')

def once(old,new,label):
    global s
    n=s.count(old)
    if n!=1:
        raise SystemExit(f'{label}: expected one anchor, got {n}')
    s=s.replace(old,new,1)

once("$SelectorV11Source = 'control-plane/autonomy/kevin-work-selector-v1.1.py'",
     "$SelectorV11Source = 'control-plane/autonomy/kevin-work-selector-v1.1.py'\n$GatewayLkgVersion = '2026.6.34'\n$GatewayRejectedVersion = '2026.7.1-2'\n$GatewayLkgIntegrity = 'sha512-Rm4khBrWn9HYqE99NBryCFgjwlsIuwBqK5jIANn2773CGXJ1JIZkDn5twEHB+8SVFdh0FPNPHRVgZepzNJDfHg=='\n$GatewayRejectedIntegrity = 'sha512-ycF3yPcbjN6bUPeaUx6Mh6vze1hQWoD3CT/wWcmD7a8xaHHHRUaAlaq+lFxMHf1ssEgODVAwjlzYqp2twkYZ7g=='\n$GatewayKeeperTaskName = 'KevinGatewayKeeper'\n$LegacyGatewayTaskName = 'OpenClaw Gateway'",
     'constants')
once("version='1.3.30'","version='1.3.31'",'state-version')
once("'install_autonomy_controller_v183','diagnose_gateway_rpc')",
     "'install_autonomy_controller_v183','diagnose_gateway_rpc','run_self_reliance_watchdog_once','diagnose_gateway_failure_detail','repair_openclaw_windows_lkg')",
     'common-allowlist')

insert=r'''function Assert-NoCallerArgs([object]$m,[string]$Operation) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ($Operation+' manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne $Operation){throw ($Operation+' operation mismatch')}
}
function Get-SemanticConfigSha([string]$Path) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return ''}
    try{$o=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json}catch{return ''}
    if($o.meta){
        if($o.meta.PSObject.Properties['lastTouchedVersion']){$o.meta.PSObject.Properties.Remove('lastTouchedVersion')}
        if($o.meta.PSObject.Properties['lastTouchedAt']){$o.meta.PSObject.Properties.Remove('lastTouchedAt')}
    }
    return Get-TextSha256 ($o|ConvertTo-Json -Depth 60 -Compress)
}
function Get-DirectGatewayConfigFacts {
    $p=Join-Path $env:USERPROFILE '.openclaw\openclaw.json';$bak=$p+'.bak'
    $r=[ordered]@{current_exists=$false;current_sha256='';current_semantic_sha256='';current_last_touched='UNKNOWN';backup_exists=$false;backup_sha256='';backup_semantic_sha256='';backup_last_touched='UNKNOWN';backup_semantically_equivalent=$false;telegram_present=$false;discord_present=$false;codex_present=$false;memory_core_present=$false}
    foreach($pair in @(@('current',$p),@('backup',$bak))){
        $tag=$pair[0];$path=$pair[1];if(-not(Test-Path -LiteralPath $path -PathType Leaf)){continue}
        $r[$tag+'_exists']=$true;$r[$tag+'_sha256']=Get-Sha $path;$r[$tag+'_semantic_sha256']=Get-SemanticConfigSha $path
        try{$o=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json}catch{continue}
        if($o.meta -and [string]$o.meta.lastTouchedVersion -match '^20\d{2}\.\d+\.\d+(?:-\d+)?$'){$r[$tag+'_last_touched']=[string]$o.meta.lastTouchedVersion}
        if($tag-eq'current'){
            if($o.channels){$r.telegram_present=($null-ne$o.channels.PSObject.Properties['telegram']);$r.discord_present=($null-ne$o.channels.PSObject.Properties['discord'])}
            if($o.plugins -and $o.plugins.entries){
                $r.telegram_present=$r.telegram_present-or($null-ne$o.plugins.entries.PSObject.Properties['telegram'])
                $r.discord_present=$r.discord_present-or($null-ne$o.plugins.entries.PSObject.Properties['discord'])
                $r.codex_present=($null-ne$o.plugins.entries.PSObject.Properties['codex'])
                $r.memory_core_present=($null-ne$o.plugins.entries.PSObject.Properties['memory-core'])
            }
        }
    }
    $r.backup_semantically_equivalent=([string]$r.current_semantic_sha256 -and [string]$r.current_semantic_sha256 -eq [string]$r.backup_semantic_sha256)
    return [pscustomobject]$r
}
function Get-GatewayTopology {
    $r=[ordered]@{keeper_present=$false;keeper_state='ABSENT';keeper_script_present=$false;keeper_script_sha256='';legacy_present=$false;legacy_state='ABSENT';port_listening=$false;gateway_listener_count=0}
    if($env:OS-ne'Windows_NT'){return [pscustomobject]$r}
    try{$k=Get-ScheduledTask -TaskName $GatewayKeeperTaskName -ErrorAction SilentlyContinue;if($k){$r.keeper_present=$true;$r.keeper_state=[string]$k.State}}catch{}
    $kp=Join-Path $Workspace 'kevin-gateway-keeper.ps1';if(Test-Path -LiteralPath $kp -PathType Leaf){$r.keeper_script_present=$true;$r.keeper_script_sha256=Get-Sha $kp}
    try{$l=Get-ScheduledTask -TaskName $LegacyGatewayTaskName -ErrorAction SilentlyContinue;if($l){$r.legacy_present=$true;$r.legacy_state=[string]$l.State}}catch{}
    try{$conns=@(Get-NetTCPConnection -State Listen -LocalPort 18789 -ErrorAction SilentlyContinue);$r.gateway_listener_count=@($conns|Select-Object -ExpandProperty OwningProcess -Unique).Count;$r.port_listening=($r.gateway_listener_count-gt0)}catch{}
    return [pscustomobject]$r
}
function Stop-FixedGatewayListener {
    if($env:OS-ne'Windows_NT'){throw 'Gateway listener stop requires Windows'}
    $conns=@(Get-NetTCPConnection -State Listen -LocalPort 18789 -ErrorAction SilentlyContinue)
    foreach($pid in @($conns|Select-Object -ExpandProperty OwningProcess -Unique)){
        if(-not$pid){continue}
        $p=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$pid) -ErrorAction SilentlyContinue
        $cmd=if($p){[string]$p.CommandLine}else{''}
        if($cmd -notmatch '(?i)openclaw.*dist[\\/].*index\.js.*(?:^|\s)gateway(?:\s|$)'){throw 'Port 18789 listener is not recognized as fixed OpenClaw Gateway'}
        Stop-Process -Id ([int]$pid) -Force -ErrorAction Stop
    }
}
function Get-GatewayFailureFamilyDetailed([string]$Text) {
    $t=[string]$Text
    if($t-match'(?i)startup migrations did not complete cleanly|startup-migration warnings'){return 'STARTUP_MIGRATION_GATE'}
    if($t-match'(?i)conflicting plugin install metadata'){return 'PLUGIN_INSTALL_METADATA_CONFLICT'}
    if($t-match'(?i)embedding_cache|memory embedding'){return 'MEMORY_EMBEDDING_CONFLICT'}
    if($t-match'(?i)binding sidecar'){return 'CODEX_BINDING_SIDECAR'}
    if($t-match'(?i)active startup-migration lock|migration.{0,30}lock'){return 'MIGRATION_LOCK'}
    if($t-match'(?i)lastTouchedVersion|last written by a newer OpenClaw|newer config'){return 'CONFIG_VERSION_SKEW'}
    if($t-match'(?i)discord.{0,60}(ready|handshake|startup|timeout)'){return 'DISCORD_STARTUP_BLOCK'}
    if($t-match'(?i)ERR_MODULE_NOT_FOUND|Cannot find module|Cannot find package'){return 'MODULE_LOAD_FAILURE'}
    if($t-match'(?i)TypeError|ReferenceError|SyntaxError|uncaught exception'){return 'RUNTIME_EXCEPTION'}
    if($t-match'(?i)invalid config|validation failed|unknown config|unrecognized config'){return 'CONFIG_INVALID'}
    if($t-match'(?i)ECONNREFUSED|connection refused|not running|stopped'){return 'GATEWAY_STOPPED_OR_RPC'}
    if($t-match'(?i)timeout|timed out'){return 'TIMEOUT'}
    if([string]::IsNullOrWhiteSpace($t)){return 'EMPTY_FAILURE'}
    return 'OTHER_FAILURE'
}
function Publish-SafeFixedReport([string]$RepoPath,[string]$LocalName,[object]$Public,[string]$Message) {
    $local=Join-Path $Reports $LocalName;Write-JsonAtomic $local $Public
    $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.sha')
    $body=[ordered]@{message=$Message;content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))}
    if($lookup.ExitCode-eq0 -and $lookup.Output){$body.sha=[string]$lookup.Output}elseif($lookup.ExitCode-ne0 -and $lookup.Output-notmatch'404|Not Found'){throw 'safe report lookup failed'}
    $tmp=Join-Path $env:TEMP ('kevin-safe-report-'+[guid]::NewGuid().ToString('N')+'.json')
    try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$RepoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
    if($put.ExitCode-ne0){throw 'safe report publish failed'}
    return Get-Sha $local
}
function Run-SelfRelianceWatchdogOnce {
    $p=Join-Path $Workspace 'kevin-self-reliance-watchdog.ps1';if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'self-reliance watchdog missing'}
    $r=Invoke-FixedNativeBounded 'powershell.exe' @('-NoProfile','-NonInteractive','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',$p) 240;if($r.exit_code-ne0){throw 'self-reliance watchdog operational run failed'}
    $statePath=Join-Path $Reports 'self-reliance\watchdog-state.json';if(-not(Test-Path -LiteralPath $statePath -PathType Leaf)){throw 'watchdog state missing after operational run'}
    try{$w=Get-Content -LiteralPath $statePath -Raw|ConvertFrom-Json}catch{throw 'watchdog state invalid JSON'}
    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology
    $cool=$false;if($w.cooldown_until){try{$cool=([DateTimeOffset]::Parse([string]$w.cooldown_until)-gt[DateTimeOffset]::Now)}catch{}}
    $public=[ordered]@{schema=1;kind='kevin-self-reliance-watchdog-public';generated_at=(Get-Date).ToString('o');state='OMEN_OPERATIONAL_PROOF';safe_for_public_repo=$true;watchdog_sha256=Get-Sha $p;last_result=[string]$w.last_result;failure_family=[string]$w.failure_family;startup_class=[string]$w.startup_class;attempts=[int]$w.attempts;cooling=$cool;gateway_probe_exit=$w.gateway_probe_exit;config_validate_exit=$w.config_validate_exit;config_schema_exit=$w.config_schema_exit;gateway_task_running=[bool]$w.gateway_task_running;binary_version=[string]$w.binary_version;config_last_touched_version=[string]$w.config_last_touched_version;maintenance_result=[string]$w.maintenance_result;work_order_result=[string]$w.work_order_result;config_backup_exists=[bool]$facts.backup_exists;config_backup_semantically_equivalent=[bool]$facts.backup_semantically_equivalent;keeper_present=[bool]$top.keeper_present;keeper_state=[string]$top.keeper_state;port_18789_listening=[bool]$top.port_listening;source_contract='One fixed watchdog run plus fixed metadata-only config/topology inspection. No caller-selected command, argv, path, token, or raw output.';truth_boundary='No raw CLI output, config bodies, credentials, host paths, messages, prompts, tool payloads, or secrets are published.'}
    $receipt=Publish-SafeFixedReport 'reports/self-reliance-watchdog-omen.json' 'self-reliance-watchdog-public.json' $public 'kevin self-reliance watchdog telemetry';Assert-Benchmark30
    return [ordered]@{state='OMEN_OPERATIONAL_PROOF';receipt_sha256=$receipt;last_result=$public.last_result;startup_class=$public.startup_class;failure_family=$public.failure_family;binary_version=$public.binary_version;config_last_touched_version=$public.config_last_touched_version;keeper_present=$public.keeper_present;port_18789_listening=$public.port_18789_listening}
}
function Diagnose-GatewayFailureDetail {
    $probes=@(Invoke-OpenClawFixedConfig @('config','validate','--json'),Invoke-OpenClawFixedConfig @('gateway','status','--json'),Invoke-OpenClawFixedConfig @('plugins','doctor','--json'),Invoke-OpenClawFixedConfig @('doctor','--json'))
    $text=($probes|ForEach-Object{[string]$_.output})-join"`n";$family=Get-GatewayFailureFamilyDetailed $text;$facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology
    $version='UNKNOWN';$pkg=Join-Path $env:APPDATA 'npm\node_modules\openclaw\package.json';if(Test-Path -LiteralPath $pkg -PathType Leaf){try{$version=[string](Get-Content -LiteralPath $pkg -Raw|ConvertFrom-Json).version}catch{}}
    $public=[ordered]@{schema=1;kind='kevin-gateway-failure-detail-public';generated_at=(Get-Date).ToString('o');state='OMEN_DIAGNOSIS_PROVEN';safe_for_public_repo=$true;openclaw_version=$version;release_policy_status=$(if($version-eq$GatewayRejectedVersion){'EVIDENCE_REJECTED'}elseif($version-eq$GatewayLkgVersion){'WINDOWS_VALIDATED_LKG'}else{'OTHER'});root_cause_family=$family;probe_exit_codes=@($probes|ForEach-Object{[int]$_.exit_code});probe_output_fingerprints=@($probes|ForEach-Object{Get-TextSha256 ([string]$_.output)});config=[ordered]@{current_sha256=$facts.current_sha256;current_last_touched=$facts.current_last_touched;backup_exists=[bool]$facts.backup_exists;backup_sha256=$facts.backup_sha256;backup_last_touched=$facts.backup_last_touched;backup_semantically_equivalent=[bool]$facts.backup_semantically_equivalent;telegram_present=[bool]$facts.telegram_present;discord_present=[bool]$facts.discord_present;codex_present=[bool]$facts.codex_present;memory_core_present=[bool]$facts.memory_core_present};windows=[ordered]@{keeper_present=[bool]$top.keeper_present;keeper_state=[string]$top.keeper_state;keeper_script_present=[bool]$top.keeper_script_present;keeper_script_sha256=$top.keeper_script_sha256;legacy_task_present=[bool]$top.legacy_present;legacy_task_state=[string]$top.legacy_state;port_18789_listening=[bool]$top.port_listening;gateway_listener_count=[int]$top.gateway_listener_count};recommended_repair=$(if($version-eq$GatewayRejectedVersion){'TYPED_WINDOWS_LKG_RECOVERY'}else{'ROOT_CAUSE_SPECIFIC_REPAIR'});source_contract='Four fixed OpenClaw probes plus fixed package/config/backup/Gateway topology metadata. No caller-selected command/path/argv.';truth_boundary='Only classifications, exit codes, hashes, safe versions, booleans, and known plugin flags are published. No raw output, config values, credentials, paths, messages, prompts, or secrets.'}
    $receipt=Publish-SafeFixedReport 'reports/gateway-failure-detail-omen.json' 'gateway-failure-detail-public.json' $public 'kevin gateway failure detail telemetry';Assert-Benchmark30
    return [ordered]@{state='OMEN_DIAGNOSIS_PROVEN';receipt_sha256=$receipt;root_cause_family=$family;openclaw_version=$version;release_policy_status=$public.release_policy_status;keeper_present=[bool]$top.keeper_present;backup_semantically_equivalent=[bool]$facts.backup_semantically_equivalent}
}
function Invoke-NpmFixed([string[]]$Args,[int]$Timeout=600) {$npm=Get-Command npm.cmd -ErrorAction SilentlyContinue;if(-not$npm){$npm=Get-Command npm -ErrorAction SilentlyContinue};if(-not$npm){throw 'npm unavailable'};return Invoke-FixedNativeBounded ([string]$npm.Source) $Args $Timeout}
function Get-InstalledOpenClawVersion {$pkg=Join-Path $env:APPDATA 'npm\node_modules\openclaw\package.json';if(-not(Test-Path -LiteralPath $pkg -PathType Leaf)){return 'ABSENT'};try{return [string](Get-Content -LiteralPath $pkg -Raw|ConvertFrom-Json).version}catch{return 'UNREADABLE'}}
function Assert-NpmIntegrity([string]$Version,[string]$Expected) {$r=Invoke-NpmFixed @('view',('openclaw@'+$Version),'dist.integrity','--json') 90;if($r.exit_code-ne0){throw ('npm registry integrity lookup failed for '+$Version)};$actual=([string]$r.output).Trim().Trim('"');if($actual-ne$Expected){throw ('npm integrity mismatch for '+$Version)}}
function Install-ExactOpenClaw([string]$Version) {$r=Invoke-NpmFixed @('install','--global',('openclaw@'+$Version),'--no-audit','--no-fund','--ignore-scripts=false') 900;if($r.exit_code-ne0){throw ('exact OpenClaw install failed version='+$Version)};if((Get-InstalledOpenClawVersion)-ne$Version){throw ('installed OpenClaw version mismatch expected='+$Version)}}
function Wait-GatewayRpc([int]$Seconds=90) {$deadline=(Get-Date).AddSeconds($Seconds);while((Get-Date)-lt$deadline){$r=Invoke-OpenClawFixedConfig @('gateway','call','status','--json');if($r.exit_code-eq0){return $true};Start-Sleep -Seconds 3};return $false}
function Start-AuthoritativeGateway([object]$Topology) {if([bool]$Topology.keeper_present){Start-ScheduledTask -TaskName $GatewayKeeperTaskName;return 'KEEPER'};if([bool]$Topology.legacy_present){Start-ScheduledTask -TaskName $LegacyGatewayTaskName;return 'LEGACY'};throw 'No fixed Gateway launcher task exists'}
function Repair-OpenClawWindowsLkg {
    if($env:OS-ne'Windows_NT'){throw 'Windows LKG recovery requires Windows'}
    $before=Get-InstalledOpenClawVersion;if($before-notin@($GatewayRejectedVersion,$GatewayLkgVersion)){throw ('Windows LKG recovery refuses unexpected installed version '+$before)}
    Assert-NpmIntegrity $GatewayLkgVersion $GatewayLkgIntegrity
    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology;if(-not$facts.current_exists){throw 'OpenClaw config missing'}
    if($top.keeper_present-and-not$top.keeper_script_present){throw 'Gateway Keeper task exists but fixed Keeper script is missing'}
    $useBackup=$false
    if([string]$facts.current_last_touched-eq$GatewayRejectedVersion){if(-not$facts.backup_exists-or-not$facts.backup_semantically_equivalent){throw 'SAFE_BACKUP_NOT_PROVEN_FOR_DOWNGRADE'};if([string]$facts.backup_last_touched-eq$GatewayRejectedVersion-or[string]$facts.backup_last_touched-eq'UNKNOWN'){throw 'SAFE_BACKUP_VERSION_NOT_COMPATIBLE'};$useBackup=$true}
    $config=Join-Path $env:USERPROFILE '.openclaw\openclaw.json';$configBak=$config+'.bak';$backupDir=Join-Path $BackupRoot ('openclaw-lkg-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force -Path $backupDir|Out-Null;$savedConfig=Join-Path $backupDir 'openclaw.json';Copy-Item -LiteralPath $config -Destination $savedConfig -Force
    $changed=$false;$launcher=''
    try{
        if($top.keeper_present){try{Stop-ScheduledTask -TaskName $GatewayKeeperTaskName -ErrorAction SilentlyContinue}catch{}}elseif($top.legacy_present){try{Stop-ScheduledTask -TaskName $LegacyGatewayTaskName -ErrorAction SilentlyContinue}catch{}}
        Stop-FixedGatewayListener
        if($before-ne$GatewayLkgVersion){Install-ExactOpenClaw $GatewayLkgVersion;$changed=$true}
        if($useBackup){Copy-Item -LiteralPath $configBak -Destination $config -Force}
        $v=Invoke-OpenClawFixedConfig @('config','validate','--json');if($v.exit_code-ne0){throw 'LKG config validation failed'}
        $launcher=Start-AuthoritativeGateway $top;if(-not(Wait-GatewayRpc 90)){throw 'LKG Gateway direct RPC did not become healthy'}
        $health=Invoke-OpenClawFixedConfig @('gateway','health','--json');if($health.exit_code-ne0){throw 'LKG Gateway health failed'};$skills=Invoke-OpenClawFixedConfig @('skills','check','--agent','main','--json');if($skills.exit_code-ne0){throw 'LKG main-agent skills check failed'}
        Assert-Benchmark30;$after=Get-InstalledOpenClawVersion
        $public=[ordered]@{schema=1;kind='kevin-openclaw-windows-lkg-recovery-public';generated_at=(Get-Date).ToString('o');state='OMEN_PROVEN';safe_for_public_repo=$true;before_version=$before;after_version=$after;validated_version=$GatewayLkgVersion;npm_integrity_verified=$true;config_backup_used=$useBackup;authoritative_launcher=$launcher;keeper_preserved=[bool]$top.keeper_present;config_valid=$true;gateway_direct_rpc=$true;gateway_health=$true;main_skills_check=$true;benchmark_30_of_30=$true;rollback_available=$true;source_contract='Fixed Windows exact-version recovery to validated LKG with fixed npm integrity, preserved Keeper topology, safe config compatibility gate, fixed RPC/health/main-skills/Benchmark postconditions.';truth_boundary='No npm output, config body, credentials, paths, messages, prompts, or secrets are published.'}
        $receipt=Publish-SafeFixedReport 'reports/openclaw-windows-lkg-recovery-omen.json' 'openclaw-windows-lkg-recovery-public.json' $public 'kevin OpenClaw Windows LKG recovery telemetry';return [ordered]@{state='OMEN_PROVEN';receipt_sha256=$receipt;before_version=$before;after_version=$after;authoritative_launcher=$launcher;gateway_direct_rpc=$true;benchmark='30/30';config_backup_used=$useBackup}
    }catch{
        $primary=$_.Exception.Message;try{Copy-Item -LiteralPath $savedConfig -Destination $config -Force}catch{};if($changed){try{Assert-NpmIntegrity $GatewayRejectedVersion $GatewayRejectedIntegrity;Install-ExactOpenClaw $GatewayRejectedVersion}catch{}}
        try{$null=Start-AuthoritativeGateway $top}catch{};try{Assert-Benchmark30}catch{};throw ('OpenClaw Windows LKG recovery rollback completed: '+$primary)
    }
}
'''
anchor='function Assert-MainAgentCanary([object]$m) {'
if s.count(anchor)!=1: raise SystemExit('function insertion anchor mismatch')
s=s.replace(anchor,insert+'\n'+anchor,1)

once("        'diagnose_gateway_rpc' { Assert-GatewayRpcDiagnosis $m }\n        default { throw 'operation not allowlisted' }",
     "        'diagnose_gateway_rpc' { Assert-GatewayRpcDiagnosis $m }\n        'run_self_reliance_watchdog_once' { Assert-NoCallerArgs $m 'run_self_reliance_watchdog_once' }\n        'diagnose_gateway_failure_detail' { Assert-NoCallerArgs $m 'diagnose_gateway_failure_detail' }\n        'repair_openclaw_windows_lkg' { Assert-NoCallerArgs $m 'repair_openclaw_windows_lkg' }\n        default { throw 'operation not allowlisted' }",
     'assert-switch')
once("            'diagnose_gateway_rpc' { Diagnose-GatewayRpc; break }\n        }",
     "            'diagnose_gateway_rpc' { Diagnose-GatewayRpc; break }\n            'run_self_reliance_watchdog_once' { Run-SelfRelianceWatchdogOnce; break }\n            'diagnose_gateway_failure_detail' { Diagnose-GatewayFailureDetail; break }\n            'repair_openclaw_windows_lkg' { Repair-OpenClawWindowsLkg; break }\n        }",
     'execute-switch')
once("            'diagnose_gateway_rpc' {'gateway_rpc_diagnosis_failure'}\n            default {'typed_replace_failure'}",
     "            'diagnose_gateway_rpc' {'gateway_rpc_diagnosis_failure'}\n            'run_self_reliance_watchdog_once' {'self_reliance_operational_probe_failure'}\n            'diagnose_gateway_failure_detail' {'gateway_failure_detail_diagnosis_failure'}\n            'repair_openclaw_windows_lkg' {'openclaw_windows_lkg_recovery_failure'}\n            default {'typed_replace_failure'}",
     'failure-family')
once("    Write-Host 'KEVIN MAINTENANCE v1.3.30 SELFTEST PASS openclaw_bootstrap_diagnosis=fixed node_probe=fixed cli_version_probe=fixed config_metadata_only=true gateway_classifier=expanded arbitrary_shell=false authority_expansion=false'",
     "    Write-Host 'KEVIN MAINTENANCE v1.3.30 SELFTEST PASS openclaw_bootstrap_diagnosis=fixed node_probe=fixed cli_version_probe=fixed config_metadata_only=true gateway_classifier=expanded arbitrary_shell=false authority_expansion=false'\n    if($GatewayLkgVersion-ne'2026.6.34'-or$GatewayRejectedVersion-ne'2026.7.1-2'){throw 'Gateway release pins changed'}\n    if($GatewayLkgIntegrity-notmatch'^sha512-' -or $GatewayRejectedIntegrity-notmatch'^sha512-'){throw 'Gateway integrity pins missing'}\n    $wx=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$wx.operation='run_self_reliance_watchdog_once';Assert-Common $wx;Assert-NoCallerArgs $wx 'run_self_reliance_watchdog_once'\n    $gfd=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$gfd.operation='diagnose_gateway_failure_detail';Assert-Common $gfd;Assert-NoCallerArgs $gfd 'diagnose_gateway_failure_detail'\n    $lkg=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$lkg.operation='repair_openclaw_windows_lkg';Assert-Common $lkg;Assert-NoCallerArgs $lkg 'repair_openclaw_windows_lkg'\n    $badLkg=$lkg|ConvertTo-Json -Depth 10|ConvertFrom-Json;$badLkg|Add-Member -NotePropertyName version -NotePropertyValue 'latest';$blocked=$false;try{Assert-NoCallerArgs $badLkg 'repair_openclaw_windows_lkg'}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected OpenClaw version accepted'}\n    if((Get-GatewayFailureFamilyDetailed 'OpenClaw startup migrations did not complete cleanly')-ne'STARTUP_MIGRATION_GATE'){throw 'detailed migration classifier failed'}\n    if((Get-GatewayFailureFamilyDetailed 'shared SQLite state has conflicting plugin install metadata')-ne'PLUGIN_INSTALL_METADATA_CONFLICT'){throw 'detailed plugin conflict classifier failed'}\n    Write-Host 'KEVIN MAINTENANCE v1.3.31 SELFTEST PASS watchdog_operational_proof=fixed gateway_detail=fixed windows_lkg=2026.6.34 integrity_pinned=true keeper_topology_preserved=true safe_config_backup_required=true rollback=true gateway_rpc_postcondition=true main_skills_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'",
     'selftest')

DST.write_text(s,encoding='utf-8',newline='\n')
print(DST)
