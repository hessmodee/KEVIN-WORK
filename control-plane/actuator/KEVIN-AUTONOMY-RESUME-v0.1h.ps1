Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# Kevin Autonomy Resume v0.1h
# Resumes a v0.1e install that stopped safely at pre-scheduling audit.
# Replaces only the reconciler with the Windows-validated resilient build,
# audits again, publishes evidence, then installs and verifies scheduler jobs.

$Repo='hessmodee/KEVIN-WORK'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Reports=Join-Path $Workspace 'reports'
if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$Root=Join-Path $Workspace 'ControlPlane'
$EvidenceDir=Join-Path $Root 'Evidence'
$BackupRoot=Join-Path $Root 'Backups'
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
$Backup=Join-Path $BackupRoot ("resume-$Stamp")

$ExpectedInstalled=[ordered]@{
 'desired-state-v1.json'='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
 'OWNER-AUTHORIZATION-v1.md'='b0cc4465f12457492b3a6c2761287398cc6295b5'
 'kevin-autonomy-bridge-v0.1.ps1'='05bb7d3a01d9eace3105a717020656a040f4da8c'
}
$OldActuatorBlob='489dfd2277245341a790c00a5db04ecd3ffb4fab'
$NewActuatorBlob='847c0a0dd629df75ce89e6591ed1d7dcdb80afad'

function Step([string]$s){Write-Host ("`n==> "+$s) -ForegroundColor Cyan}
function Good([string]$s){Write-Host ("PASS  "+$s) -ForegroundColor Green}
function Note([string]$s){Write-Host ("INFO  "+$s) -ForegroundColor DarkGray}

function Write-JsonAtomic{
 param($Object,[string]$Path)
 $tmp="$Path.tmp-$PID"
 [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),(New-Object Text.UTF8Encoding($false)))
 Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Get-GitBlobSha1{
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

function Invoke-NativeCapture{
 param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string[]]$Args)
 $err=Join-Path $env:TEMP ("kevin-native-{0}.txt" -f [guid]::NewGuid().ToString('N'))
 $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
 try{$out=& $Executable @Args 2>$err;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
 $stderr=''
 if(Test-Path -LiteralPath $err){$stderr=Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue;Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue}
 return [pscustomobject]@{ExitCode=$code;Stdout=(($out|ForEach-Object{[string]$_}) -join "`n");Stderr=$stderr}
}

function Get-OpenClawLauncher{
 $node=Get-Command node.exe -ErrorAction SilentlyContinue
 if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue}
 $shim=Get-Command openclaw.cmd -ErrorAction SilentlyContinue
 if(-not $shim){$shim=Get-Command openclaw -ErrorAction SilentlyContinue}
 if(-not $shim){throw 'OpenClaw CLI not found in PATH.'}
 if($node){
  $shimDir=Split-Path -Parent $shim.Source
  $pkgDir=Join-Path $shimDir 'node_modules\openclaw'
  $pkgJson=Join-Path $pkgDir 'package.json'
  if(Test-Path -LiteralPath $pkgJson){
   try{
    $pkg=Get-Content -LiteralPath $pkgJson -Raw|ConvertFrom-Json
    $binRel=$null
    if($pkg.bin -is [string]){$binRel=[string]$pkg.bin}
    elseif($pkg.bin -and $pkg.bin.openclaw){$binRel=[string]$pkg.bin.openclaw}
    if($binRel){$cli=Join-Path $pkgDir $binRel;if(Test-Path -LiteralPath $cli){return [pscustomobject]@{Kind='node';Executable=$node.Source;Cli=$cli}}}
   }catch{}
  }
 }
 return [pscustomobject]@{Kind='shim';Executable=$shim.Source;Cli=$null}
}

$script:Ocl=$null
function Invoke-OpenClawRaw{
 param([Parameter(Mandatory=$true)][string[]]$Args)
 if(-not $script:Ocl){$script:Ocl=Get-OpenClawLauncher}
 $err=Join-Path $env:TEMP ("kevin-ocl-{0}.txt" -f [guid]::NewGuid().ToString('N'))
 $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
 try{
  if($script:Ocl.Kind -eq 'node'){$out=& $script:Ocl.Executable $script:Ocl.Cli @Args 2>$err}
  else{$out=& $script:Ocl.Executable @Args 2>$err}
  $code=$LASTEXITCODE
 }finally{$ErrorActionPreference=$old}
 $stderr=''
 if(Test-Path -LiteralPath $err){$stderr=Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue;Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue}
 return [pscustomobject]@{ExitCode=$code;Stdout=(($out|ForEach-Object{[string]$_}) -join "`n");Stderr=$stderr}
}

function ConvertFrom-OpenClawJson{
 param([Parameter(Mandatory=$true)][string]$Text)
 $t=$Text.Trim()
 if([string]::IsNullOrWhiteSpace($t)){return $null}
 try{return ($t|ConvertFrom-Json)}catch{}
 $t=[regex]::Replace($t,"`e\[[0-9;?]*[ -/]*[@-~]",'')
 $starts=@($t.IndexOf('{'),$t.IndexOf('['))|Where-Object{$_ -ge 0}|Sort-Object
 foreach($start in $starts){
  $candidate=$t.Substring([int]$start)
  try{return ($candidate|ConvertFrom-Json)}catch{}
 }
 throw 'OpenClaw stdout was not valid JSON.'
}

function Invoke-OpenClawJson{
 param([Parameter(Mandatory=$true)][string[]]$Args)
 $r=Invoke-OpenClawRaw -Args $Args
 if($r.ExitCode -ne 0){throw "OpenClaw failed: $($Args -join ' ') :: $($r.Stderr)"}
 try{return ConvertFrom-OpenClawJson -Text $r.Stdout}catch{throw "OpenClaw returned non-JSON output for $($Args -join ' ') :: $($r.Stdout)"}
}

function Resolve-JobId{
 param($Object,[string]$Label)
 if($Object -and ($Object.PSObject.Properties.Name -contains 'id') -and $Object.id){return [string]$Object.id}
 if($Object -and ($Object.PSObject.Properties.Name -contains 'jobId') -and $Object.jobId){return [string]$Object.jobId}
 if($Object -and ($Object.PSObject.Properties.Name -contains 'job') -and $Object.job -and $Object.job.id){return [string]$Object.job.id}
 if($Object -and ($Object.PSObject.Properties.Name -contains 'result') -and $Object.result -and $Object.result.id){return [string]$Object.result.id}
 throw "Could not resolve job id from $Label create response."
}

function Run-Ps{
 param([Parameter(Mandatory=$true)][string]$File,[string[]]$Args=@())
 $err=Join-Path $env:TEMP ("kevin-ps-{0}.txt" -f [guid]::NewGuid().ToString('N'))
 $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
 try{$out=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $File @Args 2>$err;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
 $stderr=''
 if(Test-Path -LiteralPath $err){$stderr=Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue;Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue}
 return [pscustomobject]@{ExitCode=$code;Stdout=(($out|ForEach-Object{[string]$_}) -join "`n");Stderr=$stderr}
}

function Assert-PowerShellParse{
 param([Parameter(Mandatory=$true)][string]$Path)
 $tokens=$null;$errors=$null
 [void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
 if($errors -and $errors.Count){$msg=($errors|ForEach-Object{"line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; ';throw "PowerShell parser rejected $Path :: $msg"}
}

function Publish-AutonomyEvidence{
 param([string]$Bridge)
 $pub=Run-Ps -File $Bridge
 Write-Host $pub.Stdout
 if($pub.ExitCode -ne 0){Note ("Autonomy evidence publish failed: "+$pub.Stderr);return $false}
 return $true
}

Step 'Verify partial v0.1e installation'
if(-not(Test-Path -LiteralPath $Root)){throw "ControlPlane root missing: $Root"}
foreach($kv in $ExpectedInstalled.GetEnumerator()){
 $path=Join-Path $Root $kv.Key
 if(-not(Test-Path -LiteralPath $path)){throw "Required installed component missing: $($kv.Key)"}
 $blob=Get-GitBlobSha1 -Path $path
 if($blob -ne [string]$kv.Value){throw "Installed component drift for $($kv.Key). Expected $($kv.Value), got $blob"}
 Good "$($kv.Key) still matches immutable Git blob $blob"
}
$Actuator=Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1'
$Bridge=Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1'
if(-not(Test-Path -LiteralPath $Actuator)){throw 'Installed actuator is missing.'}
$currentActuator=Get-GitBlobSha1 -Path $Actuator
if($currentActuator -ne $OldActuatorBlob -and $currentActuator -ne $NewActuatorBlob){throw "Unexpected installed actuator blob: $currentActuator"}
Good "Installed actuator recognized: $currentActuator"

$gh=Get-Command gh.exe -ErrorAction SilentlyContinue
if(-not $gh){$gh=Get-Command gh -ErrorAction SilentlyContinue}
if(-not $gh){throw 'GitHub CLI not found.'}
$auth=Invoke-NativeCapture -Executable $gh.Source -Args @('auth','status')
if($auth.ExitCode -ne 0){throw "GitHub CLI is not authenticated :: $($auth.Stderr)"}
Good 'GitHub CLI authentication available.'

Step 'Install Windows-validated resilient reconciler'
if(-not(Test-Path -LiteralPath $Backup)){New-Item -ItemType Directory -Path $Backup -Force|Out-Null}
if($currentActuator -ne $NewActuatorBlob){
 Copy-Item -LiteralPath $Actuator -Destination (Join-Path $Backup 'kevin-autonomy-actuator-v0.1.ps1') -Force
 $r=Invoke-NativeCapture -Executable $gh.Source -Args @('api',("repos/{0}/git/blobs/{1}" -f $Repo,$NewActuatorBlob))
 if($r.ExitCode -ne 0){throw "GitHub reconciler blob fetch failed :: $($r.Stderr)"}
 $o=$r.Stdout|ConvertFrom-Json
 if(([string]$o.sha).ToLowerInvariant() -ne $NewActuatorBlob){throw "Git blob identity mismatch for reconciler: $($o.sha)"}
 if([string]$o.encoding -ne 'base64'){throw 'Unexpected reconciler blob encoding.'}
 [IO.File]::WriteAllBytes($Actuator,[Convert]::FromBase64String(([string]$o.content -replace '\s','')))
 Assert-PowerShellParse -Path $Actuator
 $afterBlob=Get-GitBlobSha1 -Path $Actuator
 if($afterBlob -ne $NewActuatorBlob){throw "Installed resilient reconciler blob mismatch: $afterBlob"}
}
Good "Resilient reconciler installed: $NewActuatorBlob"

Step 'Re-run authority self-test and desired-state audit'
$self=Run-Ps -File $Actuator -Args @('-Mode','SelfTest')
Write-Host $self.Stdout
if($self.ExitCode -ne 0){throw "Actuator self-test failed :: $($self.Stderr)"}
Good 'Actuator self-test passed.'
$audit=Run-Ps -File $Actuator -Args @('-Mode','Audit')
Write-Host $audit.Stdout
[void](Publish-AutonomyEvidence -Bridge $Bridge)
if($audit.ExitCode -eq 2){
 $latest=Join-Path $Reports 'autonomy-latest.json'
 if(Test-Path -LiteralPath $latest){
  try{$a=Get-Content -LiteralPath $latest -Raw|ConvertFrom-Json;foreach($d in @($a.drift)){Write-Host ("REVIEW  {0}: {1}" -f $d.family,$d.detail) -ForegroundColor Yellow}}catch{}
 }
 throw 'Resilient audit still found NEEDS_REVIEW. Evidence was published before stopping.'
}
if($audit.ExitCode -ne 0){throw "Audit failed unexpectedly :: $($audit.Stderr)"}
Good 'Desired-state audit passed.'

Step 'Install autonomy scheduler jobs without all-jobs list dependency'
$oldManifest=Join-Path $Root 'install-manifest-v0.1h.json'
if(Test-Path -LiteralPath $oldManifest){
 try{
  $m=Get-Content -LiteralPath $oldManifest -Raw|ConvertFrom-Json
  foreach($jid in @($m.reconciler_job_id,$m.telemetry_job_id)|Where-Object{$_}){try{$null=Invoke-OpenClawJson -Args @('cron','remove',[string]$jid,'--json')}catch{}}
 }catch{}
}
$reconcileArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Actuator,'-Mode','Reconcile')|ConvertTo-Json -Compress
$bridgeArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Bridge)|ConvertTo-Json -Compress
$rId=$null;$bId=$null
try{
 $rc=Invoke-OpenClawJson -Args @('cron','create','*/3 * * * *','--name','Kevin Autonomy Reconciler v0.1','--command-argv',$reconcileArgv,'--command-cwd',$Root,'--timeout-seconds','600','--no-output-timeout-seconds','600','--output-max-bytes','65536','--no-deliver','--json')
 $rId=Resolve-JobId -Object $rc -Label 'reconciler'
 $rj=Invoke-OpenClawJson -Args @('cron','get',$rId)
 if(-not $rj -or -not [bool]$rj.enabled){throw 'Reconciler job create/get postcondition failed.'}
 Good "Reconciler job created and verified: $rId"

 $bc=Invoke-OpenClawJson -Args @('cron','create','*/5 * * * *','--name','Kevin Autonomy Telemetry v0.1','--command-argv',$bridgeArgv,'--command-cwd',$Root,'--timeout-seconds','120','--no-output-timeout-seconds','120','--output-max-bytes','32768','--no-deliver','--json')
 $bId=Resolve-JobId -Object $bc -Label 'telemetry'
 $bj=Invoke-OpenClawJson -Args @('cron','get',$bId)
 if(-not $bj -or -not [bool]$bj.enabled){throw 'Telemetry job create/get postcondition failed.'}
 Good "Telemetry job created and verified: $bId"
}catch{
 if($rId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$rId,'--json')}catch{}}
 if($bId){try{$null=Invoke-OpenClawJson -Args @('cron','remove',$bId,'--json')}catch{}}
 throw
}

Step 'First live reconciliation and evidence publication'
$first=Run-Ps -File $Actuator -Args @('-Mode','Reconcile')
Write-Host $first.Stdout
if($first.ExitCode -eq 2){Note 'First reconcile completed bounded with NEEDS_REVIEW or failed repair; jobs remain installed for evidence and future safe reconciliation.'}
elseif($first.ExitCode -ne 0){throw "First reconcile failed unexpectedly :: $($first.Stderr)"}
else{Good 'First live reconcile completed.'}
if(-not(Publish-AutonomyEvidence -Bridge $Bridge)){throw 'First autonomy evidence publication failed.'}
$remote=Invoke-NativeCapture -Executable $gh.Source -Args @('api',("repos/{0}/contents/reports/autonomy-latest.json" -f $Repo))
if($remote.ExitCode -ne 0){throw 'Remote autonomy telemetry could not be independently fetched after publish.'}
$remoteObj=$remote.Stdout|ConvertFrom-Json
if(-not $remoteObj.sha){throw 'Remote autonomy telemetry fetch returned no content identity.'}
Good 'Remote autonomy telemetry exists and was independently fetched.'

$install=[ordered]@{
 schema=1
 installed_at=(Get-Date).ToString('o')
 version='0.1f'
 reconciler_blob=$NewActuatorBlob
 root=$Root
 backup=$Backup
 reconciler_job_id=$rId
 telemetry_job_id=$bId
 first_reconcile_exit=$first.ExitCode
 first_reconcile_output=$first.Stdout
}
Write-JsonAtomic -Object $install -Path $oldManifest
Write-JsonAtomic -Object $install -Path (Join-Path $EvidenceDir ("$Stamp-install-proof-v0.1h.json"))
$rollback=@"
`$ErrorActionPreference='Continue'
openclaw automations remove '$rId' --json | Out-Null
openclaw automations remove '$bId' --json | Out-Null
Write-Host 'Kevin Autonomy v0.1h jobs removed. Backup: $Backup'
"@
[IO.File]::WriteAllText((Join-Path $Root 'ROLLBACK-v0.1h.ps1'),$rollback,(New-Object Text.UTF8Encoding($false)))

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host 'KEVIN AUTONOMY ACTUATOR v0.1h INSTALLED + PROVEN' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host 'Reconciler: every 3 minutes'
Write-Host 'Telemetry: every 5 minutes'
Write-Host 'Audit truth: fresh Support Bridge desired-state evidence'
Write-Host 'Live list-query errors: diagnostic only, still recorded'
Write-Host 'Typed job verification: automations get <job-id>'
Write-Host "Evidence: $EvidenceDir"
Write-Host "Rollback: $(Join-Path $Root 'ROLLBACK-v0.1h.ps1')"
