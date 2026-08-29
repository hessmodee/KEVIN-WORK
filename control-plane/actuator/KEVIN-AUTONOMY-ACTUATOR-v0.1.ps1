Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

$Repo='hessmodee/KEVIN-WORK'
$Branch='kevin-autonomy-actuator-v0.1'
$RawBase="https://raw.githubusercontent.com/$Repo/$Branch/control-plane"
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Reports=Join-Path $Workspace 'reports'
if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$Root=Join-Path $Workspace 'ControlPlane'
$BackupRoot=Join-Path $Root 'Backups'
$Stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
$Backup=Join-Path $BackupRoot $Stamp
$EvidenceDir=Join-Path $Root 'Evidence'

$Pins=[ordered]@{
 'desired-state-v1.json'='852F681A784376BEC87825D5C00AD789EBD21101B17DA06CECBABB1F78F1330E'
 'OWNER-AUTHORIZATION-v1.md'='B7384FE15D811826B0764DD8E4C081C639B44A31568AFE4CD5201A09270C87DC'
 'kevin-autonomy-actuator-v0.1.ps1'='1DE36FC0D47B64D4FAF2A99E2492F7D901713262DC13BE0E9B66E346CA9EFB3B'
 'kevin-autonomy-bridge-v0.1.ps1'='2373A68E5B6F7EC522FF38FC6F44F96D4DAC084CFFCEFE658A238D4B445FE4C0'
}
$Sources=[ordered]@{
 'desired-state-v1.json'="$RawBase/desired-state-v1.json"
 'OWNER-AUTHORIZATION-v1.md'="$RawBase/OWNER-AUTHORIZATION-v1.md"
 'kevin-autonomy-actuator-v0.1.ps1'="$RawBase/actuator/kevin-autonomy-actuator-v0.1.ps1"
 'kevin-autonomy-bridge-v0.1.ps1'="$RawBase/actuator/kevin-autonomy-bridge-v0.1.ps1"
}

function Step([string]$s){Write-Host ("`n==> "+$s) -ForegroundColor Cyan}
function Good([string]$s){Write-Host ("PASS  "+$s) -ForegroundColor Green}
function Note([string]$s){Write-Host ("INFO  "+$s) -ForegroundColor DarkGray}

function Write-JsonAtomic{param($Object,[string]$Path)$tmp="$Path.tmp-$PID";[IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),(New-Object Text.UTF8Encoding($false)));Move-Item -LiteralPath $tmp -Destination $Path -Force}

function Get-OpenClawLauncher{
 $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue}
 $shim=Get-Command openclaw.cmd -ErrorAction SilentlyContinue;if(-not $shim){$shim=Get-Command openclaw -ErrorAction SilentlyContinue}
 if(-not $shim){throw 'OpenClaw CLI not found in PATH.'}
 if($node){
  $shimDir=Split-Path -Parent $shim.Source;$pkgDir=Join-Path $shimDir 'node_modules\openclaw';$pkgJson=Join-Path $pkgDir 'package.json'
  if(Test-Path -LiteralPath $pkgJson){
   try{$pkg=Get-Content -LiteralPath $pkgJson -Raw|ConvertFrom-Json;$binRel=$null;if($pkg.bin -is [string]){$binRel=[string]$pkg.bin}elseif($pkg.bin -and $pkg.bin.openclaw){$binRel=[string]$pkg.bin.openclaw};if($binRel){$cli=Join-Path $pkgDir $binRel;if(Test-Path -LiteralPath $cli){return [pscustomobject]@{Kind='node';Executable=$node.Source;Cli=$cli}}}}catch{}
  }
 }
 return [pscustomobject]@{Kind='shim';Executable=$shim.Source;Cli=$null}
}
$script:Ocl=$null
function Invoke-OpenClawRaw{param([string[]]$Args)
 if(-not $script:Ocl){$script:Ocl=Get-OpenClawLauncher}
 $err=Join-Path $env:TEMP ("kevin-ocl-{0}.txt" -f [guid]::NewGuid().ToString('N'));$old=$ErrorActionPreference;$ErrorActionPreference='Continue'
 try{if($script:Ocl.Kind -eq 'node'){$out=& $script:Ocl.Executable $script:Ocl.Cli @Args 2>$err}else{$out=& $script:Ocl.Executable @Args 2>$err};$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
 $stderr='';if(Test-Path $err){$stderr=Get-Content $err -Raw -ErrorAction SilentlyContinue;Remove-Item $err -Force -ErrorAction SilentlyContinue};return [pscustomobject]@{ExitCode=$code;Stdout=(($out|ForEach-Object{[string]$_}) -join "`n");Stderr=$stderr}
}
function Invoke-OpenClawJson{param([string[]]$Args)$r=Invoke-OpenClawRaw $Args;if($r.ExitCode -ne 0){throw "OpenClaw failed: $($Args -join ' ') :: $($r.Stderr)"};if([string]::IsNullOrWhiteSpace($r.Stdout)){return $null};return ($r.Stdout|ConvertFrom-Json)}
function Get-Jobs{$x=Invoke-OpenClawJson @('automations','list','--all','--json');if($x -and ($x.PSObject.Properties.Name -contains 'jobs')){return @($x.jobs)};return @($x)}
function Run-Ps{param([string]$File,[string[]]$Args=@())$err=Join-Path $env:TEMP ("kevin-ps-{0}.txt" -f [guid]::NewGuid().ToString('N'));$old=$ErrorActionPreference;$ErrorActionPreference='Continue';try{$out=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $File @Args 2>$err;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old};$stderr='';if(Test-Path $err){$stderr=Get-Content $err -Raw -ErrorAction SilentlyContinue;Remove-Item $err -Force -ErrorAction SilentlyContinue};return [pscustomobject]@{ExitCode=$code;Stdout=(($out|ForEach-Object{[string]$_}) -join "`n");Stderr=$stderr}}

Step 'Preflight existing Kevin state'
if(-not(Test-Path -LiteralPath $Workspace)){throw "Kevin workspace not found: $Workspace"}
$supportPath=Join-Path $Reports 'support-latest.json';if(-not(Test-Path $supportPath)){throw 'support-latest.json not found. Run Support Bridge before installing.'}
$support=Get-Content $supportPath -Raw|ConvertFrom-Json
$expectedCore=[ordered]@{
 supervisor='EA28600FDE1E7572F431710416238DA8A4AD6B80321C9A8F0687C1C8A92421F7';benchmark='02447EE8F3302E3EA1EF00290DBA6804F30FAC9F46CAE8714F402EA2D013CC38';forge='0ED50A9714B4B5E778844006CD24E57D25FFA0873261E5BF63F990FBB4D5643E';goal_os='B20C7AC8EDC35C656ED544C4D13D3EB4FF4A79453AF0F49BD60B7DF31092AEF0';support_bridge='E72A2A635326CF1AB036404E64E274D2F56E79CA5CEB268DBF9B2EA4B67BEA5';maintenance_runner='B47714C91EFDCCD1FAE6C2CB0B97D72F799125A63C084956916A8BD5A07678C1'
}
if(-not $support.governance.ok){throw 'Governance is not healthy; refusing actuator install.'}
foreach($k in $expectedCore.Keys){$actual=[string]$support.hashes.$k;if($actual -ne $expectedCore[$k]){throw "Core hash mismatch for $k. Expected $($expectedCore[$k]), saw $actual"}}
Good 'Governance healthy and all pinned core hashes match.'

$gh=Get-Command gh.exe -ErrorAction SilentlyContinue;if(-not $gh){$gh=Get-Command gh -ErrorAction SilentlyContinue};if(-not $gh){throw 'GitHub CLI not found; autonomy telemetry bridge requires existing authenticated gh.'}
$old=$ErrorActionPreference;$ErrorActionPreference='Continue';try{$null=& $gh.Source auth status 2>$null;$ghCode=$LASTEXITCODE}finally{$ErrorActionPreference=$old};if($ghCode -ne 0){throw 'GitHub CLI is not authenticated.'};Good 'GitHub CLI authentication available.'

Step 'Download hash-pinned actuator components'
foreach($d in @($Root,$BackupRoot,$Backup,$EvidenceDir,(Join-Path $Root 'State'),(Join-Path $Root 'Queue'))){if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}}
$downloadDir=Join-Path $env:TEMP ("kevin-autonomy-{0}" -f [guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $downloadDir -Force|Out-Null
try{
 foreach($name in $Sources.Keys){
  $tmp=Join-Path $downloadDir $name;Invoke-WebRequest -UseBasicParsing -Uri $Sources[$name] -OutFile $tmp
  $hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $tmp).Hash.ToUpperInvariant();if($hash -ne $Pins[$name]){throw "HASH MISMATCH for $name. Expected $($Pins[$name]), got $hash"};Good "$name SHA-256 $hash"
 }
 foreach($name in $Sources.Keys){$dest=Join-Path $Root $name;if(Test-Path $dest){Copy-Item $dest (Join-Path $Backup $name) -Force};Copy-Item (Join-Path $downloadDir $name) $dest -Force}
}finally{Remove-Item $downloadDir -Recurse -Force -ErrorAction SilentlyContinue}
Good "Installed pinned files under $Root"

$Actuator=Join-Path $Root 'kevin-autonomy-actuator-v0.1.ps1';$Bridge=Join-Path $Root 'kevin-autonomy-bridge-v0.1.ps1'
Step 'Static/authority self-test'
$self=Run-Ps $Actuator @('-Mode','SelfTest');Write-Host $self.Stdout;if($self.ExitCode -ne 0){throw "Actuator self-test failed: $($self.Stderr)"};Good 'Actuator authority self-test passed.'
$audit=Run-Ps $Actuator @('-Mode','Audit');Write-Host $audit.Stdout;if($audit.ExitCode -eq 2){throw 'Audit found a NEEDS_REVIEW condition. Installation stopped before scheduling.'}elseif($audit.ExitCode -ne 0){throw "Audit failed: $($audit.Stderr)"};Good 'Desired-state audit passed without review-class drift.'

Step 'Install deterministic OpenClaw automation jobs'
$jobs=Get-Jobs
foreach($name in @('Kevin Autonomy Reconciler v0.1','Kevin Autonomy Telemetry v0.1')){foreach($j in @($jobs|Where-Object{$_.name -eq $name})){$null=Invoke-OpenClawJson @('automations','remove',[string]$j.id,'--json')}}
$reconcileArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Actuator,'-Mode','Reconcile')|ConvertTo-Json -Compress
$bridgeArgv=@('powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Bridge)|ConvertTo-Json -Compress
$reconcileJob=Invoke-OpenClawJson @('automations','create','*/3 * * * *','--name','Kevin Autonomy Reconciler v0.1','--command-argv',$reconcileArgv,'--command-cwd',$Root,'--timeout-seconds','600','--no-output-timeout-seconds','600','--output-max-bytes','65536','--no-deliver','--json')
$bridgeJob=Invoke-OpenClawJson @('automations','create','*/5 * * * *','--name','Kevin Autonomy Telemetry v0.1','--command-argv',$bridgeArgv,'--command-cwd',$Root,'--timeout-seconds','120','--no-output-timeout-seconds','120','--output-max-bytes','32768','--no-deliver','--json')
$jobs=Get-Jobs
$rj=@($jobs|Where-Object{$_.name -eq 'Kevin Autonomy Reconciler v0.1' -and [bool]$_.enabled})|Select-Object -First 1
$bj=@($jobs|Where-Object{$_.name -eq 'Kevin Autonomy Telemetry v0.1' -and [bool]$_.enabled})|Select-Object -First 1
if(-not $rj -or -not $bj){throw 'New autonomy automation jobs were not independently verified as enabled.'}
Good ("Reconciler job enabled: "+$rj.id);Good ("Telemetry job enabled: "+$bj.id)

Step 'First live reconciliation'
$first=Run-Ps $Actuator @('-Mode','Reconcile');Write-Host $first.Stdout
if($first.ExitCode -eq 2){Note 'First reconcile completed with NEEDS_REVIEW or failed repair. Actuator remains installed and bounded; inspect autonomy-latest.json.'}elseif($first.ExitCode -ne 0){throw "First reconcile failed unexpectedly: $($first.Stderr)"}else{Good 'First live reconcile completed.'}

Step 'Publish first sanitized autonomy snapshot'
$pub=Run-Ps $Bridge @();Write-Host $pub.Stdout;if($pub.ExitCode -ne 0){throw "Autonomy telemetry publish failed: $($pub.Stderr)"}
$old=$ErrorActionPreference;$ErrorActionPreference='Continue';try{$remote=& $gh.Source api "repos/$Repo/contents/reports/autonomy-latest.json" 2>$null;$remoteCode=$LASTEXITCODE}finally{$ErrorActionPreference=$old};if($remoteCode -ne 0){throw 'Remote autonomy telemetry could not be independently fetched after publish.'};Good 'Remote autonomy telemetry exists.'

$install=[ordered]@{schema=1;installed_at=(Get-Date).ToString('o');version='0.1';root=$Root;backup=$Backup;reconciler_job_id=[string]$rj.id;telemetry_job_id=[string]$bj.id;pins=$Pins;first_reconcile_exit=$first.ExitCode;first_reconcile_output=$first.Stdout}
$manifest=Join-Path $Root 'install-manifest-v0.1.json';Write-JsonAtomic $install $manifest
$proof=Join-Path $EvidenceDir ("$Stamp-install-proof.json");Write-JsonAtomic $install $proof

$rollback=@"
`$ErrorActionPreference='Continue'
openclaw automations remove '$($rj.id)' --json | Out-Null
openclaw automations remove '$($bj.id)' --json | Out-Null
Write-Host 'Kevin Autonomy v0.1 automation jobs removed. Installed ControlPlane files were left in place as evidence; restore from: $Backup'
"@
[IO.File]::WriteAllText((Join-Path $Root 'ROLLBACK-v0.1.ps1'),$rollback,(New-Object Text.UTF8Encoding($false)))

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host 'KEVIN AUTONOMY ACTUATOR v0.1 INSTALLED + PROVEN' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Reconciler: every 3 minutes"
Write-Host "Telemetry:  every 5 minutes, semantic-change only"
Write-Host "GREEN verbs: collect diagnostics, run Support Bridge, run Benchmark, enable expected automation"
Write-Host "Unknown/unsafe drift: NEEDS_REVIEW (no improvisation)"
Write-Host "Work-conserving mission queue: installed as advisory hook for next Supervisor integration"
Write-Host "Evidence: $EvidenceDir"
Write-Host "Rollback: $(Join-Path $Root 'ROLLBACK-v0.1.ps1')"
