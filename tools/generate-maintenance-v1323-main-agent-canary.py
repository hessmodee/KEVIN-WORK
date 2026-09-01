from pathlib import Path
import hashlib

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.22.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.23.ps1')
EXPECTED='3F926629917D49BD28FD492C6698146461BA5F362F09146A160CB221CBAEEE4E'
raw=SRC.read_bytes(); actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED: raise SystemExit(f'v1.3.22 source identity mismatch: {actual}')
text=raw.decode('utf-8')

def once(old,new,label):
    global text
    n=text.count(old)
    if n!=1: raise SystemExit(f'{label} anchor count={n}')
    text=text.replace(old,new,1)

once("version='1.3.22'","version='1.3.23'",'state version')
old="'repair_supervisor_v171_forge_pin','ensure_autonomy_continuation_automation') -contains [string]$m.operation)"
new="'repair_supervisor_v171_forge_pin','ensure_autonomy_continuation_automation','run_main_agent_canary') -contains [string]$m.operation)"
once(old,new,'common operation allowlist')

anchor="function Assert-AutonomyContinuationAutomation([object]$m) {\n"
code=r'''function Assert-MainAgentCanary([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('main-agent canary manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'run_main_agent_canary'){throw 'main-agent canary operation mismatch'}
}
function Publish-MainAgentCanaryReceipt([object]$Public) {
    $local=Join-Path $Reports 'main-agent-canary-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/main-agent-canary-omen.json'
    $localHash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToUpperInvariant()
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
        if($lookup.ExitCode-ne0 -or -not$lookup.Output){throw 'main-agent canary receipt remote SHA lookup failed'}
        $body=[ordered]@{message='kevin main-agent canary telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local));sha=[string]$lookup.Output}|ConvertTo-Json -Compress
        $tmp=Join-Path $env:TEMP ('kevin-main-agent-canary-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,$body,$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode-ne0){if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt);continue};throw 'main-agent canary receipt bounded publish retries exhausted'}
        Start-Sleep -Milliseconds 600
        $get=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.content')
        if($get.ExitCode-eq0 -and $get.Output){
            try{$remote=[Convert]::FromBase64String(([string]$get.Output-replace'\s',''));$sha=[Security.Cryptography.SHA256]::Create();try{$rh=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()};if($rh-eq$localHash){return [ordered]@{published=$true;repo_path=$repoPath;receipt_sha256=$localHash;attempt=$attempt}}}catch{}
        }
        if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt)}
    }
    throw 'main-agent canary receipt remote verification failed'
}
function Run-MainAgentCanary {
    $gw=Invoke-OpenClawFixedConfig @('gateway','status','--deep','--require-rpc')
    if($gw.exit_code-ne0){throw 'main-agent canary gateway deep probe failed'}
    $message='KEVIN_MAIN_AGENT_CANARY_V1: Reply exactly KEVIN_MAIN_AGENT_CANARY_OK. Do not call tools.'
    $sw=[Diagnostics.Stopwatch]::StartNew();$r=Invoke-OpenClawFixedConfig @('agent','--agent','main','--json','--message',$message);$sw.Stop()
    if($r.exit_code-ne0){throw ('main-agent canary agent turn failed: '+(Safe-Text $r.output 220))}
    $o=ConvertFrom-ReaderJson ([string]$r.output)
    $status=[string]$o.status;$text=Get-ReaderFinalText $o;$calls=Get-ReaderToolCalls $o;$tools=@(Get-ReaderVisibleToolNames $o|Sort-Object -Unique)
    $expected=($text -eq 'KEVIN_MAIN_AGENT_CANARY_OK')
    $toolHash=Get-TextSha256 (($tools -join "`n"))
    $kevinCount=@($tools|Where-Object{$_ -match '^(?i)kevin[_-]'}).Count
    $success=($status-eq'success' -and $expected -and $calls-eq0)
    $public=[ordered]@{
        schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state=if($success){'OMEN_PROVEN'}else{'REJECT'};safe_for_public_repo=$true
        gateway_probe_ok=$true;agent='fixed:main';status=$status;exact_expected_reply=$expected;tool_calls=$calls;visible_tool_count=$tools.Count;visible_tool_names_sha256=$toolHash;visible_kevin_tool_count=$kevinCount;has_kevin_system_status=($tools -contains 'kevin_system_status');duration_ms=[int]$sw.ElapsedMilliseconds;output_sha256=(Get-TextSha256 $text)
        source_contract='One fixed Gateway-backed OpenClaw main-agent turn. No caller-selected prompt, agent, profile, command, argv, path, recipient, or authority.'
        truth_boundary='Metadata-only proof of one real main-agent turn and its prompt-reported visible tool surface. No raw prompt, model text, tool output, tool names list, configuration, paths, usernames, ports, credentials, or secrets are published.'
    }
    $pub=Publish-MainAgentCanaryReceipt $public
    Assert-Benchmark30
    if(-not$success){throw 'main-agent canary semantic contract rejected'}
    return [ordered]@{state='OMEN_PROVEN';published=$pub.published;receipt_sha256=$pub.receipt_sha256;visible_tool_count=$tools.Count;visible_kevin_tool_count=$kevinCount;tool_calls=0;authority_effect='NONE'}
}

'''+anchor
once(anchor,code,'main-agent canary insertion')

once("        'ensure_autonomy_continuation_automation' { Assert-AutonomyContinuationAutomation $m }\n        default { throw 'operation not allowlisted' }",
     "        'ensure_autonomy_continuation_automation' { Assert-AutonomyContinuationAutomation $m }\n        'run_main_agent_canary' { Assert-MainAgentCanary $m }\n        default { throw 'operation not allowlisted' }",'assert switch')
once("            'ensure_autonomy_continuation_automation' { Ensure-AutonomyContinuationAutomation; break }\n        }",
     "            'ensure_autonomy_continuation_automation' { Ensure-AutonomyContinuationAutomation; break }\n            'run_main_agent_canary' { Run-MainAgentCanary; break }\n        }",'execute switch')
once("            'ensure_autonomy_continuation_automation' {'autonomy_continuation_automation_failure'}\n            default {'typed_replace_failure'}",
     "            'ensure_autonomy_continuation_automation' {'autonomy_continuation_automation_failure'}\n            'run_main_agent_canary' {'main_agent_canary_failure'}\n            default {'typed_replace_failure'}",'failure family')

self_anchor="    $ac=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$ac.operation='ensure_autonomy_continuation_automation';Assert-Common $ac;Assert-AutonomyContinuationAutomation $ac\n"
self_code=self_anchor+r'''    $mac=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$mac.operation='run_main_agent_canary';Assert-Common $mac;Assert-MainAgentCanary $mac
    $macBad=$mac|ConvertTo-Json -Depth 10|ConvertFrom-Json;$macBad|Add-Member -NotePropertyName prompt -NotePropertyValue 'override';$blocked=$false;try{Assert-MainAgentCanary $macBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected main-agent prompt accepted'}
'''
once(self_anchor,self_code,'selftest canary fixture')
old="    Write-Host 'KEVIN MAINTENANCE v1.3.22 SELFTEST PASS cli_surface_audit=fixed read_only=true raw_help_published=false arbitrary_shell=false authority_expansion=false'"
new=old+"\n    Write-Host 'KEVIN MAINTENANCE v1.3.23 SELFTEST PASS main_agent_canary=fixed gateway_backed=true raw_text_published=false arbitrary_shell=false authority_expansion=false'"
once(old,new,'v1323 selftest marker')

OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1323_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
