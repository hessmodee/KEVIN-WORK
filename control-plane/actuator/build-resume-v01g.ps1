Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$src='control-plane/actuator/KEVIN-AUTONOMY-RESUME-v0.1f.ps1'
$dst='control-plane/actuator/KEVIN-AUTONOMY-RESUME-v0.1g.ps1'
$text=Get-Content -LiteralPath $src -Raw
$repls=[ordered]@{
 'v0.1f'='v0.1g'
 "`$OldActuatorBlob='38bc72bc29569c72c3618b0b8ce8fa59876ba76c'"="`$OldActuatorBlob='ef1e7f9ea6847e6d963af0cd40c28735573bc26d'"
 "`$NewActuatorBlob='ef1e7f9ea6847e6d963af0cd40c28735573bc26d'"="`$NewActuatorBlob='489dfd2277245341a790c00a5db04ecd3ffb4fab'"
}
foreach($kv in $repls.GetEnumerator()){
 $count=([regex]::Matches($text,[regex]::Escape([string]$kv.Key))).Count
 if($kv.Key -eq 'v0.1f'){
  if($count -lt 2){throw "Expected multiple v0.1f markers, found $count"}
 } elseif($count -ne 1){throw "Replacement target count=$count for $($kv.Key)"}
 $text=$text.Replace([string]$kv.Key,[string]$kv.Value)
}
[IO.File]::WriteAllText((Join-Path (Get-Location) $dst),$text,(New-Object Text.UTF8Encoding($false)))
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $dst),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'Resume v0.1g parse failed'}
$check=Get-Content -LiteralPath $dst -Raw
if($check -notmatch '489dfd2277245341a790c00a5db04ecd3ffb4fab'){throw 'New repaired actuator blob pin missing'}
if($check -notmatch 'ef1e7f9ea6847e6d963af0cd40c28735573bc26d'){throw 'Current installed actuator blob pin missing'}
if($check -match '38bc72bc29569c72c3618b0b8ce8fa59876ba76c'){throw 'Obsolete actuator pin remains'}
Write-Host 'PASS resume v0.1g generated and parsed.'
