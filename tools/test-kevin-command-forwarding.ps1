param([string]$RepositoryRoot=(Split-Path -Parent $PSScriptRoot))
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$script:NativeCalls=New-Object Collections.Generic.List[object]

function Assert-True([bool]$Condition,[string]$Message){if(-not$Condition){throw $Message}}
function Import-SourceFunction([string]$Relative,[string]$Name){
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $RepositoryRoot $Relative),[ref]$tokens,[ref]$errors)
    Assert-True ($errors.Count-eq0) ('parse failed: '+$Relative)
    $nodes=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name-eq$Name},$true))
    Assert-True ($nodes.Count-eq1) ('function not unique: '+$Name)
    # Function parameters are outside Body for the compact declaration syntax.
    $definition=$nodes[0].Extent.Text -replace ('^function\s+'+[regex]::Escape($Name)),('function script:'+$Name)
    . ([scriptblock]::Create($definition))
}
function Get-FixedOpenClawRuntime{return [pscustomobject]@{node='fixture-node';cli='fixture-cli.js'}}
function Invoke-FixedNativeBounded([string]$Executable,[string[]]$Argv,[int]$TimeoutSeconds){
    $script:NativeCalls.Add([pscustomobject]@{executable=$Executable;argv=@($Argv);timeout=$TimeoutSeconds})
    return [pscustomobject]@{exit_code=0;output='{}';timed_out=$false}
}
function Assert-Arguments([object[]]$Actual,[object[]]$Expected,[string]$Label){
    Assert-True ($Actual.Count-eq$Expected.Count) ($Label+' argument count mismatch')
    for($i=0;$i-lt$Expected.Count;$i++){Assert-True ([string]$Actual[$i]-ceq[string]$Expected[$i]) ($Label+' argument mismatch at '+$i)}
}

$old='control-plane/maintenance/kevin-maintenance-runner-v1.3.35.ps1'
$new='control-plane/maintenance/kevin-maintenance-runner-v1.3.37.ps1'
Import-SourceFunction $old 'Invoke-OpenClawFixedConfig'
$null=Invoke-OpenClawFixedConfig @('gateway','call','status','--json')
Assert-True ($script:NativeCalls[0].argv.Count-eq1) 'historical Args-loss regression was not reproduced'
Write-Host 'REPRODUCED_OLD_BUG requested=4 forwarded=0'

Import-SourceFunction $new 'Invoke-OpenClawFixedConfig'
$cases=@(
    @('gateway','call','status','--json'),
    @('config','validate','--json'),
    @('agent','--agent','main','--json','--message','literal spaces "quotes" $dollar; & operators'),
    @('--help')
)
foreach($case in $cases){
    $script:NativeCalls.Clear();$null=Invoke-OpenClawFixedConfig $case
    Assert-True ($script:NativeCalls.Count-eq1) 'fixed wrapper invoked more than once'
    Assert-Arguments $script:NativeCalls[0].argv (@('fixture-cli.js')+@($case)) 'maintenance'
}

Import-SourceFunction 'control-plane/autonomy/kevin-supervisor-v1.8.5.ps1' 'Invoke-OpenClaw'
foreach($case in $cases){
    $script:NativeCalls.Clear();$null=Invoke-OpenClaw $case
    Assert-Arguments $script:NativeCalls[0].argv (@('fixture-cli.js')+@($case)) 'supervisor'
}

# Execute the real diagnostic function using inert collectors/publisher.
Import-SourceFunction $new 'Diagnose-GatewayFailureDetail'
function Invoke-OpenClawFixedConfig([string[]]$CommandArguments){
    $script:NativeCalls.Add(@($CommandArguments))
    return [pscustomobject]@{exit_code=0;output='{}'}
}
function Get-GatewayFailureFamilyDetailed([string]$Text){throw 'successful probes must not be classified from arbitrary stdout'}
function Get-DirectGatewayConfigFacts{return [pscustomobject]@{current_sha256='';current_last_touched='';backup_exists=$false;backup_sha256='';backup_last_touched='';backup_semantically_equivalent=$false;telegram_present=$false;discord_present=$false;codex_present=$false;memory_core_present=$false}}
function Get-GatewayTopology{return [pscustomobject]@{keeper_present=$false;keeper_state='';keeper_script_present=$false;keeper_script_sha256='';legacy_present=$false;legacy_state='';port_listening=$false;gateway_listener_count=0}}
function Get-TextSha256([string]$Text){return ('A'*64)}
function Publish-SafeFixedReport([string]$RepoPath,[string]$LocalName,[object]$Public,[string]$Message){$script:Published=$Public;return ('B'*64)}
function Assert-Benchmark30{}
$GatewayRejectedVersion='2026.7.1-2';$GatewayLkgVersion='2026.6.34'
$previousAppData=$env:APPDATA
try{
    $env:APPDATA=[IO.Path]::GetTempPath()
    $script:NativeCalls.Clear();$null=Diagnose-GatewayFailureDetail
    Assert-True ($script:NativeCalls.Count-eq4) 'diagnostic must call exactly four independent probes'
    Assert-Arguments $script:NativeCalls[0] @('config','validate','--json') 'probe 1'
    Assert-Arguments $script:NativeCalls[1] @('gateway','status','--require-rpc','--json') 'probe 2'
    Assert-Arguments $script:NativeCalls[2] @('gateway','call','status','--json') 'probe 3'
    Assert-Arguments $script:NativeCalls[3] @('gateway','health','--json') 'probe 4'
    Assert-True ($script:Published.root_cause_family-eq'HEALTHY') 'all-pass diagnostic reported a failure'
    Assert-True ($script:Published.recommended_repair-eq'NONE_ALL_PROBES_PASSED') 'all-pass diagnostic recommended a version change'
}finally{if($null-eq$previousAppData){Remove-Item Env:APPDATA -ErrorAction SilentlyContinue}else{$env:APPDATA=$previousAppData}}

# Test the actual native process boundary and quoting, with an argv-only child.
Import-SourceFunction $new 'ConvertTo-FixedWin32Arg'
Import-SourceFunction $new 'Invoke-FixedNativeBounded'
$node=(Get-Command node -ErrorAction Stop).Source
$fixture=Join-Path $RepositoryRoot 'tools/fixtures/echo-argv.cjs'
$literal=@('with spaces','literal "quotes"','dollar $value','semi;colon','amp&ersand','C:\folder with space\','')
$native=Invoke-FixedNativeBounded $node (@($fixture)+$literal) 15
Assert-True ($native.exit_code-eq0) 'native argv fixture failed'
$received=@($native.output|ConvertFrom-Json)
Assert-Arguments $received $literal 'native process'
Write-Host 'COMMAND_FORWARDING_PASS maintenance=true supervisor=true probes=4 native_argv=true shell=false'
