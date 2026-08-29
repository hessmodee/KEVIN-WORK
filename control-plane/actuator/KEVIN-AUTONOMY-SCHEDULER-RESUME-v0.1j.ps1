param(
  [ValidateSet('Install','ValidateTransport')]
  [string]$Mode='Install'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

function Step([string]$s){Write-Host ("`n==> "+$s) -ForegroundColor Cyan}
function Good([string]$s){Write-Host ("PASS  "+$s) -ForegroundColor Green}
function Note([string]$s){Write-Host ("INFO  "+$s) -ForegroundColor DarkGray}

function ConvertTo-Win32CommandLineArg {
  param([AllowEmptyString()][string]$Value)
  if($null -eq $Value -or $Value.Length -eq 0){return '""'}
  if($Value -notmatch '[\s"]'){return $Value}
  $sb=New-Object System.Text.StringBuilder
  [void]$sb.Append('"')
  $slashes=0
  for($i=0;$i -lt $Value.Length;$i++){
    $ch=$Value[$i]
    if($ch -eq '\'){$slashes++;continue}
    if($ch -eq '"'){
      if($slashes -gt 0){[void]$sb.Append((('\' * ($slashes*2)) -join ''))}
      [void]$sb.Append('\"')
      $slashes=0
      continue
    }
    if($slashes -gt 0){[void]$sb.Append((('\' * $slashes) -join ''));$slashes=0}
    [void]$sb.Append($ch)
  }
  if($slashes -gt 0){[void]$sb.Append((('\' * ($slashes*2)) -join ''))}
  [void]$sb.Append('"')
  return $sb.ToString()
}

function Invoke-ExactNative {
  param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string[]]$Argv)
  $psi=New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Executable
  $psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ')
  $psi.UseShellExecute=$false
  $psi.CreateNoWindow=$true
  $psi.RedirectStandardOutput=$true
  $psi.RedirectStandardError=$true
  $p=New-Object System.Diagnostics.Process
  $p.StartInfo=$psi
  if(-not $p.Start()){throw "Could not start native process: $Executable"}
  $outTask=$p.StandardOutput.ReadToEndAsync();$errTask=$p.StandardError.ReadToEndAsync();$p.WaitForExit()
  $result=[pscustomobject]@{ExitCode=[int]$p.ExitCode;Stdout=[string]$outTask.Result;Stderr=[string]$errTask.Result;CommandLine=$psi.Arguments}
  $p.Dispose();return $result
}

function Test-ExactNativeJsonTransport {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue
  if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue}
  if(-not $node){throw 'Node.js is required for exact native transport self-test.'}
  $probe=Join-Path $env:TEMP ("kevin-argv-probe-{0}.js" -f [guid]::NewGuid().ToString('N'))
  $js=@'
const args=process.argv.slice(2);
const i=args.indexOf('--command-argv');
if(i<0 || i+1>=args.length) process.exit(31);
let p;
try { p=JSON.parse(args[i+1]); } catch { process.exit(32); }
const ok=Array.isArray(p) && p.length===4 && p[0]==='powershell.exe' && p[1]==='C:\\Path With Space\\x.ps1' && p[2]==='A"B' && p[3]==='tail\\';
process.exit(ok?0:33);
'@
  [IO.File]::WriteAllText($probe,$js,(New-Object Text.UTF8Encoding($false)))
  try{
    $json=@('powershell.exe','C:\Path With Space\x.ps1','A"B','tail\')|ConvertTo-Json -Compress
    $r=Invoke-ExactNative -Executable $node.Source -Argv @($probe,'--command-argv',$json)
    if($r.ExitCode -ne 0){throw "Exact native JSON transport self-test failed with exit $($r.ExitCode)."}
  } finally {Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue}
  return $true
}

if($Mode -eq 'ValidateTransport'){
  [void](Test-ExactNativeJsonTransport)
  Write-Output 'TRANSPORT_OK'
  exit 0
}

$Repo='hessmodee/KEVIN-WORK'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Root=Join-Path $Workspace 'ControlPlane'
$Reports=Join-Path $Workspace 'reports'
if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$EvidenceDir=Join-Path $Root 'Evidence'
$BackupDir=Join-Path $Root 'Backups'
if(-not(Test-Path -LiteralPath $EvidenceDir)){New-Item -ItemType Directory -Path $EvidenceDir -Force|Out-Null}
if(-not(Test-Path -LiteralPath $BackupDir)){New-Item -ItemType Directory -Path $BackupDir -Force|Out-Null}
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')

$DesiredBlob='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
$OwnerBlob='b0cc4465f12457492b3a6c2761287398cc6295b5'
$ActuatorBlob='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
$OldBridgeBlob='05bb7d3a01d9eace3105a717020656a040f4da8c'
$NewBridgeBlob='d542581dc4783fc8f34ede34edf47e4427df7091'

$DesiredPath=Join-Path $Root 'desired-state-v1.json'
$OwnerPath=Join-Path $Root 'OWNER-AUTHORIZATION-v1.md'
$Actuator=Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1'
$Bridge=Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1'

function Write-JsonAtomic {param($Object,[string]$Path);$tmp="$Path.tmp-$PID";[IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),(New-Object Text.UTF8Encoding($false)));Move-Item -LiteralPath $tmp -Destination $Path -Force}

function Get-GitBlobSha1 {
  param([Parameter(Mandatory=$true)][string]$Path)
  $bytes=[IO.File]::ReadAllBytes($Path)
  $header=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $bytes.Length))
  $all=New-Object byte[] ($header.Length+1+$bytes.Length)
  [Buffer]::BlockCopy($header,0,$all,0,$header.Length);$all[$header.Length]=0;[Buffer]::BlockCopy($bytes,0,$all,$header.Length+1,$bytes.Length)
  $sha=[Security.Cryptography.SHA1]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
}

function Parse-PowerShellFile([string]$Path){
  $tokens=$null;$errors=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
  if($errors -and $errors.Count){$msg=($errors|ForEach-Object{"line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; ';throw "PowerShell parser rejected $Path :: $msg"}
}

function Get-OpenClawNodeLauncher {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js not found in PATH.'}
  $shim=Get-Command openclaw.cmd -ErrorAction SilentlyContinue;if(-not $shim){$shim=Get-Command openclaw -ErrorAction SilentlyContinue};if(-not $shim){throw 'OpenClaw CLI not found in PATH.'}
  $shimDir=Split-Path -Parent $shim.Source;$pkgDir=Join-Path $shimDir 'node_modules\openclaw';$pkgJson=Join-Path $pkgDir 'package.json'
  if(-not(Test-Path -LiteralPath $pkgJson)){throw "OpenClaw package.json not found: $pkgJson"}
  $pkg=Get-Content -LiteralPath $pkgJson -Raw|ConvertFrom-Json;$binRel=$null
  if($pkg.bin -is [string]){$binRel=[string]$pkg.bin}elseif($pkg.bin -and $pkg.bin.openclaw){$binRel=[string]$pkg.bin.openclaw}
  if(-not $binRel){throw 'OpenClaw package does not declare its CLI binary.'}
  $cli=Join-Path $pkgDir $binRel;if(-not(Test-Path -LiteralPath $cli)){throw "OpenClaw node entrypoint not found: $cli"}
  return [pscustomobject]@{Node=$node.Source;Cli=$cli;Version=[string]$pkg.version}
}

function ConvertFrom-OpenClawJson {
  param([AllowEmptyString()][string]$Text)
  if([string]::IsNullOrWhiteSpace($Text)){return $null}
  $t=$Text.Trim();try{return ($t|ConvertFrom-Json)}catch{}
  $t=[regex]::Replace($t,"`e\[[0-9;?]*[ -/]*[@-~]",'')
  $starts=@($t.IndexOf('{'),$t.IndexOf('['))|Where-Object{$_ -ge 0}|Sort-Object
  foreach($start in $starts){try{return ($t.Substring([int]$start)|ConvertFrom-Json)}catch{}}
  throw 'OpenClaw stdout was not valid JSON.'
}

$script:Ocl=$null
function Invoke-OpenClawRaw {param([Parameter(Mandatory=$true)][string[]]$Args);if(-not $script:Ocl){$script:Ocl=Get-OpenClawNodeLauncher};return Invoke-ExactNative -Executable $script:Ocl.Node -Argv (@($script:Ocl.Cli)+@($Args))}
function Invoke-OpenClawJson {
  param([Parameter(Mandatory=$true)][string[]]$Args)
  $r=Invoke-OpenClawRaw -Args $Args
  $obj=$null;try{$obj=ConvertFrom-OpenClawJson -Text $r.Stdout}catch{}
  if($r.ExitCode -ne 0){throw ("OpenClaw failed: {0} :: stdout={1} :: stderr={2}" -f ($Args -join ' '),($r.Stdout.Trim()),($r.Stderr.Trim()))}
  if($null -eq $obj -and -not [string]::IsNullOrWhiteSpace($r.Stdout)){throw "OpenClaw returned non-JSON output for $($Args -join ' ') :: $($r.Stdout)"}
  return $obj
}

function Run-Ps {param([Parameter(Mandatory=$true)][string]$File,[string[]]$Args=@());return Invoke-ExactNative -Executable 'powershell.exe' -Argv (@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$File)+@($Args))}

function Resolve-Gh {
  $gh=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not $gh){$gh=Get-Command gh -ErrorAction SilentlyContinue};if(-not $gh){throw 'GitHub CLI not found.'};return $gh.Source
}
$script:GhExe=$null
function Invoke-GhRaw {param([Parameter(Mandatory=$true)][string[]]$Args);if(-not $script:GhExe){$script:GhExe=Resolve-Gh};return Invoke-ExactNative -Executable $script:GhExe -Argv $Args}

function Get-GitBlobBytes {
  param([string]$Blob)
  $r=Invoke-GhRaw -Args @('api',("repos/{0}/git/blobs/{1}" -f $Repo,$Blob))
  if($r.ExitCode -ne 0){throw "GitHub blob fetch failed for $Blob :: $($r.Stderr)"}
  $o=$r.Stdout|ConvertFrom-Json
  if(([string]$o.sha).ToLowerInvariant() -ne $Blob.ToLowerInvariant()){throw "GitHub blob identity mismatch for $Blob"}
  if([string]$o.encoding -ne 'base64'){throw "Unexpected blob encoding for $Blob"}
  return [Convert]::FromBase64String(([string]$o.content -replace '\s',''))
}

function Resolve-JobId {param($Object,[string]$Label);if($Object -and $Object.id){return [string]$Object.id};if($Object -and $Object.jobId){return [string]$Object.jobId};if($Object -and $Object.job -and $Object.job.id){return [string]$Object.job.id};if($Object -and $Object.result -and $Object.result.id){return [string]$Object.result.id};throw "Could not resolve job id from $Label create response."}

function Assert-StringArrayEqual {param([string[]]$Actual,[string[]]$Expected,[string]$Label);if(@($Actual).Count -ne @($Expected).Count){throw "$Label argv length mismatch."};for($i=0;$i -lt @($Expected).Count;$i++){if([string]$Actual[$i] -cne [string]$Expected[$i]){throw "$Label argv mismatch at index $i. Expected '$($Expected[$i])', got '$($Actual[$i])'."}}}

function Assert-CronJob {
  param($Job,[string]$Label,[string]$ExpectedExpr,[string[]]$ExpectedArgv,[string]$ExpectedCwd,[string]$ExpectedGhExe='')
  if(-not $Job){throw "$Label cron get returned no job."};if(-not [bool]$Job.enabled){throw "$Label job is not enabled."};if(-not $Job.payload -or [string]$Job.payload.kind -ne 'command'){throw "$Label payload is not command kind."}
  Assert-StringArrayEqual -Actual @($Job.payload.argv) -Expected $ExpectedArgv -Label $Label
  if([string]$Job.payload.cwd -cne $ExpectedCwd){throw "$Label cwd mismatch."};if([string]$Job.schedule.kind -ne 'cron' -or [string]$Job.schedule.expr -cne $ExpectedExpr){throw "$Label schedule mismatch."}
  if($ExpectedGhExe){
    if(-not $Job.payload.env -or -not ($Job.payload.env.PSObject.Properties.Name -contains 'KEVIN_GH_EXE')){throw "$Label stored environment is missing KEVIN_GH_EXE."}
    if([string]$Job.payload.env.KEVIN_GH_EXE -cne $ExpectedGhExe){throw "$Label KEVIN_GH_EXE mismatch. Expected '$ExpectedGhExe', got '$([string]$Job.payload.env.KEVIN_GH_EXE)'."}
  }
}

function Get-RunFailureDetail {
  param($RunObject,$Entry,[string]$RawStdout,[string]$RawStderr)
  $parts=New-Object System.Collections.Generic.List[string]
  if($RunObject){foreach($n in @('status','error')){if($RunObject.PSObject.Properties.Name -contains $n){$v=[string]$RunObject.$n;if($v){$parts.Add("run.$n=$v")}}}}
  if($Entry){
    foreach($n in @('status','error','errorReason','summary')){if($Entry.PSObject.Properties.Name -contains $n){$v=[string]$Entry.$n;if($v){$parts.Add("entry.$n=$v")}}}
    if($Entry.diagnostics -and ($Entry.diagnostics.PSObject.Properties.Name -contains 'summary') -and $Entry.diagnostics.summary){$parts.Add("diagnostics.summary=$([string]$Entry.diagnostics.summary)")}
  }
  if($RawStderr.Trim()){$parts.Add("cli.stderr=$($RawStderr.Trim())")}
  if($parts.Count -eq 0 -and $RawStdout.Trim()){$parts.Add("cli.stdout=$($RawStdout.Trim())")}
  return (($parts -join ' | ') -replace '[\r\n]+',' ')
}

function Assert-RunSuccessDetailed {
  param([string]$JobId,[string]$Label,[string]$Wait='5m')
  $runRaw=Invoke-OpenClawRaw -Args @('cron','run',$JobId,'--wait','--wait-timeout',$Wait,'--poll-interval','2s')
  $runObj=$null;try{$runObj=ConvertFrom-OpenClawJson -Text $runRaw.Stdout}catch{}
  $runId=$null;if($runObj -and ($runObj.PSObject.Properties.Name -contains 'runId') -and $runObj.runId){$runId=[string]$runObj.runId}
  $histArgs=@('cron','runs','--id',$JobId,'--limit','5');if($runId){$histArgs+=@('--run-id',$runId)}
  $histRaw=Invoke-OpenClawRaw -Args $histArgs
  $hist=$null;if($histRaw.ExitCode -eq 0){try{$hist=ConvertFrom-OpenClawJson -Text $histRaw.Stdout}catch{}}
  $items=@();if($hist -and ($hist.PSObject.Properties.Name -contains 'entries')){$items=@($hist.entries)}elseif($hist -and ($hist.PSObject.Properties.Name -contains 'runs')){$items=@($hist.runs)}
  $entry=$null;if($items.Count -gt 0){$entry=$items[0]}
  if($runRaw.ExitCode -eq 0 -and $entry -and [string]$entry.status -eq 'ok'){Good "$Label manual scheduler execution verified by exact run history.";return $entry}
  $detail=Get-RunFailureDetail -RunObject $runObj -Entry $entry -RawStdout $runRaw.Stdout -RawStderr $runRaw.Stderr
  throw "$Label scheduler execution failed :: $detail"
}

Step 'Verify current autonomy installation'
$checks=[ordered]@{$DesiredPath=$DesiredBlob;$OwnerPath=$OwnerBlob;$Actuator=$ActuatorBlob}
foreach($kv in $checks.GetEnumerator()){if(-not(Test-Path -LiteralPath $kv.Key)){throw "Required component missing: $($kv.Key)"};$actual=Get-GitBlobSha1 $kv.Key;if($actual -ne [string]$kv.Value){throw "Component drift: $($kv.Key) expected $($kv.Value), got $actual"};Good "$(Split-Path $kv.Key -Leaf) verified: $actual"}
if(-not(Test-Path -LiteralPath $Bridge)){throw 'Installed autonomy bridge missing.'}
$currentBridge=Get-GitBlobSha1 $Bridge
if(@($OldBridgeBlob,$NewBridgeBlob) -notcontains $currentBridge){throw "Unexpected installed autonomy bridge: $currentBridge"}
Good "Installed autonomy bridge recognized: $currentBridge"

Step 'Prove exact Windows native transport and runtime versions'
[void](Test-ExactNativeJsonTransport);Good 'WinPS 5.1 exact argv transport self-test passed.'
$script:Ocl=Get-OpenClawNodeLauncher;if($script:Ocl.Version -ne '2026.7.1-2'){throw "Expected OpenClaw 2026.7.1-2, found $($script:Ocl.Version)."};Good 'OpenClaw 2026.7.1-2 node entrypoint resolved directly.'
$script:GhExe=Resolve-Gh;Good ("GitHub CLI resolved: "+$script:GhExe)

Step 'Install hardened telemetry bridge from immutable Git blob'
if($currentBridge -ne $NewBridgeBlob){Copy-Item -LiteralPath $Bridge -Destination (Join-Path $BackupDir ("$Stamp-kevin-autonomy-bridge-v0.1.ps1")) -Force;$bytes=Get-GitBlobBytes -Blob $NewBridgeBlob;[IO.File]::WriteAllBytes($Bridge,$bytes)}
if((Get-GitBlobSha1 $Bridge) -ne $NewBridgeBlob){throw 'Hardened telemetry bridge install hash mismatch.'}
Parse-PowerShellFile $Bridge
Good "Hardened telemetry bridge installed and parsed: $NewBridgeBlob"

Step 'Prove telemetry bridge directly on this OMEN before cron mutation'
$direct=Run-Ps -File $Bridge
Write-Host $direct.Stdout
if($direct.ExitCode -ne 0){throw "Direct telemetry bridge proof failed :: stdout=$($direct.Stdout.Trim()) :: stderr=$($direct.Stderr.Trim())"}
if($direct.Stdout -notmatch 'AUTONOMY_(PUBLISHED|UNCHANGED)'){throw "Direct telemetry bridge returned unexpected output: $($direct.Stdout)"}
Good 'Direct telemetry publish/no-op proof passed on OMEN.'

Step 'Re-run autonomy self-test and desired-state audit'
$self=Run-Ps -File $Actuator -Args @('-Mode','SelfTest');Write-Host $self.Stdout;if($self.ExitCode -ne 0){throw "Actuator self-test failed :: $($self.Stderr)"};Good 'Actuator self-test passed.'
$audit=Run-Ps -File $Actuator -Args @('-Mode','Audit');Write-Host $audit.Stdout;if($audit.ExitCode -ne 0){throw "Desired-state audit failed :: $($audit.Stderr)"};Good 'Desired-state audit passed.'

Step 'Remove only prior same-name autonomy scheduler jobs'
$status=Invoke-OpenClawJson -Args @('cron','status','--json');if($status -and ($status.PSObject.Properties.Name -contains 'enabled') -and (-not [bool]$status.enabled)){throw 'OpenClaw cron scheduler is disabled.'}
$list=Invoke-OpenClawJson -Args @('cron','list','--all','--json');$jobs=@();if($list -and ($list.PSObject.Properties.Name -contains 'jobs')){$jobs=@($list.jobs)}
$targetNames=@('Kevin Autonomy Reconciler v0.1','Kevin Autonomy Telemetry v0.1');$removed=@()
foreach($j in $jobs){if($targetNames -contains [string]$j.name){if(-not $j.id){throw "Prior autonomy job missing id: $($j.name)"};$null=Invoke-OpenClawJson -Args @('cron','remove',[string]$j.id,'--json');$removed+=[string]$j.id;Note ("Removed prior same-name job: "+[string]$j.id)}}

Step 'Create exact scheduler jobs and verify stored argv'
$reconcileArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Actuator,'-Mode','Reconcile')
$bridgeArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Bridge)
$reconcileJson=$reconcileArgv|ConvertTo-Json -Compress;$bridgeJson=$bridgeArgv|ConvertTo-Json -Compress
$rId=$null;$bId=$null
try{
  $rc=Invoke-OpenClawJson -Args @('cron','create','*/3 * * * *','--exact','--name','Kevin Autonomy Reconciler v0.1','--declaration-key','kevin-autonomy-reconciler-v0.1','--session','isolated','--command-argv',$reconcileJson,'--command-cwd',$Root,'--timeout-seconds','600','--no-output-timeout-seconds','600','--output-max-bytes','65536','--no-deliver','--json')
  $rId=Resolve-JobId $rc 'reconciler';$rj=Invoke-OpenClawJson -Args @('cron','get',$rId);Assert-CronJob $rj 'Reconciler' '*/3 * * * *' $reconcileArgv $Root;Good "Reconciler job stored exact argv: $rId"
  $bc=Invoke-OpenClawJson -Args @('cron','create','*/5 * * * *','--exact','--name','Kevin Autonomy Telemetry v0.1','--declaration-key','kevin-autonomy-telemetry-v0.1','--session','isolated','--command-argv',$bridgeJson,'--command-cwd',$Root,'--timeout-seconds','120','--no-output-timeout-seconds','120','--output-max-bytes','32768','--command-env',("KEVIN_GH_EXE={0}" -f $script:GhExe),'--no-deliver','--json')
  $bId=Resolve-JobId $bc 'telemetry';$bj=Invoke-OpenClawJson -Args @('cron','get',$bId);Assert-CronJob $bj 'Telemetry' '*/5 * * * *' $bridgeArgv $Root $script:GhExe;Good "Telemetry job stored exact argv: $bId"
}catch{if($rId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$rId,'--json')}catch{}};if($bId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$bId,'--json')}catch{}};throw}

Step 'Execute and prove both jobs through OpenClaw cron'
$reconcilerProven=$false
try{$null=Assert-RunSuccessDetailed -JobId $rId -Label 'Reconciler' -Wait '6m';$reconcilerProven=$true;$null=Assert-RunSuccessDetailed -JobId $bId -Label 'Telemetry' -Wait '4m'}catch{
  $failure=$_.Exception.Message
  if($bId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$bId,'--json')}catch{}}
  if(-not $reconcilerProven -and $rId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$rId,'--json')}catch{}}
  if($reconcilerProven){Note 'Telemetry proof failed, but the already-proven Reconciler job was preserved so safe local self-healing can continue.'}
  throw $failure
}

Step 'Independently verify public autonomy telemetry'
$remote=Invoke-GhRaw -Args @('api',("repos/{0}/contents/reports/autonomy-latest.json?ref=main" -f $Repo),'-H','Accept: application/vnd.github+json')
if($remote.ExitCode -ne 0){throw "Remote autonomy telemetry fetch failed :: $($remote.Stderr)"}
$remoteObj=$remote.Stdout|ConvertFrom-Json;if(-not $remoteObj.sha){throw 'Remote autonomy telemetry has no content SHA.'}
$decoded=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$remoteObj.content -replace '\s','')))|ConvertFrom-Json
if($decoded.kind -ne 'kevin-autonomy-public' -or -not $decoded.semantic_hash){throw 'Remote autonomy telemetry payload failed independent validation.'}
Good ("Remote autonomy evidence independently verified: "+[string]$remoteObj.sha)

Step 'Write v0.1j installation proof and rollback'
$manifest=[ordered]@{schema=1;version='0.1j';installed_at=(Get-Date).ToString('o');openclaw_version=$script:Ocl.Version;native_transport='ProcessStartInfo-Win32-argv-quoting-v1';actuator_blob=$ActuatorBlob;bridge_blob=$NewBridgeBlob;reconciler_job_id=$rId;telemetry_job_id=$bId;removed_prior_job_ids=@($removed);remote_autonomy_sha=[string]$remoteObj.sha}
$manifestPath=Join-Path $Root 'install-manifest-v0.1j.json';Write-JsonAtomic $manifest $manifestPath;Write-JsonAtomic $manifest (Join-Path $EvidenceDir ("$Stamp-install-proof-v0.1j.json"))
$nodeLiteral=$script:Ocl.Node.Replace("'","''");$cliLiteral=$script:Ocl.Cli.Replace("'","''")
$rollback=@"
`$ErrorActionPreference='Continue'
`$node='$nodeLiteral'
`$cli='$cliLiteral'
& `$node `$cli cron remove '$rId' --json | Out-Null
& `$node `$cli cron remove '$bId' --json | Out-Null
Write-Host 'Kevin Autonomy scheduler v0.1j jobs removed.'
"@
$rollbackPath=Join-Path $Root 'ROLLBACK-v0.1j.ps1';[IO.File]::WriteAllText($rollbackPath,$rollback,(New-Object Text.UTF8Encoding($false)))

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host 'KEVIN AUTONOMY SCHEDULER v0.1j INSTALLED + PROVEN' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host 'Reconciler: every 3 minutes'
Write-Host 'Telemetry: every 5 minutes'
Write-Host 'Bridge: hardened exact gh transport + bounded retry + pinned scheduler gh.exe'
Write-Host 'Scheduler evidence: exact run-id history with failure diagnostics'
Write-Host "Manifest: $manifestPath"
Write-Host "Rollback: $rollbackPath"
