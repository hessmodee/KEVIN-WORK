param([string]$Runner = 'control-plane/maintenance/kevin-maintenance-runner-v1.3.41.ps1')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner),[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0].Message}
foreach($name in @('Get-OptionalPropertyValue','Get-OptionalPathValue','Get-MainCanaryShape')){
    $fn=$ast.Find({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$name},$true)
    if(-not$fn){throw "Missing function $name"}
    Set-Item -Path ('function:'+ $name) -Value $fn.Body.GetScriptBlock()
}
$token='KEVIN_MAIN_AGENT_CANARY_OK'
$explicit=[pscustomobject]@{result=[pscustomobject]@{meta=[pscustomobject]@{toolSummary=[pscustomobject]@{calls=0}}}}
$s=Get-MainCanaryShape $explicit $token
if(-not$s.tool_evidence_present -or $s.tool_evidence_calls-ne0 -or -not$s.final_exact_case_sensitive){throw 'explicit zero contract failed'}
$missing=Get-MainCanaryShape ([pscustomobject]@{status='ok'}) $token
if($missing.tool_evidence_present -or $null-ne$missing.tool_evidence_calls){throw 'missing telemetry fabricated zero calls'}
$nonzero=Get-MainCanaryShape ([pscustomobject]@{toolSummary=[pscustomobject]@{calls=2}}) $token
if($nonzero.tool_evidence_calls-ne2){throw 'top level tool calls lost'}
$conflict=[pscustomobject]@{toolSummary=[pscustomobject]@{calls=0};meta=[pscustomobject]@{toolSummary=[pscustomobject]@{calls=1}}}
$blocked=$false;try{$null=Get-MainCanaryShape $conflict $token}catch{$blocked=$true}
if(-not$blocked){throw 'conflicting telemetry accepted'}
$privateText='PRIVATE_TEST_SENTINEL '+$token
$s=Get-MainCanaryShape $explicit $privateText
if($s.final_exact_case_sensitive -or -not$s.final_contains_expected){throw 'substring accepted as exact reply'}
if(($s|ConvertTo-Json -Depth 10).Contains('PRIVATE_TEST_SENTINEL')){throw 'raw model text leaked'}
$case=Get-MainCanaryShape $explicit $token.ToLowerInvariant()
if($case.final_exact_case_sensitive){throw 'case mismatch accepted'}
Write-Host 'CANARY_SHAPE_PASS explicit_zero=true missing_unknown=true nonzero=true contradiction_rejected=true exact_case=true raw_text_absent=true'
