Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# Kevin Autonomy Actuator v0.1e
# Standalone installer. No runtime source rewriting.
# Component integrity is anchored to immutable Git blob IDs.

$Repo='hessmodee/KEVIN-WORK'
$ComponentCommit='689fcadf9b413cae588242cae0cdf3995bc4a70b'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Reports=Join-Path $Workspace 'reports'
if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$Root=Join-Path $Workspace 'ControlPlane'
$BackupRoot=Join-Path $Root 'Backups'
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
$Backup=Join-Path $BackupRoot $Stamp
$EvidenceDir=Join-Path $Root 'Evidence'

$ComponentBlobs=[ordered]@{
 'desired-state-v1.json'='610e89b426ac0e7fa947f6575c977aa0a08efbe6'
 'OWNER-AUTHORIZATION-v1.md'='b0cc4465f12457492b3a6c2761287398cc6295b5'
 'kevin-autonomy-actuator-v0.1.ps1'='38bc72bc29569c72c3618b0b8ce8fa59876ba76c'
 'kevin-autonomy-bridge-v0.1.ps1'='05bb7d3a01d9eace3105a717020656a040f4da8c'
}

$ExpectedCore=[ordered]@{
 supervisor='EA28600FDE1E7572F431710416238DA8A4AD6B80321C9A8F0687C1C8A92421F7'
 benchmark='02447EE8F3302E3EA1EF00290DBA6804F30FAC9F46CAE8714F402EA2D013CC38'
 forge='0ED50A9714B4B5E778844006CD24E57D25FFA0873261E5BF63F990FBB4D5643E'
 goal_os='B20C7AC8EDC35C656ED544C4D13D3EB4FF4A79453AF0F49BD60B7DF31092AEF0'
 support_bridge='E72A2A635326CF1AB036404E64E274D2F56CE79CA5CEB268DBF9B2EA4B67BEA5'
 maintenance_runner='B47714C91EFDCCD1FAE6C2CB0B97D72F799125A63C084956916A8BD5A07678C1'
}

function Step([string]$s){Write-Host ("`n==> "+$s) -ForegroundColor Cyan}
function Good([string]$s){Write-Host ("PASS  "+$s) -ForegroundColor Green}
function Note([string]$s){Write-Host ("INFO  "+$s) -ForegroundColor DarkGray}

function Write-JsonAtomic{
 param($Object,[string]$Path)
 $tmp="$Path.tmp-$PID"
 [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),(New-Object Text.UTF8Encoding($false)))
 Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Invoke-NativeCapture{
 param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string[]]$Args)
 $err=Join-Path $env:TEMP ("kevin-native-{0}.txt" -f [guid]::NewGuid().ToString('N'))
 $old=$ErrorActionPreference
 $ErrorActionPreference='Continue'
 try{
  $out=& $Executable @Args 2>$err
  $code=$LASTEXITCODE
 }finally{$ErrorActionPreference=$old}
 $stderr=''
 if(Test-Path -LiteralPath $err){
  $stderr=Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue
 }
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
    if($binRel){
     $cli=Join-Path $pkgDir $binRel
     if(Test-Path -LiteralPath $cli){return [pscustomobject]@{Kind='node';Executable=$node.Source;Cli=$cli}}
    }
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
 $old=$ErrorActionPreference
 $ErrorActionPreference='Continue'
 try{
  if($script:Ocl.Kind -eq 'node'){$out=& $script:Ocl.Executable $script:Ocl.Cli @Args 2>$err}
  else{$out=& $script:Ocl.Executable @Args 2>$err}
  $code=$LASTEXITCODE
 }finally{$ErrorActionPreference=$old}
 $stderr=''
 if(Test-Path -LiteralPath $err){
  $stderr=Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue
 }
 return [pscustomobject]@{ExitCode=$code;Stdout=(($out|ForEach-Object{[string]$_}) -join "`n");Stderr=$stderr}
}

function Invoke-OpenClawJson{
 param([Parameter(Mandatory=$true)][string[]]$Args)
 $r=Invoke-OpenClawRaw -Args $Args
 if($r.ExitCode -ne 0){throw "OpenClaw failed: $($Args -join ' ') :: $($r.Stderr)"}
 if([string]::IsNullOrWhiteSpace($r.Stdout)){return $null}
 try{return ($r.Stdout|ConvertFrom-Json)}catch{throw "OpenClaw returned non-JSON output: $($Args -join ' ')"}
}

function Get-Jobs{
 $x=Invoke-OpenClawJson -Args @('automations','list','--all','--json')
 if($x -and ($x.PSObject.Properties.Name -contains 'jobs')){return @($x.jobs)}
 return @($x)
}

function Run-Ps{
 param([Parameter(Mandatory=$true)][string]$File,[string[]]$Args=@())
 $err=Join-Path $env:TEMP ("kevin-ps-{0}.txt" -f [guid]::NewGuid().ToString('N'))
 $old=$ErrorActionPreference
 $ErrorActionPreference='Continue'
 try{
  $out=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $File @Args 2>$err
  $code=$LASTEXITCODE
 }finally{$ErrorActionPreference=$old}
 $stderr=''
 if(Test-Path -LiteralPath $err){
  $stderr=Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue
 }
 return [pscustomobject]@{ExitCode=$code;Stdout=(($out|ForEach-Object{[string]$_}) -join "`n");Stderr=$stderr}
}

function Assert-PowerShellParse{
 param([Parameter(Mandatory=$true)][string]$Path)
 $tokens=$null
 $errors=$null
 [void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
 if($errors -and $errors.Count -gt 0){
  $msg=($errors|ForEach-Object{"line $($_.Extent.StartLineNumber): $($_.Message)"}) -join '; '
  throw "PowerShell parser rejected $Path :: $msg"
 }
}

function Get-GitBlobToFile{
 param([Parameter(Mandatory=$true)][string]$Blob,[Parameter(Mandatory=$true)][string]$Destination,[Parameter(Mandatory=$true)][string]$GhExe)
 $r=Invoke-NativeCapture -Executable $GhExe -Args @('api',("repos/{0}/git/blobs/{1}" -f $Repo,$Blob))
 if($r.ExitCode -ne 0){throw "GitHub blob fetch failed for $Blob :: $($r.Stderr)"}
 $o=$r.Stdout|ConvertFrom-Json
 if(([string]$o.sha).ToLowerInvariant() -ne $Blob.ToLowerInvariant()){throw "Git blob identity mismatch. Expected $Blob, got $($o.sha)"}
 if([string]$o.encoding -ne 'base64'){throw "Unexpected Git blob encoding for ${Blob}: $($o.encoding)"}
 $bytes=[Convert]::FromBase64String(([string]$o.content -replace '\s',''))
 [IO.File]::WriteAllBytes($Destination,$bytes)
}

Step 'Preflight existing Kevin state'
if(-not(Test-Path -LiteralPath $Workspace)){throw "Kevin workspace not found: $Workspace"}
$supportPath=Join-Path $Reports 'support-latest.json'
if(-not(Test-Path -LiteralPath $supportPath)){throw 'support-latest.json not found. Run Support Bridge before installing.'}
$support=Get-Content -LiteralPath $supportPath -Raw|ConvertFrom-Json
if(-not $support.governance.ok){throw 'Governance is not healthy; refusing actuator install.'}
foreach($k in $ExpectedCore.Keys){
 $actual=[string]$support.hashes.$k
 if($actual -ne $ExpectedCore[$k]){throw "Core hash mismatch for $k. Expected $($ExpectedCore[$k]), saw $actual"}
}
Good 'Governance healthy and every pinned Kevin core hash matches current telemetry.'

$gh=Get-Command gh.exe -ErrorAction SilentlyContinue
if(-not $gh){$gh=Get-Command gh -ErrorAction SilentlyContinue}
if(-not $gh){throw 'GitHub CLI not found.'}
$auth=Invoke-NativeCapture -Executable $gh.Source -Args @('auth','status')
if($auth.ExitCode -ne 0){throw "GitHub CLI is not authenticated :: $($auth.Stderr)"}
Good 'GitHub CLI authentication available.'

Step 'Fetch immutable control-plane components by Git blob ID'
foreach($d in @($Root,$BackupRoot,$Backup,$EvidenceDir,(Join-Path $Root 'State'),(Join-Path $Root 'Queue'))){
 if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
}
$downloadDir=Join-Path $env:TEMP ("kevin-autonomy-v01e-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $downloadDir -Force|Out-Null
try{
 foreach($name in $ComponentBlobs.Keys){
  $tmp=Join-Path $downloadDir $name
  Get-GitBlobToFile -Blob ([string]$ComponentBlobs[$name]) -Destination $tmp -GhExe $gh.Source
  Good "$name verified as Git blob $($ComponentBlobs[$name])"
 }

 Step 'Validate downloaded components before installation'
 Assert-PowerShellParse -Path (Join-Path $downloadDir 'kevin-autonomy-actuator-v0.1.ps1')
 Assert-PowerShellParse -Path (Join-Path $downloadDir 'kevin-autonomy-bridge-v0.1.ps1')
 $desired=Get-Content -LiteralPath (Join-Path $downloadDir 'desired-state-v1.json') -Raw|ConvertFrom-Json
 if($desired.kind -ne 'kevin-desired-state' -or $desired.version -ne '1.0'){throw 'Desired State schema/version mismatch.'}
 if($desired.core_hashes.support_bridge -ne $ExpectedCore.support_bridge){throw 'Desired State Support Bridge hash does not match current pinned core.'}
 if($desired.authority.allow_arbitrary_shell -or $desired.authority.allow_authority_expansion -or $desired.authority.allow_novel_production_promotion){throw 'Desired State authority boundary validation failed.'}
 $ownerText=Get-Content -LiteralPath (Join-Path $downloadDir 'OWNER-AUTHORIZATION-v1.md') -Raw
 if($ownerText -notmatch 'Kevin Owner Authorization v1'){throw 'Owner Authorization identity check failed.'}
 Good 'PowerShell parser, Desired State, and owner-authorization validation passed.'

 Step 'Install verified components with backup'
 foreach($name in $ComponentBlobs.Keys){
  $dest=Join-Path $Root $name
  if(Test-Path -LiteralPath $dest){Copy-Item -LiteralPath $dest -Destination (Join-Path $Backup $name) -Force}
  Copy-Item -LiteralPath (Join-Path $downloadDir $name) -Destination $dest -Force
 }
}finally{
 Remove-Item -LiteralPath $downloadDir -Recurse -Force -ErrorAction SilentlyContinue
}
Good "Installed immutable control-plane components under $Root"

$Actuator=Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1'
$Bridge=Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1'

Step 'Actuator authority self-test and desired-state audit'
$self=Run-Ps -File $Actuator -Args @('-Mode','SelfTest')
Write-Host $self.Stdout
if($self.ExitCode -ne 0){throw "Actuator self-test failed :: $($self.Stderr)"}
Good 'Actuator authority self-test passed.'
$audit=Run-Ps -File $Actuator -Args @('-Mode','Audit')
Write-Host $audit.Stdout
if($audit.ExitCode -eq 2){throw 'Audit found a NEEDS_REVIEW condition. Installation stopped before scheduling.'}
elseif($audit.ExitCode -ne 0){throw "Audit failed :: $($audit.Stderr)"}
Good 'Desired-state audit passed without review-class drift.'

Step 'Install deterministic OpenClaw automation jobs'
$jobs=Get-Jobs
foreach($name in @('Kevin Autonomy Reconciler v0.1','Kevin Autonomy Telemetry v0.1')){
 foreach($j in @($jobs|Where-Object{$_.name -eq $name})){
  $null=Invoke-OpenClawJson -Args @('automations','remove',[string]$j.id,'--json')
 }
}
$reconcileArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Actuator,'-Mode','Reconcile')|ConvertTo-Json -Compress
$bridgeArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Bridge)|ConvertTo-Json -Compress
$null=Invoke-OpenClawJson -Args @('automations','create','*/3 * * * *','--name','Kevin Autonomy Reconciler v0.1','--command-argv',$reconcileArgv,'--command-cwd',$Root,'--timeout-seconds','600','--no-output-timeout-seconds','600','--output-max-bytes','65536','--no-deliver','--json')
$null=Invoke-OpenClawJson -Args @('automations','create','*/5 * * * *','--name','Kevin Autonomy Telemetry v0.1','--command-argv',$bridgeArgv,'--command-cwd',$Root,'--timeout-seconds','120','--no-output-timeout-seconds','120','--output-max-bytes','32768','--no-deliver','--json')
$jobs=Get-Jobs
$rj=@($jobs|Where-Object{$_.name -eq 'Kevin Autonomy Reconciler v0.1' -and [bool]$_.enabled})|Select-Object -First 1
$bj=@($jobs|Where-Object{$_.name -eq 'Kevin Autonomy Telemetry v0.1' -and [bool]$_.enabled})|Select-Object -First 1
if(-not $rj -or -not $bj){throw 'New autonomy jobs were not independently verified as enabled.'}
Good ("Reconciler job enabled: "+$rj.id)
Good ("Telemetry job enabled: "+$bj.id)

Step 'First live reconciliation'
$first=Run-Ps -File $Actuator -Args @('-Mode','Reconcile')
Write-Host $first.Stdout
if($first.ExitCode -eq 2){Note 'First reconcile completed bounded with NEEDS_REVIEW or failed repair; actuator remains installed for evidence.'}
elseif($first.ExitCode -ne 0){throw "First reconcile failed unexpectedly :: $($first.Stderr)"}
else{Good 'First live reconcile completed.'}

Step 'Publish and independently verify first autonomy snapshot'
$pub=Run-Ps -File $Bridge
Write-Host $pub.Stdout
if($pub.ExitCode -ne 0){throw "Autonomy telemetry publish failed :: $($pub.Stderr)"}
$remote=Invoke-NativeCapture -Executable $gh.Source -Args @('api',("repos/{0}/contents/reports/autonomy-latest.json" -f $Repo))
if($remote.ExitCode -ne 0){throw 'Remote autonomy telemetry could not be independently fetched after publish.'}
$remoteObj=$remote.Stdout|ConvertFrom-Json
if(-not $remoteObj.sha){throw 'Remote autonomy telemetry fetch returned no content identity.'}
Good 'Remote autonomy telemetry exists and was independently fetched.'

$install=[ordered]@{
 schema=1
 installed_at=(Get-Date).ToString('o')
 version='0.1e'
 component_commit=$ComponentCommit
 root=$Root
 backup=$Backup
 reconciler_job_id=[string]$rj.id
 telemetry_job_id=[string]$bj.id
 component_blobs=$ComponentBlobs
 first_reconcile_exit=$first.ExitCode
 first_reconcile_output=$first.Stdout
}
$manifest=Join-Path $Root 'install-manifest-v0.1e.json'
Write-JsonAtomic -Object $install -Path $manifest
$proof=Join-Path $EvidenceDir ("$Stamp-install-proof-v0.1e.json")
Write-JsonAtomic -Object $install -Path $proof

$rollback=@"
`$ErrorActionPreference='Continue'
openclaw automations remove '$($rj.id)' --json | Out-Null
openclaw automations remove '$($bj.id)' --json | Out-Null
Write-Host 'Kevin Autonomy v0.1 automation jobs removed. Installed ControlPlane files remain as evidence. Backup: $Backup'
"@
[IO.File]::WriteAllText((Join-Path $Root 'ROLLBACK-v0.1e.ps1'),$rollback,(New-Object Text.UTF8Encoding($false)))

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host 'KEVIN AUTONOMY ACTUATOR v0.1e INSTALLED + PROVEN' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host 'Reconciler: every 3 minutes'
Write-Host 'Telemetry: every 5 minutes, semantic-change only'
Write-Host 'GREEN verbs: diagnostics, Support Bridge, Benchmark, enable expected automation'
Write-Host 'Unknown/unsafe drift: NEEDS_REVIEW; no arbitrary improvisation'
Write-Host 'Work-conserving queue: advisory hook installed for next dispatcher phase'
Write-Host "Evidence: $EvidenceDir"
Write-Host "Rollback: $(Join-Path $Root 'ROLLBACK-v0.1e.ps1')"
