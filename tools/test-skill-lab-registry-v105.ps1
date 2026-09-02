param()
$ErrorActionPreference='Stop'
$RepoRoot=Split-Path -Parent $PSScriptRoot
$Candidate=Join-Path $RepoRoot 'control-plane/skill-lab/kevin-skill-lab-v1.0.5.ps1'
$Baseline=Join-Path $RepoRoot 'control-plane/skill-lab/kevin-skill-lab-v1.0.4.ps1'
$SkillFile=Join-Path $RepoRoot 'inbox/skills/kevin-recovery-evidence-kit-v1.json'
$Utf8=New-Object Text.UTF8Encoding($false)
$TempRoot=Join-Path ([IO.Path]::GetTempPath()) ('kevin-registry-proof-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $TempRoot|Out-Null
$script:Cases=0

function Assert($Condition,[string]$Message){if(-not$Condition){throw $Message}}
function Case([string]$Name,[scriptblock]$Body){& $Body;$script:Cases++;Write-Host ('PASS '+$Name)}
function Json($Object){return ConvertTo-Json -InputObject $Object -Depth 50}
function Put([string]$Path,[string]$Text){[IO.File]::WriteAllText($Path,$Text,$Utf8)}
function Digest([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Load-Functions([string]$Path,[string[]]$Names){
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    Assert ($errors.Count-eq0) 'PowerShell parser rejected source'
    foreach($name in $Names){
        $found=@($ast.FindAll({param($n) $n-is[Management.Automation.Language.FunctionDefinitionAst]},$true)|Where-Object{$_.Name-ceq$name})
        Assert ($found.Count-eq1) ('Expected one fixed function '+$name)
        # Return reviewed source definitions to dot-source in this test scope.
        [ScriptBlock]::Create($found[0].Extent.Text)
    }
}
foreach($definition in @(Load-Functions $Candidate @('ReadJ','C','HT','HO','RegistryTimestampValid','Assert-RegistryValid','Registry'))){. $definition}
$tokens=$null;$errors=$null
$oldAst=[Management.Automation.Language.Parser]::ParseFile($Baseline,[ref]$tokens,[ref]$errors)
$old=@($oldAst.FindAll({param($n) $n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Registry'},$true))[0]
. ([ScriptBlock]::Create(($old.Extent.Text-replace'^function Registry','function LegacyRegistry')))

$reg=Join-Path $TempRoot 'registry.json'
$sd=Join-Path $TempRoot 'done'
New-Item -ItemType Directory -Path $sd|Out-Null
function GoodRegistry {
    return [pscustomobject]@{
        schema=1;kind='kevin-composite-skill-registry';updated_at='2026-09-02T10:00:00-06:00'
        skills=@([pscustomobject]@{
            key='fixture-skill@1';id='fixture-skill';version='1';name='Fixture skill';authority='GREEN';status='PROVEN'
            manifest_sha256=('A'*64);proof_sha256=('B'*64);proven_at='2026-09-02T09:00:00-06:00'
            primitive_steps=@('create_text');result_file='fixture-skill--1.json'
        })
    }
}
function Reject-Preserved([string]$Text){
    Put $reg $Text;$before=Digest $reg;$failed=$false
    try{[void](Registry)}catch{$failed=$true;Assert ($_.Exception.Message-match'SKILL_REGISTRY_') 'Expected classified registry rejection'}
    Assert $failed 'Invalid registry was accepted'
    Assert ((Digest $reg)-ceq$before) 'Rejected registry bytes changed'
}

try {
    Case 'baseline reproduces corrupt-registry empty-history bug' {
        Put $reg '{"schema":'
        $oldResult=LegacyRegistry
        Assert (@($oldResult.skills).Count-eq0) 'Baseline no longer reproduces the documented bug'
    }
    Case 'valid legacy registry remains byte-for-byte unchanged' {
        Put $reg (Json (GoodRegistry));$before=Digest $reg;$result=Registry
        Assert (@($result.skills).Count-eq1) 'Valid learned skill lost'
        Assert ((Digest $reg)-ceq$before) 'Read mutated valid registry'
    }
    Case 'first run may initialize empty history without completed receipts' {
        Remove-Item -LiteralPath $reg
        $result=Registry
        Assert (@($result.skills).Count-eq0) 'First-run registry was not empty'
        Assert (-not(Test-Path -LiteralPath $reg)) 'Read created a registry file'
    }
    Case 'missing registry with prior evidence fails closed' {
        Put (Join-Path $sd 'prior.json') '{}';$failed=$false
        try{[void](Registry)}catch{$failed=$_.Exception.Message-eq'SKILL_REGISTRY_MISSING_WITH_PRIOR_EVIDENCE'}
        Assert $failed 'Missing history was silently initialized'
        Assert (-not(Test-Path -LiteralPath $reg)) 'Missing registry was recreated'
        Remove-Item -LiteralPath (Join-Path $sd 'prior.json')
    }
    foreach($bad in @('', 'null', '[]', '[{}]', '42', 'true', '{}', '{"schema":', '{"schema":1,"kind":"kevin-composite-skill-registry"}')){
        Case ('reject malformed/root fixture '+($script:Cases+1)) {Reject-Preserved $bad}
    }
    Case 'single-element root array cannot be unwrapped into a valid registry' {Reject-Preserved ('['+(Json (GoodRegistry))+']')}
    Case 'boolean schema rejected' {$x=GoodRegistry;$x.schema=$true;Reject-Preserved (Json $x)}
    Case 'fractional schema rejected' {$x=GoodRegistry;$x.schema=1.2;Reject-Preserved (Json $x)}
    Case 'unsupported schema rejected' {$x=GoodRegistry;$x.schema=2;Reject-Preserved (Json $x)}
    Case 'wrong kind rejected' {$x=GoodRegistry;$x.kind='other';Reject-Preserved (Json $x)}
    Case 'skills object cannot masquerade as an array' {$x=GoodRegistry;$x.skills=[pscustomobject]@{};Reject-Preserved (Json $x)}
    Case 'duplicate learned identity rejected' {$x=GoodRegistry;$x.skills=@($x.skills[0],$x.skills[0]);Reject-Preserved (Json $x)}
    Case 'case-colliding learned identity rejected' {
        $x=GoodRegistry;$second=(Json $x.skills[0])|ConvertFrom-Json;$second.id='FIXTURE-SKILL';$second.key='FIXTURE-SKILL@1'
        $x.skills=@($x.skills[0],$second);Reject-Preserved (Json $x)
    }
    Case 'mismatched key rejected' {$x=GoodRegistry;$x.skills[0].key='different@1';Reject-Preserved (Json $x)}
    Case 'nonstring identity rejected' {$x=GoodRegistry;$x.skills[0].id=1234;Reject-Preserved (Json $x)}
    Case 'unproven skill rejected' {$x=GoodRegistry;$x.skills[0].status='RUNNING';Reject-Preserved (Json $x)}
    Case 'authority expansion rejected' {$x=GoodRegistry;$x.skills[0].authority='YELLOW';Reject-Preserved (Json $x)}
    Case 'invalid proof hash rejected' {$x=GoodRegistry;$x.skills[0].proof_sha256='not-a-hash';Reject-Preserved (Json $x)}
    Case 'missing proof field rejected' {$x=GoodRegistry;$x.skills[0].PSObject.Properties.Remove('manifest_sha256');Reject-Preserved (Json $x)}
    Case 'invalid registry timestamp rejected' {$x=GoodRegistry;$x.updated_at='yesterday';Reject-Preserved (Json $x)}
    Case 'invalid proof timestamp rejected' {$x=GoodRegistry;$x.skills[0].proven_at='never';Reject-Preserved (Json $x)}
    Case 'numeric registry timestamp rejected' {$x=GoodRegistry;$x.updated_at=2026;Reject-Preserved (Json $x)}
    Case 'boolean proof timestamp rejected' {$x=GoodRegistry;$x.skills[0].proven_at=$true;Reject-Preserved (Json $x)}
    Case 'unapproved primitive rejected' {$x=GoodRegistry;$x.skills[0].primitive_steps=@('shell');Reject-Preserved (Json $x)}
    Case 'result path escape rejected' {$x=GoodRegistry;$x.skills[0].result_file='../elsewhere.json';Reject-Preserved (Json $x)}
    Case 'empty name rejected' {$x=GoodRegistry;$x.skills[0].name='';Reject-Preserved (Json $x)}
    Case 'registry file size is bounded' {Reject-Preserved (' '*2097153)}

    $RunRoot=Join-Path $TempRoot 'runner'
    New-Item -ItemType Directory -Path $RunRoot|Out-Null
    $Runner=Join-Path $RunRoot 'kevin-skill-lab.ps1'
    Copy-Item -LiteralPath $Candidate -Destination $Runner
    $Engine=(Get-Process -Id $PID).Path
    function Tick([int]$ExpectedExit=0){
        $oldPreference=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$output=(& $Engine -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Runner 2>&1|Out-String);$code=$LASTEXITCODE}finally{$ErrorActionPreference=$oldPreference}
        Assert ($code-eq$ExpectedExit) ('Unexpected runner exit '+$code+': '+$output)
        return $output
    }
    $SkillReady=Join-Path $RunRoot 'reports/action-era/skills/ready'
    $SkillDone=Join-Path $RunRoot 'reports/action-era/skills/done'
    $SkillFailed=Join-Path $RunRoot 'reports/action-era/skills/failed'
    $QueueReady=Join-Path $RunRoot 'reports/action-era/queue/ready'
    $QueueDone=Join-Path $RunRoot 'reports/action-era/queue/done'
    $LiveRegistry=Join-Path $RunRoot 'reports/capabilities/composite-skills.json'
    $Artifacts=Join-Path $RunRoot 'fixture-artifacts'
    New-Item -ItemType Directory -Path $Artifacts|Out-Null
    [void](Tick)
    $Manifest=Get-Content -LiteralPath $SkillFile -Raw|ConvertFrom-Json
    function FixtureOperator {
        $orders=@(Get-ChildItem -LiteralPath $QueueReady -File -Filter '*.json')
        Assert ($orders.Count-eq1) 'Expected exactly one queued primitive'
        $order=Get-Content -LiteralPath $orders[0].FullName -Raw|ConvertFrom-Json
        Assert ($order.operation-ceq'create_text'-and$order.authority-ceq'GREEN') 'Fixture operator accepts GREEN text only'
        $name=[string]$order.payload.filename
        Assert ($name-match'^[A-Za-z0-9._-]+\.md$'-and-not$name.Contains('..')) 'Fixture output must be a fixed markdown basename'
        $file=Join-Path $Artifacts $name
        Assert (-not(Test-Path -LiteralPath $file)) 'Primitive would duplicate an artifact'
        Put $file ([string]$order.payload.content)
        Assert ([IO.File]::ReadAllText($file)-ceq[string]$order.payload.content) 'Independent text postcondition failed'
        $order|Add-Member NoteProperty status 'DONE'
        $order|Add-Member NoteProperty result ([pscustomobject]@{status='DONE';completed_at=(Get-Date).ToString('o');output_name=$name;sha256=(Digest $file);bytes=(Get-Item $file).Length})
        Put (Join-Path $QueueDone $orders[0].Name) (Json $order)
        Remove-Item -LiteralPath $orders[0].FullName
    }
    Case 'actual runner completes two text steps across process restarts' {
        Copy-Item -LiteralPath $SkillFile -Destination (Join-Path $SkillReady 'recovery-kit.json')
        [void](Tick);FixtureOperator
        [void](Tick);FixtureOperator
        [void](Tick)
        $r=Get-Content -LiteralPath $LiveRegistry -Raw|ConvertFrom-Json
        Assert-RegistryValid $r
        Assert (@($r.skills).Count-eq1) 'Expected one proven skill'
        Assert ($r.skills[0].manifest_sha256-ceq(HO $Manifest)) 'Manifest proof is not correlated'
        foreach($step in $Manifest.steps){Assert ([IO.File]::ReadAllText((Join-Path $Artifacts $step.payload.filename))-ceq[string]$step.payload.content) 'Delivered text changed'}
    }
    Case 'exact replay reuses proof with no duplicate actions' {
        $before=Digest $LiveRegistry
        Copy-Item -LiteralPath $SkillFile -Destination (Join-Path $SkillReady 'recovery-kit-replay.json')
        $out=Tick
        Assert ($out-match'DUPLICATE already proven') 'Replay was not suppressed'
        Assert ((Digest $LiveRegistry)-ceq$before) 'Replay changed learned history'
        Assert (@(Get-ChildItem -LiteralPath $QueueReady -File).Count-eq0) 'Replay queued duplicate work'
        Assert (@(Get-ChildItem -LiteralPath $Artifacts -File).Count-eq2) 'Replay duplicated artifacts'
    }
    Case 'same identity with different content is rejected without replacing proof' {
        $before=Digest $LiveRegistry
        $collision=(Json $Manifest)|ConvertFrom-Json;$collision.steps[0].payload.content='different'
        Put (Join-Path $SkillReady 'collision.json') (Json $collision)
        $out=Tick
        Assert ($out-match'proven manifest conflict') 'Identity collision accepted'
        Assert ((Digest $LiveRegistry)-ceq$before) 'Collision changed learned history'
        Assert (@(Get-ChildItem -LiteralPath $QueueReady -File).Count-eq0) 'Collision queued new work'
    }
    Case 'corrupt registry blocks the actual runner before consuming staged work' {
        Copy-Item -LiteralPath $SkillFile -Destination (Join-Path $SkillReady 'blocked.json')
        $valid=[IO.File]::ReadAllText($LiveRegistry)
        Put $LiveRegistry '{"schema":';$before=Digest $LiveRegistry
        $out=Tick 1
        Assert ($out-match'SKILL_REGISTRY_') 'Registry fault was not identified'
        Assert ((Digest $LiveRegistry)-ceq$before) 'Runner replaced corrupt history'
        Assert (Test-Path -LiteralPath (Join-Path $SkillReady 'blocked.json')) 'Runner consumed work despite corrupt history'
        Assert (@(Get-ChildItem -LiteralPath $QueueReady -File).Count-eq0) 'Runner queued work despite corrupt history'
        Put $LiveRegistry $valid
        [void](Tick)
    }
    Case 'missing live registry with completed receipts cannot reset learning' {
        Remove-Item -LiteralPath $LiveRegistry
        $out=Tick 1
        Assert ($out-match'SKILL_REGISTRY_MISSING_WITH_PRIOR_EVIDENCE') 'Missing history was not identified'
        Assert (-not(Test-Path -LiteralPath $LiveRegistry)) 'Runner invented empty history'
    }
    $summary=[ordered]@{schema=1;kind='kevin-skill-registry-candidate-proof';tests_passed=$script:Cases;engine=$PSVersionTable.PSVersion.ToString();candidate_sha256=(Digest $Candidate);manifest_sha256=(Digest $SkillFile);manifest_canonical_sha256=(HO $Manifest);baseline_bug_reproduced=$true;authority_delta='NONE';omen_runtime_proven=$false;truth_boundary='Staged Windows runner tests with an independent fixture text operator; not live Omen repair or autonomous-learning proof.'}
    Write-Host ('PROOF_JSON='+(ConvertTo-Json -InputObject $summary -Depth 10 -Compress))
}finally{Remove-Item -LiteralPath $TempRoot -Recurse -Force}
# The last negative subprocess test intentionally exits 1. Report suite success
# only after every assertion and cleanup has completed successfully.
exit 0
