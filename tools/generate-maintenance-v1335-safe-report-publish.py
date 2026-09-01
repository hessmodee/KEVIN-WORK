from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.34.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.35.ps1')
EXPECTED_SRC_SHA256 = '48B066C7C632B0551897A239528B026A6D75BA02F549B25601858923925B0D4F'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA256:
    raise SystemExit(f'v1.3.34 source identity mismatch: {actual}')
text = raw.decode('utf-8')


def once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)


once("version='1.3.34'", "version='1.3.35'", 'state version')

start = text.index('function Publish-SafeFixedReport(')
end = text.index('function Run-SelfRelianceWatchdogOnce', start)
old = text[start:end]
new = r'''function Publish-SafeFixedReport([string]$RepoPath,[string]$LocalName,[object]$Public,[string]$Message) {
    $local=Join-Path $Reports $LocalName;Write-JsonAtomic $local $Public
    $localHash=Get-Sha $local
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.sha')
        $body=[ordered]@{message=$Message;content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))}
        if($lookup.ExitCode-eq0 -and $lookup.Output){
            $body.sha=[string]$lookup.Output
        }elseif($lookup.ExitCode-ne0 -and [string]$lookup.Output -notmatch '404|Not Found'){
            if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt);continue}
            throw 'safe report lookup bounded retries exhausted'
        }
        $tmp=Join-Path $env:TEMP ('kevin-safe-report-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$RepoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode-ne0){if($attempt-lt3){Start-Sleep -Milliseconds (500*$attempt);continue};throw 'safe report publish bounded retries exhausted'}
        Start-Sleep -Milliseconds 600
        $get=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$RepoPath),'--jq','.content')
        if($get.ExitCode-eq0 -and $get.Output){
            try{
                $remote=[Convert]::FromBase64String(([string]$get.Output-replace'\s',''))
                $sha=[Security.Cryptography.SHA256]::Create()
                try{$remoteHash=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()}
                if($remoteHash-eq$localHash){return $localHash}
            }catch{}
        }
        if($attempt-lt3){Start-Sleep -Milliseconds (500*$attempt)}
    }
    throw 'safe report remote verification bounded retries exhausted'
}
'''
text = text[:start] + new + text[end:]

self_anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.34 SELFTEST PASS continuation_cli=cron_alias runtime_compatible=true maintenance_backoff_reset=enabled_patch no_recursive_run=true fixed_job_identity=true benchmark_postcondition=true arbitrary_shell=false authority_expansion=false'\n"
self_extra = self_anchor + r'''    $pubFn=(Get-Command Publish-SafeFixedReport).ScriptBlock.ToString();if($pubFn -notmatch 'attempt=1;\$attempt-le3'){throw 'safe report bounded retry loop missing'};if(-not$pubFn.Contains("--jq','.content")){throw 'safe report remote verification fetch missing'};if(-not$pubFn.Contains('remoteHash-eq$localHash')){throw 'safe report hash verification missing'};if($pubFn -match '(?i)invoke-expression|kevin_shell|cmd\.exe'){throw 'safe report publisher widened authority'}
    Write-Host 'KEVIN MAINTENANCE v1.3.35 SELFTEST PASS safe_report_publish=bounded3 create_update_race=true remote_hash_verify=true continuation_cli=cron_alias backoff_reset=true arbitrary_shell=false authority_expansion=false'
'''
once(self_anchor, self_extra, 'v1.3.35 selftest')

OUT.write_text(text, encoding='utf-8', newline='')
print('MAINT_V1335_GENERATED sha256=' + hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
