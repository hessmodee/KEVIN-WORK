param([string]$Runner='control-plane/autonomy/kevin-supervisor-v1.8.8.ps1')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner),[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0].Message}
foreach($name in @('Get-ToolCallCount','Get-PublicContinuation','Get-TextSha')){
 $fn=$ast.Find({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$name},$true)
 if(-not$fn){throw "missing $name"};. ([scriptblock]::Create($fn.Extent.Text))
}
$Utf8=New-Object Text.UTF8Encoding($false)
function Read-State {return [pscustomobject]@{schema=2;items=@([pscustomobject]@{id='fixture-task';fingerprint=('A'*64);turns=2;last_turn_at='2026-09-02T00:00:00Z';status='AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF'})}}
if($null-ne(Get-ToolCallCount ([pscustomobject]@{status='ok'}))){throw 'missing tool telemetry became zero'}
if((Get-ToolCallCount ([pscustomobject]@{toolSummary=[pscustomobject]@{calls=2}}))-ne2){throw 'explicit tool calls lost'}
$s=[ordered]@{at='2026-09-02T00:00:00Z';status='CONTROLLER_ERROR';selected_id='fixture-task';failure='PRIVATE CANARY TEXT';raw='PRIVATE EXTRA';tool_calls=$null}
$p=Get-PublicContinuation $s;$json=$p|ConvertTo-Json -Depth 20
if($json.Contains('PRIVATE')-or$p.outcome_proven-or$null-ne$p.tool_calls){throw 'public boundary violated'}
if(@($p.history).Count-ne1-or$p.history[0].turns-ne2){throw 'durable history omitted'}
$s.selected_id='../private path';$rejected=$false
try{Get-PublicContinuation $s|Out-Null}catch{$rejected=$true}
if(-not$rejected){throw 'invalid public identity accepted'}
Write-Host 'CONTINUATION_PUBLIC_PASS missing_telemetry_unknown=true raw_text_excluded=true history_preserved=true no_outcome_inference=true'
