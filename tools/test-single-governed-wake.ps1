param([string]$Runner='control-plane/maintenance/kevin-maintenance-runner-v1.3.43.ps1')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Runner),[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0].Message}
foreach($name in @('Get-GovernedContinuationJob','Get-ContinuationImmutableHash','Get-OptionalPropertyValue','Get-TextSha256')){
 $fn=$ast.Find({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$name},$true)
 if(-not$fn){throw "missing $name"};. ([scriptblock]::Create($fn.Extent.Text))
}
$j=[pscustomobject]@{id='af9ced44-a046-4557-a485-edc9114f0c19';name='Kevin Supervisor v1.6 High Gear';enabled=$true;schedule=[pscustomobject]@{kind='every';everyMs=180000};payload=[pscustomobject]@{kind='command';argv=@('powershell.exe','-File','kevin-supervisor.ps1')};sessionTarget='isolated';delivery=[pscustomobject]@{mode='none'}}
$null=Get-GovernedContinuationJob @($j)
$h=Get-ContinuationImmutableHash $j
$j.schedule.everyMs=300000
if((Get-ContinuationImmutableHash $j)-ne$h){throw 'cadence changed protected payload identity'}
$j.payload.argv=@('powershell.exe','-File','evil.ps1')
if((Get-ContinuationImmutableHash $j)-eq$h){throw 'payload mutation not detected'}
$reject=$false;try{Get-GovernedContinuationJob @($j)|Out-Null}catch{$reject=$true};if(-not$reject){throw 'wrong payload accepted'}
$j.payload.argv=@('powershell.exe','-File','kevin-supervisor.ps1')
$extra=[pscustomobject]@{name='Kevin Autonomy Continuation v1'}
$reject=$false;try{Get-GovernedContinuationJob @($j,$extra)|Out-Null}catch{$reject=$true};if(-not$reject){throw 'duplicate scheduler admitted'}
Write-Host 'SINGLE_GOVERNED_WAKE_PASS existing_job_reused=true payload_hash_preserved=true duplicates_rejected=true cadence_only=true'
