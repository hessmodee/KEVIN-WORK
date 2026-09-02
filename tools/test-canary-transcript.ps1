param([string]$Runner='control-plane/maintenance/kevin-maintenance-runner-v1.3.42.ps1')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner),[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0].Message}
foreach($name in @('Get-Sha','Get-OptionalPropertyValue','Get-OptionalPathValue','Get-CanaryTranscriptEvidence')){
    $fn=$ast.Find({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$name},$true)
    if(-not$fn){throw "Missing function $name"}
    . ([scriptblock]::Create($fn.Extent.Text))
}
$testRoot=Join-Path $env:RUNNER_TEMP ('kevin-transcript-test-'+[guid]::NewGuid().ToString('N'))
$priorProfile=$env:USERPROFILE
try{
    $env:USERPROFILE=$testRoot
    $dir=Join-Path $testRoot '.openclaw/agents/main/sessions'
    New-Item -ItemType Directory -Force $dir|Out-Null
    $sid=[guid]::NewGuid().ToString();$file=Join-Path $dir ($sid+'.jsonl')
    $o=[pscustomobject]@{result=[pscustomobject]@{meta=[pscustomobject]@{agentMeta=[pscustomobject]@{sessionId=$sid}}}}
    $prompt='Fixed canary fixture';$start=(Get-Date).AddMinutes(-1)
    $rows=@(
        [ordered]@{type='session';id=$sid},
        [ordered]@{type='message';message=[ordered]@{role='user';content=@([ordered]@{type='text';text=$prompt})}},
        [ordered]@{type='message';message=[ordered]@{role='assistant';content=@([ordered]@{type='text';text='KEVIN_MAIN_AGENT_CANARY_OK'});stopReason='stop'}}
    )
    function Save-Fixture($Rows){$text=(@($Rows|ForEach-Object{$_|ConvertTo-Json -Depth 12 -Compress})-join"`n")+"`n";[IO.File]::WriteAllText($file,$text,(New-Object Text.UTF8Encoding($false)))}
    Save-Fixture $rows
    $proof=Get-CanaryTranscriptEvidence $o $prompt $start
    if(-not$proof.complete -or -not$proof.final_exact -or $proof.tool_calls-ne0){throw 'correlated zero-tool transcript rejected'}
    $rows[2].message.content=@([ordered]@{type='toolCall';id='fixture-tool';name='fixture'},[ordered]@{type='text';text='KEVIN_MAIN_AGENT_CANARY_OK'})
    Save-Fixture $rows
    if((Get-CanaryTranscriptEvidence $o $prompt $start).tool_calls-ne1){throw 'forbidden tool use lost'}
    $rows[2].message.content=@([ordered]@{type='text';text='prefix KEVIN_MAIN_AGENT_CANARY_OK'})
    Save-Fixture $rows
    if((Get-CanaryTranscriptEvidence $o $prompt $start).final_exact){throw 'substring passed exact semantic verification'}
    if((Get-CanaryTranscriptEvidence $o 'Different prompt' $start).complete){throw 'uncorrelated request accepted'}
    $rows[0].id=[guid]::NewGuid().ToString();Save-Fixture $rows
    if((Get-CanaryTranscriptEvidence $o $prompt $start).complete){throw 'wrong transcript identity accepted'}
    $o.result.meta.agentMeta.sessionId='../escape'
    if((Get-CanaryTranscriptEvidence $o $prompt $start).present){throw 'arbitrary transcript path accepted'}
    Write-Host 'CANARY_TRANSCRIPT_PASS exact_identity=true correlated_request=true complete_turn=true zero_tools_proven=true tool_use_detected=true substring_rejected=true path_escape_rejected=true'
}finally{
    $env:USERPROFILE=$priorProfile
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
