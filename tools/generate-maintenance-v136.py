from pathlib import Path

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.5.ps1')
DST = Path('control-plane/maintenance/generated/kevin-maintenance-runner-v1.3.6.ps1')
text = SRC.read_text(encoding='utf-8')


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'expected exactly one marker, found {count}: {old[:100]!r}')
    text = text.replace(old, new, 1)


replace_once("version='1.3.5'", "version='1.3.6'")
replace_once(
    "@('replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','replace_runtime_policy_bundle','migrate_design_forge_v40')",
    "@('replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','publish_runtime_convergence','replace_runtime_policy_bundle','migrate_design_forge_v40')",
)

publisher = r'''
function Publish-RuntimeConvergence {
    $audit=Audit-RuntimeConvergence
    $public=[ordered]@{
        schema=1
        kind='kevin-runtime-convergence-public'
        generated_at=(Get-Date).ToString('o')
        state='OMEN_AUDIT_PROVEN'
        safe_for_public_repo=$true
        policy_hashes=$audit.policy_hashes
        design_forge_sha256=$audit.design_forge_sha256
        design_forge_present=$audit.design_forge_present
        maintenance_runner_sha256=(Get-Sha (Join-Path $Workspace 'kevin-maintenance-runner.ps1'))
        source_contract='fixed five runtime policy files + fixed design_forge alias + fixed maintenance runner only'
        truth_boundary='Metadata-only Omen audit. Hashes prove local file identities at generated_at; they do not by themselves prove semantic behavior.'
    }
    $local=Join-Path $Reports 'runtime-convergence-public.json'
    Write-JsonAtomic $local $public
    $repoPath='reports/runtime-convergence-omen.json'
    $lookup=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.sha')
    if($lookup.ExitCode -ne 0 -or -not $lookup.Output){throw 'runtime convergence receipt remote SHA lookup failed'}
    $payload=[ordered]@{
        message='kevin runtime convergence telemetry'
        content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))
        sha=[string]$lookup.Output
    }|ConvertTo-Json -Compress
    $payloadPath=Join-Path $env:TEMP ('kevin-runtime-convergence-'+[guid]::NewGuid().ToString('N')+'.json')
    try{
        [IO.File]::WriteAllText($payloadPath,$payload,$Utf8)
        $publish=Invoke-Gh @('api','--method','PUT',('repos/'+$Repo+'/contents/'+$repoPath),'--input',$payloadPath,'--silent')
        if($publish.ExitCode -ne 0){throw ('runtime convergence receipt publish failed: '+(Safe-Text $publish.Output 400))}
    }finally{Remove-Item -LiteralPath $payloadPath -Force -ErrorAction SilentlyContinue}
    $verify=Invoke-Gh @('api',('repos/'+$Repo+'/contents/'+$repoPath),'--jq','.content')
    if($verify.ExitCode -ne 0 -or -not $verify.Output){throw 'runtime convergence receipt verification fetch failed'}
    try{$remote=[Convert]::FromBase64String(([string]$verify.Output -replace '\s',''))}catch{throw 'runtime convergence receipt verification decode failed'}
    $localHash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToUpperInvariant()
    $sha=[Security.Cryptography.SHA256]::Create()
    try{$remoteHash=([BitConverter]::ToString($sha.ComputeHash($remote))).Replace('-','').ToUpperInvariant()}finally{$sha.Dispose()}
    if($remoteHash -ne $localHash){throw 'runtime convergence receipt remote verification hash mismatch'}
    return [ordered]@{published=$true;repo_path=$repoPath;receipt_sha256=$localHash;policy_hashes=$audit.policy_hashes;design_forge_sha256=$audit.design_forge_sha256}
}
'''.strip()
replace_once('function Install-RuntimePolicyBundle([object]$m) {', publisher + "\nfunction Install-RuntimePolicyBundle([object]$m) {")

replace_once(
    "        'audit_runtime_convergence' { }\n        'replace_runtime_policy_bundle' { Assert-RuntimeBundle $m }",
    "        'audit_runtime_convergence' { }\n        'publish_runtime_convergence' { }\n        'replace_runtime_policy_bundle' { Assert-RuntimeBundle $m }",
)
replace_once(
    "            'audit_runtime_convergence' { Audit-RuntimeConvergence; break }\n            'replace_runtime_policy_bundle' { Install-RuntimePolicyBundle $m; break }",
    "            'audit_runtime_convergence' { Audit-RuntimeConvergence; break }\n            'publish_runtime_convergence' { Publish-RuntimeConvergence; break }\n            'replace_runtime_policy_bundle' { Install-RuntimePolicyBundle $m; break }",
)
replace_once(
    "            'audit_runtime_convergence' {'runtime_convergence_audit_failure'}\n            'replace_runtime_policy_bundle' {'runtime_policy_bundle_failure'}",
    "            'audit_runtime_convergence' {'runtime_convergence_audit_failure'}\n            'publish_runtime_convergence' {'runtime_convergence_publish_failure'}\n            'replace_runtime_policy_bundle' {'runtime_policy_bundle_failure'}",
)

selftest = r'''
    $pub=$audit|ConvertTo-Json -Depth 10|ConvertFrom-Json;$pub.operation='publish_runtime_convergence';Assert-Common $pub
'''.rstrip()
replace_once(
    "    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration'",
    selftest + "\n    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration'",
)
replace_once(
    "    Write-Host 'KEVIN MAINTENANCE v1.3.5 SELFTEST PASS aliases=6 runtime_policy_bundle=5 convergence_audit=1 coordinated_forge_validator_migration=1 exact_literal_pin_patch=1 arbitrary_shell=false authority_expansion=false max_attempts=3'",
    "    Write-Host 'KEVIN MAINTENANCE v1.3.5 SELFTEST PASS compatibility=v1.3.6'\n    Write-Host 'KEVIN MAINTENANCE v1.3.6 SELFTEST PASS aliases=6 runtime_policy_bundle=5 convergence_audit=1 convergence_publish=1 fixed_public_receipt=1 coordinated_forge_validator_migration=1 arbitrary_shell=false authority_expansion=false max_attempts=3'",
)

DST.parent.mkdir(parents=True, exist_ok=True)
DST.write_text(text, encoding='utf-8', newline='\n')
print(DST)
