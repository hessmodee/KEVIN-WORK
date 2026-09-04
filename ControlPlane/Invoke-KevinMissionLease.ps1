# Kevin Mission Lease bridge v1 — authority: NONE. Calls kevin-mission-lease-v1.py store actions.
param(
    [ValidateSet('SelfTest','Acquire','Heartbeat','Release','Recover','Truth')]
    [string]$Action = 'SelfTest',
    [string]$MissionId = '',
    [string]$Holder = '',
    [string]$EvidenceUri = '',
    [string]$Reason = 'COMPLETE',
    [int]$TtlSeconds = 900,
    [string]$StorePath = ''
)
$ErrorActionPreference = 'Stop'
$Workspace = if ($PSScriptRoot -and (Split-Path -Leaf $PSScriptRoot) -eq 'ControlPlane') {
    Split-Path -Parent $PSScriptRoot
} elseif ($env:USERPROFILE) {
    Join-Path $env:USERPROFILE '.openclaw\workspace'
} else {
    $PSScriptRoot
}
$Py = Join-Path $Workspace 'control-plane\autonomy\kevin-mission-lease-v1.py'
if (-not $StorePath) {
    $StorePath = Join-Path $Workspace 'reports\autonomy-runtime\mission-leases-v1.json'
}
if (-not (Test-Path -LiteralPath $Py -PathType Leaf)) { throw "lease library missing: $Py" }

function Invoke-LeaseCli([string[]]$CliArgs) {
    $out = & python $Py @CliArgs 2>&1
    $code = $LASTEXITCODE
    return [pscustomobject]@{ ExitCode = $code; Output = (($out | Out-String).Trim()) }
}

if ($Action -eq 'SelfTest') {
    $lib = Invoke-LeaseCli @('--selftest')
    if ($lib.ExitCode -ne 0) { throw "lease library selftest failed: $($lib.Output)" }
    $tmp = Join-Path $env:TEMP ('kevin-lease-wire-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        $a = Invoke-LeaseCli @('--store', $tmp, '--action', 'acquire', '--mission-id', 'wire-selftest-mission', '--holder', 'skill-lab', '--ttl-seconds', '120', '--evidence-uri', 'reports/autonomy-runtime/wire-selftest.evidence')
        if ($a.ExitCode -ne 0) { throw "acquire failed: $($a.Output)" }
        $h = Invoke-LeaseCli @('--store', $tmp, '--action', 'heartbeat', '--mission-id', 'wire-selftest-mission', '--holder', 'skill-lab', '--evidence-uri', 'reports/autonomy-runtime/wire-selftest.evidence')
        if ($h.ExitCode -ne 0) { throw "heartbeat failed: $($h.Output)" }
        $t = Invoke-LeaseCli @('--store', $tmp, '--action', 'truth', '--mission-id', 'wire-selftest-mission')
        if ($t.Output -notmatch 'WORKING') { throw "truth expected WORKING: $($t.Output)" }
        $r = Invoke-LeaseCli @('--store', $tmp, '--action', 'release', '--mission-id', 'wire-selftest-mission', '--holder', 'skill-lab', '--reason', 'SELFTEST')
        if ($r.ExitCode -ne 0) { throw "release failed: $($r.Output)" }
        Write-Host 'KEVIN MISSION LEASE WIRE v1 SELFTEST PASS library=PASS acquire=PASS heartbeat=PASS truth=WORKING release=PASS authority=NONE'
        exit 0
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

$argsList = @('--store', $StorePath, '--action', $Action.ToLowerInvariant())
if ($MissionId) { $argsList += @('--mission-id', $MissionId) }
if ($Holder) { $argsList += @('--holder', $Holder) }
if ($EvidenceUri) { $argsList += @('--evidence-uri', $EvidenceUri) }
if ($Action -eq 'Acquire') { $argsList += @('--ttl-seconds', [string]$TtlSeconds) }
if ($Action -eq 'Release') { $argsList += @('--reason', $Reason) }
$res = Invoke-LeaseCli $argsList
Write-Output $res.Output
exit $res.ExitCode
