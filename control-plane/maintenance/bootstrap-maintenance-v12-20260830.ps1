$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
$target = Join-Path $ws 'kevin-maintenance-runner.ps1'
$expectedBefore = 'B47714C91EFDCCD1FAE6C2CB0B97D72F799125A63C084956916A8BD5A07678C1'
$expectedAfter  = '3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483'
$sourceApi = 'repos/hessmodee/KEVIN-WORK/contents/control-plane/maintenance/kevin-maintenance-runner-v1.2.ps1?ref=main'
$backupDir = Join-Path $ws ('reports\maintenance\backups\bootstrap-v12-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
$temp = Join-Path $env:TEMP ('kevin-maintenance-v12-'+[guid]::NewGuid().ToString('N')+'.ps1')
$mutated = $false

function Get-Sha([string]$Path) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return ''}
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-CandidateBytes {
    $gh=(Get-Command gh -ErrorAction Stop).Source
    $oldGh=[Environment]::GetEnvironmentVariable('GH_TOKEN','Process')
    $oldGithub=[Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    try {
        Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
        Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
        $old=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$out=(& $gh api $sourceApi --jq '.content' 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
        if($code -ne 0){throw 'STOP: CI-qualified v1.2 candidate fetch failed'}
        try{return [Convert]::FromBase64String(($out -replace '\s',''))}catch{throw 'STOP: candidate decode failed'}
    }
    finally {
        if($null-ne$oldGh){$env:GH_TOKEN=$oldGh}else{Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue}
        if($null-ne$oldGithub){$env:GITHUB_TOKEN=$oldGithub}else{Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue}
    }
}

try {
    if(-not(Test-Path -LiteralPath $target -PathType Leaf)){throw 'STOP: maintenance runner missing'}
    $before=Get-Sha $target
    if($before -eq $expectedAfter){
        Write-Host 'BOOTSTRAP MAINTENANCE v1.2 ALREADY_INSTALLED exact_hash=true'
        exit 0
    }
    if($before -ne $expectedBefore){throw ('STOP: maintenance runner expected-current mismatch actual='+$before)}

    $bytes=Get-CandidateBytes
    [IO.File]::WriteAllBytes($temp,$bytes)
    if((Get-Sha $temp) -ne $expectedAfter){throw 'STOP: fetched v1.2 candidate hash mismatch'}

    $tokens=$null;$errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($temp,[ref]$tokens,[ref]$errors)
    if($errors.Count -gt 0){throw ('STOP: v1.2 parser rejected candidate: '+$errors[0].Message)}

    $old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$self=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $temp -SelfTest 2>&1|Out-String).Trim();$selfCode=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    if($selfCode -ne 0 -or $self -notmatch 'KEVIN MAINTENANCE v1\.2 SELFTEST PASS'){throw 'STOP: v1.2 fixed self-test failed'}

    New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $backup=Join-Path $backupDir 'kevin-maintenance-runner.ps1'
    Copy-Item -LiteralPath $target -Destination $backup -Force
    if((Get-Sha $backup) -ne $expectedBefore){throw 'STOP: bootstrap backup hash mismatch'}

    $installTemp=$target+'.bootstrap-'+[guid]::NewGuid().ToString('N')
    Copy-Item -LiteralPath $temp -Destination $installTemp -Force
    Move-Item -LiteralPath $installTemp -Destination $target -Force
    $mutated=$true
    if((Get-Sha $target) -ne $expectedAfter){throw 'STOP: installed v1.2 hash mismatch'}

    Write-Host ('BOOTSTRAP MAINTENANCE v1.2 PROVEN before='+$before+' after='+(Get-Sha $target))
    Write-Host ('BACKUP '+$backup)
    exit 0
}
catch {
    if($mutated -and $backup -and (Test-Path -LiteralPath $backup -PathType Leaf)){
        Copy-Item -LiteralPath $backup -Destination $target -Force
        Write-Host 'BOOTSTRAP ROLLBACK restored v1.1d'
    }
    Write-Host ('BOOTSTRAP FAILED '+$_.Exception.Message)
    exit 1
}
finally {
    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
}
