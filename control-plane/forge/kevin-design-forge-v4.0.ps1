param(
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Root = Join-Path $env:USERPROFILE '.openclaw'
$Workspace = Join-Path $Root 'workspace'
$Reports = Join-Path $Workspace 'reports'
$Lab = Join-Path $Workspace 'forge-designs'
$DemandRoot = Join-Path $Workspace 'forge-demands'
$ArchiveRoot = Join-Path $DemandRoot 'archive'
$DemandPath = Join-Path $DemandRoot 'CURRENT.json'
$StateFile = Join-Path $Lab 'design-forge-state.json'
$ErrorFile = Join-Path $Lab 'design-forge-last-error.txt'
$StatePy = Join-Path $Workspace 'helper_kevin_state.py'
foreach($d in @($Lab,$DemandRoot,$ArchiveRoot)){New-Item -ItemType Directory -Force -Path $d | Out-Null}

function Write-Utf8Atomic([string]$Path,[string]$Text){
    $tmp=$Path+'.tmp-'+$PID+'-'+[guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,$Text,$Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Write-JsonAtomic([string]$Path,[object]$Object){Write-Utf8Atomic $Path ($Object|ConvertTo-Json -Depth 20)}
function Finish-State([string]$Result,[string]$Summary){
    if(Test-Path -LiteralPath $StatePy -PathType Leaf){
        try{& python $StatePy finish design-forge $Result $Summary --source forge | Out-Null}catch{}
    }
}
function Start-State([string]$Summary){
    if(Test-Path -LiteralPath $StatePy -PathType Leaf){
        try{& python $StatePy start design-forge $Summary forge --source forge | Out-Null}catch{}
    }
}
function Safe-OneLine([string]$Text,[int]$Max=500){
    if($null-eq$Text){return ''}
    $s=($Text -replace '[\r\n]+',' ').Trim()
    if($s.Length-gt$Max){$s=$s.Substring(0,$Max)}
    return $s
}
function ConvertTo-Win32CommandLineArg([string]$Value){
    if($null-eq$Value -or $Value.Length-eq0){return '""'}
    if($Value-notmatch'[\s"]'){return $Value}
    $sb=New-Object System.Text.StringBuilder;[void]$sb.Append('"');$slashes=0
    for($i=0;$i-lt$Value.Length;$i++){
        $ch=$Value[$i]
        if($ch-eq'\'){$slashes++;continue}
        if($ch-eq'"'){
            if($slashes-gt0){[void]$sb.Append(('\'*($slashes*2)))}
            [void]$sb.Append('\"');$slashes=0;continue
        }
        if($slashes-gt0){[void]$sb.Append(('\'*$slashes));$slashes=0}
        [void]$sb.Append($ch)
    }
    if($slashes-gt0){[void]$sb.Append(('\'*($slashes*2)))}
    [void]$sb.Append('"');return $sb.ToString()
}
function Format-WinArgs([string[]]$ArgList){return (($ArgList|ForEach-Object{ConvertTo-Win32CommandLineArg ([string]$_)})-join' ')}

function Assert-Demand([object]$d){
    if($null-eq$d){throw 'forge demand is null'}
    $allowed=@('schema','kind','id','authority_class','created_at','expires_at','goal','acceptance_criteria','downstream_consumer','failure_family','hypothesis_id','attempt','max_attempts','reason')
    foreach($p in $d.PSObject.Properties.Name){if($allowed-notcontains[string]$p){throw('unknown forge demand property '+$p)}}
    foreach($n in @('schema','kind','id','authority_class','created_at','expires_at','goal','acceptance_criteria','downstream_consumer','failure_family','hypothesis_id','attempt','max_attempts')){if($null-eq$d.PSObject.Properties[$n]){throw('missing forge demand property '+$n)}}
    if([int]$d.schema-ne1 -or [string]$d.kind-ne'kevin-forge-demand' -or [string]$d.authority_class-ne'GREEN'){throw 'forge demand schema/kind/authority mismatch'}
    if([string]$d.id-notmatch'^[A-Za-z0-9._-]{8,96}$'){throw 'forge demand id invalid'}
    if([string]$d.failure_family-notmatch'^[A-Za-z0-9._-]{3,80}$' -or [string]$d.hypothesis_id-notmatch'^[A-Za-z0-9._-]{3,80}$'){throw 'failure/hypothesis identity invalid'}
    $goal=[string]$d.goal;if($goal.Length-lt10 -or $goal.Length-gt1500){throw 'forge goal outside 10..1500 chars'}
    $criteria=@($d.acceptance_criteria);if($criteria.Count-lt1 -or $criteria.Count-gt12){throw 'acceptance criteria count outside 1..12'}
    foreach($c in $criteria){$s=[string]$c;if($s.Length-lt3 -or $s.Length-gt300){throw 'acceptance criterion outside 3..300 chars'}}
    if(@('STAGING','SKILL_LAB','INTEGRATION_PR','BOUNDED_EXPERIMENT') -notcontains ([string]$d.downstream_consumer).ToUpperInvariant()){throw 'downstream consumer not allowlisted'}
    if([int]$d.max_attempts-ne3){throw 'max_attempts must equal 3'}
    if([int]$d.attempt-lt1 -or [int]$d.attempt-gt3){throw 'attempt outside 1..3'}
    $created=[DateTimeOffset]::Parse([string]$d.created_at);$expires=[DateTimeOffset]::Parse([string]$d.expires_at);$now=[DateTimeOffset]::Now
    if($expires-le$now){throw 'forge demand expired'}
    if($created-gt$now.AddMinutes(10)){throw 'forge demand created_at too far in future'}
    if(($expires-$created).TotalHours-gt24){throw 'forge demand validity exceeds 24 hours'}
}
function Archive-Demand([object]$d,[string]$Suffix){
    $id=if($d -and $d.PSObject.Properties['id']){[string]$d.id}else{'unknown-'+(Get-Date -Format 'yyyyMMddHHmmss')}
    $safe=($id -replace '[^A-Za-z0-9._-]','_')
    $dest=Join-Path $ArchiveRoot ($safe+'.'+$Suffix+'.json')
    if(Test-Path -LiteralPath $DemandPath -PathType Leaf){Move-Item -LiteralPath $DemandPath -Destination $dest -Force}
    return $dest
}
function Write-Idle([string]$Reason){
    $state=[ordered]@{
        schema=2;kind='kevin-design-forge-state';version='4.0';updated_at=(Get-Date).ToString('o')
        status='IDLE_NO_ELIGIBLE_DEMAND';reason=$Reason;last_mission='';last_iteration=0;last_candidate='';demand_driven=$true;round_robin=$false
    }
    Write-JsonAtomic $StateFile $state
    Finish-State 'PASS' ('Design Forge idle: '+$Reason)
    Write-Host ('DESIGN FORGE IDLE '+$Reason)
}

function Invoke-ForgeDemand([object]$d){
    $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
    $sessionKey='design-'+$stamp+'-'+([string]$d.id)
    Start-State ('Design Forge demand: '+[string]$d.id)

    Remove-Item Env:OPENCLAW_PROFILE -ErrorAction SilentlyContinue
    Remove-Item Env:OPENCLAW_STATE_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:OPENCLAW_CONFIG_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:OPENCLAW_GATEWAY_PORT -ErrorAction SilentlyContinue
    Remove-Item Env:OPENCLAW_GATEWAY_TOKEN -ErrorAction SilentlyContinue

    $criteria=(@($d.acceptance_criteria)|ForEach-Object{'- '+[string]$_})-join"`n"
    $prompt=@"
You are Kevin Forge working inside an isolated candidate-design laboratory.

DEMAND ID: $([string]$d.id)
FAILURE FAMILY: $([string]$d.failure_family)
HYPOTHESIS ID: $([string]$d.hypothesis_id)
ATTEMPT: $([int]$d.attempt) of 3
DOWNSTREAM CONSUMER: $([string]$d.downstream_consumer)
GOAL:
$([string]$d.goal)

ACCEPTANCE CRITERIA:
$criteria

NON-NEGOTIABLE:
- This is demand-driven candidate work only; do not invent unrelated missions.
- Production Chat/permissions/configuration remain unchanged.
- No arbitrary shell, browser, admin, sessions, unrestricted filesystem, credentials, secrets or production promotion.
- Do not install or execute generated candidates.
- Prefer deterministic host-side code plus narrow typed interfaces.
- Fail closed and preserve proven behavior.
- Include tests tied directly to the acceptance criteria.
- Maximum 2 candidate files; total candidate content <=16000 characters.
- No usernames, tokens, secrets, ports or host-specific absolute paths.

Return ONLY valid JSON:
{
  "demand_id":"$([string]$d.id)",
  "hypothesis_id":"$([string]$d.hypothesis_id)",
  "title":"short title",
  "engineering_summary":"concise explanation",
  "candidate_files":[{"path":"relative/path","purpose":"purpose","content":"candidate content"}],
  "tests":["test tied to acceptance criteria"],
  "risks":["risk"],
  "promotion_gates":["gate"],
  "next_experiment":"materially different next hypothesis if this one fails"
}
"@
    if($prompt.Length-gt14000){throw 'prompt exceeded 14KB safety cap'}
    $promptFile=Join-Path $env:TEMP ('kevin-forge-'+$stamp+'.prompt.txt')
    $outFile=Join-Path $env:TEMP ('kevin-forge-'+$stamp+'.out.json')
    $errFile=Join-Path $env:TEMP ('kevin-forge-'+$stamp+'.err.txt')
    [IO.File]::WriteAllText($promptFile,$prompt,$Utf8)

    $node=(Get-Command node -ErrorAction Stop).Source
    $openclawJs=Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if(-not(Test-Path -LiteralPath $openclawJs -PathType Leaf)){throw 'OpenClaw runtime missing'}
    $args=@($openclawJs,'agent','--agent','kevin-lab-qwen','--session-key',$sessionKey,'--json','--timeout','180','--message-file',$promptFile)
    $psi=New-Object Diagnostics.ProcessStartInfo
    $psi.FileName=$node;$psi.Arguments=Format-WinArgs $args;$psi.WorkingDirectory=$Workspace;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
    $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $p=New-Object Diagnostics.Process;$p.StartInfo=$psi
    if(-not$p.Start()){throw 'could not start OpenClaw'}
    $stdout=$p.StandardOutput.ReadToEndAsync();$stderr=$p.StandardError.ReadToEndAsync()
    if(-not$p.WaitForExit(210000)){try{$p.Kill()}catch{};$p.WaitForExit();throw 'Design Forge hard timeout'}
    $raw=[string]$stdout.Result;$err=[string]$stderr.Result;$code=[int]$p.ExitCode;$p.Dispose()
    if($code-ne0){throw('OpenClaw exit='+$code+' '+(Safe-OneLine $err 400))}
    if([string]::IsNullOrWhiteSpace($raw)){throw 'OpenClaw output missing'}
    $outer=$raw|ConvertFrom-Json
    $visible=$outer.result.meta.finalAssistantVisibleText
    if(-not$visible){$visible=$outer.result.payloads[0].text}
    if(-not$visible -or [string]$visible-eq'NO_REPLY'){throw 'model returned NO_REPLY'}
    $visible=[string]$visible;$first=$visible.IndexOf('{');$last=$visible.LastIndexOf('}')
    if($first-lt0 -or $last-le$first){throw 'candidate response contained no JSON object'}
    $candidate=$visible.Substring($first,$last-$first+1)|ConvertFrom-Json
    if([string]$candidate.demand_id-ne[string]$d.id -or [string]$candidate.hypothesis_id-ne[string]$d.hypothesis_id){throw 'candidate demand/hypothesis mismatch'}
    $files=@($candidate.candidate_files);if($files.Count-gt2){throw 'too many candidate files'}
    $run=Join-Path $Lab ($stamp+'-'+[string]$d.id+'-a'+[int]$d.attempt)
    $candidateRoot=Join-Path $run 'candidate';New-Item -ItemType Directory -Force -Path $candidateRoot|Out-Null
    $chars=0
    foreach($f in $files){
        $rel=([string]$f.path).Replace('\','/')
        if(-not$rel -or [IO.Path]::IsPathRooted($rel) -or $rel-match'(^|/)\.\.(/|$)' -or $rel-match'^[A-Za-z]:'){throw 'unsafe candidate path'}
        if($rel-notmatch'^[A-Za-z0-9._/-]+$'){throw 'candidate path has forbidden characters'}
        $content=[string]$f.content;$chars+=$content.Length;if($chars-gt16000){throw 'candidate content exceeded 16K cap'}
        $dest=Join-Path $candidateRoot $rel;$parent=Split-Path $dest -Parent;New-Item -ItemType Directory -Force -Path $parent|Out-Null
        [IO.File]::WriteAllText($dest,$content,$Utf8)
    }
    Write-JsonAtomic (Join-Path $run 'proposal.json') $candidate
    $archive=Archive-Demand $d 'consumed'
    $state=[ordered]@{
        schema=2;kind='kevin-design-forge-state';version='4.0';updated_at=(Get-Date).ToString('o')
        status='PASS';demand_id=[string]$d.id;failure_family=[string]$d.failure_family;hypothesis_id=[string]$d.hypothesis_id
        attempt=[int]$d.attempt;last_mission=[string]$d.id;last_iteration=[int]$d.attempt;last_candidate=$run
        downstream_consumer=[string]$d.downstream_consumer;demand_archive=$archive;demand_driven=$true;round_robin=$false
    }
    Write-JsonAtomic $StateFile $state
    Remove-Item -LiteralPath $ErrorFile -Force -ErrorAction SilentlyContinue
    Finish-State 'PASS' ('Design Forge built demanded candidate: '+[string]$d.id)
    Write-Host 'DESIGN FORGE PASS'
    Write-Host ('Demand = '+[string]$d.id)
    Write-Host ('Candidate files = '+$files.Count)
    Write-Host 'Nothing was executed or promoted.'
}

function Invoke-SelfTest{
    $now=[DateTimeOffset]::Now
    $good=[pscustomobject]@{
        schema=1;kind='kevin-forge-demand';id='selftest-demand-001';authority_class='GREEN'
        created_at=$now.ToString('o');expires_at=$now.AddMinutes(10).ToString('o')
        goal='Design one bounded test candidate for selftest acceptance.'
        acceptance_criteria=@('must be deterministic','must stay candidate-only')
        downstream_consumer='STAGING';failure_family='selftest-family';hypothesis_id='hypothesis-a'
        attempt=1;max_attempts=3;reason='selftest'
    }
    Assert-Demand $good
    $bad=$good|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.downstream_consumer='PRODUCTION';$blocked=$false;try{Assert-Demand $bad}catch{$blocked=$true};if(-not$blocked){throw 'production downstream accepted'}
    $bad=$good|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad.max_attempts=99;$blocked=$false;try{Assert-Demand $bad}catch{$blocked=$true};if(-not$blocked){throw 'unbounded attempts accepted'}
    $bad=$good|ConvertTo-Json -Depth 10|ConvertFrom-Json;$bad|Add-Member -NotePropertyName command -NotePropertyValue 'whoami';$blocked=$false;try{Assert-Demand $bad}catch{$blocked=$true};if(-not$blocked){throw 'unknown command field accepted'}
    Write-Host 'KEVIN DESIGN FORGE v4.0 SELFTEST PASS demand_driven=true round_robin=false max_attempts=3 production_promotion=false arbitrary_shell=false'
}

if($SelfTest){Invoke-SelfTest;exit 0}

$mutex=New-Object Threading.Mutex($false,'Global\KevinDesignForgeV4')
$owned=$false
try{
    $owned=$mutex.WaitOne(0)
    if(-not$owned){Write-Host 'DESIGN FORGE SKIP_OVERLAP';exit 0}
    if(-not(Test-Path -LiteralPath $DemandPath -PathType Leaf)){Write-Idle 'no CURRENT forge demand';exit 0}
    $d=$null
    try{$d=Get-Content -LiteralPath $DemandPath -Raw|ConvertFrom-Json;Assert-Demand $d}catch{
        if($d -and $d.PSObject.Properties['expires_at']){
            try{if([DateTimeOffset]::Parse([string]$d.expires_at)-le[DateTimeOffset]::Now){$null=Archive-Demand $d 'expired';Write-Idle 'expired demand archived';exit 0}}catch{}
        }
        $msg=Safe-OneLine $_.Exception.Message
        Write-JsonAtomic $StateFile ([ordered]@{schema=2;kind='kevin-design-forge-state';version='4.0';updated_at=(Get-Date).ToString('o');status='REJECTED_DEMAND';reason=$msg;demand_driven=$true;round_robin=$false})
        Finish-State 'PASS' ('Design Forge rejected ineligible demand: '+$msg)
        Write-Host ('DESIGN FORGE NO_ELIGIBLE_WORK '+$msg)
        exit 0
    }
    Invoke-ForgeDemand $d
    exit 0
}catch{
    $msg=Safe-OneLine $_.Exception.Message 700
    [IO.File]::WriteAllText($ErrorFile,((Get-Date).ToString('o')+"`n"+$msg+"`n"),$Utf8)
    Write-JsonAtomic $StateFile ([ordered]@{schema=2;kind='kevin-design-forge-state';version='4.0';updated_at=(Get-Date).ToString('o');status='FAIL';reason=$msg;demand_driven=$true;round_robin=$false})
    Finish-State 'FAIL' $msg
    Write-Host ('DESIGN FORGE FAIL '+$msg)
    exit 1
}finally{
    if($owned){try{$mutex.ReleaseMutex()}catch{}}
    $mutex.Dispose()
}
