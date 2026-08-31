from pathlib import Path

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.9.ps1')
DST=Path('control-plane/maintenance/generated/kevin-maintenance-runner-v1.3.11.ps1')
text=SRC.read_text(encoding='utf-8')

def once(old,new):
    global text
    n=text.count(old)
    if n!=1:
        raise SystemExit(f'expected exactly one marker, got {n}: {old[:140]!r}')
    text=text.replace(old,new,1)

once("version='1.3.9'","version='1.3.11'")
once("'configure_skill_workshop_guardrails','run_reader_status_canary')","'configure_skill_workshop_guardrails','run_reader_status_canary','diagnose_forge_v40_benchmark')")

insert=r'''
function Assert-ForgeV40Diagnosis([object]$m) {
    foreach($name in @('path','command','args','target','source_path','source_sha256','expected_current_sha256','expected_after_sha256','benchmark','test_id')){
        if($m.PSObject.Properties[$name]){throw ('Forge diagnosis manifest must not supply '+$name)}
    }
}
function Get-SafeFailureMetadata([object]$Failure) {
    $txt=if($Failure -is [string]){[string]$Failure}else{try{$Failure|ConvertTo-Json -Depth 8 -Compress}catch{[string]$Failure}}
    $id=''
    $m=[regex]::Match($txt,'(?i)\bR\d{2}\b');if($m.Success){$id=$m.Value.ToUpperInvariant()}
    $sha=[Security.Cryptography.SHA256]::Create();try{$h=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($txt)))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()}
    return [ordered]@{
        test_id=$id
        entry_sha256=$h
        mentions_r03=($txt -match '(?i)\bR03\b')
        mentions_forge=($txt -match '(?i)forge')
        mentions_goal_os=($txt -match '(?i)goal.?os')
        mentions_hash=($txt -match '(?i)hash|sha256|filehash')
    }
}
function Publish-ForgeV40Diagnosis([object]$Public) {
    $local=Join-Path $Reports 'forge-v40-benchmark-diagnosis-public.json';Write-JsonAtomic $local $Public
    $repoPath='reports/forge-v40-benchmark-diagnosis.json'
    $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
    if($lookup.ExitCode -ne 0 -or -not$lookup.Output){throw 'Forge diagnosis remote SHA lookup failed'}
    $payload=[ordered]@{message='kevin Forge benchmark diagnosis telemetry';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local));sha=[string]$lookup.Output}|ConvertTo-Json -Compress
    $tmp=Join-Path $env:TEMP ('kevin-forge-diagnosis-'+[guid]::NewGuid().ToString('N')+'.json')
    try{[IO.File]::WriteAllText($tmp,$payload,$Utf8);$put=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$tmp,'--silent');if($put.ExitCode-ne0){throw ('Forge diagnosis publish failed: '+(Safe-Text $put.Output 300))}}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
    return [ordered]@{published=$true;repo_path=$repoPath}
}
function Diagnose-ForgeV40Benchmark {
    $candidateSha='433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
    $legacySha='4C83DF29E765D61F2B26D2029FE6C2C7ED68DA90E5A7A457A82BE769029E22CA'
    $spec=Get-AliasSpec 'design_forge_runner';$target=[string]$spec.Target
    $before=Get-Sha $target
    if($before -ne $legacySha){throw ('Forge diagnosis requires exact legacy identity; actual='+$before)}
    $bytes=Get-RemoteFixedBytes 'control-plane/forge/kevin-design-forge-v4.0.ps1'
    $stage=Join-Path $StageRoot 'forge-v40-benchmark-diagnosis.candidate.ps1';[IO.File]::WriteAllBytes($stage,$bytes)
    if((Get-Sha $stage)-ne$candidateSha){throw 'Forge diagnosis candidate source identity mismatch'}
    Parse-PowerShell $stage;Invoke-FixedSelfTest 'design_forge_runner' $stage
    $bench=Join-Path $Workspace 'kevin-benchmark-v1.ps1';$latest=Join-Path $Reports 'benchmark-v1\latest.json'
    if(-not(Test-Path -LiteralPath $bench -PathType Leaf)){throw 'Benchmark script missing for Forge diagnosis'}
    $benchText=[IO.File]::ReadAllText($bench)
    $r03=[regex]::Match($benchText,'(?is).{0,1200}\bR03\b.{0,2800}')
    $r03Text=if($r03.Success){$r03.Value}else{''}
    $contextFlags=[ordered]@{
        marker_present=$r03.Success
        mentions_forge=($r03Text-match'(?i)forge')
        mentions_goal_os=($r03Text-match'(?i)goal.?os')
        mentions_file_hash=($r03Text-match'(?i)Get-FileHash|SHA256|hash')
        mentions_equality=($r03Text-match'(?i)-eq\b|Equals\(')
        mentions_inequality=($r03Text-match'(?i)-ne\b')
        context_sha256=if($r03.Success){Get-TextSha256 $r03Text}else{''}
    }
    $backup=Join-Path $BackupRoot ('forge-v40-diagnosis-'+[guid]::NewGuid().ToString('N')+'.ps1');Copy-Item -LiteralPath $target -Destination $backup -Force
    $candidateResult=$null
    try{
        $tmpTarget=$target+'.diagnostic-'+[guid]::NewGuid().ToString('N');Copy-Item -LiteralPath $stage -Destination $tmpTarget -Force;Move-Item -LiteralPath $tmpTarget -Destination $target -Force
        if((Get-Sha $target)-ne$candidateSha){throw 'temporary Forge diagnostic identity mismatch'}
        Invoke-FixedSelfTest 'design_forge_runner' $target
        $old=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $bench 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
        $b=if(Test-Path -LiteralPath $latest -PathType Leaf){try{Get-Content -LiteralPath $latest -Raw|ConvertFrom-Json}catch{$null}}else{$null}
        $failed=@();if($b -and $b.regression -and $b.regression.failed){foreach($f in @($b.regression.failed)){$failed+=,(Get-SafeFailureMetadata $f)}}
        $candidateResult=[ordered]@{
            exit_code=$code
            status=if($b){[string]$b.status}else{'NO_REPORT'}
            passed=if($b){[int]$b.regression.passed}else{-1}
            total=if($b){[int]$b.regression.total}else{-1}
            critical_failures=if($b){[int]$b.regression.critical_failures}else{-1}
            failed_count=$failed.Count
            failed=@($failed)
            stdout_sha256=(Get-TextSha256 ([string]$out))
        }
    }finally{
        Copy-Item -LiteralPath $backup -Destination $target -Force
        if((Get-Sha $target)-ne$legacySha){throw 'Forge diagnosis rollback identity mismatch'}
    }
    Assert-Benchmark30
    $ids=@($candidateResult.failed|ForEach-Object{$_.test_id}|Where-Object{$_}|Select-Object -Unique)
    $public=[ordered]@{
        schema=1;kind='kevin-forge-v40-benchmark-diagnosis-public';generated_at=(Get-Date).ToString('o');state='DIAGNOSIS_PROVEN';safe_for_public_repo=$true
        legacy_sha256=$legacySha;candidate_sha256=$candidateSha;candidate_benchmark=$candidateResult;r03_context=$contextFlags
        failed_test_ids=$ids
        rollback=[ordered]@{restored_legacy_identity=$true;post_rollback_benchmark='PASS_30_OF_30_CRITICAL_0'}
        source_contract='Fixed candidate + fixed installed Forge target + fixed Benchmark only. No caller-selected path, command, argv, URL, test, hash, or output.'
        truth_boundary='Metadata-only reversible diagnostic. Raw Benchmark source/output and local paths/configuration are not published.'
    }
    $pub=Publish-ForgeV40Diagnosis $public
    return [ordered]@{state='DIAGNOSIS_PROVEN';failed_test_ids=$ids;published=$pub.published;legacy_restored=$true;benchmark_restored='PASS_30_OF_30_CRITICAL_0'}
}
'''.strip()
once('function Assert-ReaderStatusCanary([object]$m) {',insert+'\n\nfunction Assert-ReaderStatusCanary([object]$m) {')
once("        'run_reader_status_canary' { Assert-ReaderStatusCanary $m }\n        default { throw 'operation not allowlisted' }",
     "        'run_reader_status_canary' { Assert-ReaderStatusCanary $m }\n        'diagnose_forge_v40_benchmark' { Assert-ForgeV40Diagnosis $m }\n        default { throw 'operation not allowlisted' }")
once("            'run_reader_status_canary' { Run-ReaderStatusCanary; break }\n        }",
     "            'run_reader_status_canary' { Run-ReaderStatusCanary; break }\n            'diagnose_forge_v40_benchmark' { Diagnose-ForgeV40Benchmark; break }\n        }")
once("            'run_reader_status_canary' {'reader_status_canary_failure'}\n            default {'typed_replace_failure'}",
     "            'run_reader_status_canary' {'reader_status_canary_failure'}\n            'diagnose_forge_v40_benchmark' {'forge_v40_benchmark_diagnosis_failure'}\n            default {'typed_replace_failure'}")
selftest=r'''
    $diag=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$diag.operation='diagnose_forge_v40_benchmark';Assert-Common $diag;Assert-ForgeV40Diagnosis $diag
    $diagBad=$diag|ConvertTo-Json -Depth 10|ConvertFrom-Json;$diagBad|Add-Member -NotePropertyName command -NotePropertyValue 'whoami';$blocked=$false;try{Assert-ForgeV40Diagnosis $diagBad}catch{$blocked=$true};if(-not$blocked){throw 'caller-selected Forge diagnosis command accepted'}
    $fm=Get-SafeFailureMetadata 'R03 Forge Goal OS hash mismatch';if($fm.test_id-ne'R03' -or -not$fm.mentions_forge -or -not$fm.mentions_goal_os -or -not$fm.mentions_hash){throw 'Forge failure metadata fixture failed'}
'''.rstrip()
once("    $reader=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$reader.operation='run_reader_status_canary';Assert-Common $reader;Assert-ReaderStatusCanary $reader",
     selftest+"\n    $reader=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$reader.operation='run_reader_status_canary';Assert-Common $reader;Assert-ReaderStatusCanary $reader")
once("    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS reader_canary=2_trials fixed_reader_prompt=true exact_tool_calls=1 semantic_categories=6 privacy_gate=true workshop_guardrails=propose_pending arbitrary_shell=false authority_expansion=false max_attempts=3'",
     "    Write-Host 'KEVIN MAINTENANCE v1.3.9 SELFTEST PASS compatibility=v1.3.11'\n    Write-Host 'KEVIN MAINTENANCE v1.3.11 SELFTEST PASS forge_diagnosis=fixed_reversible metadata_only=true rollback=true benchmark_restore=30of30 reader_canary=2_trials arbitrary_shell=false authority_expansion=false max_attempts=3'")
DST.parent.mkdir(parents=True,exist_ok=True)
DST.write_text(text,encoding='utf-8',newline='\n')
print(DST)
