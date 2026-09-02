param([string]$Runner='control-plane/maintenance/kevin-maintenance-runner-v1.3.44.ps1')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner),[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0].Message}
foreach($name in @('Get-MainModelContractFacts','Get-OptionalPropertyValue','Get-OptionalPathValue','Get-TextSha256')){
 $fn=$ast.Find({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$name},$true)
 if(-not$fn){throw "missing $name"};. ([scriptblock]::Create($fn.Extent.Text))
}
$c='{"agents":{"defaults":{"model":{"primary":"local/qwen2.5:14b"}},"list":[{"id":"main","tools":{"profile":"coding","allow":["kevin_system_status","PRIVATE_TOOL"]}}]},"models":{"providers":{"local":{"api":"ollama","apiKey":"PRIVATE_SECRET","baseUrl":"http://PRIVATE_HOST"}}},"tools":{"deny":["exec"]}}'|ConvertFrom-Json
$p=Get-MainModelContractFacts $c
if($p.model_family-ne'QWEN2_5'-or$p.provider_api-ne'ollama'-or-not$p.main_kevin_core_allowed){throw 'effective main model/policy not classified'}
if(($p|ConvertTo-Json -Depth 20).Contains('PRIVATE')){throw 'private config leaked'}
$c.agents.list[0]|Add-Member -NotePropertyName model -NotePropertyValue 'local/qwen3:14b'
if((Get-MainModelContractFacts $c).model_family-ne'QWEN3'){throw 'agent override not honored'}
$c.agents.list+=,$c.agents.list[0];$rejected=$false
try{Get-MainModelContractFacts $c|Out-Null}catch{$rejected=$true};if(-not$rejected){throw 'duplicate main accepted'}
Write-Host 'MAIN_MODEL_CONTRACT_PASS effective_model=true override=true fixed_allowlists=true no_secret_values=true duplicate_rejected=true'
