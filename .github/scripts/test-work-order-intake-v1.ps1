$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0

$repo=(Resolve-Path '.').Path
$fakeProfile=Join-Path $env:TEMP ('kevin-wo-v1-'+[guid]::NewGuid().ToString('N'))
$oldProfile=$env:USERPROFILE
try{
  $env:USERPROFILE=$fakeProfile
  $ws=Join-Path $fakeProfile '.openclaw\workspace';$cp=Join-Path $ws 'ControlPlane';$reports=Join-Path $ws 'reports'
  New-Item -ItemType Directory -Path $cp,$reports -Force|Out-Null
  Copy-Item 'control-plane/dispatcher/mission-catalog-v1.json' (Join-Path $cp 'mission-catalog-v1.json')
  Copy-Item 'control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1' (Join-Path $cp 'kevin-mission-dispatcher-v0.1.ps1')
  Copy-Item 'control-plane/intake/kevin-work-order-intake-v0.1.ps1' (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1')
  Copy-Item 'control-plane/actuator/kevin-autonomy-actuator-v0.1.ps1' (Join-Path $cp 'kevin-autonomy-actuator-v0.1.ps1')
  $fakeBridge=Join-Path $cp 'kevin-autonomy-bridge-v0.1.ps1'
  [IO.File]::WriteAllText($fakeBridge,"Write-Output 'AUTONOMY_UNCHANGED'`r`nexit 0`r`n",(New-Object Text.UTF8Encoding($false)))

  $src=@'
using System;
using System.Text;
class Program {
  static int Main(string[] args) {
    foreach (var n in new[]{"GH_TOKEN","GITHUB_TOKEN","GH_ENTERPRISE_TOKEN","GITHUB_ENTERPRISE_TOKEN"}) {
      if (!String.IsNullOrEmpty(Environment.GetEnvironmentVariable(n))) { Console.Error.Write("TOKEN_ENV_NOT_REMOVED:"+n); return 71; }
    }
    if (args.Length < 2 || args[0] != "api") return 72;
    var joined=String.Join(" ",args);
    bool isPut=joined.Contains("--method PUT");
    if (joined.Contains("contents/control-plane/orders/CURRENT.json")) {
      var mode=Environment.GetEnvironmentVariable("FAKE_ORDER_MODE") ?? "valid";
      var created=DateTimeOffset.UtcNow.AddMinutes(-1).ToString("o");
      var expires=DateTimeOffset.UtcNow.AddHours(1).ToString("o");
      string order;
      if (mode=="malformed") {
        order="{\"schema\":1,\"kind\":\"kevin-work-order\",\"idempotency_key\":\"malformed-key-001\",\"created_at\":\""+created+"\",\"expires_at\":\""+expires+"\",\"authority_class\":\"GREEN\",\"verb\":\"run_reconcile\",\"target\":\"autonomy\"}";
      } else {
        order="{\"schema\":1,\"kind\":\"kevin-work-order\",\"id\":\"ci-order-0001\",\"idempotency_key\":\"ci-idem-0001\",\"created_at\":\""+created+"\",\"expires_at\":\""+expires+"\",\"authority_class\":\"GREEN\",\"verb\":\"refresh_autonomy_telemetry\",\"target\":\"autonomy-telemetry\",\"reason\":\"CI typed work-order regression\"}";
      }
      var b64=Convert.ToBase64String(Encoding.UTF8.GetBytes(order));
      Console.Write("{\"sha\":\"fake-order-sha\",\"encoding\":\"base64\",\"content\":\""+b64+"\"}");
      return 0;
    }
    if (joined.Contains("contents/reports/control-plane-latest.json")) {
      if (isPut) { Console.Write("{\"content\":{\"sha\":\"ack-sha\"}}"); return 0; }
      Console.Write("{\"message\":\"Not Found\",\"status\":404}"); Console.Error.Write("HTTP 404 Not Found"); return 1;
    }
    Console.Error.Write("UNEXPECTED_ARGS:"+joined);return 73;
  }
}
'@
  $fakeGh=Join-Path $env:TEMP 'fakegh-control-plane-v1.exe'
  Add-Type -TypeDefinition $src -Language CSharp -OutputAssembly $fakeGh -OutputType ConsoleApplication
  $env:KEVIN_GH_EXE=$fakeGh;$env:GH_TOKEN='poison';$env:GITHUB_TOKEN='poison';$env:GH_ENTERPRISE_TOKEN='poison';$env:GITHUB_ENTERPRISE_TOKEN='poison'

  $env:FAKE_ORDER_MODE='valid'
  $first=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode Poll
  if($LASTEXITCODE -ne 0 -or ($first -join "`n") -notmatch 'WORK_ORDER_VERIFIED'){throw "Valid work order failed: $($first -join ' | ')"}
  Write-Host ($first -join "`n")
  $latest=Get-Content (Join-Path $reports 'work-order-latest.json') -Raw|ConvertFrom-Json
  if($latest.status -ne 'VERIFIED' -or $latest.verb -ne 'refresh_autonomy_telemetry'){throw 'Valid work-order acknowledgement mismatch.'}

  $second=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode Poll
  if($LASTEXITCODE -ne 0 -or ($second -join "`n") -notmatch 'WORK_ORDER_REPLAY_IGNORED'){throw "Replay protection failed: $($second -join ' | ')"}
  Write-Host ($second -join "`n")

  $env:FAKE_ORDER_MODE='malformed'
  $third=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $cp 'kevin-work-order-intake-v0.1.ps1') -Mode Poll 2>&1
  if($LASTEXITCODE -ne 2 -or ($third -join "`n") -notmatch 'WORK_ORDER_FAILED'){throw "Malformed order did not fail cleanly: exit=$LASTEXITCODE output=$($third -join ' | ')"}
  Write-Host ($third -join "`n")

  Write-Host 'WORK_ORDER_INTAKE_E2E_PASS'
} finally {
  $env:USERPROFILE=$oldProfile
  foreach($n in @('KEVIN_GH_EXE','GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN','FAKE_ORDER_MODE')){Remove-Item -LiteralPath ("Env:{0}" -f $n) -ErrorAction SilentlyContinue}
  Remove-Item -LiteralPath $fakeProfile -Recurse -Force -ErrorAction SilentlyContinue
}
