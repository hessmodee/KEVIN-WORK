$ErrorActionPreference='Stop'
$candidate = Join-Path $PSScriptRoot 'kevin-skill-lab-v1.0.4.ps1'
if(-not(Test-Path $candidate -PathType Leaf)){throw 'candidate missing'}

$root = Join-Path $env:TEMP ('kevin-skill-lab-v104-runtime-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $root | Out-Null
$runner = Join-Path $root 'kevin-skill-lab.ps1'
Copy-Item $candidate $runner -Force

function Invoke-Runner {
    $old=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        $out = (& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $runner 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    } finally {
        $ErrorActionPreference=$old
    }
    Write-Host $out
    if($code -ne 0){throw ('runner failed exit='+$code+' output='+$out)}
    return $out
}

try {
    $ready = Join-Path $root 'reports\action-era\skills\ready'
    $running = Join-Path $root 'reports\action-era\skills\running'
    $done = Join-Path $root 'reports\action-era\skills\done'
    $qready = Join-Path $root 'reports\action-era\queue\ready'
    $qdone = Join-Path $root 'reports\action-era\queue\done'
    $reg = Join-Path $root 'reports\capabilities\composite-skills.json'
    foreach($d in @($ready,$running,$done,$qready,$qdone)){New-Item -ItemType Directory -Force -Path $d | Out-Null}

    $manifest = [ordered]@{
        schema=1
        kind='kevin-composite-skill'
        id='windows-runtime-proof'
        version='1'
        authority='GREEN'
        name='Windows Runtime Proof'
        steps=@(
            [ordered]@{
                operation='create_text'
                payload=[ordered]@{
                    filename='windows-runtime-proof.txt'
                    content='ok'
                }
            }
        )
    }
    $manifestText = $manifest | ConvertTo-Json -Depth 20
    $manifestPath = Join-Path $ready 'windows-runtime-proof--1.json'
    [IO.File]::WriteAllText($manifestPath,$manifestText,(New-Object Text.UTF8Encoding($false)))

    $o1 = Invoke-Runner
    if($o1 -notmatch 'SKILL LAB ENQUEUED skill-windows-runtime-proof-1-s01'){throw 'READY discovery/enqueue failed'}
    if(Test-Path $manifestPath){throw 'READY manifest was not moved to RUNNING'}
    $runningPath = Join-Path $running 'windows-runtime-proof--1.json'
    if(-not(Test-Path $runningPath -PathType Leaf)){throw 'RUNNING state missing'}

    $orderReady = Join-Path $qready 'skill-windows-runtime-proof-1-s01.json'
    if(-not(Test-Path $orderReady -PathType Leaf)){throw 'Operator READY order missing'}
    $order = Get-Content $orderReady -Raw | ConvertFrom-Json
    $order | Add-Member -NotePropertyName status -NotePropertyValue 'DONE'
    $order | Add-Member -NotePropertyName result -NotePropertyValue ([pscustomobject]@{
        status='DONE'
        completed_at=(Get-Date).ToString('o')
        output_name='windows-runtime-proof.txt'
        sha256=('A'*64)
        bytes=2
    })
    $orderDone = Join-Path $qdone 'skill-windows-runtime-proof-1-s01.json'
    [IO.File]::WriteAllText($orderDone,($order|ConvertTo-Json -Depth 20),(New-Object Text.UTF8Encoding($false)))
    Remove-Item $orderReady -Force

    $o2 = Invoke-Runner
    if($o2 -notmatch 'SKILL LAB PROVEN windows-runtime-proof@1'){throw 'RUNNING discovery/DONE reconciliation failed'}
    if(Test-Path $runningPath){throw 'RUNNING state not moved to DONE'}
    $skillDone = Join-Path $done 'windows-runtime-proof--1.json'
    if(-not(Test-Path $skillDone -PathType Leaf)){throw 'PROVEN skill result missing'}
    if(-not(Test-Path $reg -PathType Leaf)){throw 'composite registry missing'}
    $r = Get-Content $reg -Raw | ConvertFrom-Json
    $hits=@($r.skills | Where-Object{[string]$_.key -eq 'windows-runtime-proof@1' -and [string]$_.status -eq 'PROVEN'})
    if($hits.Count -ne 1){throw 'registry PROVEN entry missing or duplicated'}

    $o3 = Invoke-Runner
    if($o3 -notmatch 'SKILL LAB NO_WORK'){throw 'empty queue did not report NO_WORK'}

    [IO.File]::WriteAllText($manifestPath,$manifestText,(New-Object Text.UTF8Encoding($false)))
    $o4 = Invoke-Runner
    if($o4 -notmatch 'SKILL LAB DUPLICATE already proven'){throw 'proven replay suppression failed'}
    $r2 = Get-Content $reg -Raw | ConvertFrom-Json
    $hits2=@($r2.skills | Where-Object{[string]$_.key -eq 'windows-runtime-proof@1'})
    if($hits2.Count -ne 1){throw 'replay duplicated registry entry'}

    Write-Host 'PASS Windows PowerShell 5.1 real queue lifecycle READY->RUNNING->PROVEN->REPLAY'
}
finally {
    Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
}
