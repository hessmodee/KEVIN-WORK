param(
    [string]$Runner = 'control-plane/autonomy/kevin-supervisor-v1.8.8.ps1',
    [ValidateSet('RequireConformance', 'CharacterizeBaseline')]
    [string]$Mode = 'RequireConformance'
)
# Evaluation only. Extract selected functions; NEVER dot-source the runner or invoke its cycle.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)
$MaxSameFingerprintTurns = 3
$MinRepeatMinutes = 15
$SourceSha = (Get-FileHash -LiteralPath $Runner -Algorithm SHA256).Hash
$BaselineSha = 'F5D8C9740D384CC576D4BD70A3940B51AA1FCF398C7085E59DB20C01E9180138'
if ($Mode -eq 'CharacterizeBaseline' -and $SourceSha -ne $BaselineSha) {
    throw 'Characterization permits only the exact known v1.8.8 source; candidate acceptance must use RequireConformance'
}
$tokens = $null; $parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Runner parse failure' }
foreach ($name in @('Write-Utf8Atomic', 'Write-JsonAtomic', 'Get-TextSha', 'Read-State', 'Get-ItemBudget', 'Record-ItemAttempt', 'Get-ItemFingerprint')) {
    $functions = @($ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true))
    if ($functions.Count -ne 1) { throw "Expected exactly one function: $name" }
    . ([scriptblock]::Create($functions[0].Extent.Text))
}
$Root = Join-Path ([IO.Path]::GetTempPath()) ('kevin-history-contract-' + [guid]::NewGuid().ToString('N'))
$StatePath = Join-Path $Root 'state.json'
$SelectionPath = Join-Path $Root 'selection.json'
$ItemsPath = Join-Path $Root 'items.json'
$Now = [datetime]'2026-09-02T00:00:00Z'
$FingerprintA = 'A' * 64
$FingerprintB = 'B' * 64
$results = New-Object 'Collections.Generic.List[object]'

function Assert-Contract([bool]$Condition, [string]$Code) {
    if (-not $Condition) { throw ('CONTRACT:' + $Code) }
}
function Set-Fixture([int]$Turns = 3, [string]$Fingerprint = $FingerprintA) {
    Write-JsonAtomic $StatePath ([ordered]@{schema=2;items=@([ordered]@{
        id='fixture-work-a';fingerprint=$Fingerprint;turns=$Turns;
        last_turn_at=$Now.AddHours(-2).ToString('o');status='AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF'
    })})
}
function Assert-ReadRejected([string]$Code) {
    $rejected = $false
    try { $null = Read-State } catch { $rejected = $true }
    Assert-Contract $rejected $Code
}
function Invoke-Case([string]$Name, [bool]$KnownBaselineViolation, [scriptblock]$Body) {
    foreach ($path in @($StatePath, $SelectionPath, $ItemsPath)) {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    $passed = $true; $failure = ''
    try { & $Body } catch {
        $passed = $false
        $failure = [string]$_.Exception.Message
        # Harness errors must fail CI, never masquerade as the expected contract violation.
        if (-not $failure.StartsWith('CONTRACT:')) { throw }
    }
    $results.Add([pscustomobject]@{case=$Name;conforms=$passed;known_baseline_violation=$KnownBaselineViolation;failure=$failure})
    Write-Host (('HISTORY_CASE ' + $Name + ' conforms=' + $passed + ' ' + $failure).Trim())
}

New-Item -ItemType Directory -Path $Root | Out-Null
try {
    Invoke-Case 'same-fingerprint-exhaustion' $false {
        Set-Fixture
        $budget = Get-ItemBudget (Read-State) 'fixture-work-a' $FingerprintA $Now
        Assert-Contract ($budget.turns -eq 3 -and [bool]$budget.reason) 'EXHAUSTION_LOST'
    }
    Invoke-Case 'fingerprint-change-does-not-reopen' $true {
        Set-Fixture
        $budget = Get-ItemBudget (Read-State) 'fixture-work-a' $FingerprintB $Now
        Assert-Contract ($budget.turns -ge 3 -and [bool]$budget.reason) 'FINGERPRINT_RESET_WITHOUT_VALIDATED_EVIDENCE'
    }
    Invoke-Case 'prose-edit-does-not-reopen' $true {
        $doc = [ordered]@{items=@([ordered]@{id='fixture-work-a';status='READY';next_action='fixture plan A';completion_evidence='';authority_class='GREEN'})}
        Write-JsonAtomic $ItemsPath $doc
        $before = Get-ItemFingerprint @{items=$ItemsPath} 'fixture-work-a'
        Set-Fixture 3 $before
        $doc.items[0].next_action = 'fixture plan B, no evidence change'
        Write-JsonAtomic $ItemsPath $doc
        $after = Get-ItemFingerprint @{items=$ItemsPath} 'fixture-work-a'
        $budget = Get-ItemBudget (Read-State) 'fixture-work-a' $after $Now
        Assert-Contract ($budget.turns -ge 3 -and [bool]$budget.reason) 'PROSE_REOPENS_EXHAUSTED_ITEM'
    }
    Invoke-Case 'a-b-a-preserves-earlier-exhaustion' $true {
        Set-Fixture
        $state = Read-State
        $budget = Get-ItemBudget $state 'fixture-work-a' $FingerprintB $Now
        # Only emulate the actual legacy reservation if its budget gate allowed it.
        if (-not $budget.reason) {
            $null = Record-ItemAttempt $state 'fixture-work-a' $FingerprintB ($budget.turns + 1) $Now 'IN_PROGRESS'
        }
        $replayed = Get-ItemBudget (Read-State) 'fixture-work-a' $FingerprintA $Now.AddHours(2)
        Assert-Contract ($replayed.turns -ge 3 -and [bool]$replayed.reason) 'EARLIER_EPOCH_ERASED'
    }
    Invoke-Case 'alternating-items-preserve-budget' $false {
        Set-Fixture
        $null = Record-ItemAttempt (Read-State) 'fixture-work-b' $FingerprintB 1 $Now 'IN_PROGRESS'
        $budget = Get-ItemBudget (Read-State) 'fixture-work-a' $FingerprintA $Now.AddHours(2)
        Assert-Contract ($budget.turns -eq 3 -and [bool]$budget.reason) 'ALTERNATION_RESET'
    }
    Invoke-Case 'reservation-survives-reload-before-effect' $false {
        Set-Fixture 0
        $null = Record-ItemAttempt (Read-State) 'fixture-work-a' $FingerprintA 1 $Now 'IN_PROGRESS'
        $budget = Get-ItemBudget (Read-State) 'fixture-work-a' $FingerprintA $Now.AddMinutes(1)
        Assert-Contract ($budget.turns -eq 1 -and [bool]$budget.reason) 'RESERVATION_NOT_PERSISTED'
    }
    Invoke-Case 'unrelated-item-and-timestamp-preserve-fingerprint' $false {
        $doc = [ordered]@{updated_at='old';items=@([ordered]@{id='fixture-work-a';status='READY'},[ordered]@{id='fixture-work-b';status='READY'})}
        Write-JsonAtomic $ItemsPath $doc
        $before = Get-ItemFingerprint @{items=$ItemsPath} 'fixture-work-a'
        $doc.updated_at = 'new'; $doc.items[1].status = 'COMPLETE'
        Write-JsonAtomic $ItemsPath $doc
        Assert-Contract ((Get-ItemFingerprint @{items=$ItemsPath} 'fixture-work-a') -eq $before) 'UNRELATED_EDIT_CHANGED_IDENTITY'
    }
    Invoke-Case 'corrupt-json-fails-closed' $false {
        [IO.File]::WriteAllText($StatePath, '{broken', $Utf8)
        Assert-ReadRejected 'CORRUPT_STATE_ACCEPTED'
    }
    Invoke-Case 'missing-state-after-selection-fails-closed' $false {
        Write-JsonAtomic $SelectionPath @{}
        Assert-ReadRejected 'MISSING_ESTABLISHED_STATE_ACCEPTED'
    }
    Invoke-Case 'missing-state-without-bootstrap-fails-closed' $true {
        # No explicit first-install authorization exists in this fixture.
        Assert-ReadRejected 'ABSENT_HISTORY_TREATED_AS_NEW_INSTALL'
    }
    Invoke-Case 'empty-established-history-fails-closed' $true {
        [IO.File]::WriteAllText($StatePath, '{"schema":2,"items":[]}', $Utf8)
        # Empty established history is indistinguishable from lost history without a verified bootstrap marker.
        Assert-ReadRejected 'EMPTY_ESTABLISHED_HISTORY_ACCEPTED'
    }
    Invoke-Case 'invalid-history-time-fails-closed' $true {
        Set-Fixture
        $doc = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        $doc.items[0].last_turn_at = 'not-a-timestamp'
        Write-JsonAtomic $StatePath $doc
        Assert-ReadRejected 'INVALID_HISTORY_TIME_ACCEPTED_AT_LOAD'
    }
    Invoke-Case 'duplicate-history-id-fails-closed' $false {
        Set-Fixture
        $doc = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        $doc.items = @($doc.items[0], $doc.items[0])
        Write-JsonAtomic $StatePath $doc
        Assert-ReadRejected 'DUPLICATE_ID_ACCEPTED'
    }
    Invoke-Case 'negative-count-fails-closed' $false {
        Set-Fixture -1
        Assert-ReadRejected 'NEGATIVE_COUNT_ACCEPTED'
    }
    $violations = @($results | Where-Object { -not $_.conforms })
    $summary = [ordered]@{schema=1;kind='kevin-history-contract-evaluation';mode=$Mode;source_sha256=$SourceSha;cases=$results.Count;contract_violations=$violations.Count;runtime_repaired=$false;owner_outcome_proven=$false;tests_only=$true;results=@($results.ToArray())}
    Write-Host ($summary | ConvertTo-Json -Depth 10 -Compress)
    if ($Mode -eq 'RequireConformance') {
        if ($violations.Count) { throw ('HISTORY_CONTRACT_NOT_CONFORMANT count=' + $violations.Count) }
        Write-Host 'HISTORY_CONTRACT_CONFORMANT tested_scope_only=true production_authorization=false'
    } else {
        foreach ($result in $results) {
            if ($result.conforms -eq $result.known_baseline_violation) { throw ('Unexpected baseline result: ' + $result.case) }
        }
        Write-Host 'BASELINE_DEFECTS_REPRODUCED runtime_conformant=false runtime_repaired=false'
    }
} finally {
    Remove-Item -LiteralPath $Root -Recurse -Force
}
