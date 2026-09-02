param()
$ErrorActionPreference='Stop'
$RepoRoot=Split-Path -Parent $PSScriptRoot
$Baseline=Join-Path $RepoRoot 'control-plane/skill-lab/kevin-skill-lab-v1.0.5.ps1'
$Candidate=Join-Path $RepoRoot 'control-plane/skill-lab/kevin-skill-lab-v1.0.6.ps1'
$Engine=(Get-Process -Id $PID).Path
$Utf8=New-Object Text.UTF8Encoding($false)
$TempRoot=Join-Path ([IO.Path]::GetTempPath()) ('kevin-replay-proof-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $TempRoot|Out-Null
$script:Cases=0
function Assert($Condition,[string]$Message){if(-not$Condition){throw $Message}}
function Case([string]$Name,[scriptblock]$Body){& $Body;$script:Cases++;Write-Host ('PASS '+$Name)}
function Put([string]$Path,[string]$Text){[IO.File]::WriteAllText($Path,$Text,$Utf8)}
function Json($Object){ConvertTo-Json -InputObject $Object -Depth 50}
function Digest([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}

function Exercise([string]$Source,[bool]$Fixed){
    $Root=Join-Path $TempRoot $(if($Fixed){'candidate'}else{'baseline'})
    New-Item -ItemType Directory -Path $Root|Out-Null
    $Runner=Join-Path $Root 'kevin-skill-lab.ps1'
    Copy-Item -LiteralPath $Source -Destination $Runner
    function Tick {
        $oldPreference=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$out=(& $Engine -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Runner 2>&1|Out-String);$code=$LASTEXITCODE}finally{$ErrorActionPreference=$oldPreference}
        Assert ($code-eq0) ('Unexpected runner error: '+$out)
        $out
    }
    [void](Tick)
    $Ready=Join-Path $Root 'reports/action-era/skills/ready'
    $Done=Join-Path $Root 'reports/action-era/skills/done'
    $Queue=Join-Path $Root 'reports/action-era/queue/ready'
    $QueueDone=Join-Path $Root 'reports/action-era/queue/done'
    $Registry=Join-Path $Root 'reports/capabilities/composite-skills.json'
    $Manifest=[ordered]@{schema=1;kind='kevin-composite-skill';id='replay-fixture';version='1';name='Replay fixture';authority='GREEN';steps=@([ordered]@{operation='create_text';payload=[ordered]@{filename='replay.txt';content='Preserve the original completed receipt.'}})}
    $ManifestText=Json $Manifest
    # This is the real relay's id--version.json naming convention, not a
    # different test filename that accidentally avoids the overwrite.
    $Staged=Join-Path $Ready 'replay-fixture--1.json'
    Put $Staged $ManifestText
    [void](Tick)
    $orders=@(Get-ChildItem -LiteralPath $Queue -File -Filter '*.json')
    Assert ($orders.Count-eq1) 'Expected one primitive action'
    $order=Get-Content -LiteralPath $orders[0].FullName -Raw|ConvertFrom-Json
    Assert ($order.operation-ceq'create_text'-and$order.authority-ceq'GREEN') 'Fixture operator is GREEN text only'
    $Artifact=Join-Path $Root 'replay.txt'
    Put $Artifact ([string]$order.payload.content)
    Assert ([IO.File]::ReadAllText($Artifact)-ceq'Preserve the original completed receipt.') 'Independent text verification failed'
    $order|Add-Member NoteProperty status 'DONE'
    $order|Add-Member NoteProperty result ([pscustomobject]@{status='DONE';completed_at=(Get-Date).ToString('o');output_name='replay.txt';sha256=(Digest $Artifact);bytes=(Get-Item $Artifact).Length})
    Put (Join-Path $QueueDone $orders[0].Name) (Json $order)
    Remove-Item -LiteralPath $orders[0].FullName
    [void](Tick)
    $Receipt=Join-Path $Done 'replay-fixture--1.json'
    $OriginalReceipt=[IO.File]::ReadAllText($Receipt)
    $ReceiptHash=Digest $Receipt;$RegistryHash=Digest $Registry;$ArtifactHash=Digest $Artifact
    Assert (($OriginalReceipt|ConvertFrom-Json).status-ceq'PROVEN') 'Fixture never completed'
    function Assert-NoNewActions {
        Assert ((Digest $Registry)-ceq$RegistryHash) 'Replay changed the learned registry'
        Assert ((Digest $Artifact)-ceq$ArtifactHash) 'Replay changed the primitive artifact'
        Assert (@(Get-ChildItem -LiteralPath $Queue -File).Count-eq0) 'Replay queued a duplicate primitive'
        Assert (@(Get-ChildItem -LiteralPath $QueueDone -File).Count-eq1) 'Replay created another primitive receipt'
    }
    if(-not$Fixed){
        Case 'v1.0.5 reproduces original receipt loss with the relay filename' {
            Put $Staged $ManifestText
            $out=Tick
            Assert ($out-match'DUPLICATE already proven') 'Expected legacy duplicate response'
            Assert ((Digest $Receipt)-cne$ReceiptHash) 'Baseline no longer reproduces receipt overwrite'
            $lost=Get-Content -LiteralPath $Receipt -Raw|ConvertFrom-Json
            Assert ($lost.status-ceq'ALREADY_PROVEN'-and@($lost.step_results).Count-eq0) 'Unexpected legacy overwrite shape'
            Assert-NoNewActions
        }
        return
    }
    Case 'relay-named replay preserves original receipt bytes and evidence' {
        Put $Staged $ManifestText
        $out=Tick
        Assert ($out-match'DUPLICATE already proven') 'Replay did not reuse the existing proof'
        Assert ((Digest $Receipt)-ceq$ReceiptHash) 'Original completed proof changed'
        Assert (@(Get-ChildItem -LiteralPath $Done -File).Count-eq1) 'Replay invented a completion receipt'
        Assert (-not(Test-Path -LiteralPath $Staged)) 'Duplicate was not consumed'
        Assert-NoNewActions
    }
    Case 'differently named replay also preserves the one original receipt' {
        $other=Join-Path $Ready 'another-filename.json'
        Put $other $ManifestText
        [void](Tick)
        Assert (-not(Test-Path -LiteralPath $other)) 'Alternate duplicate was not consumed'
        Assert ((Digest $Receipt)-ceq$ReceiptHash) 'Alternate filename changed original proof'
        Assert (@(Get-ChildItem -LiteralPath $Done -File).Count-eq1) 'Alternate filename invented another completion'
        Assert-NoNewActions
    }
    Case 'missing original receipt cannot masquerade as a completed replay' {
        Remove-Item -LiteralPath $Receipt
        Put $Staged $ManifestText
        $out=Tick
        Assert ($out-match'SKILL_REPLAY_PROOF_MISSING_PRESERVED'-and$out-notmatch'DUPLICATE already proven') 'Missing proof was accepted'
        Assert (-not(Test-Path -LiteralPath $Receipt)) 'Missing proof was fabricated'
        Assert-NoNewActions
        Put $Receipt $OriginalReceipt
    }
    function Reject-Proof([string]$Invalid){
        Put $Receipt $Invalid;$badHash=Digest $Receipt
        Put $Staged $ManifestText
        $out=Tick
        Assert ($out-match'SKILL_REPLAY_PROOF_'-and$out-notmatch'DUPLICATE already proven') 'Invalid proof was accepted'
        Assert ((Digest $Receipt)-ceq$badHash) 'Rejected proof evidence was overwritten'
        Assert-NoNewActions
        Put $Receipt $OriginalReceipt
    }
    Case 'truncated original proof remains untouched' {Reject-Proof '{"schema":'}
    Case 'mismatched recorded proof hash is rejected' {$p=$OriginalReceipt|ConvertFrom-Json;$p.proof_sha256=('0'*64);Reject-Proof (Json $p)}
    Case 'legacy already-proven stub cannot replace a proven receipt' {$p=$OriginalReceipt|ConvertFrom-Json;$p.status='ALREADY_PROVEN';$p.step_results=@();Reject-Proof (Json $p)}
    Case 'single-element proof array cannot be silently unwrapped' {Reject-Proof ('['+$OriginalReceipt+']')}
    Case 'missing step evidence is rejected' {$p=$OriginalReceipt|ConvertFrom-Json;$p.step_results=@();Reject-Proof (Json $p)}
    Case 'identity collision preserves proof and artifacts' {
        $collision=$ManifestText|ConvertFrom-Json;$collision.steps[0].payload.content='Different task'
        Put $Staged (Json $collision)
        $out=Tick
        Assert ($out-match'proven manifest conflict') 'Identity collision accepted'
        Assert ((Digest $Receipt)-ceq$ReceiptHash) 'Collision changed original receipt'
        Assert-NoNewActions
    }
}
try{
    Exercise $Baseline $false
    Exercise $Candidate $true
    $summary=[ordered]@{schema=1;kind='kevin-skill-replay-candidate-proof';tests_passed=$script:Cases;engine=$PSVersionTable.PSVersion.ToString();candidate_sha256=(Digest $Candidate);baseline_sha256=(Digest $Baseline);baseline_overwrite_reproduced=$true;relay_filename_exercised=$true;original_receipt_bytes_preserved=$true;authority_delta='NONE';omen_runtime_proven=$false}
    Write-Host ('PROOF_JSON='+(ConvertTo-Json -InputObject $summary -Depth 10 -Compress))
}finally{Remove-Item -LiteralPath $TempRoot -Recurse -Force}
exit 0
