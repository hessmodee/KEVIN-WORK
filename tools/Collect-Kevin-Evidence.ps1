param([switch]$SelfTest)

# Read-only Kevin evidence collector. Never runs Kevin scripts or changes settings.
# Exact source files stay in the owner's ZIP; never automatically uploaded.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-Value($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -ne $p) { return $p.Value }
    return $null
}
function Get-Sha([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Write-Json([string]$Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding($false)))
}
function Read-Json([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return ([IO.File]::ReadAllText($Path) | ConvertFrom-Json)
}
function Get-ToolPolicy($Policy) {
    $o = [ordered]@{ present=($null -ne $Policy) }
    $profile = Get-Value $Policy 'profile'
    if ($profile -is [string] -and $profile -match '^[A-Za-z0-9_-]{1,80}$') { $o.profile=$profile }
    foreach ($key in @('allow','deny','alsoAllow')) {
        $value = Get-Value $Policy $key
        if ($null -ne $value) {
            $o[$key] = @($value | Where-Object { $_ -is [string] -and $_ -match '^[A-Za-z0-9_:.*-]{1,100}$' } | Select-Object -First 100)
        }
    }
    return $o
}
function Get-ConfigMetadata([string]$Workspace) {
    $path = Join-Path (Split-Path $Workspace -Parent) 'openclaw.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @{present=$false} }
    $before = Get-Sha $path
    $c = Read-Json $path
    if ((Get-Sha $path) -cne $before) { throw 'Configuration changed during metadata collection.' }
    $agents = Get-Value $c 'agents'
    $defaults = Get-Value $agents 'defaults'
    $entries = @(Get-Value $agents 'list' | Where-Object { (Get-Value $_ 'id') -eq 'main' })
    $main = if ($entries.Count -eq 1) { $entries[0] } else { $null }
    $o = [ordered]@{present=$true;sha256=$before;main_entries=$entries.Count;global_tools=(Get-ToolPolicy (Get-Value $c 'tools'));main_tools=(Get-ToolPolicy (Get-Value $main 'tools'));defaults_tools=(Get-ToolPolicy (Get-Value $defaults 'tools'));compaction=[ordered]@{}}
    $compaction = Get-Value $defaults 'compaction'
    foreach ($key in @('reserveTokensFloor','reserveTokens','keepRecentTokens')) {
        $v = Get-Value $compaction $key
        if ($v -is [int] -or $v -is [long]) { $o.compaction[$key]=$v }
    }
    $model = Get-Value $main 'model'
    if ($null -eq $model) { $model = Get-Value $defaults 'model' }
    $primary = if ($model -is [string]) { $model } else { Get-Value $model 'primary' }
    # Record the fixed repaired model's match, never arbitrary model/config text.
    $o.main_model_matches_repaired = ($primary -ceq 'ollama-chat-16k/qwen2.5:14b')
    $provider = Get-Value (Get-Value (Get-Value $c 'models') 'providers') 'ollama-chat-16k'
    $models = @(Get-Value $provider 'models' | Where-Object { (Get-Value $_ 'id') -eq 'qwen2.5:14b' })
    $o.repaired_model_entries = $models.Count
    $o.model_limits = [ordered]@{}
    if ($models.Count -eq 1) {
        foreach ($key in @('contextWindow','contextTokens','maxTokens')) {
            $v = Get-Value $models[0] $key
            if ($v -is [int] -or $v -is [long]) { $o.model_limits[$key]=$v }
        }
        $v = Get-Value (Get-Value $models[0] 'params') 'num_ctx'
        if ($v -is [int] -or $v -is [long]) { $o.model_limits.num_ctx=$v }
    }
    return $o
}
function Get-UiTaskMetadata {
    $name = 'Kevin UI Bridge v0.3'
    $o = [ordered]@{task_name=$name;status='UNAVAILABLE'}
    try {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction Stop
        $info = Get-ScheduledTaskInfo -TaskName $name -ErrorAction Stop
        $o.status='OBSERVED';$o.state=[string]$task.State
        $o.enabled=[bool]$task.Settings.Enabled
        $o.logon_type=[string]$task.Principal.LogonType
        $o.run_level=[string]$task.Principal.RunLevel
        $o.last_task_result=[long]$info.LastTaskResult
        $o.last_run_at=$info.LastRunTime.ToString('o')
        $o.next_run_at=$info.NextRunTime.ToString('o')
        $o.missed_runs=[long]$info.NumberOfMissedRuns
        $o.collector_session_id=[int](Get-Process -Id $PID).SessionId
        $o.explorer_session_ids=@(Get-Process -Name explorer -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SessionId -Unique)
        # Do not export task arguments, user identity, environment or raw logs.
    } catch { $o.error_type=$_.Exception.GetType().Name }
    return $o
}
function New-Evidence([string]$Workspace, [string]$Destination, [bool]$CollectTask) {
    New-Item -ItemType Directory -Path $Destination -ErrorAction Stop | Out-Null
    $sourceDir=Join-Path $Destination 'sources'
    New-Item -ItemType Directory -Path $sourceDir | Out-Null
    $report=[ordered]@{schema=1;kind='kevin-owner-evidence';generated_at=[DateTimeOffset]::Now.ToString('o');read_only=$true;sources=@();config=$null;baseline=$null;ui_task=$null;collection_errors=@()}
    foreach ($name in @('kevin-maintenance-runner.ps1','kevin-ui-bridge.ps1','kevin-benchmark-v1.ps1','kevin-engineering-relay.ps1')) {
        $p=Join-Path $Workspace $name
        $row=[ordered]@{name=$name;state='MISSING'}
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            if ((Get-Item -LiteralPath $p).Length -gt 2097152) { throw 'Source file exceeds 2 MiB cap.' }
            $before=Get-Sha $p;$dest=Join-Path $sourceDir $name
            Copy-Item -LiteralPath $p -Destination $dest
            if ((Get-Sha $p) -cne $before -or (Get-Sha $dest) -cne $before) { throw 'Source changed during collection; retry after the edit finishes.' }
            $row.state='COPIED_EXACT';$row.sha256=$before;$row.bytes=(Get-Item -LiteralPath $dest).Length
        }
        $report.sources+=,$row
    }
    try { $report.config=Get-ConfigMetadata $Workspace } catch { $report.collection_errors+=,'config_metadata_unavailable' }
    $baseline=Join-Path $Workspace 'reports\benchmark-v1\baseline.json'
    try {
        if (Test-Path -LiteralPath $baseline -PathType Leaf) {
            $before=Get-Sha $baseline;$b=Read-Json $baseline;$hashes=Get-Value $b 'hashes'
            if ((Get-Sha $baseline) -cne $before) { throw 'Baseline changed during metadata collection.' }
            $report.baseline=[ordered]@{sha256=$before;hashes=[ordered]@{}}
            foreach ($key in @('production_config','reader_config','benchmark','supervisor','forge')) {
                $v=Get-Value $hashes $key
                if ($v -is [string] -and $v -match '^[A-Fa-f0-9]{64}$') { $report.baseline.hashes[$key]=$v }
            }
        }
    } catch { $report.collection_errors+=,'baseline_metadata_unavailable' }
    if ($CollectTask) { $report.ui_task=Get-UiTaskMetadata }
    Write-Json (Join-Path $Destination 'evidence.json') $report
    [IO.File]::WriteAllText((Join-Path $Destination 'README.txt'), 'Owner-provided Kevin evidence. Script sources are included verbatim and must stay private until reviewed. No OpenClaw config body, credential files, chat transcripts, task arguments or user documents are collected. Nothing is installed, restarted or uploaded by this collector.')
    return $report
}
function Invoke-CollectorSelfTest {
    $root=Join-Path ([IO.Path]::GetTempPath()) ('kevin-evidence-test-'+[guid]::NewGuid().ToString('N'))
    try {
        $ws=Join-Path $root '.openclaw\workspace'
        New-Item -ItemType Directory -Path (Join-Path $ws 'reports\benchmark-v1') -Force | Out-Null
        $source=Join-Path $ws 'kevin-maintenance-runner.ps1'
        [IO.File]::WriteAllBytes($source,[byte[]](35,32,102,105,120,116,117,114,101,13,10))
        $config=@{secret='DO_NOT_EXPORT_SECRET';agents=@{list=@(@{id='main';model='ollama-chat-16k/qwen2.5:14b';tools=@{allow=@('kevin_system_status');deny=@('exec')}});defaults=@{compaction=@{reserveTokens=2048;reserveTokensFloor=2048;keepRecentTokens=4000}}};models=@{providers=@{'ollama-chat-16k'=@{apiKey='DO_NOT_EXPORT_SECRET';models=@(@{id='qwen2.5:14b';contextWindow=16384;params=@{num_ctx=16384}})}}}}
        Write-Json (Join-Path (Split-Path $ws -Parent) 'openclaw.json') $config
        Write-Json (Join-Path $ws 'reports\benchmark-v1\baseline.json') @{hashes=@{production_config=('A'*64);secret='DO_NOT_EXPORT_SECRET'};private='DO_NOT_EXPORT_SECRET'}
        $out=Join-Path $root 'output';$r=New-Evidence $ws $out $false
        if ($r.sources.Count -ne 4 -or @($r.sources | Where-Object {$_.state -eq 'COPIED_EXACT'}).Count -ne 1) { throw 'Source inventory failed' }
        if ((Get-Sha (Join-Path $out 'sources\kevin-maintenance-runner.ps1')) -cne (Get-Sha $source)) { throw 'Exact bytes not preserved' }
        if (-not $r.config.main_model_matches_repaired -or $r.config.model_limits.contextWindow -ne 16384 -or $r.config.model_limits.num_ctx -ne 16384) { throw 'Model metadata failed' }
        if ($r.config.compaction.reserveTokens -ne 2048 -or $r.config.main_tools.allow.Count -ne 1 -or $r.config.main_tools.deny[0] -ne 'exec') { throw 'Policy metadata failed' }
        if ($r.baseline.hashes.production_config -cne ('A'*64)) { throw 'Baseline hash failed' }
        $json=[IO.File]::ReadAllText((Join-Path $out 'evidence.json'))
        if ($json.Contains('DO_NOT_EXPORT_SECRET') -or (Test-Path (Join-Path $out 'openclaw.json'))) { throw 'Private config leaked' }
        if ((Get-ToolPolicy $null).present) { throw 'Missing policy mishandled' }
        $zip=Join-Path $root 'test.zip';Compress-Archive -Path (Join-Path $out '*') -DestinationPath $zip
        $expanded=Join-Path $root 'expanded';Expand-Archive -LiteralPath $zip -DestinationPath $expanded
        if ((Get-Sha (Join-Path $expanded 'sources\kevin-maintenance-runner.ps1')) -cne (Get-Sha $source)) { throw 'ZIP roundtrip failed' }
        Write-Host 'KEVIN EVIDENCE SELFTEST PASS: exact source bytes, fixed inventory, missing files, model/compaction/tool metadata, secret exclusion, ZIP roundtrip'
    } finally { if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force } }
}

if ($SelfTest) { Invoke-CollectorSelfTest; exit 0 }
if ($env:OS -ne 'Windows_NT') { throw 'Run this read-only collector on the Windows PC that hosts Kevin.' }
$desktop=[Environment]::GetFolderPath('Desktop')
if (-not $desktop -or -not (Test-Path -LiteralPath $desktop -PathType Container)) { throw 'Windows Desktop folder is unavailable.' }
$workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
if (-not (Test-Path -LiteralPath $workspace -PathType Container)) { throw 'Kevin workspace was not found for this Windows user.' }
$name='Kevin-Evidence-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6)
$stage=Join-Path ([IO.Path]::GetTempPath()) $name
$archive=Join-Path $desktop ($name+'.zip')
try {
    $null=New-Evidence $workspace $stage $true
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive
    Write-Host ('Created: '+$archive)
    Write-Host 'Upload this ZIP to the Kevin Build chat. No settings were changed and nothing was uploaded automatically.'
} finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force } }
