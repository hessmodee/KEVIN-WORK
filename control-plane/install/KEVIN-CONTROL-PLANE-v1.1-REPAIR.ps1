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
  $psi=New-Object System.Diagnostics.ProcessStartInfo;$psi.FileName=$Executable;$psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ');$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory}
  $p=New-Object System.Diagnostics.Process;$p.StartInfo=$psi;if(-not $p.Start()){throw "Could not start native process: $Executable"};$ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();$to=$false;if($TimeoutSeconds -gt 0){if(-not $p.WaitForExit($TimeoutSeconds*1000)){$to=$true;try{$p.Kill()}catch{};$p.WaitForExit()}}else{$p.WaitForExit()};$r=[pscustomobject]@{ExitCode=$(if($to){124}else{[int]$p.ExitCode});Stdout=[string]$ot.Result;Stderr=[string]$et.Result;TimedOut=$to;CommandLine=$psi.Arguments};$p.Dispose();return $r
}
function Test-ExactNativeJsonTransport {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js required.'}
  $probe=Join-Path $env:TEMP ("kevin-cp11-argv-{0}.js" -f [guid]::NewGuid().ToString('N'))
  $js=@'
const a=process.argv.slice(2);const i=a.indexOf('--command-argv');if(i<0||i+1>=a.length)process.exit(31);let p;try{p=JSON.parse(a[i+1]);}catch{process.exit(32);}const ok=Array.isArray(p)&&p.length===4&&p[0]==='powershell.exe'&&p[1]==='C:\\Path With Space\\x.ps1'&&p[2]==='A"B'&&p[3]==='tail\\';process.exit(ok?0:33);
'@
  [IO.File]::WriteAllText($probe,$js,$Utf8);try{$j=@('powershell.exe','C:\Path With Space\x.ps1','A"B','tail\')|ConvertTo-Json -Compress;$r=Invoke-ExactNative -Executable $node.Source -Argv @($probe,'--command-argv',$j) -TimeoutSeconds 30;if($r.ExitCode -ne 0){throw "Exact argv transport failed: $($r.ExitCode)"}}finally{Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue}
}
if($Mode -eq 'ValidateTransport'){Test-ExactNativeJsonTransport;Write-Output 'CONTROL_PLANE_V11_TRANSPORT_OK';exit 0}

$Repo='hessmodee/KEVIN-WORK';$OrderBranch='kevin-control-plane-v1'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace';$Root=Join-Path $Workspace 'ControlPlane';$StateDir=Join-Path $Root 'State';$BackupDir=Join-Path $Root 'Backups';$EvidenceDir=Join-Path $Root 'Evidence';$Reports=Join-Path $Workspace 'reports';if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
foreach($d in @($Root,$StateDir,$BackupDir,$EvidenceDir)){if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}}
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
$WorkerPath=Join-Path $Root 'kevin-mission-worker-v0.1.ps1';$DispatcherPath=Join-Path $Root 'kevin-mission-dispatcher-v0.1.ps1';$IntakePath=Join-Path $Root 'kevin-work-order-intake-v0.1.ps1';$CatalogPath=Join-Path $Root 'mission-catalog-v1.json'
$DispatcherStatePath=Join-Path $StateDir 'mission-dispatcher-state-v1.json';$WorkerStatePath=Join-Path $StateDir 'mission-worker-state-v1.json'

$InvariantPins=[ordered]@{
  (Join-Path $Root 'desired-state-v1.json')='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
  (Join-Path $Root 'OWNER-AUTHORIZATION-v1.md')='b0cc4465f12457492b3a6c2761287398cc6295b5'
  (Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1')='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
  (Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1')='2b0a4f168b2d5f64b1979063eaf62807373e25ce'
  $CatalogPath='743db880f6529f59341f2e0f89da533091392001'
}
$OldPins=[ordered]@{$WorkerPath='5546b2bc5d6eb87b7f25b3d72214e99fe6636ba8';$DispatcherPath='893d2fac2e0ffb5aa536d9d6b02eb49164018d10';$IntakePath='75709657b6d34ffb24a9e6a9dc968d07e0467557'}
$NewPins=[ordered]@{$WorkerPath='3b02fb4acfadb715a017641b622179a9cf422eb0';$DispatcherPath='766fa55163b238f04ca54cc18164363b962a777e';$IntakePath='b21488796d967da6b892190538d61b4e58d072f5'}

function Get-GitBlobSha1([string]$Path){$b=[IO.File]::ReadAllBytes($Path);$h=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $b.Length));$all=New-Object byte[] ($h.Length+1+$b.Length);[Buffer]::BlockCopy($h,0,$all,0,$h.Length);$all[$h.Length]=0;[Buffer]::BlockCopy($b,0,$all,$h.Length+1,$b.Length);$sha=[Security.Cryptography.SHA1]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
function Parse-PowerShellFile([string]$Path){$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors);if($errors -and $errors.Count){$m=($errors|ForEach-Object{"line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; ';throw "Parser rejected $(Split-Path $Path -Leaf): $m"}}
function Read-JsonFile([string]$Path){if(-not(Test-Path -LiteralPath $Path)){return $null};try{return (Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)}catch{return $null}}
function Write-JsonAtomic($Object,[string]$Path){$tmp="$Path.tmp-$PID";[IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),$Utf8);Move-Item -LiteralPath $tmp -Destination $Path -Force}
function Get-OptionalPropertyValue($Object,[string]$Name){if($null -eq $Object){return $null};$p=$Object.PSObject.Properties[$Name];if($null -eq $p){return $null};return $p.Value}

function Resolve-Gh {$g=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not $g){$g=Get-Command gh -ErrorAction SilentlyContinue};if(-not $g){throw 'GitHub CLI not found.'};return $g.Source}
function Use-StoredGhCredential {foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath ("Env:{0}" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}
Use-StoredGhCredential;$script:GhExe=Resolve-Gh
function Invoke-Gh([string[]]$Argv){return Invoke-ExactNative -Executable $script:GhExe -Argv $Argv -TimeoutSeconds 90 -WorkingDirectory $Workspace}
function Get-GitBlobBytes([string]$Blob){$r=Invoke-Gh @('api',("repos/{0}/git/blobs/{1}" -f $Repo,$Blob));if($r.ExitCode -ne 0){throw "GitHub blob fetch failed for ${Blob}: $(One-Line ($r.Stdout+' '+$r.Stderr))"};$o=$r.Stdout|ConvertFrom-Json;if(([string](Get-OptionalPropertyValue $o 'sha')).ToLowerInvariant() -ne $Blob){throw "Blob identity mismatch: $Blob"};return [Convert]::FromBase64String(([string](Get-OptionalPropertyValue $o 'content') -replace '\s',''))}

function Get-OpenClawNodeLauncher {$node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js missing.'};$shim=Get-Command openclaw.cmd -ErrorAction SilentlyContinue;if(-not $shim){$shim=Get-Command openclaw -ErrorAction SilentlyContinue};if(-not $shim){throw 'OpenClaw CLI missing.'};$pkgDir=Join-Path (Split-Path -Parent $shim.Source) 'node_modules\openclaw';$pkg=Get-Content -LiteralPath (Join-Path $pkgDir 'package.json') -Raw|ConvertFrom-Json;$binRel=if($pkg.bin -is [string]){[string]$pkg.bin}else{[string]$pkg.bin.openclaw};return [pscustomobject]@{Node=$node.Source;Cli=(Join-Path $pkgDir $binRel);Version=[string]$pkg.version}}
function ConvertFrom-OpenClawJson([string]$Text){if([string]::IsNullOrWhiteSpace($Text)){return $null};$t=$Text.Trim();try{return ($t|ConvertFrom-Json)}catch{};$t=[regex]::Replace($t,"`e\[[0-9;?]*[ -/]*[@-~]",'');$starts=@($t.IndexOf('{'),$t.IndexOf('['))|Where-Object{$_ -ge 0}|Sort-Object;foreach($s in $starts){try{return ($t.Substring([int]$s)|ConvertFrom-Json)}catch{}};throw 'OpenClaw stdout was not valid JSON.'}
$script:Ocl=$null
function Invoke-OclRaw([string[]]$Argv){if(-not $script:Ocl){$script:Ocl=Get-OpenClawNodeLauncher};return Invoke-ExactNative -Executable $script:Ocl.Node -Argv (@($script:Ocl.Cli)+@($Argv)) -TimeoutSeconds 120 -WorkingDirectory $Workspace}
function Invoke-OclJson([string[]]$Argv){$r=Invoke-OclRaw $Argv;if($r.ExitCode -ne 0){throw "OpenClaw failed: $(One-Line ($r.Stdout+' '+$r.Stderr))"};return (ConvertFrom-OpenClawJson $r.Stdout)}
function Assert-StringArrayEqual([string[]]$Actual,[string[]]$Expected,[string]$Label){if(@($Actual).Count -ne @($Expected).Count){throw "$Label argv length mismatch."};for($i=0;$i -lt @($Expected).Count;$i++){if([string]$Actual[$i] -cne [string]$Expected[$i]){throw "$Label argv mismatch at $i."}}}
function Assert-CommandJob($Job,[string]$Label,[string]$Expr,[string[]]$Argv,[string]$Cwd){if(-not $Job -or -not [bool](Get-OptionalPropertyValue $Job 'enabled')){throw "$Label missing or disabled."};$payload=Get-OptionalPropertyValue $Job 'payload';if([string](Get-OptionalPropertyValue $payload 'kind') -ne 'command'){throw "$Label payload kind mismatch."};Assert-StringArrayEqual @((Get-OptionalPropertyValue $payload 'argv')) $Argv $Label;if([string](Get-OptionalPropertyValue $payload 'cwd') -cne $Cwd){throw "$Label cwd mismatch."};$schedule=Get-OptionalPropertyValue $Job 'schedule';if([string](Get-OptionalPropertyValue $schedule 'expr') -cne $Expr){throw "$Label schedule mismatch."}}

$tempDir=Join-Path $env:TEMP ("kevin-cp11-{0}" -f [guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $tempDir -Force|Out-Null
$backups=New-Object System.Collections.Generic.List[object];$stateBackup='';$stateReset=$false
try{
  Step 'Verify frozen autonomy roots and installed Control Plane v1 identities'
  foreach($kv in $InvariantPins.GetEnumerator()){if(-not(Test-Path -LiteralPath $kv.Key)){throw "Missing invariant component: $($kv.Key)"};$a=Get-GitBlobSha1 $kv.Key;if($a -ne [string]$kv.Value){throw "Invariant drift: $($kv.Key) expected $($kv.Value), got $a"};Good "$(Split-Path $kv.Key -Leaf) unchanged: $a"}
  foreach($p in @($WorkerPath,$DispatcherPath,$IntakePath)){if(-not(Test-Path -LiteralPath $p)){throw "Missing Control Plane component: $p"};$a=Get-GitBlobSha1 $p;if($a -ne [string]$OldPins[$p] -and $a -ne [string]$NewPins[$p]){throw "Unexpected Control Plane drift: $(Split-Path $p -Leaf) $a"};Good "$(Split-Path $p -Leaf) recognized: $a"}

  Step 'Prove exact transport, OpenClaw version, stored GitHub credential, and empty work-order inbox'
  Test-ExactNativeJsonTransport;Good 'WinPS 5.1 exact argv transport passed.';$script:Ocl=Get-OpenClawNodeLauncher;if($script:Ocl.Version -ne '2026.7.1-2'){throw "Expected OpenClaw 2026.7.1-2, found $($script:Ocl.Version)"};Good 'OpenClaw 2026.7.1-2 resolved.'
  $auth=Invoke-Gh @('auth','status','--hostname','github.com');if($auth.ExitCode -ne 0){throw "Stored GitHub credential unavailable: $(One-Line ($auth.Stdout+' '+$auth.Stderr))"};Good 'Stored GitHub credential available.'
  $ep=("repos/{0}/contents/control-plane/orders/CURRENT.json?ref={1}" -f $Repo,[Uri]::EscapeDataString($OrderBranch));$pending=Invoke-Gh @('api',$ep,'-H','Accept: application/vnd.github+json');if($pending.ExitCode -eq 0){throw 'A CURRENT work order exists; refusing repair while intake has pending work.'};$pt=One-Line ($pending.Stdout+' '+$pending.Stderr);if($pt -notmatch '404|Not Found'){throw "Could not prove empty work-order inbox: $pt"};Good 'Remote CURRENT work-order inbox is empty.'

  Step 'Freeze existing scheduler identities before file mutation'
  $list=Invoke-OclJson @('cron','list','--all','--json');$jobs=@();if($list){$j=Get-OptionalPropertyValue $list 'jobs';if($j){$jobs=@($j)}}
  $disp=@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Mission Dispatcher v1'});$int=@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Work Order Intake v1'});$rec=@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Autonomy Reconciler v0.1'});$tel=@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Autonomy Telemetry v0.1'})
  if($disp.Count -ne 1 -or $int.Count -ne 1 -or $rec.Count -ne 1 -or $tel.Count -ne 1){throw "Expected one Dispatcher/Intake/Reconciler/Telemetry job; found $($disp.Count)/$($int.Count)/$($rec.Count)/$($tel.Count)"}
  $dispId=[string](Get-OptionalPropertyValue $disp[0] 'id');$intId=[string](Get-OptionalPropertyValue $int[0] 'id');$recId=[string](Get-OptionalPropertyValue $rec[0] 'id');$telId=[string](Get-OptionalPropertyValue $tel[0] 'id')
  $dispArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$DispatcherPath,'-Mode','Dispatch');$intArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$IntakePath,'-Mode','Poll')
  $dj=Invoke-OclJson @('cron','get',$dispId);$ij=Invoke-OclJson @('cron','get',$intId);Assert-CommandJob $dj 'Mission Dispatcher' '*/3 * * * *' $dispArgv $Root;Assert-CommandJob $ij 'Work Order Intake' '*/2 * * * *' $intArgv $Root
  $ienv=Get-OptionalPropertyValue (Get-OptionalPropertyValue $ij 'payload') 'env';if([string](Get-OptionalPropertyValue $ienv 'KEVIN_GH_AUTH_MODE') -cne 'stored'){throw 'Work Order Intake lost stored credential mode.'};Good "Scheduler identities frozen: Dispatcher=$dispId Intake=$intId Reconciler=$recId Telemetry=$telId"

  Step 'Fetch repaired components by immutable Git blob identity'
  $staged=@{}
  foreach($p in @($WorkerPath,$DispatcherPath,$IntakePath)){$blob=[string]$NewPins[$p];$dest=Join-Path $tempDir (Split-Path $p -Leaf);[IO.File]::WriteAllBytes($dest,(Get-GitBlobBytes $blob));$actual=Get-GitBlobSha1 $dest;if($actual -ne $blob){throw "Staged blob mismatch for $(Split-Path $p -Leaf)"};Parse-PowerShellFile $dest;$staged[$p]=$dest;Good "$(Split-Path $p -Leaf) staged: $blob"}

  Step 'Back up and atomically install only the three repaired Control Plane files'
  foreach($p in @($WorkerPath,$DispatcherPath,$IntakePath)){$backup=Join-Path $BackupDir ("$Stamp-"+(Split-Path $p -Leaf));Copy-Item -LiteralPath $p -Destination $backup -Force;$backups.Add([pscustomobject]@{target=$p;backup=$backup});[IO.File]::WriteAllBytes($p,[IO.File]::ReadAllBytes([string]$staged[$p]));$a=Get-GitBlobSha1 $p;if($a -ne [string]$NewPins[$p]){throw "Installed blob mismatch: $p"}}
  Good 'Repaired worker, dispatcher, and intake installed with exact identity.'

  Step 'Run local deterministic self-tests and fail-closed negative test'
  foreach($x in @(@($WorkerPath,'SelfTest','MISSION_WORKER_SELF_TEST_PASS'),@($DispatcherPath,'SelfTest','MISSION_DISPATCHER_SELF_TEST_PASS'),@($IntakePath,'SelfTest','WORK_ORDER_INTAKE_SELF_TEST_PASS'))){$r=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',[string]$x[0],'-Mode',[string]$x[1]) -TimeoutSeconds 90 -WorkingDirectory $Workspace;if($r.ExitCode -ne 0 -or (One-Line $r.Stdout) -notmatch [regex]::Escape([string]$x[2])){throw "Self-test failed: $(Split-Path ([string]$x[0]) -Leaf) $(One-Line ($r.Stdout+' '+$r.Stderr))"};Good (One-Line $r.Stdout)}
  $neg=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','Run','-MissionId','__not_allowlisted__') -TimeoutSeconds 45 -WorkingDirectory $Workspace;if($neg.ExitCode -eq 0 -or (One-Line ($neg.Stdout+' '+$neg.Stderr)) -notmatch 'not in the local hash-pinned catalog'){throw 'Unallowlisted mission negative test failed.'};Good 'Worker still rejects unallowlisted mission before model execution.'

  Step 'Retire only the obsolete JSON-format failure cooldown when local evidence matches'
  $ws=Read-JsonFile $WorkerStatePath;$ds=Read-JsonFile $DispatcherStatePath
  if($ws -and $ds -and [string](Get-OptionalPropertyValue $ws 'state') -eq 'INFRA_FAILURE' -and [string](Get-OptionalPropertyValue $ws 'error') -match 'Model response contained no JSON object|JSON contract failed after one bounded format-recovery attempt' -and [string](Get-OptionalPropertyValue $ds 'failure_family') -eq [string](Get-OptionalPropertyValue $ws 'mission_id')){
    $stateBackup=Join-Path $BackupDir ("$Stamp-mission-dispatcher-state-v1.json");Copy-Item -LiteralPath $DispatcherStatePath -Destination $stateBackup -Force;$ds.failure_family='';$ds.attempts=0;$ds.cooldown_until=$null;$ds.last_result='CONTROL_PLANE_V11_REPAIR_READY';$ds.updated_at=(Get-Date).ToString('o');Write-JsonAtomic $ds $DispatcherStatePath;$stateReset=$true;Good 'Exact obsolete JSON-format failure cooldown cleared; mission queue preserved.'
  }else{Note 'No exact obsolete JSON-format cooldown matched; dispatcher state left unchanged.'}

  Step 'Verify repaired files are live behind the same scheduler jobs'
  $after=Invoke-OclJson @('cron','list','--all','--json');$afterJobs=@();if($after){$j=Get-OptionalPropertyValue $after 'jobs';if($j){$afterJobs=@($j)}}
  foreach($pair in @(@('Kevin Mission Dispatcher v1',$dispId),@('Kevin Work Order Intake v1',$intId),@('Kevin Autonomy Reconciler v0.1',$recId),@('Kevin Autonomy Telemetry v0.1',$telId))){$m=@($afterJobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq [string]$pair[0]});if($m.Count -ne 1 -or [string](Get-OptionalPropertyValue $m[0] 'id') -cne [string]$pair[1]){throw "Scheduler identity changed: $($pair[0])"}}
  $dj2=Invoke-OclJson @('cron','get',$dispId);$ij2=Invoke-OclJson @('cron','get',$intId);Assert-CommandJob $dj2 'Mission Dispatcher' '*/3 * * * *' $dispArgv $Root;Assert-CommandJob $ij2 'Work Order Intake' '*/2 * * * *' $intArgv $Root;Good 'All scheduler IDs, argv, cadence, and autonomy jobs remained unchanged.'
  $poll=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$IntakePath,'-Mode','Poll') -TimeoutSeconds 120 -WorkingDirectory $Workspace;if($poll.ExitCode -ne 0 -or (One-Line $poll.Stdout) -notmatch 'WORK_ORDER_NONE'){throw "Repaired Intake empty-inbox proof failed: $(One-Line ($poll.Stdout+' '+$poll.Stderr))"};Good 'Repaired Work Order Intake confirmed empty inbox.'

  Step 'Write v1.1 repair evidence and rollback'
  $manifest=[ordered]@{schema=1;kind='kevin-control-plane-repair';version='1.1';installed_at=(Get-Date).ToString('o');old_blobs=$OldPins;new_blobs=$NewPins;state_reset=[bool]$stateReset;jobs=[ordered]@{mission_dispatcher=$dispId;work_order_intake=$intId;reconciler=$recId;telemetry=$telId};safety=[ordered]@{scheduler_jobs_recreated=$false;production_chat_changed=$false;reader_changed=$false;autonomy_roots_changed=$false;arbitrary_shell=$false;automatic_candidate_promotion=$false}}
  $manifestPath=Join-Path $Root 'install-manifest-control-plane-v1.1.json';[IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 20),$Utf8);$proofPath=Join-Path $EvidenceDir ("$Stamp-control-plane-v1.1-repair-proof.json");[IO.File]::WriteAllText($proofPath,($manifest|ConvertTo-Json -Depth 20),$Utf8)
  $rollbackPath=Join-Path $Root 'ROLLBACK-CONTROL-PLANE-v1.1.ps1';$rb=New-Object System.Collections.Generic.List[string];$rb.Add("`$ErrorActionPreference='Stop'");foreach($b in $backups){$rb.Add(("Copy-Item -LiteralPath '{0}' -Destination '{1}' -Force" -f ([string]$b.backup).Replace("'","''"),([string]$b.target).Replace("'","''")))};if($stateBackup){$rb.Add(("Copy-Item -LiteralPath '{0}' -Destination '{1}' -Force" -f $stateBackup.Replace("'","''"),$DispatcherStatePath.Replace("'","''")))};$rb.Add("Write-Host 'Kevin Control Plane v1.1 rollback completed; scheduler jobs were never changed.'");[IO.File]::WriteAllLines($rollbackPath,$rb,$Utf8)
  Good "Manifest: $manifestPath";Good "Rollback: $rollbackPath"

  Write-Host ''
  Write-Host '============================================================' -ForegroundColor Green
  Write-Host 'KEVIN CONTROL PLANE v1.1 REPAIR INSTALLED + PROVEN' -ForegroundColor Green
  Write-Host '============================================================' -ForegroundColor Green
  Write-Host 'JSON format recovery: one bounded retry, same proven Qwen lane'
  Write-Host 'Failed typed orders: terminalized by idempotency key; no accidental replay loop'
  Write-Host 'Failure diagnostics: sanitized root cause returned through existing acknowledgement channel'
  Write-Host "Mission Dispatcher: unchanged ($dispId)"
  Write-Host "Work Order Intake: unchanged ($intId)"
  Write-Host "Reconciler + Telemetry: unchanged ($recId / $telId)"
  exit 0
}catch{
  $msg=[string]$_.Exception.Message;Note ("Repair stopped safely: "+$msg)
  foreach($b in @($backups)){try{if(Test-Path -LiteralPath ([string]$b.backup)){Copy-Item -LiteralPath ([string]$b.backup) -Destination ([string]$b.target) -Force}}catch{}}
  if($stateBackup -and (Test-Path -LiteralPath $stateBackup)){try{Copy-Item -LiteralPath $stateBackup -Destination $DispatcherStatePath -Force}catch{}}
  throw
}finally{Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue}
