param(
    [switch]$SelfTest,
    [switch]$ApplyOnce
)
# Kevin Maintenance v1.3.51 Expired-Manifest Clean-Idle Compatibility Wrapper
# Authority-neutral hardening around exact-pinned v1.3.50. Expired canonical
# manifests are refused before delegation and recorded as a clean terminal idle
# state so scheduler health is not poisoned by intentionally stale input.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)
$Workspace = if ($env:KEVIN_MAINT_TEST_ROOT) { $env:KEVIN_MAINT_TEST_ROOT } elseif ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Reports = Join-Path $Workspace 'reports'
$Root = Join-Path $Reports 'maintenance'
$LatestPath = Join-Path $Root 'latest.json'
$ControlPlane = Join-Path $Workspace 'ControlPlane'
$ParentCache = Join-Path $ControlPlane 'kevin-maintenance-core-v1.3.50.ps1'
$Repo = 'hessmodee/KEVIN-WORK'
$ParentRepoPath = 'control-plane/maintenance/kevin-maintenance-runner-v1.3.50.ps1'
$ManifestRepoPath = 'inbox/maintenance/manifest.json'
$ExpectedParentSha = '8E01A9DFE52CEE241DAD30B10181BACD1B258907482262811EFDA92DFA5646DE'

foreach($d in @($Reports,$Root,$ControlPlane)){New-Item -ItemType Directory -Force -Path $d|Out-Null}

function Get-Sha([string]$Path){
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return ''}
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Write-JsonAtomic([string]$Path,[object]$Object){
    $tmp=$Path+'.tmp-'+[guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 20),$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Safe-Text([object]$Value,[int]$Max=600){
    $s=[string]$Value
    foreach($pattern in @(
        '(?i)\bghp_[A-Za-z0-9_]{8,}\b',
        '(?i)\bgithub_pat_[A-Za-z0-9_]{8,}\b',
        '(?i)\bsk-[A-Za-z0-9_-]{8,}\b',
        '(?i)(Authorization\s*:\s*Bearer\s+)[^\s''";,]+'
    )){$s=[regex]::Replace($s,$pattern,'[REDACTED]')}
    $s=$s.Replace("`r",' ').Replace("`n",' ')
    if($s.Length-gt$Max){$s=$s.Substring(0,$Max)}
    return $s
}
function Save-State([string]$Status,[string]$ManifestId='',[string]$Detail='',[hashtable]$Extra=$null){
    $o=[ordered]@{
        schema=3
        kind='kevin-maintenance-state'
        version='1.3.51'
        at=(Get-Date).ToString('o')
        status=$Status
        manifest_id=$ManifestId
        detail=(Safe-Text $Detail)
    }
    if($Extra){foreach($k in $Extra.Keys){$o[$k]=$Extra[$k]}}
    Write-JsonAtomic $LatestPath $o
}
function Invoke-GhFixed([string[]]$CommandArguments){
    $gh=(Get-Command gh -ErrorAction Stop).Source
    $oldGh=[Environment]::GetEnvironmentVariable('GH_TOKEN','Process')
    $oldGithub=[Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    $old=$ErrorActionPreference
    try{
        Remove-Item Env:GH_TOKEN,Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
        $ErrorActionPreference='Continue'
        $out=(& $gh @CommandArguments 2>&1|Out-String).Trim()
        $code=[int]$LASTEXITCODE
        if($code-ne0){throw('gh fixed request failed: '+(Safe-Text $out 240))}
        return $out
    }finally{
        $ErrorActionPreference=$old
        if($null-ne$oldGh){$env:GH_TOKEN=$oldGh}else{Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue}
        if($null-ne$oldGithub){$env:GITHUB_TOKEN=$oldGithub}else{Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue}
    }
}
function Get-RepoText([string]$Path){
    if($Path -notin @($ManifestRepoPath,$ParentRepoPath)){throw 'repo path rejected'}
    $endpoint='repos/'+$Repo+'/contents/'+$Path+'?ref=main'
    $b64=Invoke-GhFixed @('api',$endpoint,'--jq','.content')
    if(-not$b64){return $null}
    try{return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($b64-replace'\s','')))}
    catch{throw 'repo content base64 invalid'}
}
function Get-ManifestText{
    if($env:KEVIN_MAINT_TEST_ROOT -and $env:KEVIN_MAINT_TEST_MANIFEST_TEXT){
        return [string]$env:KEVIN_MAINT_TEST_MANIFEST_TEXT
    }
    return Get-RepoText $ManifestRepoPath
}
function Test-IsCanonicalExpired([string]$Text,[ref]$ManifestId,[ref]$ExpiresAt){
    $ManifestId.Value=''
    $ExpiresAt.Value=''
    if(-not$Text){return $false}
    try{$m=$Text|ConvertFrom-Json}catch{return $false}
    if([int]$m.schema-ne3 -or [string]$m.kind-ne'kevin-self-maintenance-manifest'){return $false}
    if([string]$m.id -notmatch '^[A-Za-z0-9._-]{6,96}$'){return $false}
    if([string]$m.authority_class-ne'GREEN' -or [string]$m.authority_delta-ne'NONE' -or [string]$m.production_effect-ne'NONE'){return $false}
    if([string]$m.owner_policy-ne'Kevin Owner Authorization v1' -or [bool]$m.preauthorized-ne$true){return $false}
    $allowed=@(
        'replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','publish_runtime_convergence',
        'publish_runtime_capabilities','replace_runtime_policy_bundle','migrate_design_forge_v40',
        'configure_skill_workshop_guardrails','run_reader_status_canary','diagnose_forge_r03_contract',
        'diagnose_goal_os_forge_anchor','diagnose_benchmark_baseline_forge_anchor',
        'migrate_supervisor_forge_demand_gated_v17','repair_supervisor_v171_forge_pin',
        'ensure_autonomy_continuation_automation','run_main_agent_canary','install_autonomy_controller_v183',
        'install_autonomy_controller_v1810','diagnose_gateway_rpc','run_self_reliance_watchdog_once',
        'diagnose_gateway_failure_detail','repair_openclaw_windows_lkg','reconcile_maintenance_cron_backoff',
        'diagnose_main_tool_policy','ensure_ui_bridge_watchdog','refresh_full_autonomy_assessment',
        'sync_local_desired_state_v19','retire_legacy_night_forge'
    )
    if($allowed-notcontains[string]$m.operation){return $false}
    if(-not$m.expires_at){return $false}
    try{$expiry=[DateTimeOffset]::Parse([string]$m.expires_at)}catch{return $false}
    $ManifestId.Value=[string]$m.id
    $ExpiresAt.Value=$expiry.ToString('o')
    return ([DateTimeOffset]::Now -gt $expiry)
}
function Ensure-Parent{
    if((Get-Sha $ParentCache)-eq$ExpectedParentSha){return}
    $text=Get-RepoText $ParentRepoPath
    if(-not$text){throw 'exact parent maintenance source unavailable'}
    $tmp=$ParentCache+'.stage-'+[guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,$text,$Utf8)
    $sha=Get-Sha $tmp
    if($sha-ne$ExpectedParentSha){Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue;throw('exact parent maintenance source hash mismatch actual='+$sha)}
    Move-Item -LiteralPath $tmp -Destination $ParentCache -Force
    if((Get-Sha $ParentCache)-ne$ExpectedParentSha){throw 'parent cache postcondition mismatch'}
}
function Invoke-Parent{
    Ensure-Parent
    $ps=(Get-Command powershell.exe -ErrorAction Stop).Source
    $args=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$ParentCache)
    if($ApplyOnce){$args+=,'-ApplyOnce'}
    $old=$ErrorActionPreference
    try{
        $ErrorActionPreference='Continue'
        & $ps @args
        $code=[int]$LASTEXITCODE
    }finally{$ErrorActionPreference=$old}
    return $code
}
function Invoke-SelfTest{
    if($ExpectedParentSha-notmatch'^[A-F0-9]{64}$'){throw 'parent pin invalid'}
    if($ParentRepoPath-ne'control-plane/maintenance/kevin-maintenance-runner-v1.3.50.ps1'){throw 'parent path widened'}
    if($ManifestRepoPath-ne'inbox/maintenance/manifest.json'){throw 'manifest path widened'}
    $id='';$exp=''
    $expired=@{
        schema=3;kind='kevin-self-maintenance-manifest';id='selftest-expired-001';
        authority_class='GREEN';authority_delta='NONE';production_effect='NONE';
        owner_policy='Kevin Owner Authorization v1';preauthorized=$true;
        operation='reconcile_maintenance_cron_backoff';
        expires_at=(Get-Date).AddMinutes(-5).ToString('o')
    }|ConvertTo-Json -Compress
    if(-not(Test-IsCanonicalExpired $expired ([ref]$id) ([ref]$exp))){throw 'expired canonical manifest not classified'}
    if($id-ne'selftest-expired-001'){throw 'expired manifest identity mismatch'}
    $fresh=$expired|ConvertFrom-Json;$fresh.expires_at=(Get-Date).AddMinutes(5).ToString('o');$id='';$exp=''
    if(Test-IsCanonicalExpired ($fresh|ConvertTo-Json -Compress) ([ref]$id) ([ref]$exp)){throw 'fresh manifest classified expired'}
    $bad=$fresh|ConvertFrom-Json;$bad.expires_at='not-a-time';$id='';$exp=''
    if(Test-IsCanonicalExpired ($bad|ConvertTo-Json -Compress) ([ref]$id) ([ref]$exp)){throw 'malformed expiry clean-idled instead of delegated hard validation'}
    $bad=$fresh|ConvertFrom-Json;$bad.authority_class='RED';$bad.expires_at=(Get-Date).AddMinutes(-5).ToString('o');$id='';$exp=''
    if(Test-IsCanonicalExpired ($bad|ConvertTo-Json -Compress) ([ref]$id) ([ref]$exp)){throw 'invalid authority clean-idled instead of delegated hard validation'}
    Write-Host 'KEVIN MAINTENANCE v1.3.3 SELFTEST PASS compatibility=v1.3.51'
    Write-Host 'KEVIN MAINTENANCE v1.3.51 SELFTEST PASS expired_manifest=clean_idle stale_execution=false parent=v1.3.50_exact delegation=fail_closed authority_expansion=false arbitrary_shell=false'
}

if($SelfTest){Invoke-SelfTest;exit 0}

try{
    $manifestText=Get-ManifestText
    $manifestId='';$expires=''
    if(Test-IsCanonicalExpired $manifestText ([ref]$manifestId) ([ref]$expires)){
        Save-State 'EXPIRED_IDLE' $manifestId 'Expired canonical manifest refused without scheduler failure.' @{
            expires_at=$expires
            execution_attempted=$false
            authority_effect='NONE'
            parent_invoked=$false
        }
        Write-Host ('MAINTENANCE EXPIRED_IDLE id='+$manifestId)
        exit 0
    }
    $code=Invoke-Parent
    exit $code
}catch{
    Save-State 'ERROR' '' $_.Exception.Message @{authority_effect='NONE';wrapper='1.3.51'}
    Write-Host ('MAINTENANCE ERROR '+(Safe-Text $_.Exception.Message 600))
    exit 1
}
