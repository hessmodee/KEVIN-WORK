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
  param(
    [Parameter(Mandatory=$true)][string]$Executable,
    [Parameter(Mandatory=$true)][string[]]$Argv
  )
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
  $outTask=$p.StandardOutput.ReadToEndAsync()
  $errTask=$p.StandardError.ReadToEndAsync()
  $p.WaitForExit()
  $stdout=[string]$outTask.Result
  $stderr=[string]$errTask.Result
  $code=[int]$p.ExitCode
  $p.Dispose()
  return [pscustomobject]@{ExitCode=$code;Stdout=$stdout;Stderr=$stderr;CommandLine=$psi.Arguments}
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
  } finally {
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
  }
  return $true
}

if($Mode -eq 'ValidateTransport'){
  Step 'Validate Windows PowerShell 5.1 exact native JSON transport'
  [void](Test-ExactNativeJsonTransport)
  Good 'Exact native argv transport preserved JSON, spaces, quotes, and backslashes.'
  exit 0
}

$Repo='hessmodee/KEVIN-WORK'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Root=Join-Path $Workspace 'ControlPlane'
$Reports=Join-Path $Workspace 'reports'
if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$EvidenceDir=Join-Path $Root 'Evidence'
if(-not(Test-Path -LiteralPath $EvidenceDir)){New-Item -ItemType Directory -Path $EvidenceDir -Force|Out-Null}
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')

$Expected=[ordered]@{
  'desired-state-v1.json'='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
  'OWNER-AUTHORIZATION-v1.md'='b0cc4465f12457492b3a6c2761287398cc6295b5'
  'kevin-autonomy-bridge-v0.1.ps1'='05bb7d3a01d9eace3105a717020656a040f4da8c'
  'kevin-autonomy-actuator-v0.1.ps1'='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'
}

function Write-JsonAtomic {
  param($Object,[string]$Path)
  $tmp="$Path.tmp-$PID"
  [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),(New-Object Text.UTF8Encoding($false)))
  Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Get-GitBlobSha1 {
  param([Parameter(Mandatory=$true)][string]$Path)
  $bytes=[IO.File]::ReadAllBytes($Path)
  $header=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $bytes.Length))
  $all=New-Object byte[] ($header.Length+1+$bytes.Length)
  [Buffer]::BlockCopy($header,0,$all,0,$header.Length)
  $all[$header.Length]=0
  [Buffer]::BlockCopy($bytes,0,$all,$header.Length+1,$bytes.Length)
  $sha=[Security.Cryptography.SHA1]::Create()
  try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}
  finally{$sha.Dispose()}
}

function Get-OpenClawNodeLauncher {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue
  if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue}
  if(-not $node){throw 'Node.js not found in PATH.'}
  $shim=Get-Command openclaw.cmd -ErrorAction SilentlyContinue
  if(-not $shim){$shim=Get-Command openclaw -ErrorAction SilentlyContinue}
  if(-not $shim){throw 'OpenClaw CLI not found in PATH.'}
  $shimDir=Split-Path -Parent $shim.Source
  $pkgDir=Join-Path $shimDir 'node_modules\openclaw'
  $pkgJson=Join-Path $pkgDir 'package.json'
  if(-not(Test-Path -LiteralPath $pkgJson)){throw "OpenClaw package.json not found beside CLI shim: $pkgJson"}
  $pkg=Get-Content -LiteralPath $pkgJson -Raw|ConvertFrom-Json
  $binRel=$null
  if($pkg.bin -is [string]){$binRel=[string]$pkg.bin}
  elseif($pkg.bin -and $pkg.bin.openclaw){$binRel=[string]$pkg.bin.openclaw}
  if(-not $binRel){throw 'OpenClaw package does not declare an openclaw binary.'}
  $cli=Join-Path $pkgDir $binRel
  if(-not(Test-Path -LiteralPath $cli)){throw "OpenClaw node entrypoint not found: $cli"}
  return [pscustomobject]@{Node=$node.Source;Cli=$cli;Version=[string]$pkg.version}
}

function ConvertFrom-OpenClawJson {
  param([Parameter(Mandatory=$true)][string]$Text)
  $t=$Text.Trim()
  if([string]::IsNullOrWhiteSpace($t)){return $null}
  try{return ($t|ConvertFrom-Json)}catch{}
  $t=[regex]::Replace($t,"`e\[[0-9;?]*[ -/]*[@-~]",'')
  $starts=@($t.IndexOf('{'),$t.IndexOf('['))|Where-Object{$_ -ge 0}|Sort-Object
  foreach($start in $starts){
    try{return ($t.Substring([int]$start)|ConvertFrom-Json)}catch{}
  }
  throw 'OpenClaw stdout was not valid JSON.'
}

$script:Ocl=$null
function Invoke-OpenClawRaw {
  param([Parameter(Mandatory=$true)][string[]]$Args)
  if(-not $script:Ocl){$script:Ocl=Get-OpenClawNodeLauncher}
  return Invoke-ExactNative -Executable $script:Ocl.Node -Argv (@($script:Ocl.Cli)+@($Args))
}

function Invoke-OpenClawJson {
  param([Parameter(Mandatory=$true)][string[]]$Args)
  $r=Invoke-OpenClawRaw -Args $Args
  if($r.ExitCode -ne 0){throw "OpenClaw failed: $($Args -join ' ') :: $($r.Stderr)"}
  try{return ConvertFrom-OpenClawJson -Text $r.Stdout}catch{throw "OpenClaw returned non-JSON output for $($Args -join ' ') :: $($r.Stdout)"}
}

function Run-Ps {
  param([Parameter(Mandatory=$true)][string]$File,[string[]]$Args=@())
  return Invoke-ExactNative -Executable 'powershell.exe' -Argv (@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$File)+@($Args))
}

function Resolve-JobId {
  param($Object,[string]$Label)
  if($Object -and ($Object.PSObject.Properties.Name -contains 'id') -and $Object.id){return [string]$Object.id}
  if($Object -and ($Object.PSObject.Properties.Name -contains 'jobId') -and $Object.jobId){return [string]$Object.jobId}
  if($Object -and ($Object.PSObject.Properties.Name -contains 'job') -and $Object.job -and $Object.job.id){return [string]$Object.job.id}
  if($Object -and ($Object.PSObject.Properties.Name -contains 'result') -and $Object.result -and $Object.result.id){return [string]$Object.result.id}
  throw "Could not resolve job id from $Label create response."
}

function Assert-StringArrayEqual {
  param([string[]]$Actual,[string[]]$Expected,[string]$Label)
  if(@($Actual).Count -ne @($Expected).Count){throw "$Label argv length mismatch."}
  for($i=0;$i -lt @($Expected).Count;$i++){
    if([string]$Actual[$i] -cne [string]$Expected[$i]){throw "$Label argv mismatch at index $i. Expected '$($Expected[$i])', got '$($Actual[$i])'."}
  }
}

function Assert-CronJob {
  param($Job,[string]$Label,[string]$ExpectedExpr,[string[]]$ExpectedArgv,[string]$ExpectedCwd)
  if(-not $Job){throw "$Label cron get returned no job."}
  if(-not [bool]$Job.enabled){throw "$Label job is not enabled."}
  if(-not $Job.payload -or [string]$Job.payload.kind -ne 'command'){throw "$Label payload is not command kind."}
  Assert-StringArrayEqual -Actual @($Job.payload.argv) -Expected $ExpectedArgv -Label $Label
  if([string]$Job.payload.cwd -cne $ExpectedCwd){throw "$Label cwd mismatch. Expected '$ExpectedCwd', got '$($Job.payload.cwd)'."}
  if($Job.schedule){
    if([string]$Job.schedule.kind -ne 'cron'){throw "$Label schedule kind is not cron."}
    if([string]$Job.schedule.expr -cne $ExpectedExpr){throw "$Label cron expression mismatch."}
  }
}

function Assert-RunSuccess {
  param([string]$JobId,[string]$Label,[string]$Wait='5m')
  $null=Invoke-OpenClawJson -Args @('cron','run',$JobId,'--wait','--wait-timeout',$Wait,'--poll-interval','2s')
  $hist=Invoke-OpenClawJson -Args @('cron','runs','--id',$JobId,'--limit','5')
  $items=@()
  if($hist -and ($hist.PSObject.Properties.Name -contains 'entries')){$items=@($hist.entries)}
  elseif($hist -and ($hist.PSObject.Properties.Name -contains 'runs')){$items=@($hist.runs)}
  foreach($entry in $items){
    if([string]$entry.status -eq 'ok'){Good "$Label manual scheduler execution verified by run history.";return}
  }
  throw "$Label did not produce a successful cron run-history entry."
}

Step 'Verify immutable installed autonomy components'
if(-not(Test-Path -LiteralPath $Root)){throw "ControlPlane root missing: $Root"}
foreach($kv in $Expected.GetEnumerator()){
  $path=Join-Path $Root $kv.Key
  if(-not(Test-Path -LiteralPath $path)){throw "Required installed component missing: $($kv.Key)"}
  $actual=Get-GitBlobSha1 -Path $path
  if($actual -ne [string]$kv.Value){throw "Installed component drift for $($kv.Key). Expected $($kv.Value), got $actual"}
  Good "$($kv.Key) matches immutable Git blob $actual"
}
$Actuator=Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1'
$Bridge=Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1'

Step 'Prove exact Windows native JSON transport before scheduler mutation'
[void](Test-ExactNativeJsonTransport)
Good 'WinPS 5.1 exact argv transport self-test passed.'
$script:Ocl=Get-OpenClawNodeLauncher
Good ("OpenClaw node entrypoint resolved directly; version="+$script:Ocl.Version)
if($script:Ocl.Version -ne '2026.7.1-2'){throw "Expected OpenClaw 2026.7.1-2, found $($script:Ocl.Version). Refusing scheduler mutation."}

Step 'Re-run autonomy self-test and desired-state audit'
$self=Run-Ps -File $Actuator -Args @('-Mode','SelfTest')
Write-Host $self.Stdout
if($self.ExitCode -ne 0){throw "Actuator self-test failed :: $($self.Stderr)"}
Good 'Actuator self-test passed.'
$audit=Run-Ps -File $Actuator -Args @('-Mode','Audit')
Write-Host $audit.Stdout
if($audit.ExitCode -ne 0){throw "Desired-state audit did not return healthy :: $($audit.Stderr)"}
Good 'Desired-state audit passed.'

Step 'Inspect scheduler and remove only prior Kevin autonomy job duplicates'
$status=Invoke-OpenClawJson -Args @('cron','status','--json')
if($status -and ($status.PSObject.Properties.Name -contains 'enabled') -and (-not [bool]$status.enabled)){throw 'OpenClaw cron scheduler is disabled.'}
$list=Invoke-OpenClawJson -Args @('cron','list','--all','--json')
$jobs=@()
if($list -and ($list.PSObject.Properties.Name -contains 'jobs')){$jobs=@($list.jobs)}
$targetNames=@('Kevin Autonomy Reconciler v0.1','Kevin Autonomy Telemetry v0.1')
$removed=@()
foreach($j in $jobs){
  if($targetNames -contains [string]$j.name){
    if(-not $j.id){throw "Found prior Kevin autonomy job without id: $($j.name)"}
    $null=Invoke-OpenClawJson -Args @('cron','remove',[string]$j.id,'--json')
    $removed+=([string]$j.id)
    Note ("Removed prior same-name autonomy job: "+[string]$j.id)
  }
}

Step 'Create scheduler jobs with exact argv transport and verify stored payloads'
$reconcileArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Actuator,'-Mode','Reconcile')
$bridgeArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Bridge)
$reconcileJson=$reconcileArgv|ConvertTo-Json -Compress
$bridgeJson=$bridgeArgv|ConvertTo-Json -Compress
$rId=$null;$bId=$null
try{
  $rc=Invoke-OpenClawJson -Args @('cron','create','*/3 * * * *','--exact','--name','Kevin Autonomy Reconciler v0.1','--declaration-key','kevin-autonomy-reconciler-v0.1','--session','isolated','--command-argv',$reconcileJson,'--command-cwd',$Root,'--timeout-seconds','600','--no-output-timeout-seconds','600','--output-max-bytes','65536','--no-deliver','--json')
  $rId=Resolve-JobId -Object $rc -Label 'reconciler'
  $rj=Invoke-OpenClawJson -Args @('cron','get',$rId)
  Assert-CronJob -Job $rj -Label 'Reconciler' -ExpectedExpr '*/3 * * * *' -ExpectedArgv $reconcileArgv -ExpectedCwd $Root
  Good "Reconciler job stored exact argv and verified: $rId"

  $bc=Invoke-OpenClawJson -Args @('cron','create','*/5 * * * *','--exact','--name','Kevin Autonomy Telemetry v0.1','--declaration-key','kevin-autonomy-telemetry-v0.1','--session','isolated','--command-argv',$bridgeJson,'--command-cwd',$Root,'--timeout-seconds','120','--no-output-timeout-seconds','120','--output-max-bytes','32768','--no-deliver','--json')
  $bId=Resolve-JobId -Object $bc -Label 'telemetry'
  $bj=Invoke-OpenClawJson -Args @('cron','get',$bId)
  Assert-CronJob -Job $bj -Label 'Telemetry' -ExpectedExpr '*/5 * * * *' -ExpectedArgv $bridgeArgv -ExpectedCwd $Root
  Good "Telemetry job stored exact argv and verified: $bId"
}catch{
  if($rId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$rId,'--json')}catch{}}
  if($bId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$bId,'--json')}catch{}}
  throw
}

Step 'Execute both jobs through the real scheduler and verify run history'
try{
  Assert-RunSuccess -JobId $rId -Label 'Reconciler' -Wait '6m'
  Assert-RunSuccess -JobId $bId -Label 'Telemetry' -Wait '4m'
}catch{
  Note 'Scheduler execution proof failed; removing newly created jobs to fail closed.'
  if($rId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$rId,'--json')}catch{}}
  if($bId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$bId,'--json')}catch{}}
  throw
}

Step 'Verify published autonomy evidence through GitHub'
$gh=Get-Command gh.exe -ErrorAction SilentlyContinue
if(-not $gh){$gh=Get-Command gh -ErrorAction SilentlyContinue}
if(-not $gh){throw 'GitHub CLI not found.'}
$remote=Invoke-ExactNative -Executable $gh.Source -Argv @('api',("repos/{0}/contents/reports/autonomy-latest.json" -f $Repo))
if($remote.ExitCode -ne 0){throw "Remote autonomy telemetry fetch failed :: $($remote.Stderr)"}
$remoteObj=$remote.Stdout|ConvertFrom-Json
if(-not $remoteObj.sha){throw 'Remote autonomy telemetry returned no content SHA.'}
Good ("Remote autonomy evidence independently fetched: "+[string]$remoteObj.sha)

Step 'Write installation proof and rollback'
$manifest=[ordered]@{
  schema=1
  version='0.1i'
  installed_at=(Get-Date).ToString('o')
  openclaw_version=$script:Ocl.Version
  native_transport='ProcessStartInfo-Win32-argv-quoting-v1'
  actuator_blob=$Expected['kevin-autonomy-actuator-v0.1.ps1']
  reconciler_job_id=$rId
  telemetry_job_id=$bId
  removed_prior_job_ids=@($removed)
  remote_autonomy_sha=[string]$remoteObj.sha
}
$manifestPath=Join-Path $Root 'install-manifest-v0.1i.json'
Write-JsonAtomic -Object $manifest -Path $manifestPath
Write-JsonAtomic -Object $manifest -Path (Join-Path $EvidenceDir ("$Stamp-install-proof-v0.1i.json"))

$nodeLiteral=$script:Ocl.Node.Replace("'","''")
$cliLiteral=$script:Ocl.Cli.Replace("'","''")
$rollback=@"
`$ErrorActionPreference='Continue'
`$node='$nodeLiteral'
`$cli='$cliLiteral'
& `$node `$cli cron remove '$rId' --json | Out-Null
& `$node `$cli cron remove '$bId' --json | Out-Null
Write-Host 'Kevin Autonomy scheduler v0.1i jobs removed.'
"@
$rollbackPath=Join-Path $Root 'ROLLBACK-v0.1i.ps1'
[IO.File]::WriteAllText($rollbackPath,$rollback,(New-Object Text.UTF8Encoding($false)))

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host 'KEVIN AUTONOMY SCHEDULER v0.1i INSTALLED + PROVEN' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host 'Reconciler: every 3 minutes, exact cron schedule'
Write-Host 'Telemetry: every 5 minutes, exact cron schedule'
Write-Host 'Transport: WinPS 5.1 exact argv via ProcessStartInfo'
Write-Host 'Stored argv: independently read back and matched element-by-element'
Write-Host 'Execution: both jobs manually run through cron and verified in run history'
Write-Host "Manifest: $manifestPath"
Write-Host "Evidence: $EvidenceDir"
Write-Host "Rollback: $rollbackPath"
