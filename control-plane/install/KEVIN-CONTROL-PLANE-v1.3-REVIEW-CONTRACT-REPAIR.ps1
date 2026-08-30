param(
  [ValidateSet('Install','ValidateTransport')]
  [string]$Mode='Install'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$Utf8=New-Object System.Text.UTF8Encoding($false)

function Step([string]$Text){Write-Host ("`n==> "+$Text) -ForegroundColor Cyan}
function Good([string]$Text){Write-Host ("PASS  "+$Text) -ForegroundColor Green}
function Note([string]$Text){Write-Host ("INFO  "+$Text) -ForegroundColor DarkGray}
function One-Line([AllowEmptyString()][string]$Text){if($null -eq $Text){return ''};$s=($Text -replace '[\r\n]+',' ').Trim();if($s.Length -gt 1200){$s=$s.Substring(0,1200)};return $s}
function Get-OptionalPropertyValue($Object,[string]$Name){if($null -eq $Object){return $null};$p=$Object.PSObject.Properties[$Name];if($null -eq $p){return $null};return $p.Value}

function ConvertTo-Win32CommandLineArg {
  param([AllowEmptyString()][string]$Value)
  if($null -eq $Value -or $Value.Length -eq 0){return '""'}
  if($Value -notmatch '[\s"]'){return $Value}
  $sb=New-Object System.Text.StringBuilder;[void]$sb.Append('"');$slashes=0
  for($i=0;$i -lt $Value.Length;$i++){$ch=$Value[$i];if($ch -eq '\'){$slashes++;continue};if($ch -eq '"'){if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))};[void]$sb.Append('\"');$slashes=0;continue};if($slashes -gt 0){[void]$sb.Append(('\' * $slashes));$slashes=0};[void]$sb.Append($ch)}
  if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))};[void]$sb.Append('"');return $sb.ToString()
}
function Invoke-ExactNative {
  param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string[]]$Argv,[int]$TimeoutSeconds=0,[string]$WorkingDirectory='')
  $psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName=$Executable;$psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ');$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory}
  $p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(-not $p.Start()){throw "Could not start $Executable"};$ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();$timed=$false;if($TimeoutSeconds -gt 0){if(-not $p.WaitForExit($TimeoutSeconds*1000)){$timed=$true;try{$p.Kill()}catch{};$p.WaitForExit()}}else{$p.WaitForExit()};$r=[pscustomobject]@{ExitCode=$(if($timed){124}else{[int]$p.ExitCode});Stdout=[string]$ot.Result;Stderr=[string]$et.Result;TimedOut=$timed};$p.Dispose();return $r
}
function Test-ExactNativeJsonTransport {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js required.'}
  $probe=Join-Path $env:TEMP ("kevin-cp13-argv-{0}.js" -f [guid]::NewGuid().ToString('N'));$js=@'
const a=process.argv.slice(2);const i=a.indexOf('--command-argv');if(i<0||i+1>=a.length)process.exit(31);let p;try{p=JSON.parse(a[i+1]);}catch{process.exit(32);}const ok=Array.isArray(p)&&p.length===4&&p[0]==='powershell.exe'&&p[1]==='C:\\Path With Space\\x.ps1'&&p[2]==='A"B'&&p[3]==='tail\\';process.exit(ok?0:33);
'@;[IO.File]::WriteAllText($probe,$js,$Utf8);try{$j=@('powershell.exe','C:\Path With Space\x.ps1','A"B','tail\')|ConvertTo-Json -Compress;$r=Invoke-ExactNative $node.Source @($probe,'--command-argv',$j) 30;if($r.ExitCode -ne 0){throw "Exact argv transport failed: $($r.ExitCode)"}}finally{Remove-Item $probe -Force -ErrorAction SilentlyContinue}
}
if($Mode -eq 'ValidateTransport'){Test-ExactNativeJsonTransport;Write-Output 'CONTROL_PLANE_V13_TRANSPORT_OK';exit 0}

$Repo='hessmodee/KEVIN-WORK'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace';$Root=Join-Path $Workspace 'ControlPlane';$BackupDir=Join-Path $Root 'Backups';$EvidenceDir=Join-Path $Root 'Evidence'
foreach($d in @($Root,$BackupDir,$EvidenceDir)){if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}}
$WorkerPath=Join-Path $Root 'kevin-mission-worker-v0.1.ps1';$DispatcherPath=Join-Path $Root 'kevin-mission-dispatcher-v0.1.ps1';$CatalogPath=Join-Path $Root 'mission-catalog-v1.json';$IntakePath=Join-Path $Root 'kevin-work-order-intake-v0.1.ps1'
$OldWorker='a3e9797aca21aa99121148e21473beeccde1f63f';$NewWorker='befe1924996fc7015fea56ae893d74390dd2b78c'
$OldDispatcher='766fa55163b238f04ca54cc18164363b962a777e';$NewDispatcher='f91b17e16639129cc3522e93da65b7c0a50f9ce5'
$InvariantPins=[ordered]@{
  (Join-Path $Root 'desired-state-v1.json')='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
  (Join-Path $Root 'OWNER-AUTHORIZATION-v1.md')='b0cc4465f12457492b3a6c2761287398cc6295b5'
  (Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1')='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
  (Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1')='2b0a4f168b2d5f64b1979063eaf62807373e25ce'
  $CatalogPath='743db880f6529f59341f2e0f89da533091392001'
  $IntakePath='b21488796d967da6b892190538d61b4e58d072f5'
}

function Get-GitBlobSha1([string]$Path){$b=[IO.File]::ReadAllBytes($Path);$h=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $b.Length));$all=New-Object byte[] ($h.Length+1+$b.Length);[Buffer]::BlockCopy($h,0,$all,0,$h.Length);$all[$h.Length]=0;[Buffer]::BlockCopy($b,0,$all,$h.Length+1,$b.Length);$sha=[Security.Cryptography.SHA1]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
function Parse-PowerShellFile([string]$Path){$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors);if($errors -and $errors.Count){$m=($errors|ForEach-Object{"line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; ';throw "Parser rejected $(Split-Path $Path -Leaf): $m"}}
function Resolve-Gh {$g=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not $g){$g=Get-Command gh -ErrorAction SilentlyContinue};if(-not $g){throw 'GitHub CLI not found.'};return $g.Source}
function Use-StoredGhCredential {if([string]$env:KEVIN_GH_AUTH_MODE -eq 'env'){$env:GH_PROMPT_DISABLED='1';return};foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath ("Env:{0}" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}
Use-StoredGhCredential;$script:GhExe=Resolve-Gh
function Invoke-Gh([string[]]$Argv){return Invoke-ExactNative $script:GhExe $Argv 90 $Workspace}
function Get-GitBlobBytes([string]$Blob){$r=Invoke-Gh @('api',("repos/{0}/git/blobs/{1}" -f $Repo,$Blob));if($r.ExitCode -ne 0){throw "GitHub blob fetch failed for ${Blob}: $(One-Line ($r.Stdout+' '+$r.Stderr))"};$o=$r.Stdout|ConvertFrom-Json;if(([string](Get-OptionalPropertyValue $o 'sha')).ToLowerInvariant() -ne $Blob){throw "Blob identity mismatch: $Blob"};if([string](Get-OptionalPropertyValue $o 'encoding') -ne 'base64'){throw "Unexpected blob encoding: $Blob"};return [Convert]::FromBase64String(([string](Get-OptionalPropertyValue $o 'content') -replace '\s',''))}

$temp=Join-Path $env:TEMP ("kevin-cp13-{0}" -f [guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $temp -Force|Out-Null
$workerBackup='';$dispatcherBackup='';$workerChanged=$false;$dispatcherChanged=$false
$engMutex=New-Object Threading.Mutex($false,'Global\Kevin14BEngineeringWorkerV1');$dispatchMutex=New-Object Threading.Mutex($false,'Global\KevinMissionDispatcherV1');$engOwned=$false;$dispatchOwned=$false
try{
  Step 'Acquire engineering and dispatcher maintenance locks'
  Note 'Waiting up to 12 minutes for any in-flight engineering/dispatch work to finish.'
  $engOwned=$engMutex.WaitOne([TimeSpan]::FromMinutes(12));if(-not $engOwned){throw 'Timed out waiting for the engineering worker maintenance lock.'}
  $dispatchOwned=$dispatchMutex.WaitOne([TimeSpan]::FromMinutes(2));if(-not $dispatchOwned){throw 'Timed out waiting for the mission dispatcher maintenance lock.'};Good 'Both maintenance locks acquired.'

  Step 'Verify frozen Control Plane authority roots'
  foreach($kv in $InvariantPins.GetEnumerator()){if(-not(Test-Path -LiteralPath $kv.Key)){throw "Missing invariant: $($kv.Key)"};$a=Get-GitBlobSha1 $kv.Key;if($a -ne [string]$kv.Value){throw "Invariant drift: $(Split-Path $kv.Key -Leaf) expected $($kv.Value), got $a"};Good "$(Split-Path $kv.Key -Leaf) unchanged: $a"}
  $workerBefore=Get-GitBlobSha1 $WorkerPath;if($workerBefore -notin @($OldWorker,$NewWorker)){throw "Unexpected worker identity: $workerBefore"}
  $dispatcherBefore=Get-GitBlobSha1 $DispatcherPath;if($dispatcherBefore -notin @($OldDispatcher,$NewDispatcher)){throw "Unexpected dispatcher identity: $dispatcherBefore"};Good "Worker recognized: $workerBefore";Good "Dispatcher recognized: $dispatcherBefore"

  Step 'Verify stored GitHub credential and exact argv transport'
  Test-ExactNativeJsonTransport;Good 'WinPS 5.1 exact argv transport passed.';$auth=Invoke-Gh @('auth','status','--hostname','github.com');if($auth.ExitCode -ne 0){throw "Stored GitHub credential unavailable: $(One-Line ($auth.Stdout+' '+$auth.Stderr))"};Good 'Stored GitHub CLI credential available.'

  Step 'Fetch immutable v1.3 worker and dispatcher blobs'
  $stagedWorker=Join-Path $temp 'worker.ps1';$stagedDispatcher=Join-Path $temp 'dispatcher.ps1';[IO.File]::WriteAllBytes($stagedWorker,(Get-GitBlobBytes $NewWorker));[IO.File]::WriteAllBytes($stagedDispatcher,(Get-GitBlobBytes $NewDispatcher));if((Get-GitBlobSha1 $stagedWorker) -ne $NewWorker -or (Get-GitBlobSha1 $stagedDispatcher) -ne $NewDispatcher){throw 'Staged blob identity mismatch.'};Parse-PowerShellFile $stagedWorker;Parse-PowerShellFile $stagedDispatcher;Good "Worker staged: $NewWorker";Good "Dispatcher staged: $NewDispatcher"

  Step 'Back up and atomically install both repaired components'
  $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
  if($workerBefore -eq $OldWorker){$workerBackup=Join-Path $BackupDir ("$stamp-kevin-mission-worker-v0.1.ps1");Copy-Item $WorkerPath $workerBackup -Force;$tmp="$WorkerPath.tmp-$PID";[IO.File]::WriteAllBytes($tmp,[IO.File]::ReadAllBytes($stagedWorker));Move-Item $tmp $WorkerPath -Force;$workerChanged=$true}else{Note 'v1.3 worker already installed.'}
  if($dispatcherBefore -eq $OldDispatcher){$dispatcherBackup=Join-Path $BackupDir ("$stamp-kevin-mission-dispatcher-v0.1.ps1");Copy-Item $DispatcherPath $dispatcherBackup -Force;$tmp="$DispatcherPath.tmp-$PID";[IO.File]::WriteAllBytes($tmp,[IO.File]::ReadAllBytes($stagedDispatcher));Move-Item $tmp $DispatcherPath -Force;$dispatcherChanged=$true}else{Note 'v1.3 dispatcher already installed.'}
  if((Get-GitBlobSha1 $WorkerPath) -ne $NewWorker){throw 'Installed worker identity mismatch.'};if((Get-GitBlobSha1 $DispatcherPath) -ne $NewDispatcher){throw 'Installed dispatcher identity mismatch.'};Good 'Exact v1.3 identities proven.'

  Step 'Run worker and dispatcher runtime self-tests'
  $w=Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','SelfTest') 90 $Workspace;if($w.ExitCode -ne 0 -or (One-Line $w.Stdout) -notmatch 'structured_fallback=line-or-json' -or (One-Line $w.Stdout) -notmatch 'fail_closed=1'){throw "Worker self-test failed: $(One-Line ($w.Stdout+' '+$w.Stderr))"};Good (One-Line $w.Stdout)
  $d=Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$DispatcherPath,'-Mode','SelfTest') 120 $Workspace;if($d.ExitCode -ne 0 -or (One-Line $d.Stdout) -notmatch 'failure_family=review-output-contract'){throw "Dispatcher self-test failed: $(One-Line ($d.Stdout+' '+$d.Stderr))"};Good (One-Line $d.Stdout)
  $neg=Invoke-ExactNative 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','Run','-MissionId','__not_allowlisted__') 45 $Workspace;if($neg.ExitCode -eq 0 -or (One-Line ($neg.Stdout+' '+$neg.Stderr)) -notmatch 'not in the local hash-pinned catalog'){throw 'Unallowlisted mission fail-closed test failed.'};Good 'Unallowlisted mission still fails closed before model execution.'

  Step 'Write evidence and rollback'
  $manifest=[ordered]@{schema=1;kind='kevin-control-plane-repair';version='1.3';installed_at=(Get-Date).ToString('o');worker_blob=$NewWorker;dispatcher_blob=$NewDispatcher;previous_worker_blob=$workerBefore;previous_dispatcher_blob=$dispatcherBefore;worker_changed=$workerChanged;dispatcher_changed=$dispatcherChanged;safety=[ordered]@{green_only=$true;arbitrary_shell=$false;authority_expansion=$false;production_chat_changed=$false;reader_changed=$false;autonomy_roots_changed=$false;intake_changed=$false;automatic_candidate_promotion=$false}}
  $manifestPath=Join-Path $Root 'install-manifest-control-plane-v1.3.json';[IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 20),$Utf8);$proofPath=Join-Path $EvidenceDir ("$stamp-control-plane-v1.3-review-contract-proof.json");[IO.File]::WriteAllText($proofPath,($manifest|ConvertTo-Json -Depth 20),$Utf8)
  $rollbackPath=Join-Path $Root 'ROLLBACK-CONTROL-PLANE-v1.3.ps1';$rb=New-Object Collections.Generic.List[string];$rb.Add("`$ErrorActionPreference='Stop'");if($workerBackup){$rb.Add(("Copy-Item -LiteralPath '{0}' -Destination '{1}' -Force" -f $workerBackup.Replace("'","''"),$WorkerPath.Replace("'","''")))};if($dispatcherBackup){$rb.Add(("Copy-Item -LiteralPath '{0}' -Destination '{1}' -Force" -f $dispatcherBackup.Replace("'","''"),$DispatcherPath.Replace("'","''")))};$rb.Add("Write-Host 'Kevin Control Plane v1.3 rollback completed.'");[IO.File]::WriteAllLines($rollbackPath,$rb,$Utf8);Good "Manifest: $manifestPath";Good "Rollback: $rollbackPath"

  Write-Host ''
  Write-Host '============================================================' -ForegroundColor Green
  Write-Host 'KEVIN CONTROL PLANE v1.3 REVIEW CONTRACT REPAIR INSTALLED + PROVEN' -ForegroundColor Green
  Write-Host '============================================================' -ForegroundColor Green
  Write-Host 'Reviewer fallback: strict line OR strict JSON; unstructured prose still rejected'
  Write-Host 'Failure budget: shared infrastructure family across rotating missions'
  Write-Host 'Production Chat, Reader, authority roots, Intake, and autonomy roots unchanged'
  exit 0
}catch{
  if($dispatcherChanged -and $dispatcherBackup -and (Test-Path $dispatcherBackup)){try{Copy-Item $dispatcherBackup $DispatcherPath -Force}catch{}}
  if($workerChanged -and $workerBackup -and (Test-Path $workerBackup)){try{Copy-Item $workerBackup $WorkerPath -Force}catch{}}
  throw
}finally{
  if($dispatchOwned){try{$dispatchMutex.ReleaseMutex()}catch{}};if($engOwned){try{$engMutex.ReleaseMutex()}catch{}};$dispatchMutex.Dispose();$engMutex.Dispose();Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
}
