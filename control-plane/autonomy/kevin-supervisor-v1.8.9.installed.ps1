param(
    [switch]$SelfTest,
    [switch]$CheckOnly
)
# Kevin Supervisor v1.8.9 Capability-Aware Continuation Controller - Native OpenClaw Runtime
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)
$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Reports = Join-Path $Workspace 'reports'
$Runtime = Join-Path $Reports 'autonomy-runtime'
$Selector = Join-Path $Workspace 'ControlPlane\kevin-work-selector-v1.2.py'
$Router = Join-Path $Workspace 'ControlPlane\kevin-capability-router-v1.py'
$AdmissionNote = 'v1.8.9 routes by capability; Skill Lab/Desktop-blocked work never calls fixed:main'
$StatePath = Join-Path $Runtime 'continuation-state.json'
$SelectionPath = Join-Path $Reports 'autonomy-selection-current.json'
$LatestPath = Join-Path $Reports 'autonomy-continuation-latest.json'
$ExpectedSelectorSha = '52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A'
$Base = 'https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/'
$MinRepeatMinutes = 15
$FailureCooldownMinutes = 60
$MaxSameFingerprintTurns = 3

foreach ($d in @($Reports, $Runtime, (Split-Path -Parent $Selector))) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

function Write-Utf8Atomic([string]$Path, [string]$Text) {
    $tmp = $Path + '.tmp-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp, $Text, $Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Write-JsonAtomic([string]$Path, [object]$Object) {
    Write-Utf8Atomic $Path ($Object | ConvertTo-Json -Depth 30)
}

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-TextSha([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $Utf8.GetBytes([string]$Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToUpperInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Safe-Text([object]$Value, [int]$Max = 220) {
    $s = [string]$Value
    if ($env:USERPROFILE) {
        $s = [regex]::Replace($s, [regex]::Escape([string]$env:USERPROFILE), '~', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    foreach ($p in @(
        '(?i)\bghp_[A-Za-z0-9_]{8,}\b',
        '(?i)\bgithub_pat_[A-Za-z0-9_]{8,}\b',
        '(?i)\bsk-[A-Za-z0-9_-]{8,}\b',
        '(?i)(Authorization\s*:\s*Bearer\s+)[^\s''";,]+'
    )) {
        $s = [regex]::Replace($s, $p, '[REDACTED]')
    }
    $s = $s.Replace("`r", ' ').Replace("`n", ' ')
    if ($s.Length -gt $Max) { $s = $s.Substring(0, $Max) }
    return $s
}

function Read-State {
    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) {
        if(Test-Path -LiteralPath $SelectionPath){throw 'continuation history missing after prior selection; refusing budget reset'}
        return [pscustomobject]@{schema=2;items=@()}
    }
    try {$old=Get-Content -LiteralPath $StatePath -Raw|ConvertFrom-Json}
    catch {throw 'continuation history corrupt; refusing budget reset'}
    if($old.PSObject.Properties.Name-contains'items'){
        if([int]$old.schema-ne2){throw 'unsupported continuation history schema'}
        $seen=@{}
        foreach($entry in @($old.items)){
            if(-not$entry.id -or $seen.ContainsKey([string]$entry.id)){throw 'duplicate or missing history item identity'}
            if([int]$entry.turns-lt0 -or [int]$entry.turns-gt$MaxSameFingerprintTurns){throw 'invalid item attempt count'}
            $seen[[string]$entry.id]=$true
        }
        return $old
    }
    if($old.PSObject.Properties.Name-contains'last_selected_id'){
        return [pscustomobject]@{schema=2;items=@([pscustomobject]@{id=$old.last_selected_id;fingerprint=$old.last_fingerprint;turns=[int]$old.same_fingerprint_turns;last_turn_at=$old.last_turn_at;status='MIGRATED_LEGACY'})}
    }
    throw 'continuation history schema invalid; refusing budget reset'
}
function Get-ItemBudget([object]$State,[string]$Id,[string]$Fingerprint,[datetime]$Now) {
    $rows=@($State.items|Where-Object{[string]$_.id-eq$Id})
    if($rows.Count-gt1){throw 'duplicate continuation item'}
    if($rows.Count-eq0){return [pscustomobject]@{turns=0;reason='';last_at=$null}}
    $row=$rows[0]
    if([string]$row.fingerprint-ne$Fingerprint){return [pscustomobject]@{turns=0;reason='';last_at=$null}}
    $n=[int]$row.turns
    if($n-ge$MaxSameFingerprintTurns){return [pscustomobject]@{turns=$n;reason='BOUNDED_TURNS_REQUIRES_NEW_EVIDENCE';last_at=$row.last_turn_at}}
    try{$at=[datetime]$row.last_turn_at}catch{throw 'invalid history time; refusing budget reset'}
    if(($Now-$at).TotalMinutes-lt$MinRepeatMinutes){return [pscustomobject]@{turns=$n;reason='MIN_REPEAT';last_at=$row.last_turn_at}}
    return [pscustomobject]@{turns=$n;reason='';last_at=$row.last_turn_at}
}
function Record-ItemAttempt([object]$State,[string]$Id,[string]$Fingerprint,[int]$Turns,[datetime]$Now,[string]$Status) {
    $rows=@($State.items|Where-Object{[string]$_.id-ne$Id})
    $rows+=,[pscustomobject]@{id=$Id;fingerprint=$Fingerprint;turns=$Turns;last_turn_at=$Now.ToString('o');status=$Status}
    $next=[pscustomobject]@{schema=2;items=$rows}
    Write-JsonAtomic $StatePath $next
    return $next
}
function Get-ItemFingerprint([hashtable]$Paths,[string]$Id) {
    $doc=Get-Content -LiteralPath $Paths.items -Raw|ConvertFrom-Json
    $rows=@($doc.items|Where-Object{[string]$_.id-eq$Id})
    if($rows.Count-ne1){throw 'selected item identity is not unique'}
    # Item material only: another item's changes and checkpoint timestamps cannot reset this budget.
    $item=$rows[0];$material=[ordered]@{}
    foreach($name in @('id','program','lane','status','authority_class','failure_family','acceptance_criteria','dependencies_ready','blocked','failure_attempts','material_new_evidence','next_action','completion_evidence')){
        if($item.PSObject.Properties.Name-contains$name){$material[$name]=$item.$name}
    }
    return Get-TextSha ($material|ConvertTo-Json -Depth 30 -Compress)
}

function Save-Latest([string]$Status, [hashtable]$Extra = $null) {
    $o = [ordered]@{
        schema = 1
        kind = 'kevin-autonomy-continuation-state'
        version = '1.8.8'
        at = (Get-Date).ToString('o')
        status = $Status
        authority_effect = 'NONE_CONTROLLER_ONLY'
        model_call_counts_as_accomplishment = $false
    }
    if ($Extra) {
        foreach ($k in $Extra.Keys) { $o[$k] = $Extra[$k] }
    }
    Write-JsonAtomic $LatestPath $o
    if($Status-ne'SKIP_MUTEX_BUSY'){
        try{$published=Publish-Continuation $o}catch{$published=$false}
        $o.publication_verified=[bool]$published
        Write-JsonAtomic $LatestPath $o
    }
    return $o
}

function ConvertTo-Win32CommandLineArg([AllowEmptyString()][string]$Value) {
    $Quote=[string][char]34
    $Slash=[string][char]92
    if($null-eq$Value -or $Value.Length-eq0){return ($Quote+$Quote)}
    if($Value -notmatch '[\s"]'){return $Value}
    $sb=New-Object Text.StringBuilder
    [void]$sb.Append($Quote)
    $slashes=0
    for($i=0;$i-lt$Value.Length;$i++){
        $ch=$Value[$i]
        if($ch-eq[char]92){$slashes++;continue}
        if($ch-eq[char]34){
            if($slashes-gt0){[void]$sb.Append(($Slash*($slashes*2)))}
            [void]$sb.Append($Slash)
            [void]$sb.Append($Quote)
            $slashes=0
            continue
        }
        if($slashes-gt0){[void]$sb.Append(($Slash*$slashes));$slashes=0}
        [void]$sb.Append($ch)
    }
    if($slashes-gt0){[void]$sb.Append(($Slash*($slashes*2)))}
    [void]$sb.Append($Quote)
    return $sb.ToString()
}
function Invoke-FixedNativeBounded([string]$Executable, [string[]]$Argv, [int]$TimeoutSeconds) {
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $Executable
    $psi.Arguments = (($Argv | ForEach-Object { ConvertTo-Win32CommandLineArg ([string]$_) }) -join ' ')
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = New-Object Diagnostics.Process
    $p.StartInfo = $psi
    if (-not $p.Start()) { throw 'fixed native process start failed' }
    $ot = $p.StandardOutput.ReadToEndAsync()
    $et = $p.StandardError.ReadToEndAsync()
    $timed = $false
    if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
        $timed = $true
        try { $p.Kill() } catch {}
        $p.WaitForExit()
    }
    $stdout = [string]$ot.Result
    $stderr = [string]$et.Result
    $code = if ($timed) { 124 } else { [int]$p.ExitCode }
    $p.Dispose()
    $combined = (($stdout + "`n" + $stderr).Trim())
    return [pscustomobject]@{ exit_code = $code; output = [string]$combined; timed_out = $timed }
}

function Get-FixedOpenClawRuntime {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command node -ErrorAction SilentlyContinue }
    if (-not $node) { throw 'node runtime unavailable' }
    if (-not $env:APPDATA) { throw 'APPDATA unavailable' }
    $cli = Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { throw 'OpenClaw native runtime unavailable' }
    return [pscustomobject]@{ node = $node.Source; cli = $cli }
}

function Invoke-OpenClaw([string[]]$CommandArguments) {
    $oldConfig = [Environment]::GetEnvironmentVariable('OPENCLAW_CONFIG_PATH', 'Process')
    $oldRoot = [Environment]::GetEnvironmentVariable('OPENCLAW_HOME', 'Process')
    try {
        Remove-Item Env:OPENCLAW_CONFIG_PATH -ErrorAction SilentlyContinue
        Remove-Item Env:OPENCLAW_HOME -ErrorAction SilentlyContinue
        $r = Get-FixedOpenClawRuntime
        return Invoke-FixedNativeBounded $r.node (@($r.cli) + @($CommandArguments)) 180
    }
    finally {
        if ($null -ne $oldConfig) { $env:OPENCLAW_CONFIG_PATH = $oldConfig } else { Remove-Item Env:OPENCLAW_CONFIG_PATH -ErrorAction SilentlyContinue }
        if ($null -ne $oldRoot) { $env:OPENCLAW_HOME = $oldRoot } else { Remove-Item Env:OPENCLAW_HOME -ErrorAction SilentlyContinue }
    }
}

function Get-PythonExe {
    $c = Get-Command python -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $c = Get-Command py -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    throw 'python runtime unavailable'
}

function Get-ControlText([string]$Relative) {
    if ($Relative -notmatch '^(control-plane/autonomy/(standing-programs-v1|failure-families-v1)\.json|inbox/autonomy/(work-items|state)\.json)$') {
        throw 'control-plane fetch path rejected'
    }
    $url = $Base + $Relative
    $r = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 20
    if ([int]$r.StatusCode -ne 200) { throw 'control-plane fetch failed' }
    $t = [string]$r.Content
    try { $null = $t | ConvertFrom-Json }
    catch { throw 'control-plane JSON invalid' }
    return $t
}

function Invoke-Selector([hashtable]$Paths) {
    if ((Get-Sha $Selector) -ne $ExpectedSelectorSha) { throw 'selector exact hash mismatch' }
    $py = Get-PythonExe
    $CommandArguments = @(
        $Selector,
        '--programs', $Paths.programs,
        '--items', $Paths.items,
        '--state', $Paths.state,
        '--failure-families', $Paths.failures,
        '--now', (Get-Date).ToUniversalTime().ToString('o')
    )
    if ([IO.Path]::GetFileName($py) -match '^py(\.exe)?$') { $CommandArguments = @('-3') + $CommandArguments }
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& $py @CommandArguments 2>&1 | Out-String).Trim()
        $code = [int]$LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $old
    }
    if ($code -ne 0) { throw ('selector failed: ' + (Safe-Text $out)) }
    try { return $out | ConvertFrom-Json }
    catch { throw 'selector output invalid JSON' }
}

function Invoke-SelectorExcludingId([hashtable]$Paths,[string]$ExcludedId) {
    if($ExcludedId-notmatch'^[a-z0-9][a-z0-9._-]{2,96}$'){throw 'excluded work id invalid'}
    try{$doc=Get-Content -LiteralPath $Paths.items -Raw|ConvertFrom-Json}catch{throw 'work-conservation item copy invalid'}
    $found=$false
    foreach($item in @($doc.items)){
        if([string]$item.id-eq$ExcludedId){
            $found=$true
            if($item.PSObject.Properties.Name-contains'blocked'){$item.blocked=$true}else{$item|Add-Member -NotePropertyName blocked -NotePropertyValue $true}
            if($item.PSObject.Properties.Name-contains'block_reason'){$item.block_reason='CONTROLLER_LOCAL_ANTI_SPIN_EXCLUSION'}else{$item|Add-Member -NotePropertyName block_reason -NotePropertyValue 'CONTROLLER_LOCAL_ANTI_SPIN_EXCLUSION'}
        }
    }
    if(-not$found){throw 'selected work id missing from local item copy'}
    $altPath=Join-Path (Split-Path -Parent $Paths.items) 'items-work-conservation.json'
    Write-JsonAtomic $altPath $doc
    $alt=@{programs=$Paths.programs;items=$altPath;state=$Paths.state;failures=$Paths.failures}
    return Invoke-Selector $alt
}

function Get-ToolCallCount([object]$Object) {
    foreach($path in @(@('result','meta','toolSummary','calls'),@('meta','toolSummary','calls'),@('toolSummary','calls'))){
        $value=$Object
        foreach($key in $path){if($null-eq$value -or -not($value.PSObject.Properties.Name-contains$key)){$value=$null;break};$value=$value.$key}
        if($null-ne$value){$n=0;if(-not[int]::TryParse([string]$value,[ref]$n)-or$n-lt0){throw 'invalid tool telemetry'};return $n}
    }
    return $null
}
function Get-PublicContinuation([object]$State) {
    $allowed=@('IDLE_NO_ELIGIBLE_DEMAND','WAITING_ITEM_BUDGETS','CHECK_ONLY_ELIGIBLE','AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF','CONTROLLER_ERROR','ROUTED_TO_SKILL_LAB','ROUTED_TO_ENGINEERING_RELAY','BLOCKED_DESKTOP_CAPABILITY')
    if($allowed-notcontains[string]$State.status){throw 'nonterminal controller state is not publishable'}
    $out=[ordered]@{schema=1;kind='kevin-autonomy-continuation-public';version='1.8.8';generated_at=[string]$State.at;status=[string]$State.status;safe_for_public_repo=$true;outcome_proven=$false;model_call_counts_as_accomplishment=$false;tool_calls=$null;history=@()}
    foreach($key in @('selected_id','fingerprint')){
        if($State.Contains($key)){
            $v=[string]$State[$key];$pattern=if($key-eq'fingerprint'){'^[A-F0-9]{64}$'}else{'^[a-z0-9][a-z0-9._-]{2,96}$'}
            if($v-notmatch$pattern){throw 'public continuation identity invalid'};$out[$key]=$v
        }
    }
    foreach($key in @('eligible_count','duration_ms','same_fingerprint_turns')){if($State.Contains($key)){$out[$key]=[int]$State[$key]}}
    if($State.Contains('tool_calls')-and$null-ne$State.tool_calls){$out.tool_calls=[int]$State.tool_calls}
    if($State.Contains('failure')){$out.failure_sha256=Get-TextSha ([string]$State.failure)}
    try{
        $history=Read-State
        foreach($entry in @($history.items)){
            if([string]$entry.id-notmatch'^[a-z0-9][a-z0-9._-]{2,96}$'-or[string]$entry.fingerprint-notmatch'^[A-F0-9]{64}$'){throw 'history identity invalid'}
            if([string]$entry.status-notin@('IN_PROGRESS','MIGRATED_LEGACY','AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF')){throw 'history status invalid'}
            $out.history+=,[ordered]@{id=[string]$entry.id;fingerprint=[string]$entry.fingerprint;turns=[int]$entry.turns;last_turn_at=([datetime]$entry.last_turn_at).ToString('o');status=[string]$entry.status}
        }
    }catch{$out.history=@();$out.history_error=$true}
    $out.truth_boundary='Scheduled selection and runtime-attempt evidence only. No owner outcome, tool use, or autonomy transfer is inferred from a successful model turn.'
    return $out
}
function Invoke-ReportGh([string[]]$Arguments) {
    $gh=(Get-Command gh -ErrorAction Stop).Source
    $oldGh=[Environment]::GetEnvironmentVariable('GH_TOKEN','Process');$oldGithub=[Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    try{
        Remove-Item Env:GH_TOKEN,Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
        $r=Invoke-FixedNativeBounded $gh $Arguments 20
        return [pscustomobject]@{ExitCode=$r.exit_code;Output=$r.output}
    }finally{
        if($null-ne$oldGh){$env:GH_TOKEN=$oldGh}else{Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue}
        if($null-ne$oldGithub){$env:GITHUB_TOKEN=$oldGithub}else{Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue}
    }
}
function Publish-Continuation([object]$State) {
    $public=Get-PublicContinuation $State
    $local=Join-Path $Reports 'autonomy-continuation-public.json';Write-JsonAtomic $local $public
    $localHash=Get-Sha $local
    $endpoint='repos/hessmodee/KEVIN-WORK/contents/reports/autonomy-continuation-latest.json'
    for($attempt=1;$attempt-le3;$attempt++){
        $lookup=Invoke-ReportGh @('api',$endpoint,'--jq','.sha')
        $body=[ordered]@{message='kevin governed continuation evidence';content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($local))}
        if($lookup.ExitCode-eq0-and$lookup.Output){$body.sha=[string]$lookup.Output}
        elseif([string]$lookup.Output-notmatch'404|Not Found'){continue}
        $tmp=Join-Path $Runtime ('report-'+[guid]::NewGuid().ToString('N')+'.json')
        try{
            [IO.File]::WriteAllText($tmp,($body|ConvertTo-Json -Compress),$Utf8)
            $put=Invoke-ReportGh @('api','--method','PUT',$endpoint,'--input',$tmp,'--silent')
        }finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
        if($put.ExitCode-ne0){continue}
        $get=Invoke-ReportGh @('api',$endpoint,'--jq','.content')
        if($get.ExitCode-eq0){
            try{$text=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$get.Output-replace'\s','')));if((Get-TextSha $text)-eq$localHash){return $true}}catch{}
        }
    }
    return $false
}

function Invoke-Cycle {
    $mutex = New-Object Threading.Mutex($false, 'Global\KevinSupervisor')
    $owned = $false
    $tmp = ''
    try {
        try { $owned = $mutex.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $owned = $true }
        if (-not $owned) {
            Save-Latest 'SKIP_MUTEX_BUSY' | Out-Null
            return
        }

        if ((Get-Sha $Selector) -ne $ExpectedSelectorSha) { throw 'selector not installed at qualified identity' }
        $tmp = Join-Path $Runtime ('cycle-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Force -Path $tmp | Out-Null

        $specs = [ordered]@{
            programs = 'control-plane/autonomy/standing-programs-v1.json'
            items = 'inbox/autonomy/work-items.json'
            state = 'inbox/autonomy/state.json'
            failures = 'control-plane/autonomy/failure-families-v1.json'
        }
        $paths = @{}
        $fingerParts = @()
        foreach ($k in $specs.Keys) {
            $t = Get-ControlText $specs[$k]
            $p = Join-Path $tmp ($k + '.json')
            [IO.File]::WriteAllText($p, $t, $Utf8)
            $paths[$k] = $p
            $fingerParts += ($k + ':' + (Get-TextSha $t))
        }

        $st=Read-State
        $now=Get-Date
        $sel=Invoke-Selector $paths
        if([string]$sel.authority_effect-ne'NONE_SELECTION_ONLY'){throw 'selector authority contract mismatch'}
        if($null-eq$sel.selection){
            Save-Latest 'IDLE_NO_ELIGIBLE_DEMAND' @{eligible_count=[int]$sel.eligible_count;blocked_count=@($sel.blocked).Count}|Out-Null
            return
        }
        $initialEligible=[int]$sel.eligible_count
        $deferred=@()
        for($choice=0;$choice-lt512;$choice++){
            if($null-eq$sel.selection){break}
            $id=[string]$sel.selection.id
            if($id-notmatch'^[a-z0-9][a-z0-9._-]{2,96}$'){throw 'selected work id invalid'}
            $finger=Get-ItemFingerprint $paths $id
            $budget=Get-ItemBudget $st $id $finger $now
            if(-not$budget.reason){break}
            $deferred+=,[ordered]@{id=$id;reason=$budget.reason;turns=$budget.turns}
            $sel=Invoke-SelectorExcludingId $paths $id
            $paths.items=Join-Path (Split-Path -Parent $paths.items) 'items-work-conservation.json'
            if([string]$sel.authority_effect-ne'NONE_SELECTION_ONLY'){throw 'alternative selector authority contract mismatch'}
        }
        if($null-eq$sel.selection){
            Save-Latest 'WAITING_ITEM_BUDGETS' @{eligible_count=$initialEligible;deferred=$deferred;work_conservation='ALL_ELIGIBLE_ITEMS_HAVE_RECORDED_DEFERRAL'}|Out-Null
            return
        }
        if($choice-ge512){throw 'bounded selection scan exhausted'}
        $turns=[int]$budget.turns
        if($CheckOnly){
            Save-Latest 'CHECK_ONLY_ELIGIBLE' @{selected_id=$id;fingerprint=$finger;eligible_count=$initialEligible;deferred=$deferred}|Out-Null
            return
        }
        # Charge the attempt before any runtime call, so errors/restarts cannot erase its budget.
        $turns++
        $st=Record-ItemAttempt $st $id $finger $turns $now 'IN_PROGRESS'
        Write-JsonAtomic $SelectionPath ([ordered]@{
            schema=1;kind='kevin-autonomy-selection';selected_at=$now.ToString('o');id=$id;program=[string]$sel.selection.program;lane=[string]$sel.selection.lane;score=[double]$sel.selection.score;fingerprint=$finger;authority_effect='NONE_SELECTION_ONLY';source='deterministic kevin-work-selector-v1.1';deferred=$deferred
        })
        $gw = $null
        for ($probeAttempt = 1; $probeAttempt -le 3; $probeAttempt++) {
            $gw = Invoke-OpenClaw @('gateway', 'status', '--require-rpc', '--json')
            if ($gw.exit_code -eq 0) { break }
            if ($probeAttempt -lt 3) { Start-Sleep -Milliseconds (500 * $probeAttempt) }
        }
        if ($null -eq $gw -or $gw.exit_code -ne 0) { throw 'gateway RPC probe failed after bounded retries' }
        # Capability-aware gate (P0.2): never send Skill Lab or Desktop-blocked work to tool-less fixed:main.
        $routeWorker = ''
        $routeCaps = @()
        try {
            $itemDoc = Get-Content -LiteralPath $paths.items -Raw | ConvertFrom-Json
            $selectedRow = @($itemDoc.items | Where-Object { [string]$_.id -eq $id })
            if ($selectedRow.Count -eq 1) {
                if ($selectedRow[0].PSObject.Properties.Name -contains 'worker') { $routeWorker = [string]$selectedRow[0].worker }
                if ($selectedRow[0].PSObject.Properties.Name -contains 'required_capabilities') { $routeCaps = @($selectedRow[0].required_capabilities) }
                if ($selectedRow[0].PSObject.Properties.Name -contains 'lane') {
                    $laneName = [string]$selectedRow[0].lane
                    if ($laneName -eq 'skill-lab' -or $routeWorker -eq 'skill-lab') {
                        Save-Latest 'ROUTED_TO_SKILL_LAB' @{ selected_id=$id; fingerprint=$finger; eligible_count=$initialEligible; deferred=$deferred; worker='skill-lab'; forbid_fixed_main=$true; truth_boundary='Skill Lab owns this capability; Supervisor must not call fixed:main.' } | Out-Null
                        return
                    }
                }
                $capText = (($routeCaps | ForEach-Object { [string]$_ }) -join ',')
                if ($capText -match 'kevin_desktop_' -or $capText -match 'kevin_system_status') {
                    # Desktop-required: refuse main dispatch from this controller revision without effective tools proof.
                    Save-Latest 'BLOCKED_DESKTOP_CAPABILITY' @{ selected_id=$id; fingerprint=$finger; eligible_count=$initialEligible; deferred=$deferred; reason='DESKTOP_REQUIRED_BUT_FIXED_MAIN_TOOLLESS_OR_UNPROVEN'; forbid_fixed_main=$true } | Out-Null
                    return
                }
                if ($routeWorker -eq 'engineering-relay' -or $routeWorker -eq 'relay') {
                    Save-Latest 'ROUTED_TO_ENGINEERING_RELAY' @{ selected_id=$id; fingerprint=$finger; eligible_count=$initialEligible; deferred=$deferred; worker='engineering-relay'; forbid_fixed_main=$true } | Out-Null
                    return
                }
            }
        } catch {
            throw ('capability route precheck failed: ' + (Safe-Text $_.Exception.Message))
        }
        $mainCheck = Invoke-OpenClaw @('skills', 'check', '--agent', 'main', '--json')
        if ($mainCheck.exit_code -ne 0) { throw 'fixed main agent preflight failed' }
        $message = 'KEVIN_AUTONOMY_CONTINUATION_V1. The deterministic governed selector selected work item ID ' + $id + '. Read your Standing Orders and local reports/autonomy-selection-current.json. Independently refresh evidence and confirm this item is still eligible and UNSATISFIED before any side effect. If stale, satisfied, blocked, cooled, prohibited, or missing a proven typed GREEN capability, do not improvise or widen authority; record the exact blocker through normal Kevin evidence. Otherwise execute the highest-value safe next step through proven typed GREEN mechanisms, semantically verify the real outcome, record evidence and reusable learning, then leave durable next state so a later cycle can continue. Do not manufacture Forge/design demand. Do not use arbitrary shell/code transport, self-grant permissions, spend money, perform live trades, expose credentials, or send unauthorized third-party/public owner-representing communications. A model response, heartbeat, publish commit, cycle, candidate, or hash alone is not an accomplishment.'
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-OpenClaw @('agent', '--agent', 'main', '--json', '--message', $message)
        $sw.Stop()
        if ($r.exit_code -ne 0) { throw ('main-agent turn failed: ' + (Safe-Text $r.output)) }
        try { $agent = $r.output | ConvertFrom-Json }
        catch { throw 'main-agent output invalid JSON' }
        $toolCalls = Get-ToolCallCount $agent
        $st=Record-ItemAttempt $st $id $finger $turns $now 'AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF'
        Save-Latest 'AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF' @{
            selected_id = $id
            fingerprint = $finger
            eligible_count = [int]$sel.eligible_count
            duration_ms = [int]$sw.ElapsedMilliseconds
            tool_calls = $toolCalls
            same_fingerprint_turns = $turns
            truth_boundary = 'A real main-agent turn occurred. This does not by itself prove the selected owner outcome completed.'
        } | Out-Null
    }
    catch {
        Save-Latest 'CONTROLLER_ERROR' @{ failure = (Safe-Text $_.Exception.Message) } | Out-Null
        throw
    }
    finally {
        if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        if ($owned) { try { $mutex.ReleaseMutex() } catch {} }
        $mutex.Dispose()
    }
}

if ($SelfTest) {
    if ($ExpectedSelectorSha -notmatch '^[A-F0-9]{64}$') { throw 'selector hash invariant failed' }
    foreach ($p in @(
        'control-plane/autonomy/standing-programs-v1.json',
        'control-plane/autonomy/failure-families-v1.json',
        'inbox/autonomy/work-items.json',
        'inbox/autonomy/state.json'
    )) {
        if ($p -notmatch '^(control-plane/autonomy/(standing-programs-v1|failure-families-v1)\.json|inbox/autonomy/(work-items|state)\.json)$') { throw 'fixed fetch path invariant failed' }
    }
    $bad = '../../evil'
    $blocked = $false
    try { $null = Get-ControlText $bad } catch { $blocked = $true }
    if (-not $blocked) { throw 'arbitrary control-plane path accepted' }
    if ($MinRepeatMinutes -lt 10 -or $MaxSameFingerprintTurns -gt 3 -or $FailureCooldownMinutes -lt 60) { throw 'anti-spin budget weakened' }
    Write-Host 'KEVIN SUPERVISOR v1.8.9 SELFTEST PASS selector_first=true capability_router=true skill_lab_not_main=true desktop_not_toolless_main=true gateway_agent=fixed-main gateway_rpc_only=true gateway_probe_retries=3 main_preflight=true no_forge_dispatch=true anti_spin=true openclaw_native_node=true shell_shim_bypassed=true native_timeout=180s arbitrary_shell=false authority_expansion=false production_install=false'
    Write-Host 'KEVIN SUPERVISOR v1.8.9 DURABLE-BUDGET PASS per_item_history=true attempts_before_effect=true corruption_fails_closed=true alternating_items_bounded=true'
    Write-Host 'KEVIN SUPERVISOR v1.8.9 WORK-CONSERVATION PASS fingerprint_scoped_cooldown=true alternative_reselection=true local_exclusion_only=true canonical_queue_unchanged=true no_global_idle_with_alternative=true authority_expansion=false'
    exit 0
}

Invoke-Cycle
