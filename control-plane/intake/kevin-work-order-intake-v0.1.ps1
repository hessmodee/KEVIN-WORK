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
$Reports=Join-Path $Workspace 'reports';if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$StateDir=Join-Path $Control 'State';if(-not(Test-Path -LiteralPath $StateDir)){New-Item -ItemType Directory -Path $StateDir -Force|Out-Null}
$LedgerPath=Join-Path $StateDir 'work-order-ledger-v1.json'
$LatestPath=Join-Path $Reports 'work-order-latest.json'
$CatalogPath=Join-Path $Control 'mission-catalog-v1.json'
$DispatcherPath=Join-Path $Control 'kevin-mission-dispatcher-v0.1.ps1'
$ActuatorPath=Join-Path $Control 'kevin-autonomy-actuator-v0.1.ps1'
$BridgePath=Join-Path $Control 'kevin-autonomy-bridge-v0.1.ps1'
$SupportPath=Join-Path $Reports 'support-latest.json'
$Repo='hessmodee/KEVIN-WORK';$OrderBranch='kevin-control-plane-v1';$OrderPath='control-plane/orders/CURRENT.json';$AckBranch='main';$AckPath='reports/control-plane-latest.json'

function Write-JsonAtomic {param([Parameter(Mandatory=$true)]$Object,[Parameter(Mandatory=$true)][string]$Path);$tmp="$Path.tmp-$PID";[IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),$Utf8);Move-Item -LiteralPath $tmp -Destination $Path -Force}
function Read-JsonFile([string]$Path){if(-not(Test-Path -LiteralPath $Path)){return $null};try{return (Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)}catch{return $null}}
function Get-OptionalPropertyValue($Object,[string]$Name){if($null -eq $Object){return $null};$p=$Object.PSObject.Properties[$Name];if($null -eq $p){return $null};return $p.Value}
function One-Line([AllowEmptyString()][string]$Text){if($null -eq $Text){return ''};$s=($Text -replace '[\r\n]+',' ').Trim();if($s.Length -gt 900){$s=$s.Substring(0,900)};return $s}

function ConvertTo-Win32CommandLineArg {param([AllowEmptyString()][string]$Value);if($null -eq $Value -or $Value.Length -eq 0){return '""'};if($Value -notmatch '[\s"]'){return $Value};$sb=New-Object System.Text.StringBuilder;[void]$sb.Append('"');$slashes=0;for($i=0;$i -lt $Value.Length;$i++){$ch=$Value[$i];if($ch -eq '\'){$slashes++;continue};if($ch -eq '"'){if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))};[void]$sb.Append('\"');$slashes=0;continue};if($slashes -gt 0){[void]$sb.Append(('\' * $slashes));$slashes=0};[void]$sb.Append($ch)};if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))};[void]$sb.Append('"');return $sb.ToString()}
function Invoke-ExactNative {param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string[]]$Argv,[int]$TimeoutSeconds=0,[string]$WorkingDirectory='');$psi=New-Object System.Diagnostics.ProcessStartInfo;$psi.FileName=$Executable;$psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ');$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory};$p=New-Object System.Diagnostics.Process;$p.StartInfo=$psi;if(-not $p.Start()){throw "Could not start $Executable"};$ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();$to=$false;if($TimeoutSeconds -gt 0){if(-not $p.WaitForExit($TimeoutSeconds*1000)){$to=$true;try{$p.Kill()}catch{};$p.WaitForExit()}}else{$p.WaitForExit()};$r=[pscustomobject]@{ExitCode=$(if($to){124}else{[int]$p.ExitCode});Stdout=[string]$ot.Result;Stderr=[string]$et.Result;TimedOut=$to};$p.Dispose();return $r}

function Resolve-Gh {$p=$env:KEVIN_GH_EXE;if($p -and (Test-Path -LiteralPath ([string]$p))){return [string]$p};$g=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not $g){$g=Get-Command gh -ErrorAction SilentlyContinue};if(-not $g){throw 'GitHub CLI not found.'};return $g.Source}
function Use-StoredGhCredential {foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath ("Env:{0}" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}
$script:GhExe=$null
function Invoke-Gh {param([Parameter(Mandatory=$true)][string[]]$Argv);if(-not $script:GhExe){Use-StoredGhCredential;$script:GhExe=Resolve-Gh};return Invoke-ExactNative -Executable $script:GhExe -Argv $Argv -TimeoutSeconds 90 -WorkingDirectory $Workspace}

function Get-RemoteJson([string]$Path,[string]$Branch){$endpoint=("repos/{0}/contents/{1}?ref={2}" -f $Repo,$Path,[Uri]::EscapeDataString($Branch));$r=Invoke-Gh -Argv @('api',$endpoint,'-H','Accept: application/vnd.github+json');if($r.ExitCode -ne 0){$all=One-Line ($r.Stdout+' '+$r.Stderr);if($all -match '404|Not Found'){return $null};throw "GitHub GET failed: $all"};$meta=$r.Stdout|ConvertFrom-Json;$txt=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$meta.content -replace '\s','')));return [pscustomobject]@{meta=$meta;data=($txt|ConvertFrom-Json)}}

function Publish-Ack($Ack){
  $endpoint=("repos/{0}/contents/{1}" -f $Repo,$AckPath);$existing=Get-RemoteJson $AckPath $AckBranch
  $payload=$Ack|ConvertTo-Json -Depth 20;$body=[ordered]@{message='kevin control plane telemetry';content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload));branch=$AckBranch};if($existing -and (Get-OptionalPropertyValue $existing.meta 'sha')){$body.sha=[string](Get-OptionalPropertyValue $existing.meta 'sha')}
  $tmp=Join-Path $env:TEMP ("kevin-wo-ack-{0}.json" -f [guid]::NewGuid().ToString('N'));try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$r=Invoke-Gh -Argv @('api','--method','PUT',$endpoint,'--input',$tmp,'-H','Accept: application/vnd.github+json');if($r.ExitCode -ne 0){throw "Ack publish failed: $(One-Line ($r.Stdout+' '+$r.Stderr))"}}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
}

function Get-Ledger {$l=Read-JsonFile $LedgerPath;if($l){return $l};return [pscustomobject]@{schema=1;processed=@();updated_at=(Get-Date).ToString('o')}}
function Save-Ledger($l){$items=@($l.processed);if($items.Count -gt 100){$items=@($items|Select-Object -Last 100)};$l.processed=$items;$l.updated_at=(Get-Date).ToString('o');Write-JsonAtomic $l $LedgerPath}
function Is-Replay($Ledger,[string]$Key){return @($Ledger.processed|Where-Object{[string]$_.idempotency_key -eq $Key}).Count -gt 0}

function Validate-Order($o){
  if($null -eq $o){throw 'Work order was null.'}
  $allowed=@('schema','kind','id','idempotency_key','created_at','expires_at','authority_class','verb','target','reason');foreach($p in $o.PSObject.Properties.Name){if($allowed -notcontains [string]$p){throw "Unknown work-order property: $p"}}
  foreach($n in @('schema','kind','id','idempotency_key','created_at','expires_at','authority_class','verb','target')){if($null -eq (Get-OptionalPropertyValue $o $n)){throw "Missing required property: $n"}}
  $schema=Get-OptionalPropertyValue $o 'schema';$kind=Get-OptionalPropertyValue $o 'kind';$authority=Get-OptionalPropertyValue $o 'authority_class';$id=Get-OptionalPropertyValue $o 'id';$idem=Get-OptionalPropertyValue $o 'idempotency_key';$createdRaw=Get-OptionalPropertyValue $o 'created_at';$expiresRaw=Get-OptionalPropertyValue $o 'expires_at';$verb=Get-OptionalPropertyValue $o 'verb';$target=[string](Get-OptionalPropertyValue $o 'target')
  if([int]$schema -ne 1 -or [string]$kind -ne 'kevin-work-order' -or [string]$authority -ne 'GREEN'){throw 'Work-order schema/kind/authority_class mismatch.'}
  if([string]$id -notmatch '^[A-Za-z0-9._-]{8,80}$' -or [string]$idem -notmatch '^[A-Za-z0-9._-]{8,120}$'){throw 'Work-order id/idempotency format invalid.'}
  $created=[DateTimeOffset]::Parse([string]$createdRaw);$expires=[DateTimeOffset]::Parse([string]$expiresRaw);$now=[DateTimeOffset]::Now
  if($expires -le $now){throw 'Work order is expired.'};if($created -gt $now.AddMinutes(10)){throw 'Work order created_at is too far in the future.'};if(($expires-$created).TotalHours -gt 24){throw 'Work order validity exceeds 24 hours.'}
  $verbs=@('dispatch_mission','run_reconcile','run_benchmark','run_support_bridge','refresh_autonomy_telemetry');if($verbs -notcontains [string]$verb){throw "Verb is not GREEN allowlisted: $verb"}
  switch([string]$verb){
    'dispatch_mission' {$c=Read-JsonFile $CatalogPath;if(-not $c -or @($c.missions|Where-Object{[string]$_.id -eq $target}).Count -ne 1){throw "Mission target is not in local catalog: $target"}}
    'run_reconcile' {if($target -ne 'autonomy'){throw 'run_reconcile target must be autonomy.'}}
    'run_benchmark' {if($target -ne 'kevin-benchmark-v1'){throw 'run_benchmark target mismatch.'}}
    'run_support_bridge' {if($target -ne 'kevin-support-bridge-v1'){throw 'run_support_bridge target mismatch.'}}
    'refresh_autonomy_telemetry' {if($target -ne 'autonomy-telemetry'){throw 'refresh_autonomy_telemetry target mismatch.'}}
  }
}

function Get-OpenClawRuntime {$n=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $n){$n=Get-Command node -ErrorAction SilentlyContinue};if(-not $n){throw 'node missing'};$cli=Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js';if(-not(Test-Path -LiteralPath $cli)){throw 'OpenClaw runtime missing'};return [pscustomobject]@{node=$n.Source;cli=$cli}}
$script:Ocl=$null
function Invoke-OclJson {param([Parameter(Mandatory=$true)][string[]]$Argv);if(-not $script:Ocl){$script:Ocl=Get-OpenClawRuntime};$r=Invoke-ExactNative -Executable $script:Ocl.node -Argv (@($script:Ocl.cli)+@($Argv)) -TimeoutSeconds 540 -WorkingDirectory $Workspace;if($r.ExitCode -ne 0){throw "OpenClaw failed: $(One-Line ($r.Stdout+' '+$r.Stderr))"};if([string]::IsNullOrWhiteSpace($r.Stdout)){return $null};return ($r.Stdout|ConvertFrom-Json)}
function Get-SupportJobId([string]$DeclarationKey){$s=Read-JsonFile $SupportPath;if(-not $s -or -not (Get-OptionalPropertyValue $s 'cron')){throw 'Support snapshot missing.'};$cron=Get-OptionalPropertyValue $s 'cron';$jobs=Get-OptionalPropertyValue $cron 'jobs';$matches=@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'declaration_key') -eq $DeclarationKey});$j=$matches|Select-Object -First 1;if(-not $j){throw "Support job not found: $DeclarationKey"};return [string](Get-OptionalPropertyValue $j 'id')}
function Run-CronJobVerified([string]$Id,[int]$WaitMinutes){$null=Invoke-OclJson -Argv @('cron','run',$Id,'--wait','--wait-timeout',("{0}m" -f $WaitMinutes),'--poll-interval','2s');$hist=Invoke-OclJson -Argv @('cron','runs','--id',$Id,'--limit','3');$entries=@();if($hist){$e=Get-OptionalPropertyValue $hist 'entries';if($e){$entries=@($e)}else{$e=Get-OptionalPropertyValue $hist 'runs';if($e){$entries=@($e)}}};foreach($entry in $entries){$status=[string](Get-OptionalPropertyValue $entry 'status');$completion=[string](Get-OptionalPropertyValue $entry 'completionStatus');if($status -eq 'ok' -or $completion -eq 'succeeded'){return $true}};return $false}

function Execute-Order($o){
  $verb=[string](Get-OptionalPropertyValue $o 'verb');$target=[string](Get-OptionalPropertyValue $o 'target')
  switch($verb){
    'dispatch_mission' {$r=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$DispatcherPath,'-Mode','Dispatch','-RequestedMission',$target) -TimeoutSeconds 560 -WorkingDirectory $Workspace;if($r.ExitCode -ne 0){throw "Dispatcher failed: $(One-Line ($r.Stdout+' '+$r.Stderr))"};return (One-Line $r.Stdout)}
    'run_reconcile' {$r=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$ActuatorPath,'-Mode','Reconcile') -TimeoutSeconds 600 -WorkingDirectory $Workspace;if($r.ExitCode -ne 0){throw "Reconcile failed: $(One-Line ($r.Stdout+' '+$r.Stderr))"};return (One-Line $r.Stdout)}
    'run_benchmark' {$jobId=Get-SupportJobId 'kevin-benchmark-v1';if(-not(Run-CronJobVerified $jobId 9)){throw 'Benchmark cron run did not verify successful terminal history.'};return "benchmark verified job=$jobId"}
    'run_support_bridge' {$jobId=Get-SupportJobId 'kevin-support-bridge-v1';if(-not(Run-CronJobVerified $jobId 5)){throw 'Support Bridge cron run did not verify successful terminal history.'};return "support bridge verified job=$jobId"}
    'refresh_autonomy_telemetry' {$env:KEVIN_GH_AUTH_MODE='stored';$r=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$BridgePath) -TimeoutSeconds 180 -WorkingDirectory $Workspace;if($r.ExitCode -ne 0){throw "Telemetry refresh failed: $(One-Line ($r.Stdout+' '+$r.Stderr))"};return (One-Line $r.Stdout)}
  }
  throw 'No executor for work-order verb.'
}

if($Mode -eq 'SelfTest'){
  foreach($p in @($CatalogPath,$DispatcherPath,$ActuatorPath,$BridgePath)){if(-not(Test-Path -LiteralPath $p)){throw "SelfTest missing required file: $p"}}
  $c=Read-JsonFile $CatalogPath;if(-not $c -or @($c.missions).Count -lt 1){throw 'SelfTest mission catalog invalid.'}
  Write-Output 'WORK_ORDER_INTAKE_SELF_TEST_PASS';exit 0
}

$mutex=New-Object System.Threading.Mutex($false,'Global\KevinWorkOrderIntakeV1');$owned=$false
try{
  $owned=$mutex.WaitOne(0);if(-not $owned){Write-Output 'WORK_ORDER_INTAKE_SKIP_OVERLAP';exit 0}
  $remote=Get-RemoteJson $OrderPath $OrderBranch;if(-not $remote){Write-Output 'WORK_ORDER_NONE';exit 0}
  $o=$remote.data;$ledger=Get-Ledger
  $oid=Get-OptionalPropertyValue $o 'id';$oIdem=Get-OptionalPropertyValue $o 'idempotency_key';$oVerb=Get-OptionalPropertyValue $o 'verb';$oTarget=Get-OptionalPropertyValue $o 'target'
  $ack=[ordered]@{schema=1;kind='kevin-control-plane-ack';generated_at=(Get-Date).ToString('o');order_id=$(if($oid){[string]$oid}else{''});idempotency_key=$(if($oIdem){[string]$oIdem}else{''});verb=$(if($oVerb){[string]$oVerb}else{''});target=$(if($oTarget){[string]$oTarget}else{''});status='STARTING';detail='';safety=[ordered]@{green_only=$true;arbitrary_shell=$false;authority_expansion=$false}}
  try{
    Validate-Order $o
    $oid=[string](Get-OptionalPropertyValue $o 'id');$oIdem=[string](Get-OptionalPropertyValue $o 'idempotency_key');$oVerb=[string](Get-OptionalPropertyValue $o 'verb');$oTarget=[string](Get-OptionalPropertyValue $o 'target')
    $ack.order_id=$oid;$ack.idempotency_key=$oIdem;$ack.verb=$oVerb;$ack.target=$oTarget
    if(Is-Replay $ledger $oIdem){$ack.status='REPLAY_IGNORED';$ack.detail='Idempotency key already processed.';Write-JsonAtomic $ack $LatestPath;Publish-Ack $ack;Write-Output 'WORK_ORDER_REPLAY_IGNORED';exit 0}
    $detail=Execute-Order $o;$ack.status='VERIFIED';$ack.detail=$detail
    $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=$oid;idempotency_key=$oIdem;verb=$oVerb;target=$oTarget;completed_at=(Get-Date).ToString('o');status='VERIFIED'});Save-Ledger $ledger
    Write-JsonAtomic $ack $LatestPath;Publish-Ack $ack;Write-Output ("WORK_ORDER_VERIFIED id={0} verb={1} target={2}" -f $oid,$oVerb,$oTarget);exit 0
  }catch{
    $ack.status='FAILED';$ack.detail=One-Line $_.Exception.Message;Write-JsonAtomic $ack $LatestPath;try{Publish-Ack $ack}catch{};Write-Output ("WORK_ORDER_FAILED id={0} detail={1}" -f $ack.order_id,$ack.detail);exit 2
  }
}finally{if($owned){try{$mutex.ReleaseMutex()}catch{}};$mutex.Dispose()}
