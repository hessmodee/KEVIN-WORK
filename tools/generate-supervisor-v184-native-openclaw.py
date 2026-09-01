from pathlib import Path

src = Path('control-plane/autonomy/kevin-supervisor-v1.8.3.ps1')
dst = Path('control-plane/autonomy/kevin-supervisor-v1.8.4.ps1')
text = src.read_bytes().decode('utf-8')
nl = '\r\n' if '\r\n' in text else '\n'

old_header = '# Kevin Supervisor v1.8.3 Governed Autonomy Continuation Controller'
new_header = '# Kevin Supervisor v1.8.4 Governed Autonomy Continuation Controller - Native OpenClaw Runtime'
if text.count(old_header) != 1:
    raise SystemExit('unexpected v1.8.3 header count')
text = text.replace(old_header, new_header, 1)
if text.count("version = '1.8.3'") != 1:
    raise SystemExit('unexpected version marker count')
text = text.replace("version = '1.8.3'", "version = '1.8.4'", 1)

start_marker = 'function Invoke-OpenClaw([string[]]$Args) {'
end_marker = 'function Get-PythonExe'
start = text.find(start_marker)
end = text.find(end_marker, start)
if start < 0 or end <= start:
    raise SystemExit('unable to isolate v1.8.3 OpenClaw wrapper')

block = r'''function ConvertTo-Win32CommandLineArg([AllowEmptyString()][string]$Value) {
    if ($null -eq $Value -or $Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $sb = New-Object Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0
    for ($i = 0; $i -lt $Value.Length; $i++) {
        $ch = $Value[$i]
        if ($ch -eq '\') { $slashes++; continue }
        if ($ch -eq '"') {
            if ($slashes -gt 0) { [void]$sb.Append(('\' * ($slashes * 2))) }
            [void]$sb.Append('\"')
            $slashes = 0
            continue
        }
        if ($slashes -gt 0) { [void]$sb.Append(('\' * $slashes)); $slashes = 0 }
        [void]$sb.Append($ch)
    }
    if ($slashes -gt 0) { [void]$sb.Append(('\' * ($slashes * 2))) }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function Invoke-FixedNativeBounded([string]$Executable, [string[]]$Argv, [int]$TimeoutSeconds) {
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $Executable
    $psi.Arguments = (($Argv | ForEach-Object { ConvertTo-Win32CommandLineArg ([string]$_) }) -join ' ')
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = New-Object Diagnostics.Process
    $p.StartInfo = $psi
    if (-not $p.Start()) { throw 'fixed native process start failed' }
    $ot = $p.StandardOutput.ReadToEndAsync()
    $et = $p.StandardError.ReadToEndAsync()
    $timed = $false
    if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
        $timed = $true
        try { $p.Kill() } catch {}
        $p.WaitForExit()
    }
    $stdout = [string]$ot.Result
    $stderr = [string]$et.Result
    $code = if ($timed) { 124 } else { [int]$p.ExitCode }
    $p.Dispose()
    $combined = (($stdout + "`n" + $stderr).Trim())
    return [pscustomobject]@{ exit_code = $code; output = [string]$combined; timed_out = $timed }
}

function Get-FixedOpenClawRuntime {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command node -ErrorAction SilentlyContinue }
    if (-not $node) { throw 'node runtime unavailable' }
    if (-not $env:APPDATA) { throw 'APPDATA unavailable' }
    $cli = Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { throw 'OpenClaw native runtime unavailable' }
    return [pscustomobject]@{ node = $node.Source; cli = $cli }
}

function Invoke-OpenClaw([string[]]$Args) {
    $oldConfig = [Environment]::GetEnvironmentVariable('OPENCLAW_CONFIG_PATH', 'Process')
    $oldRoot = [Environment]::GetEnvironmentVariable('OPENCLAW_HOME', 'Process')
    try {
        Remove-Item Env:OPENCLAW_CONFIG_PATH -ErrorAction SilentlyContinue
        Remove-Item Env:OPENCLAW_HOME -ErrorAction SilentlyContinue
        $r = Get-FixedOpenClawRuntime
        return Invoke-FixedNativeBounded $r.node (@($r.cli) + @($Args)) 180
    }
    finally {
        if ($null -ne $oldConfig) { $env:OPENCLAW_CONFIG_PATH = $oldConfig } else { Remove-Item Env:OPENCLAW_CONFIG_PATH -ErrorAction SilentlyContinue }
        if ($null -ne $oldRoot) { $env:OPENCLAW_HOME = $oldRoot } else { Remove-Item Env:OPENCLAW_HOME -ErrorAction SilentlyContinue }
    }
}

'''.replace('\n', nl)
text = text[:start] + block + text[end:]

old_self = "Write-Host 'KEVIN SUPERVISOR v1.8.3 SELFTEST PASS selector_first=true gateway_agent=fixed-main gateway_rpc_only=true gateway_probe_retries=3 main_preflight=true no_forge_dispatch=true anti_spin=true arbitrary_shell=false authority_expansion=false'"
new_self = "Write-Host 'KEVIN SUPERVISOR v1.8.4 SELFTEST PASS selector_first=true gateway_agent=fixed-main gateway_rpc_only=true gateway_probe_retries=3 main_preflight=true no_forge_dispatch=true anti_spin=true openclaw_native_node=true shell_shim_bypassed=true native_timeout=180s arbitrary_shell=false authority_expansion=false'"
if text.count(old_self) != 1:
    raise SystemExit('unexpected selftest marker count')
text = text.replace(old_self, new_self, 1)

if 'Get-Command openclaw' in text:
    raise SystemExit('PowerShell OpenClaw shim remains')
if text.count('Get-FixedOpenClawRuntime') < 2:
    raise SystemExit('native runtime resolver not wired')
if text.count("@('agent', '--agent', 'main'") != 1:
    raise SystemExit('fixed-main agent invocation changed')

dst.write_bytes(text.encode('utf-8'))
print(f'SUPERVISOR_V184_GENERATED bytes={dst.stat().st_size}')
