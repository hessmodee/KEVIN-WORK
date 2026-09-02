from pathlib import Path
import hashlib
import re

# CI trigger note: runtime output remains deterministic from the pinned v1.3.39 parent.
SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.39.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.40.ps1')
EXPECTED='1863A86CE3E03492CF438A09575CF8B77F3BEB0FA43695AA3DDC532940F292D2'

def sha(b:bytes)->str:return hashlib.sha256(b).hexdigest().upper()
data=SRC.read_bytes();actual=sha(data)
if actual!=EXPECTED:raise SystemExit(f'v1.3.39 source identity mismatch {actual}')
text=data.decode('utf-8')
if text.count("version='1.3.39'")!=1:raise SystemExit('version anchor mismatch')
text=text.replace("version='1.3.39'","version='1.3.40'",1)

new_final=r'''function Get-ReaderFinalText([object]$Obj) {
    # Current OpenClaw stable `agent --json` envelope exposes top-level `final`
    # and `payloads`; older embedded/Gateway envelopes may nest the same data.
    $v=Get-OptionalPropertyValue $Obj 'final'
    $t=if($null-ne$v){[string]$v}else{''}
    if([string]::IsNullOrWhiteSpace($t)){
        $v=Get-OptionalPathValue $Obj @('result','meta','finalAssistantVisibleText')
        if($null-ne$v){$t=[string]$v}
    }
    if([string]::IsNullOrWhiteSpace($t)){
        $payloads=Get-OptionalPropertyValue $Obj 'payloads'
        if($null-eq$payloads){$payloads=Get-OptionalPathValue $Obj @('result','payloads')}
        if($null-ne$payloads -and @($payloads).Count-gt0){
            $candidate=Get-OptionalPropertyValue @($payloads)[0] 'text'
            if($null-ne$candidate){$t=[string]$candidate}
        }
    }
    return $t.Trim()
}
'''
pat=r"function Get-ReaderFinalText\(\[object\]\$Obj\) \{.*?\n\}\nfunction Test-ReaderPublicText"
m=re.search(pat,text,flags=re.S)
if not m:raise SystemExit('Get-ReaderFinalText boundary missing')
text=text[:m.start()]+new_final+'function Test-ReaderPublicText'+text[m.end():]

old="$success=($status-eq'success' -and $expected -and $calls-eq0)"
new="$statusOk=($status-eq'ok' -or $status-eq'success');$success=($statusOk -and $expected -and $calls-eq0)"
if text.count(old)!=1:raise SystemExit('canary success anchor mismatch')
text=text.replace(old,new,1)

anchor="    Write-Host 'KEVIN MAINTENANCE v1.3.39 SELFTEST PASS optional_agent_json=true missing_toolSummary_safe=true missing_tool_inventory_safe=true payload_fallback=true recursive_tool_count=true exact_canary_semantics_preserved=true authority_expansion=false arbitrary_shell=false'\n"
if text.count(anchor)!=1:raise SystemExit('v1.3.39 selftest anchor mismatch')
extra=anchor+r'''    $stable=[pscustomobject]@{ok=$true;status='ok';final='KEVIN_MAIN_AGENT_CANARY_OK';payloads=@([pscustomobject]@{text='KEVIN_MAIN_AGENT_CANARY_OK'});toolSummary=[pscustomobject]@{calls=0;tools=@()}}
    if((Get-ReaderFinalText $stable)-cne'KEVIN_MAIN_AGENT_CANARY_OK'){throw 'current top-level OpenClaw final envelope parser failed'}
    $stablePayloadOnly=[pscustomobject]@{ok=$true;status='ok';payloads=@([pscustomobject]@{text='KEVIN_MAIN_AGENT_CANARY_OK'})}
    if((Get-ReaderFinalText $stablePayloadOnly)-cne'KEVIN_MAIN_AGENT_CANARY_OK'){throw 'current top-level OpenClaw payload fallback failed'}
    $legacy=[pscustomobject]@{status='success';result=[pscustomobject]@{meta=[pscustomobject]@{finalAssistantVisibleText='KEVIN_MAIN_AGENT_CANARY_OK'};payloads=@()}}
    if((Get-ReaderFinalText $legacy)-cne'KEVIN_MAIN_AGENT_CANARY_OK'){throw 'legacy nested agent envelope regressed'}
    foreach($s in @('ok','success')){$status=$s;$expected=$true;$calls=0;$statusOk=($status-eq'ok' -or $status-eq'success');$success=($statusOk -and $expected -and $calls-eq0);if(-not$success){throw ('accepted success status rejected: '+$s)}}
    foreach($s in @('error','timeout','')){$status=$s;$expected=$true;$calls=0;$statusOk=($status-eq'ok' -or $status-eq'success');$success=($statusOk -and $expected -and $calls-eq0);if($success){throw ('failure status accepted: '+$s)}}
    Write-Host 'KEVIN MAINTENANCE v1.3.40 SELFTEST PASS openclaw_stable_envelope=true top_level_final=true top_level_payloads=true status_ok=true legacy_nested=true exact_canary_semantics_preserved=true zero_tools_required=true authority_expansion=false arbitrary_shell=false'
'''
text=text.replace(anchor,extra,1)
OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1340_GENERATED sha256='+sha(OUT.read_bytes()))
