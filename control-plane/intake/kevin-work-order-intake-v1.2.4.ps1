param(
    [ValidateSet('Poll','SelfTest')]
    [string]$Mode='Poll'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$Utf8=New-Object System.Text.UTF8Encoding($false)

$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Control=Join-Path $Workspace 'ControlPlane'
$Reports=Join-Path $Workspace 'reports'
if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$StateDir=Join-Path $Control 'State'
if(-not(Test-Path -LiteralPath $StateDir)){New-Item -ItemType Directory -Path $StateDir -Force|Out-Null}
$LedgerPath=Join-Path $StateDir 'work-order-ledger-v1.json'
$CatalogPath=Join-Path $Control 'mission-catalog-v1.json'
$DispatcherPath=Join-Path $Control 'kevin-mission-dispatcher-v0.1.ps1'
$ActuatorPath=Join-Path $Control 'kevin-autonomy-actuator-v0.1.ps1'
$BridgePath=Join-Path $Control 'kevin-autonomy-bridge-v0.1.ps1'
$MaintenancePath=Join-Path $Workspace 'kevin-maintenance-runner.ps1'
$OsObserverPath=Join-Path $Workspace 'kevin-os-observer.ps1'
$OsPublicPath=Join-Path $Reports 'os-awareness\latest-public.json'
$SupportPath=Join-Path $Reports 'support-latest.json'
$Repo='hessmodee/KEVIN-WORK'
$OrderBranch='kevin-control-plane-v1'
$OrderPath='control-plane/orders/CURRENT.json'
$AckBranch='main'
$AckPath='reports/control-plane-latest.json'

function Write-JsonAtomic {
    param($Object,[string]$Path)
    $tmp=$Path+'.tmp-'+$PID
    [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Read-JsonFile([string]$Path){if(-not(Test-Path -LiteralPath $Path)){return $null};try{return Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json}catch{return $null}}
function Get-PropertyValue($Object,[string]$Name){if($null-eq$Object){return $null};$p=$Object.PSObject.Properties[$Name];if($null-eq$p){return $null};return $p.Value}
function One-Line([AllowEmptyString()][string]$Text){if($null-eq$Text){return ''};$s=($Text-replace'[\r\n]+',' ').Trim();if($s.Length-gt900){$s=$s.Substring(0,900)};return $s}

function ConvertTo-Win32CommandLineArg {
    param([AllowEmptyString()][string]$Value)
    if($null-eq$Value -or $Value.Length-eq0){return '""'}
    if($Value-notmatch'[\s"]'){return $Value}
    $sb=New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $slashes=0
    for($i=0;$i-lt$Value.Length;$i++){
        $ch=$Value[$i]
        if($ch-eq'\'){$slashes++;continue}
        if($ch-eq'"'){
            if($slashes-gt0){[void]$sb.Append(('\'*($slashes*2)))}
            [void]$sb.Append('\"');$slashes=0;continue
        }
        if($slashes-gt0){[void]$sb.Append(('\'*$slashes));$slashes=0}
        [void]$sb.Append($ch)
    }
    if($slashes-gt0){[void]$sb.Append(('\'*($slashes*2)))}
    [void]$sb.Append('"')
    return $sb.ToString()
}
function Invoke-ExactNative {
    param([string]$Executable,[string[]]$Argv,[int]$TimeoutSeconds=0,[string]$WorkingDirectory='')
    $psi=New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName=$Executable
    $psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)})-join' ')
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory}
    $p=New-Object System.Diagnostics.Process;$p.StartInfo=$psi
    if(-not$p.Start()){throw 'Could not start fixed executable'}
    $ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();$timed=$false
    if($TimeoutSeconds-gt0){if(-not$p.WaitForExit($TimeoutSeconds*1000)){$timed=$true;try{$p.Kill()}catch{};$p.WaitForExit()}}else{$p.WaitForExit()}
    $r=[pscustomobject]@{ExitCode=$(if($timed){124}else{[int]$p.ExitCode});Stdout=[string]$ot.Result;Stderr=[string]$et.Result;TimedOut=$timed}
    $p.Dispose();return $r
}
function Resolve-Gh {$g=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not$g){$g=Get-Command gh -ErrorAction SilentlyContinue};if(-not$g){throw 'GitHub CLI missing'};return $g.Source}
function Invoke-Gh {param([string[]]$Argv);Remove-Item Env:GH_TOKEN,Env:GITHUB_TOKEN -ErrorAction SilentlyContinue;$env:GH_PROMPT_DISABLED='1';return Invoke-ExactNative (Resolve-Gh) $Argv 90 $Workspace}
function Get-RemoteJson([string]$Path,[string]$Branch){$endpoint='repos/'+$Repo+'/contents/'+$Path+'?ref='+[Uri]::EscapeDataString($Branch);$r=Invoke-Gh @('api',$endpoint,'-H','Accept: application/vnd.github+json');if($r.ExitCode-ne0){$all=One-Line ($r.Stdout+' '+$r.Stderr);if($all-match'404|Not Found'){return $null};throw('GitHub GET failed: '+$all)};$meta=$r.Stdout|ConvertFrom-Json;$txt=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$meta.content-replace'\s','')));return [pscustomobject]@{meta=$meta;data=($txt|ConvertFrom-Json)}}
function Publish-Ack($Ack){
    $existing=Get-RemoteJson $AckPath $AckBranch
    if($existing){
        $prev=$existing.data
        $prevId=if($prev.request){[string]$prev.request.id}else{''}
        $nextId=if($Ack.request){[string]$Ack.request.id}else{''}
        if($prevId-eq$nextId -and [string]$prev.status-eq[string]$Ack.status -and [string]$prev.detail-eq[string]$Ack.detail){return $false}
    }
    $payload=$Ack|ConvertTo-Json -Depth 20
    $body=[ordered]@{message='kevin control plane telemetry';content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload));branch=$AckBranch}
    if($existing){$body.sha=[string]$existing.meta.sha}
    $tmp=Join-Path $env:TEMP ('kevin-wo-ack-'+[guid]::NewGuid().ToString('N')+'.json')
    try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$r=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$AckPath),'--input',$tmp,'-H','Accept: application/vnd.github+json');if($r.ExitCode-ne0){throw 'Ack publish failed'}}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
    return $true
}
function Get-Ledger {
    $l=Read-JsonFile $LedgerPath
    if($l){return $l}
    $emptyProcessed=New-Object System.Collections.ArrayList
    return [pscustomobject]@{schema=1;processed=$emptyProcessed;updated_at=(Get-Date).ToString('o')}
}
function Save-Ledger($l){$l.processed=@($l.processed|Select-Object -Last 100);$l.updated_at=(Get-Date).ToString('o');Write-JsonAtomic $l $LedgerPath}

function Validate-Order($o){
    if($null-eq$o){throw 'Work order was null.'}
    $allowed=@('schema','kind','id','idempotency_key','created_at','expires_at','authority_class','verb','target','reason')
    foreach($p in $o.PSObject.Properties.Name){if($allowed-notcontains[string]$p){throw('Unknown work-order property: '+$p)}}
    foreach($n in @('schema','kind','id','idempotency_key','created_at','expires_at','authority_class','verb','target')){if($null-eq(Get-PropertyValue $o $n)){throw('Missing required property: '+$n)}}
    if([int]$o.schema-ne1 -or [string]$o.kind-ne'kevin-work-order' -or [string]$o.authority_class-ne'GREEN'){throw 'Work-order schema/kind/authority mismatch.'}
    if([string]$o.id-notmatch'^[A-Za-z0-9._-]{8,80}$' -or [string]$o.idempotency_key-notmatch'^[A-Za-z0-9._-]{8,120}$'){throw 'Work-order identity invalid.'}
    $created=[DateTimeOffset]::Parse([string]$o.created_at);$expires=[DateTimeOffset]::Parse([string]$o.expires_at);$now=[DateTimeOffset]::Now
    if($expires-le$now){throw 'Work order is expired.'};if($created-gt$now.AddMinutes(10)){throw 'created_at too far in future.'};if(($expires-$created).TotalHours-gt24){throw 'validity exceeds 24 hours.'}
    $verbs=@('dispatch_mission','run_reconcile','run_benchmark','run_support_bridge','refresh_autonomy_telemetry','run_typed_maintenance','run_os_awareness')
    if($verbs-notcontains[string]$o.verb){throw('Verb is not GREEN allowlisted: '+[string]$o.verb)}
    switch([string]$o.verb){
        'dispatch_mission'{$c=Read-JsonFile $CatalogPath;if(-not$c -or @($c.missions|Where-Object{[string]$_.id-eq[string]$o.target}).Count-ne1){throw 'Mission target is not local-catalogued.'}}
        'run_reconcile'{if([string]$o.target-ne'autonomy'){throw 'run_reconcile target mismatch.'}}
        'run_benchmark'{if([string]$o.target-ne'kevin-benchmark-v1'){throw 'run_benchmark target mismatch.'}}
        'run_support_bridge'{if([string]$o.target-ne'kevin-support-bridge-v1'){throw 'run_support_bridge target mismatch.'}}
        'refresh_autonomy_telemetry'{if([string]$o.target-ne'autonomy-telemetry'){throw 'refresh target mismatch.'}}
        'run_typed_maintenance'{if([string]$o.target-ne'kevin-maintenance-v1'){throw 'maintenance target mismatch.'}}
        'run_os_awareness'{if([string]$o.target-ne'kevin-os-awareness-v1'){throw 'OS awareness target mismatch.'}}
    }
}
function Get-OpenClawRuntime {$n=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not$n){$n=Get-Command node -ErrorAction SilentlyContinue};if(-not$n){throw 'node missing'};$cli=Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js';if(-not(Test-Path $cli)){throw 'OpenClaw runtime missing'};return [pscustomobject]@{node=$n.Source;cli=$cli}}
function Invoke-OclJson([string[]]$Argv){$o=Get-OpenClawRuntime;$r=Invoke-ExactNative $o.node (@($o.cli)+@($Argv)) 540 $Workspace;if($r.ExitCode-ne0){throw('OpenClaw failed: '+(One-Line ($r.Stdout+' '+$r.Stderr)))};if([string]::IsNullOrWhiteSpace($r.Stdout)){return $null};return $r.Stdout|ConvertFrom-Json}
function Get-JobId([string]$Key){$s=Read-JsonFile $SupportPath;$matches=@($s.cron.jobs|Where-Object{[string]$_.declaration_key-eq$Key});if($matches.Count-ne1){throw('Support job mismatch: '+$Key)};return [string]$matches[0].id}
function Run-CronVerified([string]$Key,[int]$Minutes){$id=Get-JobId $Key;$null=Invoke-OclJson @('cron','run',$id,'--wait','--wait-timeout',($Minutes.ToString()+'m'),'--poll-interval','2s');$hist=Invoke-OclJson @('cron','runs','--id',$id,'--limit','3');$entries=@();if($hist.entries){$entries=@($hist.entries)}elseif($hist.runs){$entries=@($hist.runs)};if(@($entries|Where-Object{[string]$_.status-eq'ok' -or [string]$_.completionStatus-eq'succeeded'}).Count-lt1){throw 'Cron terminal success not verified.'};return('verified job='+$id)}
function Invoke-FixedPowerShell([string]$Path,[string[]]$Args=@(),[int]$Timeout=600){$r=Invoke-ExactNative 'powershell.exe' (@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Path)+@($Args)) $Timeout $Workspace;if($r.ExitCode-ne0){throw('Fixed local action failed: '+(One-Line ($r.Stdout+' '+$r.Stderr)))};return One-Line $r.Stdout}
function Invoke-OsAwarenessSnapshot {
    $started=[DateTimeOffset]::Now
    $out=Invoke-FixedPowerShell $OsObserverPath @('-Operation','snapshot') 240
    if(-not(Test-Path -LiteralPath $OsPublicPath -PathType Leaf)){throw 'OS awareness public summary missing'}
    $p=Get-Content -LiteralPath $OsPublicPath -Raw|ConvertFrom-Json
    if([string]$p.kind-ne'kevin-os-awareness-public-summary' -or [string]$p.operation-ne'snapshot' -or -not[bool]$p.read_only){throw 'OS awareness public summary invariant failed'}
    $at=[DateTimeOffset]::Parse([string]$p.generated_at)
    if($at-lt$started.AddSeconds(-3)){throw 'OS awareness evidence not fresh'}
    return ('OS_AWARENESS_PROVEN generated_at='+[string]$p.generated_at+' memory_bytes='+[string]$p.hardware_summary.total_physical_memory_bytes+' cpu_count='+[string]$p.hardware_summary.cpu_count+' gpu_count='+[string]$p.hardware_summary.gpu_count+' memory_modules='+[string]$p.hardware_summary.memory_module_count+' processes='+[string]$p.counts.processes+' services='+[string]$p.counts.services+' tasks='+[string]$p.counts.scheduled_tasks+' software='+[string]$p.counts.installed_software+' system_errors_24h='+[string]$p.counts.system_critical_or_error_24h+' application_errors_24h='+[string]$p.counts.application_critical_or_error_24h+' runner='+$out)
}
function Execute-Order($o){switch([string]$o.verb){'dispatch_mission'{return Invoke-FixedPowerShell $DispatcherPath @('-Mode','Dispatch','-RequestedMission',[string]$o.target) 560}'run_reconcile'{return Invoke-FixedPowerShell $ActuatorPath @('-Mode','Reconcile') 600}'run_benchmark'{return Run-CronVerified 'kevin-benchmark-v1' 9}'run_support_bridge'{return Run-CronVerified 'kevin-support-bridge-v1' 5}'refresh_autonomy_telemetry'{$env:KEVIN_GH_AUTH_MODE='stored';return Invoke-FixedPowerShell $BridgePath @() 180}'run_typed_maintenance'{return Invoke-FixedPowerShell $MaintenancePath @('-CheckOnly') 600}'run_os_awareness'{return Invoke-OsAwarenessSnapshot}};throw 'No executor for work-order verb.'}

function Invoke-SelfTest {
    $good=[pscustomobject]@{schema=1;kind='kevin-work-order';id='selftest-maint-01';idempotency_key='selftest-maintenance-once';created_at=(Get-Date).AddMinutes(-1).ToString('o');expires_at=(Get-Date).AddMinutes(10).ToString('o');authority_class='GREEN';verb='run_typed_maintenance';target='kevin-maintenance-v1';reason='selftest'}
    Validate-Order $good
    $os=$good|ConvertTo-Json|ConvertFrom-Json;$os.id='selftest-os-001';$os.idempotency_key='selftest-os-awareness';$os.verb='run_os_awareness';$os.target='kevin-os-awareness-v1';Validate-Order $os
    $bad=$os|ConvertTo-Json|ConvertFrom-Json;$bad.target='arbitrary';$blocked=$false;try{Validate-Order $bad}catch{$blocked=$true};if(-not$blocked){throw 'arbitrary OS awareness target accepted'}
    $bad=$good|ConvertTo-Json|ConvertFrom-Json;$bad|Add-Member command 'whoami';$blocked=$false;try{Validate-Order $bad}catch{$blocked=$true};if(-not$blocked){throw 'command injection accepted'}
    $bad=$good|ConvertTo-Json|ConvertFrom-Json;$bad.target='arbitrary';$blocked=$false;try{Validate-Order $bad}catch{$blocked=$true};if(-not$blocked){throw 'arbitrary target accepted'}
    if((ConvertTo-Win32CommandLineArg 'a b')-ne'"a b"'){throw 'Win32 argv quote selftest failed'}
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS compatibility=v1.2.4'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.3 SELFTEST PASS compatibility=v1.2.4'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.4 SELFTEST PASS verbs=7 stale_order_retirement=true terminal_idle=true semantic_ack_dedupe=true os_awareness_snapshot=fixed maintenance_target=fixed arbitrary_shell=false caller_argv=false caller_path=false'
}
if($Mode-eq'SelfTest'){Invoke-SelfTest;exit 0}

$ack=[ordered]@{schema=1;kind='kevin-control-plane-ack';generated_at=(Get-Date).ToString('o');request=$null;status='NO_ORDER';detail='';safety=[ordered]@{green_only=$true;arbitrary_shell=$false;authority_expansion=$false}}
try{
    $remote=Get-RemoteJson $OrderPath $OrderBranch
    if(-not$remote){$ack.status='IDLE_NO_ORDER';$ack.detail='No current work order; awaiting next bounded GREEN order';Publish-Ack $ack|Out-Null;exit 0}
    $o=$remote.data;$ack.request=[ordered]@{id=[string]$o.id;verb=[string]$o.verb;target=[string]$o.target}
    $ledger=Get-Ledger
    $prior=@($ledger.processed|Where-Object{[string]$_.idempotency_key-eq[string]$o.idempotency_key})
    if($prior.Count){$ack.status='IDLE_TERMINAL';$ack.detail='Current work order is already terminal; awaiting replacement';Publish-Ack $ack|Out-Null;exit 0}
    try{Validate-Order $o}catch{
        $reason=[string]$_.Exception.Message
        $safeId=([string]$o.id -match '^[A-Za-z0-9._-]{8,80}$')
        $safeKey=([string]$o.idempotency_key -match '^[A-Za-z0-9._-]{8,120}$')
        if($reason-eq'Work order is expired.' -and $safeId -and $safeKey){
            $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=[string]$o.id;idempotency_key=[string]$o.idempotency_key;at=(Get-Date).ToString('o');status='EXPIRED_RETIRED'})
            Save-Ledger $ledger
            $ack.status='STALE_RETIRED';$ack.detail='Expired work order retired; awaiting replacement';Publish-Ack $ack|Out-Null;exit 0
        }
        throw
    }
    $result=Execute-Order $o
    $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=[string]$o.id;idempotency_key=[string]$o.idempotency_key;at=(Get-Date).ToString('o');status='SUCCESS'})
    Save-Ledger $ledger
    $ack.status='SUCCESS';$ack.detail=One-Line $result;Publish-Ack $ack|Out-Null;exit 0
}catch{$ack.status='FAILED';$ack.detail=One-Line $_.Exception.Message;try{Publish-Ack $ack|Out-Null}catch{};exit 1}
