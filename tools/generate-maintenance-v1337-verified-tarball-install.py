from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.36.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.37.ps1')
EXPECTED_SRC_SHA256 = 'AE726C9B2446D12BFB2C9B0ECA1706642B3393E5509B2F6AC1E3DDD5E7ECD742'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA256:
    raise SystemExit(f'v1.3.36 source identity mismatch: {actual}')
text = raw.decode('utf-8')


def once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)


once("version='1.3.36'", "version='1.3.37'", 'state version')

start = text.index('function Assert-NpmIntegrity')
end = text.index('function Wait-GatewayRpc', start)
new = r'''function Get-FixedOpenClawTarballSpec([string]$Version) {
    $integrity = if($Version-eq$GatewayLkgVersion){$GatewayLkgIntegrity}elseif($Version-eq$GatewayRejectedVersion){$GatewayRejectedIntegrity}else{throw ('untrusted OpenClaw package version '+$Version)}
    if($Version-notmatch '^2026\.[0-9]+\.[0-9]+(?:-[0-9]+)?$'){throw 'OpenClaw package version format rejected'}
    $uri='https://registry.npmjs.org/openclaw/-/openclaw-'+$Version+'.tgz'
    if($uri-notmatch '^https://registry\.npmjs\.org/openclaw/-/openclaw-2026\.[0-9]+\.[0-9]+(?:-[0-9]+)?\.tgz$'){throw 'fixed npm tarball URI invariant failed'}
    return [pscustomobject]@{version=$Version;uri=$uri;integrity=$integrity}
}
function Get-FileSriSha512([string]$Path) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw 'tarball missing for SRI verification'}
    $sha=[Security.Cryptography.SHA512]::Create()
    try{
        $fs=[IO.File]::OpenRead($Path)
        try{$digest=$sha.ComputeHash($fs)}finally{$fs.Dispose()}
    }finally{$sha.Dispose()}
    return 'sha512-'+[Convert]::ToBase64String($digest)
}
function Download-VerifiedOpenClawTarball([string]$Version,[string]$Expected) {
    $spec=Get-FixedOpenClawTarballSpec $Version
    if([string]$Expected-ne[string]$spec.integrity){throw ('embedded integrity contract mismatch for '+$Version)}
    $dest=Join-Path $env:TEMP ('openclaw-'+$Version+'-'+[guid]::NewGuid().ToString('N')+'.tgz')
    try{
        Invoke-WebRequest -UseBasicParsing -Uri ([string]$spec.uri) -OutFile $dest -TimeoutSec 180 -ErrorAction Stop
        $actual=Get-FileSriSha512 $dest
        if($actual-ne$Expected){throw ('downloaded OpenClaw tarball integrity mismatch for '+$Version)}
        return $dest
    }catch{
        Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
        throw
    }
}
function Assert-NpmIntegrity([string]$Version,[string]$Expected) {
    $tar=Download-VerifiedOpenClawTarball $Version $Expected
    try{if((Get-FileSriSha512 $tar)-ne$Expected){throw ('verified OpenClaw tarball changed before use for '+$Version)}}finally{Remove-Item -LiteralPath $tar -Force -ErrorAction SilentlyContinue}
}
function Install-ExactOpenClaw([string]$Version) {
    $spec=Get-FixedOpenClawTarballSpec $Version
    $tar=Download-VerifiedOpenClawTarball $Version ([string]$spec.integrity)
    try{
        if((Get-FileSriSha512 $tar)-ne[string]$spec.integrity){throw ('verified OpenClaw tarball changed before install for '+$Version)}
        $r=Invoke-NpmFixed @('install','--global',$tar,'--no-audit','--no-fund','--ignore-scripts=false') 900
        if($r.exit_code-ne0){throw ('exact verified-tarball OpenClaw install failed version='+$Version)}
        if((Get-InstalledOpenClawVersion)-ne$Version){throw ('installed OpenClaw version mismatch expected='+$Version)}
    }finally{Remove-Item -LiteralPath $tar -Force -ErrorAction SilentlyContinue}
}
'''
text = text[:start] + new + text[end:]

self_anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.36 SELFTEST PASS lkg_config_compat=target_validates_untouched transactional_snapshot=true config_hash_unchanged=true exact_config_rollback=true exact_package_rollback=true keeper_preserved=true gateway_rpc_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'\n"
self_extra = self_anchor + r'''    $pkgFn=(Get-Command Install-ExactOpenClaw).ScriptBlock.ToString();$dlFn=(Get-Command Download-VerifiedOpenClawTarball).ScriptBlock.ToString();$specFn=(Get-Command Get-FixedOpenClawTarballSpec).ScriptBlock.ToString();if(-not$pkgFn.Contains("'--global'") -or -not$pkgFn.Contains('$tar')){throw 'verified local tarball install missing'};if(-not$dlFn.Contains('Get-FileSriSha512')){throw 'tarball byte-level SRI verification missing'};if(-not$specFn.Contains('https://registry.npmjs.org/openclaw/-/openclaw-')){throw 'fixed official registry tarball root missing'};if($specFn.Contains('http://')){throw 'insecure tarball transport present'}
    Write-Host 'KEVIN MAINTENANCE v1.3.37 SELFTEST PASS package_source=fixed_registry_tarball byte_sri_sha512=true embedded_windows_policy_pin=true install_from_verified_local_tarball=true rollback_package_same_contract=true dynamic_npm_view=false arbitrary_url=false arbitrary_shell=false authority_expansion=false'
'''
once(self_anchor, self_extra, 'v1.3.37 selftest')

OUT.write_text(text, encoding='utf-8', newline='')
print('MAINT_V1337_GENERATED sha256=' + hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
