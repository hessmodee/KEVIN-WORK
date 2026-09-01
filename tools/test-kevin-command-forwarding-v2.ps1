param([string]$RepositoryRoot=(Split-Path -Parent $PSScriptRoot))
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$script:NativeCalls=New-Object Collections.Generic.List[object]

function Assert-True([bool]$Condition,[string]$Message){if(-not$Condition){throw $Message}}
function Import-SourceFunction([string]$Relative,[string]$Name){
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $RepositoryRoot $Relative),[ref]$tokens,[ref]$errors)
    Assert-True ($errors.Count-eq0) ('parse failed: '+$Relative)
    $nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$Name},$true))
    Assert-True ($nodes.Count-eq1) ('function not unique: '+$Name)
    $definition=$nodes[0].Extent.Text-replace('^function\s+'+[regex]::Escape($Name)),('function script:'+$Name)
    .([scriptblock]::Create($definition))
}
function Get-FixedOpenClawRuntime{return [pscustomobject]@{node='fixture-node';cli='fixture-cli.js'}}
function Invoke-FixedNativeBounded([string]$Executable,[string[]]$Argv,[int]$TimeoutSeconds){
    $script:NativeCalls.Add([pscustomobject]@{executable=$Executable;argv=@($Argv);timeout=$TimeoutSeconds})
    return [pscustomobject]@{exit_code=0;output='{}';timed_out=$false}
}
function Assert-Arguments([object[]]$Actual,[object[]]$Expected,[string]$Label){
    Assert-True ($Actual.Count-eq$Expected.Count) ($Label+' argument count mismatch actual='+$Actual.Count+' expected='+$Expected.Count)
    for($i=0;$i-lt$Expected.Count;$i++){Assert-True ([string]$Actual[$i]-ceq[string]$Expected[$i]) ($Label+' argument mismatch at '+$i+' actual=['+[string]$Actual[$i]+'] expected=['+[string]$Expected[$i]+']')}
}

$old='control-plane/maintenance/kevin-maintenance-runner-v1.3.35.ps1'
$new='control-plane/maintenance/kevin-maintenance-runner-v1.3.38.ps1'
$sup='control-plane/autonomy/kevin-supervisor-v1.8.5.ps1'
$cases=@(
    @('gateway','call','status','--json'),
    @('config','validate','--json'),
    @('agent','--agent','main','--json','--message','literal spaces "quotes" $dollar; & operators'),
    @('--help')
)

# Reproduce the historical automatic-$Args defect so this test guards the real regression.
Import-SourceFunction $old 'Invoke-OpenClawFixedConfig'
$script:NativeCalls.Clear();$null=Invoke-OpenClawFixedConfig @('gateway','call','status','--json')
Assert-True ($script:NativeCalls.Count-eq1) 'historical wrapper did not invoke fixture'
Assert-True ($script:NativeCalls[0].argv.Count-eq1) 'historical Args-loss regression was not reproduced'
Write-Host 'REPRODUCED_OLD_BUG requested=4 forwarded_command_args=0'

# New Maintenance wrapper must forward every fixed argument exactly once.
Import-SourceFunction $new 'Invoke-OpenClawFixedConfig'
foreach($case in $cases){
    $script:NativeCalls.Clear();$null=Invoke-OpenClawFixedConfig $case
    Assert-True ($script:NativeCalls.Count-eq1) 'Maintenance wrapper invoked native boundary more than once'
    Assert-Arguments $script:NativeCalls[0].argv (@('fixture-cli.js')+@($case)) 'maintenance wrapper'
}

# Supervisor wrapper must preserve the same contract.
Import-SourceFunction $sup 'Invoke-OpenClaw'
foreach($case in $cases){
    $script:NativeCalls.Clear();$null=Invoke-OpenClaw $case
    Assert-True ($script:NativeCalls.Count-eq1) 'Supervisor wrapper invoked native boundary more than once'
    Assert-Arguments $script:NativeCalls[0].argv (@('fixture-cli.js')+@($case)) 'supervisor wrapper'
}

# Diagnostic must execute exactly four independent read-only probes and never infer
# a downgrade solely from the installed version.
Import-SourceFunction $new 'Diagnose-GatewayFailureDetail'
function Invoke-OpenClawFixedConfig([string[]]$CommandArguments){
    $script:NativeCalls.Add(@($CommandArguments))
    if($script:ProbeFailure-and$CommandArguments[0]-eq'config'){return [pscustomobject]@{exit_code=1;output='invalid config'}}
    return [pscustomobject]@{exit_code=0;output='{}'}
}
function Get-GatewayFailureFamilyDetailed([string]$Text){if($script:ProbeFailure-and$Text.Contains('invalid config')){return 'CONFIG_INVALID'};throw 'all-pass probes must not be classified from arbitrary stdout'}
function Get-DirectGatewayConfigFacts{return [pscustomobject]@{current_sha256='';current_last_touched='';backup_exists=$false;backup_sha256='';backup_last_touched='';backup_semantically_equivalent=$false;telegram_present=$false;discord_present=$false;codex_present=$false;memory_core_present=$false}}
function Get-GatewayTopology{return [pscustomobject]@{keeper_present=$false;keeper_state='';keeper_script_present=$false;keeper_script_sha256='';legacy_present=$false;legacy_state='';port_listening=$false;gateway_listener_count=0}}
function Get-TextSha256([string]$Text){return('A'*64)}
function Publish-SafeFixedReport([string]$RepoPath,[string]$LocalName,[object]$Public,[string]$Message){$script:Published=$Public;return('B'*64)}
function Assert-Benchmark30{}
$GatewayRejectedVersion='2026.7.1-2';$GatewayLkgVersion='2026.6.34'
$previousAppData=$env:APPDATA
try{
    $env:APPDATA=[IO.Path]::GetTempPath()
    $script:ProbeFailure=$false;$script:NativeCalls.Clear();$null=Diagnose-GatewayFailureDetail
    Assert-True ($script:NativeCalls.Count-eq4) 'diagnostic did not execute four probes'
    Assert-Arguments $script:NativeCalls[0] @('config','validate','--json') 'probe1'
    Assert-Arguments $script:NativeCalls[1] @('gateway','status','--require-rpc','--json') 'probe2'
    Assert-Arguments $script:NativeCalls[2] @('gateway','call','status','--json') 'probe3'
    Assert-Arguments $script:NativeCalls[3] @('gateway','health','--json') 'probe4'
    Assert-True ($script:Published.all_probes_ok-eq$true) 'all-pass diagnostic not healthy'
    Assert-True ($script:Published.root_cause_family-eq'HEALTHY') 'all-pass diagnostic family wrong'
    Assert-True ($script:Published.recommended_repair-eq'NONE_ALL_PROBES_PASSED') 'all-pass diagnostic recommended repair'
    $script:ProbeFailure=$true;$script:NativeCalls.Clear();$null=Diagnose-GatewayFailureDetail
    Assert-True ($script:NativeCalls.Count-eq4) 'negative diagnostic skipped probes'
    Assert-True ($script:Published.all_probes_ok-eq$false) 'failed probe reported all-pass'
    Assert-True ($script:Published.root_cause_family-eq'CONFIG_INVALID') 'failed config probe not classified'
    Assert-True ($script:Published.recommended_repair-eq'CLASSIFY_FAILED_PROBE_BEFORE_REPAIR') 'failed probe jumped directly to downgrade'
}finally{if($null-eq$previousAppData){Remove-Item Env:APPDATA -ErrorAction SilentlyContinue}else{$env:APPDATA=$previousAppData}}

# Test actual ProcessStartInfo boundary without a top-level JSON-array pipeline.
$literal=@('with spaces','literal "quotes"','dollar $value','semi;colon','amp&ersand','C:\folder with space\','')
$node=(Get-Command node -ErrorAction Stop).Source
$fixture=Join-Path $RepositoryRoot 'tools/fixtures/echo-argv-envelope.cjs'

Import-SourceFunction $new 'ConvertTo-FixedWin32Arg'
Import-SourceFunction $new 'Invoke-FixedNativeBounded'
$r=Invoke-FixedNativeBounded $node (@($fixture)+$literal) 15
Assert-True ($r.exit_code-eq0) 'Maintenance native argv fixture failed'
$envObj=ConvertFrom-Json -InputObject ([string]$r.output)
Assert-True ([int]$envObj.count-eq$literal.Count) ('Maintenance native argv count mismatch actual='+$envObj.count+' expected='+$literal.Count+' raw='+[string]$r.output)
Assert-Arguments @($envObj.args) $literal 'maintenance native argv'

Import-SourceFunction $sup 'ConvertTo-Win32CommandLineArg'
Import-SourceFunction $sup 'Invoke-FixedNativeBounded'
$r=Invoke-FixedNativeBounded $node (@($fixture)+$literal) 15
Assert-True ($r.exit_code-eq0) 'Supervisor native argv fixture failed'
$envObj=ConvertFrom-Json -InputObject ([string]$r.output)
Assert-True ([int]$envObj.count-eq$literal.Count) ('Supervisor native argv count mismatch actual='+$envObj.count+' expected='+$literal.Count+' raw='+[string]$r.output)
Assert-Arguments @($envObj.args) $literal 'supervisor native argv'

Write-Host 'COMMAND_FORWARDING_V2_PASS maintenance_wrapper=true supervisor_wrapper=true probes=4 native_argv=true trailing_empty=true shell=false'
