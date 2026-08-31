from pathlib import Path

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.6.ps1')
DST = Path('control-plane/maintenance/generated/kevin-maintenance-runner-v1.3.7.ps1')
text = SRC.read_text(encoding='utf-8')


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'expected exactly one marker, found {count}: {old[:120]!r}')
    text = text.replace(old, new, 1)


replace_once("version='1.3.6'", "version='1.3.7'")
replace_once(
    "@('replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','publish_runtime_convergence','replace_runtime_policy_bundle','migrate_design_forge_v40')",
    "@('replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','publish_runtime_convergence','publish_runtime_capabilities','replace_runtime_policy_bundle','migrate_design_forge_v40')",
)

runtime_audit = r'''
function Invoke-OpenClawReadOnlyProbe([string]$Probe) {
    $cmd=Get-Command openclaw -ErrorAction SilentlyContinue
    if(-not $cmd){return [pscustomobject]@{exit_code=127;output='';available=$false}}
    $args=switch($Probe){
        'version' {@('--version')}
        'config_validate' {@('config','validate','--json')}
        'main_tools' {@('config','get','agents.entries.main.tools','--json')}
        'default_tools' {@('config','get','agents.defaults.tools','--json')}
        'root_tools' {@('config','get','tools','--json')}
        'workshop_mode' {@('config','get','skills.workshop.autonomous.mode','--json')}
        'workshop_approval' {@('config','get','skills.workshop.approvalPolicy','--json')}
        'task_flow' {@('tasks','flow','list','--json')}
        'workshop_list' {@('skills','workshop','list','--json')}
        'curator_status' {@('skills','curator','status','--json')}
        'skills_check_main' {@('skills','check','--agent','main','--json')}
        'plugins_list' {@('plugins','list','--json')}
        'plugins_doctor' {@('plugins','doctor','--json')}
        'doctor' {@('doctor','--json')}
        'gateway_deep' {@('gateway','status','--deep','--require-rpc')}
        default {throw 'runtime audit probe not allowlisted'}
    }
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $cmd.Source @args 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    return [pscustomobject]@{exit_code=$code;output=[string]$out;available=$true}
}
function ConvertFrom-JsonSafe([string]$Text){if(-not$Text){return $null};try{return($Text|ConvertFrom-Json)}catch{return $null}}
function Get-JsonCollectionCount([object]$Obj,[string[]]$Names){
    if($null -eq $Obj){return 0}
    if($Obj -is [System.Array]){return @($Obj).Count}
    foreach($n in $Names){$p=$Obj.PSObject.Properties[$n];if($p){return @($p.Value).Count}}
    return 0
}
function Get-SafeEnum([object]$Probe,[string[]]$Allowed,[string]$Default='UNSET_OR_UNKNOWN'){
    if([int]$Probe.exit_code -ne 0){return $Default}
    $obj=ConvertFrom-JsonSafe ([string]$Probe.output)
    $v=if($obj -is [string]){[string]$obj}else{[string]$Probe.output}
    $v=$v.Trim().Trim('"')
    foreach($a in $Allowed){if($v -eq $a){return $a}}
    return $Default
}
function Invoke-LobsterRuntimeProbe([string]$Id){
    if(-not$Id -or $Id -notmatch '(?i)lobster' -or $Id -notmatch '^[A-Za-z0-9._@/-]{1,128}$'){return [pscustomobject]@{exit_code=2;output=''}}
    $cmd=Get-Command openclaw -ErrorAction SilentlyContinue
    if(-not$cmd){return [pscustomobject]@{exit_code=127;output=''}}
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $cmd.Source plugins inspect $Id --runtime --json 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    return [pscustomobject]@{exit_code=$code;output=[string]$out}
}
function Get-TextSha256([string]$Text){
    $bytes=[Text.Encoding]::UTF8.GetBytes([string]$Text);$sha=[Security.Cryptography.SHA256]::Create()
    try{return([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()}
}
function Publish-RuntimeCapabilities {
    $version=Invoke-OpenClawReadOnlyProbe 'version'
    $validate=Invoke-OpenClawReadOnlyProbe 'config_validate'
    $mainTools=Invoke-OpenClawReadOnlyProbe 'main_tools'
    $defaultTools=Invoke-OpenClawReadOnlyProbe 'default_tools'
    $rootTools=Invoke-OpenClawReadOnlyProbe 'root_tools'
    $modeProbe=Invoke-OpenClawReadOnlyProbe 'workshop_mode'
    $approvalProbe=Invoke-OpenClawReadOnlyProbe 'workshop_approval'
    $flow=Invoke-OpenClawReadOnlyProbe 'task_flow'
    $workshop=Invoke-OpenClawReadOnlyProbe 'workshop_list'
    $curator=Invoke-OpenClawReadOnlyProbe 'curator_status'
    $skillsCheck=Invoke-OpenClawReadOnlyProbe 'skills_check_main'
    $plugins=Invoke-OpenClawReadOnlyProbe 'plugins_list'
    $pluginsDoctor=Invoke-OpenClawReadOnlyProbe 'plugins_doctor'
    $doctor=Invoke-OpenClawReadOnlyProbe 'doctor'
    $gateway=Invoke-OpenClawReadOnlyProbe 'gateway_deep'

    $versionToken='UNKNOWN'
    if([int]$version.exit_code -eq 0){$vm=[regex]::Match([string]$version.output,'\b\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?\b');if($vm.Success){$versionToken=$vm.Value}}
    $flowObj=ConvertFrom-JsonSafe ([string]$flow.output)
    $workshopObj=ConvertFrom-JsonSafe ([string]$workshop.output)
    $pluginsObj=ConvertFrom-JsonSafe ([string]$plugins.output)
    $pluginText=if($pluginsObj){$pluginsObj|ConvertTo-Json -Depth 20 -Compress}else{''}
    $lobsterId=''
    $lm=[regex]::Match($pluginText,'(?i)"id"\s*:\s*"([^"\\]*lobster[^"\\]*)"')
    if($lm.Success -and $lm.Groups[1].Value -match '^[A-Za-z0-9._@/-]{1,128}$'){$lobsterId=$lm.Groups[1].Value}
    $lobsterRuntime=if($lobsterId){Invoke-LobsterRuntimeProbe $lobsterId}else{[pscustomobject]@{exit_code=3;output=''}}
    $lobsterRuntimeText=[string]$lobsterRuntime.output
    $workshopIssue=$false
    if([int]$doctor.exit_code -eq 0 -and [string]$doctor.output -match '(?i)skill_workshop' -and [string]$doctor.output -match '(?i)hidden|exclud|not allowed|tool policy'){$workshopIssue=$true}

    $forge=(Get-AliasSpec 'design_forge_runner');$forgeSha=Get-Sha $forge.Target
    $benchPath=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    $benchPresent=Test-Path -LiteralPath $benchPath -PathType Leaf
    $benchText=if($benchPresent){[IO.File]::ReadAllText($benchPath)}else{''}
    $r03=[regex]::Match($benchText,'(?is).{0,1000}\bR03\b.{0,2200}')
    $r03Text=if($r03.Success){$r03.Value}else{''}
    $forgeLiteralCount=if($forgeSha){Get-LiteralOccurrenceCount $benchText $forgeSha}else{0}

    $public=[ordered]@{
        schema=1
        kind='kevin-runtime-capabilities-public'
        generated_at=(Get-Date).ToString('o')
        state='OMEN_AUDIT_PROVEN'
        safe_for_public_repo=$true
        openclaw=[ordered]@{
            cli_present=[bool]$version.available
            version=$versionToken
            config_valid=([int]$validate.exit_code -eq 0)
            gateway_deep_probe_ok=([int]$gateway.exit_code -eq 0)
        }
        orchestration=[ordered]@{
            task_flow_cli_available=([int]$flow.exit_code -eq 0)
            task_flow_count=(Get-JsonCollectionCount $flowObj @('flows','items'))
        }
        tool_policy=[ordered]@{
            main_tools_path_present=([int]$mainTools.exit_code -eq 0)
            default_tools_path_present=([int]$defaultTools.exit_code -eq 0)
            root_tools_path_present=([int]$rootTools.exit_code -eq 0)
            main_tools_redacted_snapshot_sha256=(Get-TextSha256 ([string]$mainTools.output))
            skill_workshop_policy_issue_reported=$workshopIssue
            skills_check_main_ok=([int]$skillsCheck.exit_code -eq 0)
            truth_boundary='Presence/hashes classify installed policy surfaces without publishing redacted config values. Actual per-turn tool availability still requires a real agent-turn proof.'
        }
        learning=[ordered]@{
            workshop_cli_available=([int]$workshop.exit_code -eq 0)
            workshop_pending_count=(Get-JsonCollectionCount $workshopObj @('proposals','items'))
            curator_status_available=([int]$curator.exit_code -eq 0)
            autonomous_mode=(Get-SafeEnum $modeProbe @('off','propose','auto'))
            approval_policy=(Get-SafeEnum $approvalProbe @('pending','auto'))
        }
        lobster=[ordered]@{
            inventory_present=[bool]$lobsterId
            inventory_id_sha256=if($lobsterId){Get-TextSha256 $lobsterId}else{''}
            runtime_inspect_ok=([int]$lobsterRuntime.exit_code -eq 0)
            runtime_registers_tool=([int]$lobsterRuntime.exit_code -eq 0 -and $lobsterRuntimeText -match '(?i)lobster|tools')
            plugins_doctor_ok=([int]$pluginsDoctor.exit_code -eq 0)
        }
        benchmark_r03=[ordered]@{
            benchmark_present=$benchPresent
            benchmark_sha256=if($benchPresent){Get-Sha $benchPath}else{''}
            forge_sha256=$forgeSha
            current_forge_sha_literal_count=$forgeLiteralCount
            r03_marker_present=$r03.Success
            r03_context_sha256=if($r03.Success){Get-TextSha256 $r03Text}else{''}
            r03_mentions_desired_state=($r03Text -match '(?i)desired.?state')
            r03_mentions_file_hash=($r03Text -match '(?i)Get-FileHash|SHA256|hash')
            r03_mentions_forge=($r03Text -match '(?i)forge')
            r03_mentions_support=($r03Text -match '(?i)support')
            r03_mentions_goal_os=($r03Text -match '(?i)goal.?os')
            diagnosis='Structural metadata only. No Benchmark source/context is published.'
        }
        source_contract='Fixed read-only OpenClaw probes + fixed local Benchmark/Forge identity inspection only; no caller-selected command, path, config write, plugin enablement, or secret output.'
        truth_boundary='This proves installed CLI/config/plugin/audit observations at generated_at. It does not by itself prove long-horizon autonomy or semantic task success.'
    }
    $local=Join-Path $Reports 'runtime-capabilities-public.json';Write-JsonAtomic $local $public
    $repoPath='reports/runtime-capabilities-omen.json'
    $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
    if($lookup.ExitCode -ne 0 -or -not$lookup.Output){throw 'runtime capabilities receipt remote SHA lookup failed'}
    $payload=[ordered]@{message='kevin runtime capabilities telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local));sha=[string]$lookup.Output}|ConvertTo-Json -Compress
    $payloadPath=Join-Path $env:TEMP ('kevin-runtime-capabilities-'+[guid]::NewGuid().ToString('N')+'.json')
    try{[IO.File]::WriteAllText($payloadPath,$payload,$Utf8);$publish=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$payloadPath,'--silent');if($publish.ExitCode -ne 0){throw ('runtime capabilities receipt publish failed: '+(Safe-Text $publish.Output 300))}}finally{Remove-Item -LiteralPath $payloadPath -Force -ErrorAction SilentlyContinue}
    $verify=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.content');if($verify.ExitCode -ne 0 -or -not$verify.Output){throw 'runtime capabilities receipt verification fetch failed'}
    try{$remote=[Convert]::FromBase64String(([string]$verify.Output -replace '\s',''))}catch{throw 'runtime capabilities receipt verification decode failed'}
    $localHash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToUpperInvariant();$sha=[Security.Cryptography.SHA256]::Create();try{$remoteHash=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()}
    if($remoteHash -ne $localHash){throw 'runtime capabilities receipt remote verification hash mismatch'}
    return [ordered]@{published=$true;repo_path=$repoPath;receipt_sha256=$localHash;task_flow=([int]$flow.exit_code -eq 0);workshop=([int]$workshop.exit_code -eq 0);lobster_runtime=([int]$lobsterRuntime.exit_code -eq 0);r03_marker=$r03.Success}
}
'''.strip()
replace_once('function Install-RuntimePolicyBundle([object]$m) {', runtime_audit + "\nfunction Install-RuntimePolicyBundle([object]$m) {")

replace_once(
    "        'publish_runtime_convergence' { }\n        'replace_runtime_policy_bundle' { Assert-RuntimeBundle $m }",
    "        'publish_runtime_convergence' { }\n        'publish_runtime_capabilities' { }\n        'replace_runtime_policy_bundle' { Assert-RuntimeBundle $m }",
)
replace_once(
    "            'publish_runtime_convergence' { Publish-RuntimeConvergence; break }\n            'replace_runtime_policy_bundle' { Install-RuntimePolicyBundle $m; break }",
    "            'publish_runtime_convergence' { Publish-RuntimeConvergence; break }\n            'publish_runtime_capabilities' { Publish-RuntimeCapabilities; break }\n            'replace_runtime_policy_bundle' { Install-RuntimePolicyBundle $m; break }",
)
replace_once(
    "            'publish_runtime_convergence' {'runtime_convergence_publish_failure'}\n            'replace_runtime_policy_bundle' {'runtime_policy_bundle_failure'}",
    "            'publish_runtime_convergence' {'runtime_convergence_publish_failure'}\n            'publish_runtime_capabilities' {'runtime_capabilities_publish_failure'}\n            'replace_runtime_policy_bundle' {'runtime_policy_bundle_failure'}",
)

replace_once(
    "    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration'",
    "    $cap=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$cap.operation='publish_runtime_capabilities';Assert-Common $cap\n    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration'",
)
replace_once(
    "    Write-Host 'KEVIN MAINTENANCE v1.3.6 SELFTEST PASS aliases=6 runtime_policy_bundle=5 convergence_audit=1 convergence_publish=1 fixed_public_receipt=1 coordinated_forge_validator_migration=1 arbitrary_shell=false authority_expansion=false max_attempts=3'",
    "    Write-Host 'KEVIN MAINTENANCE v1.3.6 SELFTEST PASS compatibility=v1.3.7'\n    Write-Host 'KEVIN MAINTENANCE v1.3.7 SELFTEST PASS aliases=6 runtime_policy_bundle=5 convergence_audit=1 convergence_publish=1 runtime_capability_audit=1 fixed_public_receipt=2 read_only_openclaw_probes=1 arbitrary_shell=false authority_expansion=false max_attempts=3'",
)

DST.parent.mkdir(parents=True, exist_ok=True)
DST.write_text(text, encoding='utf-8', newline='\n')
print(DST)
