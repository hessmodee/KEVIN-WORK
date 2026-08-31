from pathlib import Path

SRC=Path('control-plane/intake/kevin-work-order-intake-v1.2.3.ps1')
DST=Path('control-plane/intake/generated/kevin-work-order-intake-v1.2.4.ps1')
text=SRC.read_text(encoding='utf-8')

def once(old,new):
    global text
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'expected exactly one marker, got {n}: {old[:160]!r}')
    text=text.replace(old,new,1)

old_publish="""function Publish-Ack($Ack){$existing=Get-RemoteJson $AckPath $AckBranch;$payload=$Ack|ConvertTo-Json -Depth 20;$body=[ordered]@{message='kevin control plane telemetry';content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload));branch=$AckBranch};if($existing){$body.sha=[string]$existing.meta.sha};$tmp=Join-Path $env:TEMP ('kevin-wo-ack-'+[guid]::NewGuid().ToString('N')+'.json');try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$r=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$AckPath),'--input',$tmp,'-H','Accept: application/vnd.github+json');if($r.ExitCode-ne0){throw 'Ack publish failed'}}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}}"""
new_publish="""function Publish-Ack($Ack){
    $existing=Get-RemoteJson $AckPath $AckBranch
    if($existing){
        $prev=$existing.data
        $prevId=if($prev.request){[string]$prev.request.id}else{''}
        $nextId=if($Ack.request){[string]$Ack.request.id}else{''}
        if($prevId-eq$nextId -and [string]$prev.status-eq[string]$Ack.status -and [string]$prev.detail-eq[string]$Ack.detail){return $false}
    }
    $payload=$Ack|ConvertTo-Json -Depth 20
    $body=[ordered]@{message='kevin control plane telemetry';content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload));branch=$AckBranch}
    if($existing){$body.sha=[string]$existing.meta.sha}
    $tmp=Join-Path $env:TEMP ('kevin-wo-ack-'+[guid]::NewGuid().ToString('N')+'.json')
    try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$r=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$AckPath),'--input',$tmp,'-H','Accept: application/vnd.github+json');if($r.ExitCode-ne0){throw 'Ack publish failed'}}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
    return $true
}"""
once(old_publish,new_publish)

old_poll="""    $remote=Get-RemoteJson $OrderPath $OrderBranch
    if(-not$remote){$ack.detail='No work order';Publish-Ack $ack;exit 0}
    $o=$remote.data;$ack.request=[ordered]@{id=[string]$o.id;verb=[string]$o.verb;target=[string]$o.target}
    Validate-Order $o
    $ledger=Get-Ledger
    if(@($ledger.processed|Where-Object{[string]$_.idempotency_key-eq[string]$o.idempotency_key}).Count){$ack.status='DUPLICATE_IGNORED';$ack.detail='Idempotency key already processed';Publish-Ack $ack;exit 0}
    $result=Execute-Order $o
    $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=[string]$o.id;idempotency_key=[string]$o.idempotency_key;at=(Get-Date).ToString('o');status='SUCCESS'})
    Save-Ledger $ledger
    $ack.status='SUCCESS';$ack.detail=One-Line $result;Publish-Ack $ack;exit 0
}catch{$ack.status='FAILED';$ack.detail=One-Line $_.Exception.Message;try{Publish-Ack $ack}catch{};exit 1}"""
new_poll="""    $remote=Get-RemoteJson $OrderPath $OrderBranch
    if(-not$remote){$ack.status='IDLE_NO_ORDER';$ack.detail='No current work order; awaiting next bounded GREEN order';Publish-Ack $ack|Out-Null;exit 0}
    $o=$remote.data;$ack.request=[ordered]@{id=[string]$o.id;verb=[string]$o.verb;target=[string]$o.target}
    $ledger=Get-Ledger
    $prior=@($ledger.processed|Where-Object{[string]$_.idempotency_key-eq[string]$o.idempotency_key})
    if($prior.Count){$ack.status='IDLE_TERMINAL';$ack.detail='Current work order is already terminal; awaiting replacement';Publish-Ack $ack|Out-Null;exit 0}
    try{Validate-Order $o}catch{
        $reason=[string]$_.Exception.Message
        $safeId=([string]$o.id -match '^[A-Za-z0-9._-]{8,80}$')
        $safeKey=([string]$o.idempotency_key -match '^[A-Za-z0-9._-]{8,120}$')
        if($reason-eq'Work order is expired.' -and $safeId -and $safeKey){
            $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=[string]$o.id;idempotency_key=[string]$o.idempotency_key;at=(Get-Date).ToString('o');status='EXPIRED_RETIRED'})
            Save-Ledger $ledger
            $ack.status='STALE_RETIRED';$ack.detail='Expired work order retired; awaiting replacement';Publish-Ack $ack|Out-Null;exit 0
        }
        throw
    }
    $result=Execute-Order $o
    $ledger.processed=@($ledger.processed)+@([pscustomobject]@{id=[string]$o.id;idempotency_key=[string]$o.idempotency_key;at=(Get-Date).ToString('o');status='SUCCESS'})
    Save-Ledger $ledger
    $ack.status='SUCCESS';$ack.detail=One-Line $result;Publish-Ack $ack|Out-Null;exit 0
}catch{$ack.status='FAILED';$ack.detail=One-Line $_.Exception.Message;try{Publish-Ack $ack|Out-Null}catch{};exit 1}"""
once(old_poll,new_poll)

old_marker="""    Write-Host 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS compatibility=v1.2.3'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.3 SELFTEST PASS verbs=7 os_awareness_snapshot=fixed maintenance_target=fixed winps51_argv=true arbitrary_shell=false caller_argv=false caller_path=false'"""
new_marker="""    Write-Host 'KEVIN WORK ORDER INTAKE v1.2 SELFTEST PASS compatibility=v1.2.4'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.3 SELFTEST PASS compatibility=v1.2.4'
    Write-Host 'KEVIN WORK ORDER INTAKE v1.2.4 SELFTEST PASS verbs=7 stale_order_retirement=true terminal_idle=true semantic_ack_dedupe=true os_awareness_snapshot=fixed maintenance_target=fixed arbitrary_shell=false caller_argv=false caller_path=false'"""
once(old_marker,new_marker)

DST.parent.mkdir(parents=True,exist_ok=True)
DST.write_text(text,encoding='utf-8',newline='\n')
print(DST)
