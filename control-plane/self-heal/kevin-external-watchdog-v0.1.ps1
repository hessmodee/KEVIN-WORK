param([switch]$SelfTest)

$ErrorActionPreference='Stop'
$Utf8=New-Object System.Text.UTF8Encoding($false)
$Workspace=if($env:KEVIN_WATCHDOG_TEST_ROOT){$env:KEVIN_WATCHDOG_TEST_ROOT}else{Join-Path $env:USERPROFILE '.openclaw\workspace'}
$Reports=Join-Path $Workspace 'reports'
$Root=Join-Path $Reports 'self-heal-watchdog'
$StatePath=Join-Path $Root 'state.json'
$LatestPath=Join-Path $Root 'latest.json'
$UiHeartbeat=Join-Path $Reports 'action-era\ui-bridge\heartbeat.json'
$UiTaskName='Kevin UI Bridge v0.3'
$MaintenanceKey='kevin-maintenance-intake-v1'
$MaxAttempts=3
$WindowMinutes=15
$MaintenanceStaleFactor=2.5
$UiHeartbeatStaleSeconds=30
New-Item -ItemType Directory -Force -Path $Root|Out-Null

function Write-JsonAtomic([string]$Path,[object]$Object){
    $tmp=$Path+'.tmp-'+$PID+'-'+[guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 20),$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Read-JsonSafe([string]$Path){
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return $null}
    try{return Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json}catch{return $null}
}
function Load-State{
    $s=Read-JsonSafe $StatePath
    if($s){return $s}
    return [pscustomobject]@{schema=1;families=@()}
}
function Save-State($s){Write-JsonAtomic $StatePath $s}
function Get-Family($s,[string]$Name){
    $h=@($s.families|Where-Object{[string]$_.name -eq $Name})
    if($h.Count -gt 1){throw 'duplicate watchdog family state'}
    if($h.Count -eq 1){return $h[0]}
    $n=[pscustomobject]@{name=$Name;attempts=@();cooled=$false;last_evidence=''}
    $s.families=@($s.families)+@($n)
    return $n
}
function Prune-Attempts($f){
    $cut=(Get-Date).AddMinutes(-$WindowMinutes)
    $f.attempts=@($f.attempts|Where-Object{try{[datetime]$_ -ge $cut}catch{$false}})
    if($f.attempts.Count -lt $MaxAttempts){$f.cooled=$false}
}
function Can-Attempt($s,[string]$Family,[string]$Evidence){
    $f=Get-Family $s $Family
    Prune-Attempts $f
    if([string]$f.last_evidence -ne $Evidence){$f.attempts=@();$f.cooled=$false;$f.last_evidence=$Evidence}
    if($f.attempts.Count -ge $MaxAttempts){$f.cooled=$true;return $false}
    return $true
}
function Record-Attempt($s,[string]$Family,[string]$Evidence){
    $f=Get-Family $s $Family
    Prune-Attempts $f
    $f.last_evidence=$Evidence
    $f.attempts=@($f.attempts)+@((Get-Date).ToString('o'))
    if($f.attempts.Count -ge $MaxAttempts){$f.cooled=$true}
    Save-State $s
}
function Invoke-OpenClaw([string[]]$Arguments,[int]$TimeoutSeconds=90){
    $node=(Get-Command node.exe -ErrorAction Stop).Source
    $js=Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if(-not(Test-Path -LiteralPath $js -PathType Leaf)){throw 'OpenClaw CLI entrypoint missing'}
    $psi=New-Object Diagnostics.ProcessStartInfo
    $psi.FileName=$node;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.CreateNoWindow=$true
    $psi.ArgumentList.Add($js)
    foreach($a in $Arguments){$psi.ArgumentList.Add([string]$a)}
    $p=New-Object Diagnostics.Process;$p.StartInfo=$psi
    [void]$p.Start();$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync()
    if(-not$p.WaitForExit($TimeoutSeconds*1000)){try{$p.Kill()}catch{};throw 'OpenClaw command timeout'}
    return [pscustomobject]@{ExitCode=$p.ExitCode;Stdout=$out.Result;Stderr=$err.Result}
}
function Get-Crons{
    $r=Invoke-OpenClaw @('cron','list','--all','--json') 60
    if($r.ExitCode -ne 0){throw 'cron list failed'}
    $o=$r.Stdout|ConvertFrom-Json
    if($o.jobs){return @($o.jobs)}
    if($o -is [array]){return @($o)}
    return @()
}
function Get-CronByKey($jobs,[string]$Key){
    $h=@($jobs|Where-Object{[string]$_.declarationKey -eq $Key})
    if($h.Count -ne 1){throw ('expected exactly one cron '+$Key)}
    return $h[0]
}
function Run-FixedMaintenance($job){
    $r=Invoke-OpenClaw @('cron','run',[string]$job.id,'--wait','--wait-timeout','3m','--poll-interval','1s') 240
    if($r.ExitCode -ne 0){throw 'fixed maintenance cron run failed'}
}
function Restart-GatewayFixed{
    $r=Invoke-OpenClaw @('gateway','restart') 90
    if($r.ExitCode -ne 0){throw 'fixed gateway restart failed'}
}
function Restart-UiBridgeFixed{
    if($env:OS -ne 'Windows_NT'){throw 'UI Bridge watchdog repair requires Windows'}
    $t=Get-ScheduledTask -TaskName $UiTaskName -ErrorAction SilentlyContinue
    if(-not$t){throw 'fixed UI Bridge task missing'}
    Start-ScheduledTask -TaskName $UiTaskName
}
function Ui-Evidence{
    $h=Read-JsonSafe $UiHeartbeat
    if(-not$h){return [pscustomobject]@{stale=$true;evidence='heartbeat-missing'}}
    try{$at=[datetime]$h.at}catch{return [pscustomobject]@{stale=$true;evidence='heartbeat-invalid'}}
    $age=((Get-Date)-$at).TotalSeconds
    return [pscustomobject]@{stale=($age -gt $UiHeartbeatStaleSeconds);evidence=('heartbeat-age-'+[math]::Floor($age))}
}
function Publish([string]$Status,[object]$Actions,[string]$Detail=''){
    Write-JsonAtomic $LatestPath ([ordered]@{schema=1;kind='kevin-external-watchdog-state';version='0.1';at=(Get-Date).ToString('o');status=$Status;actions=@($Actions);detail=$Detail;authority=[ordered]@{arbitrary_shell=$false;caller_commands=$false;caller_paths=$false;permission_changes=$false}})
}
function Self-Test{
    $s=[pscustomobject]@{schema=1;families=@()}
    if(-not(Can-Attempt $s 'gateway' 'a')){throw 'fresh family should be eligible'}
    1..3|ForEach-Object{Record-Attempt $s 'gateway' 'a'}
    if(Can-Attempt $s 'gateway' 'a'){throw 'three-attempt circuit breaker failed'}
    if(-not(Can-Attempt $s 'gateway' 'b')){throw 'new evidence should reset family'}
    if($UiTaskName -ne 'Kevin UI Bridge v0.3'){throw 'UI task pin changed'}
    if($MaintenanceKey -ne 'kevin-maintenance-intake-v1'){throw 'maintenance key pin changed'}
    Write-Host 'KEVIN EXTERNAL WATCHDOG v0.1 SELFTEST PASS fixed_actions=3 max_attempts=3 arbitrary_shell=false caller_commands=false'
}
if($SelfTest){Self-Test;exit 0}

$state=Load-State;$actions=@()
try{
    $jobs=$null
    try{$jobs=Get-Crons}catch{
        $ev='cron-list-unreachable'
        if(Can-Attempt $state 'gateway' $ev){Record-Attempt $state 'gateway' $ev;Restart-GatewayFixed;$actions+='restart_gateway_fixed'}else{$actions+='gateway_cooled'}
        Publish 'RECOVERY_ATTEMPTED' $actions 'Gateway/cron control path was unavailable.'
        exit 0
    }

    $maint=Get-CronByKey $jobs $MaintenanceKey
    $nowMs=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $lastMs=if($maint.state.lastRunAtMs){[int64]$maint.state.lastRunAtMs}elseif($maint.lastRunAtMs){[int64]$maint.lastRunAtMs}else{0}
    $everyMs=if($maint.schedule.everyMs){[int64]$maint.schedule.everyMs}elseif($maint.everyMs){[int64]$maint.everyMs}else{300000}
    if($lastMs -le 0 -or ($nowMs-$lastMs) -gt ($everyMs*$MaintenanceStaleFactor)){
        $ev='maintenance-stale-'+$lastMs
        if(Can-Attempt $state 'maintenance' $ev){Record-Attempt $state 'maintenance' $ev;Run-FixedMaintenance $maint;$actions+='run_fixed_maintenance_intake'}else{$actions+='maintenance_cooled'}
    }

    $ui=Ui-Evidence
    if($ui.stale){
        if(Can-Attempt $state 'ui_bridge' $ui.evidence){Record-Attempt $state 'ui_bridge' $ui.evidence;Restart-UiBridgeFixed;$actions+='restart_ui_bridge_fixed'}else{$actions+='ui_bridge_cooled'}
    }

    Publish $(if($actions.Count){'RECOVERY_ATTEMPTED'}else{'HEALTHY'}) $actions
    exit 0
}catch{
    Publish 'ERROR' $actions $_.Exception.Message
    Write-Host ('WATCHDOG ERROR '+$_.Exception.Message)
    exit 1
}
