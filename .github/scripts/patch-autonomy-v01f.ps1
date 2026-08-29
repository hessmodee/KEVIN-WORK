$ErrorActionPreference='Stop'
$path='control-plane/actuator/kevin-autonomy-actuator-v0.1.ps1'
$text=Get-Content $path -Raw

function Replace-Exact([string]$old,[string]$new,[string]$label){
  $count=([regex]::Matches($script:text,[regex]::Escape($old))).Count
  if($count -ne 1){throw "$label target count=$count"}
  $script:text=$script:text.Replace($old,$new)
}

Replace-Exact 'param($Desired,$Support,$Dashboard,$LiveJobs)' 'param($Desired,$Support,$Dashboard)' 'Test-DesiredState signature'

$oldLoop=@'
    foreach ($expected in @($Desired.required_automations)) {
        $sj = Find-SnapshotJob -Support $Support -DeclarationKey $expected.declaration_key -Name $expected.name
        $lj = Find-LiveJob -LiveJobs $LiveJobs -SnapshotJob $sj -Name $expected.name
        if (-not $lj) {
            Add-Drift $drift ("automation_missing_"+$expected.declaration_key) 'review' ("Expected automation not found: {0}" -f $expected.name) '' $expected.declaration_key
            continue
        }
        if ($expected.must_be_enabled -and (-not [bool]$lj.enabled)) {
            Add-Drift $drift ("automation_disabled_"+$expected.declaration_key) 'repair' ("Expected automation is disabled: {0}" -f $expected.name) 'enable_expected_automation' $expected.declaration_key
        }
    }
'@
$newLoop=@'
    foreach ($expected in @($Desired.required_automations)) {
        $sj = Find-SnapshotJob -Support $Support -DeclarationKey $expected.declaration_key -Name $expected.name
        if (-not $sj) {
            Add-Drift $drift ("automation_missing_"+$expected.declaration_key) 'review' ("Expected automation not present in fresh Support Bridge snapshot: {0}" -f $expected.name) '' $expected.declaration_key
            continue
        }
        if ($expected.must_be_enabled -and (-not [bool]$sj.enabled)) {
            Add-Drift $drift ("automation_disabled_"+$expected.declaration_key) 'repair' ("Expected automation is disabled: {0}" -f $expected.name) 'enable_expected_automation' $expected.declaration_key
        }
    }
'@
Replace-Exact $oldLoop.Trim() $newLoop.Trim() 'required automation loop'

$oldDrift=@'
$drift = New-Object System.Collections.ArrayList
if ($liveError) { Add-Drift $drift 'openclaw_live_jobs_unavailable' 'review' $liveError '' 'openclaw-automations' }
else { foreach($d in @(Test-DesiredState -Desired $Desired -Support $Support -Dashboard $Dashboard -LiveJobs $LiveJobs)){ [void]$drift.Add($d) } }
'@
$newDrift=@'
$drift = New-Object System.Collections.ArrayList
foreach($d in @(Test-DesiredState -Desired $Desired -Support $Support -Dashboard $Dashboard)){ [void]$drift.Add($d) }
'@
Replace-Exact $oldDrift.Trim() $newDrift.Trim() 'main live-query drift gate'

$oldVerify=@'
        $null = Invoke-OpenClawJson -Args @('automations','enable',$job.id,'--json')
        $after = Get-LiveJobs
        $verified = @($after | Where-Object { $_.id -eq $job.id -and [bool]$_.enabled }).Count -gt 0
        return [pscustomobject]@{ ok=$verified; detail=("Enable {0}; verified={1}" -f $job.name,$verified); target=$job.id }
'@
$newVerify=@'
        $null = Invoke-OpenClawJson -Args @('automations','enable',$job.id,'--json')
        $after = Invoke-OpenClawJson -Args @('automations','get',$job.id,'--json')
        $verified = ($after -and [bool]$after.enabled)
        return [pscustomobject]@{ ok=$verified; detail=("Enable {0}; verified={1} through automations get" -f $job.name,$verified); target=$job.id }
'@
Replace-Exact $oldVerify.Trim() $newVerify.Trim() 'enable postcondition'

$needle='    safety=[pscustomobject]@{ green_only=$true; arbitrary_shell=$false; authority_expansion=$false; novel_production_promotion=$false }'
$replacement="    live_query_error=`$liveError`r`n$needle"
Replace-Exact $needle $replacement 'evidence live-query field'

[IO.File]::WriteAllText((Resolve-Path $path),$text,(New-Object Text.UTF8Encoding($false)))

$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $path),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'Patched reconciler parse failed'}
$check=Get-Content $path -Raw
if($check -match "openclaw_live_jobs_unavailable' 'review'"){throw 'Old live-query review gate remains'}
if($check -notmatch [regex]::Escape("Invoke-OpenClawJson -Args @('automations','get',`$job.id,'--json')")){throw 'Typed get verification missing'}
Write-Host 'PASS patched reconciler parses and audit no longer depends on list query.'
