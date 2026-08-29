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
  $sb=New-Object System.Text.StringBuilder
  [void]$sb.Append('"');$slashes=0
  for($i=0;$i -lt $Value.Length;$i++){
    $ch=$Value[$i]
    if($ch -eq '\'){$slashes++;continue}
    if($ch -eq '"'){
      if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))}
      [void]$sb.Append('\"');$slashes=0;continue
    }
    if($slashes -gt 0){[void]$sb.Append(('\' * $slashes));$slashes=0}
    [void]$sb.Append($ch)
  }
  if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))}
  [void]$sb.Append('"')
  return $sb.ToString()
}

function Invoke-ExactNative {
  param(
    [Parameter(Mandatory=$true)][string]$Executable,
    [Parameter(Mandatory=$true)][string[]]$Argv,
    [int]$TimeoutSeconds=0,
    [string]$WorkingDirectory=''
  )
  $psi=New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Executable
  $psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ')
  $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory}
  $p=New-Object System.Diagnostics.Process;$p.StartInfo=$psi
  if(-not $p.Start()){throw "Could not start native process: $Executable"}
  $outTask=$p.StandardOutput.ReadToEndAsync();$errTask=$p.StandardError.ReadToEndAsync();$timedOut=$false
  if($TimeoutSeconds -gt 0){if(-not $p.WaitForExit($TimeoutSeconds*1000)){$timedOut=$true;try{$p.Kill()}catch{};$p.WaitForExit()}}else{$p.WaitForExit()}
  $r=[pscustomobject]@{ExitCode=$(if($timedOut){124}else{[int]$p.ExitCode});Stdout=[string]$outTask.Result;Stderr=[string]$errTask.Result;TimedOut=$timedOut;CommandLine=$psi.Arguments}
  $p.Dispose();return $r
}

function Test-ExactNativeJsonTransport {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js required.'}
  $probe=Join-Path $env:TEMP ("kevin-cp-argv-probe-{0}.js" -f [guid]::NewGuid().ToString('N'))
  $js=@'
const a=process.argv.slice(2);const i=a.indexOf('--command-argv');if(i<0||i+1>=a.length)process.exit(31);let p;try{p=JSON.parse(a[i+1]);}catch{process.exit(32);}const ok=Array.isArray(p)&&p.length===4&&p[0]==='powershell.exe'&&p[1]==='C:\\Path With Space\\x.ps1'&&p[2]==='A"B'&&p[3]==='tail\\';process.exit(ok?0:33);
'@
  [IO.File]::WriteAllText($probe,$js,$Utf8)
  try{$json=@('powershell.exe','C:\Path With Space\x.ps1','A"B','tail\')|ConvertTo-Json -Compress;$r=Invoke-ExactNative -Executable $node.Source -Argv @($probe,'--command-argv',$json) -TimeoutSeconds 30;if($r.ExitCode -ne 0){throw "Exact native transport failed exit=$($r.ExitCode)"}}finally{Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue}
  return $true
}

if($Mode -eq 'ValidateTransport'){[void](Test-ExactNativeJsonTransport);Write-Output 'CONTROL_PLANE_TRANSPORT_OK';exit 0}

$Repo='hessmodee/KEVIN-WORK'
$OrderBranch='kevin-control-plane-v1'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Root=Join-Path $Workspace 'ControlPlane'
$SchemaDir=Join-Path $Root 'Schemas'
$BackupDir=Join-Path $Root 'Backups'
$EvidenceDir=Join-Path $Root 'Evidence'
foreach($d in @($Root,$SchemaDir,$BackupDir,$EvidenceDir)){if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}}
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')

$ExistingPins=[ordered]@{
  (Join-Path $Root 'desired-state-v1.json')='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
  (Join-Path $Root 'OWNER-AUTHORIZATION-v1.md')='b0cc4465f12457492b3a6c2761287398cc6295b5'
  (Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1')='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
  (Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1')='2b0a4f168b2d5f64b1979063eaf62807373e25ce'
}
$Components=[ordered]@{
  'mission-catalog-v1.json'='743db880f6529f59341f2e0f89da533091392001'
  'kevin-mission-worker-v0.1.ps1'='5546b2bc5d6eb87b7f25b3d72214e99fe6636ba8'
  'kevin-mission-dispatcher-v0.1.ps1'='893d2fac2e0ffb5aa536d9d6b02eb49164018d10'
  'kevin-work-order-intake-v0.1.ps1'='75709657b6d34ffb24a9e6a9dc968d07e0467557'
  'work-order-v1.schema.json'='c030d84c1da9de2d1df4f3a9b067dbd4ac8935c9'
}

$CatalogPath=Join-Path $Root 'mission-catalog-v1.json'
$WorkerPath=Join-Path $Root 'kevin-mission-worker-v0.1.ps1'
$DispatcherPath=Join-Path $Root 'kevin-mission-dispatcher-v0.1.ps1'
$IntakePath=Join-Path $Root 'kevin-work-order-intake-v0.1.ps1'
$SchemaPath=Join-Path $SchemaDir 'work-order-v1.schema.json'
$ActuatorPath=Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1'
$BridgePath=Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1'

function Get-GitBlobSha1 {
  param([Parameter(Mandatory=$true)][string]$Path)
  $bytes=[IO.File]::ReadAllBytes($Path);$header=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $bytes.Length));$all=New-Object byte[] ($header.Length+1+$bytes.Length)
  [Buffer]::BlockCopy($header,0,$all,0,$header.Length);$all[$header.Length]=0;[Buffer]::BlockCopy($bytes,0,$all,$header.Length+1,$bytes.Length)
  $sha=[Security.Cryptography.SHA1]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
}
function Parse-PowerShellFile([string]$Path){$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors);if($errors -and $errors.Count){$m=($errors|ForEach-Object{"line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; ';throw "PowerShell parser rejected $(Split-Path $Path -Leaf): $m"}}
function Get-OptionalPropertyValue($Object,[string]$Name){if($null -eq $Object){return $null};$p=$Object.PSObject.Properties[$Name];if($null -eq $p){return $null};return $p.Value}

function Resolve-Gh {$g=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not $g){$g=Get-Command gh -ErrorAction SilentlyContinue};if(-not $g){throw 'GitHub CLI not found.'};return $g.Source}
function Use-StoredGhCredential {foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath ("Env:{0}" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}
Use-StoredGhCredential
$script:GhExe=Resolve-Gh
function Invoke-Gh {param([Parameter(Mandatory=$true)][string[]]$Argv);return Invoke-ExactNative -Executable $script:GhExe -Argv $Argv -TimeoutSeconds 90 -WorkingDirectory $Workspace}
function Get-GitBlobBytes {param([Parameter(Mandatory=$true)][string]$Blob);$r=Invoke-Gh -Argv @('api',("repos/{0}/git/blobs/{1}" -f $Repo,$Blob));if($r.ExitCode -ne 0){throw "GitHub blob fetch failed for ${Blob}: $(One-Line ($r.Stdout+' '+$r.Stderr))"};$o=$r.Stdout|ConvertFrom-Json;if(([string](Get-OptionalPropertyValue $o 'sha')).ToLowerInvariant() -ne $Blob.ToLowerInvariant()){throw "GitHub blob identity mismatch for $Blob"};if([string](Get-OptionalPropertyValue $o 'encoding') -ne 'base64'){throw "Unexpected GitHub blob encoding for $Blob"};return [Convert]::FromBase64String(([string](Get-OptionalPropertyValue $o 'content') -replace '\s',''))}

function Get-OpenClawNodeLauncher {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js not found.'}
  $shim=Get-Command openclaw.cmd -ErrorAction SilentlyContinue;if(-not $shim){$shim=Get-Command openclaw -ErrorAction SilentlyContinue};if(-not $shim){throw 'OpenClaw CLI not found.'}
  $pkgDir=Join-Path (Split-Path -Parent $shim.Source) 'node_modules\openclaw';$pkgPath=Join-Path $pkgDir 'package.json';if(-not(Test-Path -LiteralPath $pkgPath)){throw "OpenClaw package.json missing: $pkgPath"}
  $pkg=Get-Content -LiteralPath $pkgPath -Raw|ConvertFrom-Json;$binRel=if($pkg.bin -is [string]){[string]$pkg.bin}else{[string]$pkg.bin.openclaw}
  return [pscustomobject]@{Node=$node.Source;Cli=(Join-Path $pkgDir $binRel);Version=[string]$pkg.version}
}
function ConvertFrom-OpenClawJson {param([AllowEmptyString()][string]$Text);if([string]::IsNullOrWhiteSpace($Text)){return $null};$t=$Text.Trim();try{return ($t|ConvertFrom-Json)}catch{};$t=[regex]::Replace($t,"`e\[[0-9;?]*[ -/]*[@-~]",'');$starts=@($t.IndexOf('{'),$t.IndexOf('['))|Where-Object{$_ -ge 0}|Sort-Object;foreach($s in $starts){try{return ($t.Substring([int]$s)|ConvertFrom-Json)}catch{}};throw 'OpenClaw stdout was not valid JSON.'}
$script:Ocl=$null
function Invoke-OclRaw {param([Parameter(Mandatory=$true)][string[]]$Argv);if(-not $script:Ocl){$script:Ocl=Get-OpenClawNodeLauncher};return Invoke-ExactNative -Executable $script:Ocl.Node -Argv (@($script:Ocl.Cli)+@($Argv)) -TimeoutSeconds 660 -WorkingDirectory $Workspace}
function Invoke-OclJson {param([Parameter(Mandatory=$true)][string[]]$Argv);$r=Invoke-OclRaw -Argv $Argv;$obj=$null;try{$obj=ConvertFrom-OpenClawJson $r.Stdout}catch{};if($r.ExitCode -ne 0){throw "OpenClaw failed: $($Argv -join ' ') :: stdout=$(One-Line $r.Stdout) :: stderr=$(One-Line $r.Stderr)"};return $obj}
function Resolve-JobId {param($Object,[string]$Label);if($null -eq $Object){throw "Could not resolve $Label job id: null response."};foreach($n in @('id','jobId')){$v=Get-OptionalPropertyValue $Object $n;if($v){return [string]$v}};$job=Get-OptionalPropertyValue $Object 'job';if($job){$v=Get-OptionalPropertyValue $job 'id';if($v){return [string]$v}};$result=Get-OptionalPropertyValue $Object 'result';if($result){$v=Get-OptionalPropertyValue $result 'id';if($v){return [string]$v}};throw "Could not resolve $Label job id. Properties: $(@($Object.PSObject.Properties.Name)-join ',')"}
function Assert-StringArrayEqual {param([string[]]$Actual,[string[]]$Expected,[string]$Label);if(@($Actual).Count -ne @($Expected).Count){throw "$Label argv length mismatch."};for($i=0;$i -lt @($Expected).Count;$i++){if([string]$Actual[$i] -cne [string]$Expected[$i]){throw "$Label argv mismatch at index $i. Expected '$($Expected[$i])', got '$($Actual[$i])'."}}}
function Assert-CommandJob {param($Job,[string]$Label,[string]$Expr,[string[]]$Argv,[string]$Cwd);if(-not $Job){throw "$Label cron get returned no job."};if(-not [bool](Get-OptionalPropertyValue $Job 'enabled')){throw "$Label job disabled."};$payload=Get-OptionalPropertyValue $Job 'payload';if(-not $payload -or [string](Get-OptionalPropertyValue $payload 'kind') -ne 'command'){throw "$Label payload is not command kind."};Assert-StringArrayEqual -Actual @((Get-OptionalPropertyValue $payload 'argv')) -Expected $Argv -Label $Label;if([string](Get-OptionalPropertyValue $payload 'cwd') -cne $Cwd){throw "$Label cwd mismatch."};$schedule=Get-OptionalPropertyValue $Job 'schedule';if(-not $schedule -or [string](Get-OptionalPropertyValue $schedule 'kind') -ne 'cron' -or [string](Get-OptionalPropertyValue $schedule 'expr') -cne $Expr){throw "$Label schedule mismatch."}}
function Get-LatestRunEntry {param([string]$JobId);$h=Invoke-OclJson -Argv @('cron','runs','--id',$JobId,'--limit','3');if(-not $h){return $null};$e=Get-OptionalPropertyValue $h 'entries';if(-not $e){$e=Get-OptionalPropertyValue $h 'runs'};$items=@($e);if($items.Count){return $items[0]};return $null}
function Run-CronAndRequireOk {param([string]$JobId,[string]$Label,[string]$Wait='4m');$r=Invoke-OclRaw -Argv @('cron','run',$JobId,'--wait','--wait-timeout',$Wait,'--poll-interval','2s');$entry=Get-LatestRunEntry $JobId;$status=if($entry){[string](Get-OptionalPropertyValue $entry 'status')}else{''};if($r.ExitCode -ne 0 -or $status -ne 'ok'){$detail=if($entry){"status=$status error=$([string](Get-OptionalPropertyValue $entry 'error')) summary=$([string](Get-OptionalPropertyValue $entry 'summary'))"}else{"stdout=$(One-Line $r.Stdout) stderr=$(One-Line $r.Stderr)"};throw "$Label scheduler proof failed: $detail"};Good "$Label scheduler execution verified.";return $entry}

$createdJobs=New-Object System.Collections.Generic.List[string]
$backups=New-Object System.Collections.Generic.List[object]
$tempDir=Join-Path $env:TEMP ("kevin-control-plane-v1-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempDir -Force|Out-Null
try{
  Step 'Verify proven autonomy roots before extending Kevin'
  foreach($kv in $ExistingPins.GetEnumerator()){
    if(-not(Test-Path -LiteralPath $kv.Key)){throw "Required autonomy root missing: $($kv.Key)"}
    $actual=Get-GitBlobSha1 $kv.Key;if($actual -ne [string]$kv.Value){throw "Autonomy root drift: $(Split-Path $kv.Key -Leaf) expected $($kv.Value), got $actual"}
    Good "$(Split-Path $kv.Key -Leaf) verified: $actual"
  }

  Step 'Prove runtime, transport, and stored GitHub credential'
  [void](Test-ExactNativeJsonTransport);Good 'WinPS 5.1 exact argv transport passed.'
  $script:Ocl=Get-OpenClawNodeLauncher;if($script:Ocl.Version -ne '2026.7.1-2'){throw "Expected OpenClaw 2026.7.1-2, found $($script:Ocl.Version)"};Good 'OpenClaw 2026.7.1-2 resolved.'
  $auth=Invoke-Gh -Argv @('auth','status','--hostname','github.com');if($auth.ExitCode -ne 0){throw "Stored GitHub credential unavailable: $(One-Line ($auth.Stdout+' '+$auth.Stderr))"};Good 'Stored GitHub CLI credential available.'

  Step 'Require an empty remote work-order inbox before enabling intake'
  $orderEndpoint=("repos/{0}/contents/control-plane/orders/CURRENT.json?ref={1}" -f $Repo,[Uri]::EscapeDataString($OrderBranch));$pending=Invoke-Gh -Argv @('api',$orderEndpoint,'-H','Accept: application/vnd.github+json')
  if($pending.ExitCode -eq 0){throw 'A CURRENT work order already exists. Refusing first-install activation until the inbox is intentionally seeded after installation.'}
  $pendingText=One-Line ($pending.Stdout+' '+$pending.Stderr);if($pendingText -notmatch '404|Not Found'){throw "Could not prove empty work-order inbox: $pendingText"};Good 'Remote CURRENT work-order inbox is empty.'

  Step 'Fetch and validate immutable Control Plane v1 components'
  $tempPaths=@{}
  foreach($kv in $Components.GetEnumerator()){
    $name=[string]$kv.Key;$blob=[string]$kv.Value;$dest=Join-Path $tempDir $name;$bytes=Get-GitBlobBytes -Blob $blob;[IO.File]::WriteAllBytes($dest,$bytes);$actual=Get-GitBlobSha1 $dest;if($actual -ne $blob){throw "Downloaded component hash mismatch: $name expected $blob got $actual"};$tempPaths[$name]=$dest;Good "$name verified: $blob"
  }
  foreach($n in @('kevin-mission-worker-v0.1.ps1','kevin-mission-dispatcher-v0.1.ps1','kevin-work-order-intake-v0.1.ps1')){Parse-PowerShellFile ([string]$tempPaths[$n])}
  $catalog=Get-Content -LiteralPath ([string]$tempPaths['mission-catalog-v1.json']) -Raw|ConvertFrom-Json
  if([string](Get-OptionalPropertyValue $catalog 'kind') -ne 'kevin-mission-catalog' -or [string](Get-OptionalPropertyValue $catalog 'version') -ne '1.0'){throw 'Mission catalog contract mismatch.'}
  $policy=Get-OptionalPropertyValue $catalog 'policy';if(-not [bool](Get-OptionalPropertyValue $policy 'candidate_only') -or [bool](Get-OptionalPropertyValue $policy 'allow_arbitrary_shell') -or [bool](Get-OptionalPropertyValue $policy 'allow_production_mutation')){throw 'Mission catalog authority boundary invalid.'}
  if(@((Get-OptionalPropertyValue $catalog 'missions')).Count -ne 6){throw 'Unexpected initial mission count.'}
  $schema=Get-Content -LiteralPath ([string]$tempPaths['work-order-v1.schema.json']) -Raw|ConvertFrom-Json;$props=Get-OptionalPropertyValue $schema 'properties';$verbProp=Get-OptionalPropertyValue $props 'verb';if(@((Get-OptionalPropertyValue $verbProp 'enum')).Count -ne 5){throw 'Typed work-order verb contract mismatch.'};Good 'PowerShell and JSON contracts validated.'

  Step 'Back up and install only new Control Plane components'
  $targets=[ordered]@{
    'mission-catalog-v1.json'=$CatalogPath
    'kevin-mission-worker-v0.1.ps1'=$WorkerPath
    'kevin-mission-dispatcher-v0.1.ps1'=$DispatcherPath
    'kevin-work-order-intake-v0.1.ps1'=$IntakePath
    'work-order-v1.schema.json'=$SchemaPath
  }
  foreach($kv in $targets.GetEnumerator()){
    $sourceName=[string]$kv.Key;$target=[string]$kv.Value;$had=Test-Path -LiteralPath $target;$backup=''
    if($had){$backup=Join-Path $BackupDir ("$Stamp-"+(Split-Path $target -Leaf));Copy-Item -LiteralPath $target -Destination $backup -Force}
    $backups.Add([pscustomobject]@{target=$target;had_original=[bool]$had;backup=$backup})
    [IO.File]::WriteAllBytes($target,[IO.File]::ReadAllBytes([string]$tempPaths[$sourceName]));$actual=Get-GitBlobSha1 $target;if($actual -ne [string]$Components[$sourceName]){throw "Installed component verification failed: $sourceName"}
  }
  Good 'All new control-plane components installed with exact blob identity.'

  Step 'Run local self-tests and non-mutating dispatcher inspection'
  foreach($test in @(@($WorkerPath,'SelfTest'),@($DispatcherPath,'SelfTest'),@($IntakePath,'SelfTest'))){$r=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',[string]$test[0],'-Mode',[string]$test[1]) -TimeoutSeconds 90 -WorkingDirectory $Workspace;if($r.ExitCode -ne 0){throw "Self-test failed for $(Split-Path ([string]$test[0]) -Leaf): $(One-Line ($r.Stdout+' '+$r.Stderr))"};Good (One-Line $r.Stdout)}
  $negative=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$WorkerPath,'-Mode','Run','-MissionId','__not_allowlisted__') -TimeoutSeconds 45 -WorkingDirectory $Workspace
  if($negative.ExitCode -eq 0 -or (One-Line ($negative.Stdout+' '+$negative.Stderr)) -notmatch 'not in the local hash-pinned catalog'){throw 'Mission worker invalid-target negative test did not fail closed.'};Good 'Mission worker rejects unallowlisted mission before model execution.'
  $inspect=Invoke-ExactNative -Executable 'powershell.exe' -Argv @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$DispatcherPath,'-Mode','Inspect') -TimeoutSeconds 90 -WorkingDirectory $Workspace;if($inspect.ExitCode -ne 0){throw "Dispatcher Inspect failed: $(One-Line ($inspect.Stdout+' '+$inspect.Stderr))"};Good (One-Line $inspect.Stdout)

  Step 'Verify existing autonomy scheduler jobs and ensure no prior Control Plane v1 jobs exist'
  $list=Invoke-OclJson -Argv @('cron','list','--all','--json');$jobs=@();if($list){$j=Get-OptionalPropertyValue $list 'jobs';if($j){$jobs=@($j)}}
  $rec=@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Autonomy Reconciler v0.1'});$tel=@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Autonomy Telemetry v0.1'})
  if($rec.Count -ne 1 -or $tel.Count -ne 1){throw "Expected exactly one proven Reconciler and one proven Telemetry job; found rec=$($rec.Count) tel=$($tel.Count)"}
  $recId=[string](Get-OptionalPropertyValue $rec[0] 'id');$telId=[string](Get-OptionalPropertyValue $tel[0] 'id');Good "Existing autonomy jobs preserved: Reconciler=$recId Telemetry=$telId"
  foreach($name in @('Kevin Mission Dispatcher v1','Kevin Work Order Intake v1')){if(@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq $name}).Count -gt 0){throw "A job named '$name' already exists. Refusing ambiguous first-install mutation."}}

  Step 'Create Mission Dispatcher and Work-Order Intake jobs with exact typed argv'
  $dispatcherArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$DispatcherPath,'-Mode','Dispatch')
  $dc=Invoke-OclJson -Argv @('cron','create','*/3 * * * *','--exact','--name','Kevin Mission Dispatcher v1','--declaration-key','kevin-mission-dispatcher-v1','--session','isolated','--command-argv',($dispatcherArgv|ConvertTo-Json -Compress),'--command-cwd',$Root,'--timeout-seconds','600','--no-output-timeout-seconds','600','--output-max-bytes','65536','--no-deliver','--json')
  $dispatcherId=Resolve-JobId $dc 'Mission Dispatcher';$createdJobs.Add($dispatcherId);$dj=Invoke-OclJson -Argv @('cron','get',$dispatcherId);Assert-CommandJob $dj 'Mission Dispatcher' '*/3 * * * *' $dispatcherArgv $Root;Good "Mission Dispatcher stored exact argv: $dispatcherId"

  $intakeArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$IntakePath,'-Mode','Poll')
  $ic=Invoke-OclJson -Argv @('cron','create','*/2 * * * *','--exact','--name','Kevin Work Order Intake v1','--declaration-key','kevin-work-order-intake-v1','--session','isolated','--command-argv',($intakeArgv|ConvertTo-Json -Compress),'--command-cwd',$Root,'--timeout-seconds','300','--no-output-timeout-seconds','300','--output-max-bytes','32768','--command-env',("KEVIN_GH_EXE={0}" -f $script:GhExe),'--command-env','KEVIN_GH_AUTH_MODE=stored','--command-env','GH_PROMPT_DISABLED=1','--no-deliver','--json')
  $intakeId=Resolve-JobId $ic 'Work Order Intake';$createdJobs.Add($intakeId);$ij=Invoke-OclJson -Argv @('cron','get',$intakeId);Assert-CommandJob $ij 'Work Order Intake' '*/2 * * * *' $intakeArgv $Root
  $ienv=Get-OptionalPropertyValue (Get-OptionalPropertyValue $ij 'payload') 'env';if(-not $ienv){throw 'Work Order Intake stored environment missing.'};if([string](Get-OptionalPropertyValue $ienv 'KEVIN_GH_EXE') -cne $script:GhExe -or [string](Get-OptionalPropertyValue $ienv 'KEVIN_GH_AUTH_MODE') -cne 'stored'){throw 'Work Order Intake stored credential-mode environment mismatch.'};Good "Work Order Intake stored exact argv + stored credential mode: $intakeId"

  Step 'Prove Work-Order Intake through the real scheduler with the empty inbox'
  $intakeEntry=Run-CronAndRequireOk -JobId $intakeId -Label 'Work Order Intake' -Wait '4m';$summary=[string](Get-OptionalPropertyValue $intakeEntry 'summary');if($summary -and $summary -notmatch 'WORK_ORDER_NONE'){Note "Intake scheduler returned ok; summary did not include WORK_ORDER_NONE: $(One-Line $summary)"}else{Good 'Intake scheduler confirmed empty work-order inbox.'}

  Step 'Verify autonomy scheduler identities were not changed'
  $after=Invoke-OclJson -Argv @('cron','list','--all','--json');$afterJobs=@();if($after){$a=Get-OptionalPropertyValue $after 'jobs';if($a){$afterJobs=@($a)}}
  $recAfter=@($afterJobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Autonomy Reconciler v0.1'});$telAfter=@($afterJobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Autonomy Telemetry v0.1'})
  if($recAfter.Count -ne 1 -or [string](Get-OptionalPropertyValue $recAfter[0] 'id') -ne $recId){throw 'Autonomy Reconciler identity changed during Control Plane install.'};if($telAfter.Count -ne 1 -or [string](Get-OptionalPropertyValue $telAfter[0] 'id') -ne $telId){throw 'Autonomy Telemetry identity changed during Control Plane install.'};Good 'Existing autonomy scheduler jobs remained untouched.'

  Step 'Write installation evidence and rollback'
  $manifest=[ordered]@{schema=1;kind='kevin-control-plane-install';version='1.0';installed_at=(Get-Date).ToString('o');component_blobs=$Components;jobs=[ordered]@{mission_dispatcher=$dispatcherId;work_order_intake=$intakeId;preserved_reconciler=$recId;preserved_telemetry=$telId};safety=[ordered]@{green_only=$true;arbitrary_shell=$false;production_chat_changed=$false;reader_changed=$false;automatic_candidate_promotion=$false};work_order_transport=[ordered]@{branch=$OrderBranch;path='control-plane/orders/CURRENT.json';local_authority='typed GREEN allowlist + local catalog + expiry + idempotency'}}
  $manifestPath=Join-Path $Root 'install-manifest-control-plane-v1.json';[IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 20),$Utf8)
  $proofPath=Join-Path $EvidenceDir ("$Stamp-control-plane-v1-install-proof.json");[IO.File]::WriteAllText($proofPath,($manifest|ConvertTo-Json -Depth 20),$Utf8)

  $rollbackPath=Join-Path $Root 'ROLLBACK-CONTROL-PLANE-v1.ps1';$rb=New-Object System.Collections.Generic.List[string]
  $rb.Add("`$ErrorActionPreference='Continue'")
  $rb.Add(("`$node={0}" -f ("'"+$script:Ocl.Node.Replace("'","''")+"'")))
  $rb.Add(("`$cli={0}" -f ("'"+$script:Ocl.Cli.Replace("'","''")+"'")))
  foreach($jid in @($dispatcherId,$intakeId)){$rb.Add(("& `$node `$cli cron remove '{0}' --json | Out-Null" -f $jid))}
  foreach($b in $backups){if([bool]$b.had_original){$rb.Add(("Copy-Item -LiteralPath '{0}' -Destination '{1}' -Force" -f ([string]$b.backup).Replace("'","''"),([string]$b.target).Replace("'","''")))}else{$rb.Add(("Remove-Item -LiteralPath '{0}' -Force -ErrorAction SilentlyContinue" -f ([string]$b.target).Replace("'","''")))}}
  $rb.Add("Write-Host 'Kevin Control Plane v1 rollback completed.'")
  [IO.File]::WriteAllLines($rollbackPath,$rb,$Utf8)
  Good "Manifest: $manifestPath";Good "Rollback: $rollbackPath"

  Write-Host ''
  Write-Host '============================================================' -ForegroundColor Green
  Write-Host 'KEVIN CONTROL PLANE v1 INSTALLED + PROVEN' -ForegroundColor Green
  Write-Host '============================================================' -ForegroundColor Green
  Write-Host "Mission Dispatcher: every 3 minutes ($dispatcherId)"
  Write-Host "Work Order Intake: every 2 minutes ($intakeId)"
  Write-Host 'Candidate factory: isolated, reviewed, never auto-promoted'
  Write-Host 'Remote control: typed GREEN work orders only; no command strings'
  Write-Host 'Existing Reconciler + Telemetry: preserved unchanged'
  exit 0
}catch{
  $msg=[string]$_.Exception.Message
  Note ("Install failed; removing only newly created Control Plane v1 scheduler jobs. Cause: "+$msg)
  foreach($jid in @($createdJobs)){try{$null=Invoke-OclJson -Argv @('cron','remove',[string]$jid,'--json')}catch{}}
  foreach($b in @($backups)){try{if([bool]$b.had_original -and [string]$b.backup -and (Test-Path -LiteralPath ([string]$b.backup))){Copy-Item -LiteralPath ([string]$b.backup) -Destination ([string]$b.target) -Force}else{Remove-Item -LiteralPath ([string]$b.target) -Force -ErrorAction SilentlyContinue}}catch{}}
  throw
}finally{Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue}
