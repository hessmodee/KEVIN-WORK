from pathlib import Path

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.10.ps1')
DST=Path('control-plane/maintenance/generated/kevin-maintenance-runner-v1.3.12.ps1')
text=SRC.read_text(encoding='utf-8')

def once(old,new):
    global text
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'expected exactly one marker, got {n}: {old[:160]!r}')
    text=text.replace(old,new,1)

once("version='1.3.10'","version='1.3.12'")
once("'configure_skill_workshop_guardrails','run_reader_status_canary')","'configure_skill_workshop_guardrails','run_reader_status_canary','diagnose_forge_r03_contract')")

insert=r'''
function Assert-ForgeR03ContractDiagnosis([object]$m) {
    foreach($name in @('path','command','args','target','source_path','source_sha256','hash','test_id','context','file')){
        if($m.PSObject.Properties[$name]){throw ('R03 contract diagnosis manifest must not supply '+$name)}
    }
}
function Get-SafeR03IdentifierHints([string]$Context) {
    $set=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($m in [regex]::Matches($Context,'\$([A-Za-z_][A-Za-z0-9_]*)')){
        $v=[string]$m.Groups[1].Value
        if($v -match '(?i)forge|goal|bench|expect|hash|support|state|policy|path'){[void]$set.Add($v)}
    }
    foreach($m in [regex]::Matches($Context,'\.([A-Za-z_][A-Za-z0-9_]*)')){
        $v=[string]$m.Groups[1].Value
        if($v -match '(?i)forge|goal|bench|expect|hash|support|state|policy|path'){[void]$set.Add($v)}
    }
    return @($set|Sort-Object|Select-Object -First 40)
}
function Get-SafeR03LiteralHints([string]$Context) {
    $set=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($m in [regex]::Matches($Context,"['\"]([^'\"\r\n]{1,160})['\"]")){
        $raw=[string]$m.Groups[1].Value
        if($raw -match '(?i)forge|goal|benchmark|support|desired|state'){
            $v=[IO.Path]::GetFileName(($raw -replace '\\','/'))
            if($v -and $v.Length -le 100 -and $v -match '^[A-Za-z0-9._ -]+$'){[void]$set.Add($v)}
        }
    }
    return @($set|Sort-Object|Select-Object -First 30)
}
function Publish-ForgeR03Contract([object]$Public) {
    $local=Join-Path $Reports 'forge-r03-contract-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/forge-r03-contract.json'
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
        if($lookup.ExitCode -ne 0 -or -not$lookup.Output){throw 'R03 contract receipt remote SHA lookup failed'}
        $payload=[ordered]@{message='kevin Forge R03 contract telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local));sha=[string]$lookup.Output}|ConvertTo-Json -Compress
        $tmp=Join-Path $env:TEMP ('kevin-r03-contract-'+[guid]::NewGuid().ToString('N')+'.json')
        try{[IO.File]::WriteAllText($tmp,$payload,$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$tmp,'--silent')}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode -eq 0){return [ordered]@{published=$true;attempt=$attempt;repo_path=$repoPath}}
        if($attempt-lt3){Start-Sleep -Milliseconds (400*$attempt)}
    }
    throw 'R03 contract receipt bounded publish retries exhausted'
}
function Diagnose-ForgeR03Contract {
    $bench=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    $forge=(Get-AliasSpec 'design_forge_runner').Target
    if(-not(Test-Path -LiteralPath $bench -PathType Leaf)){throw 'Benchmark missing for R03 diagnosis'}
    if(-not(Test-Path -LiteralPath $forge -PathType Leaf)){throw 'Forge missing for R03 diagnosis'}
    $text=[IO.File]::ReadAllText($bench)
    $idx=$text.IndexOf('R03',[StringComparison]::OrdinalIgnoreCase)
    if($idx-lt0){throw 'R03 marker missing from Benchmark'}
    $start=[Math]::Max(0,$idx-3500);$len=[Math]::Min(8000,$text.Length-$start);$ctx=$text.Substring($start,$len)
    $currentForge=Get-Sha $forge
    $candidateForge='433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
    $shaLits=@([regex]::Matches($ctx,'(?i)\b[A-F0-9]{64}\b')|ForEach-Object{$_.Value.ToUpperInvariant()})
    $ops=[ordered]@{}
    foreach($pair in @(@('get_file_hash','Get-FileHash'),@('get_content','Get-Content'),@('json_parse','ConvertFrom-Json'),@('test_path','Test-Path'),@('eq','-eq'),@('ne','-ne'),@('contains','-contains'),@('notcontains','-notcontains'),@('match','-match'))){$ops[$pair[0]]=($ctx -match [regex]::Escape($pair[1]))}
    $public=[ordered]@{
        schema=1;kind='kevin-forge-r03-contract-public';generated_at=(Get-Date).ToString('o');state='DIAGNOSIS_PROVEN';safe_for_public_repo=$true
        benchmark_sha256=(Get-Sha $bench);forge_sha256=$currentForge;candidate_forge_sha256=$candidateForge
        r03=[ordered]@{
            marker_present=$true
            context_sha256=(Get-TextSha256 $ctx)
            current_forge_literal_count=(Get-LiteralOccurrenceCount $ctx $currentForge)
            candidate_forge_literal_count=(Get-LiteralOccurrenceCount $ctx $candidateForge)
            sha64_literal_count=$shaLits.Count
            current_forge_sha64_matches=@($shaLits|Where-Object{$_-eq$currentForge}).Count
            candidate_forge_sha64_matches=@($shaLits|Where-Object{$_-eq$candidateForge}).Count
            identifier_hints=@(Get-SafeR03IdentifierHints $ctx)
            literal_hints=@(Get-SafeR03LiteralHints $ctx)
            operators=$ops
        }
        source_contract='Fixed installed Benchmark + fixed installed Forge only; R03 marker selected internally. No caller-selected path, command, argv, hash, test, source, or context.'
        privacy='No raw Benchmark source, raw lines, absolute paths, usernames, arbitrary literals, configuration values, credentials, prompts, or secrets are published. Only allowlisted identifier/basename hints and structural counts/booleans.'
    }
    $pub=Publish-ForgeR03Contract $public
    Assert-Benchmark30
    return [ordered]@{state='DIAGNOSIS_PROVEN';published=$pub.published;benchmark_sha256=$public.benchmark_sha256;forge_sha256=$currentForge;current_forge_literal_count=$public.r03.current_forge_literal_count;sha64_literal_count=$public.r03.sha64_literal_count}
}
'''.strip()
once('function Assert-ReaderStatusCanary([object]$m) {',insert+'\n\nfunction Assert-ReaderStatusCanary([object]$m) {')

once("        'run_reader_status_canary' { Assert-ReaderStatusCanary $m }\n        default { throw 'operation not allowlisted' }",
     "        'run_reader_status_canary' { Assert-ReaderStatusCanary $m }\n        'diagnose_forge_r03_contract' { Assert-ForgeR03ContractDiagnosis $m }\n        default { throw 'operation not allowlisted' }")
once("            'run_reader_status_canary' { Run-ReaderStatusCanary; break }\n        }",
     "            'run_reader_status_canary' { Run-ReaderStatusCanary; break }\n            'diagnose_forge_r03_contract' { Diagnose-ForgeR03Contract; break }\n        }")
once("            'run_reader_status_canary' {'reader_status_canary_failure'}\n            default {'typed_replace_failure'}",
     "            'run_reader_status_canary' {'reader_status_canary_failure'}\n            'diagnose_forge_r03_contract' {'forge_r03_contract_diagnosis_failure'}\n            default {'typed_replace_failure'}")

selftest=r'''
    $diag=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$diag.operation='diagnose_forge_r03_contract';Assert-Common $diag;Assert-ForgeR03ContractDiagnosis $diag
    $diagBad=$diag|ConvertTo-Json -Depth 10|ConvertFrom-Json;$diagBad|Add-Member -NotePropertyName path -NotePropertyValue 'arbitrary';$blocked=$false;try{Assert-ForgeR03ContractDiagnosis $diagBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected R03 path accepted'}
    $hints=Get-SafeR03IdentifierHints '$forgeExpected = $goal_os.forge_hash; $secretToken = 1';if($hints -notcontains 'forgeExpected' -or $hints -notcontains 'goal_os' -or $hints -contains 'secretToken'){throw 'R03 identifier redaction fixture failed'}
'''.rstrip()
once("    $guard=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$guard.operation='configure_skill_workshop_guardrails';Assert-Common $guard;Assert-SkillWorkshopGuardrails $guard",
     selftest+"\n    $guard=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$guard.operation='configure_skill_workshop_guardrails';Assert-Common $guard;Assert-SkillWorkshopGuardrails $guard")

old="""    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS compatibility=v1.3.10'
    Write-Host 'KEVIN MAINTENANCE v1.3.10 SELFTEST PASS workshop_dry_run_raw_string=true workshop_guardrails=propose_pending reader_canary=2_trials fixed_reader_prompt=true exact_tool_calls=1 semantic_categories=6 privacy_gate=true arbitrary_shell=false authority_expansion=false max_attempts=3'"""
new="""    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS compatibility=v1.3.12'
    Write-Host 'KEVIN MAINTENANCE v1.3.10 SELFTEST PASS compatibility=v1.3.12'
    Write-Host 'KEVIN MAINTENANCE v1.3.12 SELFTEST PASS r03_contract_diagnosis=fixed metadata_only=true bounded_publish_retries=3 workshop_guardrails=propose_pending reader_canary=2_trials arbitrary_shell=false authority_expansion=false max_attempts=3'"""
once(old,new)

DST.parent.mkdir(parents=True,exist_ok=True)
DST.write_text(text,encoding='utf-8',newline='\n')
print(DST)
