from pathlib import Path

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.12.ps1')
DST=Path('control-plane/maintenance/generated/kevin-maintenance-runner-v1.3.13.ps1')
text=SRC.read_text(encoding='utf-8')

def once(old,new):
    global text
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'expected exactly one marker, got {n}: {old[:160]!r}')
    text=text.replace(old,new,1)

once("version='1.3.12'","version='1.3.13'")
once("'configure_skill_workshop_guardrails','run_reader_status_canary','diagnose_forge_r03_contract')","'configure_skill_workshop_guardrails','run_reader_status_canary','diagnose_forge_r03_contract','diagnose_goal_os_forge_anchor')")

insert=r'''
function Assert-GoalOsForgeAnchorDiagnosis([object]$m) {
    foreach($name in @('path','command','args','target','source_path','source_sha256','hash','file','property','root','pattern')){
        if($m.PSObject.Properties[$name]){throw ('Goal OS anchor diagnosis manifest must not supply '+$name)}
    }
}
function Get-BoundedJsonInventory {
    $files=@(Get-ChildItem -LiteralPath $Workspace -Filter '*.json' -File -Recurse -ErrorAction SilentlyContinue | Where-Object{
        $_.FullName -notmatch '(?i)\\(?:Backups?|Stage|node_modules|\.git|Logs?)\\'
    } | Select-Object -First 500)
    if($files.Count -ge 500){throw 'Goal OS discovery inventory exceeded fixed 500-file budget'}
    return @($files)
}
function Find-JsonBySha([string]$Sha) {
    $hits=@()
    foreach($f in @(Get-BoundedJsonInventory)){
        try{if((Get-Sha $f.FullName)-eq$Sha){$hits+=,$f}}catch{}
    }
    return @($hits)
}
function Find-ForgeAnchorMatches([object]$Node,[string]$Expected,[string]$Prefix='') {
    $out=@()
    if($null-eq$Node){return @()}
    if($Node -is [System.Collections.IDictionary]){
        foreach($k in $Node.Keys){$name=[string]$k;$p=if($Prefix){$Prefix+'.'+$name}else{$name};$v=$Node[$k];if($v -is [string] -and ([string]$v).ToUpperInvariant()-eq$Expected -and $name-match'(?i)^forge(?:_sha256|_hash)?$'){$out+=,[pscustomobject]@{path=$p;leaf=$name}}else{$out+=@(Find-ForgeAnchorMatches $v $Expected $p)}}
        return @($out)
    }
    if($Node -is [System.Collections.IEnumerable] -and -not($Node -is [string]) -and -not($Node -is [pscustomobject])){
        $i=0;foreach($v in $Node){$p=if($Prefix){$Prefix+'['+$i+']'}else{'['+$i+']'};$out+=@(Find-ForgeAnchorMatches $v $Expected $p);$i++};return @($out)
    }
    foreach($prop in @($Node.PSObject.Properties)){
        $name=[string]$prop.Name;$p=if($Prefix){$Prefix+'.'+$name}else{$name};$v=$prop.Value
        if($v -is [string] -and ([string]$v).ToUpperInvariant()-eq$Expected -and $name-match'(?i)^forge(?:_sha256|_hash)?$'){$out+=,[pscustomobject]@{path=$p;leaf=$name}}else{$out+=@(Find-ForgeAnchorMatches $v $Expected $p)}
    }
    return @($out)
}
function Publish-GoalOsForgeAnchor([object]$Public) {
    $local=Join-Path $Reports 'goal-os-forge-anchor-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/goal-os-forge-anchor.json'
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
        if($lookup.ExitCode -ne 0 -or -not$lookup.Output){throw 'Goal OS anchor receipt remote SHA lookup failed'}
        $payload=[ordered]@{message='kevin Goal OS Forge anchor telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local));sha=[string]$lookup.Output}|ConvertTo-Json -Compress
        $tmp=Join-Path $env:TEMP ('kevin-goalos-anchor-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,$payload,$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode-eq0){return [ordered]@{published=$true;attempt=$attempt}}
        if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt)}
    }
    throw 'Goal OS anchor receipt bounded publish retries exhausted'
}
function Diagnose-GoalOsForgeAnchor {
    $support=Get-Content -LiteralPath (Join-Path $Reports 'support-latest.json') -Raw|ConvertFrom-Json
    $goalSha=([string]$support.hashes.goal_os).ToUpperInvariant();$forgeSha=([string]$support.hashes.forge).ToUpperInvariant()
    if($goalSha-notmatch'^[A-F0-9]{64}$' -or $forgeSha-notmatch'^[A-F0-9]{64}$'){throw 'Support Goal OS/Forge identities unavailable'}
    $files=@(Find-JsonBySha $goalSha)
    if($files.Count-ne1){throw ('Goal OS exact-hash file match count must be 1; count='+$files.Count)}
    $goalFile=$files[0]
    try{$goal=Get-Content -LiteralPath $goalFile.FullName -Raw|ConvertFrom-Json}catch{throw 'Exact Goal OS file is not valid JSON'}
    $anchors=@(Find-ForgeAnchorMatches $goal $forgeSha)
    $leafs=@($anchors|ForEach-Object{$_.leaf}|Sort-Object -Unique)
    $public=[ordered]@{
        schema=1;kind='kevin-goal-os-forge-anchor-public';generated_at=(Get-Date).ToString('o');state='DIAGNOSIS_PROVEN';safe_for_public_repo=$true
        goal_os_sha256=$goalSha;forge_sha256=$forgeSha;matched_file_count=$files.Count;matched_file_basename=[IO.Path]::GetFileName($goalFile.FullName)
        forge_anchor_match_count=$anchors.Count;forge_anchor_property_names=$leafs
        migration_ready=($anchors.Count-eq1)
        source_contract='Fixed Workspace JSON inventory capped at 500; exact Goal OS SHA from fixed Support snapshot; fixed live Forge SHA. No caller-selected path, hash, property, root, pattern, command, or argv.'
        privacy='Publishes only exact public component hashes, one basename, counts, and Forge-related leaf property names. No file content, absolute path, usernames, credentials, prompts, or arbitrary configuration values.'
    }
    $null=Publish-GoalOsForgeAnchor $public
    Assert-Benchmark30
    if($anchors.Count-ne1){throw ('Goal OS Forge anchor must be unique before migration; count='+$anchors.Count)}
    return [ordered]@{state='DIAGNOSIS_PROVEN';migration_ready=$true;file=[IO.Path]::GetFileName($goalFile.FullName);anchor_count=1;property=$leafs[0]}
}
'''.strip()
once('function Assert-ReaderStatusCanary([object]$m) {',insert+'\n\nfunction Assert-ReaderStatusCanary([object]$m) {')
once("        'diagnose_forge_r03_contract' { Assert-ForgeR03ContractDiagnosis $m }\n        default { throw 'operation not allowlisted' }","        'diagnose_forge_r03_contract' { Assert-ForgeR03ContractDiagnosis $m }\n        'diagnose_goal_os_forge_anchor' { Assert-GoalOsForgeAnchorDiagnosis $m }\n        default { throw 'operation not allowlisted' }")
once("            'diagnose_forge_r03_contract' { Diagnose-ForgeR03Contract; break }\n        }","            'diagnose_forge_r03_contract' { Diagnose-ForgeR03Contract; break }\n            'diagnose_goal_os_forge_anchor' { Diagnose-GoalOsForgeAnchor; break }\n        }")
once("            'diagnose_forge_r03_contract' {'forge_r03_contract_diagnosis_failure'}\n            default {'typed_replace_failure'}","            'diagnose_forge_r03_contract' {'forge_r03_contract_diagnosis_failure'}\n            'diagnose_goal_os_forge_anchor' {'goal_os_forge_anchor_diagnosis_failure'}\n            default {'typed_replace_failure'}")
selftest=r'''
    $ga=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$ga.operation='diagnose_goal_os_forge_anchor';Assert-Common $ga;Assert-GoalOsForgeAnchorDiagnosis $ga
    $gaBad=$ga|ConvertTo-Json -Depth 10|ConvertFrom-Json;$gaBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-GoalOsForgeAnchorDiagnosis $gaBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Goal OS path accepted'}
    $fixture=[pscustomobject]@{hashes=[pscustomobject]@{forge=('A'*64);other='x'}};$hits=@(Find-ForgeAnchorMatches $fixture ('A'*64));if($hits.Count-ne1 -or $hits[0].leaf-ne'forge'){throw 'Goal OS Forge anchor fixture failed'}
    $fixture2=[pscustomobject]@{hashes=[pscustomobject]@{notforge=('A'*64)}};$hits=@(Find-ForgeAnchorMatches $fixture2 ('A'*64));if($hits.Count-ne0){throw 'non-Forge same hash fixture accepted'}
'''.rstrip()
once("    $diag=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$diag.operation='diagnose_forge_r03_contract';Assert-Common $diag;Assert-ForgeR03ContractDiagnosis $diag",selftest+"\n    $diag=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$diag.operation='diagnose_forge_r03_contract';Assert-Common $diag;Assert-ForgeR03ContractDiagnosis $diag")
old="""    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS compatibility=v1.3.12'
    Write-Host 'KEVIN MAINTENANCE v1.3.10 SELFTEST PASS compatibility=v1.3.12'
    Write-Host 'KEVIN MAINTENANCE v1.3.12 SELFTEST PASS r03_contract_diagnosis=fixed metadata_only=true bounded_publish_retries=3 workshop_guardrails=propose_pending reader_canary=2_trials arbitrary_shell=false authority_expansion=false max_attempts=3'"""
new="""    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS compatibility=v1.3.13'
    Write-Host 'KEVIN MAINTENANCE v1.3.10 SELFTEST PASS compatibility=v1.3.13'
    Write-Host 'KEVIN MAINTENANCE v1.3.12 SELFTEST PASS compatibility=v1.3.13'
    Write-Host 'KEVIN MAINTENANCE v1.3.13 SELFTEST PASS goal_os_anchor_discovery=fixed exact_hash_lookup=true unique_forge_anchor=true inventory_max=500 r03_contract_diagnosis=fixed arbitrary_shell=false authority_expansion=false max_attempts=3'"""
once(old,new)
DST.parent.mkdir(parents=True,exist_ok=True);DST.write_text(text,encoding='utf-8',newline='\n');print(DST)
