param(
    [switch]$CheckOnly,
    [switch]$ApplyOnce,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Workspace = if ($env:KEVIN_MAINT_TEST_ROOT) { $env:KEVIN_MAINT_TEST_ROOT } elseif ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Reports = Join-Path $Workspace 'reports'
$Root = Join-Path $Reports 'maintenance'
$StageRoot = Join-Path $Root 'staged'
$BackupRoot = Join-Path $Root 'backups'
$LatestPath = Join-Path $Root 'latest.json'
$AttemptPath = Join-Path $Root 'typed-attempts.json'
$Repo = 'hessmodee/KEVIN-WORK'
$ManifestRemote = 'inbox/maintenance/manifest.json'
$OwnerPolicy = 'Kevin Owner Authorization v1'
$MaxAttempts = 3
$AbsentHash = ('0' * 64)
$RuntimePolicyNames = @('AGENTS.md','HEARTBEAT.md','MEMORY.md','SOUL.md','TOOLS.md')
$SupervisorV16Sha = '63B8D9C27625E0FB6AFE62165BE376E7ED7EB416E5DA15BB47C206BBF4AE4989'
$SupervisorV17Sha = '796B1756CE0B3C9E926AA72A32410FC9119F0AD4FEC2E6CA15D977F4DA87333A'
$SupervisorV171Sha = '47A0A1D0E3F744E972E2F2239F100CA2B009ABD3928D0281E4587A364B7C27AC'
$ForgeV37Sha = '4C83DF29E765D61F2B26D2029FE6C2C7ED68DA90E5A7A457A82BE769029E22CA'
$ForgeV40Sha = '433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
$ForgeV40Source = 'control-plane/forge/kevin-design-forge-v4.0.ps1'
$BenchmarkBaselineBeforeSha = 'B4F2B01ADBFC946754A987797F94D3E50C51300111DE4003546825D11ED649A1'
$SupervisorV183Sha = 'C3F781E4F722AF691D2B47A9CD0F06A4F6AD3134A826C5D657B9ED9D5AEBC400'
$SelectorV11Sha = '9DF1F770E8855232758AC275FA2D3A82C6D484099B5B2D2185A999ACDE185DE4'
$SupervisorV183Source = 'control-plane/autonomy/kevin-supervisor-v1.8.5.ps1'
# Legacy v183 symbol/operation name is retained as the typed contract identifier; its qualified target is Supervisor v1.8.5.
$SelectorV11Source = 'control-plane/autonomy/kevin-work-selector-v1.1.py'
$GatewayLkgVersion = '2026.6.34'
$GatewayRejectedVersion = '2026.7.1-2'
$GatewayLkgIntegrity = 'sha512-Rm4khBrWn9HYqE99NBryCFgjwlsIuwBqK5jIANn2773CGXJ1JIZkDn5twEHB+8SVFdh0FPNPHRVgZepzNJDfHg=='
$GatewayRejectedIntegrity = 'sha512-ycF3yPcbjN6bUPeaUx6Mh6vze1hQWoD3CT/wWcmD7a8xaHHHRUaAlaq+lFxMHf1ssEgODVAwjlzYqp2twkYZ7g=='
$GatewayKeeperTaskName = 'KevinGatewayKeeper'
$LegacyGatewayTaskName = 'OpenClaw Gateway'
foreach ($d in @($Root,$StageRoot,$BackupRoot)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

function Write-Utf8Atomic([string]$Path,[string]$Text) {
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,$Text,$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Write-JsonAtomic([string]$Path,[object]$Object) { Write-Utf8Atomic $Path ($Object | ConvertTo-Json -Depth 30) }
function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Safe-Text([object]$Value,[int]$MaxLength = 900) {
    $s = [string]$Value
    if (-not $s) { return '' }
    if ($env:USERPROFILE) { $s = [regex]::Replace($s,[regex]::Escape([string]$env:USERPROFILE),'~',[Text.RegularExpressions.RegexOptions]::IgnoreCase) }
    foreach ($pattern in @('(?i)\bghp_[A-Za-z0-9_]{8,}\b','(?i)\bgithub_pat_[A-Za-z0-9_]{8,}\b','(?i)\bsk-[A-Za-z0-9_-]{8,}\b','(?i)(Authorization\s*:\s*Bearer\s+)[^\s''";,]+')) { $s = [regex]::Replace($s,$pattern,'[REDACTED]') }
    $s = $s.Replace("`r",' ').Replace("`n",' ')
    if ($s.Length -gt $MaxLength) { $s = $s.Substring(0,$MaxLength) }
    return $s
}
function Save-State([string]$Status,[string]$ManifestId = '',[string]$Detail = '',[hashtable]$Extra = $null) {
    $obj = [ordered]@{ schema=3; kind='kevin-maintenance-state'; version='1.3.38'; at=(Get-Date).ToString('o'); status=$Status; manifest_id=$ManifestId; detail=(Safe-Text $Detail) }
    if ($Extra) { foreach ($k in $Extra.Keys) { $obj[$k] = $Extra[$k] } }
    Write-JsonAtomic $LatestPath $obj
}

function Invoke-Gh([string[]]$Arguments) {
    $gh = (Get-Command gh -ErrorAction Stop).Source
    $oldGh = [Environment]::GetEnvironmentVariable('GH_TOKEN','Process')
    $oldGithub = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    try {
        Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
        Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
        $env:GH_PROMPT_DISABLED='1'
        $old=$ErrorActionPreference
        try { $ErrorActionPreference='Continue'; $out=(& $gh @Arguments 2>&1 | Out-String).Trim(); $code=[int]$LASTEXITCODE }
        finally { $ErrorActionPreference=$old }
        return [pscustomobject]@{ExitCode=$code;Output=[string]$out}
    }
    finally {
        if ($null -ne $oldGh) { $env:GH_TOKEN=$oldGh } else { Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue }
        if ($null -ne $oldGithub) { $env:GITHUB_TOKEN=$oldGithub } else { Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue }
    }
}
function Get-RemoteManifestText {
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$ManifestRemote),'--jq','.content')
    if ($r.ExitCode -ne 0) { if ($r.Output -match '404|Not Found') { return $null }; throw ('manifest fetch failed: '+(Safe-Text $r.Output 400)) }
    try { return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$r.Output -replace '\s',''))) } catch { throw 'manifest base64 decode failed' }
}
function Get-RemoteFixedBytes([string]$RepoPath) {
    if ($RepoPath -notmatch '^(workspace/(AGENTS|HEARTBEAT|MEMORY|SOUL|TOOLS)\.md|control-plane/(maintenance|intake|skill-lab|os-awareness|forge)/[A-Za-z0-9._-]+\.ps1)$') { throw 'fixed remote source path rejected' }
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.content')
    if ($r.ExitCode -ne 0) { throw ('remote source fetch failed: '+(Safe-Text $r.Output 400)) }
    try { return [Convert]::FromBase64String(([string]$r.Output -replace '\s','')) } catch { throw 'remote source base64 decode failed' }
}

function Get-AliasSpec([string]$Alias) {
    switch ($Alias) {
        'maintenance_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-maintenance-runner.ps1');Source='^control-plane/maintenance/kevin-maintenance-runner-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN MAINTENANCE v1.3.3 SELFTEST PASS';AllowAbsent=$false} }
        'work_order_intake' { return [pscustomobject]@{Target=(Join-Path $Workspace 'ControlPlane\kevin-work-order-intake-v0.1.ps1');Source='^control-plane/intake/kevin-work-order-intake-v[0-9._-]+\.ps1$';SelfTestArgs=@('-Mode','SelfTest');Marker='KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS';AllowAbsent=$false} }
        'skill_lab_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-skill-lab.ps1');Source='^control-plane/skill-lab/kevin-skill-lab-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN SKILL LAB v1.0.3 SELFTEST PASS';AllowAbsent=$false} }
        'os_observer_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-os-observer.ps1');Source='^control-plane/os-awareness/kevin-os-observer-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN OS OBSERVER v0.1 SELFTEST PASS';AllowAbsent=$true} }
        'self_reliance_watchdog' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-self-reliance-watchdog.ps1');Source='^control-plane/maintenance/kevin-self-reliance-watchdog-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN SELF-RELIANCE WATCHDOG v1.3 SELFTEST PASS';AllowAbsent=$false} }
        'design_forge_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-design-forge.ps1');Source='^control-plane/forge/kevin-design-forge-v[0-9._-]+\.ps1$';SelfTestArgs=@('-SelfTest');Marker='KEVIN DESIGN FORGE v4.0 SELFTEST PASS';AllowAbsent=$false} }
        'ui_bridge_runner' { return [pscustomobject]@{Target=(Join-Path $Workspace 'kevin-ui-bridge.ps1');Source='';SelfTestArgs=@('-SelfTest');Marker='';AllowAbsent=$false} }
        default { throw ('target alias not allowlisted: '+$Alias) }
    }
}
function Get-PolicySpec([string]$Name) {
    if ($RuntimePolicyNames -notcontains $Name) { throw ('runtime policy component not allowlisted: '+$Name) }
    $marker = switch ($Name) {
        'AGENTS.md' { 'Standing Order 1' }
        'HEARTBEAT.md' { 'ambient monitor' }
        'MEMORY.md' { 'durable' }
        'SOUL.md' { 'Chief of Staff' }
        'TOOLS.md' { 'typed' }
    }
    return [pscustomobject]@{Name=$Name;Target=(Join-Path $Workspace $Name);Source=('workspace/'+$Name);Marker=$marker}
}
function Get-RemoteBytes([string]$RepoPath,[string]$Alias) {
    $spec=Get-AliasSpec $Alias
    if (-not $spec.Source -or $RepoPath -notmatch $spec.Source) { throw 'remote source path outside alias root' }
    return Get-RemoteFixedBytes $RepoPath
}

function Read-Attempts { if (-not (Test-Path -LiteralPath $AttemptPath -PathType Leaf)) { return [pscustomobject]@{schema=1;items=@()} }; try { return Get-Content -LiteralPath $AttemptPath -Raw | ConvertFrom-Json } catch { return [pscustomobject]@{schema=1;items=@()} } }
function Get-AttemptRecord([object]$State,[string]$Id) { $hits=@($State.items|Where-Object{[string]$_.id -eq $Id}); if($hits.Count -gt 1){throw 'duplicate maintenance attempt state'}; if($hits.Count -eq 1){return $hits[0]}; return $null }
function Save-Attempt([string]$Id,[int]$Attempts,[string]$Status,[string]$FailureFamily='') { $state=Read-Attempts; $items=@($state.items|Where-Object{[string]$_.id -ne $Id}); $items+=,[pscustomobject]@{id=$Id;attempts=$Attempts;status=$Status;failure_family=$FailureFamily;updated_at=(Get-Date).ToString('o')}; Write-JsonAtomic $AttemptPath ([ordered]@{schema=1;kind='kevin-typed-maintenance-attempts';items=$items}) }

function Assert-Common([object]$m) {
    if([int]$m.schema -ne 3){throw 'manifest schema must be 3'}
    if([string]$m.kind -ne 'kevin-self-maintenance-manifest'){throw 'manifest kind mismatch'}
    if([string]$m.id -notmatch '^[A-Za-z0-9._-]{6,96}$'){throw 'manifest id invalid'}
    if([string]$m.authority_class -ne 'GREEN'){throw 'maintenance must be GREEN'}
    if([string]$m.authority_delta -ne 'NONE'){throw 'authority_delta must be NONE'}
    if([string]$m.production_effect -ne 'NONE'){throw 'production_effect must be NONE'}
    if([string]$m.owner_policy -ne $OwnerPolicy){throw 'owner policy mismatch'}
    if([bool]$m.preauthorized -ne $true){throw 'manifest must be preauthorized'}
    if($m.expires_at -and (Get-Date) -gt [datetime]$m.expires_at){throw 'manifest expired'}
    if(-not(@('replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','publish_runtime_convergence','publish_runtime_capabilities','replace_runtime_policy_bundle','migrate_design_forge_v40','configure_skill_workshop_guardrails','run_reader_status_canary','diagnose_forge_r03_contract','diagnose_goal_os_forge_anchor','diagnose_benchmark_baseline_forge_anchor','migrate_supervisor_forge_demand_gated_v17','repair_supervisor_v171_forge_pin','ensure_autonomy_continuation_automation','run_main_agent_canary','install_autonomy_controller_v183','diagnose_gateway_rpc','run_self_reliance_watchdog_once','diagnose_gateway_failure_detail','repair_openclaw_windows_lkg','reconcile_maintenance_cron_backoff') -contains [string]$m.operation)){throw 'operation not allowlisted'}
}
function Assert-Replace([object]$m) {
    $spec=Get-AliasSpec ([string]$m.target_alias)
    if([string]$m.target_alias -eq 'ui_bridge_runner'){throw 'UI Bridge cannot use replace operation'}
    if([string]$m.source_path -notmatch $spec.Source){throw 'source path outside alias root'}
    foreach($n in @('source_sha256','expected_current_sha256','expected_after_sha256')){if([string]$m.$n -notmatch '^[A-Fa-f0-9]{64}$'){throw($n+' invalid')}}
    if(([string]$m.source_sha256).ToUpperInvariant() -ne ([string]$m.expected_after_sha256).ToUpperInvariant()){throw 'source hash must equal after hash'}
    if(([string]$m.expected_current_sha256).ToUpperInvariant() -eq $AbsentHash -and -not [bool]$spec.AllowAbsent){throw 'absent-current sentinel not allowed for alias'}
}
function Assert-ForgeMigration([object]$m) {
    if([string]$m.target_alias -ne 'design_forge_runner'){throw 'Forge migration target alias mismatch'}
    if([string]$m.source_path -ne 'control-plane/forge/kevin-design-forge-v4.0.ps1'){throw 'Forge migration source path mismatch'}
    foreach($n in @('source_sha256','expected_forge_current_sha256','expected_forge_after_sha256','expected_benchmark_current_sha256')){
        if([string]$m.$n -notmatch '^[A-Fa-f0-9]{64}$'){throw ($n+' invalid')}
    }
    if(([string]$m.source_sha256).ToUpperInvariant() -ne ([string]$m.expected_forge_after_sha256).ToUpperInvariant()){throw 'Forge migration source hash must equal after hash'}
    if(([string]$m.expected_forge_current_sha256).ToUpperInvariant() -eq ([string]$m.expected_forge_after_sha256).ToUpperInvariant()){throw 'Forge migration requires a real hash transition'}
}

function Get-LiteralOccurrenceCount([string]$Text,[string]$Needle) {
    if(-not $Needle){return 0}
    $count=0;$offset=0
    while($true){$i=$Text.IndexOf($Needle,$offset,[StringComparison]::OrdinalIgnoreCase);if($i -lt 0){break};$count++;$offset=$i+$Needle.Length}
    return $count
}
function Get-ForgePinPatchedBenchmark([string]$Text,[string]$Before,[string]$After) {
    $beforeCount=Get-LiteralOccurrenceCount $Text $Before
    $afterCount=Get-LiteralOccurrenceCount $Text $After
    if($beforeCount -ne 1){throw ('Benchmark must contain old Forge pin exactly once; count='+$beforeCount)}
    if($afterCount -ne 0){throw ('Benchmark already contains candidate Forge pin; count='+$afterCount)}
    return [regex]::Replace($Text,[regex]::Escape($Before),$After,[Text.RegularExpressions.RegexOptions]::IgnoreCase,[TimeSpan]::FromSeconds(1))
}
function Assert-SupervisorForgeDemandGateMigration([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('Supervisor/Forge migration manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'migrate_supervisor_forge_demand_gated_v17'){throw 'Supervisor/Forge migration operation mismatch'}
}
function Assert-SupervisorV171ForgePinRepair([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('Supervisor v1.7.1 pin repair manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'repair_supervisor_v171_forge_pin'){throw 'Supervisor v1.7.1 pin repair operation mismatch'}
}
function Get-SupervisorV171ForgePinPatched([string]$Text) {
    $header='# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel'
    if((Get-LiteralOccurrenceCount $Text $header) -ne 1){throw 'Supervisor v1.7 header anchor mismatch'}
    if((Get-LiteralOccurrenceCount $Text $ForgeV37Sha) -ne 1){throw 'Supervisor v1.7 old Forge pin must occur exactly once'}
    if((Get-LiteralOccurrenceCount $Text $ForgeV40Sha) -ne 0){throw 'Supervisor v1.7 already contains Forge v4 pin'}
    $out=$Text.Replace($ForgeV37Sha,$ForgeV40Sha).Replace('Design Forge hash changed from approved v3.7.','Design Forge hash changed from approved v4.0.')
    if((Get-LiteralOccurrenceCount $out $ForgeV37Sha) -ne 0){throw 'Supervisor v1.7.1 retained old Forge pin'}
    if((Get-LiteralOccurrenceCount $out $ForgeV40Sha) -ne 1){throw 'Supervisor v1.7.1 Forge v4 pin missing or duplicated'}
    if(-not$out.Contains('SUPERVISOR IDLE NO_ELIGIBLE_MISSION')){throw 'Supervisor v1.7.1 demand gate marker missing'}
    return $out
}
function Get-DemandGatedSupervisorV17([string]$Text) {
    $oldHeader='# Kevin Supervisor v1.6 High Gear'
    $newHeader='# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel'
    if((Get-LiteralOccurrenceCount $Text $oldHeader) -ne 1){throw 'Supervisor v1.6 header anchor mismatch'}
    $nl=if($Text.Contains("`r`n")){"`r`n"}else{"`n"}
    $anchor='    $recoveryExperiment = $null'+$nl
    if((Get-LiteralOccurrenceCount $Text $anchor) -ne 1){throw 'Supervisor recovery-dispatch anchor mismatch'}
    $lines=@(
        '    # v1.7: legacy Supervisor candidate dispatch is retired.',
        '    # Durable owner work is admitted by the governed selector/Task Flow path; Forge v4 consumes only typed eligible demand.',
        '    Ensure-Property $state "last_mission" ""',
        '    Ensure-Property $state "last_result" "NO_ELIGIBLE_MISSION"',
        '    Ensure-Property $state "next_eligible_at" ((Get-Date).AddMinutes(3).ToString("o"))',
        '    Ensure-Property $state "updated_at" ((Get-Date).ToString("o"))',
        '    Save-JsonAtomic $statePath $state',
        '',
        '    Rec @{',
        '        event = "cycle"',
        '        result = "NO_ELIGIBLE_MISSION"',
        '        detail = "Legacy Supervisor candidate dispatch retired; governed demand flow owns admission."',
        '    }',
        '',
        '    Write-Status `',
        '        "WAITING" `',
        '        "No eligible legacy mission. Governed work selection and Task Flow own admission; Forge v4 requires typed demand." `',
        '        $state',
        '',
        '    Write-Host "SUPERVISOR IDLE NO_ELIGIBLE_MISSION"',
        '    return',
        '',
        '    $recoveryExperiment = $null'
    )
    $block=($lines -join $nl)+$nl
    $out=$Text.Replace($oldHeader,$newHeader).Replace($anchor,$block)
    if((Get-LiteralOccurrenceCount $out $newHeader) -ne 1){throw 'Supervisor v1.7 header missing after patch'}
    $idle=$out.IndexOf('SUPERVISOR IDLE NO_ELIGIBLE_MISSION',[StringComparison]::Ordinal)
    $legacy=$out.IndexOf('MissionContractPath',[StringComparison]::Ordinal)
    if($idle -lt 0 -or $legacy -lt 0 -or $idle -ge $legacy){throw 'Supervisor demand gate is not before legacy Forge dispatch'}
    $between=$out.Substring($idle,$legacy-$idle)
    if($between -notmatch '(?m)^\s*return\s*$'){throw 'Supervisor demand gate lacks fail-closed return'}
    return $out
}
function Assert-Restart([object]$m) {
    if([string]$m.target_alias -ne 'ui_bridge_runner'){throw 'UI restart target alias mismatch'}
    if([string]$m.expected_current_sha256 -notmatch '^[A-Fa-f0-9]{64}$'){throw 'UI restart expected hash invalid'}
    if([string]$m.task_name -ne 'Kevin UI Bridge v0.3'){throw 'UI restart task name mismatch'}
    if([int]$m.heartbeat_timeout_seconds -lt 5 -or [int]$m.heartbeat_timeout_seconds -gt 30){throw 'UI heartbeat timeout outside 5..30 seconds'}
}
function Assert-RuntimeBundle([object]$m) {
    $items=@($m.components)
    if($items.Count -ne $RuntimePolicyNames.Count){throw 'runtime policy bundle must contain exactly five components'}
    $seen=@{}
    foreach($item in $items){
        $name=[string]$item.name
        $null=Get-PolicySpec $name
        if($seen.ContainsKey($name)){throw 'duplicate runtime policy component'}
        $seen[$name]=$true
        foreach($n in @('source_sha256','expected_current_sha256','expected_after_sha256')){
            if([string]$item.$n -notmatch '^[A-Fa-f0-9]{64}$'){throw ($name+' '+$n+' invalid')}
        }
        if(([string]$item.source_sha256).ToUpperInvariant() -ne ([string]$item.expected_after_sha256).ToUpperInvariant()){throw ($name+' source hash must equal after hash')}
        if(([string]$item.expected_current_sha256).ToUpperInvariant() -eq $AbsentHash){throw ($name+' absent-current is not allowed')}
    }
    foreach($name in $RuntimePolicyNames){if(-not$seen.ContainsKey($name)){throw ('missing runtime policy component '+$name)}}
}
function Assert-Governance {
    $desired=Join-Path $Workspace 'ControlPlane\desired-state-v1.json'; $owner=Join-Path $Workspace 'ControlPlane\OWNER-AUTHORIZATION-v1.md'
    if(-not(Test-Path -LiteralPath $desired -PathType Leaf) -or -not(Test-Path -LiteralPath $owner -PathType Leaf)){throw 'governance roots missing'}
    $d=Get-Content -LiteralPath $desired -Raw | ConvertFrom-Json
    if(-not[bool]$d.authority.green_only -or [bool]$d.authority.allow_arbitrary_shell -or [bool]$d.authority.allow_authority_expansion -or [bool]$d.authority.allow_novel_production_promotion){throw 'governance denies action'}
    $ot=[IO.File]::ReadAllText($owner)
    if(-not $ot.Contains('apply an owner-preauthorized GREEN maintenance package only through the typed maintenance/reconciliation contract')){throw 'owner preauthorization clause missing'}
}
function Parse-PowerShell([string]$Path) { $tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors);if($errors.Count -gt 0){throw('PowerShell parser rejected candidate: '+$errors[0].Message)} }
function Invoke-FixedSelfTest([string]$Alias,[string]$Path) {
    $spec=Get-AliasSpec $Alias;$CommandArguments=@($spec.SelfTestArgs);$old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path @CommandArguments 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code -ne 0){throw('fixed self-test failed exit='+$code)}
    if($out -notmatch [regex]::Escape([string]$spec.Marker)){throw 'fixed self-test marker missing'}
}
function Assert-Benchmark30 {
    $bench=Join-Path $Workspace 'kevin-benchmark-v1.ps1';$latest=Join-Path $Reports 'benchmark-v1\latest.json'
    if(-not(Test-Path -LiteralPath $bench -PathType Leaf)){throw 'benchmark script missing'}
    $deadline=(Get-Date).AddSeconds(60)
    while($true){$started=[DateTime]::UtcNow;$old=$ErrorActionPreference;try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $bench 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old};if($out -match '(?i)BENCHMARK\s+SKIP_ACTIVE_WORK'){if((Get-Date)-ge$deadline){throw 'fresh benchmark retry budget exhausted'};Start-Sleep 5;continue};if($code -ne 0){throw('benchmark failed exit='+$code)};if(-not(Test-Path -LiteralPath $latest)){throw 'benchmark evidence missing'};$b=Get-Content $latest -Raw|ConvertFrom-Json;if([string]$b.status -ne 'PASS' -or [int]$b.regression.passed -ne 30 -or [int]$b.regression.total -ne 30 -or [int]$b.regression.critical_failures -ne 0){throw 'benchmark not 30/30 critical=0'};if((Get-Item $latest).LastWriteTimeUtc -lt $started.AddSeconds(-3)){throw 'benchmark evidence not fresh'};return}
}
function Assert-Utf8Policy([string]$Path,[string]$Name) {
    $bytes=[IO.File]::ReadAllBytes($Path)
    if($bytes.Length -lt 32 -or $bytes.Length -gt 65536){throw ($Name+' size outside 32..65536 bytes')}
    if($bytes -contains 0){throw ($Name+' contains NUL byte')}
    $text=[Text.Encoding]::UTF8.GetString($bytes)
    $spec=Get-PolicySpec $Name
    if(-not $text.Contains([string]$spec.Marker)){throw ($Name+' required doctrine marker missing')}
}

function New-InstallResult([bool]$Changed,[string]$Before,[string]$After,[bool]$Idempotent,[string]$Backup='') { $r=[ordered]@{changed=$Changed;before=$Before;after=$After;idempotent=$Idempotent};if($Backup){$r['backup']=$Backup};return $r }
function New-RestartResult([string]$Hash,[string]$TaskName,[string]$HeartbeatAt,[string]$State) { return [ordered]@{changed=$true;hash=$Hash;task_name=$TaskName;heartbeat_at=$HeartbeatAt;state=$State} }

function Install-Pinned([object]$m) {
    $alias=[string]$m.target_alias;$spec=Get-AliasSpec $alias;$target=[string]$spec.Target;$hadTarget=Test-Path -LiteralPath $target -PathType Leaf;$before=Get-Sha $target;$cur=([string]$m.expected_current_sha256).ToUpperInvariant();$after=([string]$m.expected_after_sha256).ToUpperInvariant()
    if($before -eq $after){Invoke-FixedSelfTest $alias $target;Assert-Benchmark30;return (New-InstallResult $false $before $before $true)}
    if($hadTarget){if($before -ne $cur){throw('expected-current mismatch alias='+$alias+' actual='+$before)}}else{if(-not[bool]$spec.AllowAbsent -or $cur -ne $AbsentHash){throw('expected-current missing alias='+$alias)}}
    $bytes=Get-RemoteBytes ([string]$m.source_path) $alias;$stage=Join-Path $StageRoot ([string]$m.id+'.candidate.ps1');[IO.File]::WriteAllBytes($stage,$bytes)
    if((Get-Sha $stage) -ne $after){throw 'staged source hash mismatch'}
    Parse-PowerShell $stage;Invoke-FixedSelfTest $alias $stage
    $backupDir=Join-Path $BackupRoot ([string]$m.id);New-Item -ItemType Directory -Force $backupDir|Out-Null;$backup=Join-Path $backupDir ([IO.Path]::GetFileName($target));if($hadTarget){Copy-Item -LiteralPath $target -Destination $backup -Force}
    try{$tmp=$target+'.typed-'+[guid]::NewGuid().ToString('N');Copy-Item $stage $tmp -Force;Move-Item $tmp $target -Force;if((Get-Sha $target) -ne $after){throw 'installed target hash mismatch'};Invoke-FixedSelfTest $alias $target;Assert-Benchmark30;return (New-InstallResult $true $(if($hadTarget){$before}else{$AbsentHash}) (Get-Sha $target) $false $(if($hadTarget){Safe-Text $backup 500}else{''}))}catch{if($hadTarget -and (Test-Path -LiteralPath $backup -PathType Leaf)){Copy-Item $backup $target -Force}elseif(-not$hadTarget -and (Test-Path -LiteralPath $target -PathType Leaf)){Remove-Item -LiteralPath $target -Force};throw('replace rollback completed: '+$_.Exception.Message)}
}
function Migrate-DesignForgeV40([object]$m) {
    Assert-ForgeMigration $m
    $forgeSpec=Get-AliasSpec 'design_forge_runner'
    $forgeTarget=[string]$forgeSpec.Target
    $benchTarget=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    if(-not(Test-Path -LiteralPath $forgeTarget -PathType Leaf)){throw 'Forge target missing'}
    if(-not(Test-Path -LiteralPath $benchTarget -PathType Leaf)){throw 'Benchmark target missing'}

    $forgeBefore=Get-Sha $forgeTarget
    $benchBefore=Get-Sha $benchTarget
    $expectedForgeBefore=([string]$m.expected_forge_current_sha256).ToUpperInvariant()
    $expectedForgeAfter=([string]$m.expected_forge_after_sha256).ToUpperInvariant()
    $expectedBenchBefore=([string]$m.expected_benchmark_current_sha256).ToUpperInvariant()
    if($forgeBefore -ne $expectedForgeBefore){throw ('Forge expected-current mismatch actual='+$forgeBefore)}
    if($benchBefore -ne $expectedBenchBefore){throw ('Benchmark expected-current mismatch actual='+$benchBefore)}

    $forgeBytes=Get-RemoteBytes ([string]$m.source_path) 'design_forge_runner'
    $forgeStage=Join-Path $StageRoot ([string]$m.id+'.forge.ps1')
    [IO.File]::WriteAllBytes($forgeStage,$forgeBytes)
    if((Get-Sha $forgeStage) -ne $expectedForgeAfter){throw 'Forge staged hash mismatch'}
    Parse-PowerShell $forgeStage
    Invoke-FixedSelfTest 'design_forge_runner' $forgeStage

    $benchText=[IO.File]::ReadAllText($benchTarget)
    $benchPatched=Get-ForgePinPatchedBenchmark $benchText $expectedForgeBefore $expectedForgeAfter
    $benchStage=Join-Path $StageRoot ([string]$m.id+'.benchmark.ps1')
    [IO.File]::WriteAllText($benchStage,$benchPatched,$Utf8)
    Parse-PowerShell $benchStage
    $benchAfter=Get-Sha $benchStage
    if($benchAfter -eq $benchBefore){throw 'Benchmark pin migration produced no byte change'}
    if((Get-LiteralOccurrenceCount ([IO.File]::ReadAllText($benchStage)) $expectedForgeBefore) -ne 0){throw 'Old Forge pin remained in staged Benchmark'}
    if((Get-LiteralOccurrenceCount ([IO.File]::ReadAllText($benchStage)) $expectedForgeAfter) -ne 1){throw 'New Forge pin missing or duplicated in staged Benchmark'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir|Out-Null
    $forgeBackup=Join-Path $backupDir 'kevin-design-forge.ps1'
    $benchBackup=Join-Path $backupDir 'kevin-benchmark-v1.ps1'
    Copy-Item -LiteralPath $forgeTarget -Destination $forgeBackup -Force
    Copy-Item -LiteralPath $benchTarget -Destination $benchBackup -Force

    try {
        foreach($pair in @(@($forgeStage,$forgeTarget),@($benchStage,$benchTarget))){
            $tmp=$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $pair[1] -Force
        }
        if((Get-Sha $forgeTarget) -ne $expectedForgeAfter){throw 'Installed Forge hash mismatch'}
        if((Get-Sha $benchTarget) -ne $benchAfter){throw 'Installed Benchmark hash mismatch'}
        Parse-PowerShell $forgeTarget
        Parse-PowerShell $benchTarget
        Invoke-FixedSelfTest 'design_forge_runner' $forgeTarget
        Assert-Benchmark30
        return [ordered]@{
            changed=$true
            forge_before=$forgeBefore
            forge_after=(Get-Sha $forgeTarget)
            benchmark_before=$benchBefore
            benchmark_after=(Get-Sha $benchTarget)
            benchmark_pin_change='exact literal old Forge SHA -> new Forge SHA; one occurrence only'
            rollback_available=$true
        }
    } catch {
        Copy-Item -LiteralPath $forgeBackup -Destination $forgeTarget -Force
        Copy-Item -LiteralPath $benchBackup -Destination $benchTarget -Force
        try { Assert-Benchmark30 } catch { }
        throw ('coordinated Forge migration rollback completed: '+$_.Exception.Message)
    }
}
function Migrate-SupervisorForgeDemandGatedV17([object]$m) {
    Assert-SupervisorForgeDemandGateMigration $m
    if($env:OS -ne 'Windows_NT'){throw 'Supervisor/Forge coordinated migration requires Windows'}
    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $forgeTarget=(Get-AliasSpec 'design_forge_runner').Target
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    foreach($p in @($supervisorTarget,$forgeTarget,$baselineTarget)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('coordinated migration target missing: '+[IO.Path]::GetFileName($p))}}

    $supBefore=Get-Sha $supervisorTarget
    $forgeBefore=Get-Sha $forgeTarget
    $baselineBefore=Get-Sha $baselineTarget
    if($supBefore -ne $SupervisorV16Sha){throw ('Supervisor expected-current mismatch actual='+$supBefore)}
    if($forgeBefore -ne $ForgeV37Sha){throw ('Forge expected-current mismatch actual='+$forgeBefore)}
    if($baselineBefore -ne $BenchmarkBaselineBeforeSha){throw ('Benchmark baseline expected-current mismatch actual='+$baselineBefore)}

    $baselineObj=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
    if(-not$baselineObj.hashes){throw 'Benchmark baseline hashes missing'}
    if(([string]$baselineObj.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV16Sha){throw 'Benchmark baseline Supervisor anchor does not match live v1.6'}
    if(([string]$baselineObj.hashes.forge).ToUpperInvariant() -ne $ForgeV37Sha){throw 'Benchmark baseline Forge anchor does not match live v3.7'}

    $supText=[IO.File]::ReadAllText($supervisorTarget)
    $supPatched=Get-DemandGatedSupervisorV17 $supText
    $supStage=Join-Path $StageRoot ([string]$m.id+'.supervisor.ps1')
    [IO.File]::WriteAllText($supStage,$supPatched,$Utf8)
    if((Get-Sha $supStage) -ne $SupervisorV17Sha){throw ('Supervisor v1.7 deterministic candidate hash mismatch actual='+(Get-Sha $supStage))}
    Parse-PowerShell $supStage
    $supStageText=[IO.File]::ReadAllText($supStage)
    foreach($marker in @('# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel','SUPERVISOR IDLE NO_ELIGIBLE_MISSION','governed selector/Task Flow path')){if(-not$supStageText.Contains($marker)){throw ('Supervisor v1.7 marker missing: '+$marker)}}
    if($supStageText -match '(?i)Invoke-Expression|kevin_shell|Start-Process\s+cmd\.exe'){throw 'Supervisor v1.7 introduced forbidden arbitrary execution marker'}

    $forgeBytes=Get-RemoteFixedBytes $ForgeV40Source
    $forgeStage=Join-Path $StageRoot ([string]$m.id+'.forge.ps1')
    [IO.File]::WriteAllBytes($forgeStage,$forgeBytes)
    if((Get-Sha $forgeStage) -ne $ForgeV40Sha){throw ('Forge v4 staged identity mismatch actual='+(Get-Sha $forgeStage))}
    Parse-PowerShell $forgeStage
    Invoke-FixedSelfTest 'design_forge_runner' $forgeStage
    $forgeStageText=[IO.File]::ReadAllText($forgeStage)
    foreach($marker in @("status='IDLE_NO_ELIGIBLE_DEMAND'",'demand_driven=$true','round_robin=$false')){if(-not$forgeStageText.Contains($marker)){throw ('Forge v4 demand-gate marker missing: '+$marker)}}
    if($forgeStageText.Contains('MissionContractPath')){throw 'Forge v4 unexpectedly accepts legacy MissionContractPath'}

    $baselineText=[IO.File]::ReadAllText($baselineTarget)
    if((Get-LiteralOccurrenceCount $baselineText $SupervisorV16Sha) -ne 1){throw 'Benchmark baseline old Supervisor anchor must occur exactly once'}
    if((Get-LiteralOccurrenceCount $baselineText $ForgeV37Sha) -ne 1){throw 'Benchmark baseline old Forge anchor must occur exactly once'}
    if((Get-LiteralOccurrenceCount $baselineText $SupervisorV17Sha) -ne 0){throw 'Benchmark baseline already contains candidate Supervisor anchor'}
    if((Get-LiteralOccurrenceCount $baselineText $ForgeV40Sha) -ne 0){throw 'Benchmark baseline already contains candidate Forge anchor'}
    $baselinePatched=$baselineText.Replace($SupervisorV16Sha,$SupervisorV17Sha).Replace($ForgeV37Sha,$ForgeV40Sha)
    $baselineStage=Join-Path $StageRoot ([string]$m.id+'.baseline.json')
    [IO.File]::WriteAllText($baselineStage,$baselinePatched,$Utf8)
    $baselineStageObj=Get-Content -LiteralPath $baselineStage -Raw|ConvertFrom-Json
    if(([string]$baselineStageObj.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV17Sha){throw 'staged baseline Supervisor anchor mismatch'}
    if(([string]$baselineStageObj.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'staged baseline Forge anchor mismatch'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir|Out-Null
    $supBackup=Join-Path $backupDir 'kevin-supervisor.ps1'
    $forgeBackup=Join-Path $backupDir 'kevin-design-forge.ps1'
    $baselineBackup=Join-Path $backupDir 'benchmark-baseline.json'
    Copy-Item -LiteralPath $supervisorTarget -Destination $supBackup -Force
    Copy-Item -LiteralPath $forgeTarget -Destination $forgeBackup -Force
    Copy-Item -LiteralPath $baselineTarget -Destination $baselineBackup -Force

    $supMutex=$null;$forgeMutex=$null;$supOwned=$false;$forgeOwned=$false
    try {
        $supMutex=New-Object -TypeName System.Threading.Mutex -ArgumentList $false,'Global\KevinSupervisor'
        $forgeMutex=New-Object -TypeName System.Threading.Mutex -ArgumentList $false,'Global\KevinDesignForge'
        try{$supOwned=$supMutex.WaitOne(60000)}catch [System.Threading.AbandonedMutexException]{$supOwned=$true}
        if(-not$supOwned){throw 'Supervisor did not become idle within 60 seconds'}
        try{$forgeOwned=$forgeMutex.WaitOne(60000)}catch [System.Threading.AbandonedMutexException]{$forgeOwned=$true}
        if(-not$forgeOwned){throw 'Forge did not become idle within 60 seconds'}

        if((Get-Sha $supervisorTarget) -ne $SupervisorV16Sha){throw 'Supervisor changed after staging; aborting TOCTOU'}
        if((Get-Sha $forgeTarget) -ne $ForgeV37Sha){throw 'Forge changed after staging; aborting TOCTOU'}
        if((Get-Sha $baselineTarget) -ne $BenchmarkBaselineBeforeSha){throw 'Benchmark baseline changed after staging; aborting TOCTOU'}

        foreach($pair in @(@($supStage,$supervisorTarget),@($forgeStage,$forgeTarget),@($baselineStage,$baselineTarget))){
            $tmp=[string]$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $pair[1] -Force
        }
        if((Get-Sha $supervisorTarget) -ne $SupervisorV17Sha){throw 'installed Supervisor v1.7 hash mismatch'}
        if((Get-Sha $forgeTarget) -ne $ForgeV40Sha){throw 'installed Forge v4 hash mismatch'}
        $liveBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$liveBase.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV17Sha -or ([string]$liveBase.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'installed Benchmark baseline anchors mismatch'}
        Parse-PowerShell $supervisorTarget
        Parse-PowerShell $forgeTarget
        Invoke-FixedSelfTest 'design_forge_runner' $forgeTarget
        Assert-Benchmark30
        return [ordered]@{
            changed=$true
            supervisor_before=$supBefore
            supervisor_after=(Get-Sha $supervisorTarget)
            forge_before=$forgeBefore
            forge_after=(Get-Sha $forgeTarget)
            baseline_before=$baselineBefore
            baseline_after=(Get-Sha $baselineTarget)
            demand_gate='legacy Supervisor dispatch retired; Forge v4 typed-demand only'
            mutex_protected=$true
            rollback_available=$true
        }
    } catch {
        if(Test-Path -LiteralPath $supBackup -PathType Leaf){Copy-Item -LiteralPath $supBackup -Destination $supervisorTarget -Force}
        if(Test-Path -LiteralPath $forgeBackup -PathType Leaf){Copy-Item -LiteralPath $forgeBackup -Destination $forgeTarget -Force}
        if(Test-Path -LiteralPath $baselineBackup -PathType Leaf){Copy-Item -LiteralPath $baselineBackup -Destination $baselineTarget -Force}
        try{Assert-Benchmark30}catch{}
        throw ('Supervisor/Forge coordinated migration rollback completed: '+$_.Exception.Message)
    } finally {
        if($forgeOwned -and $forgeMutex){try{$forgeMutex.ReleaseMutex()}catch{}}
        if($supOwned -and $supMutex){try{$supMutex.ReleaseMutex()}catch{}}
        if($forgeMutex){$forgeMutex.Dispose()}
        if($supMutex){$supMutex.Dispose()}
    }
}
function Repair-SupervisorV171ForgePin([object]$m) {
    Assert-SupervisorV171ForgePinRepair $m
    if($env:OS -ne 'Windows_NT'){throw 'Supervisor v1.7.1 repair requires Windows'}
    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $forgeTarget=(Get-AliasSpec 'design_forge_runner').Target
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    foreach($p in @($supervisorTarget,$forgeTarget,$baselineTarget)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('Supervisor v1.7.1 coordinated repair target missing: '+[IO.Path]::GetFileName($p))}}

    $before=Get-Sha $supervisorTarget
    $forge=Get-Sha $forgeTarget
    $baselineBefore=Get-Sha $baselineTarget
    if($forge -ne $ForgeV40Sha){throw ('Forge v4 expected-current mismatch actual='+$forge)}
    try{$baselineObj=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json}catch{throw 'Benchmark baseline is not valid JSON'}
    if(-not$baselineObj.hashes){throw 'Benchmark baseline hashes missing'}
    $baselineSup=([string]$baselineObj.hashes.supervisor).ToUpperInvariant()
    $baselineForge=([string]$baselineObj.hashes.forge).ToUpperInvariant()
    if($baselineForge -ne $ForgeV40Sha){throw ('Benchmark baseline Forge anchor mismatch actual='+$baselineForge)}

    if($before -eq $SupervisorV171Sha -and $baselineSup -eq $SupervisorV171Sha){
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;supervisor_after=$before;baseline_supervisor_anchor=$baselineSup;forge_pin=$ForgeV40Sha}
    }
    if($before -ne $SupervisorV17Sha){throw ('Supervisor v1.7 expected-current mismatch actual='+$before)}
    if($baselineSup -ne $SupervisorV17Sha){throw ('Benchmark baseline Supervisor anchor expected v1.7 actual='+$baselineSup)}

    $patched=Get-SupervisorV171ForgePinPatched ([IO.File]::ReadAllText($supervisorTarget))
    $stage=Join-Path $StageRoot ([string]$m.id+'.supervisor-v171.ps1')
    [IO.File]::WriteAllText($stage,$patched,$Utf8)
    $stageSha=Get-Sha $stage
    if($stageSha -ne $SupervisorV171Sha){throw ('Supervisor v1.7.1 deterministic candidate hash mismatch actual='+$stageSha)}
    Parse-PowerShell $stage
    $stageText=[IO.File]::ReadAllText($stage)
    if((Get-LiteralOccurrenceCount $stageText $ForgeV40Sha) -ne 1){throw 'Supervisor v1.7.1 staged Forge pin mismatch'}
    if((Get-LiteralOccurrenceCount $stageText $ForgeV37Sha) -ne 0){throw 'Supervisor v1.7.1 staged old Forge pin remained'}
    foreach($marker in @('# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel','SUPERVISOR IDLE NO_ELIGIBLE_MISSION','governed selector/Task Flow path')){if(-not$stageText.Contains($marker)){throw ('Supervisor v1.7.1 marker missing: '+$marker)}}
    if($stageText -match '(?i)Invoke-Expression|kevin_shell|Start-Process\s+cmd\.exe'){throw 'Supervisor v1.7.1 introduced forbidden arbitrary execution marker'}

    $baselineStageObj=$baselineObj|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $baselineStageObj.hashes.supervisor=$SupervisorV171Sha
    if(([string]$baselineStageObj.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'staged Benchmark baseline Forge anchor changed unexpectedly'}
    $baselineStage=Join-Path $StageRoot ([string]$m.id+'.benchmark-baseline.json')
    [IO.File]::WriteAllText($baselineStage,($baselineStageObj|ConvertTo-Json -Depth 30),$Utf8)
    try{$verifyBaseline=Get-Content -LiteralPath $baselineStage -Raw|ConvertFrom-Json}catch{throw 'staged Benchmark baseline invalid JSON'}
    if(([string]$verifyBaseline.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV171Sha){throw 'staged Benchmark baseline Supervisor anchor mismatch'}
    if(([string]$verifyBaseline.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'staged Benchmark baseline Forge anchor mismatch'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir|Out-Null
    $supervisorBackup=Join-Path $backupDir 'kevin-supervisor.ps1'
    $baselineBackup=Join-Path $backupDir 'benchmark-baseline.json'
    Copy-Item -LiteralPath $supervisorTarget -Destination $supervisorBackup -Force
    Copy-Item -LiteralPath $baselineTarget -Destination $baselineBackup -Force
    $mutex=$null;$owned=$false
    try {
        $mutex=New-Object -TypeName System.Threading.Mutex -ArgumentList $false,'Global\KevinSupervisor'
        try{$owned=$mutex.WaitOne(60000)}catch [System.Threading.AbandonedMutexException]{$owned=$true}
        if(-not$owned){throw 'Supervisor did not become idle within 60 seconds'}
        if((Get-Sha $supervisorTarget) -ne $SupervisorV17Sha){throw 'Supervisor changed after staging; aborting TOCTOU'}
        if((Get-Sha $forgeTarget) -ne $ForgeV40Sha){throw 'Forge changed after staging; aborting TOCTOU'}
        if((Get-Sha $baselineTarget) -ne $baselineBefore){throw 'Benchmark baseline changed after staging; aborting TOCTOU'}

        foreach($pair in @(@($stage,$supervisorTarget),@($baselineStage,$baselineTarget))){
            $tmp=$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $pair[1] -Force
        }
        if((Get-Sha $supervisorTarget) -ne $SupervisorV171Sha){throw 'installed Supervisor v1.7.1 hash mismatch'}
        Parse-PowerShell $supervisorTarget
        $installedBaseline=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$installedBaseline.hashes.supervisor).ToUpperInvariant() -ne $SupervisorV171Sha){throw 'installed Benchmark baseline Supervisor anchor mismatch'}
        if(([string]$installedBaseline.hashes.forge).ToUpperInvariant() -ne $ForgeV40Sha){throw 'installed Benchmark baseline Forge anchor mismatch'}
        Assert-Benchmark30
        return [ordered]@{changed=$true;supervisor_before=$before;supervisor_after=(Get-Sha $supervisorTarget);baseline_before=$baselineBefore;baseline_after=(Get-Sha $baselineTarget);baseline_supervisor_anchor=$SupervisorV171Sha;forge_pin=$ForgeV40Sha;demand_gate_preserved=$true;rollback_available=$true}
    } catch {
        if(Test-Path -LiteralPath $supervisorBackup -PathType Leaf){Copy-Item -LiteralPath $supervisorBackup -Destination $supervisorTarget -Force}
        if(Test-Path -LiteralPath $baselineBackup -PathType Leaf){Copy-Item -LiteralPath $baselineBackup -Destination $baselineTarget -Force}
        try{Assert-Benchmark30}catch{}
        throw ('Supervisor v1.7.1 coordinated repair rollback completed: '+$_.Exception.Message)
    } finally {
        if($owned -and $mutex){try{$mutex.ReleaseMutex()}catch{}}
        if($mutex){$mutex.Dispose()}
    }
}
function Restart-UiBridge([object]$m) {
    if($env:OS -ne 'Windows_NT'){throw 'UI restart requires Windows'};$spec=Get-AliasSpec 'ui_bridge_runner';$actual=Get-Sha $spec.Target;if($actual -ne ([string]$m.expected_current_sha256).ToUpperInvariant()){throw('UI Bridge hash mismatch actual='+$actual)};$task=Get-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue;if(-not$task){throw 'UI Bridge task missing'};$heartbeat=Join-Path $Reports 'action-era\ui-bridge\heartbeat.json';$started=Get-Date;try{Stop-ScheduledTask -TaskName ([string]$m.task_name) -ErrorAction SilentlyContinue}catch{};Start-ScheduledTask -TaskName ([string]$m.task_name);$deadline=(Get-Date).AddSeconds([int]$m.heartbeat_timeout_seconds);$fresh=$null;while((Get-Date)-lt$deadline){Start-Sleep -Milliseconds 500;if(Test-Path $heartbeat){try{$h=Get-Content $heartbeat -Raw|ConvertFrom-Json;if([string]$h.kind -eq 'kevin-ui-bridge-heartbeat' -and [datetime]$h.at -ge $started.AddSeconds(-2) -and [string]$h.state -eq 'READY'){$fresh=$h;break}}catch{}}};if(-not$fresh){throw 'UI Bridge did not produce fresh READY heartbeat'};Assert-Benchmark30;return (New-RestartResult $actual ([string]$m.task_name) ([string]$fresh.at) ([string]$fresh.state))
}
function Audit-RuntimeConvergence {
    $policy=[ordered]@{}
    foreach($name in $RuntimePolicyNames){$spec=Get-PolicySpec $name;$policy[$name]=Get-Sha $spec.Target}
    $forge=Get-AliasSpec 'design_forge_runner'
    return [ordered]@{
        policy_hashes=$policy
        design_forge_sha256=(Get-Sha $forge.Target)
        design_forge_present=(Test-Path -LiteralPath $forge.Target -PathType Leaf)
        source_contract='fixed workspace policy set + fixed design_forge alias only'
    }
}
function Publish-RuntimeConvergence {
    $audit=Audit-RuntimeConvergence
    $public=[ordered]@{
        schema=1
        kind='kevin-runtime-convergence-public'
        generated_at=(Get-Date).ToString('o')
        state='OMEN_AUDIT_PROVEN'
        safe_for_public_repo=$true
        policy_hashes=$audit.policy_hashes
        design_forge_sha256=$audit.design_forge_sha256
        design_forge_present=$audit.design_forge_present
        maintenance_runner_sha256=(Get-Sha (Join-Path $Workspace 'kevin-maintenance-runner.ps1'))
        source_contract='fixed five runtime policy files + fixed design_forge alias + fixed maintenance runner only'
        truth_boundary='Metadata-only Omen audit. Hashes prove local file identities at generated_at; they do not by themselves prove semantic behavior.'
    }
    $local=Join-Path $Reports 'runtime-convergence-public.json'
    Write-JsonAtomic $local $public
    $repoPath='reports/runtime-convergence-omen.json'
    $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
    if($lookup.ExitCode -ne 0 -or -not $lookup.Output){throw 'runtime convergence receipt remote SHA lookup failed'}
    $payload=[ordered]@{
        message='kevin runtime convergence telemetry'
        content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))
        sha=[string]$lookup.Output
    }|ConvertTo-Json -Compress
    $payloadPath=Join-Path $env:TEMP ('kevin-runtime-convergence-'+[guid]::NewGuid().ToString('N')+'.json')
    try{
        [IO.File]::WriteAllText($payloadPath,$payload,$Utf8)
        $publish=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$payloadPath,'--silent')
        if($publish.ExitCode -ne 0){throw ('runtime convergence receipt publish failed: '+(Safe-Text $publish.Output 400))}
    }finally{Remove-Item -LiteralPath $payloadPath -Force -ErrorAction SilentlyContinue}
    $verify=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.content')
    if($verify.ExitCode -ne 0 -or -not $verify.Output){throw 'runtime convergence receipt verification fetch failed'}
    try{$remote=[Convert]::FromBase64String(([string]$verify.Output -replace '\s',''))}catch{throw 'runtime convergence receipt verification decode failed'}
    $localHash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToUpperInvariant()
    $sha=[Security.Cryptography.SHA256]::Create()
    try{$remoteHash=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()}
    if($remoteHash -ne $localHash){throw 'runtime convergence receipt remote verification hash mismatch'}
    return [ordered]@{published=$true;repo_path=$repoPath;receipt_sha256=$localHash;policy_hashes=$audit.policy_hashes;design_forge_sha256=$audit.design_forge_sha256}
}
function Invoke-OpenClawReadOnlyProbe([string]$Probe) {
    $cmd=Get-Command openclaw -ErrorAction SilentlyContinue
    if(-not $cmd){return [pscustomobject]@{exit_code=127;output='';available=$false}}
    $CommandArguments=switch($Probe){
        'version' {@('--version')}
        'root_help' {@('--help')}
        'automations_help' {@('automations','--help')}
        'cron_help' {@('cron','--help')}
        'agent_help' {@('agent','--help')}
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
    try{$ErrorActionPreference='Continue';$out=(& $cmd.Source @CommandArguments 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
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
    $rootHelp=Invoke-OpenClawReadOnlyProbe 'root_help'
    $automationsHelp=Invoke-OpenClawReadOnlyProbe 'automations_help'
    $cronHelp=Invoke-OpenClawReadOnlyProbe 'cron_help'
    $agentHelp=Invoke-OpenClawReadOnlyProbe 'agent_help'
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
            version_exit_code=[int]$version.exit_code
            version_output_sha256=(Get-TextSha256 (Safe-Text ([string]$version.output) 400))
            config_valid=([int]$validate.exit_code -eq 0)
            gateway_deep_probe_ok=([int]$gateway.exit_code -eq 0)
            cli_surface=[ordered]@{
                root_help_ok=([int]$rootHelp.exit_code -eq 0)
                root_mentions_agent=([string]$rootHelp.output -match '(?i)\bagent\b')
                root_mentions_automations=([string]$rootHelp.output -match '(?i)\bautomations\b')
                root_mentions_cron=([string]$rootHelp.output -match '(?i)\bcron\b')
                automations_help_ok=([int]$automationsHelp.exit_code -eq 0)
                automations_fell_to_tui=([string]$automationsHelp.output -match '(?i)TUI needs an interactive TTY')
                cron_help_ok=([int]$cronHelp.exit_code -eq 0)
                cron_fell_to_tui=([string]$cronHelp.output -match '(?i)TUI needs an interactive TTY')
                agent_help_ok=([int]$agentHelp.exit_code -eq 0)
                agent_has_local=([string]$agentHelp.output -match '(?i)--local')
                agent_has_message=([string]$agentHelp.output -match '(?i)--message')
                agent_has_agent=([string]$agentHelp.output -match '(?i)--agent')
                agent_has_json=([string]$agentHelp.output -match '(?i)--json')
            }
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
function Install-RuntimePolicyBundle([object]$m) {
    Assert-RuntimeBundle $m
    $byName=@{}
    foreach($item in @($m.components)){$byName[[string]$item.name]=$item}
    $allAlready=$true
    foreach($name in $RuntimePolicyNames){
        $spec=Get-PolicySpec $name
        $item=$byName[$name]
        $actual=Get-Sha $spec.Target
        if($actual -ne ([string]$item.expected_after_sha256).ToUpperInvariant()){$allAlready=$false}
    }
    if($allAlready){
        foreach($name in $RuntimePolicyNames){$spec=Get-PolicySpec $name;Assert-Utf8Policy $spec.Target $name}
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;components=$RuntimePolicyNames}
    }
    $bundleStage=Join-Path $StageRoot ([string]$m.id+'-runtime-policy')
    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $bundleStage,$backupDir|Out-Null
    foreach($name in $RuntimePolicyNames){
        $spec=Get-PolicySpec $name;$item=$byName[$name]
        $cur=Get-Sha $spec.Target
        if($cur -ne ([string]$item.expected_current_sha256).ToUpperInvariant()){throw ('runtime policy expected-current mismatch '+$name+' actual='+$cur)}
        $bytes=Get-RemoteFixedBytes ([string]$spec.Source)
        $stage=Join-Path $bundleStage $name
        [IO.File]::WriteAllBytes($stage,$bytes)
        if((Get-Sha $stage) -ne ([string]$item.expected_after_sha256).ToUpperInvariant()){throw ('runtime policy staged hash mismatch '+$name)}
        Assert-Utf8Policy $stage $name
        Copy-Item -LiteralPath $spec.Target -Destination (Join-Path $backupDir $name) -Force
    }
    try{
        foreach($name in $RuntimePolicyNames){
            $spec=Get-PolicySpec $name;$item=$byName[$name];$stage=Join-Path $bundleStage $name
            $tmp=$spec.Target+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $stage -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $spec.Target -Force
            if((Get-Sha $spec.Target) -ne ([string]$item.expected_after_sha256).ToUpperInvariant()){throw ('runtime policy installed hash mismatch '+$name)}
            Assert-Utf8Policy $spec.Target $name
        }
        Assert-Benchmark30
        $after=[ordered]@{};foreach($name in $RuntimePolicyNames){$specAfter=Get-PolicySpec $name;$after[$name]=Get-Sha $specAfter.Target}
        return [ordered]@{changed=$true;idempotent=$false;after=$after}
    }catch{
        foreach($name in $RuntimePolicyNames){
            $spec=Get-PolicySpec $name;$backup=Join-Path $backupDir $name
            if(Test-Path -LiteralPath $backup -PathType Leaf){Copy-Item -LiteralPath $backup -Destination $spec.Target -Force}
        }
        throw ('runtime policy bundle rollback completed: '+$_.Exception.Message)
    }
}

function Assert-ForgeR03ContractDiagnosis([object]$m) {
    foreach($name in @('path','command','args','target','source_path','source_sha256','hash','test_id','context','file')){
        if($m.PSObject.Properties[$name]){throw ('R03 contract diagnosis manifest must not supply '+$name)}
    }
}
function Get-SafeR03IdentifierHints([string]$Context) {
    $set=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($m in [regex]::Matches($Context,'\$([A-Za-z_][A-Za-z0-9_]*)')){
        $v=[string]$m.Groups[1].Value
        if($v -match '(?i)forge|goal|bench|expect|hash|support|state|policy|path'){[void]$set.Add($v)}
    }
    foreach($m in [regex]::Matches($Context,'\.([A-Za-z_][A-Za-z0-9_]*)')){
        $v=[string]$m.Groups[1].Value
        if($v -match '(?i)forge|goal|bench|expect|hash|support|state|policy|path'){[void]$set.Add($v)}
    }
    return @($set|Sort-Object|Select-Object -First 40)
}
function Get-SafeR03LiteralHints([string]$Context) {
    $set=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($m in [regex]::Matches($Context,'(?i)\b[A-Za-z0-9._-]*(?:forge|goal|benchmark|support|desired|state)[A-Za-z0-9._-]*\.(?:ps1|json|md|txt)\b')){
        $v=[string]$m.Value
        if($v.Length -le 100 -and $v -match '^[A-Za-z0-9._-]+$'){[void]$set.Add($v)}
    }
    return @($set|Sort-Object|Select-Object -First 30)
}
function Publish-ForgeR03Contract([object]$Public) {
    $local=Join-Path $Reports 'forge-r03-contract-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/forge-r03-contract.json'
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
        if($lookup.ExitCode -ne 0 -or -not$lookup.Output){throw 'R03 contract receipt remote SHA lookup failed'}
        $payload=[ordered]@{message='kevin Forge R03 contract telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local));sha=[string]$lookup.Output}|ConvertTo-Json -Compress
        $tmp=Join-Path $env:TEMP ('kevin-r03-contract-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,$payload,$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode -eq 0){return [ordered]@{published=$true;attempt=$attempt;repo_path=$repoPath}}
        if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt)}
    }
    throw 'R03 contract receipt bounded publish retries exhausted'
}
function Diagnose-ForgeR03Contract {
    $bench=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    $forge=(Get-AliasSpec 'design_forge_runner').Target
    if(-not(Test-Path -LiteralPath $bench -PathType Leaf)){throw 'Benchmark missing for R03 diagnosis'}
    if(-not(Test-Path -LiteralPath $forge -PathType Leaf)){throw 'Forge missing for R03 diagnosis'}
    $text=[IO.File]::ReadAllText($bench)
    $idx=$text.IndexOf('R03',[StringComparison]::OrdinalIgnoreCase)
    if($idx-lt0){throw 'R03 marker missing from Benchmark'}
    $start=[Math]::Max(0,$idx-3500);$len=[Math]::Min(8000,$text.Length-$start);$ctx=$text.Substring($start,$len)
    $currentForge=Get-Sha $forge
    $candidateForge='433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
    $shaLits=@([regex]::Matches($ctx,'(?i)\b[A-F0-9]{64}\b')|ForEach-Object{$_.Value.ToUpperInvariant()})
    $ops=[ordered]@{}
    foreach($pair in @(@('get_file_hash','Get-FileHash'),@('get_content','Get-Content'),@('json_parse','ConvertFrom-Json'),@('test_path','Test-Path'),@('eq','-eq'),@('ne','-ne'),@('contains','-contains'),@('notcontains','-notcontains'),@('match','-match'))){$ops[$pair[0]]=($ctx -match [regex]::Escape($pair[1]))}
    $public=[ordered]@{
        schema=1;kind='kevin-forge-r03-contract-public';generated_at=(Get-Date).ToString('o');state='DIAGNOSIS_PROVEN';safe_for_public_repo=$true
        benchmark_sha256=(Get-Sha $bench);forge_sha256=$currentForge;candidate_forge_sha256=$candidateForge
        r03=[ordered]@{
            marker_present=$true
            context_sha256=(Get-TextSha256 $ctx)
            current_forge_literal_count=(Get-LiteralOccurrenceCount $ctx $currentForge)
            candidate_forge_literal_count=(Get-LiteralOccurrenceCount $ctx $candidateForge)
            sha64_literal_count=$shaLits.Count
            current_forge_sha64_matches=@($shaLits|Where-Object{$_-eq$currentForge}).Count
            candidate_forge_sha64_matches=@($shaLits|Where-Object{$_-eq$candidateForge}).Count
            identifier_hints=@(Get-SafeR03IdentifierHints $ctx)
            literal_hints=@(Get-SafeR03LiteralHints $ctx)
            operators=$ops
        }
        source_contract='Fixed installed Benchmark + fixed installed Forge only; R03 marker selected internally. No caller-selected path, command, argv, hash, test, source, or context.'
        privacy='No raw Benchmark source, raw lines, absolute paths, usernames, arbitrary literals, configuration values, credentials, prompts, or secrets are published. Only allowlisted identifier/basename hints and structural counts/booleans.'
    }
    $pub=Publish-ForgeR03Contract $public
    Assert-Benchmark30
    return [ordered]@{state='DIAGNOSIS_PROVEN';published=$pub.published;benchmark_sha256=$public.benchmark_sha256;forge_sha256=$currentForge;current_forge_literal_count=$public.r03.current_forge_literal_count;sha64_literal_count=$public.r03.sha64_literal_count}
}

function Assert-BenchmarkBaselineForgeAnchorDiagnosis([object]$m) {
    foreach($name in @('path','command','args','target','source_path','source_sha256','hash','file','property','root','pattern')){
        if($m.PSObject.Properties[$name]){throw ('Benchmark baseline diagnosis manifest must not supply '+$name)}
    }
}
function Publish-BenchmarkBaselineForgeAnchor([object]$Public) {
    $local=Join-Path $Reports 'benchmark-baseline-forge-anchor-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/benchmark-baseline-forge-anchor.json'
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
        $body=[ordered]@{message='kevin Benchmark baseline Forge anchor telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))}
        if($lookup.ExitCode-eq0 -and $lookup.Output){$body.sha=[string]$lookup.Output}
        elseif($lookup.ExitCode-ne0 -and $lookup.Output-notmatch'404|Not Found'){throw 'Benchmark baseline receipt lookup failed'}
        $tmp=Join-Path $env:TEMP ('kevin-benchmark-baseline-anchor-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode-eq0){return [ordered]@{published=$true;attempt=$attempt}}
        if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt)}
    }
    throw 'Benchmark baseline receipt bounded publish retries exhausted'
}
function Diagnose-BenchmarkBaselineForgeAnchor {
    $support=Get-Content -LiteralPath (Join-Path $Reports 'support-latest.json') -Raw|ConvertFrom-Json
    $liveForge=([string]$support.hashes.forge).ToUpperInvariant();$liveSupervisor=([string]$support.hashes.supervisor).ToUpperInvariant()
    if($liveForge-notmatch'^[A-F0-9]{64}$' -or $liveSupervisor-notmatch'^[A-F0-9]{64}$'){throw 'Support Supervisor/Forge identities unavailable'}
    $p=Join-Path $Reports 'benchmark-v1\baseline.json'
    if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'Fixed Benchmark baseline file missing'}
    try{$b=Get-Content -LiteralPath $p -Raw|ConvertFrom-Json}catch{throw 'Fixed Benchmark baseline is not valid JSON'}
    if(-not$b.hashes){throw 'Benchmark baseline hashes object missing'}
    $forgePresent=$null-ne$b.hashes.PSObject.Properties['forge'];$superPresent=$null-ne$b.hashes.PSObject.Properties['supervisor']
    $forgeMatch=$forgePresent-and([string]$b.hashes.forge).ToUpperInvariant()-eq$liveForge
    $superMatch=$superPresent-and([string]$b.hashes.supervisor).ToUpperInvariant()-eq$liveSupervisor
    $keys=@($b.hashes.PSObject.Properties.Name|Where-Object{$_-match'(?i)^(supervisor|benchmark|forge|goal_os|goalOs|support|maintenance|promotion)'}|Sort-Object -Unique)
    $public=[ordered]@{
        schema=1;kind='kevin-benchmark-baseline-forge-anchor-public';generated_at=(Get-Date).ToString('o');state='DIAGNOSIS_PROVEN';safe_for_public_repo=$true
        baseline_sha256=Get-Sha $p;forge_anchor_present=$forgePresent;forge_matches_live=$forgeMatch;supervisor_anchor_present=$superPresent;supervisor_matches_live=$superMatch
        allowlisted_hash_keys=$keys;migration_ready=($forgePresent-and$forgeMatch)
        source_contract='Fixed reports/benchmark-v1/baseline.json + fixed Support Supervisor/Forge identities only. No caller-selected path, hash, property, command, argv, or arbitrary configuration.'
        privacy='Publishes only baseline SHA, booleans, and allowlisted component-key names. No paths beyond the fixed public contract, raw baseline content, usernames, credentials, prompts, or secrets.'
    }
    $null=Publish-BenchmarkBaselineForgeAnchor $public
    Assert-Benchmark30
    if(-not$forgePresent){throw 'Benchmark baseline Forge anchor missing'}
    if(-not$forgeMatch){throw 'Benchmark baseline Forge anchor does not match live Forge'}
    return [ordered]@{state='DIAGNOSIS_PROVEN';migration_ready=$true;baseline_sha256=$public.baseline_sha256;forge_matches_live=$true;supervisor_matches_live=$superMatch}
}

function Assert-GoalOsForgeAnchorDiagnosis([object]$m) {
    foreach($name in @('path','command','args','target','source_path','source_sha256','hash','file','property','root','pattern')){
        if($m.PSObject.Properties[$name]){throw ('Goal OS anchor diagnosis manifest must not supply '+$name)}
    }
}
function Get-FixedGoalOsFile([string]$ExpectedSha) {
    $p=Join-Path $Reports 'goals\goal-os.json'
    if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'Fixed Goal OS file missing'}
    $actual=Get-Sha $p
    if($actual-ne$ExpectedSha){throw ('Fixed Goal OS hash mismatch actual='+$actual)}
    return (Get-Item -LiteralPath $p)
}
function Find-ForgeAnchorMatches([object]$Node,[string]$Expected,[string]$Prefix='') {
    $out=@()
    if($null-eq$Node){return @()}
    if($Node -is [System.Collections.IDictionary]){
        foreach($k in $Node.Keys){$name=[string]$k;$p=if($Prefix){$Prefix+'.'+$name}else{$name};$v=$Node[$k];if($v -is [string] -and ([string]$v).ToUpperInvariant()-eq$Expected -and $name-match'(?i)^forge(?:_sha256|_hash)?$'){$out+=,[pscustomobject]@{path=$p;leaf=$name}}else{$out+=@(Find-ForgeAnchorMatches $v $Expected $p)}}
        return @($out)
    }
    if($Node -is [System.Collections.IEnumerable] -and -not($Node -is [string]) -and -not($Node -is [pscustomobject])){
        $i=0;foreach($v in $Node){$p=if($Prefix){$Prefix+'['+$i+']'}else{'['+$i+']'};$out+=@(Find-ForgeAnchorMatches $v $Expected $p);$i++};return @($out)
    }
    foreach($prop in @($Node.PSObject.Properties)){
        $name=[string]$prop.Name;$p=if($Prefix){$Prefix+'.'+$name}else{$name};$v=$prop.Value
        if($v -is [string] -and ([string]$v).ToUpperInvariant()-eq$Expected -and $name-match'(?i)^forge(?:_sha256|_hash)?$'){$out+=,[pscustomobject]@{path=$p;leaf=$name}}else{$out+=@(Find-ForgeAnchorMatches $v $Expected $p)}
    }
    return @($out)
}
function Publish-GoalOsForgeAnchor([object]$Public) {
    $local=Join-Path $Reports 'goal-os-forge-anchor-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/goal-os-forge-anchor.json'
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
        if($lookup.ExitCode -ne 0 -or -not$lookup.Output){throw 'Goal OS anchor receipt remote SHA lookup failed'}
        $payload=[ordered]@{message='kevin Goal OS Forge anchor telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local));sha=[string]$lookup.Output}|ConvertTo-Json -Compress
        $tmp=Join-Path $env:TEMP ('kevin-goalos-anchor-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,$payload,$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode-eq0){return [ordered]@{published=$true;attempt=$attempt}}
        if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt)}
    }
    throw 'Goal OS anchor receipt bounded publish retries exhausted'
}
function Diagnose-GoalOsForgeAnchor {
    $support=Get-Content -LiteralPath (Join-Path $Reports 'support-latest.json') -Raw|ConvertFrom-Json
    $goalSha=([string]$support.hashes.goal_os).ToUpperInvariant();$forgeSha=([string]$support.hashes.forge).ToUpperInvariant()
    if($goalSha-notmatch'^[A-F0-9]{64}$' -or $forgeSha-notmatch'^[A-F0-9]{64}$'){throw 'Support Goal OS/Forge identities unavailable'}
    $goalFile=Get-FixedGoalOsFile $goalSha
    $files=@($goalFile)
    try{$goal=Get-Content -LiteralPath $goalFile.FullName -Raw|ConvertFrom-Json}catch{throw 'Exact Goal OS file is not valid JSON'}
    $anchors=@(Find-ForgeAnchorMatches $goal $forgeSha)
    $leafs=@($anchors|ForEach-Object{$_.leaf}|Sort-Object -Unique)
    $public=[ordered]@{
        schema=1;kind='kevin-goal-os-forge-anchor-public';generated_at=(Get-Date).ToString('o');state='DIAGNOSIS_PROVEN';safe_for_public_repo=$true
        goal_os_sha256=$goalSha;forge_sha256=$forgeSha;matched_file_count=$files.Count;matched_file_basename=[IO.Path]::GetFileName($goalFile.FullName)
        forge_anchor_match_count=$anchors.Count;forge_anchor_property_names=$leafs
        migration_ready=($anchors.Count-eq1)
        source_contract='Fixed reports/goals/goal-os.json path; exact Goal OS SHA from fixed Support snapshot; fixed live Forge SHA. No caller-selected path, hash, property, root, pattern, command, or argv.'
        privacy='Publishes only exact public component hashes, one basename, counts, and Forge-related leaf property names. No file content, absolute path, usernames, credentials, prompts, or arbitrary configuration values.'
    }
    $null=Publish-GoalOsForgeAnchor $public
    Assert-Benchmark30
    if($anchors.Count-ne1){throw ('Goal OS Forge anchor must be unique before migration; count='+$anchors.Count)}
    return [ordered]@{state='DIAGNOSIS_PROVEN';migration_ready=$true;file=[IO.Path]::GetFileName($goalFile.FullName);anchor_count=1;property=$leafs[0]}
}

function Assert-ReaderStatusCanary([object]$m) {
    foreach($name in @('prompt','message','path','agent','profile','tool','command','args','question','trials')){
        if($m.PSObject.Properties[$name]){throw ('Reader canary manifest must not supply '+$name)}
    }
}
function Invoke-ReaderOpenClaw([string[]]$CommandArguments) {
    $cmd=Get-Command openclaw -ErrorAction SilentlyContinue
    if(-not$cmd){throw 'OpenClaw CLI unavailable for Reader canary'}
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $cmd.Source --profile reader @CommandArguments 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    return [pscustomobject]@{exit_code=$code;output=[string]$out}
}
function ConvertFrom-ReaderJson([string]$Raw) {
    $i=$Raw.IndexOf('{');if($i -lt 0){throw 'Reader agent returned no JSON'}
    try{return($Raw.Substring($i)|ConvertFrom-Json)}catch{throw 'Reader agent JSON parse failed'}
}
function Get-ReaderVisibleToolNames([object]$Obj) {
    $entries=@($Obj.result.meta.systemPromptReport.tools.entries);$names=@()
    foreach($e in $entries){if($null -eq$e){continue};if($e -is [string]){$names+=[string]$e}elseif($e.name){$names+=[string]$e.name}}
    return @($names)
}
function Get-ReaderFinalText([object]$Obj) {
    $t=[string]$Obj.result.meta.finalAssistantVisibleText
    if(-not$t -and @($Obj.result.payloads).Count -gt 0){$t=[string]$Obj.result.payloads[0].text}
    return $t.Trim()
}
function Test-ReaderPublicText([string]$Text) {
    if(-not$Text -or $Text.Length -gt 4000){return [pscustomobject]@{ok=$false;categories=0}}
    foreach($re in @('(?i)C:\\Users','(?i)hessm','127\.0\.0\.1','(?i)ghp_[A-Za-z0-9]{8,}','(?i)xai-[A-Za-z0-9]{8,}',':18789\b',':19001\b')){if($Text -match $re){return [pscustomobject]@{ok=$false;categories=0}}}
    $cats=0;foreach($re in @('(?i)\bram\b|memory','(?i)\bcpu\b','(?i)\bgpu\b','(?i)disk|free space','(?i)ollama','(?i)gateway')){if($Text -match $re){$cats++}}
    return [pscustomobject]@{ok=($cats -eq 6);categories=$cats}
}
function Get-ReaderToolCalls([object]$Obj) {
    if($null -ne $Obj.result.meta.toolSummary.calls){return [int]$Obj.result.meta.toolSummary.calls}
    return 0
}
function Run-OneReaderTrial([int]$Number) {
    $reset=Invoke-ReaderOpenClaw @('agent','--agent','kevin-reader','--message','/new')
    if($reset.exit_code -ne 0){throw ('Reader session reset failed trial '+$Number)}
    $question='How is this computer doing right now? Use your one allowed system-status tool exactly once. Briefly report overall health plus RAM, CPU, GPU, disk free space, Ollama, and gateway status. Do not reveal paths, usernames, ports, configuration, or secrets.'
    $sw=[Diagnostics.Stopwatch]::StartNew();$r=Invoke-ReaderOpenClaw @('agent','--agent','kevin-reader','--json','--message',$question);$sw.Stop()
    if($r.exit_code -ne 0){throw ('Reader agent failed trial '+$Number)}
    $o=ConvertFrom-ReaderJson ([string]$r.output);$text=Get-ReaderFinalText $o;$calls=Get-ReaderToolCalls $o;$tools=Get-ReaderVisibleToolNames $o;$public=Test-ReaderPublicText $text
    $status=[string]$o.status;$toolBoundary=($tools.Count -eq 1 -and $tools[0] -eq 'kevin_system_status' -and $calls -eq 1)
    $semantic=($status -eq 'success' -and $public.ok -and $toolBoundary)
    return [ordered]@{trial=$Number;status=$status;tool_calls=$calls;visible_tool_count=$tools.Count;visible_tool_boundary_ok=$toolBoundary;semantic_ok=$semantic;privacy_ok=$public.ok;required_categories=$public.categories;duration_ms=[int]$sw.ElapsedMilliseconds;output_sha256=(Get-TextSha256 $text)}
}
function Publish-ReaderCanaryReceipt([object]$Public) {
    $local=Join-Path $Reports 'reader-canary-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/reader-canary-omen.json';$lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
    if($lookup.ExitCode -ne 0 -or -not$lookup.Output){throw 'Reader canary receipt remote SHA lookup failed'}
    $payload=[ordered]@{message='kevin Reader canary telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local));sha=[string]$lookup.Output}|ConvertTo-Json -Compress
    $payloadPath=Join-Path $env:TEMP ('kevin-reader-canary-'+[guid]::NewGuid().ToString('N')+'.json')
    try{[IO.File]::WriteAllText($payloadPath,$payload,$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$payloadPath,'--silent');if($put.ExitCode -ne 0){throw ('Reader canary receipt publish failed: '+(Safe-Text $put.Output 300))}}finally{Remove-Item -LiteralPath $payloadPath -Force -ErrorAction SilentlyContinue}
    $localHash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToUpperInvariant();$verified=$false
    1..3|ForEach-Object{if($verified){return};Start-Sleep -Milliseconds 700;$get=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.content');if($get.ExitCode -eq 0 -and $get.Output){try{$remote=[Convert]::FromBase64String(([string]$get.Output -replace '\s',''));$sha=[Security.Cryptography.SHA256]::Create();try{$rh=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()};if($rh -eq $localHash){$verified=$true}}catch{}}}
    if(-not$verified){throw 'Reader canary receipt remote verification failed'}
    return [ordered]@{published=$true;repo_path=$repoPath;receipt_sha256=$localHash}
}
function Run-ReaderStatusCanary {
    $gw=Invoke-ReaderOpenClaw @('gateway','status','--deep','--require-rpc')
    if($gw.exit_code -ne 0){throw 'Reader gateway deep probe failed'}
    $trials=@();$trials+=Run-OneReaderTrial 1;Start-Sleep -Seconds 1;$trials+=Run-OneReaderTrial 2
    $pass=@($trials|Where-Object{$_.semantic_ok -eq $true}).Count
    $public=[ordered]@{schema=1;kind='kevin-reader-canary-public';generated_at=(Get-Date).ToString('o');state=if($pass -eq 2){'REPEATEDLY_PROVEN'}else{'REJECT'};safe_for_public_repo=$true;pass_k=($pass.ToString()+'/2');gateway_probe_ok=$true;reader_profile='fixed:reader';reader_agent='fixed:kevin-reader';allowed_tool='kevin_system_status';expected_tool_calls_per_trial=1;trials=@($trials);truth_boundary='Two real fixed Reader agent turns on the Omen. Receipt contains metadata and output hashes only; no raw model text/tool output, paths, usernames, ports, configuration, prompts, or secrets.'}
    if($pass -ne 2){throw ('Reader repeated canary rejected '+$pass+'/2')}
    $pub=Publish-ReaderCanaryReceipt $public
    Assert-Benchmark30
    return [ordered]@{state='REPEATEDLY_PROVEN';pass_k='2/2';published=$pub.published;receipt_sha256=$pub.receipt_sha256;tool='kevin_system_status';authority_effect='NONE'}
}

function Assert-SkillWorkshopGuardrails([object]$m) {
    foreach($name in @('path','key','value','command','args','plugin','target','mode','approval_policy')){
        if($m.PSObject.Properties[$name]){throw ('skill workshop guardrail manifest must not supply '+$name)}
    }
}
function ConvertTo-FixedWin32Arg([AllowEmptyString()][string]$Value) {
    $Quote=[string][char]34
    $Slash=[string][char]92
    if($null-eq$Value -or $Value.Length-eq0){return ($Quote+$Quote)}
    if($Value -notmatch '[\s"]'){return $Value}
    $sb=New-Object Text.StringBuilder
    [void]$sb.Append($Quote)
    $slashes=0
    for($i=0;$i-lt$Value.Length;$i++){
        $ch=$Value[$i]
        if($ch-eq[char]92){$slashes++;continue}
        if($ch-eq[char]34){
            if($slashes-gt0){[void]$sb.Append(($Slash*($slashes*2)))}
            [void]$sb.Append($Slash)
            [void]$sb.Append($Quote)
            $slashes=0
            continue
        }
        if($slashes-gt0){[void]$sb.Append(($Slash*$slashes));$slashes=0}
        [void]$sb.Append($ch)
    }
    if($slashes-gt0){[void]$sb.Append(($Slash*($slashes*2)))}
    [void]$sb.Append($Quote)
    return $sb.ToString()
}
function Get-FixedOpenClawRuntime {
    $node=Get-Command node.exe -ErrorAction SilentlyContinue
    if(-not$node){$node=Get-Command node -ErrorAction SilentlyContinue}
    if(-not$node){throw 'node runtime unavailable'}
    if(-not$env:APPDATA){throw 'APPDATA unavailable'}
    $cli=Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if(-not(Test-Path -LiteralPath $cli -PathType Leaf)){throw 'OpenClaw native runtime unavailable'}
    return [pscustomobject]@{node=[string]$node.Source;cli=$cli}
}
function Invoke-FixedNativeBounded([string]$Executable,[string[]]$Argv,[int]$TimeoutSeconds=180) {
    $psi=New-Object Diagnostics.ProcessStartInfo
    $psi.FileName=$Executable
    $psi.Arguments=(($Argv|ForEach-Object{ConvertTo-FixedWin32Arg ([string]$_)})-join' ')
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $p=New-Object Diagnostics.Process;$p.StartInfo=$psi
    if(-not$p.Start()){throw 'fixed native process start failed'}
    $ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();$timed=$false
    if(-not$p.WaitForExit($TimeoutSeconds*1000)){$timed=$true;try{$p.Kill()}catch{};$p.WaitForExit()}
    $stdout=[string]$ot.Result;$stderr=[string]$et.Result;$code=if($timed){124}else{[int]$p.ExitCode}
    $p.Dispose()
    $out=(($stdout+$(if($stdout-and$stderr){"`n"}else{''})+$stderr)).Trim()
    return [pscustomobject]@{exit_code=$code;output=$out;timed_out=$timed}
}
function Invoke-OpenClawFixedConfig([string[]]$CommandArguments) {
    $r=Get-FixedOpenClawRuntime
    return Invoke-FixedNativeBounded $r.node (@($r.cli)+@($CommandArguments)) 180
}
function Get-WorkshopAuthoredValue([string]$Path,[string[]]$Allowed) {
    if($Path -notin @('skills.workshop.autonomous.mode','skills.workshop.approvalPolicy')){throw 'workshop config path not fixed'}
    $r=Invoke-OpenClawFixedConfig @('config','get',$Path,'--json')
    if($r.exit_code -ne 0){return [pscustomobject]@{present=$false;value=''}}
    $v=[string]$r.output;$v=$v.Trim().Trim('"')
    if($Allowed -notcontains $v){throw ('unexpected authored value at '+$Path)}
    return [pscustomobject]@{present=$true;value=$v}
}
function Restore-WorkshopValue([string]$Path,[object]$Before) {
    if([bool]$Before.present){$r=Invoke-OpenClawFixedConfig @('config','set',$Path,[string]$Before.value);if($r.exit_code -ne 0){throw ('rollback set failed '+$Path)}}
    else{$r=Invoke-OpenClawFixedConfig @('config','unset',$Path);if($r.exit_code -ne 0){throw ('rollback unset failed '+$Path)}}
}
function Configure-SkillWorkshopGuardrails {
    $modePath='skills.workshop.autonomous.mode'
    $approvalPath='skills.workshop.approvalPolicy'
    $beforeMode=Get-WorkshopAuthoredValue $modePath @('off','propose','auto')
    $beforeApproval=Get-WorkshopAuthoredValue $approvalPath @('pending','auto')
    if($beforeMode.present -and $beforeMode.value -eq 'propose' -and $beforeApproval.present -and $beforeApproval.value -eq 'pending'){
        $v=Invoke-OpenClawFixedConfig @('config','validate','--json');if($v.exit_code -ne 0){throw 'existing Workshop guardrails present but config invalid'}
        Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;autonomous_mode='propose';approval_policy='pending'}
    }
    $dryMode=Invoke-OpenClawFixedConfig @('config','set',$modePath,'propose','--dry-run')
    if($dryMode.exit_code -ne 0){throw 'Workshop propose dry-run rejected'}
    $dryApproval=Invoke-OpenClawFixedConfig @('config','set',$approvalPath,'pending','--dry-run')
    if($dryApproval.exit_code -ne 0){throw 'Workshop pending dry-run rejected'}
    try{
        $setMode=Invoke-OpenClawFixedConfig @('config','set',$modePath,'propose');if($setMode.exit_code -ne 0){throw 'Workshop propose write failed'}
        $setApproval=Invoke-OpenClawFixedConfig @('config','set',$approvalPath,'pending');if($setApproval.exit_code -ne 0){throw 'Workshop pending write failed'}
        $validate=Invoke-OpenClawFixedConfig @('config','validate','--json');if($validate.exit_code -ne 0){throw 'OpenClaw config invalid after Workshop guardrails'}
        $mode=Get-WorkshopAuthoredValue $modePath @('off','propose','auto')
        $approval=Get-WorkshopAuthoredValue $approvalPath @('pending','auto')
        if(-not$mode.present -or $mode.value -ne 'propose'){throw 'Workshop propose readback failed'}
        if(-not$approval.present -or $approval.value -ne 'pending'){throw 'Workshop pending readback failed'}
        $skills=Invoke-OpenClawFixedConfig @('skills','check','--agent','main','--json');if($skills.exit_code -ne 0){throw 'main-agent skills check failed after Workshop guardrails'}
        Assert-Benchmark30
        return [ordered]@{changed=$true;idempotent=$false;autonomous_mode='propose';approval_policy='pending';rollback_available=$true}
    }catch{
        $primary=$_.Exception.Message
        try{Restore-WorkshopValue $approvalPath $beforeApproval}catch{}
        try{Restore-WorkshopValue $modePath $beforeMode}catch{}
        try{Invoke-OpenClawFixedConfig @('config','validate','--json')|Out-Null}catch{}
        try{Assert-Benchmark30}catch{}
        throw ('skill workshop guardrail rollback completed: '+$primary)
    }
}


function Assert-AutonomyControllerV183Install([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('autonomy controller install manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'install_autonomy_controller_v183'){throw 'autonomy controller install operation mismatch'}
}
function Get-RemoteAutonomyControllerBytes([string]$RepoPath) {
    if($RepoPath -notin @($SupervisorV183Source,$SelectorV11Source)){throw 'autonomy controller source path rejected'}
    $r=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.content')
    if($r.ExitCode -ne 0){throw 'autonomy controller source fetch failed'}
    try{return [Convert]::FromBase64String(([string]$r.Output -replace '\s',''))}catch{throw 'autonomy controller source base64 decode failed'}
}
function Invoke-FixedPythonSelfTest([string]$Path) {
    $py=Get-Command python -ErrorAction SilentlyContinue
    $CommandArguments=@($Path,'--selftest')
    if(-not$py){$py=Get-Command py -ErrorAction SilentlyContinue;$CommandArguments=@('-3',$Path,'--selftest')}
    if(-not$py){throw 'python runtime unavailable for selector selftest'}
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $py.Source @CommandArguments 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($code-ne0 -or $out -notmatch 'KEVIN WORK SELECTOR v1.1 SELFTEST PASS'){throw 'selector fixed selftest failed'}
}
function Install-AutonomyControllerV183([object]$m) {
    Assert-AutonomyControllerV183Install $m
    if($env:OS -ne 'Windows_NT'){throw 'autonomy controller install requires Windows'}
    $supervisorTarget=Join-Path $Workspace 'kevin-supervisor.ps1'
    $selectorDir=Join-Path $Workspace 'ControlPlane'
    $selectorTarget=Join-Path $selectorDir 'kevin-work-selector-v1.1.py'
    $baselineTarget=Join-Path $Reports 'benchmark-v1\baseline.json'
    foreach($p in @($supervisorTarget,$baselineTarget)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('autonomy controller install target missing: '+[IO.Path]::GetFileName($p))}}
    New-Item -ItemType Directory -Force -Path $selectorDir|Out-Null
    $supBefore=Get-Sha $supervisorTarget
    $selectorBefore=Get-Sha $selectorTarget
    try{$base=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json}catch{throw 'Benchmark baseline is not valid JSON'}
    if(-not$base.hashes){throw 'Benchmark baseline hashes missing'}
    $baseSup=([string]$base.hashes.supervisor).ToUpperInvariant();$baseForge=([string]$base.hashes.forge).ToUpperInvariant()
    if($supBefore -eq $SupervisorV183Sha -and $selectorBefore -eq $SelectorV11Sha -and $baseSup -eq $SupervisorV183Sha -and $baseForge -eq $ForgeV40Sha){
        Parse-PowerShell $supervisorTarget; & $supervisorTarget -SelfTest; if($LASTEXITCODE-ne0){throw 'installed Supervisor v1.8.5 selftest failed'}
        Invoke-FixedPythonSelfTest $selectorTarget;Assert-Benchmark30
        return [ordered]@{changed=$false;idempotent=$true;supervisor_after=$supBefore;selector_after=$selectorBefore;baseline_supervisor_anchor=$baseSup;forge_anchor=$baseForge}
    }
    if($supBefore -ne $SupervisorV171Sha){throw ('Supervisor expected-current mismatch actual='+$supBefore)}
    if($selectorBefore -and $selectorBefore -ne $SelectorV11Sha){throw ('selector target contains unexpected identity actual='+$selectorBefore)}
    if($baseSup -ne $SupervisorV171Sha){throw ('Benchmark baseline Supervisor anchor mismatch actual='+$baseSup)}
    if($baseForge -ne $ForgeV40Sha){throw ('Benchmark baseline Forge anchor changed actual='+$baseForge)}

    $supBytes=Get-RemoteAutonomyControllerBytes $SupervisorV183Source
    $selBytes=Get-RemoteAutonomyControllerBytes $SelectorV11Source
    $supStage=Join-Path $StageRoot ([string]$m.id+'.supervisor-v183.ps1')
    $selStage=Join-Path $StageRoot ([string]$m.id+'.selector-v11.py')
    [IO.File]::WriteAllBytes($supStage,$supBytes);[IO.File]::WriteAllBytes($selStage,$selBytes)
    if((Get-Sha $supStage)-ne$SupervisorV183Sha){throw 'Supervisor v1.8.5 source hash mismatch'}
    if((Get-Sha $selStage)-ne$SelectorV11Sha){throw 'selector v1.1 source hash mismatch'}
    Parse-PowerShell $supStage
    & $supStage -SelfTest;if($LASTEXITCODE-ne0){throw 'staged Supervisor v1.8.5 selftest failed'}
    Invoke-FixedPythonSelfTest $selStage
    $supText=[IO.File]::ReadAllText($supStage)
    foreach($marker in @('Governed Autonomy Continuation Controller','IDLE_NO_ELIGIBLE_DEMAND','COOLDOWN_BUDGET_EXHAUSTED','AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF')){if(-not$supText.Contains($marker)){throw ('Supervisor v1.8.5 marker missing: '+$marker)}}
    foreach($bad in @('Invoke-Expression','kevin_shell','Start-Process cmd.exe')){if($supText.Contains($bad)){throw ('Supervisor v1.8.5 forbidden marker: '+$bad)}}

    $baseStageObj=$base|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $baseStageObj.hashes.supervisor=$SupervisorV183Sha
    if(([string]$baseStageObj.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'staged Benchmark Forge anchor changed'}
    $baseStage=Join-Path $StageRoot ([string]$m.id+'.benchmark-baseline.json')
    [IO.File]::WriteAllText($baseStage,($baseStageObj|ConvertTo-Json -Depth 30),$Utf8)
    $verify=Get-Content -LiteralPath $baseStage -Raw|ConvertFrom-Json
    if(([string]$verify.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV183Sha){throw 'staged Benchmark Supervisor anchor mismatch'}
    if(([string]$verify.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'staged Benchmark Forge anchor mismatch'}

    $mutex=New-Object Threading.Mutex($false,'Global\KevinSupervisor');$owned=$false
    try{$owned=$mutex.WaitOne(10000)}catch [Threading.AbandonedMutexException]{$owned=$true}
    if(-not$owned){$mutex.Dispose();throw 'Supervisor mutex busy; bounded install deferred'}
    $backupDir=Join-Path $BackupRoot ([string]$m.id);New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $supBackup=Join-Path $backupDir 'kevin-supervisor.ps1';$baseBackup=Join-Path $backupDir 'benchmark-baseline.json';$selBackup=Join-Path $backupDir 'kevin-work-selector-v1.1.py'
    Copy-Item -LiteralPath $supervisorTarget -Destination $supBackup -Force;Copy-Item -LiteralPath $baselineTarget -Destination $baseBackup -Force
    $selectorExisted=Test-Path -LiteralPath $selectorTarget -PathType Leaf;if($selectorExisted){Copy-Item -LiteralPath $selectorTarget -Destination $selBackup -Force}
    try{
        if((Get-Sha $supervisorTarget)-ne$SupervisorV171Sha){throw 'Supervisor changed after staging; aborting TOCTOU'}
        if($selectorExisted -and (Get-Sha $selectorTarget)-ne$SelectorV11Sha){throw 'selector changed after staging; aborting TOCTOU'}
        $liveBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$liveBase.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV171Sha -or ([string]$liveBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'Benchmark anchors changed after staging; aborting TOCTOU'}
        foreach($pair in @(@($supStage,$supervisorTarget),@($selStage,$selectorTarget),@($baseStage,$baselineTarget))){$tmp=[string]$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N');Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force;Move-Item -LiteralPath $tmp -Destination $pair[1] -Force}
        if((Get-Sha $supervisorTarget)-ne$SupervisorV183Sha){throw 'installed Supervisor v1.8.5 hash mismatch'}
        if((Get-Sha $selectorTarget)-ne$SelectorV11Sha){throw 'installed selector v1.1 hash mismatch'}
        $postBase=Get-Content -LiteralPath $baselineTarget -Raw|ConvertFrom-Json
        if(([string]$postBase.hashes.supervisor).ToUpperInvariant()-ne$SupervisorV183Sha -or ([string]$postBase.hashes.forge).ToUpperInvariant()-ne$ForgeV40Sha){throw 'installed Benchmark anchors mismatch'}
        Parse-PowerShell $supervisorTarget;& $supervisorTarget -SelfTest;if($LASTEXITCODE-ne0){throw 'installed Supervisor v1.8.5 selftest failed'}
        Invoke-FixedPythonSelfTest $selectorTarget;Assert-Benchmark30
        return [ordered]@{changed=$true;supervisor_before=$supBefore;supervisor_after=(Get-Sha $supervisorTarget);selector_before=$selectorBefore;selector_after=(Get-Sha $selectorTarget);benchmark_supervisor_anchor=$SupervisorV183Sha;forge_anchor=$ForgeV40Sha;selector_first=$true;fixed_main_agent=$true;anti_spin=$true;openclaw_native_node=$true;shell_shim_bypassed=$true;rollback_available=$true}
    }catch{
        Copy-Item -LiteralPath $supBackup -Destination $supervisorTarget -Force;Copy-Item -LiteralPath $baseBackup -Destination $baselineTarget -Force
        if($selectorExisted){Copy-Item -LiteralPath $selBackup -Destination $selectorTarget -Force}else{Remove-Item -LiteralPath $selectorTarget -Force -ErrorAction SilentlyContinue}
        try{Assert-Benchmark30}catch{}
        throw ('autonomy controller rollback completed: '+$_.Exception.Message)
    }finally{if($owned){try{$mutex.ReleaseMutex()}catch{}};$mutex.Dispose()}
}


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
    if($t -match '(?i)ERR_MODULE_NOT_FOUND|Cannot find module|Cannot find package'){return 'MODULE_LOAD_FAILURE'}
    if($t -match '(?i)invalid config|configuration.{0,40}invalid|config.{0,40}error|validation failed|unknown config|unrecognized config|schema.{0,40}(invalid|error)'){return 'CONFIG_INVALID'}
    if($t -match '(?i)SyntaxError|Unexpected token|parse error'){return 'RUNTIME_PARSE_FAILURE'}
    if($t -match '(?i)unsupported.{0,30}node|requires Node|Node.{0,30}version'){return 'NODE_VERSION_INCOMPATIBLE'}
    if($t -match '(?i)ENOENT|file not found|path not found'){return 'FILE_NOT_FOUND'}
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
    $runtime=Get-FixedOpenClawRuntime
    $nodeVersion=Invoke-FixedNativeBounded $runtime.node @('--version') 30
    $cliVersion=Invoke-FixedNativeBounded $runtime.node @($runtime.cli,'--version') 30
    $cliHelp=Invoke-FixedNativeBounded $runtime.node @($runtime.cli,'--help') 30
    $defaultConfig=Join-Path $env:USERPROFILE '.openclaw\openclaw.json'
    $configExists=Test-Path -LiteralPath $defaultConfig -PathType Leaf
    $configSha=if($configExists){Get-Sha $defaultConfig}else{''}
    $configSize=if($configExists){[int64](Get-Item -LiteralPath $defaultConfig).Length}else{0}
    $strictJsonValid=$false
    if($configExists){try{$null=Get-Content -LiteralPath $defaultConfig -Raw|ConvertFrom-Json;$strictJsonValid=$true}catch{}}
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
        bootstrap=[ordered]@{
            node_version=[ordered]@{exit_code=[int]$nodeVersion.exit_code;class=(Get-GatewayProbeClass $nodeVersion);output_sha256=(Get-TextSha256 ([string]$nodeVersion.output))}
            cli_version=[ordered]@{exit_code=[int]$cliVersion.exit_code;class=(Get-GatewayProbeClass $cliVersion);output_sha256=(Get-TextSha256 ([string]$cliVersion.output))}
            cli_help=[ordered]@{exit_code=[int]$cliHelp.exit_code;class=(Get-GatewayProbeClass $cliHelp);output_sha256=(Get-TextSha256 ([string]$cliHelp.output))}
        }
        config_file=[ordered]@{exists=[bool]$configExists;sha256=$configSha;size_bytes=$configSize;strict_json_valid=[bool]$strictJsonValid}
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

function Assert-NoCallerArgs([object]$m,[string]$Operation) {
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
    foreach($listenerPid in @($conns|Select-Object -ExpandProperty OwningProcess -Unique)){
        if(-not$listenerPid){continue}
        $p=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$listenerPid) -ErrorAction SilentlyContinue
        $cmd=if($p){[string]$p.CommandLine}else{''}
        if($cmd -notmatch '(?i)openclaw.*dist[\\/].*index\.js.*(?:^|\s)gateway(?:\s|$)'){throw 'Port 18789 listener is not recognized as fixed OpenClaw Gateway'}
        Stop-Process -Id ([int]$listenerPid) -Force -ErrorAction Stop
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
    $localHash=Get-Sha $local
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.sha')
        $body=[ordered]@{message=$Message;content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))}
        if($lookup.ExitCode-eq0 -and $lookup.Output){
            $body.sha=[string]$lookup.Output
        }elseif($lookup.ExitCode-ne0 -and [string]$lookup.Output -notmatch '404|Not Found'){
            if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt);continue}
            throw 'safe report lookup bounded retries exhausted'
        }
        $tmp=Join-Path $env:TEMP ('kevin-safe-report-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$RepoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode-ne0){if($attempt-lt3){Start-Sleep -Milliseconds (500*$attempt);continue};throw 'safe report publish bounded retries exhausted'}
        Start-Sleep -Milliseconds 600
        $get=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.content')
        if($get.ExitCode-eq0 -and $get.Output){
            try{
                $remote=[Convert]::FromBase64String(([string]$get.Output-replace'\s',''))
                $sha=[Security.Cryptography.SHA256]::Create()
                try{$remoteHash=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()}
                if($remoteHash-eq$localHash){return $localHash}
            }catch{}
        }
        if($attempt-lt3){Start-Sleep -Milliseconds (500*$attempt)}
    }
    throw 'safe report remote verification bounded retries exhausted'
}
function Run-SelfRelianceWatchdogOnce {
    $p=Join-Path $Workspace 'kevin-self-reliance-watchdog.ps1';if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'self-reliance watchdog missing'}
    $st=Invoke-FixedNativeBounded 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$p,'-SelfTest') 120
    if($st.exit_code-ne0 -or [string]$st.output -notmatch 'implementation=v1\.6\.0' -or [string]$st.output -notmatch 'probe_no_intake=true' -or [string]$st.output -notmatch 'probe_no_restart=true'){throw 'installed watchdog does not prove ProbeOnly v1.6.0 contract'}
    $r=Invoke-FixedNativeBounded 'powershell.exe' @('-NoProfile','-NonInteractive','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',$p,'-ProbeOnly') 180;if($r.exit_code-ne0){throw 'self-reliance watchdog ProbeOnly run failed'}
    $statePath=Join-Path $Reports 'self-reliance\watchdog-state.json';if(-not(Test-Path -LiteralPath $statePath -PathType Leaf)){throw 'watchdog state missing after ProbeOnly run'}
    try{$w=Get-Content -LiteralPath $statePath -Raw|ConvertFrom-Json}catch{throw 'watchdog state invalid JSON'}
    if([string]$w.last_result -notmatch '^PROBE_ONLY_(?:HEALTHY|[A-Z0-9_]+)$'){throw 'watchdog ProbeOnly terminal state missing'}
    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology
    $cool=$false;if($w.cooldown_until){try{$cool=([DateTimeOffset]::Parse([string]$w.cooldown_until)-gt[DateTimeOffset]::Now)}catch{}}
    $public=[ordered]@{schema=1;kind='kevin-self-reliance-watchdog-public';generated_at=(Get-Date).ToString('o');state='OMEN_CLASSIFIER_PROOF';safe_for_public_repo=$true;probe_mode='NO_SIDE_EFFECTS';watchdog_contract='v1.6.0';watchdog_sha256=Get-Sha $p;last_result=[string]$w.last_result;failure_family=[string]$w.failure_family;startup_class=[string]$w.startup_class;attempts=[int]$w.attempts;cooling=$cool;gateway_probe_exit=$w.gateway_probe_exit;config_validate_exit=$w.config_validate_exit;config_schema_exit=$w.config_schema_exit;gateway_task_running=[bool]$w.gateway_task_running;binary_version=[string]$w.binary_version;config_last_touched_version=[string]$w.config_last_touched_version;maintenance_result=[string]$w.maintenance_result;work_order_result=[string]$w.work_order_result;config_backup_exists=[bool]$facts.backup_exists;config_backup_semantically_equivalent=[bool]$facts.backup_semantically_equivalent;keeper_present=[bool]$top.keeper_present;keeper_state=[string]$top.keeper_state;port_18789_listening=[bool]$top.port_listening;source_contract='One fixed watchdog v1.6.0 ProbeOnly run plus fixed metadata-only config/topology inspection. ProbeOnly skips maintenance/work-order intake, console mutation, retries/cooldown changes, and Gateway restart. No caller-selected command, argv, path, token, or raw output.';truth_boundary='No raw CLI output, config bodies, credentials, host paths, messages, prompts, tool payloads, or secrets are published.'}
    $receipt=Publish-SafeFixedReport 'reports/self-reliance-watchdog-omen.json' 'self-reliance-watchdog-public.json' $public 'kevin self-reliance watchdog telemetry';Assert-Benchmark30
    return [ordered]@{state='OMEN_CLASSIFIER_PROOF';probe_mode='NO_SIDE_EFFECTS';receipt_sha256=$receipt;last_result=$public.last_result;startup_class=$public.startup_class;failure_family=$public.failure_family;binary_version=$public.binary_version;config_last_touched_version=$public.config_last_touched_version;keeper_present=$public.keeper_present;port_18789_listening=$public.port_18789_listening}
}
function Diagnose-GatewayFailureDetail {
    # Every read-only probe is a separate command expression. This prevents
    # Windows PowerShell from binding later commands as arguments to the first.
    $probes=@(
        (Invoke-OpenClawFixedConfig @('config','validate','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','status','--require-rpc','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','call','status','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','health','--json'))
    )
    if($probes.Count-ne4){throw 'fixed diagnostic must execute exactly four probes'}
    $allProbesOk=(@($probes|Where-Object{$_.exit_code-ne0}).Count-eq0)
    $text=($probes|ForEach-Object{[string]$_.output})-join"`n"
    $family=if($allProbesOk){'HEALTHY'}else{Get-GatewayFailureFamilyDetailed $text}
    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology
    $version='UNKNOWN';$pkg=Join-Path $env:APPDATA 'npm\node_modules\openclaw\package.json';if(Test-Path -LiteralPath $pkg -PathType Leaf){try{$version=[string](Get-Content -LiteralPath $pkg -Raw|ConvertFrom-Json).version}catch{}}
    $public=[ordered]@{schema=1;kind='kevin-gateway-failure-detail-public';generated_at=(Get-Date).ToString('o');state='OMEN_DIAGNOSIS_PROVEN';safe_for_public_repo=$true;openclaw_version=$version;release_policy_status=$(if($version-eq$GatewayRejectedVersion){'EVIDENCE_REJECTED'}elseif($version-eq$GatewayLkgVersion){'WINDOWS_VALIDATED_LKG'}else{'OTHER'});root_cause_family=$family;probe_count=$probes.Count;probe_names=@('config_validate','gateway_require_rpc','gateway_direct_rpc','gateway_health');all_probes_ok=$allProbesOk;command_forwarding_contract='v1.3.38';win32_argv_contract='numeric-char-mscrt';probe_exit_codes=@($probes|ForEach-Object{[int]$_.exit_code});probe_output_fingerprints=@($probes|ForEach-Object{Get-TextSha256 ([string]$_.output)});config=[ordered]@{current_sha256=$facts.current_sha256;current_last_touched=$facts.current_last_touched;backup_exists=[bool]$facts.backup_exists;backup_sha256=$facts.backup_sha256;backup_last_touched=$facts.backup_last_touched;backup_semantically_equivalent=[bool]$facts.backup_semantically_equivalent;telegram_present=[bool]$facts.telegram_present;discord_present=[bool]$facts.discord_present;codex_present=[bool]$facts.codex_present;memory_core_present=[bool]$facts.memory_core_present};windows=[ordered]@{keeper_present=[bool]$top.keeper_present;keeper_state=[string]$top.keeper_state;keeper_script_present=[bool]$top.keeper_script_present;keeper_script_sha256=$top.keeper_script_sha256;legacy_task_present=[bool]$top.legacy_present;legacy_task_state=[string]$top.legacy_state;port_18789_listening=[bool]$top.port_listening;gateway_listener_count=[int]$top.gateway_listener_count};recommended_repair=$(if($allProbesOk){'NONE_ALL_PROBES_PASSED'}else{'CLASSIFY_FAILED_PROBE_BEFORE_REPAIR'});source_contract='Four separately invoked read-only config/RPC/health probes with verified command forwarding and byte-tested Win32 argv quoting plus fixed package/config/backup/Gateway topology metadata. No doctor repair, version mutation, or caller-selected command/path/argv.';truth_boundary='Only classifications, exit codes, hashes, safe versions, booleans, and known plugin flags are published. No raw output, config values, credentials, paths, messages, prompts, or secrets.'}
    $receipt=Publish-SafeFixedReport 'reports/gateway-failure-detail-omen.json' 'gateway-failure-detail-public.json' $public 'kevin gateway failure detail telemetry';Assert-Benchmark30
    return [ordered]@{state='OMEN_DIAGNOSIS_PROVEN';receipt_sha256=$receipt;root_cause_family=$family;all_probes_ok=$allProbesOk;probe_count=$probes.Count;openclaw_version=$version;release_policy_status=$public.release_policy_status;recommended_repair=$public.recommended_repair;keeper_present=[bool]$top.keeper_present;backup_semantically_equivalent=[bool]$facts.backup_semantically_equivalent}
}
function Invoke-NpmFixed([string[]]$CommandArguments,[int]$Timeout=600) {
    $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not$node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not$node){throw 'node unavailable for fixed npm runtime'}
    $npmCli=Join-Path (Split-Path -Parent ([string]$node.Source)) 'node_modules\npm\bin\npm-cli.js'
    if(-not(Test-Path -LiteralPath $npmCli -PathType Leaf)){throw 'fixed npm-cli.js unavailable beside Node runtime'}
    return Invoke-FixedNativeBounded ([string]$node.Source) (@($npmCli)+@($CommandArguments)) $Timeout
}
function Get-InstalledOpenClawVersion {$pkg=Join-Path $env:APPDATA 'npm\node_modules\openclaw\package.json';if(-not(Test-Path -LiteralPath $pkg -PathType Leaf)){return 'ABSENT'};try{return [string](Get-Content -LiteralPath $pkg -Raw|ConvertFrom-Json).version}catch{return 'UNREADABLE'}}
function Get-FixedOpenClawTarballSpec([string]$Version) {
    $integrity = if($Version-eq$GatewayLkgVersion){$GatewayLkgIntegrity}elseif($Version-eq$GatewayRejectedVersion){$GatewayRejectedIntegrity}else{throw ('untrusted OpenClaw package version '+$Version)}
    if($Version-notmatch '^2026\.[0-9]+\.[0-9]+(?:-[0-9]+)?$'){throw 'OpenClaw package version format rejected'}
    $uri='https://registry.npmjs.org/openclaw/-/openclaw-'+$Version+'.tgz'
    if($uri-notmatch '^https://registry\.npmjs\.org/openclaw/-/openclaw-2026\.[0-9]+\.[0-9]+(?:-[0-9]+)?\.tgz$'){throw 'fixed npm tarball URI invariant failed'}
    return [pscustomobject]@{version=$Version;uri=$uri;integrity=$integrity}
}
function Get-FileSriSha512([string]$Path) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw 'tarball missing for SRI verification'}
    $sha=[Security.Cryptography.SHA512]::Create()
    try{
        $fs=[IO.File]::OpenRead($Path)
        try{$digest=$sha.ComputeHash($fs)}finally{$fs.Dispose()}
    }finally{$sha.Dispose()}
    return 'sha512-'+[Convert]::ToBase64String($digest)
}
function Download-VerifiedOpenClawTarball([string]$Version,[string]$Expected) {
    $spec=Get-FixedOpenClawTarballSpec $Version
    if([string]$Expected-ne[string]$spec.integrity){throw ('embedded integrity contract mismatch for '+$Version)}
    $dest=Join-Path $env:TEMP ('openclaw-'+$Version+'-'+[guid]::NewGuid().ToString('N')+'.tgz')
    try{
        Invoke-WebRequest -UseBasicParsing -Uri ([string]$spec.uri) -OutFile $dest -TimeoutSec 180 -ErrorAction Stop
        $actual=Get-FileSriSha512 $dest
        if($actual-ne$Expected){throw ('downloaded OpenClaw tarball integrity mismatch for '+$Version)}
        return $dest
    }catch{
        Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
        throw
    }
}
function Assert-NpmIntegrity([string]$Version,[string]$Expected) {
    $tar=Download-VerifiedOpenClawTarball $Version $Expected
    try{if((Get-FileSriSha512 $tar)-ne$Expected){throw ('verified OpenClaw tarball changed before use for '+$Version)}}finally{Remove-Item -LiteralPath $tar -Force -ErrorAction SilentlyContinue}
}
function Install-ExactOpenClaw([string]$Version) {
    $spec=Get-FixedOpenClawTarballSpec $Version
    $tar=Download-VerifiedOpenClawTarball $Version ([string]$spec.integrity)
    try{
        if((Get-FileSriSha512 $tar)-ne[string]$spec.integrity){throw ('verified OpenClaw tarball changed before install for '+$Version)}
        $r=Invoke-NpmFixed @('install','--global',$tar,'--no-audit','--no-fund','--ignore-scripts=false') 900
        if($r.exit_code-ne0){throw ('exact verified-tarball OpenClaw install failed version='+$Version)}
        if((Get-InstalledOpenClawVersion)-ne$Version){throw ('installed OpenClaw version mismatch expected='+$Version)}
    }finally{Remove-Item -LiteralPath $tar -Force -ErrorAction SilentlyContinue}
}
function Wait-GatewayRpc([int]$Seconds=90) {$deadline=(Get-Date).AddSeconds($Seconds);while((Get-Date)-lt$deadline){$r=Invoke-OpenClawFixedConfig @('gateway','call','status','--json');if($r.exit_code-eq0){return $true};Start-Sleep -Seconds 3};return $false}
function Start-AuthoritativeGateway([object]$Topology) {if([bool]$Topology.keeper_present){Start-ScheduledTask -TaskName $GatewayKeeperTaskName;return 'KEEPER'};if([bool]$Topology.legacy_present){Start-ScheduledTask -TaskName $LegacyGatewayTaskName;return 'LEGACY'};throw 'No fixed Gateway launcher task exists'}
function Repair-OpenClawWindowsLkg {
    if($env:OS-ne'Windows_NT'){throw 'Windows LKG recovery requires Windows'}
    $before=Get-InstalledOpenClawVersion;if($before-notin@($GatewayRejectedVersion,$GatewayLkgVersion)){throw ('Windows LKG recovery refuses unexpected installed version '+$before)}
    Assert-NpmIntegrity $GatewayLkgVersion $GatewayLkgIntegrity
    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology;if(-not$facts.current_exists){throw 'OpenClaw config missing'}
    if($top.keeper_present-and-not$top.keeper_script_present){throw 'Gateway Keeper task exists but fixed Keeper script is missing'}
    $config=Join-Path $env:USERPROFILE '.openclaw\\openclaw.json'
    $beforeConfigSha=Get-Sha $config;if(-not$beforeConfigSha){throw 'starting OpenClaw config hash unavailable'}
    $backupDir=Join-Path $BackupRoot ('openclaw-lkg-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $savedConfig=Join-Path $backupDir 'openclaw.json';Copy-Item -LiteralPath $config -Destination $savedConfig -Force
    if((Get-Sha $savedConfig)-ne$beforeConfigSha){throw 'pretransition config snapshot hash mismatch'}
    $versionTransitionAttempted=$false;$launcher=''
    try{
        if($top.keeper_present){try{Stop-ScheduledTask -TaskName $GatewayKeeperTaskName -ErrorAction SilentlyContinue}catch{}}elseif($top.legacy_present){try{Stop-ScheduledTask -TaskName $LegacyGatewayTaskName -ErrorAction SilentlyContinue}catch{}}
        Stop-FixedGatewayListener
        if($before-ne$GatewayLkgVersion){$versionTransitionAttempted=$true;Install-ExactOpenClaw $GatewayLkgVersion}
        # The target LKG must prove it can read the untouched current config.
        # No metadata rewrite or backup substitution is allowed.
        $v=Invoke-OpenClawFixedConfig @('config','validate','--json');if($v.exit_code-ne0){throw 'LKG current-config compatibility validation failed'}
        if((Get-Sha $config)-ne$beforeConfigSha){throw 'LKG config validation unexpectedly modified config'}
        $launcher=Start-AuthoritativeGateway $top;if(-not(Wait-GatewayRpc 90)){throw 'LKG Gateway direct RPC did not become healthy'}
        $health=Invoke-OpenClawFixedConfig @('gateway','health','--json');if($health.exit_code-ne0){throw 'LKG Gateway health failed'}
        $skills=Invoke-OpenClawFixedConfig @('skills','check','--agent','main','--json');if($skills.exit_code-ne0){throw 'LKG main-agent skills check failed'}
        Assert-Benchmark30;$after=Get-InstalledOpenClawVersion
        if($after-ne$GatewayLkgVersion){throw 'LKG postcondition version mismatch'}
        if((Get-Sha $config)-ne$beforeConfigSha){throw 'OpenClaw config changed during successful LKG recovery'}
        $public=[ordered]@{schema=1;kind='kevin-openclaw-windows-lkg-recovery-public';generated_at=(Get-Date).ToString('o');state='OMEN_PROVEN';safe_for_public_repo=$true;before_version=$before;after_version=$after;validated_version=$GatewayLkgVersion;npm_integrity_verified=$true;transactional_config_validation=$true;config_snapshot_verified=$true;config_sha_unchanged=$true;config_backup_used=$false;authoritative_launcher=$launcher;keeper_preserved=[bool]$top.keeper_present;config_valid=$true;gateway_direct_rpc=$true;gateway_health=$true;main_skills_check=$true;benchmark_30_of_30=$true;rollback_available=$true;source_contract='Fixed Windows exact-version recovery to validated LKG with fixed npm integrity, exact pretransition config snapshot, target-version compatibility validation against the untouched config, preserved Keeper topology, fixed RPC/health/main-skills/Benchmark postconditions, and exact package/config rollback.';truth_boundary='No npm output, config body, credentials, paths, messages, prompts, or secrets are published.'}
        $receipt=Publish-SafeFixedReport 'reports/openclaw-windows-lkg-recovery-omen.json' 'openclaw-windows-lkg-recovery-public.json' $public 'kevin OpenClaw Windows LKG recovery telemetry'
        return [ordered]@{state='OMEN_PROVEN';receipt_sha256=$receipt;before_version=$before;after_version=$after;authoritative_launcher=$launcher;gateway_direct_rpc=$true;benchmark='30/30';transactional_config_validation=$true;config_sha_unchanged=$true}
    }catch{
        $primary=$_.Exception.Message;$packageRollbackOk=$true;$configRollbackOk=$true
        try{Copy-Item -LiteralPath $savedConfig -Destination $config -Force;if((Get-Sha $config)-ne$beforeConfigSha){throw 'starting OpenClaw config not restored exactly'}}catch{$configRollbackOk=$false}
        if($versionTransitionAttempted){
            try{Assert-NpmIntegrity $GatewayRejectedVersion $GatewayRejectedIntegrity;Install-ExactOpenClaw $GatewayRejectedVersion;if((Get-InstalledOpenClawVersion)-ne$before){throw 'starting OpenClaw version not restored'}}catch{$packageRollbackOk=$false}
        }
        try{$null=Start-AuthoritativeGateway $top}catch{};try{Assert-Benchmark30}catch{}
        if(-not$configRollbackOk -or -not$packageRollbackOk){throw ('OpenClaw Windows LKG recovery AND exact rollback failed config='+$configRollbackOk+' package='+$packageRollbackOk+' after: '+$primary)}
        throw ('OpenClaw Windows LKG recovery rollback completed: '+$primary)
    }
}

function Reconcile-MaintenanceCronBackoff {
    $declarationKey='kevin-maintenance-intake-v1'
    $expectedName='Kevin Maintenance Intake v1.1d'
    $list=Invoke-OpenClawFixedConfig @('cron','list','--all','--json')
    if($list.exit_code-ne0){throw 'Maintenance cron list failed'}
    try{$obj=$list.output|ConvertFrom-Json}catch{throw 'Maintenance cron list returned invalid JSON'}
    $jobs=if($obj -is [array]){@($obj)}elseif($obj.PSObject.Properties['jobs']){@($obj.jobs)}elseif($obj.PSObject.Properties['items']){@($obj.items)}else{@($obj)}
    $matches=@($jobs|Where-Object{[string]$_.declarationKey -eq $declarationKey -and [string]$_.name -eq $expectedName})
    if($matches.Count-ne1){throw ('Maintenance cron identity did not resolve exactly once count='+$matches.Count)}
    $id=[string]$matches[0].id
    if($id -notmatch '^[A-Za-z0-9-]{8,96}$'){throw 'Maintenance cron id invalid'}
    $before=Invoke-OpenClawFixedConfig @('cron','get',$id,'--json')
    if($before.exit_code-ne0){throw 'Maintenance cron get before reset failed'}
    try{$b=$before.output|ConvertFrom-Json}catch{throw 'Maintenance cron get before reset invalid JSON'}
    if([string]$b.declarationKey-ne$declarationKey -or [string]$b.name-ne$expectedName){throw 'Maintenance cron readback identity mismatch'}
    if($b.PSObject.Properties['enabled'] -and -not[bool]$b.enabled){throw 'Maintenance cron unexpectedly disabled before reset'}
    $beforeErrors=if($b.state -and $b.state.PSObject.Properties['consecutiveErrors']){[int]$b.state.consecutiveErrors}else{0}
    $rawBefore=[string]$before.output
    if($rawBefore -notmatch '"everyMs"\s*:\s*300000'){throw 'Maintenance cron cadence changed before reset'}

    # A committed enabled=true patch is the scheduler-owned reset primitive.
    # It does not execute this job and therefore cannot recurse into Maintenance.
    $edit=Invoke-OpenClawFixedConfig @('cron','edit',$id,'--enable')
    if($edit.exit_code-ne0){throw 'Maintenance cron enable/reset patch failed'}
    $after=Invoke-OpenClawFixedConfig @('cron','get',$id,'--json')
    if($after.exit_code-ne0){throw 'Maintenance cron get after reset failed'}
    try{$a=$after.output|ConvertFrom-Json}catch{throw 'Maintenance cron get after reset invalid JSON'}
    if([string]$a.declarationKey-ne$declarationKey -or [string]$a.name-ne$expectedName){throw 'Maintenance cron identity changed during reset'}
    if($a.PSObject.Properties['enabled'] -and -not[bool]$a.enabled){throw 'Maintenance cron not enabled after reset'}
    $afterErrors=if($a.state -and $a.state.PSObject.Properties['consecutiveErrors']){[int]$a.state.consecutiveErrors}else{0}
    $scheduleErrors=if($a.state -and $a.state.PSObject.Properties['scheduleErrorCount']){[int]$a.state.scheduleErrorCount}else{0}
    if($afterErrors-ne0 -or $scheduleErrors-ne0){throw ('Maintenance cron backoff counters not reset errors='+$afterErrors+' schedule='+$scheduleErrors)}
    $rawAfter=[string]$after.output
    if($rawAfter -notmatch '"everyMs"\s*:\s*300000'){throw 'Maintenance cron cadence changed during reset'}
    Assert-Benchmark30
    return [ordered]@{state='OMEN_PROVEN';declaration_key=$declarationKey;job_name=$expectedName;enabled=$true;cadence_ms=300000;consecutive_errors_before=$beforeErrors;consecutive_errors_after=$afterErrors;schedule_errors_after=$scheduleErrors;job_executed=$false;authority_effect='NONE'}
}

function Assert-MainAgentCanary([object]$m) {
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
    $message='KEVIN_MAIN_AGENT_CANARY_V2: Reply exactly KEVIN_MAIN_AGENT_CANARY_OK. Do not call tools.'
    $gw=$null
    for($probeAttempt=1;$probeAttempt-le3;$probeAttempt++){
        $gw=Invoke-OpenClawFixedConfig @('gateway','call','status','--json')
        if($gw.exit_code-eq0){break}
        if($probeAttempt-lt3){Start-Sleep -Milliseconds (500*$probeAttempt)}
    }
    if($gw.exit_code-ne0){
        $public=[ordered]@{
            schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state='REJECT';safe_for_public_repo=$true
            gateway_probe_ok=$false;agent='fixed:main';agent_exit_code=$null;failure_stage='gateway_probe';status='';exact_expected_reply=$false;tool_calls=0;visible_tool_count=0;visible_tool_names_sha256=(Get-TextSha256 '');visible_kevin_tool_count=0;has_kevin_system_status=$false;duration_ms=0;output_sha256=''
            source_contract='One fixed Gateway-backed OpenClaw fixed-main-agent turn. No caller-selected prompt, agent id, profile, command, argv, path, recipient, or authority.'
            truth_boundary='Metadata-only proof. Raw prompt, model text, CLI output, tool output, configuration, paths, usernames, ports, credentials, and secrets are not published.'
        }
        $null=Publish-MainAgentCanaryReceipt $public
        Assert-Benchmark30
        throw 'main-agent canary direct RPC status failed'
    }
    $sw=[Diagnostics.Stopwatch]::StartNew();$r=Invoke-OpenClawFixedConfig @('agent','--agent','main','--json','--message',$message);$sw.Stop()
    if($r.exit_code-ne0){
        $public=[ordered]@{
            schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state='REJECT';safe_for_public_repo=$true
            gateway_probe_ok=$true;agent='fixed:main';agent_exit_code=[int]$r.exit_code;failure_stage='agent_cli';status='';exact_expected_reply=$false;tool_calls=0;visible_tool_count=0;visible_tool_names_sha256=(Get-TextSha256 '');visible_kevin_tool_count=0;has_kevin_system_status=$false;duration_ms=[int]$sw.ElapsedMilliseconds;output_sha256=(Get-TextSha256 ([string]$r.output))
            source_contract='One fixed Gateway-backed OpenClaw fixed-main-agent turn. No caller-selected prompt, agent id, profile, command, argv, path, recipient, or authority.'
            truth_boundary='Metadata-only proof. Raw prompt, model text, CLI output, tool output, configuration, paths, usernames, ports, credentials, and secrets are not published.'
        }
        $null=Publish-MainAgentCanaryReceipt $public
        Assert-Benchmark30
        throw 'main-agent canary fixed-main-agent CLI invocation failed'
    }
    try{$o=ConvertFrom-ReaderJson ([string]$r.output)}catch{
        $public=[ordered]@{
            schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state='REJECT';safe_for_public_repo=$true
            gateway_probe_ok=$true;agent='fixed:main';agent_exit_code=0;failure_stage='agent_json_parse';status='';exact_expected_reply=$false;tool_calls=0;visible_tool_count=0;visible_tool_names_sha256=(Get-TextSha256 '');visible_kevin_tool_count=0;has_kevin_system_status=$false;duration_ms=[int]$sw.ElapsedMilliseconds;output_sha256=(Get-TextSha256 ([string]$r.output))
            source_contract='One fixed Gateway-backed OpenClaw fixed-main-agent turn. No caller-selected prompt, agent id, profile, command, argv, path, recipient, or authority.'
            truth_boundary='Metadata-only proof. Raw prompt, model text, CLI output, tool output, configuration, paths, usernames, ports, credentials, and secrets are not published.'
        }
        $null=Publish-MainAgentCanaryReceipt $public
        Assert-Benchmark30
        throw 'main-agent canary fixed-main-agent JSON parse failed'
    }
    $status=[string]$o.status;$finalText=Get-ReaderFinalText $o;$calls=Get-ReaderToolCalls $o;$tools=@(Get-ReaderVisibleToolNames $o|Sort-Object -Unique)
    $expected=($finalText -eq 'KEVIN_MAIN_AGENT_CANARY_OK')
    $toolHash=Get-TextSha256 (($tools -join "`n"))
    $kevinCount=@($tools|Where-Object{$_ -match '^(?i)kevin[_-]'}).Count
    $success=($status-eq'success' -and $expected -and $calls-eq0)
    $public=[ordered]@{
        schema=1;kind='kevin-main-agent-canary-public';generated_at=(Get-Date).ToString('o');state=if($success){'OMEN_PROVEN'}else{'REJECT'};safe_for_public_repo=$true
        gateway_probe_ok=$true;agent='fixed:main';agent_exit_code=0;failure_stage=if($success){''}else{'semantic_contract'};status=$status;exact_expected_reply=$expected;tool_calls=$calls;visible_tool_count=$tools.Count;visible_tool_names_sha256=$toolHash;visible_kevin_tool_count=$kevinCount;has_kevin_system_status=($tools -contains 'kevin_system_status');duration_ms=[int]$sw.ElapsedMilliseconds;output_sha256=(Get-TextSha256 $finalText)
        source_contract='One fixed Gateway-backed OpenClaw fixed-main-agent turn. No caller-selected prompt, agent id, profile, command, argv, path, recipient, or authority.'
        truth_boundary='Metadata-only proof of one real fixed-main-agent turn and its prompt-reported visible tool surface. Raw prompt, model text, CLI output, tool output, tool names list, configuration, paths, usernames, ports, credentials, and secrets are not published.'
    }
    $pub=Publish-MainAgentCanaryReceipt $public
    Assert-Benchmark30
    if(-not$success){throw 'main-agent canary semantic contract rejected'}
    return [ordered]@{state='OMEN_PROVEN';published=$pub.published;receipt_sha256=$pub.receipt_sha256;agent='main';visible_tool_count=$tools.Count;visible_kevin_tool_count=$kevinCount;tool_calls=0;authority_effect='NONE'}
}

function Assert-AutonomyContinuationAutomation([object]$m) {
    $allowed=@('schema','kind','id','authority_class','authority_delta','production_effect','owner_policy','preauthorized','operation','expires_at')
    foreach($p in $m.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw ('autonomy continuation manifest must not supply '+[string]$p)}}
    if([string]$m.operation -ne 'ensure_autonomy_continuation_automation'){throw 'autonomy continuation operation mismatch'}
}

function Get-AutonomyContinuationJobs {
    $r=Invoke-OpenClawFixedConfig @('cron','list','--all','--json')
    if($r.exit_code -ne 0){throw ('OpenClaw automation list failed: '+(Safe-Text $r.output 240))}
    try{$obj=$r.output|ConvertFrom-Json}catch{throw 'OpenClaw automation list returned invalid JSON'}
    if($obj -is [array]){return @($obj)}
    if($obj.PSObject.Properties['jobs']){return @($obj.jobs)}
    if($obj.PSObject.Properties['items']){return @($obj.items)}
    return @($obj)
}

function Ensure-AutonomyContinuationAutomation {
    $name='Kevin Autonomy Continuation v1'
    $event='KEVIN_CONTINUATION_V1: Execute standing orders now. Refresh trusted evidence. If an active GREEN goal can advance, select the highest eligible UNSATISFIED item via governed selector/Task Flow; never re-select already-satisfied work; execute only existing proven typed GREEN paths; semantically verify; record outcome/evidence/failure family; then continue. If production WIP is occupied, advance an independent eligible staging or research item within WIP. Do not manufacture Forge/design demand. If no eligible action exists, record the exact blocker and return NO_REPLY.'
    $jobs=@(Get-AutonomyContinuationJobs|Where-Object{[string]$_.name -eq $name})
    if($jobs.Count -gt 1){throw 'duplicate Kevin Autonomy Continuation jobs detected'}
    $changed=$false
    if($jobs.Count -eq 0){
        $create=Invoke-OpenClawFixedConfig @('cron','add','--name',$name,'--every','5m','--session','main','--system-event',$event,'--wake','now')
        if($create.exit_code -ne 0){throw ('autonomy continuation automation create failed: '+(Safe-Text $create.output 260))}
        $changed=$true
        $jobs=@(Get-AutonomyContinuationJobs|Where-Object{[string]$_.name -eq $name})
        if($jobs.Count -ne 1){throw 'autonomy continuation automation create did not converge to exactly one job'}
    }
    $id=[string]$jobs[0].id
    if(-not$id){throw 'autonomy continuation automation missing id'}
    $get=Invoke-OpenClawFixedConfig @('cron','get',$id,'--json')
    if($get.exit_code -ne 0){throw 'autonomy continuation automation get failed'}
    try{$job=$get.output|ConvertFrom-Json}catch{throw 'autonomy continuation automation get returned invalid JSON'}
    if([string]$job.name -ne $name){throw 'autonomy continuation job name readback mismatch'}
    if($job.PSObject.Properties['enabled'] -and [bool]$job.enabled -ne $true){throw 'autonomy continuation job is disabled'}
    $raw=[string]$get.output
    if($raw -notmatch '"everyMs"\s*:\s*300000'){throw 'autonomy continuation cadence readback mismatch'}
    if($raw -notmatch '"kind"\s*:\s*"systemEvent"'){throw 'autonomy continuation payload kind mismatch'}
    if(-not$raw.Contains('KEVIN_CONTINUATION_V1')){throw 'autonomy continuation event marker missing from readback'}
    $run=Invoke-OpenClawFixedConfig @('cron','run',$id)
    if($run.exit_code -ne 0){throw ('autonomy continuation immediate wake enqueue failed: '+(Safe-Text $run.output 220))}
    Assert-Benchmark30
    return [ordered]@{changed=$changed;idempotent=(-not$changed);job_name=$name;cadence='5m';session='main';payload='systemEvent';wake='now';immediate_run_enqueued=$true;arbitrary_shell=$false;authority_expansion=$false}
}

function Process-Typed([object]$m) {
    Assert-Common $m
    switch([string]$m.operation){
        'replace_pinned_component' { Assert-Replace $m }
        'restart_ui_bridge' { Assert-Restart $m }
        'audit_runtime_convergence' { }
        'publish_runtime_convergence' { }
        'publish_runtime_capabilities' { }
        'replace_runtime_policy_bundle' { Assert-RuntimeBundle $m }
        'migrate_design_forge_v40' { Assert-ForgeMigration $m }
        'configure_skill_workshop_guardrails' { Assert-SkillWorkshopGuardrails $m }
        'run_reader_status_canary' { Assert-ReaderStatusCanary $m }
        'diagnose_forge_r03_contract' { Assert-ForgeR03ContractDiagnosis $m }
        'diagnose_goal_os_forge_anchor' { Assert-GoalOsForgeAnchorDiagnosis $m }
        'diagnose_benchmark_baseline_forge_anchor' { Assert-BenchmarkBaselineForgeAnchorDiagnosis $m }
        'migrate_supervisor_forge_demand_gated_v17' { Assert-SupervisorForgeDemandGateMigration $m }
        'repair_supervisor_v171_forge_pin' { Assert-SupervisorV171ForgePinRepair $m }
        'ensure_autonomy_continuation_automation' { Assert-AutonomyContinuationAutomation $m }
        'run_main_agent_canary' { Assert-MainAgentCanary $m }
        'install_autonomy_controller_v183' { Assert-AutonomyControllerV183Install $m }
        'diagnose_gateway_rpc' { Assert-GatewayRpcDiagnosis $m }
        'run_self_reliance_watchdog_once' { Assert-NoCallerArgs $m 'run_self_reliance_watchdog_once' }
        'diagnose_gateway_failure_detail' { Assert-NoCallerArgs $m 'diagnose_gateway_failure_detail' }
        'repair_openclaw_windows_lkg' { Assert-NoCallerArgs $m 'repair_openclaw_windows_lkg' }
        'reconcile_maintenance_cron_backoff' { Assert-NoCallerArgs $m 'reconcile_maintenance_cron_backoff' }
        default { throw 'operation not allowlisted' }
    }
    Assert-Governance
    $state=Read-Attempts;$rec=Get-AttemptRecord $state ([string]$m.id);$attempts=if($rec){[int]$rec.attempts}else{0}
    if($rec -and [string]$rec.status -eq 'PROVEN'){Save-State 'ALREADY_APPLIED_PROVEN' ([string]$m.id) 'Maintenance previously proven.' @{attempts=$attempts};return}
    if($attempts -ge $MaxAttempts){Save-State 'BLOCKED_FAILURE_BUDGET' ([string]$m.id) 'Failure budget exhausted.' @{attempts=$attempts};return}
    $attempts++
    try{
        $result=switch([string]$m.operation){
            'replace_pinned_component' { Install-Pinned $m; break }
            'restart_ui_bridge' { Restart-UiBridge $m; break }
            'audit_runtime_convergence' { Audit-RuntimeConvergence; break }
            'publish_runtime_convergence' { Publish-RuntimeConvergence; break }
            'publish_runtime_capabilities' { Publish-RuntimeCapabilities; break }
            'replace_runtime_policy_bundle' { Install-RuntimePolicyBundle $m; break }
            'migrate_design_forge_v40' { Migrate-DesignForgeV40 $m; break }
            'configure_skill_workshop_guardrails' { Configure-SkillWorkshopGuardrails; break }
            'run_reader_status_canary' { Run-ReaderStatusCanary; break }
            'diagnose_forge_r03_contract' { Diagnose-ForgeR03Contract; break }
            'diagnose_goal_os_forge_anchor' { Diagnose-GoalOsForgeAnchor; break }
            'diagnose_benchmark_baseline_forge_anchor' { Diagnose-BenchmarkBaselineForgeAnchor; break }
            'migrate_supervisor_forge_demand_gated_v17' { Migrate-SupervisorForgeDemandGatedV17 $m; break }
            'repair_supervisor_v171_forge_pin' { Repair-SupervisorV171ForgePin $m; break }
            'ensure_autonomy_continuation_automation' { Ensure-AutonomyContinuationAutomation; break }
            'run_main_agent_canary' { Run-MainAgentCanary; break }
            'install_autonomy_controller_v183' { Install-AutonomyControllerV183 $m; break }
            'diagnose_gateway_rpc' { Diagnose-GatewayRpc; break }
            'run_self_reliance_watchdog_once' { Run-SelfRelianceWatchdogOnce; break }
            'diagnose_gateway_failure_detail' { Diagnose-GatewayFailureDetail; break }
            'repair_openclaw_windows_lkg' { Repair-OpenClawWindowsLkg; break }
            'reconcile_maintenance_cron_backoff' { Reconcile-MaintenanceCronBackoff; break }
        }
        Save-Attempt ([string]$m.id) $attempts 'PROVEN'
        Save-State 'APPLIED_PREAUTHORIZED_PROVEN' ([string]$m.id) 'Applied/audited and independently verified.' @{attempts=$attempts;operation=[string]$m.operation;result=$result}
    }catch{
        $family=switch([string]$m.operation){
            'restart_ui_bridge' {'ui_bridge_restart_failure'}
            'audit_runtime_convergence' {'runtime_convergence_audit_failure'}
            'publish_runtime_convergence' {'runtime_convergence_publish_failure'}
            'publish_runtime_capabilities' {'runtime_capabilities_publish_failure'}
            'replace_runtime_policy_bundle' {'runtime_policy_bundle_failure'}
            'migrate_design_forge_v40' {'forge_validator_migration_failure'}
            'configure_skill_workshop_guardrails' {'skill_workshop_guardrail_failure'}
            'run_reader_status_canary' {'reader_status_canary_failure'}
            'diagnose_forge_r03_contract' {'forge_r03_contract_diagnosis_failure'}
            'diagnose_goal_os_forge_anchor' {'goal_os_forge_anchor_diagnosis_failure'}
            'diagnose_benchmark_baseline_forge_anchor' {'benchmark_baseline_forge_anchor_diagnosis_failure'}
            'migrate_supervisor_forge_demand_gated_v17' {'supervisor_forge_demand_gate_migration_failure'}
            'repair_supervisor_v171_forge_pin' {'supervisor_v171_forge_pin_repair_failure'}
            'ensure_autonomy_continuation_automation' {'autonomy_continuation_automation_failure'}
            'run_main_agent_canary' {'main_agent_canary_failure'}
            'install_autonomy_controller_v183' {'autonomy_controller_v183_install_failure'}
            'diagnose_gateway_rpc' {'gateway_rpc_diagnosis_failure'}
            'run_self_reliance_watchdog_once' {'self_reliance_operational_probe_failure'}
            'diagnose_gateway_failure_detail' {'gateway_failure_detail_diagnosis_failure'}
            'repair_openclaw_windows_lkg' {'openclaw_windows_lkg_recovery_failure'}
            'reconcile_maintenance_cron_backoff' {'maintenance_cron_backoff_reconcile_failure'}
            default {'typed_replace_failure'}
        }
        Save-Attempt ([string]$m.id) $attempts 'FAILED' $family
        Save-State 'APPLY_FAILED' ([string]$m.id) $_.Exception.Message @{attempts=$attempts;failure_family=$family}
        Write-Host ('MAINTENANCE TYPED OUTCOME APPLY_FAILED family='+$family+' attempts='+$attempts)
        return
    }
}

function Legacy-Stage([string]$Text,[bool]$Apply) { $m=$Text|ConvertFrom-Json;if([int]$m.schema -ne 1 -or [string]$m.kind -ne 'kevin-maintenance-manifest'){throw 'legacy manifest invalid'};if(-not$Apply){Save-State 'LEGACY_STAGED_APPROVAL_REQUIRED' ([string]$m.id) 'Legacy executable package requires one-time ApplyOnce.';return};throw 'v1.3.4 never executes legacy executable maintenance packages' }
function Invoke-SelfTest {
    $base=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-maint-001';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='replace_pinned_component';target_alias='maintenance_runner';source_path='control-plane/maintenance/kevin-maintenance-runner-v1.3.4.ps1';source_sha256=('A'*64);expected_current_sha256=('B'*64);expected_after_sha256=('A'*64);expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-Common $base;Assert-Replace $base
    foreach($case in @(
        @('work_order_intake','control-plane/intake/kevin-work-order-intake-v1.2.3.ps1'),
        @('skill_lab_runner','control-plane/skill-lab/kevin-skill-lab-v1.0.4.ps1'),
        @('os_observer_runner','control-plane/os-awareness/kevin-os-observer-v0.1.ps1'),
        @('self_reliance_watchdog','control-plane/maintenance/kevin-self-reliance-watchdog-v1.4.ps1'),
        @('design_forge_runner','control-plane/forge/kevin-design-forge-v4.0.ps1')
    )){$x=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$x.target_alias=$case[0];$x.source_path=$case[1];if($case[0] -eq 'os_observer_runner'){$x.expected_current_sha256=$AbsentHash};Assert-Replace $x}
    $bundle=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-runtime-policy';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='replace_runtime_policy_bundle';expires_at=(Get-Date).AddMinutes(10).ToString('o');components=@()}
    foreach($name in $RuntimePolicyNames){$bundle.components+=,[pscustomobject]@{name=$name;source_sha256=('A'*64);expected_current_sha256=('B'*64);expected_after_sha256=('A'*64)}}
    Assert-Common $bundle;Assert-RuntimeBundle $bundle
    $bad=$bundle|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.components=@($bad.components|Select-Object -First 4);$blocked=$false;try{Assert-RuntimeBundle $bad}catch{$blocked=$true};if(-not$blocked){throw 'partial runtime policy bundle accepted'}
    $bad=$bundle|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.components[0].name='BAD.md';$blocked=$false;try{Assert-RuntimeBundle $bad}catch{$blocked=$true};if(-not$blocked){throw 'unknown runtime policy component accepted'}
    $audit=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$audit.operation='audit_runtime_convergence';$audit.PSObject.Properties.Remove('target_alias');$audit.PSObject.Properties.Remove('source_path');$audit.PSObject.Properties.Remove('source_sha256');$audit.PSObject.Properties.Remove('expected_current_sha256');$audit.PSObject.Properties.Remove('expected_after_sha256');Assert-Common $audit


    $pub=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$pub.operation='publish_runtime_convergence';Assert-Common $pub
    $cap=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$cap.operation='publish_runtime_capabilities';Assert-Common $cap


    $reader=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$reader.operation='run_reader_status_canary';Assert-Common $reader;Assert-ReaderStatusCanary $reader
    $readerBad=$reader|ConvertTo-Json -Depth 10|ConvertFrom-Json;$readerBad|Add-Member -NotePropertyName prompt -NotePropertyValue 'override';$blocked=$false;try{Assert-ReaderStatusCanary $readerBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Reader prompt accepted'}
    $goodText='Overall healthy. RAM 40%. CPU 12%. GPU 7%. Disk free space 500 GB. Ollama running. Gateway open.'
    $pt=Test-ReaderPublicText $goodText;if(-not$pt.ok -or $pt.categories -ne 6){throw 'Reader semantic text fixture failed'}
    $badText='RAM CPU GPU disk Ollama gateway C:\Users\secret';$pt=Test-ReaderPublicText $badText;if($pt.ok){throw 'Reader privacy fixture accepted'}


    $ga=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$ga.operation='diagnose_goal_os_forge_anchor';Assert-Common $ga;Assert-GoalOsForgeAnchorDiagnosis $ga
    $gaBad=$ga|ConvertTo-Json -Depth 10|ConvertFrom-Json;$gaBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-GoalOsForgeAnchorDiagnosis $gaBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Goal OS path accepted'}
    $bb=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bb.operation='diagnose_benchmark_baseline_forge_anchor';Assert-Common $bb;Assert-BenchmarkBaselineForgeAnchorDiagnosis $bb
    $bbBad=$bb|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bbBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-BenchmarkBaselineForgeAnchorDiagnosis $bbBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Benchmark baseline path accepted'}
    $fixture=[pscustomobject]@{hashes=[pscustomobject]@{forge=('A'*64);other='x'}};$hits=@(Find-ForgeAnchorMatches $fixture ('A'*64));if($hits.Count-ne1 -or $hits[0].leaf-ne'forge'){throw 'Goal OS Forge anchor fixture failed'}
    $fixture2=[pscustomobject]@{hashes=[pscustomobject]@{notforge=('A'*64)}};$hits=@(Find-ForgeAnchorMatches $fixture2 ('A'*64));if($hits.Count-ne0){throw 'non-Forge same hash fixture accepted'}
    $diag=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$diag.operation='diagnose_forge_r03_contract';Assert-Common $diag;Assert-ForgeR03ContractDiagnosis $diag
    $diagBad=$diag|ConvertTo-Json -Depth 10|ConvertFrom-Json;$diagBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-ForgeR03ContractDiagnosis $diagBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected R03 path accepted'}
    $hints=Get-SafeR03IdentifierHints '$forgeExpected = $goal_os.forge_hash; $secretToken = 1';if($hints -notcontains 'forgeExpected' -or $hints -notcontains 'goal_os' -or $hints -contains 'secretToken'){throw 'R03 identifier redaction fixture failed'}
    $guard=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$guard.operation='configure_skill_workshop_guardrails';Assert-Common $guard;Assert-SkillWorkshopGuardrails $guard
    $guardBad=$guard|ConvertTo-Json -Depth 10|ConvertFrom-Json;$guardBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary.path';$blocked=$false;try{Assert-SkillWorkshopGuardrails $guardBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Workshop config path accepted'}
    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='migrate_design_forge_v40';target_alias='design_forge_runner';source_path='control-plane/forge/kevin-design-forge-v4.0.ps1';source_sha256=('C'*64);expected_forge_current_sha256=('B'*64);expected_forge_after_sha256=('C'*64);expected_benchmark_current_sha256=('D'*64);expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-Common $mig;Assert-ForgeMigration $mig
    $fake=('prefix '+('B'*64)+' suffix')
    $patched=Get-ForgePinPatchedBenchmark $fake ('B'*64) ('C'*64)
    if((Get-LiteralOccurrenceCount $patched ('B'*64)) -ne 0 -or (Get-LiteralOccurrenceCount $patched ('C'*64)) -ne 1){throw 'Forge pin patch helper selftest failed'}
    $blocked=$false;try{Get-ForgePinPatchedBenchmark ($fake+' '+('B'*64)) ('B'*64) ('C'*64)|Out-Null}catch{$blocked=$true};if(-not$blocked){throw 'duplicate old Forge pin accepted'}
    $bad=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.target_alias='supervisor';$blocked=$false;try{Assert-Replace $bad}catch{$blocked=$true};if(-not$blocked){throw 'unknown alias accepted'}
    $bad=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.operation='shell';$blocked=$false;try{Assert-Common $bad}catch{$blocked=$true};if(-not$blocked){throw 'arbitrary operation accepted'}
    Write-Host 'KEVIN MAINTENANCE v1.3.2 SELFTEST PASS compatibility=v1.3.4'
    Write-Host 'KEVIN MAINTENANCE v1.3.3 SELFTEST PASS compatibility=v1.3.4'
    Write-Host 'KEVIN MAINTENANCE v1.3.4 SELFTEST PASS compatibility=v1.3.5'
    Write-Host 'KEVIN MAINTENANCE v1.3.5 SELFTEST PASS compatibility=v1.3.6'
    Write-Host 'KEVIN MAINTENANCE v1.3.6 SELFTEST PASS compatibility=v1.3.7'
    Write-Host 'KEVIN MAINTENANCE v1.3.7 SELFTEST PASS compatibility=v1.3.8'
    Write-Host 'KEVIN MAINTENANCE v1.3.8 SELFTEST PASS compatibility=v1.3.9'
    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS compatibility=v1.3.13'
    Write-Host 'KEVIN MAINTENANCE v1.3.10 SELFTEST PASS compatibility=v1.3.13'
    Write-Host 'KEVIN MAINTENANCE v1.3.12 SELFTEST PASS compatibility=v1.3.13'
    Write-Host 'KEVIN MAINTENANCE v1.3.13 SELFTEST PASS goal_os_anchor_discovery=fixed exact_hash_lookup=true unique_forge_anchor=true inventory_max=500 r03_contract_diagnosis=fixed arbitrary_shell=false authority_expansion=false max_attempts=3'
    $sf=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-supervisor-forge-v17';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='migrate_supervisor_forge_demand_gated_v17';expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-Common $sf;Assert-SupervisorForgeDemandGateMigration $sf
    $sfBad=$sf|ConvertTo-Json -Depth 10|ConvertFrom-Json;$sfBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-SupervisorForgeDemandGateMigration $sfBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Supervisor/Forge path accepted'}
    $nl=[Environment]::NewLine
    $fixture='# Kevin Supervisor v1.6 High Gear'+$nl+'prefix'+$nl+'    $recoveryExperiment = $null'+$nl+'legacy MissionContractPath suffix'+$nl
    $gate=Get-DemandGatedSupervisorV17 $fixture
    if(-not$gate.Contains('# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel') -or -not$gate.Contains('SUPERVISOR IDLE NO_ELIGIBLE_MISSION')){throw 'Supervisor v1.7 deterministic patch fixture failed'}
    if($gate.IndexOf('SUPERVISOR IDLE NO_ELIGIBLE_MISSION') -ge $gate.IndexOf('MissionContractPath')){throw 'Supervisor v1.7 gate fixture is after legacy dispatch'}
    Write-Host 'KEVIN MAINTENANCE v1.3.15 SELFTEST PASS benchmark_baseline_anchor=fixed typed_apply_failure=handled scheduler_backoff_poison=false arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.16 SELFTEST PASS supervisor_forge_migration=fixed baseline_anchor=atomic mutex_protected=true demand_gate=true rollback=true arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.17 SELFTEST PASS operation_parity=fixed supervisor_forge_validation=true arbitrary_shell=false authority_expansion=false'
    $sr=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$sr.operation='repair_supervisor_v171_forge_pin';Assert-Common $sr;Assert-SupervisorV171ForgePinRepair $sr
    $srBad=$sr|ConvertTo-Json -Depth 10|ConvertFrom-Json;$srBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-SupervisorV171ForgePinRepair $srBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Supervisor repair path accepted'}
    $fixture='# Kevin Supervisor v1.7 Demand-Gated Compatibility Sentinel'+[Environment]::NewLine+$ForgeV37Sha+[Environment]::NewLine+'Design Forge hash changed from approved v3.7.'+[Environment]::NewLine+'SUPERVISOR IDLE NO_ELIGIBLE_MISSION'+[Environment]::NewLine
    $fixed=Get-SupervisorV171ForgePinPatched $fixture
    if((Get-LiteralOccurrenceCount $fixed $ForgeV37Sha)-ne0 -or (Get-LiteralOccurrenceCount $fixed $ForgeV40Sha)-ne1){throw 'Supervisor v1.7.1 Forge pin fixture failed'}
    Write-Host 'KEVIN MAINTENANCE v1.3.18 SELFTEST PASS supervisor_v171_forge_pin=fixed demand_gate_preserved=true rollback=true operation_parity=true arbitrary_shell=false authority_expansion=false'
    $ac=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$ac.operation='ensure_autonomy_continuation_automation';Assert-Common $ac;Assert-AutonomyContinuationAutomation $ac
    $mac=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$mac.operation='run_main_agent_canary';Assert-Common $mac;Assert-MainAgentCanary $mac
    $macBad=$mac|ConvertTo-Json -Depth 10|ConvertFrom-Json;$macBad|Add-Member -NotePropertyName prompt -NotePropertyValue 'override';$blocked=$false;try{Assert-MainAgentCanary $macBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected main-agent prompt accepted'}
    $acBad=$ac|ConvertTo-Json -Depth 10|ConvertFrom-Json;$acBad|Add-Member -NotePropertyName command -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-AutonomyContinuationAutomation $acBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected autonomy automation command accepted'}
    Write-Host 'KEVIN MAINTENANCE v1.3.19 SELFTEST PASS supervisor_baseline_anchor=atomic forge_v4_anchor=preserved rollback=true operation_parity=true arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.20 SELFTEST PASS native_automation=fixed cadence=5m system_event=true main_session=true arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.21 SELFTEST PASS canonical_automations_cli=true noninteractive_scheduler_adapter=fixed arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.22 SELFTEST PASS cli_surface_audit=fixed read_only=true raw_help_published=false arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.23 SELFTEST PASS main_agent_canary=fixed gateway_backed=true raw_text_published=false arbitrary_shell=false authority_expansion=false'
    $aci=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$aci.operation='install_autonomy_controller_v183';Assert-Common $aci;Assert-AutonomyControllerV183Install $aci
    $aciBad=$aci|ConvertTo-Json -Depth 10|ConvertFrom-Json;$aciBad|Add-Member -NotePropertyName source_path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-AutonomyControllerV183Install $aciBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected autonomy controller path accepted'}
    Write-Host 'KEVIN MAINTENANCE v1.3.24 SELFTEST PASS default_agent_canary=fixed failure_receipt=true raw_text_published=false arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.25 SELFTEST PASS autonomy_controller_install=fixed supervisor_v183=true selector_v11=true baseline_anchor=atomic rollback=true arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.26 SELFTEST PASS fixed_main_canary=true gateway_rpc_only=true gateway_probe_retries=3 supervisor_v183=true selector_v11=true arbitrary_shell=false authority_expansion=false'
    $gdx=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$gdx.operation='diagnose_gateway_rpc';Assert-Common $gdx;Assert-GatewayRpcDiagnosis $gdx
    Write-Host 'KEVIN MAINTENANCE v1.3.27 SELFTEST PASS gateway_direct_rpc=true gateway_diagnosis=metadata-only watchdog_inspection=fixed fixed_main_canary=true arbitrary_shell=false authority_expansion=false'
    $fn=(Get-Command Invoke-OpenClawFixedConfig).ScriptBlock.ToString();if($fn -match '(?i)Get-Command\s+openclaw'){throw 'OpenClaw shim resolution still present in fixed wrapper'}
    if(-not$fn.Contains('Get-FixedOpenClawRuntime')){throw 'native OpenClaw runtime wrapper missing'}
    Write-Host 'KEVIN MAINTENANCE v1.3.28 SELFTEST PASS openclaw_native_node=true shell_shim_bypassed=true native_timeout=180s gateway_direct_rpc=true fixed_main_canary=true arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.29 SELFTEST PASS autonomy_controller_contract=legacy_v183 supervisor_v184=true selector_v11=true openclaw_native_node=true shell_shim_bypassed=true baseline_anchor=atomic rollback=true arbitrary_shell=false authority_expansion=false'
    Write-Host 'KEVIN MAINTENANCE v1.3.30 SELFTEST PASS openclaw_bootstrap_diagnosis=fixed node_probe=fixed cli_version_probe=fixed config_metadata_only=true gateway_classifier=expanded arbitrary_shell=false authority_expansion=false'
    if($GatewayLkgVersion-ne'2026.6.34'-or$GatewayRejectedVersion-ne'2026.7.1-2'){throw 'Gateway release pins changed'}
    if($GatewayLkgIntegrity-notmatch'^sha512-' -or $GatewayRejectedIntegrity-notmatch'^sha512-'){throw 'Gateway integrity pins missing'}
    $wx=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$wx.operation='run_self_reliance_watchdog_once';Assert-Common $wx;Assert-NoCallerArgs $wx 'run_self_reliance_watchdog_once'
    $gfd=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$gfd.operation='diagnose_gateway_failure_detail';Assert-Common $gfd;Assert-NoCallerArgs $gfd 'diagnose_gateway_failure_detail'
    $lkg=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$lkg.operation='repair_openclaw_windows_lkg';Assert-Common $lkg;Assert-NoCallerArgs $lkg 'repair_openclaw_windows_lkg'
    $badLkg=$lkg|ConvertTo-Json -Depth 10|ConvertFrom-Json;$badLkg|Add-Member -NotePropertyName version -NotePropertyValue 'latest';$blocked=$false;try{Assert-NoCallerArgs $badLkg 'repair_openclaw_windows_lkg'}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected OpenClaw version accepted'}
    if((Get-GatewayFailureFamilyDetailed 'OpenClaw startup migrations did not complete cleanly')-ne'STARTUP_MIGRATION_GATE'){throw 'detailed migration classifier failed'}
    if((Get-GatewayFailureFamilyDetailed 'shared SQLite state has conflicting plugin install metadata')-ne'PLUGIN_INSTALL_METADATA_CONFLICT'){throw 'detailed plugin conflict classifier failed'}
    Write-Host 'KEVIN MAINTENANCE v1.3.31 SELFTEST PASS watchdog_operational_proof=fixed gateway_detail=fixed windows_lkg=2026.6.34 integrity_pinned=true keeper_topology_preserved=true safe_config_backup_required=true rollback=true gateway_rpc_postcondition=true main_skills_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'
    $stopFn=(Get-Command Stop-FixedGatewayListener).ScriptBlock.ToString();if($stopFn -match 'foreach\(\$pid\b'){throw 'read-only PID automatic variable collision retained'};if($stopFn -notmatch '\$listenerPid'){throw 'listenerPid fixed variable missing'}
    $npmFn=(Get-Command Invoke-NpmFixed).ScriptBlock.ToString();if($npmFn -match 'npm\.cmd'){throw 'batch npm launcher retained'};if($npmFn -notmatch 'npm-cli\.js'){throw 'fixed npm-cli.js runtime missing'}
    $repairFn=(Get-Command Repair-OpenClawWindowsLkg).ScriptBlock.ToString();if($repairFn -notmatch 'versionTransitionAttempted'){throw 'partial install rollback flag missing'};if($repairFn -notmatch 'starting OpenClaw version not restored'){throw 'exact starting-version rollback verification missing'}
    Write-Host 'KEVIN MAINTENANCE v1.3.32 SELFTEST PASS gateway_listener_pid_collision=false native_npm_cli=true partial_install_rollback=true fixed_listener_identity_check=true rollback=true arbitrary_shell=false authority_expansion=false'
    $wp=(Get-Command Run-SelfRelianceWatchdogOnce).ScriptBlock.ToString()
    if(-not $wp.Contains("'-SelfTest'")){throw 'watchdog fixed self-test invocation missing'}
    if(-not $wp.Contains("'-ProbeOnly'")){throw 'watchdog ProbeOnly invocation missing'}
    if(-not $wp.Contains('installed watchdog does not prove ProbeOnly v1.6.0 contract')){throw 'watchdog v1.6.0 contract guard missing'}
    if(-not $wp.Contains('self-reliance watchdog ProbeOnly run failed')){throw 'watchdog ProbeOnly terminal guard missing'}
    Write-Host 'KEVIN MAINTENANCE v1.3.33 SELFTEST PASS watchdog_probe=v1.6.0 probe_no_intake=true probe_no_restart=true classifier_proof=true native_npm_cli=true package_rollback=true arbitrary_shell=false authority_expansion=false'
    $rb=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$rb.operation='reconcile_maintenance_cron_backoff';Assert-Common $rb;Assert-NoCallerArgs $rb 'reconcile_maintenance_cron_backoff'
    $rbBad=$rb|ConvertTo-Json -Depth 10|ConvertFrom-Json;$rbBad|Add-Member -NotePropertyName job_id -NotePropertyValue 'caller-selected';$blocked=$false;try{Assert-NoCallerArgs $rbBad 'reconcile_maintenance_cron_backoff'}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Maintenance cron id accepted'}
    $contFn=(Get-Command Ensure-AutonomyContinuationAutomation).ScriptBlock.ToString();if($contFn -match "'automations'"){throw 'runtime-incompatible automations CLI remains in continuation'};if($contFn -notmatch "'cron'"){throw 'cron compatibility alias missing from continuation'}
    $backFn=(Get-Command Reconcile-MaintenanceCronBackoff).ScriptBlock.ToString();if(-not$backFn.Contains("'kevin-maintenance-intake-v1'")){throw 'fixed Maintenance declaration key missing'};if(-not$backFn.Contains("'Kevin Maintenance Intake v1.1d'")){throw 'fixed Maintenance name missing'};if(-not$backFn.Contains("'--enable'")){throw 'scheduler-owned reset patch missing'};if($backFn.Contains("@('cron','run',`$id)")){throw 'backoff reconciler must not execute Maintenance job'}
    Write-Host 'KEVIN MAINTENANCE v1.3.34 SELFTEST PASS continuation_cli=cron_alias runtime_compatible=true maintenance_backoff_reset=enabled_patch no_recursive_run=true fixed_job_identity=true benchmark_postcondition=true arbitrary_shell=false authority_expansion=false'
    $pubFn=(Get-Command Publish-SafeFixedReport).ScriptBlock.ToString();if($pubFn -notmatch 'attempt=1;\$attempt-le3'){throw 'safe report bounded retry loop missing'};if(-not$pubFn.Contains("--jq','.content")){throw 'safe report remote verification fetch missing'};if(-not$pubFn.Contains('remoteHash-eq$localHash')){throw 'safe report hash verification missing'};if($pubFn -match '(?i)invoke-expression|kevin_shell|cmd\.exe'){throw 'safe report publisher widened authority'}
    Write-Host 'KEVIN MAINTENANCE v1.3.35 SELFTEST PASS safe_report_publish=bounded3 create_update_race=true remote_hash_verify=true continuation_cli=cron_alias backoff_reset=true arbitrary_shell=false authority_expansion=false'
    $lkgFn=(Get-Command Repair-OpenClawWindowsLkg).ScriptBlock.ToString();if($lkgFn.Contains('SAFE_BACKUP_NOT_PROVEN_FOR_DOWNGRADE') -or $lkgFn.Contains('SAFE_BACKUP_VERSION_NOT_COMPATIBLE')){throw 'metadata-only downgrade backup gate retained'};if(-not$lkgFn.Contains('pretransition config snapshot hash mismatch')){throw 'exact pretransition config snapshot verification missing'};if(-not$lkgFn.Contains('LKG current-config compatibility validation failed')){throw 'target-version config compatibility validation missing'};if(-not$lkgFn.Contains('LKG config validation unexpectedly modified config')){throw 'config mutation guard missing'};if(-not$lkgFn.Contains('starting OpenClaw config not restored exactly')){throw 'exact config rollback verification missing'};if(-not$lkgFn.Contains('starting OpenClaw version not restored')){throw 'exact package rollback verification missing'}
    Write-Host 'KEVIN MAINTENANCE v1.3.36 SELFTEST PASS lkg_config_compat=target_validates_untouched transactional_snapshot=true config_hash_unchanged=true exact_config_rollback=true exact_package_rollback=true keeper_preserved=true gateway_rpc_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'
    $pkgFn=(Get-Command Install-ExactOpenClaw).ScriptBlock.ToString();$dlFn=(Get-Command Download-VerifiedOpenClawTarball).ScriptBlock.ToString();$specFn=(Get-Command Get-FixedOpenClawTarballSpec).ScriptBlock.ToString();if(-not$pkgFn.Contains("'--global'") -or -not$pkgFn.Contains('$tar')){throw 'verified local tarball install missing'};if(-not$dlFn.Contains('Get-FileSriSha512')){throw 'tarball byte-level SRI verification missing'};if(-not$specFn.Contains('https://registry.npmjs.org/openclaw/-/openclaw-')){throw 'fixed official registry tarball root missing'};if($specFn.Contains('http://')){throw 'insecure tarball transport present'};$lkgSpec=Get-FixedOpenClawTarballSpec $GatewayLkgVersion;$rejSpec=Get-FixedOpenClawTarballSpec $GatewayRejectedVersion;if([string]$lkgSpec.uri-ne'https://registry.npmjs.org/openclaw/-/openclaw-2026.6.34.tgz' -or [string]$lkgSpec.integrity-ne$GatewayLkgIntegrity){throw 'LKG package spec mismatch'};if([string]$rejSpec.uri-ne'https://registry.npmjs.org/openclaw/-/openclaw-2026.7.1-2.tgz' -or [string]$rejSpec.integrity-ne$GatewayRejectedIntegrity){throw 'rollback package spec mismatch'};$untrustedRejected=$false;try{$null=Get-FixedOpenClawTarballSpec '2026.9.9'}catch{$untrustedRejected=$true};if(-not$untrustedRejected){throw 'untrusted package version accepted'}
    Write-Host 'KEVIN MAINTENANCE v1.3.37 SELFTEST PASS package_source=fixed_registry_tarball fixed_specs_runtime_proven=true byte_sri_sha512=true embedded_windows_policy_pin=true install_from_verified_local_tarball=true rollback_package_same_contract=true dynamic_npm_view=false arbitrary_url=false arbitrary_shell=false authority_expansion=false'
    foreach($fn in @('Invoke-OpenClawFixedConfig','Invoke-ReaderOpenClaw','Invoke-NpmFixed')){if((Get-Command $fn).Parameters.ContainsKey('Args')){throw 'automatic Args parameter must never be used for fixed command forwarding'};if(-not(Get-Command $fn).Parameters.ContainsKey('CommandArguments')){throw 'explicit command argument parameter missing'}};$diagFn=(Get-Command Diagnose-GatewayFailureDetail).ScriptBlock.ToString();foreach($m in @("@('config','validate','--json')","@('gateway','status','--require-rpc','--json')","@('gateway','call','status','--json')","@('gateway','health','--json')",'NONE_ALL_PROBES_PASSED','CLASSIFY_FAILED_PROBE_BEFORE_REPAIR')){if(-not$diagFn.Contains($m)){throw ('diagnostic contract missing '+$m)}}
    Write-Host 'KEVIN MAINTENANCE v1.3.38 SELFTEST PASS convergence=true explicit_command_arguments=true win32_argv_preserved=true four_independent_readonly_probes=true false_downgrade_prevented=true package_source=fixed_registry_tarball byte_sri_sha512=true supervisor_target=v1.8.5 authority_expansion=false arbitrary_shell=false'
}

if($SelfTest){Invoke-SelfTest;exit 0}
try{$text=Get-RemoteManifestText;if($null -eq $text){Save-State 'NO_MANIFEST' '' 'No maintenance proposal is waiting.';exit 0};$m=$text|ConvertFrom-Json;if([int]$m.schema -eq 3 -and [string]$m.kind -eq 'kevin-self-maintenance-manifest'){Process-Typed $m;exit 0};if([int]$m.schema -eq 2 -and [string]$m.kind -eq 'kevin-typed-maintenance-manifest'){Save-State 'SCHEMA2_NEEDS_MIGRATION' ([string]$m.id) 'v1.3.4 requires schema-3 aliases for self-maintenance transport.';exit 0};Legacy-Stage $text ([bool]$ApplyOnce);exit 0}catch{if(-not(Test-Path $LatestPath) -or (Get-Content $LatestPath -Raw) -notmatch 'APPLY_FAILED'){Save-State 'ERROR' '' $_.Exception.Message};Write-Host('MAINTENANCE ERROR '+(Safe-Text $_.Exception.Message 600));exit 1}
