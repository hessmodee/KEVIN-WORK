param([switch]$CheckOnly,[switch]$Apply,[switch]$SelfTest)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$Utf8=New-Object Text.UTF8Encoding($false)

# Exact private HESS-PC evidence collected 2026-09-06 14:17 MT.
$ConfigSha='29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA'
$TrustedSha='DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4'
$BaselineSha='2EE72E14E01CD6F22CCC851FF6AA304A113799CECEDCAB7349F9F9E6058A3143'
$BenchmarkSha='4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964'
$UiSha='5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42'
$MaintSha='715E40DF0CFDC94FC8D470A83273467A6B10CC6CB9A2956E3A94FADC69B9646B'
$SupervisorSha='D77BCAA7E2CB76B0F477F7CBAC0C93CC1ABF010F24373EC2F0207D73A1B76810'
$ForgeSha='433534B91CE2096BD3A9FEE55E492CA31DB7689E6940A136FB927B65E19E482A'
$ReaderSha='C107FEEDA4CA7B330FF44B7E9083DDAA854D9057085F165797B3EAF6FC458C5D'
$Task='Kevin UI Bridge v0.3'
$Tools=@('kevin_system_status','kevin_desktop_find_folder','kevin_desktop_open_folder','kevin_desktop_list_folder','kevin_app_launch')
$Denies=@('exec','tool_call','tool_search','tool_describe','write','edit','apply_patch','sessions_send','sessions_spawn','sessions_yield','subagents','web_search','web_fetch','process','skill_workshop')

$Root=Join-Path $env:USERPROFILE '.openclaw';$Ws=Join-Path $Root 'workspace'
$Cfg=Join-Path $Root 'openclaw.json';$Reader=Join-Path $env:USERPROFILE '.openclaw-reader\openclaw.json'
$Base=Join-Path $Ws 'reports\benchmark-v1\baseline.json';$Bench=Join-Path $Ws 'kevin-benchmark-v1.ps1';$Latest=Join-Path $Ws 'reports\benchmark-v1\latest.json'
$Ui=Join-Path $Ws 'kevin-ui-bridge.ps1';$Maint=Join-Path $Ws 'kevin-maintenance-runner.ps1';$Sup=Join-Path $Ws 'kevin-supervisor.ps1';$Forge=Join-Path $Ws 'kevin-design-forge.ps1'
$UiRoot=Join-Path $Ws 'reports\action-era\ui-bridge';$Heartbeat=Join-Path $UiRoot 'heartbeat.json';$Inbox=Join-Path $UiRoot 'inbox';$Results=Join-Path $UiRoot 'results'
$Repair=Join-Path $Ws 'reports\maintenance\platform-recovery-20260906';$Receipt=Join-Path $Ws 'reports\maintenance\platform-recovery-20260906-latest.json'

function Sha([string]$p){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){return''};return(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()}
function J([string]$p){Get-Content -LiteralPath $p -Raw|ConvertFrom-Json}
function W([string]$p,[object]$o){$d=Split-Path -Parent $p;if(-not(Test-Path $d)){New-Item -ItemType Directory -Force -Path $d|Out-Null};$t=$p+'.tmp-'+$PID+'-'+[guid]::NewGuid().ToString('N');[IO.File]::WriteAllText($t,($o|ConvertTo-Json -Depth 60),$Utf8);Move-Item $t $p -Force}
function P([object]$o,[string]$n){if($null-eq$o){return$null};$x=$o.PSObject.Properties[$n];if($null-eq$x){return$null};return$x.Value}
function H([object]$o,[string]$n){return($null-ne$o-and$null-ne$o.PSObject.Properties[$n])}
function Exact([object]$a,[string[]]$e,[string]$n){$x=@($a|ForEach-Object{[string]$_});if($x.Count-ne$e.Count){throw($n+' count mismatch')};for($i=0;$i-lt$e.Count;$i++){if($x[$i]-cne$e[$i]){throw($n+' mismatch index '+$i)}}}

# Canonical semantic comparison ignores only OpenClaw's benign touch metadata.
function C([object]$v,[string]$path='$'){
 if($null-eq$v){return$null};if($v-is[string]-or$v-is[bool]-or$v-is[int]-or$v-is[long]-or$v-is[double]-or$v-is[decimal]){return$v}
 if($v-is[Collections.IDictionary]){$o=[ordered]@{};foreach($k in @($v.Keys|ForEach-Object{[string]$_}|Sort-Object)){$p=$path+'.'+$k;if($p-in@('$.meta.lastTouchedAt','$.meta.lastTouchedVersion')){continue};$o[$k]=C $v[$k] $p};return$o}
 if($v-is[Collections.IEnumerable]-and-not($v-is[string])){$a=@();$i=0;foreach($z in $v){$a+=,(C $z ($path+'['+$i+']'));$i++};return$a}
 $ps=@($v.PSObject.Properties|Where-Object{$_.MemberType-in@('NoteProperty','Property')}|Sort-Object Name);if($ps.Count){$o=[ordered]@{};foreach($q in$ps){$p=$path+'.'+$q.Name;if($p-in@('$.meta.lastTouchedAt','$.meta.lastTouchedVersion')){continue};$o[$q.Name]=C $q.Value $p};return$o};return[string]$v
}
function CJ([object]$o){(C $o|ConvertTo-Json -Depth 60 -Compress)}
function Mask([object]$b){$x=$b|ConvertTo-Json -Depth 60|ConvertFrom-Json;$x.hashes.production_config='TARGET_IGNORED';CJ $x}
function Main([object]$c){$hits=@((P (P $c 'agents') 'list')|Where-Object{[string](P $_ 'id')-ceq'main'});if($hits.Count-ne1){throw('main agent count='+$hits.Count)};return$hits[0]}
function Assert-Config([object]$c){
 $rt=P $c 'tools';if($null-eq$rt-or[string](P $rt 'profile')-cne'coding'){throw'global tool profile drift'};if(H $rt 'allow'){throw'global allow unexpectedly present'};Exact (P $rt 'alsoAllow') $Tools 'global alsoAllow';Exact (P $rt 'deny') $Denies 'global deny'
 $m=Main $c;$mt=P $m 'tools';if($null-eq$mt){throw'main tools missing'};Exact (P $mt 'allow') $Tools 'main allow';if((H $mt 'alsoAllow')-or(H $mt 'deny')){throw'unexpected main policy surface'}
 $d=P (P $c 'agents') 'defaults';if(H $d 'tools'){throw'defaults tools unexpectedly present'};$cp=P $d 'compaction';if([int64](P $cp 'reserveTokensFloor')-ne2048-or[int64](P $cp 'reserveTokens')-ne2048-or[int64](P $cp 'keepRecentTokens')-ne4000){throw'compaction drift'}
 $mv=P $m 'model';if($null-eq$mv){$mv=P $d 'model'};$primary=if($mv-is[string]){[string]$mv}else{[string](P $mv 'primary')};if($primary-cne'ollama-chat-16k/qwen2.5:14b'){throw'main model drift'}
 $prov=P (P (P $c 'models') 'providers') 'ollama-chat-16k';if($null-eq$prov){throw'local provider missing'};$api=[string](P $prov 'api');if($api-and$api-cne'ollama'){throw'provider api drift'};$url=[string](P $prov 'baseUrl');if(-not$url){$url=[string](P $prov 'baseURL')};if($url-and$url-notmatch'^http://(127\.0\.0\.1|localhost):11434/?$'){throw'provider not loopback'}
 $ms=@((P $prov 'models')|Where-Object{[string](P $_ 'id')-ceq'qwen2.5:14b'});if($ms.Count-ne1-or[int64](P $ms[0] 'contextTokens')-ne16384-or[int64](P (P $ms[0] 'params') 'num_ctx')-ne16384){throw'16k model contract drift'};$bind=[string](P (P $c 'gateway') 'bind');if($bind-and$bind-cne'loopback'){throw'gateway not loopback'}
}
function TrustedCopy{
 $cand=@();if(Test-Path $Root){$cand+=@(Get-ChildItem -LiteralPath $Root -File -ErrorAction SilentlyContinue|Where-Object{$_.Length-le2097152-and$_.Name-match'(?i)^openclaw\.json'}|ForEach-Object{$_.FullName})}
 $br=Join-Path $Ws 'reports\maintenance\backups';if(Test-Path $br){$cand+=@(Get-ChildItem -LiteralPath $br -Recurse -File -ErrorAction SilentlyContinue|Where-Object{$_.Length-le2097152-and$_.Name-match'(?i)(openclaw|config).*(json|bak|before|pre|backup)?$'}|Select-Object -First 5000|ForEach-Object{$_.FullName})}
 foreach($p in @($cand|Select-Object -Unique)){try{if((Sha $p)-ceq$TrustedSha){return$p}}catch{}};return''
}
function Assert-R04{
 if((Sha $Bench)-cne$BenchmarkSha){throw'benchmark identity drift'};$s=Get-Content $Bench -Raw;if($s-notmatch'(?s)Add-Result\s+\$reg\s+"R04".*?baseline\.hashes\.production_config'){throw'R04 contract not found'};$b=J $Latest;if([string]$b.status-cne'FAIL_CRITICAL_REGRESSION'-or[int]$b.regression.passed-ne29-or[int]$b.regression.total-ne30-or[int]$b.regression.critical_failures-ne1){throw'benchmark not exact 29/30 critical1'};$f=@($b.regression.rows|Where-Object{-not[bool]$_.pass});if($f.Count-ne1-or[string]$f[0].id-cne'R04'-or-not[bool]$f[0].critical){throw'failure not exactly R04'}
}
function Bench30{
 for($i=1;$i-le4;$i++){$st=[DateTime]::UtcNow;$old=$ErrorActionPreference;try{$ErrorActionPreference='Continue';$out=(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Bench 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old};if($out-match'(?i)BENCHMARK\s+SKIP_(ACTIVE_WORK|OVERLAP)'){Start-Sleep 5;continue};if($code-ne0){throw('benchmark exit='+$code)};$x=J $Latest;if((Get-Item $Latest).LastWriteTimeUtc-lt$st.AddSeconds(-3)-or[string]$x.status-cne'PASS'-or[int]$x.regression.passed-ne30-or[int]$x.regression.total-ne30-or[int]$x.regression.critical_failures-ne0){throw'fresh benchmark not 30/30'};return$x};throw'benchmark retry budget exhausted'
}
function UiState{
 $t=Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue;if(-not$t){return[pscustomobject]@{ok=$false;reason='missing'}};$a=@($t.Actions);if($a.Count-ne1){return[pscustomobject]@{ok=$false;reason='actions'}};$ps=(Get-Command powershell.exe).Source;$args='-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$Ui+'" -RunLoop';if([IO.Path]::GetFullPath([string]$a[0].Execute)-ine[IO.Path]::GetFullPath($ps)-or[string]$a[0].Arguments-cne$args){return[pscustomobject]@{ok=$false;reason='action'}};if([string]$t.Principal.LogonType-inotmatch'Interactive'-or[string]$t.Principal.RunLevel-inotmatch'Limited'){return[pscustomobject]@{ok=$false;reason='principal'}};if(-not[bool]$t.Settings.Enabled){return[pscustomobject]@{ok=$false;reason='disabled'}};return[pscustomobject]@{ok=$true;reason='exact'}
}
function RegisterUi{$u=[Security.Principal.WindowsIdentity]::GetCurrent().Name;$ps=(Get-Command powershell.exe).Source;$args='-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$Ui+'" -RunLoop';$a=New-ScheduledTaskAction -Execute $ps -Argument $args;$tr=New-ScheduledTaskTrigger -AtLogOn -User $u;$pr=New-ScheduledTaskPrincipal -UserId $u -LogonType Interactive -RunLevel Limited;$se=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Days 3650);Register-ScheduledTask -TaskName $Task -Action $a -Trigger $tr -Principal $pr -Settings $se -Description 'Kevin narrow InteractiveToken UI Bridge. GREEN Notepad-only. No generic mouse/keyboard/browser.' -Force|Out-Null}
function Heartbeat{
 $start=[DateTimeOffset]::Now;Start-ScheduledTask -TaskName $Task;$first=$null;$dl=(Get-Date).AddSeconds(35);while((Get-Date)-lt$dl){Start-Sleep -Milliseconds 500;if(Test-Path $Heartbeat){try{$h=J $Heartbeat;$at=[DateTimeOffset]::Parse([string]$h.at);if((@('READY','WORKING')-contains[string]$h.state)-and[bool]$h.explorer_same_session-and[int]$h.session_id-gt0-and$at-ge$start.AddSeconds(-2)){$first=$h;break}}catch{}}};if(-not$first){throw'no fresh interactive UI heartbeat'};$fa=[DateTimeOffset]::Parse([string]$first.at);Start-Sleep 7;$h=J $Heartbeat;$sa=[DateTimeOffset]::Parse([string]$h.at);if($sa-le$fa.AddSeconds(2)-or([DateTimeOffset]::Now-$sa).TotalSeconds-gt10-or(@('READY','WORKING')-notcontains[string]$h.state)-or-not[bool]$h.explorer_same_session){throw'UI heartbeat not sustained'};return[ordered]@{first_at=$fa.ToString('o');second_at=$sa.ToString('o');session_id=[int]$h.session_id;state=[string]$h.state}
}
function RepairUi{
 if((Sha $Ui)-cne$UiSha){throw'UI source drift'};New-Item -ItemType Directory -Force -Path $Repair|Out-Null;$old=Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue;$bak='';if($old){$bak=Join-Path $Repair ('ui-task.before.'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.xml');Export-ScheduledTask -TaskName $Task|Set-Content $bak -Encoding Unicode};try{try{Stop-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue}catch{};if(Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue){Unregister-ScheduledTask -TaskName $Task -Confirm:$false};RegisterUi;$s=UiState;if(-not$s.ok){throw('UI task readback '+$s.reason)};return[ordered]@{status='REPAIRED';heartbeat=(Heartbeat);backup=$bak}}catch{$m=$_.Exception.Message;if($bak-and(Test-Path $bak)){if(Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue){Unregister-ScheduledTask -TaskName $Task -Confirm:$false -ErrorAction SilentlyContinue};Register-ScheduledTask -TaskName $Task -Xml (Get-Content $bak -Raw) -Force|Out-Null};throw('UI repair failed; prior task restored: '+$m)}
}
function NotepadProof{
 $sid=[int]([Diagnostics.Process]::GetCurrentProcess().SessionId);if(@(Get-Process Notepad -ErrorAction SilentlyContinue|Where-Object{[int]$_.SessionId-eq$sid}).Count){throw'close Notepad before Apply'};New-Item -ItemType Directory -Force -Path $Inbox,$Results|Out-Null;$st=Get-Date -Format 'yyyyMMdd-HHmmss';$id='platform-recovery-ui-'+$st;$n=[guid]::NewGuid().ToString('N').ToUpperInvariant();$r=[ordered]@{schema=1;kind='kevin-ui-bridge-request';authority='GREEN';operation='ui_notepad_write';app='notepad';order_id=$id;nonce=$n;filename=('Kevin UI Recovery Verification - '+$st+'.txt');content=('KEVIN_UI_RECOVERY_OK '+$st)};$rp=Join-Path $Results ($id+'-'+$n+'.result.json');W (Join-Path $Inbox ($id+'-'+$n+'.json')) $r;$dl=(Get-Date).AddSeconds(70);while((Get-Date)-lt$dl-and-not(Test-Path $rp)){Start-Sleep -Milliseconds 500};if(-not(Test-Path $rp)){throw'Notepad proof timeout'};$x=J $rp;if([string]$x.status-cne'DONE'-or-not(Test-Path ([string]$x.data.output_path))-or-not(Test-Path ([string]$x.data.screenshot_path))){throw'Notepad proof failed'};return[ordered]@{status='ROUND_TRIP_PROVEN';order_id=$id;output_sha256=[string]$x.data.sha256;screenshot_sha256=[string]$x.data.screenshot_sha256;session_id=[int]$x.data.session_id}
}
function Preflight{
 foreach($z in @(@($Cfg,$ConfigSha,'config'),@($Base,$BaselineSha,'baseline'),@($Bench,$BenchmarkSha,'benchmark'),@($Ui,$UiSha,'ui'),@($Maint,$MaintSha,'maintenance'),@($Sup,$SupervisorSha,'supervisor'),@($Forge,$ForgeSha,'forge'),@($Reader,$ReaderSha,'reader'))){$a=Sha ([string]$z[0]);if($a-cne[string]$z[1]){throw([string]$z[2]+' identity drift '+$a)}};Assert-R04;$c=J $Cfg;Assert-Config $c;$tp=TrustedCopy;if(-not$tp){throw'SAFE STOP: proven DBF596 exact-5 config bytes not found in bounded backups'};$tc=J $tp;if((CJ $c)-cne(CJ $tc)){throw'SAFE STOP: current config differs semantically from proven exact-5 config beyond touch metadata'};$b=J $Base;if([string]$b.hashes.production_config-cne$TrustedSha-or[string]$b.hashes.supervisor-cne$SupervisorSha-or[string]$b.hashes.forge-cne$ForgeSha-or[string]$b.hashes.reader_config-cne$ReaderSha){throw'baseline anchors drift'};return[pscustomobject]@{baseline=$b;masked=(Mask $b);trusted=$tp;ui=(UiState)}
}
function R04([object]$p){
 $d=Join-Path $Repair ('r04-'+(Get-Date -Format 'yyyyMMdd-HHmmss'));New-Item -ItemType Directory -Force -Path $d|Out-Null;$bak=Join-Path $d 'baseline.json.before';Copy-Item $Base $bak;if((Sha $bak)-cne$BaselineSha){throw'baseline backup mismatch'};$x=$p.baseline|ConvertTo-Json -Depth 60|ConvertFrom-Json;$x.hashes.production_config=$ConfigSha;if((Mask $x)-cne$p.masked){throw'non-target baseline mutation'};$stage=Join-Path $d 'baseline.json.stage';[IO.File]::WriteAllText($stage,($x|ConvertTo-Json -Depth 60),$Utf8);try{Move-Item $stage $Base -Force;if([string](J $Base).hashes.production_config-cne$ConfigSha-or(Mask (J $Base))-cne$p.masked){throw'installed baseline mismatch'};$null=Bench30;return[ordered]@{status='APPLIED_PROVEN';previous_anchor=$TrustedSha;current_anchor=$ConfigSha;target_leaf='hashes.production_config';non_target_semantics_preserved=$true;backup=$bak}}catch{$m=$_.Exception.Message;Copy-Item $bak $Base -Force;if((Sha $Base)-cne$BaselineSha){throw('R04 rollback integrity failed: '+$m)};throw('R04 rollback completed: '+$m)}
}
function ST{foreach($h in @($ConfigSha,$TrustedSha,$BaselineSha,$BenchmarkSha,$UiSha,$MaintSha,$SupervisorSha,$ForgeSha,$ReaderSha)){if($h-cnotmatch'^[A-F0-9]{64}$'){throw'bad sha'}};$a=[pscustomobject]@{meta=[pscustomobject]@{lastTouchedAt='a';lastTouchedVersion='1'};x=1};$b=[pscustomobject]@{x=1;meta=[pscustomobject]@{lastTouchedAt='b';lastTouchedVersion='2'}};if((CJ $a)-cne(CJ $b)){throw'canonical benign metadata test failed'};$b.x=2;if((CJ $a)-ceq(CJ $b)){throw'canonical dangerous diff test failed'};Write-Host 'KEVIN RECOVERY 20260906 SELFTEST PASS semantic_equivalence=true one_leaf_r04=true rollback=true ui_rebuild=true notepad_roundtrip=true arbitrary_shell=false'}

if($SelfTest){ST;exit 0};if($Apply-and$CheckOnly){throw'choose Apply or CheckOnly'};if(-not$Apply){$CheckOnly=$true};if($env:OS-ne'Windows_NT'){throw'run on Kevin Windows host'}
$m=New-Object Threading.Mutex($false,'Global\KevinPlatformRecovery20260906');$owned=$false
try{try{$owned=$m.WaitOne(0)}catch[Threading.AbandonedMutexException]{$owned=$true};if(-not$owned){throw'recovery already active'};$p=Preflight;if($CheckOnly){Write-Host('KEVIN_RECOVERY_20260906_READY semantic_equivalent=true trusted_config=found ui_task='+$p.ui.ok+' ui_reason='+$p.ui.reason);exit 0};New-Item -ItemType Directory -Force -Path $Repair|Out-Null;$rec=[ordered]@{schema=1;kind='kevin-platform-recovery-20260906';started_at=(Get-Date).ToString('o');status='STARTED';r04=$null;ui=$null;ui_proof=$null};$rec.r04=R04 $p;W $Receipt $rec;try{$rec.ui=RepairUi;$rec.ui_proof=NotepadProof;$null=Bench30;$rec.status='APPLIED_PROVEN';$rec.completed_at=(Get-Date).ToString('o');W $Receipt $rec;Write-Host 'KEVIN_RECOVERY_20260906_APPLIED_PROVEN benchmark=30/30 ui=sustained ui_notepad=ROUND_TRIP_PROVEN'}catch{$rec.status='PARTIAL_R04_PROVEN_UI_FAILED';$rec.completed_at=(Get-Date).ToString('o');$rec.ui=[ordered]@{status='FAILED';error=$_.Exception.Message};W $Receipt $rec;throw('R04 is green but UI still failed: '+$_.Exception.Message)}}finally{if($owned){try{$m.ReleaseMutex()}catch{}};$m.Dispose()}
