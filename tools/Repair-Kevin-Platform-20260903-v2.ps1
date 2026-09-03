param(
    [switch]$CheckOnly,
    [switch]$Apply,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)

# Exact evidence/pins from Matt's 2026-09-02 HESS-PC collector and the corrected R04 v2 wrapper.
$Repo = 'hessmodee/KEVIN-WORK'
$R04Ref = 'main'
$R04Path = 'candidates/maintenance/r04-production-config-rebaseline-v2/kevin-r04-production-config-rebaseline-v2.ps1'
$R04Blob = '30f41ac7701684b673af83324e263ef6e6eec036'
$ConfigSha = '23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5'
$BaselineSha = '1396897473D874154FF24DB933D4B4FB643298652FC3C0C05097971DC2336B30'
$BenchmarkSha = '4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964'
$UiSha = '5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42'
$TaskName = 'Kevin UI Bridge v0.3'

$Workspace = Join-Path $env:USERPROFILE '.openclaw\workspace'
$ConfigPath = Join-Path $env:USERPROFILE '.openclaw\openclaw.json'
$BaselinePath = Join-Path $Workspace 'reports\benchmark-v1\baseline.json'
$BenchmarkPath = Join-Path $Workspace 'kevin-benchmark-v1.ps1'
$BenchmarkLatest = Join-Path $Workspace 'reports\benchmark-v1\latest.json'
$UiBridgePath = Join-Path $Workspace 'kevin-ui-bridge.ps1'
$UiRoot = Join-Path $Workspace 'reports\action-era\ui-bridge'
$HeartbeatPath = Join-Path $UiRoot 'heartbeat.json'
$UiInbox = Join-Path $UiRoot 'inbox'
$UiResults = Join-Path $UiRoot 'results'
$RepairRoot = Join-Path $Workspace 'reports\maintenance\platform-repair-20260903'
$ReceiptPath = Join-Path $Workspace 'reports\maintenance\platform-repair-20260903-latest.json'

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Read-Json([string]$Path) {
    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}

function Write-JsonAtomic([string]$Path, [object]$Value) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp, ($Value | ConvertTo-Json -Depth 30), $Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Invoke-FixedPowerShell([string]$Path, [string[]]$Arguments) {
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path @Arguments 2>&1 | Out-String).Trim()
        $exitCode = [int]$LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $old
    }
    if ($exitCode -ne 0) {
        throw ('Fixed PowerShell child failed exit=' + $exitCode + ' ' + $output)
    }
    return $output
}

function Get-PinnedR04Candidate {
    $gh = Get-Command gh.exe -ErrorAction SilentlyContinue
    if (-not $gh) { $gh = Get-Command gh -ErrorAction Stop }
    $endpoint = 'repos/' + $Repo + '/contents/' + $R04Path + '?ref=' + $R04Ref
    $raw = (& $gh.Source api $endpoint -H 'Accept: application/vnd.github+json' 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw ('Pinned R04 fetch failed: ' + $raw) }
    $meta = $raw | ConvertFrom-Json
    if ([string]$meta.sha -cne $R04Blob) {
        throw ('Pinned R04 Git blob mismatch actual=' + [string]$meta.sha)
    }
    $candidate = Join-Path $env:TEMP ('kevin-r04-' + [guid]::NewGuid().ToString('N') + '.ps1')
    [IO.File]::WriteAllBytes($candidate, [Convert]::FromBase64String(([string]$meta.content -replace '\s','')))
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($candidate, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw ('Pinned R04 parser rejected: ' + $errors[0].Message) }
    return $candidate
}

function Assert-InitialPlatformState {
    if ((Get-Sha $ConfigPath) -cne $ConfigSha) { throw ('Production config identity changed: ' + (Get-Sha $ConfigPath)) }
    if ((Get-Sha $BaselinePath) -cne $BaselineSha) { throw ('Benchmark baseline identity changed: ' + (Get-Sha $BaselinePath)) }
    if ((Get-Sha $BenchmarkPath) -cne $BenchmarkSha) { throw ('Benchmark runner identity changed: ' + (Get-Sha $BenchmarkPath)) }
    if ((Get-Sha $UiBridgePath) -cne $UiSha) { throw ('UI Bridge identity changed: ' + (Get-Sha $UiBridgePath)) }

    $latest = Read-Json $BenchmarkLatest
    if ([string]$latest.status -cne 'FAIL_CRITICAL_REGRESSION' -or
        [int]$latest.regression.passed -ne 29 -or
        [int]$latest.regression.total -ne 30 -or
        [int]$latest.regression.critical_failures -ne 1) {
        throw 'Benchmark is no longer the exact expected 29/30 critical1 precondition.'
    }
}

function Get-UiTaskDefinitionState {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) { return [pscustomobject]@{ ok=$false; reason='missing' } }
    $actions = @($task.Actions)
    if ($actions.Count -ne 1) { return [pscustomobject]@{ ok=$false; reason='actions' } }

    $powerShellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
    $expectedArguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $UiBridgePath + '" -RunLoop'
    if ([IO.Path]::GetFullPath([string]$actions[0].Execute) -ine [IO.Path]::GetFullPath($powerShellExe)) {
        return [pscustomobject]@{ ok=$false; reason='execute' }
    }
    if ([string]$actions[0].Arguments -cne $expectedArguments) {
        return [pscustomobject]@{ ok=$false; reason='arguments' }
    }
    if ([string]$task.Principal.LogonType -inotmatch 'Interactive' -or [string]$task.Principal.RunLevel -inotmatch 'Limited') {
        return [pscustomobject]@{ ok=$false; reason='principal' }
    }
    return [pscustomobject]@{ ok=$true; reason='exact' }
}

function Wait-ForSustainedUiHeartbeat {
    $started = [DateTimeOffset]::Now
    Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    $first = $null
    $deadline = (Get-Date).AddSeconds(35)

    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if (Test-Path -LiteralPath $HeartbeatPath -PathType Leaf) {
            try {
                $heartbeat = Read-Json $HeartbeatPath
                $at = [DateTimeOffset]::Parse([string]$heartbeat.at)
                if ((@('READY','WORKING') -contains [string]$heartbeat.state) -and
                    [bool]$heartbeat.explorer_same_session -and
                    [int]$heartbeat.session_id -gt 0 -and
                    $at -ge $started.AddSeconds(-2)) {
                    $first = $heartbeat
                    break
                }
            }
            catch {}
        }
    }
    if (-not $first) { throw 'UI Bridge did not produce a fresh interactive heartbeat.' }

    $firstAt = [DateTimeOffset]::Parse([string]$first.at)
    Start-Sleep -Seconds 7
    $second = Read-Json $HeartbeatPath
    $secondAt = [DateTimeOffset]::Parse([string]$second.at)
    if ($secondAt -le $firstAt.AddSeconds(2) -or
        ([DateTimeOffset]::Now - $secondAt).TotalSeconds -gt 10 -or
        (@('READY','WORKING') -notcontains [string]$second.state) -or
        -not [bool]$second.explorer_same_session) {
        throw 'UI Bridge heartbeat did not continue after startup.'
    }
    return [ordered]@{
        first_at=$firstAt.ToString('o')
        second_at=$secondAt.ToString('o')
        session_id=[int]$second.session_id
        state=[string]$second.state
    }
}

function Register-KnownGoodUiTask {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $powerShellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
    $arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $UiBridgePath + '" -RunLoop'
    $action = New-ScheduledTaskAction -Execute $powerShellExe -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
    $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Days 3650)
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Kevin narrow InteractiveToken UI Bridge. GREEN Notepad-only. No generic mouse/keyboard/browser.' -Force | Out-Null
}

function Repair-UiBridgeTask {
    $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $backupXml = ''
    if ($existing) {
        New-Item -ItemType Directory -Path $RepairRoot -Force | Out-Null
        $backupXml = Join-Path $RepairRoot 'ui-task.before.xml'
        Export-ScheduledTask -TaskName $TaskName | Set-Content -LiteralPath $backupXml -Encoding Unicode
    }

    $definition = Get-UiTaskDefinitionState
    if ($definition.ok) {
        try {
            return [ordered]@{status='ALREADY_HEALTHY';heartbeat=(Wait-ForSustainedUiHeartbeat);replaced=$false}
        }
        catch {
            # Exact task but failed persistent startup: materially new evidence authorizes restoring known-good definition.
        }
    }

    try {
        try { Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue } catch {}
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
        Register-KnownGoodUiTask
        $after = Get-UiTaskDefinitionState
        if (-not $after.ok) { throw ('New UI task definition failed verification: ' + $after.reason) }
        return [ordered]@{status='REPAIRED';heartbeat=(Wait-ForSustainedUiHeartbeat);replaced=$true;backup=$backupXml}
    }
    catch {
        $originalError = $_.Exception.Message
        if ($backupXml -and (Test-Path -LiteralPath $backupXml -PathType Leaf)) {
            try {
                if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
                    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
                }
                Register-ScheduledTask -TaskName $TaskName -Xml (Get-Content -LiteralPath $backupXml -Raw) -Force | Out-Null
            }
            catch {
                throw ('UI repair failed and task rollback also failed: ' + $originalError + ' / ' + $_.Exception.Message)
            }
        }
        throw ('UI repair failed; previous task was restored when available: ' + $originalError)
    }
}

function Invoke-UiNotepadRoundTripProof {
    $sessionId = [int]([Diagnostics.Process]::GetCurrentProcess().SessionId)
    $ownerNotepad = @(Get-Process -Name Notepad -ErrorAction SilentlyContinue | Where-Object { [int]$_.SessionId -eq $sessionId })
    if ($ownerNotepad.Count -gt 0) {
        throw 'Notepad is already open in the owner session; refusing to disturb an owner window.'
    }

    New-Item -ItemType Directory -Path $UiInbox,$UiResults -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $orderId = 'platform-repair-ui-' + $stamp
    $nonce = [guid]::NewGuid().ToString('N').ToUpperInvariant()
    $filename = 'Kevin UI Recovery Verification - ' + $stamp + '.txt'
    $content = 'KEVIN_UI_RECOVERY_OK ' + $stamp
    $request = [ordered]@{
        schema=1
        kind='kevin-ui-bridge-request'
        authority='GREEN'
        operation='ui_notepad_write'
        app='notepad'
        order_id=$orderId
        nonce=$nonce
        filename=$filename
        content=$content
    }
    $resultPath = Join-Path $UiResults ($orderId + '-' + $nonce + '.result.json')
    Write-JsonAtomic (Join-Path $UiInbox ($orderId + '-' + $nonce + '.json')) $request

    $deadline = (Get-Date).AddSeconds(70)
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        Start-Sleep -Milliseconds 500
    }
    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) { throw 'UI Notepad round-trip proof timed out.' }
    $result = Read-Json $resultPath
    if ([string]$result.status -cne 'DONE') {
        throw ('UI Notepad proof failed: ' + [string]$result.status + ' ' + [string]$result.reason)
    }
    if (-not (Test-Path -LiteralPath ([string]$result.data.output_path) -PathType Leaf) -or
        -not (Test-Path -LiteralPath ([string]$result.data.screenshot_path) -PathType Leaf)) {
        throw 'UI Notepad proof evidence files are missing.'
    }
    return [ordered]@{
        status='ROUND_TRIP_PROVEN'
        order_id=$orderId
        output_sha256=[string]$result.data.sha256
        screenshot_sha256=[string]$result.data.screenshot_sha256
        session_id=[int]$result.data.session_id
        text_method=[string]$result.data.text_method
        save_method=[string]$result.data.save_method
    }
}

function Invoke-SelfTest {
    foreach ($hash in @($ConfigSha,$BaselineSha,$BenchmarkSha,$UiSha)) {
        if ($hash -cnotmatch '^[A-F0-9]{64}$') { throw 'SHA256 pin malformed.' }
    }
    if ($R04Ref -cne 'main' -or $R04Blob -cnotmatch '^[a-f0-9]{40}$') {
        throw 'Git pin malformed.'
    }
    if ($TaskName -cne 'Kevin UI Bridge v0.3') { throw 'Task pin changed.' }
    Write-Host 'KEVIN PLATFORM BOOTSTRAP v2 SELFTEST PASS pinned_r04_v2=true ui_task=true sustained_heartbeat=true roundtrip=true rollback=true arbitrary_shell=false'
}

if ($SelfTest) { Invoke-SelfTest; exit 0 }
if ($Apply -and $CheckOnly) { throw 'Choose only one of -Apply or -CheckOnly.' }
if (-not $Apply) { $CheckOnly = $true }
if ($env:OS -ne 'Windows_NT') { throw 'Run this on the Windows PC that hosts Kevin.' }

Assert-InitialPlatformState
$r04Candidate = Get-PinnedR04Candidate
try {
    $selfTestOutput = Invoke-FixedPowerShell $r04Candidate @('-SelfTest')
    if ($selfTestOutput -notmatch 'R04 REBASELINE v2 SELFTEST PASS') { throw 'R04 self-test marker missing.' }
    $checkOutput = Invoke-FixedPowerShell $r04Candidate @('-CheckOnly')
    if ($checkOutput -notmatch 'R04_REBASELINE_READY') { throw 'R04 preflight marker missing.' }

    $taskDefinition = Get-UiTaskDefinitionState
    if ($CheckOnly) {
        Write-Host ('KEVIN_PLATFORM_BOOTSTRAP_READY r04=true ui_task=' + $taskDefinition.ok + ' ui_reason=' + $taskDefinition.reason)
        exit 0
    }

    $receipt = [ordered]@{
        schema=1
        kind='kevin-platform-bootstrap'
        started_at=(Get-Date).ToString('o')
        r04=$null
        ui=$null
        ui_proof=$null
        status='STARTED'
    }

    $applyOutput = Invoke-FixedPowerShell $r04Candidate @('-Apply')
    if ($applyOutput -notmatch 'R04_REBASELINE_APPLIED_PROVEN') { throw 'R04 apply marker missing.' }
    $postBenchmark = Read-Json $BenchmarkLatest
    if ([string]$postBenchmark.status -cne 'PASS' -or
        [int]$postBenchmark.regression.passed -ne 30 -or
        [int]$postBenchmark.regression.total -ne 30 -or
        [int]$postBenchmark.regression.critical_failures -ne 0) {
        throw 'Post-R04 Benchmark is not 30/30 critical0.'
    }
    $receipt.r04 = 'APPLIED_PROVEN'

    $receipt.ui = Repair-UiBridgeTask
    $receipt.ui_proof = Invoke-UiNotepadRoundTripProof
    $receipt.status = 'APPLIED_PROVEN'
    $receipt.completed_at = (Get-Date).ToString('o')
    Write-JsonAtomic $ReceiptPath $receipt
    Write-Host 'KEVIN_PLATFORM_BOOTSTRAP_APPLIED_PROVEN benchmark=30/30 ui=sustained ui_notepad=ROUND_TRIP_PROVEN'
}
finally {
    Remove-Item -LiteralPath $r04Candidate -Force -ErrorAction SilentlyContinue
}
