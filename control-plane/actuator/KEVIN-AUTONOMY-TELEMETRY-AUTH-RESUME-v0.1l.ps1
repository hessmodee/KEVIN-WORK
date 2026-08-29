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
      [void]$sb.Append('\"');$slashes=0;continue
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
  $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  $p=New-Object System.Diagnostics.Process;$p.StartInfo=$psi
  if(-not $p.Start()){throw "Could not start native process: $Executable"}
  $outTask=$p.StandardOutput.ReadToEndAsync();$errTask=$p.StandardError.ReadToEndAsync();$p.WaitForExit()
  $r=[pscustomobject]@{ExitCode=[int]$p.ExitCode;Stdout=[string]$outTask.Result;Stderr=[string]$errTask.Result;CommandLine=$psi.Arguments}
  $p.Dispose();return $r
}

function Test-ExactNativeJsonTransport {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js required.'}
  $probe=Join-Path $env:TEMP ("kevin-argv-probe-{0}.js" -f [guid]::NewGuid().ToString('N'))
  $js=@'
const args=process.argv.slice(2);const i=args.indexOf('--command-argv');if(i<0||i+1>=args.length)process.exit(31);let p;try{p=JSON.parse(args[i+1]);}catch{process.exit(32);}const ok=Array.isArray(p)&&p.length===4&&p[0]==='powershell.exe'&&p[1]==='C:\\Path With Space\\x.ps1'&&p[2]==='A"B'&&p[3]==='tail\\';process.exit(ok?0:33);
'@
  [IO.File]::WriteAllText($probe,$js,(New-Object Text.UTF8Encoding($false)))
  try{$json=@('powershell.exe','C:\Path With Space\x.ps1','A"B','tail\')|ConvertTo-Json -Compress;$r=Invoke-ExactNative -Executable $node.Source -Argv @($probe,'--command-argv',$json);if($r.ExitCode -ne 0){throw "Exact native transport failed: $($r.ExitCode)"}}finally{Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue}
  return $true
}

if($Mode -eq 'ValidateTransport'){[void](Test-ExactNativeJsonTransport);Write-Output 'TRANSPORT_OK';exit 0}

$Repo='hessmodee/KEVIN-WORK'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Root=Join-Path $Workspace 'ControlPlane'
$EvidenceDir=Join-Path $Root 'Evidence';$BackupDir=Join-Path $Root 'Backups'
foreach($d in @($EvidenceDir,$BackupDir)){if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}}
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
$DesiredPath=Join-Path $Root 'desired-state-v1.json';$OwnerPath=Join-Path $Root 'OWNER-AUTHORIZATION-v1.md';$Actuator=Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1';$Bridge=Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1'
$DesiredBlob='610e89b426ac0e7fa947f6575c977aa0a08efbe6';$OwnerBlob='b0cc4465f12457492b3a6c2761287398cc6295b5';$ActuatorBlob='847c0a0dd629df75ce89e6591ed1d7dcdb80afad';$OldBridgeBlob='d542581dc4783fc8f34ede34edf47e4427df7091';$NewBridgeBlob='2b0a4f168b2d5f64b1979063eaf62807373e25ce'

function Get-GitBlobSha1 {param([Parameter(Mandatory=$true)][string]$Path);$bytes=[IO.File]::ReadAllBytes($Path);$header=[Text.Encoding]::ASCII.GetBytes(("blob {0}" -f $bytes.Length));$all=New-Object byte[] ($header.Length+1+$bytes.Length);[Buffer]::BlockCopy($header,0,$all,0,$header.Length);$all[$header.Length]=0;[Buffer]::BlockCopy($bytes,0,$all,$header.Length+1,$bytes.Length);$sha=[Security.Cryptography.SHA1]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
function Parse-PowerShellFile([string]$Path){$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors);if($errors -and $errors.Count){$msg=($errors|ForEach-Object{"line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; ';throw "PowerShell parser rejected $Path :: $msg"}}
function Run-Ps {param([Parameter(Mandatory=$true)][string]$File,[string[]]$Args=@());return Invoke-ExactNative -Executable 'powershell.exe' -Argv (@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$File)+@($Args))}

function Resolve-Gh {$gh=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not $gh){$gh=Get-Command gh -ErrorAction SilentlyContinue};if(-not $gh){throw 'GitHub CLI not found.'};return $gh.Source}
$script:GhExe=$null
function Invoke-GhRaw {param([Parameter(Mandatory=$true)][string[]]$Args);if(-not $script:GhExe){$script:GhExe=Resolve-Gh};return Invoke-ExactNative -Executable $script:GhExe -Argv $Args}
function Get-GitBlobBytes {param([string]$Blob);$r=Invoke-GhRaw -Args @('api',("repos/{0}/git/blobs/{1}" -f $Repo,$Blob));if($r.ExitCode -ne 0){throw "GitHub blob fetch failed for $Blob :: $($r.Stderr)"};$o=$r.Stdout|ConvertFrom-Json;if(([string]$o.sha).ToLowerInvariant() -ne $Blob.ToLowerInvariant()){throw "GitHub blob identity mismatch for $Blob"};return [Convert]::FromBase64String(([string]$o.content -replace '\s',''))}

function Get-OpenClawNodeLauncher {$node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'Node.js not found.'};$shim=Get-Command openclaw.cmd -ErrorAction SilentlyContinue;if(-not $shim){$shim=Get-Command openclaw -ErrorAction SilentlyContinue};if(-not $shim){throw 'OpenClaw CLI not found.'};$pkgDir=Join-Path (Split-Path -Parent $shim.Source) 'node_modules\openclaw';$pkg=Get-Content -LiteralPath (Join-Path $pkgDir 'package.json') -Raw|ConvertFrom-Json;$binRel=if($pkg.bin -is [string]){[string]$pkg.bin}else{[string]$pkg.bin.openclaw};return [pscustomobject]@{Node=$node.Source;Cli=(Join-Path $pkgDir $binRel);Version=[string]$pkg.version}}
function ConvertFrom-OpenClawJson {param([AllowEmptyString()][string]$Text);if([string]::IsNullOrWhiteSpace($Text)){return $null};$t=$Text.Trim();try{return ($t|ConvertFrom-Json)}catch{};$t=[regex]::Replace($t,"`e\[[0-9;?]*[ -/]*[@-~]",'');$starts=@($t.IndexOf('{'),$t.IndexOf('['))|Where-Object{$_ -ge 0}|Sort-Object;foreach($start in $starts){try{return ($t.Substring([int]$start)|ConvertFrom-Json)}catch{}};throw 'OpenClaw stdout was not valid JSON.'}
$script:Ocl=$null
function Invoke-OpenClawRaw {param([Parameter(Mandatory=$true)][string[]]$Args);if(-not $script:Ocl){$script:Ocl=Get-OpenClawNodeLauncher};return Invoke-ExactNative -Executable $script:Ocl.Node -Argv (@($script:Ocl.Cli)+@($Args))}
function Invoke-OpenClawJson {param([Parameter(Mandatory=$true)][string[]]$Args);$r=Invoke-OpenClawRaw -Args $Args;$obj=$null;try{$obj=ConvertFrom-OpenClawJson -Text $r.Stdout}catch{};if($r.ExitCode -ne 0){throw ("OpenClaw failed: {0} :: stdout={1} :: stderr={2}" -f ($Args -join ' '),($r.Stdout.Trim()),($r.Stderr.Trim()))};return $obj}

function Get-OptionalPropertyValue {param($Object,[Parameter(Mandatory=$true)][string]$Name);if($null -eq $Object){return $null};$p=$Object.PSObject.Properties[$Name];if($null -eq $p){return $null};return $p.Value}
function Resolve-JobId {param($Object,[string]$Label);if($null -eq $Object){throw "Could not resolve $Label job id: null response."};foreach($n in @('id','jobId')){$v=Get-OptionalPropertyValue $Object $n;if($v){return [string]$v}};$job=Get-OptionalPropertyValue $Object 'job';if($job){$v=Get-OptionalPropertyValue $job 'id';if($v){return [string]$v}};$result=Get-OptionalPropertyValue $Object 'result';if($result){$v=Get-OptionalPropertyValue $result 'id';if($v){return [string]$v}};throw "Could not resolve $Label job id. Properties: $(@($Object.PSObject.Properties.Name)-join ',')"}
function Assert-StringArrayEqual {param([string[]]$Actual,[string[]]$Expected,[string]$Label);if(@($Actual).Count -ne @($Expected).Count){throw "$Label argv length mismatch."};for($i=0;$i -lt @($Expected).Count;$i++){if([string]$Actual[$i] -cne [string]$Expected[$i]){throw "$Label argv mismatch at $i."}}}
function Assert-CommandJob {param($Job,[string]$Label,[string]$Expr,[string[]]$Argv,[string]$Cwd);if(-not $Job){throw "$Label job missing."};if(-not [bool]$Job.enabled){throw "$Label disabled."};if([string](Get-OptionalPropertyValue (Get-OptionalPropertyValue $Job 'payload') 'kind') -ne 'command'){throw "$Label payload kind mismatch."};$payload=Get-OptionalPropertyValue $Job 'payload';Assert-StringArrayEqual @($payload.argv) $Argv $Label;if([string]$payload.cwd -cne $Cwd){throw "$Label cwd mismatch."};$schedule=Get-OptionalPropertyValue $Job 'schedule';if([string]$schedule.kind -ne 'cron' -or [string]$schedule.expr -cne $Expr){throw "$Label schedule mismatch."}}
function Assert-RunOk {param([string]$JobId,[string]$Label,[string]$Wait='4m');$run=Invoke-OpenClawRaw -Args @('cron','run',$JobId,'--wait','--wait-timeout',$Wait,'--poll-interval','2s');$hist=Invoke-OpenClawRaw -Args @('cron','runs','--id',$JobId,'--limit','3');$h=$null;try{$h=ConvertFrom-OpenClawJson $hist.Stdout}catch{};$entries=@();if($h){$e=Get-OptionalPropertyValue $h 'entries';if($e){$entries=@($e)}else{$e=Get-OptionalPropertyValue $h 'runs';if($e){$entries=@($e)}}};$entry=if($entries.Count){$entries[0]}else{$null};if($run.ExitCode -eq 0 -and $entry -and [string]$entry.status -eq 'ok'){Good "$Label scheduler execution verified.";return};$detail=if($entry){"status=$([string]$entry.status) error=$([string](Get-OptionalPropertyValue $entry 'error')) summary=$([string](Get-OptionalPropertyValue $entry 'summary'))"}else{"stdout=$($run.Stdout.Trim()) stderr=$($run.Stderr.Trim())"};throw "$Label scheduler execution failed :: $detail"}

Step 'Verify installed autonomy core and current bridge'
foreach($kv in ([ordered]@{$DesiredPath=$DesiredBlob;$OwnerPath=$OwnerBlob;$Actuator=$ActuatorBlob}).GetEnumerator()){if(-not(Test-Path -LiteralPath $kv.Key)){throw "Missing component $($kv.Key)"};$actual=Get-GitBlobSha1 $kv.Key;if($actual -ne [string]$kv.Value){throw "Component drift: $($kv.Key) expected $($kv.Value), got $actual"};Good "$(Split-Path $kv.Key -Leaf) verified: $actual"}
if(-not(Test-Path -LiteralPath $Bridge)){throw 'Autonomy bridge missing.'};$currentBridge=Get-GitBlobSha1 $Bridge;if(@($OldBridgeBlob,$NewBridgeBlob) -notcontains $currentBridge){throw "Unexpected bridge blob: $currentBridge"};Good "Current bridge recognized: $currentBridge"

Step 'Prove runtime and exact argv transport'
[void](Test-ExactNativeJsonTransport);Good 'WinPS 5.1 exact argv transport passed.';$script:Ocl=Get-OpenClawNodeLauncher;if($script:Ocl.Version -ne '2026.7.1-2'){throw "Expected OpenClaw 2026.7.1-2, found $($script:Ocl.Version)"};Good 'OpenClaw 2026.7.1-2 resolved.';$script:GhExe=Resolve-Gh;Good ("GitHub CLI resolved: "+$script:GhExe)

Step 'Install credential-isolated telemetry bridge'
if($currentBridge -ne $NewBridgeBlob){$backup=Join-Path $BackupDir ("$Stamp-kevin-autonomy-bridge-v0.1.ps1");Copy-Item -LiteralPath $Bridge -Destination $backup -Force;$bytes=Get-GitBlobBytes $NewBridgeBlob;[IO.File]::WriteAllBytes($Bridge,$bytes)}else{$backup=''}
if((Get-GitBlobSha1 $Bridge) -ne $NewBridgeBlob){throw 'Bridge install hash mismatch.'};Parse-PowerShellFile $Bridge;Good "Credential-isolated bridge installed: $NewBridgeBlob"

Step 'Reproduce poisoned scheduler token environment before cron mutation'
$names=@('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN','KEVIN_GH_AUTH_MODE','KEVIN_GH_EXE');$saved=@{}
foreach($n in $names){$item=Get-Item -LiteralPath ("Env:{0}" -f $n) -ErrorAction SilentlyContinue;$saved[$n]=if($item){[pscustomobject]@{Exists=$true;Value=[string]$item.Value}}else{[pscustomobject]@{Exists=$false;Value=''}}}
try{
  $env:GH_TOKEN='kevin-intentional-invalid-token';$env:GITHUB_TOKEN='kevin-intentional-invalid-token';$env:GH_ENTERPRISE_TOKEN='kevin-intentional-invalid-token';$env:GITHUB_ENTERPRISE_TOKEN='kevin-intentional-invalid-token';$env:KEVIN_GH_AUTH_MODE='stored';$env:KEVIN_GH_EXE=$script:GhExe
  $poison=Run-Ps -File $Bridge;Write-Host $poison.Stdout
  if($poison.ExitCode -ne 0){throw "Stored-credential poison test failed :: stdout=$($poison.Stdout.Trim()) :: stderr=$($poison.Stderr.Trim())"}
  if($poison.Stdout -notmatch 'AUTONOMY_AUTH mode=stored inherited_token_env=removed' -or $poison.Stdout -notmatch 'AUTONOMY_(PUBLISHED|UNCHANGED)'){throw "Stored-credential poison test did not prove sanitization + GitHub access: $($poison.Stdout)"}
} finally {
  foreach($n in $names){if($saved[$n].Exists){[Environment]::SetEnvironmentVariable($n,[string]$saved[$n].Value,[EnvironmentVariableTarget]::Process)}else{[Environment]::SetEnvironmentVariable($n,$null,[EnvironmentVariableTarget]::Process)}}
}
Good 'Bad inherited GitHub token variables were neutralized and stored Windows gh credential succeeded.'

Step 'Verify or restore the already-proven Reconciler job'
$reconcileArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Actuator,'-Mode','Reconcile')
$list=Invoke-OpenClawJson @('cron','list','--all','--json');$jobs=@();if($list){$j=Get-OptionalPropertyValue $list 'jobs';if($j){$jobs=@($j)}}
$recs=@($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Autonomy Reconciler v0.1'})
$rId=$null
if($recs.Count -eq 1){$rId=[string](Get-OptionalPropertyValue $recs[0] 'id');$rj=Invoke-OpenClawJson @('cron','get',$rId);Assert-CommandJob $rj 'Reconciler' '*/3 * * * *' $reconcileArgv $Root;Good "Existing proven Reconciler preserved: $rId"}
elseif($recs.Count -eq 0){$rc=Invoke-OpenClawJson @('cron','create','*/3 * * * *','--exact','--name','Kevin Autonomy Reconciler v0.1','--declaration-key','kevin-autonomy-reconciler-v0.1','--session','isolated','--command-argv',($reconcileArgv|ConvertTo-Json -Compress),'--command-cwd',$Root,'--timeout-seconds','600','--no-output-timeout-seconds','600','--output-max-bytes','65536','--no-deliver','--json');$rId=Resolve-JobId $rc 'Reconciler';$rj=Invoke-OpenClawJson @('cron','get',$rId);Assert-CommandJob $rj 'Reconciler' '*/3 * * * *' $reconcileArgv $Root;Assert-RunOk $rId 'Reconciler' '6m';Good "Reconciler restored and proven: $rId"}
else{throw "Multiple Reconciler jobs found ($($recs.Count)); refusing ambiguous mutation."}

Step 'Replace telemetry job with stored-credential mode'
foreach($j in @($jobs|Where-Object{[string](Get-OptionalPropertyValue $_ 'name') -eq 'Kevin Autonomy Telemetry v0.1'})){ $jid=[string](Get-OptionalPropertyValue $j 'id');if($jid){$null=Invoke-OpenClawJson @('cron','remove',$jid,'--json');Note "Removed prior telemetry job: $jid"}}
$bridgeArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Bridge);$bridgeJson=$bridgeArgv|ConvertTo-Json -Compress
$bc=Invoke-OpenClawJson @('cron','create','*/5 * * * *','--exact','--name','Kevin Autonomy Telemetry v0.1','--declaration-key','kevin-autonomy-telemetry-v0.1','--session','isolated','--command-argv',$bridgeJson,'--command-cwd',$Root,'--timeout-seconds','120','--no-output-timeout-seconds','120','--output-max-bytes','32768','--command-env',("KEVIN_GH_EXE={0}" -f $script:GhExe),'--command-env','KEVIN_GH_AUTH_MODE=stored','--command-env','GH_PROMPT_DISABLED=1','--no-deliver','--json')
$bId=Resolve-JobId $bc 'Telemetry';$bj=Invoke-OpenClawJson @('cron','get',$bId);Assert-CommandJob $bj 'Telemetry' '*/5 * * * *' $bridgeArgv $Root
$penv=Get-OptionalPropertyValue (Get-OptionalPropertyValue $bj 'payload') 'env';if(-not $penv){throw 'Telemetry env missing.'};if([string](Get-OptionalPropertyValue $penv 'KEVIN_GH_EXE') -cne $script:GhExe){throw 'Stored KEVIN_GH_EXE mismatch.'};if([string](Get-OptionalPropertyValue $penv 'KEVIN_GH_AUTH_MODE') -cne 'stored'){throw 'Stored KEVIN_GH_AUTH_MODE mismatch.'};Good "Telemetry job stored exact argv + stored-credential mode: $bId"

Step 'Execute telemetry through real OpenClaw scheduler'
try{Assert-RunOk $bId 'Telemetry' '4m'}catch{try{$null=Invoke-OpenClawJson @('cron','remove',$bId,'--json')}catch{};throw}

Step 'Independently verify public autonomy telemetry'
$remote=Invoke-GhRaw @('api',("repos/{0}/contents/reports/autonomy-latest.json?ref=main" -f $Repo),'-H','Accept: application/vnd.github+json');if($remote.ExitCode -ne 0){throw "Remote autonomy telemetry fetch failed :: $($remote.Stderr)"};$ro=$remote.Stdout|ConvertFrom-Json;$decoded=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$ro.content -replace '\s','')))|ConvertFrom-Json;if([string]$decoded.kind -ne 'kevin-autonomy-public' -or -not $decoded.semantic_hash){throw 'Remote autonomy payload validation failed.'};Good ("Remote autonomy telemetry verified: "+[string]$ro.sha)

$manifest=[ordered]@{schema=1;version='0.1l';installed_at=(Get-Date).ToString('o');openclaw_version=$script:Ocl.Version;bridge_blob=$NewBridgeBlob;auth_mode='stored';reconciler_job_id=$rId;telemetry_job_id=$bId;remote_autonomy_sha=[string]$ro.sha}
$manifestPath=Join-Path $Root 'install-manifest-v0.1l.json';[IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)));[IO.File]::WriteAllText((Join-Path $EvidenceDir ("$Stamp-install-proof-v0.1l.json")),($manifest|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)))

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host 'KEVIN AUTONOMY TELEMETRY v0.1l INSTALLED + PROVEN' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Reconciler: preserved/proven every 3 minutes ($rId)"
Write-Host "Telemetry: proven every 5 minutes ($bId)"
Write-Host 'GitHub auth: stored Windows credential; inherited token variables isolated inside bridge process'
Write-Host "Manifest: $manifestPath"
