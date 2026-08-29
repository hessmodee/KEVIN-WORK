$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0

$src='control-plane/actuator/KEVIN-AUTONOMY-SCHEDULER-RESUME-v0.1j.ps1'
$dst='control-plane/actuator/KEVIN-AUTONOMY-SCHEDULER-RESUME-v0.1k.ps1'
$text=Get-Content -LiteralPath $src -Raw

$old="function Resolve-JobId {param(`$Object,[string]`$Label);if(`$Object -and `$Object.id){return [string]`$Object.id};if(`$Object -and `$Object.jobId){return [string]`$Object.jobId};if(`$Object -and `$Object.job -and `$Object.job.id){return [string]`$Object.job.id};if(`$Object -and `$Object.result -and `$Object.result.id){return [string]`$Object.result.id};throw \"Could not resolve job id from `$Label create response.\"}"
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
if(-not $text.Contains($old)){throw 'Expected v0.1j Resolve-JobId function not found exactly once.'}
if(([regex]::Matches($text,[regex]::Escape($old))).Count -ne 1){throw 'Resolve-JobId source occurrence count was not exactly 1.'}
$text=$text.Replace($old,$new.TrimEnd())
$text=$text.Replace("version='0.1j'","version='0.1k'")
$text=$text.Replace("install-manifest-v0.1j.json","install-manifest-v0.1k.json")
$text=$text.Replace("install-proof-v0.1j.json","install-proof-v0.1k.json")
$text=$text.Replace("ROLLBACK-v0.1j.ps1","ROLLBACK-v0.1k.ps1")
$text=$text.Replace("scheduler v0.1j jobs removed","scheduler v0.1k jobs removed")
$text=$text.Replace("SCHEDULER v0.1j INSTALLED + PROVEN","SCHEDULER v0.1k INSTALLED + PROVEN")
[IO.File]::WriteAllText($dst,$text,(New-Object Text.UTF8Encoding($false)))
Write-Host "Built $dst"
