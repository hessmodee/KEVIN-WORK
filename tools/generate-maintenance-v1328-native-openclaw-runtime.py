from pathlib import Path
import hashlib

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.27.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.28.ps1')
EXPECTED='B22A26EA5B417F0514BE253E1F45F93407BD5B8EDC2A92482D9518FB058B83AA'
raw=SRC.read_bytes(); actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED: raise SystemExit(f'v1.3.27 identity mismatch {actual}')
text=raw.decode('utf-8')

def once(old,new,label):
    global text
    n=text.count(old)
    if n!=1: raise SystemExit(f'{label} anchor count={n}')
    text=text.replace(old,new,1)

once("version='1.3.27'","version='1.3.28'",'state version')
old=r'''function Invoke-OpenClawFixedConfig([string[]]$Args) {
    $cmd=Get-Command openclaw -ErrorAction SilentlyContinue
    if(-not$cmd){throw 'OpenClaw CLI unavailable'}
    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$out=(& $cmd.Source @Args 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    return [pscustomobject]@{exit_code=$code;output=[string]$out}
}'''
new=r'''function ConvertTo-FixedWin32Arg([AllowEmptyString()][string]$Value) {
    if($null-eq$Value -or $Value.Length-eq0){return '""'}
    if($Value -notmatch '[\s"]'){return $Value}
    $sb=New-Object Text.StringBuilder;[void]$sb.Append('"');$slashes=0
    for($i=0;$i-lt$Value.Length;$i++){
        $ch=$Value[$i]
        if($ch-eq'\'){$slashes++;continue}
        if($ch-eq'"'){
            if($slashes-gt0){[void]$sb.Append(('\'*($slashes*2)))}
            [void]$sb.Append('\"');$slashes=0;continue
        }
        if($slashes-gt0){[void]$sb.Append(('\'*$slashes));$slashes=0}
        [void]$sb.Append($ch)
    }
    if($slashes-gt0){[void]$sb.Append(('\'*($slashes*2)))}
    [void]$sb.Append('"');return $sb.ToString()
}
function Get-FixedOpenClawRuntime {
    $node=Get-Command node.exe -ErrorAction SilentlyContinue
    if(-not$node){$node=Get-Command node -ErrorAction SilentlyContinue}
    if(-not$node){throw 'node runtime unavailable'}
    if(-not$env:APPDATA){throw 'APPDATA unavailable'}
    $cli=Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if(-not(Test-Path -LiteralPath $cli -PathType Leaf)){throw 'OpenClaw native runtime unavailable'}
    return [pscustomobject]@{node=[string]$node.Source;cli=$cli}
}
function Invoke-FixedNativeBounded([string]$Executable,[string[]]$Argv,[int]$TimeoutSeconds=180) {
    $psi=New-Object Diagnostics.ProcessStartInfo
    $psi.FileName=$Executable
    $psi.Arguments=(($Argv|ForEach-Object{ConvertTo-FixedWin32Arg ([string]$_)})-join' ')
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $p=New-Object Diagnostics.Process;$p.StartInfo=$psi
    if(-not$p.Start()){throw 'fixed native process start failed'}
    $ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();$timed=$false
    if(-not$p.WaitForExit($TimeoutSeconds*1000)){$timed=$true;try{$p.Kill()}catch{};$p.WaitForExit()}
    $stdout=[string]$ot.Result;$stderr=[string]$et.Result;$code=if($timed){124}else{[int]$p.ExitCode}
    $p.Dispose()
    $out=(($stdout+$(if($stdout-and$stderr){"`n"}else{''})+$stderr)).Trim()
    return [pscustomobject]@{exit_code=$code;output=$out;timed_out=$timed}
}
function Invoke-OpenClawFixedConfig([string[]]$Args) {
    $r=Get-FixedOpenClawRuntime
    return Invoke-FixedNativeBounded $r.node (@($r.cli)+@($Args)) 180
}'''
once(old,new,'native OpenClaw wrapper')
marker="    Write-Host 'KEVIN MAINTENANCE v1.3.27 SELFTEST PASS gateway_direct_rpc=true gateway_diagnosis=metadata-only watchdog_inspection=fixed fixed_main_canary=true arbitrary_shell=false authority_expansion=false'"
extra=marker+"\n    $fn=(Get-Command Invoke-OpenClawFixedConfig).ScriptBlock.ToString();if($fn -match '(?i)Get-Command\\s+openclaw'){throw 'OpenClaw shim resolution still present in fixed wrapper'}\n    if(-not$fn.Contains('Get-FixedOpenClawRuntime')){throw 'native OpenClaw runtime wrapper missing'}\n    Write-Host 'KEVIN MAINTENANCE v1.3.28 SELFTEST PASS openclaw_native_node=true shell_shim_bypassed=true native_timeout=180s gateway_direct_rpc=true fixed_main_canary=true arbitrary_shell=false authority_expansion=false'"
once(marker,extra,'selftest extension')
OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1328_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
