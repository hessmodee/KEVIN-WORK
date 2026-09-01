from pathlib import Path

src = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.32.ps1')
dst = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.33.ps1')
s = src.read_text(encoding='utf-8')

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit(f'{label}: expected one anchor, got {n}')
    s = s.replace(old, new, 1)

once("version='1.3.32'", "version='1.3.33'", 'state-version')

old = """function Run-SelfRelianceWatchdogOnce {
    $p=Join-Path $Workspace 'kevin-self-reliance-watchdog.ps1';if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'self-reliance watchdog missing'}
    $r=Invoke-FixedNativeBounded 'powershell.exe' @('-NoProfile','-NonInteractive','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',$p) 240;if($r.exit_code-ne0){throw 'self-reliance watchdog operational run failed'}
    $statePath=Join-Path $Reports 'self-reliance\\watchdog-state.json';if(-not(Test-Path -LiteralPath $statePath -PathType Leaf)){throw 'watchdog state missing after operational run'}"""
new = """function Run-SelfRelianceWatchdogOnce {
    $p=Join-Path $Workspace 'kevin-self-reliance-watchdog.ps1';if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'self-reliance watchdog missing'}
    $st=Invoke-FixedNativeBounded 'powershell.exe' @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$p,'-SelfTest') 120
    if($st.exit_code-ne0 -or [string]$st.output -notmatch 'implementation=v1\\.6\\.0' -or [string]$st.output -notmatch 'probe_no_intake=true' -or [string]$st.output -notmatch 'probe_no_restart=true'){throw 'installed watchdog does not prove ProbeOnly v1.6.0 contract'}
    $r=Invoke-FixedNativeBounded 'powershell.exe' @('-NoProfile','-NonInteractive','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',$p,'-ProbeOnly') 180;if($r.exit_code-ne0){throw 'self-reliance watchdog ProbeOnly run failed'}
    $statePath=Join-Path $Reports 'self-reliance\\watchdog-state.json';if(-not(Test-Path -LiteralPath $statePath -PathType Leaf)){throw 'watchdog state missing after ProbeOnly run'}"""
once(old, new, 'probe-only-invocation')

once(
    "    try{$w=Get-Content -LiteralPath $statePath -Raw|ConvertFrom-Json}catch{throw 'watchdog state invalid JSON'}\n    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology",
    "    try{$w=Get-Content -LiteralPath $statePath -Raw|ConvertFrom-Json}catch{throw 'watchdog state invalid JSON'}\n    if([string]$w.last_result -notmatch '^PROBE_ONLY_(?:HEALTHY|[A-Z0-9_]+)$'){throw 'watchdog ProbeOnly terminal state missing'}\n    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology",
    'probe-terminal-assert'
)
once(
    "state='OMEN_OPERATIONAL_PROOF';safe_for_public_repo=$true;watchdog_sha256=Get-Sha $p;last_result=[string]$w.last_result",
    "state='OMEN_CLASSIFIER_PROOF';safe_for_public_repo=$true;probe_mode='NO_SIDE_EFFECTS';watchdog_contract='v1.6.0';watchdog_sha256=Get-Sha $p;last_result=[string]$w.last_result",
    'public-proof-state'
)
once(
    "source_contract='One fixed watchdog run plus fixed metadata-only config/topology inspection. No caller-selected command, argv, path, token, or raw output.'",
    "source_contract='One fixed watchdog v1.6.0 ProbeOnly run plus fixed metadata-only config/topology inspection. ProbeOnly skips maintenance/work-order intake, console mutation, retries/cooldown changes, and Gateway restart. No caller-selected command, argv, path, token, or raw output.'",
    'source-contract'
)
once(
    "return [ordered]@{state='OMEN_OPERATIONAL_PROOF';receipt_sha256=$receipt;last_result=$public.last_result",
    "return [ordered]@{state='OMEN_CLASSIFIER_PROOF';probe_mode='NO_SIDE_EFFECTS';receipt_sha256=$receipt;last_result=$public.last_result",
    'return-state'
)

old_marker = "    Write-Host 'KEVIN MAINTENANCE v1.3.32 SELFTEST PASS gateway_listener_pid_collision=false native_npm_cli=true partial_install_rollback=true fixed_listener_identity_check=true rollback=true arbitrary_shell=false authority_expansion=false'"
new_marker = """    Write-Host 'KEVIN MAINTENANCE v1.3.32 SELFTEST PASS gateway_listener_pid_collision=false native_npm_cli=true partial_install_rollback=true fixed_listener_identity_check=true rollback=true arbitrary_shell=false authority_expansion=false'
    $wp=(Get-Command Run-SelfRelianceWatchdogOnce).ScriptBlock.ToString()
    if(-not $wp.Contains("'-ProbeOnly'")){throw 'watchdog ProbeOnly invocation missing'}
    if($wp -notmatch 'implementation=v1\\.6\\.0'){throw 'watchdog v1.6.0 contract gate missing'}
    if($wp -notmatch 'ProbeOnly run failed'){throw 'watchdog ProbeOnly terminal guard missing'}
    Write-Host 'KEVIN MAINTENANCE v1.3.33 SELFTEST PASS watchdog_probe=v1.6.0 probe_no_intake=true probe_no_restart=true classifier_proof=true native_npm_cli=true package_rollback=true arbitrary_shell=false authority_expansion=false'"""
once(old_marker, new_marker, 'selftest')

dst.write_text(s, encoding='utf-8', newline='\n')
print(dst)
