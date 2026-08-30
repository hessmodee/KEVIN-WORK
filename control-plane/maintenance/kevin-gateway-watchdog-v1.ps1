param([switch]$SelfTest)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$Utf8=New-Object System.Text.UTF8Encoding($false)
$Workspace=if($env:USERPROFILE){Join-Path $env:USERPROFILE '.openclaw\workspace'}else{$PSScriptRoot}
$Evidence=Join-Path $Workspace 'reports\watchdog'
$StatePath=Join-Path $Evidence 'gateway-watchdog-state.json'
$MaxAttempts=3
$CooldownMinutes=15

function Write-JsonAtomic([string]$Path,[object]$Object){New-Item -ItemType Directory -Force (Split-Path $Path -Parent)|Out-Null;$tmp=$Path+'.tmp-'+$PID;[IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 20),$Utf8);Move-Item $tmp $Path -Force}
function Read-State{if(Test-Path $StatePath){try{return Get-Content $StatePath -Raw|ConvertFrom-Json}catch{}};return [pscustomobject]@{schema=1;failure_family='';attempts=0;cooldown_until=$null;last_result='';updated_at=$null}}
function Resolve-OpenClaw{$c=Get-Command openclaw.cmd -ErrorAction SilentlyContinue;if(-not$c){$c=Get-Command openclaw -ErrorAction SilentlyContinue};if(-not$c){throw'OpenClaw CLI missing'};return $c.Source}
function Invoke-Fixed([string[]]$Args,[int]$TimeoutSeconds=45){$exe=Resolve-OpenClaw;$psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName=$exe;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.Arguments=(($Args|ForEach-Object{if($_-match'[\s"]'){throw'watchdog fixed argv invariant violated'};$_})-join' ');$p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(-not$p.Start()){throw'OpenClaw start failed'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();if(-not$p.WaitForExit($TimeoutSeconds*1000)){try{$p.Kill()}catch{};$p.Dispose();return[pscustomobject]@{ExitCode=124;Stdout='';Stderr='timeout'}};$r=[pscustomobject]@{ExitCode=[int]$p.ExitCode;Stdout=[string]$out.Result;Stderr=[string]$err.Result};$p.Dispose();return$r}
function Save([object]$s,[string]$result){$s.last_result=$result;$s.updated_at=(Get-Date).ToString('o');Write-JsonAtomic $StatePath $s}

function Invoke-SelfTest{
    if($MaxAttempts-ne3){throw'watchdog retry invariant'}
    if($CooldownMinutes-ne15){throw'watchdog cooldown invariant'}
    $status=@('gateway','status','--require-rpc','--json')
    $restart=@('gateway','restart','--wait','30s','--json')
    if(($status-join' ')-ne'gateway status --require-rpc --json'){throw'status argv drift'}
    if(($restart-join' ')-ne'gateway restart --wait 30s --json'){throw'restart argv drift'}
    Write-Host 'KEVIN GATEWAY WATCHDOG v1 SELFTEST PASS fixed_status=1 fixed_restart=1 max_attempts=3 arbitrary_shell=false remote_payload=false'
}
if($SelfTest){Invoke-SelfTest;exit 0}

$s=Read-State
$now=[DateTimeOffset]::Now
if($s.cooldown_until){try{if([DateTimeOffset]::Parse([string]$s.cooldown_until)-gt$now){Save $s 'COOLDOWN';exit 0}}catch{}}
$status=Invoke-Fixed @('gateway','status','--require-rpc','--json') 30
if($status.ExitCode-eq0){$s.failure_family='';$s.attempts=0;$s.cooldown_until=$null;Save $s 'HEALTHY';exit 0}
if([string]$s.failure_family-ne'gateway_rpc_unhealthy'){$s.failure_family='gateway_rpc_unhealthy';$s.attempts=0}
$s.attempts=[int]$s.attempts+1
if([int]$s.attempts-gt$MaxAttempts){$s.cooldown_until=$now.AddMinutes($CooldownMinutes).ToString('o');Save $s 'RESTART_BUDGET_EXHAUSTED';exit 1}
$restart=Invoke-Fixed @('gateway','restart','--wait','30s','--json') 60
if($restart.ExitCode-ne0){Save $s 'RESTART_FAILED';exit 1}
Start-Sleep -Seconds 3
$verify=Invoke-Fixed @('gateway','status','--require-rpc','--json') 30
if($verify.ExitCode-ne0){Save $s 'RESTART_POSTCONDITION_FAILED';exit 1}
$s.failure_family='';$s.attempts=0;$s.cooldown_until=$null;Save $s 'RECOVERED';exit 0
