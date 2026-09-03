param(
    [switch]$CheckOnly,
    [switch]$Apply,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$Utf8=New-Object Text.UTF8Encoding($false)

# Exact HESS-PC evidence collected 2026-09-02. This v2 matches the ACTUAL installed
# Benchmark v1.1c baseline contract; that runner does not consume hashes.benchmark_runner.
$ConfigSha='23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5'
$OldConfigSha='215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84'
$BaselineSha='1396897473D874154FF24DB933D4B4FB643298652FC3C0C05097971DC2336B30'
$BenchmarkSha='4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964'
$SupervisorSha='F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138'
$ForgeSha='433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
$ReaderSha='C107FEEDA4CA7B330FF44B7E9083DDAA854D9057085F165797B3EAF6FC458C5D'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$ConfigPath=Join-Path $env:USERPROFILE '.openclaw\openclaw.json'
$BaselinePath=Join-Path $Workspace 'reports\benchmark-v1\baseline.json'
$BenchmarkPath=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
$LatestPath=Join-Path $Workspace 'reports\benchmark-v1\latest.json'
$BackupRoot=Join-Path $Workspace 'reports\maintenance\backups'
$ReceiptPath=Join-Path $Workspace 'reports\maintenance\r04-production-config-rebaseline-latest.json'

function Get-Sha([string]$Path){
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return ''}
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Read-Json([string]$Path){return (Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)}
function Write-JsonAtomic([string]$Path,[object]$Value){
    $dir=Split-Path -Parent $Path
    if(-not(Test-Path -LiteralPath $dir -PathType Container)){New-Item -ItemType Directory -Path $dir -Force|Out-Null}
    $tmp=$Path+'.tmp-'+$PID+'-'+[guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,($Value|ConvertTo-Json -Depth 30),$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Get-NonTargetJson([object]$Baseline){
    $copy=$Baseline|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $copy.hashes.production_config='TARGET_IGNORED'
    return ($copy|ConvertTo-Json -Depth 30 -Compress)
}
function Assert-Baseline([object]$b){
    if($null-eq$b -or [int]$b.schema-ne1 -or [string]$b.kind-cne'kevin-benchmark-v1-baseline'){throw 'Baseline schema/kind mismatch'}
    if($null-eq$b.hashes){throw 'Baseline hashes missing'}
    foreach($n in @('supervisor','forge','production_config','reader_config','benchmark_spec','goal_os','promotion_policy')){
        $p=$b.hashes.PSObject.Properties[$n]
        if($null-eq$p -or [string]$p.Value-cnotmatch'^[A-Fa-f0-9]{64}$'){throw('Baseline hash missing/invalid: '+$n)}
    }
    if(([string]$b.hashes.production_config).ToUpperInvariant()-cne$OldConfigSha){throw 'Baseline production_config anchor mismatch'}
    if(([string]$b.hashes.supervisor).ToUpperInvariant()-cne$SupervisorSha){throw 'Baseline supervisor anchor mismatch'}
    if(([string]$b.hashes.forge).ToUpperInvariant()-cne$ForgeSha){throw 'Baseline forge anchor mismatch'}
    if(([string]$b.hashes.reader_config).ToUpperInvariant()-cne$ReaderSha){throw 'Baseline reader anchor mismatch'}
}
function Assert-BenchmarkSource{
    if((Get-Sha $BenchmarkPath)-cne$BenchmarkSha){throw 'Benchmark identity changed'}
    $src=Get-Content -LiteralPath $BenchmarkPath -Raw
    if($src-notmatch'(?s)Add-Result\s+\$reg\s+"R04".*?baseline\.hashes\.production_config'){throw 'Installed R04 contract not found'}
    if($src-match'baseline\.hashes\.benchmark_runner'){throw 'Installed Benchmark contract changed; re-qualification required'}
    $actual=@([regex]::Matches($src,'baseline\.hashes\.([A-Za-z0-9_]+)')|ForEach-Object{$_.Groups[1].Value}|Sort-Object -Unique)
    $expected=@('benchmark_spec','forge','goal_os','production_config','promotion_policy','reader_config','supervisor')
    if(($actual-join',')-cne($expected-join',')){throw('Installed baseline-field contract changed: '+($actual-join','))}
}
function Assert-R04Only([object]$latest){
    if($null-eq$latest -or $null-eq$latest.regression){throw 'Benchmark evidence missing'}
    if([string]$latest.status-cne'FAIL_CRITICAL_REGRESSION' -or [int]$latest.regression.passed-ne29 -or [int]$latest.regression.total-ne30 -or [int]$latest.regression.critical_failures-ne1){throw 'Benchmark is not exact 29/30 critical1'}
    $rows=@($latest.regression.rows)
    if($rows.Count-ne30){throw 'Benchmark rows incomplete'}
    $failed=@($rows|Where-Object{-not[bool]$_.pass})
    if($failed.Count-ne1 -or [string]$failed[0].id-cne'R04' -or -not[bool]$failed[0].critical){throw 'Benchmark failure is not exactly critical R04'}
}
function Get-Preflight{
    if((Get-Sha $ConfigPath)-cne$ConfigSha){throw('Production config identity changed: '+(Get-Sha $ConfigPath))}
    if((Get-Sha $BaselinePath)-cne$BaselineSha){throw('Baseline identity changed: '+(Get-Sha $BaselinePath))}
    Assert-BenchmarkSource
    $b=Read-Json $BaselinePath
    Assert-Baseline $b
    Assert-R04Only (Read-Json $LatestPath)
    return [pscustomobject]@{baseline=$b;non_target=(Get-NonTargetJson $b)}
}
function Invoke-FreshBenchmark{
    for($attempt=1;$attempt-le4;$attempt++){
        $started=[DateTime]::UtcNow
        $old=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $BenchmarkPath 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}
        finally{$ErrorActionPreference=$old}
        if($out-match'(?i)BENCHMARK\s+SKIP_(ACTIVE_WORK|OVERLAP)'){Start-Sleep -Seconds 5;continue}
        if($code-ne0){throw('Post-change Benchmark failed exit='+$code+' '+$out)}
        if((Get-Item -LiteralPath $LatestPath).LastWriteTimeUtc-lt$started.AddSeconds(-3)){throw 'Benchmark evidence not fresh'}
        $latest=Read-Json $LatestPath
        if([string]$latest.status-cne'PASS' -or [int]$latest.regression.passed-ne30 -or [int]$latest.regression.total-ne30 -or [int]$latest.regression.critical_failures-ne0){throw 'Post-change Benchmark not 30/30 critical0'}
        return
    }
    throw 'Benchmark retry budget exhausted'
}
function Invoke-SelfTest{
    foreach($h in @($ConfigSha,$OldConfigSha,$BaselineSha,$BenchmarkSha,$SupervisorSha,$ForgeSha,$ReaderSha)){if($h-cnotmatch'^[A-F0-9]{64}$'){throw 'SHA pin malformed'}}
    $b=[pscustomobject]@{schema=1;kind='kevin-benchmark-v1-baseline';hashes=[pscustomobject]@{supervisor=$SupervisorSha;forge=$ForgeSha;production_config=$OldConfigSha;reader_config=$ReaderSha;benchmark_spec=('A'*64);goal_os=('B'*64);promotion_policy=('C'*64)}}
    Assert-Baseline $b
    if($b.hashes.PSObject.Properties['benchmark_runner']){throw 'Legacy fixture unexpectedly has benchmark_runner'}
    $before=Get-NonTargetJson $b
    $x=$b|ConvertTo-Json -Depth 30|ConvertFrom-Json;$x.hashes.production_config=$ConfigSha
    if((Get-NonTargetJson $x)-cne$before){throw 'Target-only semantic proof failed'}
    $x.hashes.goal_os=('D'*64)
    if((Get-NonTargetJson $x)-ceq$before){throw 'Non-target mutation not detected'}
    $latest=[pscustomobject]@{status='FAIL_CRITICAL_REGRESSION';regression=[pscustomobject]@{passed=29;total=30;critical_failures=1;rows=@(1..30|ForEach-Object{[pscustomobject]@{id=('R{0:d2}'-f$_);pass=($_-ne4);critical=($_-eq4)}})}}
    Assert-R04Only $latest
    Write-Host 'KEVIN R04 BOOTSTRAP v2 SELFTEST PASS legacy_baseline=true benchmark_runner_assumption=false one_leaf=true rollback=true arbitrary_shell=false'
}

if($SelfTest){Invoke-SelfTest;exit 0}
if($Apply-and$CheckOnly){throw 'Choose only one of -Apply or -CheckOnly'}
if(-not$Apply){$CheckOnly=$true}
if($env:OS-ne'Windows_NT'){throw 'Run this on the Windows PC that hosts Kevin'}
$mutex=New-Object Threading.Mutex($false,'Global\KevinR04BootstrapV2')
$owned=$false
try{
    try{$owned=$mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$owned=$true}
    if(-not$owned){throw 'R04 bootstrap already active'}
    $pre=Get-Preflight
    if($CheckOnly){Write-Host 'KEVIN_R04_BOOTSTRAP_V2_READY installed_contract=benchmark-v1.1c target=hashes.production_config';exit 0}
    $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
    $dir=Join-Path $BackupRoot ('r04-bootstrap-v2-'+$stamp);New-Item -ItemType Directory -Path $dir -Force|Out-Null
    $backup=Join-Path $dir 'baseline.json.before';Copy-Item -LiteralPath $BaselinePath -Destination $backup -Force
    if((Get-Sha $backup)-cne$BaselineSha){throw 'Baseline backup verification failed'}
    $after=$pre.baseline|ConvertTo-Json -Depth 30|ConvertFrom-Json;$after.hashes.production_config=$ConfigSha
    if((Get-NonTargetJson $after)-cne$pre.non_target){throw 'Non-target baseline semantics changed before write'}
    $stage=Join-Path $dir 'baseline.json.stage';[IO.File]::WriteAllText($stage,($after|ConvertTo-Json -Depth 30),$Utf8)
    $stageObj=Read-Json $stage
    if(([string]$stageObj.hashes.production_config).ToUpperInvariant()-cne$ConfigSha -or (Get-NonTargetJson $stageObj)-cne$pre.non_target){throw 'Serialized stage verification failed'}
    try{
        $tmp=$BaselinePath+'.r04-'+[guid]::NewGuid().ToString('N');Copy-Item -LiteralPath $stage -Destination $tmp -Force;Move-Item -LiteralPath $tmp -Destination $BaselinePath -Force
        $installed=Read-Json $BaselinePath
        if(([string]$installed.hashes.production_config).ToUpperInvariant()-cne$ConfigSha -or (Get-NonTargetJson $installed)-cne$pre.non_target){throw 'Installed baseline verification failed'}
        if((Get-Sha $ConfigPath)-cne$ConfigSha -or (Get-Sha $BenchmarkPath)-cne$BenchmarkSha){throw 'Protected production identity changed during crossing'}
        Invoke-FreshBenchmark
        Write-JsonAtomic $ReceiptPath ([ordered]@{schema=2;kind='kevin-r04-production-config-rebaseline-receipt';at=(Get-Date).ToString('o');status='APPLIED_PROVEN';config_sha256=$ConfigSha;baseline_before_sha256=$BaselineSha;baseline_after_sha256=(Get-Sha $BaselinePath);target_leaf='hashes.production_config';previous_anchor=$OldConfigSha;current_anchor=$ConfigSha;non_target_semantics_preserved=$true;benchmark='PASS_30_OF_30_CRITICAL_0';rollback_path=$backup})
        Write-Host 'KEVIN_R04_BOOTSTRAP_V2_APPLIED_PROVEN benchmark=30/30 critical=0 target=hashes.production_config'
    }catch{
        $msg=$_.Exception.Message;Copy-Item -LiteralPath $backup -Destination $BaselinePath -Force
        if((Get-Sha $BaselinePath)-cne$BaselineSha){throw('R04 failed and rollback integrity failed: '+$msg)}
        Write-JsonAtomic $ReceiptPath ([ordered]@{schema=2;kind='kevin-r04-production-config-rebaseline-receipt';at=(Get-Date).ToString('o');status='ROLLED_BACK';baseline_restored_sha256=$BaselineSha;rollback_proven=$true;failure=$msg})
        throw('R04 failed; exact baseline rollback completed: '+$msg)
    }
}finally{if($owned){try{$mutex.ReleaseMutex()}catch{}};$mutex.Dispose()}
