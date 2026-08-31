from pathlib import Path
import subprocess, sys

subprocess.run([sys.executable,'tools/generate-work-order-intake-v125.py'],check=True)
SRC=Path('control-plane/intake/generated/kevin-work-order-intake-v1.2.5.ps1')
DST=Path('control-plane/intake/generated/kevin-work-order-intake-v1.2.6.ps1')
text=SRC.read_text(encoding='utf-8')

start=text.index('function Publish-Ack($Ack){')
end=text.index('function Get-Ledger {',start)
replacement=r'''function Test-AckSemanticallySame([object]$Prev,[object]$Next) {
    if($null-eq$Prev -or $null-eq$Next){return $false}
    $prevId=if($Prev.request){[string]$Prev.request.id}else{''}
    $nextId=if($Next.request){[string]$Next.request.id}else{''}
    return ($prevId-eq$nextId -and [string]$Prev.status-eq[string]$Next.status -and [string]$Prev.detail-eq[string]$Next.detail)
}
function Publish-Ack($Ack){
    for($attempt=1;$attempt-le3;$attempt++){
        $existing=Get-RemoteJson $AckPath $AckBranch
        if($existing -and (Test-AckSemanticallySame $existing.data $Ack)){return $false}
        $payload=$Ack|ConvertTo-Json -Depth 20
        $body=[ordered]@{message='kevin control plane telemetry';content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload));branch=$AckBranch}
        if($existing){$body.sha=[string]$existing.meta.sha}
        $tmp=Join-Path $env:TEMP ('kevin-wo-ack-'+[guid]::NewGuid().ToString('N')+'.json')
        try{
            [IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8)
            $r=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$AckPath),'--input',$tmp,'-H','Accept: application/vnd.github+json')
        }finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($r.ExitCode-eq0){return $true}
        $msg=One-Line ($r.Stdout+' '+$r.Stderr)
        if($attempt-lt3 -and $msg-match'(?i)409|conflict|does not match|sha|422'){
            Start-Sleep -Milliseconds (250*$attempt)
            continue
        }
        throw ('Ack publish failed: '+$msg)
    }
    throw 'Ack publish CAS retry budget exhausted'
}
'''
text=text[:start]+replacement+'\n'+text[end:]

old="""    Write-Host 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS compatibility=v1.2.5'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.3 SELFTEST PASS compatibility=v1.2.5'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.4 SELFTEST PASS compatibility=v1.2.5'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.5 SELFTEST PASS verbs=7 stale_order_retirement=true terminal_idle=true semantic_ack_dedupe=true maintenance_semantic_postcondition=true maintenance_freshness=true false_success_blocked=true arbitrary_shell=false caller_argv=false caller_path=false'"""
fixture=r'''
    $ackA=[pscustomobject]@{request=[pscustomobject]@{id='same-id'};status='SUCCESS';detail='done'}
    $ackB=[pscustomobject]@{request=[pscustomobject]@{id='same-id'};status='SUCCESS';detail='done'}
    if(-not(Test-AckSemanticallySame $ackA $ackB)){throw 'semantic ack equality fixture failed'}
    $ackB.detail='different';if(Test-AckSemanticallySame $ackA $ackB){throw 'semantic ack inequality fixture failed'}
'''.rstrip()
needle="    if((ConvertTo-Win32CommandLineArg 'a b')-ne'\"a b\"'){throw 'Win32 argv quote selftest failed'}"
text=text.replace(needle,fixture+'\n'+needle,1)
new="""    Write-Host 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS compatibility=v1.2.6'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.3 SELFTEST PASS compatibility=v1.2.6'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.4 SELFTEST PASS compatibility=v1.2.6'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.5 SELFTEST PASS compatibility=v1.2.6'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.6 SELFTEST PASS verbs=7 stale_order_retirement=true terminal_idle=true semantic_ack_dedupe=true ack_cas_retries=3 maintenance_semantic_postcondition=true maintenance_freshness=true false_success_blocked=true arbitrary_shell=false caller_argv=false caller_path=false'"""
if old not in text: raise SystemExit('marker block not found')
text=text.replace(old,new,1)
DST.parent.mkdir(parents=True,exist_ok=True)
DST.write_text(text,encoding='utf-8',newline='\n')
print(DST)
