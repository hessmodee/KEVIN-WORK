param(
  [ValidateSet('Inspect','Dispatch','SelfTest')]
  [string]$Mode='Dispatch',
  [string]$RequestedMission=''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$Utf8=New-Object System.Text.UTF8Encoding($false)

$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Control=Join-Path $Workspace 'ControlPlane'
$CatalogPath=Join-Path $Control 'mission-catalog-v1.json'
$WorkerPath=Join-Path $Control 'kevin-mission-worker-v0.1.ps1'
$StateDir=Join-Path $Control 'State'
$StatePath=Join-Path $StateDir 'mission-dispatcher-state-v1.json'
$Reports=Join-Path $Workspace 'reports';if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$SupportPath=Join-Path $Reports 'support-latest.json'
$AutonomyPath=Join-Path $Reports 'autonomy-latest.json'
$LatestPath=Join-Path $Reports 'mission-dispatch-latest.json'
foreach($d in @($Control,$StateDir,$Reports)){if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}}

function Write-JsonAtomic {param([Parameter(Mandatory=$true)]$Object,[Parameter(Mandatory=$true)][string]$Path);$tmp="$Path.tmp-$PID";[IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),$Utf8);Move-Item -LiteralPath $tmp -Destination $Path -Force}
function Read-JsonFile([string]$Path){if(-not(Test-Path -LiteralPath $Path)){return $null};try{return (Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)}catch{return $null}}

function ConvertTo-Win32CommandLineArg {
  param([AllowEmptyString()][string]$Value)
  if($null -eq $Value -or $Value.Length -eq 0){return '""'}
  if($Value -notmatch '[\s"]'){return $Value}
  $sb=New-Object System.Text.StringBuilder;[void]$sb.Append('"');$slashes=0
  for($i=0;$i -lt $Value.Length;$i++){$ch=$Value[$i];if($ch -eq '\'){$slashes++;continue};if($ch -eq '"'){if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))};[void]$sb.Append('\"');$slashes=0;continue};if($slashes -gt 0){[void]$sb.Append(('\' * $slashes));$slashes=0};[void]$sb.Append($ch)}
  if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))};[void]$sb.Append('"');return $sb.ToString()
}
function Invoke-ExactNative {param([string]$Executable,[string[]]$Argv,[int]$TimeoutSeconds=0,[string]$WorkingDirectory='');$psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName=$Executable;$psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ');$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory};$p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(-not $p.Start()){throw "Could not start $Executable"};$ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();$to=$false;if($TimeoutSeconds -gt 0){if(-not $p.WaitForExit($TimeoutSeconds*1000)){$to=$true;try{$p.Kill()}catch{};$p.WaitForExit()}}else{$p.WaitForExit()};$r=[pscustomobject]@{ExitCode=$(if($to){124}else{[int]$p.ExitCode});Stdout=[string]$ot.Result;Stderr=[string]$et.Result;TimedOut=$to};$p.Dispose();return $r}

function Get-Catalog {$c=Read-JsonFile $CatalogPath;if(-not $c){throw 'Mission catalog missing/invalid.'};if([string]$c.kind -ne 'kevin-mission-catalog' -or [string]$c.version -ne '1.0'){throw 'Mission catalog contract mismatch.'};if(-not [bool]$c.policy.candidate_only -or [bool]$c.policy.allow_production_mutation -or [bool]$c.policy.allow_arbitrary_shell){throw 'Mission catalog violates authority boundary.'};return $c}
function Mission-Exists($Catalog,[string]$Id){return @($Catalog.missions|Where-Object{[string]$_.id -eq $Id}).Count -eq 1}
function New-State {return [pscustomobject]@{schema=1;queue_index=0;last_mission='';last_result='';failure_family='';attempts=0;cooldown_until=$null;recent=@();updated_at=(Get-Date).ToString('o')}}
function Get-State {$s=Read-JsonFile $StatePath;if($s){return $s};return New-State}
function Save-State($s){$s.updated_at=(Get-Date).ToString('o');Write-JsonAtomic $s $StatePath}
function Is-Fresh($Obj,[double]$Minutes){if(-not $Obj -or -not $Obj.generated_at){return $false};try{return (([DateTimeOffset]::Now-[DateTimeOffset]::Parse([string]$Obj.generated_at)).TotalMinutes -le $Minutes)}catch{return $false}}

function Test-14B-Free {
  $m=New-Object Threading.Mutex($false,'Global\Kevin14BEngineeringWorkerV1');$got=$false
  try{$got=$m.WaitOne(0);return $got}finally{if($got){try{$m.ReleaseMutex()}catch{}};$m.Dispose()}
}

function Get-Eligibility($Support,$Autonomy){
  $reasons=New-Object Collections.Generic.List[string]
  if(-not(Is-Fresh $Support 10)){$reasons.Add('support-stale-or-missing')}
  if(-not(Is-Fresh $Autonomy 15)){$reasons.Add('autonomy-stale-or-missing')}
  if($Support -and $Support.governance -and (-not [bool]$Support.governance.ok)){$reasons.Add('governance-not-ok')}
  if($Support -and $Support.benchmark -and [string]$Support.benchmark.status -ne 'PASS'){$reasons.Add('benchmark-not-pass')}
  if($Autonomy -and [string]$Autonomy.state -notin @('HEALTHY','VERIFIED')){$reasons.Add('autonomy-not-healthy')}
  $active=0;if($Support -and $Support.active_workers){foreach($p in $Support.active_workers.PSObject.Properties){$active+=[int]$p.Value}}
  if($active -gt 0){$reasons.Add("active-workers=$active")}
  if(-not(Test-14B-Free)){$reasons.Add('14b-mutex-busy')}
  $blocked=$false;if($Support -and $Support.supervisor){$blocked=([string]$Support.supervisor.last_result -match 'RECOVERY_SATURATED|RECOVERY_THROTTLED|WAIT|BLOCK|COOL')}
  return [pscustomobject]@{ok=($reasons.Count -eq 0);reasons=@($reasons);active_workers=$active;supervisor_blocked_or_cooling=$blocked}
}

function Normalize-Recent($State,[int]$Max=30){$items=@($State.recent);if($items.Count -gt $Max){$items=@($items|Select-Object -Last $Max)};$State.recent=$items}
function Was-RecentlyRun($State,[string]$MissionId,[double]$CooldownMinutes){foreach($r in @($State.recent)){if([string]$r.mission_id -eq $MissionId){try{if((([DateTimeOffset]::Now)-[DateTimeOffset]::Parse([string]$r.at)).TotalMinutes -lt $CooldownMinutes){return $true}}catch{}}};return $false}
function Pick-Mission($Catalog,$State,$Autonomy,[string]$Requested){
  if($Requested){if(-not(Mission-Exists $Catalog $Requested)){throw "Requested mission is not allowlisted: $Requested"};return $Requested}
  $cool=[double]$Catalog.policy.mission_repeat_cooldown_minutes
  $suggested='';if($Autonomy -and $Autonomy.work_conserving){$suggested=[string]$Autonomy.work_conserving.next_suggested_candidate}
  if($suggested -and (Mission-Exists $Catalog $suggested) -and -not(Was-RecentlyRun $State $suggested $cool)){return $suggested}
  $missions=@($Catalog.missions);if($missions.Count -eq 0){return ''};$start=[int]$State.queue_index;if($start -lt 0){$start=0}
  for($i=0;$i -lt $missions.Count;$i++){$idx=($start+$i)%$missions.Count;$id=[string]$missions[$idx].id;if(-not(Was-RecentlyRun $State $id $cool)){$State.queue_index=($idx+1)%$missions.Count;return $id}}
  return ''
}

$Catalog=Get-Catalog
if($Mode -eq 'SelfTest'){if(-not(Test-Path -LiteralPath $WorkerPath)){throw 'Mission worker missing.'};$r=Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','SelfTest') 60 $Workspace;if($r.ExitCode -ne 0){throw "Mission worker self-test failed: $($r.Stdout) $($r.Stderr)"};Write-Output 'MISSION_DISPATCHER_SELF_TEST_PASS';exit 0}

$mutex=New-Object Threading.Mutex($false,'Global\KevinMissionDispatcherV1');$owned=$false
try{
  $owned=$mutex.WaitOne(0);if(-not $owned){Write-Output 'MISSION_DISPATCHER_SKIP_OVERLAP';exit 0}
  $Support=Read-JsonFile $SupportPath;$Autonomy=Read-JsonFile $AutonomyPath;$State=Get-State;$elig=Get-Eligibility $Support $Autonomy
  $result=[ordered]@{schema=1;kind='kevin-mission-dispatch-result';generated_at=(Get-Date).ToString('o');mode=$Mode;eligible=[bool]$elig.ok;reasons=@($elig.reasons);active_workers=[int]$elig.active_workers;supervisor_blocked_or_cooling=[bool]$elig.supervisor_blocked_or_cooling;requested_mission=$(if($RequestedMission){$RequestedMission}else{$null});selected_mission=$null;state='INSPECTED';worker_exit=$null;worker_state=$null;candidate_only=$true}
  if($Mode -eq 'Inspect'){Write-JsonAtomic $result $LatestPath;Write-Output ("MISSION_DISPATCHER_INSPECT eligible={0} blocked={1}" -f $elig.ok,$elig.supervisor_blocked_or_cooling);exit 0}
  if(-not $elig.ok){$result.state='NOT_ELIGIBLE';Write-JsonAtomic $result $LatestPath;Write-Output ("MISSION_DISPATCHER_NOT_ELIGIBLE reasons={0}" -f (@($elig.reasons)-join ','));exit 0}
  if(-not $RequestedMission -and -not [bool]$elig.supervisor_blocked_or_cooling){$result.state='PRIMARY_MISSION_ACTIVE';Write-JsonAtomic $result $LatestPath;Write-Output 'MISSION_DISPATCHER_PRIMARY_MISSION_ACTIVE';exit 0}
  if($State.cooldown_until){try{if([DateTimeOffset]::Parse([string]$State.cooldown_until) -gt [DateTimeOffset]::Now){$result.state='FAILURE_COOLDOWN';Write-JsonAtomic $result $LatestPath;Write-Output 'MISSION_DISPATCHER_FAILURE_COOLDOWN';exit 0}}catch{}}
  $mission=Pick-Mission $Catalog $State $Autonomy $RequestedMission
  if(-not $mission){$result.state='QUEUE_COOLING';Write-JsonAtomic $result $LatestPath;Save-State $State;Write-Output 'MISSION_DISPATCHER_QUEUE_COOLING';exit 0}
  $result.selected_mission=$mission;$result.state='RUNNING';Write-JsonAtomic $result $LatestPath
  $worker=Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','Run','-MissionId',$mission) 520 $Workspace
  $workerReport=Read-JsonFile (Join-Path $Reports 'mission-factory-latest.json');$workerState=$(if($workerReport){[string]$workerReport.state}else{'UNKNOWN'})
  $result.worker_exit=[int]$worker.ExitCode;$result.worker_state=$workerState;$result.generated_at=(Get-Date).ToString('o')
  $semanticProgress=($worker.ExitCode -eq 0 -and $workerState -in @('PASS','REJECT','SKIP_14B_BUSY'))
  if($semanticProgress -and $workerState -ne 'SKIP_14B_BUSY'){
    $result.state='DISPATCH_COMPLETE';$State.failure_family='';$State.attempts=0;$State.cooldown_until=$null;$State.last_mission=$mission;$State.last_result=$workerState
    $recent=@($State.recent)+@([pscustomobject]@{mission_id=$mission;at=(Get-Date).ToString('o');result=$workerState});$State.recent=$recent;Normalize-Recent $State
  }elseif($workerState -eq 'SKIP_14B_BUSY'){$result.state='RESOURCE_RACE_SKIP'}
  else{
    $result.state='DISPATCH_INFRA_FAILURE';$same=([string]$State.failure_family -eq $mission);if(-not $same){$State.failure_family=$mission;$State.attempts=0};$State.attempts=[int]$State.attempts+1;$State.last_mission=$mission;$State.last_result='INFRA_FAILURE'
    if([int]$State.attempts -ge [int]$Catalog.policy.max_same_mission_infra_failures){$State.cooldown_until=([DateTimeOffset]::Now.AddMinutes([double]$Catalog.policy.infra_failure_cooldown_minutes)).ToString('o')}
    $result.worker_error=(($worker.Stdout+' '+$worker.Stderr) -replace '[\r\n]+',' ').Trim()
  }
  Save-State $State;Write-JsonAtomic $result $LatestPath
  Write-Output ("MISSION_DISPATCHER_RESULT mission={0} state={1} worker={2}" -f $mission,$result.state,$workerState)
  if($result.state -eq 'DISPATCH_INFRA_FAILURE'){exit 2};exit 0
}finally{if($owned){try{$mutex.ReleaseMutex()}catch{}};$mutex.Dispose()}
