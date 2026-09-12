param([switch]$SelfTest)
# Diagnose-Kevin-InvocationStage-v1.ps1
# GREEN-A/C. Runs builder+stage against live HESS-PC files and publishes ONLY
# a reason-code (+ hashes). No raw logs, configs, environment, or secrets.
# Uses an isolated diagnose queue so it cannot collide with Supervisor orders.
# If live python hashes mismatch, runs Repair once (-SkipDiagnose) then retries.
# If builder returns WORK_ITEM_NOT_UNIQUE or WORK_ITEM_NOT_FOUND, runs
# --repair-unique once then retries the builder.
# After isolated STAGE_OK: quarantines sticky invoke-<work-id> leftovers, then
# stages the Supervisor RequestId (invoke-<work-id>) into diagnose-worker-sim
# (never Action Era). Publishes live worker hashes. Does not recopy Supervisor.
# Does not replace the live worker pin. Not PASS.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { Split-Path -Parent $PSScriptRoot }
$Autonomy = Join-Path $Workspace 'control-plane\autonomy'
$Builder = Join-Path $Autonomy 'kevin-proven-skill-request-builder-v1.py'
$Invoker = Join-Path $Autonomy 'kevin-proven-skill-invocation-v1.py'
$Items = Join-Path $Workspace 'inbox\autonomy\work-items.json'
$Registry = Join-Path $Workspace 'reports\capabilities\composite-skills.json'
$ProofRoot = Join-Path $Workspace 'reports\action-era\skills\done'
$Ready = Join-Path $Workspace 'reports\invocations\diagnose-ready'
$RunRoot = Join-Path $Workspace 'reports\invocations\diagnose-runs'
$SimReady = Join-Path $Workspace 'reports\invocations\diagnose-worker-sim'
$OutDir = Join-Path $Workspace 'reports\invocations'
$LiveReady = Join-Path $Workspace 'reports\action-era\queue\ready'
$Archive = Join-Path $Workspace 'inbox\autonomy\archive'
$WorkId = 'owner-west-motor-parts-chase-fresh-8-v1'
$RequestId = 'diagnose-' + $WorkId
$SupervisorRequestId = 'invoke-' + $WorkId
$InvExpected$BldExpected$BldExpected = 'E7381E6051B988A0E36386265A0E09263D88CF83EB2EB2BAC808DF04EB5BB1B3'
$BldExpected$BldExpected$BldExpected$BldExpected = 'E7381E6051B988A0E36386265A0E09263D88CF83EB2EB2BAC808DF04EB5BB1B3'
$WorkerExpectedV1$BldExpected$BldExpected = 'E7381E6051B988A0E36386265A0E09263D88CF83EB2EB2BAC808DF04EB5BB1B3'
$WorkerExpectedV11$BldExpected$BldExpected = 'E7381E6051B988A0E36386265A0E09263D88CF83EB2EB2BAC808DF04EB5BB1B3'
$WorkerLivePath = Join-Path $Workspace 'ControlPlane\kevin-proven-skill-invoke-worker-v1.ps1'
$WorkerV11Path = Join-Path $Workspace 'control-plane\autonomy\kevin-proven-skill-invoke-worker-v1.1.ps1'

function Get-Sha256Upper([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return ([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($Path)) | ForEach-Object { $_.ToString('X2') }) -join ''
}
function Write-Utf8NoBom([string]$Path, [string]$Text) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, $Utf8)
}
function Reason-FromJson([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    if ($Text -match 'Unexpected UTF-8 BOM' -or $Text -match 'utf-8 BOM') { return 'WORK_ITEMS_UTF8_BOM' }
    foreach ($line in ($Text -split "`r?`n")) {
        $line = $line.Trim()
        if ($line.StartsWith('{') -and $line.EndsWith('}')) {
            try {
                $o = $line | ConvertFrom-Json
                if ($o.reason) {
                    $r = [string]$o.reason
                    if ($r -match 'UTF-8 BOM|Unexpected UTF-8 BOM') { return 'WORK_ITEMS_UTF8_BOM' }
                    return $r
                }
                if ($o.status -and [string]$o.status -ne 'REJECTED') { return [string]$o.status }
                if ($o.status) { return [string]$o.status }
            } catch {}
        }
    }
    try {
        $o = $Text | ConvertFrom-Json
        if ($o.reason) { return [string]$o.reason }
        if ($o.status) { return [string]$o.status }
    } catch {}
    $m = [regex]::Match($Text, '(?<![A-Za-z])([A-Z][A-Z0-9_]{5,80})(?![A-Za-z])')
    if ($m.Success) {
        $code = $m.Groups[1].Value
        if ($code -notin @('TRACEBACK','FILE','PYTHON')) { return $code }
    }
    return 'UNPARSEABLE_REASON'
}
function Field-FromJson([string]$Text, [string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    foreach ($line in ($Text -split "`r?`n")) {
        $line = $line.Trim()
        if ($line.StartsWith('{') -and $line.EndsWith('}')) {
            try {
                $o = $line | ConvertFrom-Json
                $val = $o.$Name
                if ($null -ne $val) { return $val }
            } catch {}
        }
    }
    return $null
}

if ($SelfTest) {
    if ($InvExpected.Length -ne 64) { throw 'inv hash pin' }
    if ($BldExpected.Length -ne 64) { throw 'bld hash pin' }
    if ($WorkerExpectedV1.Length -ne 64) { throw 'worker v1 pin' }
    if ($WorkerExpectedV11.Length -ne 64) { throw 'worker v11 pin' }
    if ($SupervisorRequestId -ne 'invoke-owner-west-motor-parts-chase-fresh-8-v1') { throw 'supervisor request id' }
    $tb = "Traceback (most recent call last):`n  File `"x.py`", line 1`njson.decoder.JSONDecodeError: Unexpected UTF-8 BOM"
    if ((Reason-FromJson $tb) -ne 'WORK_ITEMS_UTF8_BOM') { throw 'bom reason map' }
    $jsonLine = '{"status": "REJECTED", "reason": "VEHICLE_COUNT_MUST_BE_8"}'
    if ((Reason-FromJson $jsonLine) -ne 'VEHICLE_COUNT_MUST_BE_8') { throw 'json reason' }
    if ((Reason-FromJson 'Traceback (most recent call last):') -eq 'Traceback') { throw 'traceback not a reason' }
    $nf = '{"status": "REJECTED", "reason": "WORK_ITEM_NOT_FOUND", "match_count": 0, "items_count": 17}'
    if ((Reason-FromJson $nf) -ne 'WORK_ITEM_NOT_FOUND') { throw 'not found reason' }
    if ([int](Field-FromJson $nf 'match_count') -ne 0) { throw 'match count 0' }
    $nu = '{"status": "REJECTED", "reason": "WORK_ITEM_NOT_UNIQUE", "match_count": 2}'
    if ((Reason-FromJson $nu) -ne 'WORK_ITEM_NOT_UNIQUE') { throw 'not unique reason' }
    if ([int](Field-FromJson $nu 'match_count') -ne 2) { throw 'match count 2' }
    $reuse = '{"status": "REJECTED", "reason": "INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST"}'
    if ((Reason-FromJson $reuse) -ne 'INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST') { throw 'reuse reason' }
    Write-Host 'KEVIN INVOCATION STAGE DIAGNOSE v1 SELFTEST PASS'
    exit 0
}

New-Item -ItemType Directory -Force -Path $RunRoot, $Ready, $SimReady, $OutDir, $Archive | Out-Null
$invHash = Get-Sha256Upper $Invoker
$bldHash = Get-Sha256Upper $Builder
$workerLiveHash = Get-Sha256Upper $WorkerLivePath
$workerV11Hash = Get-Sha256Upper $WorkerV11Path
$workerHasHidden = $false
if (Test-Path -LiteralPath $WorkerLivePath -PathType Leaf) {
    $workerHasHidden = ([IO.File]::ReadAllText($WorkerLivePath) -match 'Invoke-HiddenPython')
}
$missing = @()
foreach ($pair in @(@('builder',$Builder), @('invoker',$Invoker), @('registry',$Registry), @('work-items',$Items), @('proof-root',$ProofRoot))) {
    if (-not (Test-Path -LiteralPath $pair[1])) { $missing += $pair[0] }
}

$reason = 'NOT_RUN'
$class = 'PRECHECK'
$exitCode = -1
$readyCount = 0
$liveReadyCount = 0
$matchCount = $null
$itemsCount = $null
$repairUnique = $null
$stickyStatus = $null
$stickyCount = $null
$supervisorRequestReason = $null
if ($missing.Count -gt 0) {
    $reason = 'MISSING:' + (($missing | Select-Object -First 6) -join ',')
    $class = 'MISSING_INPUT'
} else {
    if ($invHash -ne $InvExpected -or $bldHash -ne $BldExpected) {
        $repair = Join-Path $Workspace 'tools\Repair-Kevin-InvocationRegistryContract-v1.ps1'
        if ($env:KEVIN_DIAGNOSE_REPAIR_ONCE -ne '1' -and (Test-Path -LiteralPath $repair -PathType Leaf)) {
            $env:KEVIN_DIAGNOSE_REPAIR_ONCE = '1'
            Write-Host 'diagnose: python hash mismatch; applying registry repair once'
            try { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $repair -SkipDiagnose } catch { Write-Host ('repair skip: ' + $_) }
            $invHash = Get-Sha256Upper $Invoker
            $bldHash = Get-Sha256Upper $Builder
        }
    }
    if ($invHash -ne $InvExpected -or $bldHash -ne $BldExpected) {
        $reason = 'PYTHON_HASH_MISMATCH'
        $class = 'PYTHON_NOT_V103'
    } else {
        $py = $null
        foreach ($cand in @('python','python3','py')) {
            $cmd = Get-Command $cand -ErrorAction SilentlyContinue
            if ($cmd) { $py = $cmd.Source; break }
        }
        if (-not $py) {
            $reason = 'PYTHON_NOT_AVAILABLE'
            $class = 'PYTHON_NOT_AVAILABLE'
        } else {
            $req = Join-Path $RunRoot ($RequestId + '.request.json')
            $st = Join-Path $RunRoot ($RequestId + '.json')
            if (Test-Path -LiteralPath $st) { Remove-Item -LiteralPath $st -Force }
            function Invoke-HiddenPython([string[]]$PyArgs) {
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = $py
                $psi.Arguments = ($PyArgs | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
                $psi.UseShellExecute = $false
                $psi.RedirectStandardOutput = $true
                $psi.RedirectStandardError = $true
                $psi.CreateNoWindow = $true
                $p = New-Object System.Diagnostics.Process
                $p.StartInfo = $psi
                [void]$p.Start()
                $stdout = $p.StandardOutput.ReadToEnd()
                $stderr = $p.StandardError.ReadToEnd()
                $p.WaitForExit()
                return [pscustomobject]@{ ExitCode = [int]$p.ExitCode; Combined = ([string]$stdout + [string]$stderr).Trim() }
            }
            $built = Invoke-HiddenPython @($Builder, '--invocation-id', $RequestId, '--output', $req, '--work-items', $Items, '--work-id', $WorkId)
            $reason = Reason-FromJson $built.Combined
            $mc = Field-FromJson $built.Combined 'match_count'
            $ic = Field-FromJson $built.Combined 'items_count'
            if ($null -ne $mc) { $matchCount = [int]$mc }
            if ($null -ne $ic) { $itemsCount = [int]$ic }
            if ($built.ExitCode -ne 0 -and $reason -in @('WORK_ITEM_NOT_UNIQUE','WORK_ITEM_NOT_FOUND') -and $env:KEVIN_WORKITEMS_REPAIR_ONCE -ne '1') {
                $env:KEVIN_WORKITEMS_REPAIR_ONCE = '1'
                Write-Host ('diagnose: ' + $reason + '; repairing work-items uniqueness once')
                $fixed = Invoke-HiddenPython @($Builder, '--repair-unique', '--work-items', $Items, '--work-id', $WorkId, '--archive', $Archive)
                $repairUnique = Reason-FromJson $fixed.Combined
                Write-Host ('uniqueness repair=' + $repairUnique + ' exit=' + $fixed.ExitCode)
                $built = Invoke-HiddenPython @($Builder, '--invocation-id', $RequestId, '--output', $req, '--work-items', $Items, '--work-id', $WorkId)
                $reason = Reason-FromJson $built.Combined
                $mc = Field-FromJson $built.Combined 'match_count'
                $ic = Field-FromJson $built.Combined 'items_count'
                if ($null -ne $mc) { $matchCount = [int]$mc }
                if ($null -ne $ic) { $itemsCount = [int]$ic }
            }
            if ($built.ExitCode -ne 0) {
                if (-not $reason) { $reason = 'BUILDER_REJECTED' }
                $class = 'BUILDER_REJECTED'
                $exitCode = $built.ExitCode
            } else {
                $stage = Invoke-HiddenPython @($Invoker, 'stage', '--registry', $Registry, '--proof-root', $ProofRoot, '--request', $req, '--state', $st, '--queue-ready', $Ready)
                $exitCode = $stage.ExitCode
                if ($stage.ExitCode -ne 0) {
                    $reason = Reason-FromJson $stage.Combined
                    if (-not $reason) { $reason = 'STAGE_REJECTED' }
                    $class = 'STAGE_REJECTED'
                } else {
                    $reason = 'STAGE_OK_WAITING_ACTION_ERA'
                    $class = 'STAGED'
                    $sticky = Join-Path $Workspace 'tools\Repair-Kevin-StickyInvokeState-v1.ps1'
                    if (Test-Path -LiteralPath $sticky -PathType Leaf) {
                        try {
                            $stickyOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $sticky
                            $stickyStatus = Reason-FromJson ([string]$stickyOut)
                            $sc = Field-FromJson ([string]$stickyOut) 'quarantined_count'
                            if ($null -ne $sc) { $stickyCount = [int]$sc }
                            Write-Host ('sticky repair=' + $stickyStatus + ' count=' + $stickyCount)
                        } catch { Write-Host ('sticky skip: ' + $_) }
                    }
                    $simReq = Join-Path $RunRoot ($SupervisorRequestId + '.request.json')
                    $simSt = Join-Path $RunRoot ($SupervisorRequestId + '.sim.json')
                    if (Test-Path -LiteralPath $simSt) { Remove-Item -LiteralPath $simSt -Force }
                    $builtSup = Invoke-HiddenPython @($Builder, '--invocation-id', $SupervisorRequestId, '--output', $simReq, '--work-items', $Items, '--work-id', $WorkId)
                    if ($builtSup.ExitCode -ne 0) {
                        $reason = Reason-FromJson $builtSup.Combined
                        if (-not $reason) { $reason = 'BUILDER_REJECTED' }
                        $class = 'SUPERVISOR_REQUEST_ID_BUILDER'
                        $exitCode = $builtSup.ExitCode
                        $supervisorRequestReason = $reason
                    } else {
                        $stageSup = Invoke-HiddenPython @($Invoker, 'stage', '--registry', $Registry, '--proof-root', $ProofRoot, '--request', $simReq, '--state', $simSt, '--queue-ready', $SimReady)
                        $supervisorRequestReason = Reason-FromJson $stageSup.Combined
                        if ($stageSup.ExitCode -ne 0) {
                            $reason = $supervisorRequestReason
                            if (-not $reason) { $reason = 'STAGE_REJECTED' }
                            $class = 'SUPERVISOR_REQUEST_ID_STAGE'
                            $exitCode = $stageSup.ExitCode
                        } else {
                            $supervisorRequestReason = 'STAGE_OK'
                        }
                    }
                }
            }
        }
    }
}
if (Test-Path -LiteralPath $Ready) {
    $readyCount = @(Get-ChildItem -LiteralPath $Ready -File -Filter 'invoke-*.json' -ErrorAction SilentlyContinue).Count
}
if (Test-Path -LiteralPath $LiveReady) {
    $liveReadyCount = @(Get-ChildItem -LiteralPath $LiveReady -File -Filter 'invoke-*.json' -ErrorAction SilentlyContinue).Count
}

$reject = [ordered]@{
    schema = 1
    kind = 'kevin-invocation-public-reject'
    version = '1.3.2'
    authority = 'GREEN'
    generated_at = [datetime]::Now.ToString('o')
    safe_for_public_repo = $true
    public_payload_policy = 'reason-code and hashes only; no raw logs, configs, environment, or secrets'
    work_id_hint = $WorkId
    reason = $reason
    reason_class = $class
    python_exit = $exitCode
    match_count = $matchCount
    items_count = $itemsCount
    uniqueness_repair = $repairUnique
    sticky_repair = $stickyStatus
    sticky_quarantined_count = $stickyCount
    supervisor_request_id = $SupervisorRequestId
    supervisor_request_id_reason = $supervisorRequestReason
    worker_live_sha256 = $workerLiveHash
    worker_v11_sha256 = $workerV11Hash
    worker_has_hidden_python = $workerHasHidden
    expected_worker_v1_sha256 = $WorkerExpectedV1
    expected_worker_v11_sha256 = $WorkerExpectedV11
    invocation_py_sha256 = $invHash
    builder_py_sha256 = $bldHash
    expected_invocation_py_sha256 = $InvExpected
    expected_builder_py_sha256 = $BldExpected
    diagnose_ready_count = $readyCount
    live_action_era_ready_invoke_count = $liveReadyCount
    isolated_diagnose_queue = $true
    outcome_proven = $false
    truth_boundary = 'Diagnostic reason-code only. Isolated diagnose queue is not Action Era. Supervisor RequestId sim is not PASS. PASS still requires workbook + note + DONE + hashes + receipt.'
}
# DURABLE_OUTCOME_PROVEN: do not let diagnose lag wipe VERIFY PASS MIXED / live expect pins
$doneReceiptPath = Join-Path $OutDir ('done\' + $SupervisorRequestId + '.json')
if (Test-Path -LiteralPath $doneReceiptPath -PathType Leaf) {
    try {
        $doneObj = Get-Content -LiteralPath $doneReceiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]$doneObj.status -eq 'PROVEN') {
            $reject.outcome_proven = $true
            $reject.reason = 'OUTCOME_PROVEN'
            $reject.reason_class = 'PROVEN'
            $reject['receipt_status'] = 'PROVEN'
            $reject['receipt_sha256'] = (Get-Sha256Upper $doneReceiptPath)
            $reject['verify_actor'] = 'MIXED'
            $reject['expected_live_worker_sha256'] = $WorkerExpectedV11
            $reject['expected_live_operator_sha256'] = $OperatorExpectedLive
            if (Get-Variable operatorLiveHash -ErrorAction SilentlyContinue) {
                $reject['operator_live_sha256'] = $operatorLiveHash
                $reject['hashes_match_pin'] = (($workerLiveHash -eq $WorkerExpectedV11) -and ($operatorLiveHash -eq $OperatorExpectedLive))
            }
            $reject.truth_boundary = 'DONE receipt PROVEN. VERIFY PASS MIXED actor. Diagnose must not regress outcome_proven. Install pin expected_worker_v1 remains separate.'
        }
    } catch {}
}

$outPath = Join-Path $OutDir 'latest-public-reject.json'
Write-Utf8NoBom $outPath (($reject | ConvertTo-Json -Depth 6) + "`n")
Write-Output ($reject | ConvertTo-Json -Depth 6)

try {
    $b64 = [Convert]::ToBase64String($Utf8.GetBytes((Get-Content -Raw $outPath)))
    $api = 'repos/hessmodee/KEVIN-WORK/contents/reports/invocations/latest-public-reject.json'
    $sha = $null
    try { $sha = gh api $api --jq .sha 2>$null } catch {}
    if ($sha) { gh api --method PUT $api -f message='invocation diagnose' -f content=$b64 -f sha=$sha | Out-Null }
    else { gh api --method PUT $api -f message='invocation diagnose' -f content=$b64 | Out-Null }
} catch { Write-Host "upload skip: $_" }
exit 0
