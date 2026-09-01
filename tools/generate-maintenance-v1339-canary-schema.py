from pathlib import Path
import hashlib
import re

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.38.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.39.ps1')
EXPECTED='0AD0A05E3F9DB4F1ED3C07B898B635A28915290D58762D11B63D07751B8B9153'

def sha(b:bytes)->str:return hashlib.sha256(b).hexdigest().upper()
data=SRC.read_bytes();actual=sha(data)
if actual!=EXPECTED:raise SystemExit(f'v1.3.38 source identity mismatch {actual}')
text=data.decode('utf-8')
if text.count("version='1.3.38'")!=1:raise SystemExit('version anchor mismatch')
text=text.replace("version='1.3.38'","version='1.3.39'",1)

helpers=r'''function Get-OptionalPropertyValue([object]$Obj,[string]$Name) {
    if($null-eq$Obj){return $null}
    if($Obj-is[Collections.IDictionary]){if($Obj.Contains($Name)){return $Obj[$Name]};return $null}
    $p=$Obj.PSObject.Properties[$Name]
    if($null-ne$p){return $p.Value}
    return $null
}
function Get-OptionalPathValue([object]$Obj,[string[]]$Path) {
    $cur=$Obj
    foreach($name in $Path){$cur=Get-OptionalPropertyValue $cur $name;if($null-eq$cur){return $null}}
    return $cur
}
function Get-ReaderVisibleToolNames([object]$Obj) {
    $entries=Get-OptionalPathValue $Obj @('result','meta','systemPromptReport','tools','entries')
    if($null-eq$entries){return @()}
    $names=@()
    foreach($e in @($entries)){
        if($null-eq$e){continue}
        if($e-is[string]){$names+=[string]$e;continue}
        $n=Get-OptionalPropertyValue $e 'name'
        if($null-ne$n -and -not[string]::IsNullOrWhiteSpace([string]$n)){$names+=[string]$n}
    }
    return @($names)
}
function Get-ReaderFinalText([object]$Obj) {
    $v=Get-OptionalPathValue $Obj @('result','meta','finalAssistantVisibleText')
    $t=if($null-ne$v){[string]$v}else{''}
    if([string]::IsNullOrWhiteSpace($t)){
        $payloads=Get-OptionalPathValue $Obj @('result','payloads')
        if($null-ne$payloads -and @($payloads).Count-gt0){
            $candidate=Get-OptionalPropertyValue @($payloads)[0] 'text'
            if($null-ne$candidate){$t=[string]$candidate}
        }
    }
    return $t.Trim()
}
'''
start=text.find('function Get-ReaderVisibleToolNames')
end=text.find('function Test-ReaderPublicText',start)
if start<0 or end<0:raise SystemExit('reader helper boundary missing')
text=text[:start]+helpers+text[end:]

calls=r'''function Get-ReaderToolCalls([object]$Obj) {
    $summary=Get-OptionalPathValue $Obj @('result','meta','toolSummary')
    if($null-ne$summary){
        $calls=Get-OptionalPropertyValue $summary 'calls'
        if($null-ne$calls){try{return [int]$calls}catch{}}
    }
    $script:KevinOptionalToolCallCount=0
    function Visit-KevinOptionalToolNode([object]$Node) {
        if($null-eq$Node){return}
        if($Node-is[Collections.IDictionary]){
            foreach($key in @($Node.Keys)){
                $value=$Node[$key]
                if([string]$key-match'(?i)^(toolCalls|tool_calls|toolUse|tool_use)$'){
                    if($value-is[Collections.IEnumerable]-and-not($value-is[string])){$script:KevinOptionalToolCallCount+=@($value).Count}elseif($null-ne$value){$script:KevinOptionalToolCallCount++}
                }
                Visit-KevinOptionalToolNode $value
            }
            return
        }
        if($Node-is[Collections.IEnumerable]-and-not($Node-is[string])){foreach($value in $Node){Visit-KevinOptionalToolNode $value};return}
        foreach($property in @($Node.PSObject.Properties)){
            $value=$property.Value
            if($property.Name-match'(?i)^(toolCalls|tool_calls|toolUse|tool_use)$'){
                if($value-is[Collections.IEnumerable]-and-not($value-is[string])){$script:KevinOptionalToolCallCount+=@($value).Count}elseif($null-ne$value){$script:KevinOptionalToolCallCount++}
            }
            Visit-KevinOptionalToolNode $value
        }
    }
    Visit-KevinOptionalToolNode $Obj
    return [int]$script:KevinOptionalToolCallCount
}
'''
start=text.find('function Get-ReaderToolCalls')
end=text.find('function Run-OneReaderTrial',start)
if start<0 or end<0:raise SystemExit('tool-call helper boundary missing')
text=text[:start]+calls+text[end:]

old="$status=[string]$o.status;$finalText=Get-ReaderFinalText $o;$calls=Get-ReaderToolCalls $o;$tools=@(Get-ReaderVisibleToolNames $o|Sort-Object -Unique)"
new="$statusValue=Get-OptionalPropertyValue $o 'status';if($null-eq$statusValue){$statusValue=Get-OptionalPathValue $o @('result','status')};$status=[string]$statusValue;$finalText=Get-ReaderFinalText $o;$calls=Get-ReaderToolCalls $o;$tools=@(Get-ReaderVisibleToolNames $o|Sort-Object -Unique)"
if text.count(old)!=1:raise SystemExit('canary status anchor mismatch')
text=text.replace(old,new,1)

anchor="    Write-Host 'KEVIN MAINTENANCE v1.3.38 SELFTEST PASS convergence=true explicit_command_arguments=true win32_argv_preserved=true four_independent_readonly_probes=true false_downgrade_prevented=true package_source=fixed_registry_tarball byte_sri_sha512=true supervisor_target=v1.8.5 authority_expansion=false arbitrary_shell=false'\n"
if text.count(anchor)!=1:raise SystemExit('v1.3.38 selftest anchor mismatch')
extra=anchor+r'''    $fixtureNoTools=[pscustomobject]@{status='success';result=[pscustomobject]@{meta=[pscustomobject]@{finalAssistantVisibleText='KEVIN_MAIN_AGENT_CANARY_OK'};payloads=@()}}
    if((Get-ReaderToolCalls $fixtureNoTools)-ne0){throw 'missing toolSummary must mean zero observed calls, not parser failure'}
    if(@(Get-ReaderVisibleToolNames $fixtureNoTools).Count-ne0){throw 'missing tool inventory must return empty list'}
    if((Get-ReaderFinalText $fixtureNoTools)-ne'KEVIN_MAIN_AGENT_CANARY_OK'){throw 'direct final text parser failed'}
    $fixturePayload=[pscustomobject]@{status='success';result=[pscustomobject]@{meta=[pscustomobject]@{};payloads=@([pscustomobject]@{text='KEVIN_MAIN_AGENT_CANARY_OK'})}}
    if((Get-ReaderFinalText $fixturePayload)-ne'KEVIN_MAIN_AGENT_CANARY_OK'){throw 'payload fallback parser failed'}
    $fixtureCalls=[pscustomobject]@{status='success';result=[pscustomobject]@{meta=[pscustomobject]@{};payloads=@();toolCalls=@([pscustomobject]@{name='fixture'})}}
    if((Get-ReaderToolCalls $fixtureCalls)-ne1){throw 'recursive tool-call fallback failed'}
    Write-Host 'KEVIN MAINTENANCE v1.3.39 SELFTEST PASS optional_agent_json=true missing_toolSummary_safe=true missing_tool_inventory_safe=true payload_fallback=true recursive_tool_count=true exact_canary_semantics_preserved=true authority_expansion=false arbitrary_shell=false'
'''
text=text.replace(anchor,extra,1)
OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1339_GENERATED sha256='+sha(OUT.read_bytes()))
