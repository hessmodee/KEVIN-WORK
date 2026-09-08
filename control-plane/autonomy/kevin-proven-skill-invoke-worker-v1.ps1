param(
    [Parameter(Mandatory = $true)][string]$WorkId,
    [Parameter(Mandatory = $true)][string]$SkillKey,
    [Parameter(Mandatory = $true)][string]$RequestId
)
# Compatibility copy. Canonical runtime location is ControlPlane\kevin-proven-skill-invoke-worker-v1.ps1
$canonical = Join-Path $PSScriptRoot '..\..\ControlPlane\kevin-proven-skill-invoke-worker-v1.ps1'
if (Test-Path -LiteralPath $canonical) {
    & $canonical -WorkId $WorkId -SkillKey $SkillKey -RequestId $RequestId
    exit $LASTEXITCODE
}
throw 'CANONICAL_INVOCATION_WORKER_MISSING'
