Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

function ConvertTo-Win32CommandLineArg {
  param([AllowEmptyString()][string]$Value)
  if($null -eq $Value -or $Value.Length -eq 0){return '""'}
  if($Value -notmatch '[\s"]'){return $Value}
  $sb=New-Object System.Text.StringBuilder
  [void]$sb.Append('"')
  $slashes=0
  for($i=0;$i -lt $Value.Length;$i++){
    $ch=$Value[$i]
    if($ch -eq '\'){$slashes++;continue}
    if($ch -eq '"'){
      if($slashes -gt 0){[void]$sb.Append((('\' * ($slashes*2)) -join ''))}
      [void]$sb.Append('\"')
      $slashes=0
      continue
    }
    if($slashes -gt 0){[void]$sb.Append((('\' * $slashes) -join ''));$slashes=0}
    [void]$sb.Append($ch)
  }
  if($slashes -gt 0){[void]$sb.Append((('\' * ($slashes*2)) -join ''))}
  [void]$sb.Append('"')
  return $sb.ToString()
}

function Invoke-ExactNative {
  param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string[]]$Argv)
  $psi=New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Executable
  $psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ')
  $psi.UseShellExecute=$false
  $psi.CreateNoWindow=$true
  $psi.RedirectStandardOutput=$true
  $psi.RedirectStandardError=$true
  $p=New-Object System.Diagnostics.Process
  $p.StartInfo=$psi
  if(-not $p.Start()){throw "Could not start native process: $Executable"}
  $outTask=$p.StandardOutput.ReadToEndAsync();$errTask=$p.StandardError.ReadToEndAsync();$p.WaitForExit()
  $r=[pscustomobject]@{ExitCode=[int]$p.ExitCode;Stdout=[string]$outTask.Result;Stderr=[string]$errTask.Result}
  $p.Dispose();return $r
}

function One-Line([AllowEmptyString()][string]$Text){
  if($null -eq $Text){return ''}
  $s=($Text -replace '[\r\n]+',' ').Trim()
  if($s.Length -gt 800){$s=$s.Substring(0,800)}
  return $s
}

function Fail([string]$Stage,[int]$Code,[AllowEmptyString()][string]$Detail){
  Write-Output ("AUTONOMY_ERROR stage={0} exit={1} detail={2}" -f $Stage,$Code,(One-Line $Detail))
  exit $(if($Code -gt 0){$Code}else{21})
}

$AuthMode=if($env:KEVIN_GH_AUTH_MODE){([string]$env:KEVIN_GH_AUTH_MODE).Trim().ToLowerInvariant()}else{'ambient'}
if($AuthMode -notin @('ambient','stored')){Fail -Stage 'auth-mode' -Code 26 -Detail "Unsupported KEVIN_GH_AUTH_MODE '$AuthMode'."}
if($AuthMode -eq 'stored'){
  foreach($name in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){
    try{Remove-Item -LiteralPath ("Env:{0}" -f $name) -Force -ErrorAction SilentlyContinue}catch{}
    [Environment]::SetEnvironmentVariable($name,$null,[EnvironmentVariableTarget]::Process)
  }
  Write-Output 'AUTONOMY_AUTH mode=stored inherited_token_env=removed'
}

$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Reports=if($env:KEVIN_AUTONOMY_REPORTS_DIR){[string]$env:KEVIN_AUTONOMY_REPORTS_DIR}else{Join-Path $Workspace 'reports'}
if(-not(Test-Path -LiteralPath $Reports)){$alt=Join-Path $Workspace 'Reports';if(Test-Path -LiteralPath $alt){$Reports=$alt}}
$Local=Join-Path $Reports 'autonomy-latest.json'
if(-not(Test-Path -LiteralPath $Local)){Write-Output 'NO_AUTONOMY_REPORT';exit 0}

$Repo=if($env:KEVIN_AUTONOMY_REPO){[string]$env:KEVIN_AUTONOMY_REPO}else{'hessmodee/KEVIN-WORK'}
$RemotePath=if($env:KEVIN_AUTONOMY_PATH){[string]$env:KEVIN_AUTONOMY_PATH}else{'reports/autonomy-latest.json'}
$Branch=if($env:KEVIN_AUTONOMY_BRANCH){[string]$env:KEVIN_AUTONOMY_BRANCH}else{'main'}

$GhExe=$null
if($env:KEVIN_GH_EXE -and (Test-Path -LiteralPath ([string]$env:KEVIN_GH_EXE))){$GhExe=[string]$env:KEVIN_GH_EXE}
if(-not $GhExe){
  $gh=Get-Command gh.exe -ErrorAction SilentlyContinue
  if(-not $gh){$gh=Get-Command gh -ErrorAction SilentlyContinue}
  if($gh){$GhExe=$gh.Source}
}
if(-not $GhExe){Fail -Stage 'gh-resolution' -Code 20 -Detail 'GitHub CLI not found in process environment and KEVIN_GH_EXE was not usable.'}

try{$obj=Get-Content -LiteralPath $Local -Raw|ConvertFrom-Json}catch{Fail -Stage 'local-report-parse' -Code 22 -Detail $_.Exception.Message}

$safe=[ordered]@{
 schema=1;kind='kevin-autonomy-public';generated_at=$obj.generated_at;state=$obj.state;fingerprint=$obj.fingerprint;
 drift_count=@($obj.drift).Count;selected_action=$(if($obj.selected_action){$obj.selected_action.verb}else{$null});
 action_ok=$(if($obj.action_result){[bool]$obj.action_result.ok}else{$null});failure_budget=$obj.failure_budget;
 work_conserving=$obj.work_conserving;safety=$obj.safety
}
$semantic=[ordered]@{state=$safe.state;fingerprint=$safe.fingerprint;drift_count=$safe.drift_count;selected_action=$safe.selected_action;action_ok=$safe.action_ok;failure_budget=$safe.failure_budget;work_conserving=$safe.work_conserving;safety=$safe.safety}
$semanticJson=$semantic|ConvertTo-Json -Depth 20 -Compress
$sha=[System.Security.Cryptography.SHA256]::Create()
try{$bytes=[Text.Encoding]::UTF8.GetBytes($semanticJson);$safe.semantic_hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')}finally{$sha.Dispose()}
$payload=$safe|ConvertTo-Json -Depth 20
$endpoint=("repos/{0}/contents/{1}" -f $Repo,$RemotePath)
$lastError=''

for($attempt=1;$attempt -le 3;$attempt++){
  $ref=[Uri]::EscapeDataString($Branch)
  $get=Invoke-ExactNative -Executable $GhExe -Argv @('api',("{0}?ref={1}" -f $endpoint,$ref),'-H','Accept: application/vnd.github+json')
  $remote=$null
  if($get.ExitCode -eq 0){
    try{$remote=$get.Stdout|ConvertFrom-Json}catch{Fail -Stage 'remote-json-parse' -Code 23 -Detail $_.Exception.Message}
  } elseif((One-Line ($get.Stdout+' '+$get.Stderr)) -notmatch '404|Not Found') {
    $lastError=("GET exit={0} stdout={1} stderr={2}" -f $get.ExitCode,(One-Line $get.Stdout),(One-Line $get.Stderr))
    if($attempt -lt 3){Write-Output ("AUTONOMY_RETRY stage=get attempt={0}" -f $attempt);Start-Sleep -Seconds $attempt;continue}
    Fail -Stage 'remote-get' -Code 24 -Detail $lastError
  }

  if($remote){
    try{
      $decodedText=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$remote.content -replace '\s','')))
      $decoded=$decodedText|ConvertFrom-Json
      if([string]$decoded.semantic_hash -eq [string]$safe.semantic_hash){Write-Output 'AUTONOMY_UNCHANGED';exit 0}
    }catch{}
  }

  $body=[ordered]@{message='kevin autonomy telemetry';content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload));branch=$Branch}
  if($remote -and $remote.sha){$body.sha=[string]$remote.sha}
  $bodyPath=Join-Path $env:TEMP ("kevin-autonomy-gh-body-{0}.json" -f [guid]::NewGuid().ToString('N'))
  try{
    [IO.File]::WriteAllText($bodyPath,($body|ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding($false)))
    $put=Invoke-ExactNative -Executable $GhExe -Argv @('api','--method','PUT',$endpoint,'--input',$bodyPath,'-H','Accept: application/vnd.github+json')
  } finally {Remove-Item -LiteralPath $bodyPath -Force -ErrorAction SilentlyContinue}
  if($put.ExitCode -eq 0){
    $publishedSha=''
    try{$po=$put.Stdout|ConvertFrom-Json;if($po.content -and $po.content.sha){$publishedSha=[string]$po.content.sha}}catch{}
    Write-Output ("AUTONOMY_PUBLISHED sha={0}" -f $publishedSha)
    exit 0
  }
  $lastError=("PUT exit={0} stdout={1} stderr={2}" -f $put.ExitCode,(One-Line $put.Stdout),(One-Line $put.Stderr))
  if($attempt -lt 3){Write-Output ("AUTONOMY_RETRY stage=publish attempt={0}" -f $attempt);Start-Sleep -Seconds $attempt;continue}
}

Fail -Stage 'publish' -Code 25 -Detail $lastError
