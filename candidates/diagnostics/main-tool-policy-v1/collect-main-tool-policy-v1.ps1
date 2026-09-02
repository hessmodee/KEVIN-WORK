param([switch]$SelfTest)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$ExpectedOpenClawVersion='2026.7.1-2'
$Protected=@('exec','process','write','edit','apply_patch','browser','sessions_spawn','sessions_send','conversations_send','cron')
$KnownControl=@('get_goal','create_goal','update_goal','update_plan','progress_card','session_status','sessions_list','sessions_history','read')

function H([string]$Text){$s=[Security.Cryptography.SHA256]::Create();try{return([BitConverter]::ToString($s.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-','')}finally{$s.Dispose()}}
function J([object]$O,[string]$N){if($null-eq$O){return$null};$p=$O.PSObject.Properties[$N];if($p){return$p.Value};return$null}
function Arr([object]$V){if($null-eq$V){return@()};if($V-is[string]){throw'tool policy list must be array'};$a=@($V);foreach($x in$a){if($x-isnot[string]){throw'tool policy list item must be string'}};return@($a|Sort-Object -Unique)}
function Summary([object]$P){
  if($null-eq$P){$P=[pscustomobject]@{}}
  $profile=[string](J $P 'profile');if(-not$profile){$profile='UNSET'}elseif($profile-notin@('minimal','coding','messaging','full')){$profile='OTHER'}
  $allow=Arr(J $P 'allow');$also=Arr(J $P 'alsoAllow');$deny=Arr(J $P 'deny');if($allow.Count-and$also.Count){throw'allow and alsoAllow cannot coexist'}
  $effectiveAllow=@($allow)+@($also)
  [ordered]@{present=($P.PSObject.Properties.Count-gt0);profile=$profile;allow_count=$allow.Count;also_allow_count=$also.Count;deny_count=$deny.Count;allow_sha256=H(($allow|ConvertTo-Json -Compress));also_allow_sha256=H(($also|ConvertTo-Json -Compress));deny_sha256=H(($deny|ConvertTo-Json -Compress));known_control_allowed=@($KnownControl|Where-Object{$effectiveAllow-contains$_});protected_explicitly_allowed=@($Protected|Where-Object{$effectiveAllow-contains$_});protected_explicitly_denied=@($Protected|Where-Object{$deny-contains$_})}
}
function FixedRuntime {
  if(-not$env:APPDATA){throw'APPDATA unavailable'}
  $pkg=Join-Path $env:APPDATA 'npm\node_modules\openclaw\package.json';$cli=Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
  if(-not(Test-Path $pkg -PathType Leaf)-or-not(Test-Path $cli -PathType Leaf)){throw'fixed OpenClaw runtime missing'}
  $version=[string](Get-Content $pkg -Raw|ConvertFrom-Json).version;if($version-ne$ExpectedOpenClawVersion){throw('unexpected OpenClaw version '+$version)}
  $node=Get-Command node.exe -ErrorAction SilentlyContinue;if(-not$node){$node=Get-Command node -ErrorAction Stop}
  [pscustomobject]@{node=$node.Source;cli=$cli;version=$version}
}
function Quote([string]$V){if($null-eq$V-or$V.Length-eq0){return'""'};if($V-notmatch'[\s"]'){return$V};return'"'+($V.Replace('\','\\').Replace('"','\"'))+'"'}
function Run([object]$R,[string[]]$A,[int]$Seconds=60){
  $psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName=$R.node;$psi.Arguments=((@($R.cli)+$A|ForEach-Object{Quote([string]$_)})-join' ');$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  $p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(-not$p.Start()){throw'fixed OpenClaw process start failed'};$ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync();if(-not$p.WaitForExit($Seconds*1000)){try{$p.Kill()}catch{};$p.WaitForExit();throw'fixed OpenClaw read-only probe timeout'};$o=[string]$ot.Result;$e=[string]$et.Result;$c=[int]$p.ExitCode;$p.Dispose();[pscustomobject]@{code=$c;out=$o;err=$e}
}
function MainEntry([object]$Cfg){$agents=J $Cfg 'agents';$list=J $agents 'list';if($null-eq$list){return$null};$rows=@($list|Where-Object{[string](J $_ 'id')-eq'main'});if($rows.Count-gt1){throw'multiple main entries'};if($rows.Count-eq1){return$rows[0]};return$null}
function ProviderPolicy([object]$Container,[string]$Provider,[string]$Model){if($null-eq$Container){return$null};$by=J $Container 'byProvider';if($null-eq$by){return$null};$p=$by.PSObject.Properties[$Provider];if($p){return$p.Value};$m=$by.PSObject.Properties[$Model];if($m){return$m.Value};return$null}

if($SelfTest){
  $p=[pscustomobject]@{allow=@('get_goal','exec');deny=@('write')};$s=Summary $p;if($s.allow_count-ne2-or$s.protected_explicitly_allowed-ne'exec'-or$s.protected_explicitly_denied-ne'write'){throw'summary selftest failed'}
  $bad=[pscustomobject]@{allow=@('get_goal');alsoAllow=@('read')};$blocked=$false;try{Summary $bad|Out-Null}catch{$blocked=$true};if(-not$blocked){throw'allow/alsoAllow negative failed'}
  Write-Host 'KEVIN MAIN TOOL POLICY DIAGNOSTIC v1 SELFTEST PASS read_only=true fixed_main=true raw_config_output=false arbitrary_command=false'
  exit 0
}

$cfgPath=Join-Path $env:USERPROFILE '.openclaw\openclaw.json';if(-not(Test-Path $cfgPath -PathType Leaf)){throw'fixed OpenClaw config missing'}
$cfg=Get-Content $cfgPath -Raw|ConvertFrom-Json;$main=MainEntry $cfg;$agents=J $cfg 'agents';$defaults=J $agents 'defaults';$model=J $main 'model';if($null-eq$model){$model=J $defaults 'model'};if($model-isnot[string]){$model=J $model 'primary'};$model=[string]$model;if(-not$model){$model='UNKNOWN'};$parts=$model-split'/',2;$provider=if($parts.Count-eq2){$parts[0]}else{'UNKNOWN'}
$root=J $cfg 'tools';$mainTools=J $main 'tools';$rootProvider=ProviderPolicy $root $provider $model;$mainProvider=ProviderPolicy $mainTools $provider $model
$runtime=FixedRuntime;$validate=Run $runtime @('config','validate','--json');if($validate.code-ne0){throw'OpenClaw config validation failed'}
$explain=Run $runtime @('sandbox','explain','--agent','main','--json');$explainOk=($explain.code-eq0);$explainObj=$null;if($explainOk){try{$explainObj=$explain.out|ConvertFrom-Json}catch{$explainOk=$false}}
$sandbox=J $main 'sandbox';$sandboxMode=[string](J $sandbox 'mode');if(-not$sandboxMode){$sandboxMode='UNSET'};$workspaceAccess=[string](J $sandbox 'workspaceAccess');if(-not$workspaceAccess){$workspaceAccess='UNSET'}
$out=[ordered]@{schema=1;kind='kevin-main-tool-policy-diagnostic';state='READ_ONLY_DIAGNOSIS';safe_for_public_repo=$true;openclaw_version=$runtime.version;config_sha256=(Get-FileHash $cfgPath -Algorithm SHA256).Hash.ToUpperInvariant();main_entry_present=($null-ne$main);model_family=if($model-match'(?i)qwen2\.5'){'QWEN2_5'}else{'OTHER'};model_id_sha256=H $model;provider_id_sha256=H $provider;root=(Summary $root);main=(Summary $mainTools);root_provider=(Summary $rootProvider);main_provider=(Summary $mainProvider);sandbox=[ordered]@{mode=$sandboxMode;workspace_access=$workspaceAccess;explain_ok=$explainOk;explain_sha256=H($(if($explainOk){$explain.out}else{''}))};risk=[ordered]@{broad_profile=([string](J $root 'profile')-in@('coding','full')-or[string](J $mainTools 'profile')-in@('coding','full'));protected_explicit_allow=((Summary $root).protected_explicitly_allowed.Count-gt0-or(Summary $mainTools).protected_explicitly_allowed.Count-gt0)};truth_boundary='Fixed main/config + fixed sandbox explain only. No raw config, list contents outside small policy-owned known sets, paths, credentials, prompts, messages, or arbitrary command output are emitted.'}
$out|ConvertTo-Json -Depth 20
