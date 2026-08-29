$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0

$src='control-plane/actuator/KEVIN-AUTONOMY-SCHEDULER-RESUME-v0.1j.ps1'
$dst='control-plane/actuator/KEVIN-AUTONOMY-SCHEDULER-RESUME-v0.1k.ps1'
$text=Get-Content -LiteralPath $src -Raw

$new=@'
function Get-OptionalPropertyValue {
  param($Object,[Parameter(Mandatory=$true)][string]$Name)
  if($null -eq $Object){return $null}
  $prop=$Object.PSObject.Properties[$Name]
  if($null -eq $prop){return $null}
  return $prop.Value
}

function Resolve-JobId {
  param($Object,[string]$Label)
  if($null -eq $Object){throw "Could not resolve job id from $Label create response: response was null."}
  $id=Get-OptionalPropertyValue -Object $Object -Name 'id'
  if($id){return [string]$id}
  $jobId=Get-OptionalPropertyValue -Object $Object -Name 'jobId'
  if($jobId){return [string]$jobId}
  $job=Get-OptionalPropertyValue -Object $Object -Name 'job'
  if($job){
    $nestedId=Get-OptionalPropertyValue -Object $job -Name 'id'
    if($nestedId){return [string]$nestedId}
  }
  $result=Get-OptionalPropertyValue -Object $Object -Name 'result'
  if($result){
    $nestedId=Get-OptionalPropertyValue -Object $result -Name 'id'
    if($nestedId){return [string]$nestedId}
  }
  $props=@($Object.PSObject.Properties.Name) -join ','
  throw "Could not resolve job id from $Label create response. Top-level properties: $props"
}
'@
$pattern='(?s)function Resolve-JobId \{.*?\}\r?\n\r?\nfunction Assert-StringArrayEqual'
$matches=[regex]::Matches($text,$pattern)
if($matches.Count -ne 1){throw "Expected exactly one bounded Resolve-JobId block; found $($matches.Count)."}
$replacement=$new.TrimEnd()+"`r`n`r`nfunction Assert-StringArrayEqual"
$text=[regex]::Replace($text,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{param($m)$replacement},1)
$text=$text.Replace("version='0.1j'","version='0.1k'")
$text=$text.Replace("install-manifest-v0.1j.json","install-manifest-v0.1k.json")
$text=$text.Replace("install-proof-v0.1j.json","install-proof-v0.1k.json")
$text=$text.Replace("ROLLBACK-v0.1j.ps1","ROLLBACK-v0.1k.ps1")
$text=$text.Replace("scheduler v0.1j jobs removed","scheduler v0.1k jobs removed")
$text=$text.Replace("SCHEDULER v0.1j INSTALLED + PROVEN","SCHEDULER v0.1k INSTALLED + PROVEN")
[IO.File]::WriteAllText($dst,$text,(New-Object Text.UTF8Encoding($false)))
Write-Host "Built $dst"
