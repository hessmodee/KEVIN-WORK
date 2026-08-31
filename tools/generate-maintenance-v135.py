from pathlib import Path

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.4.ps1')
DST = Path('control-plane/maintenance/generated/kevin-maintenance-runner-v1.3.5.ps1')
text = SRC.read_text(encoding='utf-8')


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'expected exactly one marker, found {count}: {old[:100]!r}')
    text = text.replace(old, new, 1)


replace_once("version='1.3.4'", "version='1.3.5'")
replace_once(
    "@('replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','replace_runtime_policy_bundle')",
    "@('replace_pinned_component','restart_ui_bridge','audit_runtime_convergence','replace_runtime_policy_bundle','migrate_design_forge_v40')",
)

assert_migration = r'''
function Assert-ForgeMigration([object]$m) {
    if([string]$m.target_alias -ne 'design_forge_runner'){throw 'Forge migration target alias mismatch'}
    if([string]$m.source_path -ne 'control-plane/forge/kevin-design-forge-v4.0.ps1'){throw 'Forge migration source path mismatch'}
    foreach($n in @('source_sha256','expected_forge_current_sha256','expected_forge_after_sha256','expected_benchmark_current_sha256')){
        if([string]$m.$n -notmatch '^[A-Fa-f0-9]{64}$'){throw ($n+' invalid')}
    }
    if(([string]$m.source_sha256).ToUpperInvariant() -ne ([string]$m.expected_forge_after_sha256).ToUpperInvariant()){throw 'Forge migration source hash must equal after hash'}
    if(([string]$m.expected_forge_current_sha256).ToUpperInvariant() -eq ([string]$m.expected_forge_after_sha256).ToUpperInvariant()){throw 'Forge migration requires a real hash transition'}
}

function Get-LiteralOccurrenceCount([string]$Text,[string]$Needle) {
    if(-not $Needle){return 0}
    $count=0;$offset=0
    while($true){$i=$Text.IndexOf($Needle,$offset,[StringComparison]::OrdinalIgnoreCase);if($i -lt 0){break};$count++;$offset=$i+$Needle.Length}
    return $count
}
function Get-ForgePinPatchedBenchmark([string]$Text,[string]$Before,[string]$After) {
    $beforeCount=Get-LiteralOccurrenceCount $Text $Before
    $afterCount=Get-LiteralOccurrenceCount $Text $After
    if($beforeCount -ne 1){throw ('Benchmark must contain old Forge pin exactly once; count='+$beforeCount)}
    if($afterCount -ne 0){throw ('Benchmark already contains candidate Forge pin; count='+$afterCount)}
    return [regex]::Replace($Text,[regex]::Escape($Before),$After,[Text.RegularExpressions.RegexOptions]::IgnoreCase,[TimeSpan]::FromSeconds(1))
}
'''.strip()
replace_once('function Assert-Restart([object]$m) {', assert_migration + "\nfunction Assert-Restart([object]$m) {")

migration_function = r'''
function Migrate-DesignForgeV40([object]$m) {
    Assert-ForgeMigration $m
    $forgeSpec=Get-AliasSpec 'design_forge_runner'
    $forgeTarget=[string]$forgeSpec.Target
    $benchTarget=Join-Path $Workspace 'kevin-benchmark-v1.ps1'
    if(-not(Test-Path -LiteralPath $forgeTarget -PathType Leaf)){throw 'Forge target missing'}
    if(-not(Test-Path -LiteralPath $benchTarget -PathType Leaf)){throw 'Benchmark target missing'}

    $forgeBefore=Get-Sha $forgeTarget
    $benchBefore=Get-Sha $benchTarget
    $expectedForgeBefore=([string]$m.expected_forge_current_sha256).ToUpperInvariant()
    $expectedForgeAfter=([string]$m.expected_forge_after_sha256).ToUpperInvariant()
    $expectedBenchBefore=([string]$m.expected_benchmark_current_sha256).ToUpperInvariant()
    if($forgeBefore -ne $expectedForgeBefore){throw ('Forge expected-current mismatch actual='+$forgeBefore)}
    if($benchBefore -ne $expectedBenchBefore){throw ('Benchmark expected-current mismatch actual='+$benchBefore)}

    $forgeBytes=Get-RemoteBytes ([string]$m.source_path) 'design_forge_runner'
    $forgeStage=Join-Path $StageRoot ([string]$m.id+'.forge.ps1')
    [IO.File]::WriteAllBytes($forgeStage,$forgeBytes)
    if((Get-Sha $forgeStage) -ne $expectedForgeAfter){throw 'Forge staged hash mismatch'}
    Parse-PowerShell $forgeStage
    Invoke-FixedSelfTest 'design_forge_runner' $forgeStage

    $benchText=[IO.File]::ReadAllText($benchTarget)
    $benchPatched=Get-ForgePinPatchedBenchmark $benchText $expectedForgeBefore $expectedForgeAfter
    $benchStage=Join-Path $StageRoot ([string]$m.id+'.benchmark.ps1')
    [IO.File]::WriteAllText($benchStage,$benchPatched,$Utf8)
    Parse-PowerShell $benchStage
    $benchAfter=Get-Sha $benchStage
    if($benchAfter -eq $benchBefore){throw 'Benchmark pin migration produced no byte change'}
    if((Get-LiteralOccurrenceCount ([IO.File]::ReadAllText($benchStage)) $expectedForgeBefore) -ne 0){throw 'Old Forge pin remained in staged Benchmark'}
    if((Get-LiteralOccurrenceCount ([IO.File]::ReadAllText($benchStage)) $expectedForgeAfter) -ne 1){throw 'New Forge pin missing or duplicated in staged Benchmark'}

    $backupDir=Join-Path $BackupRoot ([string]$m.id)
    New-Item -ItemType Directory -Force $backupDir|Out-Null
    $forgeBackup=Join-Path $backupDir 'kevin-design-forge.ps1'
    $benchBackup=Join-Path $backupDir 'kevin-benchmark-v1.ps1'
    Copy-Item -LiteralPath $forgeTarget -Destination $forgeBackup -Force
    Copy-Item -LiteralPath $benchTarget -Destination $benchBackup -Force

    try {
        foreach($pair in @(@($forgeStage,$forgeTarget),@($benchStage,$benchTarget))){
            $tmp=$pair[1]+'.typed-'+[guid]::NewGuid().ToString('N')
            Copy-Item -LiteralPath $pair[0] -Destination $tmp -Force
            Move-Item -LiteralPath $tmp -Destination $pair[1] -Force
        }
        if((Get-Sha $forgeTarget) -ne $expectedForgeAfter){throw 'Installed Forge hash mismatch'}
        if((Get-Sha $benchTarget) -ne $benchAfter){throw 'Installed Benchmark hash mismatch'}
        Parse-PowerShell $forgeTarget
        Parse-PowerShell $benchTarget
        Invoke-FixedSelfTest 'design_forge_runner' $forgeTarget
        Assert-Benchmark30
        return [ordered]@{
            changed=$true
            forge_before=$forgeBefore
            forge_after=(Get-Sha $forgeTarget)
            benchmark_before=$benchBefore
            benchmark_after=(Get-Sha $benchTarget)
            benchmark_pin_change='exact literal old Forge SHA -> new Forge SHA; one occurrence only'
            rollback_available=$true
        }
    } catch {
        Copy-Item -LiteralPath $forgeBackup -Destination $forgeTarget -Force
        Copy-Item -LiteralPath $benchBackup -Destination $benchTarget -Force
        try { Assert-Benchmark30 } catch { }
        throw ('coordinated Forge migration rollback completed: '+$_.Exception.Message)
    }
}
'''.strip()
replace_once('function Restart-UiBridge([object]$m) {', migration_function + "\nfunction Restart-UiBridge([object]$m) {")

replace_once(
    "        'replace_runtime_policy_bundle' { Assert-RuntimeBundle $m }\n        default { throw 'operation not allowlisted' }",
    "        'replace_runtime_policy_bundle' { Assert-RuntimeBundle $m }\n        'migrate_design_forge_v40' { Assert-ForgeMigration $m }\n        default { throw 'operation not allowlisted' }",
)
replace_once(
    "            'replace_runtime_policy_bundle' { Install-RuntimePolicyBundle $m; break }\n        }",
    "            'replace_runtime_policy_bundle' { Install-RuntimePolicyBundle $m; break }\n            'migrate_design_forge_v40' { Migrate-DesignForgeV40 $m; break }\n        }",
)
replace_once(
    "            'replace_runtime_policy_bundle' {'runtime_policy_bundle_failure'}\n            default {'typed_replace_failure'}",
    "            'replace_runtime_policy_bundle' {'runtime_policy_bundle_failure'}\n            'migrate_design_forge_v40' {'forge_validator_migration_failure'}\n            default {'typed_replace_failure'}",
)

selftest_insert = r'''
    $mig=[pscustomobject]@{schema=3;kind='kevin-self-maintenance-manifest';id='selftest-forge-migration';authority_class='GREEN';authority_delta='NONE';production_effect='NONE';owner_policy=$OwnerPolicy;preauthorized=$true;operation='migrate_design_forge_v40';target_alias='design_forge_runner';source_path='control-plane/forge/kevin-design-forge-v4.0.ps1';source_sha256=('C'*64);expected_forge_current_sha256=('B'*64);expected_forge_after_sha256=('C'*64);expected_benchmark_current_sha256=('D'*64);expires_at=(Get-Date).AddMinutes(10).ToString('o')}
    Assert-Common $mig;Assert-ForgeMigration $mig
    $fake=('prefix '+('B'*64)+' suffix')
    $patched=Get-ForgePinPatchedBenchmark $fake ('B'*64) ('C'*64)
    if((Get-LiteralOccurrenceCount $patched ('B'*64)) -ne 0 -or (Get-LiteralOccurrenceCount $patched ('C'*64)) -ne 1){throw 'Forge pin patch helper selftest failed'}
    $blocked=$false;try{Get-ForgePinPatchedBenchmark ($fake+' '+('B'*64)) ('B'*64) ('C'*64)|Out-Null}catch{$blocked=$true};if(-not$blocked){throw 'duplicate old Forge pin accepted'}
'''.rstrip()
replace_once(
    "    $bad=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.target_alias='supervisor';$blocked=$false;try{Assert-Replace $bad}catch{$blocked=$true};if(-not$blocked){throw 'unknown alias accepted'}",
    selftest_insert + "\n    $bad=$base|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.target_alias='supervisor';$blocked=$false;try{Assert-Replace $bad}catch{$blocked=$true};if(-not$blocked){throw 'unknown alias accepted'}",
)
replace_once(
    "    Write-Host 'KEVIN MAINTENANCE v1.3.4 SELFTEST PASS aliases=6 runtime_policy_bundle=5 convergence_audit=1 arbitrary_shell=false authority_expansion=false max_attempts=3'",
    "    Write-Host 'KEVIN MAINTENANCE v1.3.4 SELFTEST PASS compatibility=v1.3.5'\n    Write-Host 'KEVIN MAINTENANCE v1.3.5 SELFTEST PASS aliases=6 runtime_policy_bundle=5 convergence_audit=1 coordinated_forge_validator_migration=1 exact_literal_pin_patch=1 arbitrary_shell=false authority_expansion=false max_attempts=3'",
)

DST.parent.mkdir(parents=True, exist_ok=True)
DST.write_text(text, encoding='utf-8', newline='\n')
print(DST)
