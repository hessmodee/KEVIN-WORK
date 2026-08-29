Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Reports=Join-Path $Workspace 'reports'
if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$Local=Join-Path $Reports 'autonomy-latest.json'
if(-not(Test-Path -LiteralPath $Local)){Write-Output 'NO_AUTONOMY_REPORT';exit 0}
$obj=Get-Content -LiteralPath $Local -Raw|ConvertFrom-Json
$safe=[ordered]@{
 schema=1;kind='kevin-autonomy-public';generated_at=$obj.generated_at;state=$obj.state;fingerprint=$obj.fingerprint;
 drift_count=@($obj.drift).Count;selected_action=$(if($obj.selected_action){$obj.selected_action.verb}else{$null});
 action_ok=$(if($obj.action_result){[bool]$obj.action_result.ok}else{$null});failure_budget=$obj.failure_budget;
 work_conserving=$obj.work_conserving;safety=$obj.safety
}
$semantic=[ordered]@{state=$safe.state;fingerprint=$safe.fingerprint;drift_count=$safe.drift_count;selected_action=$safe.selected_action;action_ok=$safe.action_ok;failure_budget=$safe.failure_budget;work_conserving=$safe.work_conserving;safety=$safe.safety}
$semanticJson=$semantic|ConvertTo-Json -Depth 20 -Compress
$sha=[System.Security.Cryptography.SHA256]::Create();try{$bytes=[Text.Encoding]::UTF8.GetBytes($semanticJson);$safe.semantic_hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')}finally{$sha.Dispose()}
$payload=$safe|ConvertTo-Json -Depth 20
$repo='hessmodee/KEVIN-WORK';$path='reports/autonomy-latest.json'
$err=Join-Path $env:TEMP ("kevin-gh-{0}.txt" -f [guid]::NewGuid().ToString('N'))
$old=$ErrorActionPreference;$ErrorActionPreference='Continue'
try{$remoteText=& gh api ("repos/{0}/contents/{1}" -f $repo,$path) -H 'Accept: application/vnd.github+json' 2>$err;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
$remote=$null
if($code -eq 0){try{$remote=$remoteText|ConvertFrom-Json}catch{}}
if($remote){
 try{$decoded=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($remote.content -replace '\s','')))|ConvertFrom-Json;if($decoded.semantic_hash -eq $safe.semantic_hash){Write-Output 'AUTONOMY_UNCHANGED';exit 0}}catch{}
}
$body=[ordered]@{message='kevin autonomy telemetry';content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload));branch='main'}
if($remote -and $remote.sha){$body.sha=$remote.sha}
$bodyPath=Join-Path $env:TEMP ("kevin-gh-body-{0}.json" -f [guid]::NewGuid().ToString('N'))
[IO.File]::WriteAllText($bodyPath,($body|ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding($false)))
$old=$ErrorActionPreference;$ErrorActionPreference='Continue'
try{$out=& gh api --method PUT ("repos/{0}/contents/{1}" -f $repo,$path) --input $bodyPath -H 'Accept: application/vnd.github+json' 2>$err;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old;Remove-Item $bodyPath -Force -ErrorAction SilentlyContinue;Remove-Item $err -Force -ErrorAction SilentlyContinue}
if($code -ne 0){throw 'Autonomy telemetry publish failed.'}
Write-Output 'AUTONOMY_PUBLISHED'
