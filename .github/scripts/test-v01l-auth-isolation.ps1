$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0

$Bridge='control-plane/actuator/kevin-autonomy-bridge-v0.1l.ps1'
$Resume='control-plane/actuator/KEVIN-AUTONOMY-TELEMETRY-AUTH-RESUME-v0.1l.ps1'

foreach($p in @($Bridge,$Resume)){
  $tokens=$null;$errors=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $p),[ref]$tokens,[ref]$errors)
  if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("$p line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw "Parse failed: $p"}
  Write-Host "PASS parse $p"
}

& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Resume -Mode ValidateTransport
if($LASTEXITCODE -ne 0){throw 'Transport validation failed'}

$src=@'
using System;
class Program {
  static int Main(string[] args) {
    if(!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("GH_TOKEN"))) return 71;
    if(!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("GITHUB_TOKEN"))) return 72;
    if(!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("GH_ENTERPRISE_TOKEN"))) return 73;
    if(!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("GITHUB_ENTERPRISE_TOKEN"))) return 74;
    if(args.Length < 2 || args[0] != "api") return 75;
    Console.Write("{\"message\":\"Not Found\",\"status\":404}");
    Console.Error.Write("HTTP 404 Not Found");
    return 1;
  }
}
'@
$fake=Join-Path $env:TEMP 'fakegh-v01l.exe'
Add-Type -TypeDefinition $src -Language CSharp -OutputAssembly $fake -OutputType ConsoleApplication
$r=Join-Path $env:TEMP 'v01l-report';New-Item -ItemType Directory -Path $r -Force|Out-Null
$obj=[ordered]@{generated_at='2026-08-29T22:00:00Z';state='HEALTHY';fingerprint='x';drift=@();selected_action=$null;action_result=$null;failure_budget=[ordered]@{family='';attempts=0;cooldown_until=$null};work_conserving=[ordered]@{status='TEST'};safety=[ordered]@{green_only=$true}}
[IO.File]::WriteAllText((Join-Path $r 'autonomy-latest.json'),($obj|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)))
$env:KEVIN_AUTONOMY_REPORTS_DIR=$r;$env:KEVIN_GH_EXE=$fake;$env:KEVIN_GH_AUTH_MODE='stored';$env:GH_TOKEN='intentionally-invalid';$env:GITHUB_TOKEN='intentionally-invalid';$env:GH_ENTERPRISE_TOKEN='intentionally-invalid';$env:GITHUB_ENTERPRISE_TOKEN='intentionally-invalid'
$fakeOut=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Bridge
$fakeCode=$LASTEXITCODE
if($fakeCode -ne 25){throw "Expected fake-gh publish-stage exit 25 after auth isolation, got $fakeCode :: $($fakeOut -join ' | ')"}
Write-Host 'PASS stored mode removed inherited GitHub token variables before gh launch.'

foreach($n in @('KEVIN_GH_AUTH_MODE','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath ("Env:{0}" -f $n) -ErrorAction SilentlyContinue}
$env:KEVIN_GH_EXE=(Get-Command gh.exe).Source
$env:KEVIN_AUTONOMY_REPO='hessmodee/KEVIN-WORK';$env:KEVIN_AUTONOMY_BRANCH='kevin-autonomy-actuator-v0.1';$env:KEVIN_AUTONOMY_PATH='reports/_ci-autonomy-v01l.json';$env:KEVIN_AUTONOMY_REPORTS_DIR=$r
if(-not $env:GH_TOKEN){throw 'CI GH_TOKEN missing for real GitHub ambient-mode test.'}
Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
$obj.generated_at=(Get-Date).ToString('o');$obj.fingerprint='CI-V01L';[IO.File]::WriteAllText((Join-Path $r 'autonomy-latest.json'),($obj|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)))
$out1=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Bridge
if($LASTEXITCODE -ne 0 -or ($out1 -join "`n") -notmatch 'AUTONOMY_PUBLISHED'){throw "First real publish failed: $($out1 -join ' | ')"}
$out2=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Bridge
if($LASTEXITCODE -ne 0 -or ($out2 -join "`n") -notmatch 'AUTONOMY_UNCHANGED'){throw "Real no-op proof failed: $($out2 -join ' | ')"}
$remote=gh api 'repos/hessmodee/KEVIN-WORK/contents/reports/_ci-autonomy-v01l.json?ref=kevin-autonomy-actuator-v0.1'|ConvertFrom-Json
gh api --method DELETE 'repos/hessmodee/KEVIN-WORK/contents/reports/_ci-autonomy-v01l.json' -f message='cleanup v0.1l auth test' -f sha=$remote.sha -f branch='kevin-autonomy-actuator-v0.1' | Out-Null
Write-Host 'PASS real GitHub ambient publish -> no-op -> cleanup.'

$b=Get-Content $Bridge -Raw;$rr=Get-Content $Resume -Raw
foreach($n in @('KEVIN_GH_AUTH_MODE','GH_TOKEN','GITHUB_TOKEN','inherited_token_env=removed')){if(-not $b.Contains($n)){throw "Bridge missing contract: $n"}}
foreach($n in @('kevin-intentional-invalid-token','KEVIN_GH_AUTH_MODE=stored','Telemetry job stored exact argv + stored-credential mode','AUTONOMY TELEMETRY v0.1l INSTALLED + PROVEN')){if(-not $rr.Contains($n)){throw "Resume missing contract: $n"}}
Write-Host 'PASS v0.1l credential-isolation contracts.'
