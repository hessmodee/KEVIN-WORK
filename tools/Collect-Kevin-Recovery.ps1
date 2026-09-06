param([switch]$SelfTest)

# Kevin recovery evidence collector plus fixed local Ollama inference diagnostic.
# No configuration changes, model tool execution, installs, restarts or uploads.
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
    # Fixed local model diagnostic; never executes model-proposed tool calls.
    $isolateStart=[DateTimeOffset]::Now
    $diagnostic=Join-Path $stage 'ollama-tool-isolate.mjs'
    [IO.File]::WriteAllBytes($diagnostic,[Convert]::FromBase64String('aW1wb3J0IHsgY3JlYXRlSGFzaCwgcmFuZG9tVVVJRCB9IGZyb20gJ25vZGU6Y3J5cHRvJzsKaW1wb3J0IHsgbWtkaXIsIHJlYWRGaWxlLCByZW5hbWUsIHdyaXRlRmlsZSB9IGZyb20gJ25vZGU6ZnMvcHJvbWlzZXMnOwppbXBvcnQgeyBob21lZGlyIH0gZnJvbSAnbm9kZTpvcyc7CmltcG9ydCB7IGpvaW4sIHJlc29sdmUgfSBmcm9tICdub2RlOnBhdGgnOwppbXBvcnQgeyBmaWxlVVJMVG9QYXRoIH0gZnJvbSAnbm9kZTp1cmwnOwoKLy8gRml4ZWQgbG9jYWwgZW5kcG9pbnQgYW5kIHN5bnRoZXRpYyBwcm9tcHQuIE5vIHRvb2wgZXhlY3V0aW9uLCBkb3dubG9hZHMsCi8vIGNvbmZpZ3VyYXRpb24gY2hhbmdlcywgY3JlZGVudGlhbHMgb3IgYXV0b21hdGljIHB1YmxpY2F0aW9uLgpleHBvcnQgY29uc3QgTU9ERUxTID0gT2JqZWN0LmZyZWV6ZShbJ2xsYW1hMy4xOjhiJywgJ3F3ZW4yLjU6MTRiJ10pOwpjb25zdCBzaGEgPSB2YWx1ZSA9PiBjcmVhdGVIYXNoKCdzaGEyNTYnKS51cGRhdGUodmFsdWUpLmRpZ2VzdCgnaGV4JykudG9VcHBlckNhc2UoKTsKY29uc3Qgb2JqZWN0ID0geCA9PiB4ICE9PSBudWxsICYmIHR5cGVvZiB4ID09PSAnb2JqZWN0JyAmJiAhQXJyYXkuaXNBcnJheSh4KTsKZXhwb3J0IGZ1bmN0aW9uIGNsYXNzaWZ5KHJlc3BvbnNlKSB7CiAgY29uc3QgY2FsbHMgPSByZXNwb25zZT8ubWVzc2FnZT8udG9vbF9jYWxsczsKICBpZiAocmVzcG9uc2U/LmRvbmUgIT09IHRydWUpIHJldHVybiAnSU5DT01QTEVURV9SRVNQT05TRSc7CiAgaWYgKCFBcnJheS5pc0FycmF5KGNhbGxzKSB8fCBjYWxscy5sZW5ndGggPT09IDApIHJldHVybiAnTk9fU1RSVUNUVVJFRF9UT09MX0NBTEwnOwogIGlmIChjYWxscy5sZW5ndGggIT09IDEpIHJldHVybiAnVU5FWFBFQ1RFRF9DQUxMX0NPVU5UJzsKICBjb25zdCBmbiA9IGNhbGxzWzBdPy5mdW5jdGlvbjsKICBpZiAoZm4/Lm5hbWUgIT09ICdnZXRfd2VhdGhlcicpIHJldHVybiAnV1JPTkdfVE9PTCc7CiAgaWYgKCFvYmplY3QoZm4uYXJndW1lbnRzKSB8fCBPYmplY3Qua2V5cyhmbi5hcmd1bWVudHMpLmxlbmd0aCAhPT0gMSB8fAogICAgICBmbi5hcmd1bWVudHMuY2l0eSAhPT0gJ1ByZXN0b24gSWRhaG8nKSByZXR1cm4gJ0lOVkFMSURfQVJHVU1FTlRTJzsKICByZXR1cm4gJ1BBU1MnOwp9CmFzeW5jIGZ1bmN0aW9uIHJlcXVlc3QocGF0aCwgYm9keSkgewogIGNvbnN0IHJlc3BvbnNlID0gYXdhaXQgZmV0Y2goJ2h0dHA6Ly8xMjcuMC4wLjE6MTE0MzQnICsgcGF0aCwgewogICAgbWV0aG9kOiBib2R5ID8gJ1BPU1QnIDogJ0dFVCcsIHJlZGlyZWN0OiAnZXJyb3InLAogICAgaGVhZGVyczogeyAnQ29udGVudC1UeXBlJzogJ2FwcGxpY2F0aW9uL2pzb24nIH0sCiAgICAuLi4oYm9keSA/IHsgYm9keTogSlNPTi5zdHJpbmdpZnkoYm9keSkgfSA6IHt9KSwKICAgIHNpZ25hbDogQWJvcnRTaWduYWwudGltZW91dChib2R5ID8gMTIwMDAwIDogMTAwMDApLAogIH0pOwogIGlmICghcmVzcG9uc2Uub2spIHRocm93IG5ldyBFcnJvcignSFRUUF8nICsgcmVzcG9uc2Uuc3RhdHVzKTsKICByZXR1cm4gcmVzcG9uc2UuanNvbigpOwp9CmV4cG9ydCBhc3luYyBmdW5jdGlvbiBwcm9iZShzZW5kID0gcmVxdWVzdCkgewogIGNvbnN0IHJlc3VsdCA9IHsKICAgIHNjaGVtYTogMSwga2luZDogJ2tldmluLW9sbGFtYS1pc29sYXRpb24tcmVjZWlwdCcsCiAgICBpZDogcmFuZG9tVVVJRCgpLCBnZW5lcmF0ZWRfYXQ6IG5ldyBEYXRlKCkudG9JU09TdHJpbmcoKSwKICAgIHNhZmVfZm9yX3B1YmxpY19yZXBvOiB0cnVlLCBzdGF0dXM6ICdGQUlMJywgYXBpOiAnbmF0aXZlLS9hcGkvY2hhdCcsCiAgICBtb2RlbHM6IFtdLCB0b29sX2V4ZWN1dGlvbl9hdHRlbXB0ZWQ6IGZhbHNlLAogICAgdHJ1dGhfYm91bmRhcnk6ICdTdHJ1Y3R1cmVkIG1vZGVsIHRvb2wtY2FsbCBnZW5lcmF0aW9uIG9ubHkuIERvZXMgbm90IHByb3ZlIE9wZW5DbGF3IGRpc3BhdGNoLCBmaWxlc3lzdGVtIHdyaXRlcywgZGVza3RvcCBhY3Rpb25zIG9yIGF1dG9ub21vdXMgd29yay4nLAogIH07CiAgbGV0IG5hbWVzOwogIHRyeSB7CiAgICBjb25zdCB0YWdzID0gYXdhaXQgc2VuZCgnL2FwaS90YWdzJyk7CiAgICBpZiAoIUFycmF5LmlzQXJyYXkodGFncy5tb2RlbHMpKSB0aHJvdyBuZXcgRXJyb3IoJ0lOVkFMSURfVEFHUycpOwogICAgbmFtZXMgPSB0YWdzLm1vZGVscy5tYXAobSA9PiBtLm5hbWUpOwogIH0gY2F0Y2ggewogICAgcmVzdWx0LmZhaWx1cmUgPSAnT0xMQU1BX1BSRUZMSUdIVF9GQUlMRUQnOyByZXR1cm4gcmVzdWx0OwogIH0KICAvLyBPbmUgaW5mZXJlbmNlIHJlcXVlc3QgcGVyIGluc3RhbGxlZCBtb2RlbCwgc2VxdWVudGlhbGx5LiBObyByZXRyeSBsb29wLgogIGZvciAoY29uc3QgbW9kZWwgb2YgTU9ERUxTKSB7CiAgICBpZiAoIW5hbWVzLmluY2x1ZGVzKG1vZGVsKSkgewogICAgICByZXN1bHQubW9kZWxzLnB1c2goeyBtb2RlbCwgc3RhdHVzOiAnTU9ERUxfTk9UX0lOU1RBTExFRCcgfSk7IGNvbnRpbnVlOwogICAgfQogICAgY29uc3Qgc3RhcnQgPSBEYXRlLm5vdygpOwogICAgdHJ5IHsKICAgICAgY29uc3QgcmVzcG9uc2UgPSBhd2FpdCBzZW5kKCcvYXBpL2NoYXQnLCB7CiAgICAgICAgbW9kZWwsIHN0cmVhbTogZmFsc2UsIGtlZXBfYWxpdmU6IDAsCiAgICAgICAgb3B0aW9uczogeyB0ZW1wZXJhdHVyZTogMCwgbnVtX2N0eDogODE5MiwgbnVtX3ByZWRpY3Q6IDI1NiB9LAogICAgICAgIG1lc3NhZ2VzOiBbeyByb2xlOiAndXNlcicsIGNvbnRlbnQ6ICdDYWxsIGdldF93ZWF0aGVyIHdpdGggY2l0eSBleGFjdGx5ICJQcmVzdG9uIElkYWhvIi4gRG8gbm90IGFuc3dlciBpbiBwcm9zZS4nIH1dLAogICAgICAgIHRvb2xzOiBbeyB0eXBlOiAnZnVuY3Rpb24nLCBmdW5jdGlvbjogewogICAgICAgICAgbmFtZTogJ2dldF93ZWF0aGVyJywgZGVzY3JpcHRpb246ICdHZXQgd2VhdGhlciBmb3IgYSBjaXR5JywKICAgICAgICAgIHBhcmFtZXRlcnM6IHsgdHlwZTogJ29iamVjdCcsIHByb3BlcnRpZXM6IHsgY2l0eTogeyB0eXBlOiAnc3RyaW5nJyB9IH0sIHJlcXVpcmVkOiBbJ2NpdHknXSwgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlIH0sCiAgICAgICAgfSB9XSwKICAgICAgfSk7CiAgICAgIHJlc3VsdC5tb2RlbHMucHVzaCh7IG1vZGVsLCBzdGF0dXM6IGNsYXNzaWZ5KHJlc3BvbnNlKSwgZHVyYXRpb25fbXM6IERhdGUubm93KCkgLSBzdGFydCwKICAgICAgICByZXNwb25zZV9zaGEyNTY6IHNoYShKU09OLnN0cmluZ2lmeShyZXNwb25zZSkpIH0pOwogICAgfSBjYXRjaCB7CiAgICAgIHJlc3VsdC5tb2RlbHMucHVzaCh7IG1vZGVsLCBzdGF0dXM6ICdSRVFVRVNUX0ZBSUxFRF9PUl9USU1FRF9PVVQnLCBkdXJhdGlvbl9tczogRGF0ZS5ub3coKSAtIHN0YXJ0IH0pOwogICAgfQogIH0KICBpZiAocmVzdWx0Lm1vZGVscy5sZW5ndGggPT09IE1PREVMUy5sZW5ndGggJiYgcmVzdWx0Lm1vZGVscy5ldmVyeShtID0+IG0uc3RhdHVzID09PSAnUEFTUycpKSByZXN1bHQuc3RhdHVzID0gJ1BBU1MnOwogIHJldHVybiByZXN1bHQ7Cn0KZXhwb3J0IGFzeW5jIGZ1bmN0aW9uIHNhdmVSZWNlaXB0KHJlcG9ydCwgcm9vdCkgewogIGF3YWl0IG1rZGlyKHJvb3QsIHsgcmVjdXJzaXZlOiB0cnVlIH0pOwogIGNvbnN0IGhpc3RvcnkgPSBqb2luKHJvb3QsICdvbGxhbWEtaXNvbGF0ZS0nICsgcmVwb3J0LmlkICsgJy5qc29uJyk7CiAgY29uc3QgbGF0ZXN0ID0gam9pbihyb290LCAnb2xsYW1hLWlzb2xhdGUtbGF0ZXN0Lmpzb24nKTsKICBjb25zdCBzdGFnZSA9IGxhdGVzdCArICcuJyArIHJhbmRvbVVVSUQoKSArICcudG1wJzsKICBjb25zdCBieXRlcyA9IEpTT04uc3RyaW5naWZ5KHJlcG9ydCwgbnVsbCwgMikgKyAnXG4nOwogIGF3YWl0IHdyaXRlRmlsZShoaXN0b3J5LCBieXRlcywgeyBmbGFnOiAnd3gnIH0pOwogIGF3YWl0IHdyaXRlRmlsZShzdGFnZSwgYnl0ZXMsIHsgZmxhZzogJ3d4JyB9KTsKICBhd2FpdCByZW5hbWUoc3RhZ2UsIGxhdGVzdCk7CiAgcmV0dXJuIGxhdGVzdDsKfQppZiAocHJvY2Vzcy5hcmd2WzFdICYmIHJlc29sdmUocHJvY2Vzcy5hcmd2WzFdKSA9PT0gZmlsZVVSTFRvUGF0aChpbXBvcnQubWV0YS51cmwpKSB7CiAgaWYgKHByb2Nlc3MuYXJndi5sZW5ndGggIT09IDIpIHRocm93IG5ldyBFcnJvcignVGhpcyBkaWFnbm9zdGljIGFjY2VwdHMgbm8gYXJndW1lbnRzLicpOwogIGNvbnN0IHJlcG9ydCA9IGF3YWl0IHByb2JlKCk7CiAgcmVwb3J0LnNvdXJjZV9zaGEyNTYgPSBzaGEoYXdhaXQgcmVhZEZpbGUoZmlsZVVSTFRvUGF0aChpbXBvcnQubWV0YS51cmwpKSk7CiAgY29uc3QgdGFyZ2V0ID0gYXdhaXQgc2F2ZVJlY2VpcHQocmVwb3J0LCBqb2luKGhvbWVkaXIoKSwgJy5vcGVuY2xhdycsICd3b3Jrc3BhY2UnLCAncmVwb3J0cycpKTsKICBjb25zb2xlLmxvZygnT2xsYW1hIGlzb2xhdGlvbjogJyArIHJlcG9ydC5zdGF0dXMpOwogIGZvciAoY29uc3QgbSBvZiByZXBvcnQubW9kZWxzKSBjb25zb2xlLmxvZyhtLm1vZGVsICsgJzogJyArIG0uc3RhdHVzKTsKICBjb25zb2xlLmxvZygnUmVjZWlwdDogJyArIHRhcmdldCk7CiAgcHJvY2Vzcy5leGl0Q29kZSA9IHJlcG9ydC5zdGF0dXMgPT09ICdQQVNTJyA/IDAgOiAxOwp9Cg=='))
    $node=Get-Command node -ErrorAction SilentlyContinue
    if ($node) {
        & $node.Source $diagnostic
        $isolatePath=Join-Path $workspace 'reports\ollama-isolate-latest.json'
        if (Test-Path -LiteralPath $isolatePath) {
            $isolate=Read-Json $isolatePath
            if ([DateTimeOffset]$isolate.generated_at -ge $isolateStart.AddSeconds(-2)) {
                Copy-Item -LiteralPath $isolatePath -Destination (Join-Path $stage 'ollama-isolate-latest.json')
            } else { Write-Json (Join-Path $stage 'isolate-collection-error.json') @{status='FAILED';reason='No fresh isolation receipt'} }
        } else { Write-Json (Join-Path $stage 'isolate-collection-error.json') @{status='FAILED';reason='No isolation receipt'} }
    } else { Write-Json (Join-Path $stage 'isolate-collection-error.json') @{status='BLOCKED';reason='Node is not on PATH'} }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive
    Write-Host ('Created: '+$archive)
    Write-Host 'Upload this ZIP to the Kevin Build chat. No settings were changed and nothing was uploaded automatically.'
} finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force } }
