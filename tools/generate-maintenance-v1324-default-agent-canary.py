from pathlib import Path
import hashlib

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.23.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.24.ps1')
EXPECTED='3E60FF4B135B676569D351438369D3650E1A336DC7F8F31181D9F24BD9CAC340'
raw=SRC.read_bytes(); actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED: raise SystemExit(f'v1.3.23 source identity mismatch: {actual}')
text=raw.decode('utf-8')

def once(old,new,label):
    global text
    n=text.count(old)
    if n!=1: raise SystemExit(f'{label} anchor count={n}')
    text=text.replace(old,new,1)

once("version='1.3.23'","version='1.3.24'",'state version')
start=text.index('function Run-MainAgentCanary {')
end=text.index('function Assert-AutonomyContinuationAutomation', start)
new_code=r'''function Run-MainAgentCanary {
    $message='KEVIN_MAIN_AGENT_CANARY_V2: Reply exactly KEVIN_MAIN_AGENT_CANARY_OK. Do not call tools.'
    $gw=Invoke-OpenClawFixedConfig @('gateway','status','--deep','--require-rpc')
    if($gw.exit_code-ne0){
        $public=[ordered]@{
            schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state='REJECT';safe_for_public_repo=$true
            gateway_probe_ok=$false;agent='fixed:runtime-default';agent_exit_code=$null;failure_stage='gateway_probe';status='';exact_expected_reply=$false;tool_calls=0;visible_tool_count=0;visible_tool_names_sha256=(Get-TextSha256 '');visible_kevin_tool_count=0;has_kevin_system_status=$false;duration_ms=0;output_sha256=''
            source_contract='One fixed Gateway-backed OpenClaw default-agent turn. No caller-selected prompt, agent id, profile, command, argv, path, recipient, or authority.'
            truth_boundary='Metadata-only proof. Raw prompt, model text, CLI output, tool output, configuration, paths, usernames, ports, credentials, and secrets are not published.'
        }
        $null=Publish-MainAgentCanaryReceipt $public
        Assert-Benchmark30
        throw 'main-agent canary gateway deep probe failed'
    }
    $sw=[Diagnostics.Stopwatch]::StartNew();$r=Invoke-OpenClawFixedConfig @('agent','--json','--message',$message);$sw.Stop()
    if($r.exit_code-ne0){
        $public=[ordered]@{
            schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state='REJECT';safe_for_public_repo=$true
            gateway_probe_ok=$true;agent='fixed:runtime-default';agent_exit_code=[int]$r.exit_code;failure_stage='agent_cli';status='';exact_expected_reply=$false;tool_calls=0;visible_tool_count=0;visible_tool_names_sha256=(Get-TextSha256 '');visible_kevin_tool_count=0;has_kevin_system_status=$false;duration_ms=[int]$sw.ElapsedMilliseconds;output_sha256=(Get-TextSha256 ([string]$r.output))
            source_contract='One fixed Gateway-backed OpenClaw default-agent turn. No caller-selected prompt, agent id, profile, command, argv, path, recipient, or authority.'
            truth_boundary='Metadata-only proof. Raw prompt, model text, CLI output, tool output, configuration, paths, usernames, ports, credentials, and secrets are not published.'
        }
        $null=Publish-MainAgentCanaryReceipt $public
        Assert-Benchmark30
        throw 'main-agent canary default-agent CLI invocation failed'
    }
    try{$o=ConvertFrom-ReaderJson ([string]$r.output)}catch{
        $public=[ordered]@{
            schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state='REJECT';safe_for_public_repo=$true
            gateway_probe_ok=$true;agent='fixed:runtime-default';agent_exit_code=0;failure_stage='agent_json_parse';status='';exact_expected_reply=$false;tool_calls=0;visible_tool_count=0;visible_tool_names_sha256=(Get-TextSha256 '');visible_kevin_tool_count=0;has_kevin_system_status=$false;duration_ms=[int]$sw.ElapsedMilliseconds;output_sha256=(Get-TextSha256 ([string]$r.output))
            source_contract='One fixed Gateway-backed OpenClaw default-agent turn. No caller-selected prompt, agent id, profile, command, argv, path, recipient, or authority.'
            truth_boundary='Metadata-only proof. Raw prompt, model text, CLI output, tool output, configuration, paths, usernames, ports, credentials, and secrets are not published.'
        }
        $null=Publish-MainAgentCanaryReceipt $public
        Assert-Benchmark30
        throw 'main-agent canary default-agent JSON parse failed'
    }
    $status=[string]$o.status;$finalText=Get-ReaderFinalText $o;$calls=Get-ReaderToolCalls $o;$tools=@(Get-ReaderVisibleToolNames $o|Sort-Object -Unique)
    $expected=($finalText -eq 'KEVIN_MAIN_AGENT_CANARY_OK')
    $toolHash=Get-TextSha256 (($tools -join "`n"))
    $kevinCount=@($tools|Where-Object{$_ -match '^(?i)kevin[_-]'}).Count
    $success=($status-eq'success' -and $expected -and $calls-eq0)
    $public=[ordered]@{
        schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state=if($success){'OMEN_PROVEN'}else{'REJECT'};safe_for_public_repo=$true
        gateway_probe_ok=$true;agent='fixed:runtime-default';agent_exit_code=0;failure_stage=if($success){''}else{'semantic_contract'};status=$status;exact_expected_reply=$expected;tool_calls=$calls;visible_tool_count=$tools.Count;visible_tool_names_sha256=$toolHash;visible_kevin_tool_count=$kevinCount;has_kevin_system_status=($tools -contains 'kevin_system_status');duration_ms=[int]$sw.ElapsedMilliseconds;output_sha256=(Get-TextSha256 $finalText)
        source_contract='One fixed Gateway-backed OpenClaw default-agent turn. No caller-selected prompt, agent id, profile, command, argv, path, recipient, or authority.'
        truth_boundary='Metadata-only proof of one real default-agent turn and its prompt-reported visible tool surface. Raw prompt, model text, CLI output, tool output, tool names list, configuration, paths, usernames, ports, credentials, and secrets are not published.'
    }
    $pub=Publish-MainAgentCanaryReceipt $public
    Assert-Benchmark30
    if(-not$success){throw 'main-agent canary semantic contract rejected'}
    return [ordered]@{state='OMEN_PROVEN';published=$pub.published;receipt_sha256=$pub.receipt_sha256;agent='runtime-default';visible_tool_count=$tools.Count;visible_kevin_tool_count=$kevinCount;tool_calls=0;authority_effect='NONE'}
}

'''
text=text[:start]+new_code+text[end:]
old="    Write-Host 'KEVIN MAINTENANCE v1.3.23 SELFTEST PASS main_agent_canary=fixed gateway_backed=true raw_text_published=false arbitrary_shell=false authority_expansion=false'"
new=old+"\n    Write-Host 'KEVIN MAINTENANCE v1.3.24 SELFTEST PASS default_agent_canary=fixed failure_receipt=true raw_text_published=false arbitrary_shell=false authority_expansion=false'"
once(old,new,'v1324 selftest marker')
OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1324_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
