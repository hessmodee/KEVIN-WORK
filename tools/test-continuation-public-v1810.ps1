param([string]$Runner='control-plane/autonomy/kevin-supervisor-v1.8.10.ps1')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner),[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0].Message}
foreach($name in @('Get-ToolCallCount','Get-PublicContinuation','Get-TextSha')){
 $fn=$ast.Find({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$name},$true)
 if(-not$fn){throw "missing $name"};. ([scriptblock]::Create($fn.Extent.Text))
}
function Read-State {return [pscustomobject]@{schema=2;items=@([pscustomobject]@{id='fixture-task';fingerprint=('A'*64);turns=2;last_turn_at='2026-09-02T00:00:00Z';status='AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF'})}}
$s=[ordered]@{at='2026-09-02T00:00:00Z';status='CONTROLLER_ERROR';selected_id='fixture-task';failure='PRIVATE CANARY TEXT';raw='PRIVATE EXTRA';tool_calls=$null}
$p=Get-PublicContinuation $s
if($p.history_error){throw 'healthy history marked history_error'}
if(@($p.history).Count-ne1-or$p.history[0].turns-ne2){throw 'durable history omitted'}
if($p.version-ne'1.8.10'){throw 'public continuation version not 1.8.10'}

function Read-State {return [pscustomobject]@{schema=2;items=@(
  [pscustomobject]@{id='fixture-task';fingerprint=('A'*64);turns=2;last_turn_at='2026-09-02T00:00:00Z';status='AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF'},
  [pscustomobject]@{id='legacy-bad';fingerprint=('B'*64);turns=1;last_turn_at='2026-09-01T00:00:00Z';status='UNCHANGED_WORK_AFTER_BOUNDED_TURNS'}
)}}
$s=[ordered]@{at='2026-09-06T16:09:00Z';status='WAITING_ITEM_BUDGETS';eligible_count=1;work_conservation='ALL_ELIGIBLE_ITEMS_HAVE_RECORDED_DEFERRAL';deferred=@([ordered]@{id='owner-west-motor-transport-dispatch-template-v1';reason='MIN_REPEAT';turns=2})}
$p=Get-PublicContinuation $s
if($p.history_error){throw 'mixed history fail-closed instead of skip'}
if(@($p.history).Count-ne1-or$p.history[0].id-ne'fixture-task'){throw 'valid history row dropped'}
if([int]$p.history_skipped-ne1){throw 'skipped invalid history row not counted'}
if(-not$p.deferred-or$p.deferred[0].reason-ne'MIN_REPEAT'){throw 'deferred reasons not published'}
if($p.deferred[0].id-ne'owner-west-motor-transport-dispatch-template-v1'){throw 'deferred id lost'}
Write-Host 'CONTINUATION_PUBLIC_V1810_PASS history_error_false_on_healthy=true invalid_history_skipped=true deferred_reasons_published=true west_motor_min_repeat_visible=true'
