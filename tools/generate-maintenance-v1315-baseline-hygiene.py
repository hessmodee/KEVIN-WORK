from pathlib import Path

BASE=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.14.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.15.ps1')
text=BASE.read_text(encoding='utf-8')
original=text

if text.count("version='1.3.14'")!=1:
    raise SystemExit('expected exact v1.3.14 state version marker')
text=text.replace("version='1.3.14'","version='1.3.15'")

old="'diagnose_forge_r03_contract','diagnose_goal_os_forge_anchor')"
new="'diagnose_forge_r03_contract','diagnose_goal_os_forge_anchor','diagnose_benchmark_baseline_forge_anchor')"
if text.count(old)!=1:
    raise SystemExit('typed operation allowlist anchor missing')
text=text.replace(old,new)

insert_before="function Assert-GoalOsForgeAnchorDiagnosis([object]$m) {"
if text.count(insert_before)!=1:
    raise SystemExit('Goal OS assertion insertion anchor missing')
block=r'''function Assert-BenchmarkBaselineForgeAnchorDiagnosis([object]$m) {
    foreach($name in @('path','command','args','target','source_path','source_sha256','hash','file','property','root','pattern')){
        if($m.PSObject.Properties[$name]){throw ('Benchmark baseline diagnosis manifest must not supply '+$name)}
    }
}
function Publish-BenchmarkBaselineForgeAnchor([object]$Public) {
    $local=Join-Path $Reports 'benchmark-baseline-forge-anchor-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/benchmark-baseline-forge-anchor.json'
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
        $body=[ordered]@{message='kevin Benchmark baseline Forge anchor telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))}
        if($lookup.ExitCode-eq0 -and $lookup.Output){$body.sha=[string]$lookup.Output}
        elseif($lookup.ExitCode-ne0 -and $lookup.Output-notmatch'404|Not Found'){throw 'Benchmark baseline receipt lookup failed'}
        $tmp=Join-Path $env:TEMP ('kevin-benchmark-baseline-anchor-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode-eq0){return [ordered]@{published=$true;attempt=$attempt}}
        if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt)}
    }
    throw 'Benchmark baseline receipt bounded publish retries exhausted'
}
function Diagnose-BenchmarkBaselineForgeAnchor {
    $support=Get-Content -LiteralPath (Join-Path $Reports 'support-latest.json') -Raw|ConvertFrom-Json
    $liveForge=([string]$support.hashes.forge).ToUpperInvariant();$liveSupervisor=([string]$support.hashes.supervisor).ToUpperInvariant()
    if($liveForge-notmatch'^[A-F0-9]{64}$' -or $liveSupervisor-notmatch'^[A-F0-9]{64}$'){throw 'Support Supervisor/Forge identities unavailable'}
    $p=Join-Path $Reports 'benchmark-v1\baseline.json'
    if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'Fixed Benchmark baseline file missing'}
    try{$b=Get-Content -LiteralPath $p -Raw|ConvertFrom-Json}catch{throw 'Fixed Benchmark baseline is not valid JSON'}
    if(-not$b.hashes){throw 'Benchmark baseline hashes object missing'}
    $forgePresent=$null-ne$b.hashes.PSObject.Properties['forge'];$superPresent=$null-ne$b.hashes.PSObject.Properties['supervisor']
    $forgeMatch=$forgePresent-and([string]$b.hashes.forge).ToUpperInvariant()-eq$liveForge
    $superMatch=$superPresent-and([string]$b.hashes.supervisor).ToUpperInvariant()-eq$liveSupervisor
    $keys=@($b.hashes.PSObject.Properties.Name|Where-Object{$_-match'(?i)^(supervisor|benchmark|forge|goal_os|goalOs|support|maintenance|promotion)'}|Sort-Object -Unique)
    $public=[ordered]@{
        schema=1;kind='kevin-benchmark-baseline-forge-anchor-public';generated_at=(Get-Date).ToString('o');state='DIAGNOSIS_PROVEN';safe_for_public_repo=$true
        baseline_sha256=Get-Sha $p;forge_anchor_present=$forgePresent;forge_matches_live=$forgeMatch;supervisor_anchor_present=$superPresent;supervisor_matches_live=$superMatch
        allowlisted_hash_keys=$keys;migration_ready=($forgePresent-and$forgeMatch)
        source_contract='Fixed reports/benchmark-v1/baseline.json + fixed Support Supervisor/Forge identities only. No caller-selected path, hash, property, command, argv, or arbitrary configuration.'
        privacy='Publishes only baseline SHA, booleans, and allowlisted component-key names. No paths beyond the fixed public contract, raw baseline content, usernames, credentials, prompts, or secrets.'
    }
    $null=Publish-BenchmarkBaselineForgeAnchor $public
    Assert-Benchmark30
    if(-not$forgePresent){throw 'Benchmark baseline Forge anchor missing'}
    if(-not$forgeMatch){throw 'Benchmark baseline Forge anchor does not match live Forge'}
    return [ordered]@{state='DIAGNOSIS_PROVEN';migration_ready=$true;baseline_sha256=$public.baseline_sha256;forge_matches_live=$true;supervisor_matches_live=$superMatch}
}

'''
text=text.replace(insert_before,block+insert_before)

old_switch="        'diagnose_goal_os_forge_anchor' { Assert-GoalOsForgeAnchorDiagnosis $m }\n        default { throw 'operation not allowlisted' }"
new_switch="        'diagnose_goal_os_forge_anchor' { Assert-GoalOsForgeAnchorDiagnosis $m }\n        'diagnose_benchmark_baseline_forge_anchor' { Assert-BenchmarkBaselineForgeAnchorDiagnosis $m }\n        default { throw 'operation not allowlisted' }"
if text.count(old_switch)!=1:
    raise SystemExit('Process-Typed assertion switch anchor missing')
text=text.replace(old_switch,new_switch)

old_exec="            'diagnose_goal_os_forge_anchor' { Diagnose-GoalOsForgeAnchor; break }\n        }"
new_exec="            'diagnose_goal_os_forge_anchor' { Diagnose-GoalOsForgeAnchor; break }\n            'diagnose_benchmark_baseline_forge_anchor' { Diagnose-BenchmarkBaselineForgeAnchor; break }\n        }"
if text.count(old_exec)!=1:
    raise SystemExit('Process-Typed execution switch anchor missing')
text=text.replace(old_exec,new_exec)

old_family="            'diagnose_goal_os_forge_anchor' {'goal_os_forge_anchor_diagnosis_failure'}\n            default {'typed_replace_failure'}"
new_family="            'diagnose_goal_os_forge_anchor' {'goal_os_forge_anchor_diagnosis_failure'}\n            'diagnose_benchmark_baseline_forge_anchor' {'benchmark_baseline_forge_anchor_diagnosis_failure'}\n            default {'typed_replace_failure'}"
if text.count(old_family)!=1:
    raise SystemExit('failure-family switch anchor missing')
text=text.replace(old_family,new_family)

old_throw="        Save-Attempt ([string]$m.id) $attempts 'FAILED' $family\n        Save-State 'APPLY_FAILED' ([string]$m.id) $_.Exception.Message @{attempts=$attempts;failure_family=$family}\n        throw"
new_throw="        Save-Attempt ([string]$m.id) $attempts 'FAILED' $family\n        Save-State 'APPLY_FAILED' ([string]$m.id) $_.Exception.Message @{attempts=$attempts;failure_family=$family}\n        Write-Host ('MAINTENANCE TYPED OUTCOME APPLY_FAILED family='+$family+' attempts='+$attempts)\n        return"
if text.count(old_throw)!=1:
    raise SystemExit('typed failure throw anchor missing')
text=text.replace(old_throw,new_throw)

self_anchor="    $gaBad=$ga|ConvertTo-Json -Depth 10|ConvertFrom-Json;$gaBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-GoalOsForgeAnchorDiagnosis $gaBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Goal OS path accepted'}\n"
if text.count(self_anchor)!=1:
    raise SystemExit('selftest Goal OS anchor missing')
self_extra="    $bb=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bb.operation='diagnose_benchmark_baseline_forge_anchor';Assert-Common $bb;Assert-BenchmarkBaselineForgeAnchorDiagnosis $bb\n    $bbBad=$bb|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bbBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-BenchmarkBaselineForgeAnchorDiagnosis $bbBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Benchmark baseline path accepted'}\n"
text=text.replace(self_anchor,self_anchor+self_extra)

marker="    Write-Host 'KEVIN MAINTENANCE v1.3.13 SELFTEST PASS goal_os_anchor_discovery=fixed exact_hash_lookup=true unique_forge_anchor=true inventory_max=500 r03_contract_diagnosis=fixed arbitrary_shell=false authority_expansion=false max_attempts=3'"
if text.count(marker)!=1:
    raise SystemExit('selftest output marker missing')
text=text.replace(marker,marker+"\n    Write-Host 'KEVIN MAINTENANCE v1.3.15 SELFTEST PASS benchmark_baseline_anchor=fixed typed_apply_failure=handled scheduler_backoff_poison=false arbitrary_shell=false authority_expansion=false'")

for required in ['diagnose_benchmark_baseline_forge_anchor','reports/benchmark-v1\\baseline.json','MAINTENANCE TYPED OUTCOME APPLY_FAILED','scheduler_backoff_poison=false']:
    if required not in text: raise SystemExit('missing invariant '+required)
if text==original: raise SystemExit('no change')
OUT.write_text(text,encoding='utf-8',newline='\n')
print(OUT)
