param(
  [ValidateSet('Run','SelfTest')]
  [string]$Mode='Run',
  [string]$MissionId=''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$Utf8=New-Object System.Text.UTF8Encoding($false)

$Workspace=Join-Path $env:USERPROFILE '.openclaw\workspace'
$Control=Join-Path $Workspace 'ControlPlane'
$CatalogPath=Join-Path $Control 'mission-catalog-v1.json'
$LabRoot=Join-Path $Workspace 'mission-lab'
$Reports=Join-Path $Workspace 'reports'
if(-not(Test-Path -LiteralPath $Reports)){$Reports=Join-Path $Workspace 'Reports'}
$StateDir=Join-Path $Control 'State'
$StatePath=Join-Path $StateDir 'mission-worker-state-v1.json'
$LatestPath=Join-Path $Reports 'mission-factory-latest.json'
$StatePy=Join-Path $Workspace 'helper_kevin_state.py'
foreach($d in @($Control,$LabRoot,$Reports,$StateDir)){if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}}

function Write-JsonAtomic {
  param([Parameter(Mandatory=$true)]$Object,[Parameter(Mandatory=$true)][string]$Path)
  $tmp="$Path.tmp-$PID"
  [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth 30),$Utf8)
  Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function ConvertTo-Win32CommandLineArg {
  param([AllowEmptyString()][string]$Value)
  if($null -eq $Value -or $Value.Length -eq 0){return '""'}
  if($Value -notmatch '[\s"]'){return $Value}
  $sb=New-Object System.Text.StringBuilder
  [void]$sb.Append('"');$slashes=0
  for($i=0;$i -lt $Value.Length;$i++){
    $ch=$Value[$i]
    if($ch -eq '\'){$slashes++;continue}
    if($ch -eq '"'){
      if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))}
      [void]$sb.Append('\"');$slashes=0;continue
    }
    if($slashes -gt 0){[void]$sb.Append(('\' * $slashes));$slashes=0}
    [void]$sb.Append($ch)
  }
  if($slashes -gt 0){[void]$sb.Append(('\' * ($slashes*2)))}
  [void]$sb.Append('"')
  return $sb.ToString()
}

function Invoke-ExactNative {
  param(
    [Parameter(Mandatory=$true)][string]$Executable,
    [Parameter(Mandatory=$true)][string[]]$Argv,
    [int]$TimeoutSeconds=0,
    [string]$WorkingDirectory=''
  )
  $psi=New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Executable
  $psi.Arguments=(($Argv|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)}) -join ' ')
  $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory}
  $p=New-Object System.Diagnostics.Process;$p.StartInfo=$psi
  if(-not $p.Start()){throw "Could not start native process: $Executable"}
  $outTask=$p.StandardOutput.ReadToEndAsync();$errTask=$p.StandardError.ReadToEndAsync()
  $timedOut=$false
  if($TimeoutSeconds -gt 0){if(-not $p.WaitForExit($TimeoutSeconds*1000)){$timedOut=$true;try{$p.Kill()}catch{};$p.WaitForExit()}}else{$p.WaitForExit()}
  $r=[pscustomobject]@{ExitCode=$(if($timedOut){124}else{[int]$p.ExitCode});Stdout=[string]$outTask.Result;Stderr=[string]$errTask.Result;TimedOut=$timedOut}
  $p.Dispose();return $r
}

function Read-JsonFile([string]$Path){if(-not(Test-Path -LiteralPath $Path)){return $null};try{return (Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)}catch{return $null}}
function Get-PropertyValue($Object,[string]$Name){if($null -eq $Object){return $null};$p=$Object.PSObject.Properties[$Name];if($null -eq $p){return $null};return $p.Value}

function Get-Catalog {
  if(-not(Test-Path -LiteralPath $CatalogPath)){throw "Mission catalog missing: $CatalogPath"}
  $c=Get-Content -LiteralPath $CatalogPath -Raw|ConvertFrom-Json
  if([string]$c.kind -ne 'kevin-mission-catalog' -or [string]$c.version -ne '1.0'){throw 'Mission catalog schema/version mismatch.'}
  if(-not [bool]$c.policy.candidate_only -or [bool]$c.policy.allow_production_mutation -or [bool]$c.policy.allow_permission_changes -or [bool]$c.policy.allow_arbitrary_shell){throw 'Mission catalog violates candidate-only authority boundary.'}
  return $c
}

function Get-Mission($Catalog,[string]$Id){return @($Catalog.missions|Where-Object{[string]$_.id -eq $Id}|Select-Object -First 1)[0]}

function Get-OpenClawRuntime {
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not $node){$node=Get-Command node -ErrorAction SilentlyContinue};if(-not $node){throw 'node.exe not found.'}
  $cli=Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
  if(-not(Test-Path -LiteralPath $cli)){throw "OpenClaw runtime missing: $cli"}
  return [pscustomobject]@{Node=$node.Source;Cli=$cli}
}

function Get-SystemStatus {
  $py=Get-Command python.exe -ErrorAction SilentlyContinue;if(-not $py){$py=Get-Command python -ErrorAction SilentlyContinue};if(-not $py){throw 'python not found.'}
  $helper=Join-Path $Workspace 'helper_system_status.py';if(-not(Test-Path -LiteralPath $helper)){throw 'helper_system_status.py missing.'}
  $r=Invoke-ExactNative -Executable $py.Source -Argv @($helper,'--json') -TimeoutSeconds 40 -WorkingDirectory $Workspace
  if($r.ExitCode -ne 0){throw "System status probe failed exit=$($r.ExitCode): $($r.Stderr)"}
  $s=$r.Stdout|ConvertFrom-Json
  if(-not [bool]$s.ok){throw 'System status returned ok=false.'}
  if([int]$s.ram_load_percent -ge 85){throw "RESOURCE_GUARD ram=$($s.ram_load_percent)%"}
  if([double]$s.disk_free_gb -lt 20){throw "RESOURCE_GUARD disk=$($s.disk_free_gb)GB"}
  if([string]$s.ollama_status -ne 'running'){throw "RESOURCE_GUARD ollama=$($s.ollama_status)"}
  if([string]$s.gateway_status -ne 'open'){throw "RESOURCE_GUARD gateway=$($s.gateway_status)"}
  return $s
}

function Extract-AssistantText($Outer){
  $result=Get-PropertyValue $Outer 'result';if(-not $result){return ''}
  $meta=Get-PropertyValue $result 'meta'
  if($meta){$v=Get-PropertyValue $meta 'finalAssistantVisibleText';if($v){return [string]$v}}
  $payloads=Get-PropertyValue $result 'payloads'
  if($payloads){$first=@($payloads)|Select-Object -First 1;if($first){$t=Get-PropertyValue $first 'text';if($t){return [string]$t}}}
  return ''
}

function Extract-JsonObject([string]$Text){
  if([string]::IsNullOrWhiteSpace($Text)){throw 'Model returned empty visible text.'}
  $t=$Text.Trim();$first=$t.IndexOf('{');$last=$t.LastIndexOf('}')
  if($first -lt 0 -or $last -le $first){throw 'Model response contained no JSON object.'}
  return ($t.Substring($first,$last-$first+1)|ConvertFrom-Json)
}

function Save-CandidateFiles($Proposal,[string]$CandidateRoot,[int]$MaxFiles,[int]$MaxChars){
  $files=@($Proposal.candidate_files)
  if($files.Count -gt $MaxFiles){throw "Candidate file count exceeded cap: $($files.Count)>$MaxFiles"}
  $chars=0
  foreach($f in $files){
    $rel=([string]$f.path).Replace('\','/')
    if([string]::IsNullOrWhiteSpace($rel)){throw 'Candidate path was empty.'}
    if([IO.Path]::IsPathRooted($rel) -or $rel -match '(^|/)\.\.(/|$)' -or $rel -match '^[A-Za-z]:'){throw "Unsafe candidate path: $rel"}
    if($rel -notmatch '^[A-Za-z0-9._/-]+$'){throw "Candidate path contains forbidden characters: $rel"}
    $content=[string]$f.content;$chars+=$content.Length;if($chars -gt $MaxChars){throw "Candidate content exceeded character cap: $chars>$MaxChars"}
    $dest=Join-Path $CandidateRoot $rel;$parent=Split-Path -Parent $dest;if(-not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
    [IO.File]::WriteAllText($dest,$content,$Utf8)
  }
  return [pscustomobject]@{count=$files.Count;chars=$chars}
}

$Catalog=Get-Catalog
if($Mode -eq 'SelfTest'){
  $ids=@($Catalog.missions|ForEach-Object{[string]$_.id})
  if($ids.Count -lt 1){throw 'Mission catalog is empty.'}
  if(($ids|Select-Object -Unique).Count -ne $ids.Count){throw 'Mission catalog contains duplicate ids.'}
  Write-Output ("MISSION_WORKER_SELF_TEST_PASS missions={0}" -f $ids.Count);exit 0
}

if([string]::IsNullOrWhiteSpace($MissionId)){throw 'MissionId is required in Run mode.'}
$Mission=Get-Mission -Catalog $Catalog -Id $MissionId
if(-not $Mission){throw "MissionId is not in the local hash-pinned catalog: $MissionId"}

$mutex=New-Object System.Threading.Mutex($false,'Global\Kevin14BEngineeringWorkerV1');$owned=$false
$stamp=(Get-Date).ToString('yyyyMMdd-HHmmss');$runRoot=Join-Path (Join-Path $LabRoot $MissionId) $stamp;$candidateRoot=Join-Path $runRoot 'candidate'
New-Item -ItemType Directory -Path $candidateRoot -Force|Out-Null
$latest=[ordered]@{schema=1;kind='kevin-mission-factory-result';generated_at=(Get-Date).ToString('o');mission_id=$MissionId;state='STARTING';run_path=$runRoot;candidate_only=$true}
Write-JsonAtomic $latest $LatestPath

try{
  $owned=$mutex.WaitOne(0);if(-not $owned){$latest.state='SKIP_14B_BUSY';$latest.generated_at=(Get-Date).ToString('o');Write-JsonAtomic $latest $LatestPath;Write-Output 'MISSION_WORKER_SKIP_14B_BUSY';exit 0}
  $sys=Get-SystemStatus
  $rt=Get-OpenClawRuntime
  if(Test-Path -LiteralPath $StatePy){try{& python $StatePy start design-forge ("Mission Factory: "+$MissionId) forge --source control-plane|Out-Null}catch{}}
  $prompt=@"
You are Kevin's isolated Candidate Engineering Worker. You are not production Kevin and you have no authority to promote or execute generated artifacts.

MISSION ID: $MissionId
TITLE: $($Mission.title)
GOAL: $($Mission.goal)

NON-NEGOTIABLE CONTRACT:
- Candidate-only work. Never modify production, permissions, credentials, services, automations, canonical memory, or owner authority.
- Never output or request secrets, tokens, usernames, private paths, or host-specific identifiers.
- Never propose arbitrary shell access as the solution.
- Generated code or configuration is source material only and must not be executed or promoted by this worker.
- Preserve evidence, rollback, idempotency, bounded retries, semantic-success checks, and fail-closed behavior where applicable.
- Prefer small deterministic components and typed interfaces.
- Return at most $([int]$Catalog.policy.max_candidate_files) candidate files and at most $([int]$Catalog.policy.max_candidate_chars) total candidate characters.

Return ONLY valid JSON with this shape:
{
  "mission_id":"$MissionId",
  "title":"short candidate title",
  "engineering_summary":"what this improves and why",
  "candidate_files":[{"path":"relative/path","purpose":"purpose","content":"candidate source"}],
  "tests":["test"],
  "risks":["risk"],
  "assumptions":["assumption"],
  "unknowns":["unknown"],
  "next_experiment":"next bounded experiment",
  "handoff":{"semantic_success_criteria":["criterion"],"evidence_required":["evidence"],"next_owner":"adversarial-review"}
}
"@
  $promptPath=Join-Path $runRoot 'candidate.prompt.txt';[IO.File]::WriteAllText($promptPath,$prompt,$Utf8)
  if((Get-Item -LiteralPath $promptPath).Length -gt 16000){throw 'Candidate prompt exceeded 16KB cap.'}
  $session="mission-$stamp-$MissionId"
  $gen=Invoke-ExactNative -Executable $rt.Node -Argv @($rt.Cli,'agent','--agent','kevin-lab-qwen','--session-key',$session,'--json','--timeout','180','--message-file',$promptPath) -TimeoutSeconds 220 -WorkingDirectory $Workspace
  if($gen.ExitCode -ne 0){throw "Candidate model run failed exit=$($gen.ExitCode): $($gen.Stderr)"}
  $outer=$gen.Stdout|ConvertFrom-Json;$proposal=Extract-JsonObject (Extract-AssistantText $outer)
  if([string]$proposal.mission_id -ne $MissionId){throw "Candidate mission mismatch: $($proposal.mission_id)"}
  $stats=Save-CandidateFiles -Proposal $proposal -CandidateRoot $candidateRoot -MaxFiles ([int]$Catalog.policy.max_candidate_files) -MaxChars ([int]$Catalog.policy.max_candidate_chars)
  Write-JsonAtomic $proposal (Join-Path $runRoot 'proposal.json')

  $proposalCompact=$proposal|ConvertTo-Json -Depth 15 -Compress
  if($proposalCompact.Length -gt 24000){$proposalCompact=$proposalCompact.Substring(0,24000)}
  $reviewPrompt=@"
You are Kevin's adversarial candidate reviewer. Review the candidate below against its mission and the non-negotiable safety contract. Do not execute it. Look specifically for false-success claims, missing evidence, unsafe authority expansion, arbitrary shell patterns, privacy leaks, weak rollback, replay/idempotency gaps, and tests that do not prove the claimed outcome.

MISSION ID: $MissionId
GOAL: $($Mission.goal)
MINIMUM PASS SCORE: $([int]$Catalog.policy.minimum_review_score)

CANDIDATE JSON:
$proposalCompact

Return ONLY valid JSON:
{
  "mission_id":"$MissionId",
  "verdict":"PASS or REJECT",
  "score":0,
  "failures":["failure"],
  "security_findings":["finding"],
  "reusable_lesson":"lesson",
  "next_experiment":"next experiment",
  "semantic_success":true
}
"@
  $reviewPath=Join-Path $runRoot 'review.prompt.txt';[IO.File]::WriteAllText($reviewPath,$reviewPrompt,$Utf8)
  $review=Invoke-ExactNative -Executable $rt.Node -Argv @($rt.Cli,'agent','--agent','kevin-lab-qwen','--session-key',("review-$stamp-$MissionId"),'--json','--timeout','180','--message-file',$reviewPath) -TimeoutSeconds 220 -WorkingDirectory $Workspace
  if($review.ExitCode -ne 0){throw "Review model run failed exit=$($review.ExitCode): $($review.Stderr)"}
  $reviewOuter=$review.Stdout|ConvertFrom-Json;$evaluation=Extract-JsonObject (Extract-AssistantText $reviewOuter)
  if([string]$evaluation.mission_id -ne $MissionId){throw 'Review mission mismatch.'}
  $score=[int]$evaluation.score;$securityCount=@($evaluation.security_findings).Count
  $passed=([string]$evaluation.verdict -eq 'PASS' -and $score -ge [int]$Catalog.policy.minimum_review_score -and $securityCount -eq 0 -and [bool]$evaluation.semantic_success)
  Write-JsonAtomic $evaluation (Join-Path $runRoot 'evaluation.json')

  $result=[ordered]@{schema=1;kind='kevin-mission-factory-result';generated_at=(Get-Date).ToString('o');mission_id=$MissionId;state=$(if($passed){'PASS'}else{'REJECT'});run_path=$runRoot;candidate_files=[int]$stats.count;candidate_chars=[int]$stats.chars;review_score=$score;security_findings=$securityCount;reusable_lesson=[string]$evaluation.reusable_lesson;next_experiment=[string]$evaluation.next_experiment;candidate_only=$true;safety=[ordered]@{production_mutation=$false;authority_expansion=$false;generated_code_executed=$false}}
  Write-JsonAtomic $result $StatePath;Write-JsonAtomic $result $LatestPath
  if(Test-Path -LiteralPath $StatePy){try{& python $StatePy finish design-forge $result.state ("Mission Factory "+$MissionId+" "+$result.state+" score="+$score) --source control-plane|Out-Null}catch{}}
  Write-Output ("MISSION_WORKER_COMPLETE mission={0} state={1} score={2} files={3}" -f $MissionId,$result.state,$score,$stats.count)
  exit 0
}catch{
  $msg=[string]$_.Exception.Message
  $result=[ordered]@{schema=1;kind='kevin-mission-factory-result';generated_at=(Get-Date).ToString('o');mission_id=$MissionId;state='INFRA_FAILURE';run_path=$runRoot;error=$msg;candidate_only=$true;safety=[ordered]@{production_mutation=$false;authority_expansion=$false;generated_code_executed=$false}}
  Write-JsonAtomic $result $StatePath;Write-JsonAtomic $result $LatestPath
  if(Test-Path -LiteralPath $StatePy){try{& python $StatePy finish design-forge FAIL $msg --source control-plane|Out-Null}catch{}}
  Write-Output ("MISSION_WORKER_ERROR mission={0} detail={1}" -f $MissionId,($msg -replace '[\r\n]+',' '));exit 2
}finally{
  if($owned){try{$mutex.ReleaseMutex()}catch{}};$mutex.Dispose()
}
