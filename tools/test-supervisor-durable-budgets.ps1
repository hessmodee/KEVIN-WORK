param([string]$Runner='control-plane/autonomy/kevin-supervisor-v1.8.7.ps1')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$Utf8=New-Object Text.UTF8Encoding($false)
$MaxSameFingerprintTurns=3;$MinRepeatMinutes=15
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner),[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0].Message}
foreach($name in @('Write-Utf8Atomic','Write-JsonAtomic','Get-TextSha','Read-State','Get-ItemBudget','Record-ItemAttempt','Get-ItemFingerprint')){
    $fn=$ast.Find({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$name},$true)
    if(-not$fn){throw "Missing function $name"}
    . ([scriptblock]::Create($fn.Extent.Text))
}
$root=Join-Path $env:RUNNER_TEMP ('kevin-budget-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $root|Out-Null
$StatePath=Join-Path $root 'state.json';$SelectionPath=Join-Path $root 'selection.json'
try{
    $state=Read-State;$now=[datetime]'2026-09-02T00:00:00Z'
    foreach($round in 1..3){
        foreach($id in @('work-a','work-b')){
            $state=Read-State
            $budget=Get-ItemBudget $state $id ('finger-'+$id) $now
            if($budget.reason -or $budget.turns-ne($round-1)){throw 'alternating item history lost'}
            $state=Record-ItemAttempt $state $id ('finger-'+$id) ($budget.turns+1) $now 'IN_PROGRESS'
            # Simulate process failure/restart immediately after reservation.
            $state=Read-State
            $again=Get-ItemBudget $state $id ('finger-'+$id) $now.AddMinutes(1)
            if(-not$again.reason){throw 'restart allowed immediate duplicate attempt'}
        }
        $now=$now.AddMinutes(16)
    }
    foreach($id in @('work-a','work-b')){
        $budget=Get-ItemBudget (Read-State) $id ('finger-'+$id) $now.AddHours(2)
        if($budget.turns-ne3 -or $budget.reason-ne'BOUNDED_TURNS_REQUIRES_NEW_EVIDENCE'){throw 'alternating work bypassed exhausted budget'}
    }
    if((Get-ItemBudget (Read-State) 'work-b' 'new-evidence' $now).turns-ne0){throw 'changed item cannot reopen'}
    if((Get-ItemBudget (Read-State) 'work-a' 'finger-work-a' $now).turns-ne3){throw 'other item change reset exhausted history'}
    $items=Join-Path $root 'items.json'
    $doc=[ordered]@{updated_at='old';items=@([ordered]@{id='work-a';status='READY';next_action='test'},[ordered]@{id='work-b';status='READY'})}
    Write-JsonAtomic $items $doc
    $fp=Get-ItemFingerprint @{items=$items} 'work-a'
    $doc.updated_at='new';$doc.items[1].status='COMPLETE';Write-JsonAtomic $items $doc
    if((Get-ItemFingerprint @{items=$items} 'work-a')-ne$fp){throw 'unrelated work reset material fingerprint'}
    [IO.File]::WriteAllText($StatePath,'{broken',$Utf8)
    $blocked=$false;try{$null=Read-State}catch{$blocked=$true}
    if(-not$blocked){throw 'corrupt state reset budget'}
    Remove-Item $StatePath
    [IO.File]::WriteAllText($SelectionPath,'{}',$Utf8)
    $blocked=$false;try{$null=Read-State}catch{$blocked=$true}
    if(-not$blocked){throw 'missing established history reset budget'}
    Write-Host 'DURABLE_BUDGET_PASS alternating_items=true restart=true before_effect=true corrupt_state_rejected=true missing_history_rejected=true unrelated_changes_preserve_budget=true'
}finally{Remove-Item -LiteralPath $root -Recurse -Force}
