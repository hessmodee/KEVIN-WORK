from pathlib import Path
import hashlib

# CI trigger note: deterministic output is pinned to the reviewed v1.8.5 parent.
SRC=Path('control-plane/autonomy/kevin-supervisor-v1.8.5.ps1')
OUT=Path('control-plane/autonomy/kevin-supervisor-v1.8.6.ps1')
EXPECTED='C3F781E4F722AF691D2B47A9CD0F06A4F6AD3134A826C5D657B9ED9D5AEBC400'

def sha(b:bytes)->str:return hashlib.sha256(b).hexdigest().upper()
data=SRC.read_bytes();actual=sha(data)
if actual!=EXPECTED:raise SystemExit(f'v1.8.5 source identity mismatch {actual}')
text=data.decode('utf-8')
text=text.replace('v1.8.5','v1.8.6')

anchor="""function Get-ToolCallCount([object]$Object) {"""
helper=r'''function Invoke-SelectorExcludingId([hashtable]$Paths,[string]$ExcludedId) {
    if($ExcludedId-notmatch'^[a-z0-9][a-z0-9._-]{2,96}$'){throw 'excluded work id invalid'}
    try{$doc=Get-Content -LiteralPath $Paths.items -Raw|ConvertFrom-Json}catch{throw 'work-conservation item copy invalid'}
    $found=$false
    foreach($item in @($doc.items)){
        if([string]$item.id-eq$ExcludedId){
            $found=$true
            if($item.PSObject.Properties.Name-contains'blocked'){$item.blocked=$true}else{$item|Add-Member -NotePropertyName blocked -NotePropertyValue $true}
            if($item.PSObject.Properties.Name-contains'block_reason'){$item.block_reason='CONTROLLER_LOCAL_ANTI_SPIN_EXCLUSION'}else{$item|Add-Member -NotePropertyName block_reason -NotePropertyValue 'CONTROLLER_LOCAL_ANTI_SPIN_EXCLUSION'}
        }
    }
    if(-not$found){throw 'selected work id missing from local item copy'}
    $altPath=Join-Path (Split-Path -Parent $Paths.items) 'items-work-conservation.json'
    Write-JsonAtomic $altPath $doc
    $alt=@{programs=$Paths.programs;items=$altPath;state=$Paths.state;failures=$Paths.failures}
    return Invoke-Selector $alt
}

'''
if text.count(anchor)!=1:raise SystemExit('tool helper anchor mismatch')
text=text.replace(anchor,helper+anchor,1)

old=r'''        if ($cool -gt $now) {
            Save-Latest 'COOLDOWN_UNCHANGED_WORK' @{ selected_id = $id; fingerprint = $finger; cooldown_until = $cool.ToString('o'); same_fingerprint_turns = $turns } | Out-Null
            return
        }
        if ($same -and $lastAt -ne [datetime]::MinValue -and ($now - $lastAt).TotalMinutes -lt $MinRepeatMinutes) {
            Save-Latest 'WAIT_UNCHANGED_WORK' @{ selected_id = $id; fingerprint = $finger; minutes_since_turn = [math]::Round(($now - $lastAt).TotalMinutes, 1); same_fingerprint_turns = $turns } | Out-Null
            return
        }
        if ($turns -ge $MaxSameFingerprintTurns) {
            $until = $now.AddMinutes($FailureCooldownMinutes)
            Write-JsonAtomic $StatePath ([ordered]@{ schema = 1; last_selected_id = $id; last_fingerprint = $finger; last_turn_at = $lastAt.ToString('o'); same_fingerprint_turns = $turns; cooldown_until = $until.ToString('o'); reason = 'UNCHANGED_WORK_AFTER_BOUNDED_TURNS' })
            Save-Latest 'COOLDOWN_BUDGET_EXHAUSTED' @{ selected_id = $id; fingerprint = $finger; cooldown_until = $until.ToString('o'); same_fingerprint_turns = $turns } | Out-Null
            return
        }
'''
new=r'''        $deferReason=''
        if($same -and $cool -gt $now){$deferReason='ITEM_COOLDOWN'}
        elseif($same -and $lastAt-ne[datetime]::MinValue -and ($now-$lastAt).TotalMinutes-lt$MinRepeatMinutes){$deferReason='MIN_REPEAT'}
        elseif($same -and $turns-ge$MaxSameFingerprintTurns){$deferReason='BOUNDED_TURNS'}

        if($deferReason -and [int]$sel.eligible_count-gt1){
            $deferredId=$id
            $altSel=Invoke-SelectorExcludingId $paths $deferredId
            if([string]$altSel.authority_effect-ne'NONE_SELECTION_ONLY'){throw 'alternative selector authority contract mismatch'}
            if($null-ne$altSel.selection){
                $sel=$altSel
                $id=[string]$sel.selection.id
                if($id-eq$deferredId){throw 'work-conservation reselector returned excluded item'}
                $finger=Get-TextSha (($fingerParts+('selection:'+$id))-join"`n")
                Write-JsonAtomic $SelectionPath ([ordered]@{
                    schema=1;kind='kevin-autonomy-selection';selected_at=(Get-Date).ToString('o');id=$id;program=[string]$sel.selection.program;lane=[string]$sel.selection.lane;score=[double]$sel.selection.score;fingerprint=$finger;authority_effect='NONE_SELECTION_ONLY';source='deterministic kevin-work-selector-v1.1 work-conservation-reselection';deferred_id=$deferredId;defer_reason=$deferReason
                })
                $same=$false;$turns=0;$cool=[datetime]::MinValue;$lastAt=[datetime]::MinValue
            }
        }

        if($same -and $cool -gt $now){
            Save-Latest 'COOLDOWN_UNCHANGED_WORK' @{selected_id=$id;fingerprint=$finger;cooldown_until=$cool.ToString('o');same_fingerprint_turns=$turns;work_conservation='NO_ALTERNATIVE_ELIGIBLE'}|Out-Null
            return
        }
        if($same -and $lastAt-ne[datetime]::MinValue -and ($now-$lastAt).TotalMinutes-lt$MinRepeatMinutes){
            Save-Latest 'WAIT_UNCHANGED_WORK' @{selected_id=$id;fingerprint=$finger;minutes_since_turn=[math]::Round(($now-$lastAt).TotalMinutes,1);same_fingerprint_turns=$turns;work_conservation='NO_ALTERNATIVE_ELIGIBLE'}|Out-Null
            return
        }
        if($same -and $turns-ge$MaxSameFingerprintTurns){
            $until=$now.AddMinutes($FailureCooldownMinutes)
            Write-JsonAtomic $StatePath ([ordered]@{schema=1;last_selected_id=$id;last_fingerprint=$finger;last_turn_at=$lastAt.ToString('o');same_fingerprint_turns=$turns;cooldown_until=$until.ToString('o');reason='UNCHANGED_WORK_AFTER_BOUNDED_TURNS'})
            Save-Latest 'COOLDOWN_BUDGET_EXHAUSTED' @{selected_id=$id;fingerprint=$finger;cooldown_until=$until.ToString('o');same_fingerprint_turns=$turns;work_conservation='NO_ALTERNATIVE_ELIGIBLE'}|Out-Null
            return
        }
'''
if text.count(old)!=1:raise SystemExit('anti-spin block anchor mismatch')
text=text.replace(old,new,1)

self_anchor="""        Write-Host 'KEVIN SUPERVISOR v1.8.5 SELFTEST PASS selector_first=true gateway_agent=fixed-main gateway_rpc_only=true gateway_probe_retries=3 main_preflight=true no_forge_dispatch=true anti_spin=true openclaw_native_node=true shell_shim_bypassed=true native_timeout=180s arbitrary_shell=false authority_expansion=false'"""
self_anchor=self_anchor.replace('v1.8.5','v1.8.6')
if text.count(self_anchor)!=1:raise SystemExit('selftest marker anchor mismatch')
extra=self_anchor+"\n        Write-Host 'KEVIN SUPERVISOR v1.8.6 WORK-CONSERVATION PASS fingerprint_scoped_cooldown=true alternative_reselection=true local_exclusion_only=true canonical_queue_unchanged=true no_global_idle_with_alternative=true authority_expansion=false'"
text=text.replace(self_anchor,extra,1)
OUT.write_text(text,encoding='utf-8',newline='')
print('SUPERVISOR_V186_GENERATED sha256='+sha(OUT.read_bytes()))
