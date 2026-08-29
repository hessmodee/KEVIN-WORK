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
  $psi=New-Object System.Diagnostics.ProcessStartInfo;$psi.FileName=$Executable;$psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ');$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory}
  $p=New-Object System.Diagnostics.Process;$p.StartInfo=$psi;if(-not $p.Start()){throw "Could not start native process: $Executable"};$ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();$to=$false;if($TimeoutSeconds -gt 0){if(-not $p.WaitForExit($TimeoutSeconds*1000)){$to=$true;try{$p.Kill()}catch{};$p.WaitForExit()}}else{$p.WaitForExit()};$r=[pscustomobject]@{ExitCode=$(if($to){124}else{[int]$p.ExitCode});Stdout=[string]$ot.Result;Stderr=[string]$et.Result;TimedOut=$to};$p.Dispose();return $r
}
function Test-ExactNativeJsonTransport {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js required.'}
  $probe=Join-Path $env:TEMP ("kevin-cp12-argv-{0}.js" -f [guid]::NewGuid().ToString('N'))
  $js=@'
const a=process.argv.slice(2);const i=a.indexOf('--command-argv');if(i<0||i+1>=a.length)process.exit(31);let p;try{p=JSON.parse(a[i+1]);}catch{process.exit(32);}const ok=Array.isArray(p)&&p.length===4&&p[0]==='powershell.exe'&&p[1]==='C:\\Path With Space\\x.ps1'&&p[2]==='A"B'&&p[3]==='tail\\';process.exit(ok?0:33);
'@
  [IO.File]::WriteAllText($probe,$js,$Utf8);try{$j=@('powershell.exe','C:\Path With Space\x.ps1','A"B','tail\')|ConvertTo-Json -Compress;$r=Invoke-ExactNative -Executable $node.Source -Argv @($probe,'--command-argv',$j) -TimeoutSeconds 30;if($r.ExitCode -ne 0){throw "Exact argv transport failed: $($r.ExitCode)"}}finally{Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue}
}
if($Mode -eq 'ValidateTransport'){Test-ExactNativeJsonTransport;Write-Output 'CONTROL_PLANE_V12_TRANSPORT_OK';exit 0}

$Repo='hessmodee/KEVIN-WORK';$OrderBranch='kevin-control-plane-v1'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace';$Root=Join-Path $Workspace 'ControlPlane';$StateDir=Join-Path $Root 'State';$BackupDir=Join-Path $Root 'Backups';$EvidenceDir=Join-Path $Root 'Evidence'
foreach($d in @($Root,$StateDir,$BackupDir,$EvidenceDir)){if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}}
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
$WorkerPath=Join-Path $Root 'kevin-mission-worker-v0.1.ps1';$DispatcherPath=Join-Path $Root 'kevin-mission-dispatcher-v0.1.ps1';$IntakePath=Join-Path $Root 'kevin-work-order-intake-v0.1.ps1';$CatalogPath=Join-Path $Root 'mission-catalog-v1.json';$DispatcherStatePath=Join-Path $StateDir 'mission-dispatcher-state-v1.json';$WorkerStatePath=Join-Path $StateDir 'mission-worker-state-v1.json'
$OldWorker='3b02fb4acfadb715a017641b622179a9cf422eb0';$NewWorker='a3e9797aca21aa99121148e21473beeccde1f63f'
$InvariantPins=[ordered]@{
  (Join-Path $Root 'desired-state-v1.json')='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
  (Join-Path $Root 'OWNER-AUTHORIZATION-v1.md')='b0cc4465f12457492b3a6c2761287398cc6295b5'
  (Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1')='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
  (Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1')='2b0a4f168b2d5f64b1979063eaf62807373e25ce'
  $CatalogPath='743db880f6529f59341f2e0f89da533091392001'
  $DispatcherPath='766fa55163b238f04ca54cc18164363b962a777e'
  $IntakePath='b21488796d967da6b892190538d61b4e58d072f5'
}
$ExpectedJobs=[ordered]@{
  'Kevin Mission Dispatcher v1'='d3a2078b-bb1a-438b-8a40-2a6b6c836e5f'
  'Kevin Work Order Intake v1'='befc526f-5f59-4216-9339-cfd998d303f0'
  'Kevin Autonomy Reconciler v0.1'='b2b620e7-b217-471f-be51-dea33f6bc839'
  'Kevin Autonomy Telemetry v0.1'='5ab49387-6664-4620-a9a1-1b0165a3b9d3'
}

function Get-GitBlobSha1([string]$Path){$b=[IO.File]::ReadAllBytes($Path);$h=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $b.Length));$all=New-Object byte[] ($h.Length+1+$b.Length);[Buffer]::BlockCopy($h,0,$all,0,$h.Length);$all[$h.Length]=0;[Buffer]::BlockCopy($b,0,$all,$h.Length+1,$b.Length);$sha=[Security.Cryptography.SHA1]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
function Parse-PowerShellFile([string]$Path){$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors);if($errors -and $errors.Count){$m=($errors|ForEach-Object{"line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; ';throw "Parser rejected $(Split-Path $Path -Leaf): $m"}}
function Read-JsonFile([string]$Path){if(-not(Test-Path -LiteralPath $Path)){return $null};try{return (Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)}catch{return $null}}
function Write-JsonAtomic($Object,[string]$Path){$tmp="$Path.tmp-$PID";[IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),$Utf8);Move-Item -LiteralPath $tmp -Destination $Path -Force}
function Resolve-Gh {$g=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not $g){$g=Get-Command gh -ErrorAction SilentlyContinue};if(-not $g){throw 'GitHub CLI not found.'};return $g.Source}
function Use-StoredGhCredential {foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath ("Env:{0}" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}
Use-StoredGhCredential;$script:GhExe=Resolve-Gh
function Invoke-Gh([string[]]$Argv){return Invoke-ExactNative -Executable $script:GhExe -Argv $Argv -TimeoutSeconds 90 -WorkingDirectory $Workspace}
function Get-GitBlobBytes([string]$Blob){$r=Invoke-Gh @('api',("repos/{0}/git/blobs/{1}" -f $Repo,$Blob));if($r.ExitCode -ne 0){throw "GitHub blob fetch failed for ${Blob}: $(One-Line ($r.Stdout+' '+$r.Stderr))"};$o=$r.Stdout|ConvertFrom-Json;if(([string](Get-OptionalPropertyValue $o 'sha')).ToLowerInvariant() -ne $Blob){throw "Blob identity mismatch: $Blob"};if([string](Get-OptionalPropertyValue $o 'encoding') -ne 'base64'){throw "Unexpected GitHub blob encoding: $Blob"};return [Convert]::FromBase64String(([string](Get-OptionalPropertyValue $o 'content') -replace '\s',''))}
function Get-OpenClawNodeLauncher {$node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js missing.'};$shim=Get-Command openclaw.cmd -ErrorAction SilentlyContinue;if(-not $shim){$shim=Get-Command openclaw -ErrorAction SilentlyContinue};if(-not $shim){throw 'OpenClaw CLI missing.'};$pkgDir=Join-Path (Split-Path -Parent $shim.Source) 'node_modules\openclaw';$pkg=Get-Content -LiteralPath (Join-Path $pkgDir 'package.json') -Raw|ConvertFrom-Json;$binRel=if($pkg.bin -is [string]){[string]$pkg.bin}else{[string]$pkg.bin.openclaw};return [pscustomobject]@{Node=$node.Source;Cli=(Join-Path $pkgDir $binRel);Version=[string]$pkg.version}}
function ConvertFrom-OpenClawJson([string]$Text){if([string]::IsNullOrWhiteSpace($Text)){return $null};$t=$Text.Trim();try{return ($t|ConvertFrom-Json)}catch{};$t=[regex]::Replace($t,"`e\[[0-9;?]*[ -/]*[@-~]",'');$starts=@($t.IndexOf('{'),$t.IndexOf('['))|Where-Object{$_ -ge 0}|Sort-Object;foreach($s in $starts){try{return ($t.Substring([int]$s)|ConvertFrom-Json)}catch{}};throw 'OpenClaw stdout was not valid JSON.'}
$script:Ocl=$null
function Invoke-OclRaw([string[]]$Argv){if(-not $script:Ocl){$script:Ocl=Get-OpenClawNodeLauncher};return Invoke-ExactNative -Executable $script:Ocl.Node -Argv (@($script:Ocl.Cli)+@($Argv)) -TimeoutSeconds 120 -WorkingDirectory $Workspace}
function Invoke-OclJson([string[]]$Argv){$r=Invoke-OclRaw $Argv;if($r.ExitCode -ne 0){throw "OpenClaw failed: $(One-Line ($r.Stdout+' '+$r.Stderr))"};return (ConvertFrom-OpenClawJson $r.Stdout)}
function Get-Jobs {$o=Invoke-OclJson @('cron','list','--all','--json');$j=Get-OptionalPropertyValue $o 'jobs';if(-not $j){return @()};return @($j)}
function Assert-ExpectedJobs([object[]]$Jobs){foreach($kv in $ExpectedJobs.GetEnumerator()){$m=@($Jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq [string]$kv.Key});if($m.Count -ne 1){throw "Expected exactly one scheduler job: $($kv.Key)"};if([string](Get-OptionalPropertyValue $m[0] 'id') -cne [string]$kv.Value){throw "Scheduler identity drift: $($kv.Key)"};if(-not [bool](Get-OptionalPropertyValue $m[0] 'enabled')){throw "Scheduler job disabled: $($kv.Key)"}}}

$temp=Join-Path $env:TEMP ("kevin-cp12-{0}" -f [guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $temp -Force|Out-Null
$workerBackup='';$stateBackup='';$stateReset=$false;$installed=$false
try{
  Step 'Verify frozen autonomy roots and Control Plane v1.1 invariants'
  foreach($kv in $InvariantPins.GetEnumerator()){if(-not(Test-Path -LiteralPath $kv.Key)){throw "Missing invariant component: $($kv.Key)"};$a=Get-GitBlobSha1 $kv.Key;if($a -ne [string]$kv.Value){throw "Invariant drift: $(Split-Path $kv.Key -Leaf) expected $($kv.Value), got $a"};Good "$(Split-Path $kv.Key -Leaf) unchanged: $a"}
  if(-not(Test-Path -LiteralPath $WorkerPath)){throw 'Mission worker missing.'};$workerBefore=Get-GitBlobSha1 $WorkerPath;if($workerBefore -ne $OldWorker -and $workerBefore -ne $NewWorker){throw "Unexpected mission worker identity: $workerBefore"};Good "Mission worker recognized: $workerBefore"

  Step 'Prove exact transport, runtime, stored GitHub credential, and empty typed-order inbox'
  Test-ExactNativeJsonTransport;Good 'WinPS 5.1 exact argv transport passed.';$script:Ocl=Get-OpenClawNodeLauncher;if($script:Ocl.Version -ne '2026.7.1-2'){throw "Expected OpenClaw 2026.7.1-2, found $($script:Ocl.Version)"};Good 'OpenClaw 2026.7.1-2 resolved.'
  $auth=Invoke-Gh @('auth','status','--hostname','github.com');if($auth.ExitCode -ne 0){throw "Stored GitHub credential unavailable: $(One-Line ($auth.Stdout+' '+$auth.Stderr))"};Good 'Stored GitHub CLI credential available.'
  $ep=("repos/{0}/contents/control-plane/orders/CURRENT.json?ref={1}" -f $Repo,[Uri]::EscapeDataString($OrderBranch));$pending=Invoke-Gh @('api',$ep,'-H','Accept: application/vnd.github+json');if($pending.ExitCode -eq 0){throw 'A CURRENT work order exists; refusing review repair while intake has pending work.'};$pt=One-Line ($pending.Stdout+' '+$pending.Stderr);if($pt -notmatch '404|Not Found'){throw "Could not prove empty work-order inbox: $pt"};Good 'Remote CURRENT work-order inbox is empty.'

  Step 'Freeze scheduler identities before worker mutation'
  $beforeJobs=Get-Jobs;Assert-ExpectedJobs $beforeJobs;Good 'Dispatcher, Intake, Reconciler, and Telemetry scheduler identities frozen.'

  Step 'Fetch v1.2 worker by immutable Git blob identity'
  $staged=Join-Path $temp 'kevin-mission-worker-v0.1.ps1';[IO.File]::WriteAllBytes($staged,(Get-GitBlobBytes $NewWorker));if((Get-GitBlobSha1 $staged) -ne $NewWorker){throw 'Staged v1.2 worker blob mismatch.'};Parse-PowerShellFile $staged;Good "v1.2 worker staged: $NewWorker"

  Step 'Back up and atomically install only the worker'
  if($workerBefore -eq $OldWorker){$workerBackup=Join-Path $BackupDir ("$Stamp-kevin-mission-worker-v0.1.ps1");Copy-Item -LiteralPath $WorkerPath -Destination $workerBackup -Force;$tmpTarget="$WorkerPath.tmp-$PID";[IO.File]::WriteAllBytes($tmpTarget,[IO.File]::ReadAllBytes($staged));Move-Item -LiteralPath $tmpTarget -Destination $WorkerPath -Force;$installed=$true}else{Note 'v1.2 worker already installed; preserving existing file.'}
  if((Get-GitBlobSha1 $WorkerPath) -ne $NewWorker){throw 'Installed v1.2 worker identity mismatch.'};Good 'Only mission worker changed; exact v1.2 identity proven.'

  Step 'Run worker self-test and fail-closed negative test'
  $self=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','SelfTest') -TimeoutSeconds 90 -WorkingDirectory $Workspace;if($self.ExitCode -ne 0 -or (One-Line $self.Stdout) -notmatch 'MISSION_WORKER_SELF_TEST_PASS' -or (One-Line $self.Stdout) -notmatch 'line_fallback=1'){throw "v1.2 worker self-test failed: $(One-Line ($self.Stdout+' '+$self.Stderr))"};Good (One-Line $self.Stdout)
  $neg=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','Run','-MissionId','__not_allowlisted__') -TimeoutSeconds 45 -WorkingDirectory $Workspace;if($neg.ExitCode -eq 0 -or (One-Line ($neg.Stdout+' '+$neg.Stderr)) -notmatch 'not in the local hash-pinned catalog'){throw 'Unallowlisted mission negative test failed.'};Good 'Worker still rejects unallowlisted mission before model execution.'

  Step 'Retire only the exact reviewer JSON-contract cooldown when evidence matches'
  $ws=Read-JsonFile $WorkerStatePath;$ds=Read-JsonFile $DispatcherStatePath
  if($ws -and $ds -and [string](Get-OptionalPropertyValue $ws 'state') -eq 'INFRA_FAILURE' -and [string](Get-OptionalPropertyValue $ws 'error') -eq 'Review model JSON contract failed after one bounded format-recovery attempt.' -and [string](Get-OptionalPropertyValue $ds 'failure_family') -eq [string](Get-OptionalPropertyValue $ws 'mission_id')){$stateBackup=Join-Path $BackupDir ("$Stamp-mission-dispatcher-state-v1.json");Copy-Item -LiteralPath $DispatcherStatePath -Destination $stateBackup -Force;$ds.failure_family='';$ds.attempts=0;$ds.cooldown_until=$null;$ds.last_result='CONTROL_PLANE_V12_REVIEW_PROTOCOL_READY';$ds.updated_at=(Get-Date).ToString('o');Write-JsonAtomic $ds $DispatcherStatePath;$stateReset=$true;Good 'Exact reviewer JSON-contract cooldown cleared; mission queue preserved.'}else{Note 'No exact reviewer JSON-contract cooldown matched; dispatcher state left unchanged.'}

  Step 'Verify scheduler identities remained unchanged'
  $afterJobs=Get-Jobs;Assert-ExpectedJobs $afterJobs;Good 'All four scheduler identities remained unchanged.'

  Step 'Write v1.2 repair evidence and rollback'
  $manifest=[ordered]@{schema=1;kind='kevin-control-plane-repair';version='1.2';installed_at=(Get-Date).ToString('o');worker_blob=$NewWorker;previous_worker_blob=$workerBefore;worker_installed=[bool]$installed;dispatcher_state_reset=[bool]$stateReset;scheduler_jobs_recreated=$false;safety=[ordered]@{green_only=$true;arbitrary_shell=$false;authority_expansion=$false;production_chat_changed=$false;reader_changed=$false;dispatcher_changed=$false;intake_changed=$false;reconciler_changed=$false;telemetry_changed=$false;automatic_candidate_promotion=$false}}
  $manifestPath=Join-Path $Root 'install-manifest-control-plane-v1.2.json';[IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 20),$Utf8);$proofPath=Join-Path $EvidenceDir ("$Stamp-control-plane-v1.2-review-repair-proof.json");[IO.File]::WriteAllText($proofPath,($manifest|ConvertTo-Json -Depth 20),$Utf8)
  $rollbackPath=Join-Path $Root 'ROLLBACK-CONTROL-PLANE-v1.2.ps1';$rb=New-Object System.Collections.Generic.List[string];$rb.Add("`$ErrorActionPreference='Stop'");if($workerBackup){$rb.Add(("Copy-Item -LiteralPath '{0}' -Destination '{1}' -Force" -f $workerBackup.Replace("'","''"),$WorkerPath.Replace("'","''")))};if($stateBackup){$rb.Add(("Copy-Item -LiteralPath '{0}' -Destination '{1}' -Force" -f $stateBackup.Replace("'","''"),$DispatcherStatePath.Replace("'","''")))};$rb.Add("Write-Host 'Kevin Control Plane v1.2 rollback completed.'");[IO.File]::WriteAllLines($rollbackPath,$rb,$Utf8);Good "Manifest: $manifestPath";Good "Rollback: $rollbackPath"

  Write-Host ''
  Write-Host '============================================================' -ForegroundColor Green
  Write-Host 'KEVIN CONTROL PLANE v1.2 REVIEW REPAIR INSTALLED + PROVEN' -ForegroundColor Green
  Write-Host '============================================================' -ForegroundColor Green
  Write-Host 'Worker: bounded JSON retry + materially different line-protocol reviewer fallback'
  Write-Host 'Reviewer fallback: one final bounded attempt; deterministic local parser; fail closed'
  Write-Host 'Dispatcher + Intake + Reconciler + Telemetry: unchanged'
  Write-Host 'Production Chat + Reader + authority boundaries: unchanged'
  exit 0
}catch{
  $msg=[string]$_.Exception.Message
  if($installed -and $workerBackup -and (Test-Path -LiteralPath $workerBackup)){try{Copy-Item -LiteralPath $workerBackup -Destination $WorkerPath -Force}catch{}}
  if($stateReset -and $stateBackup -and (Test-Path -LiteralPath $stateBackup)){try{Copy-Item -LiteralPath $stateBackup -Destination $DispatcherStatePath -Force}catch{}}
  throw
}finally{Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue}
