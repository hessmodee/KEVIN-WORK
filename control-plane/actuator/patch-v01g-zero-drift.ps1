Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'

$path='control-plane/actuator/kevin-autonomy-actuator-v0.1.ps1'
$text=Get-Content -LiteralPath $path -Raw
$old=@'
function Get-Fingerprint {
    param($Drift)
    $semantic = @($Drift | ForEach-Object { "{0}|{1}|{2}|{3}" -f $_.family,$_.severity,$_.verb,$_.target }) -join "`n"
    return Get-Sha256Text -Text $semantic
}
'@
$new=@'
function Get-Fingerprint {
    param($Drift)
    $items = @($Drift)
    if ($items.Count -eq 0) {
        $semantic = 'NO_DRIFT'
    } else {
        $semantic = @($items | ForEach-Object { "{0}|{1}|{2}|{3}" -f $_.family,$_.severity,$_.verb,$_.target }) -join "`n"
    }
    return Get-Sha256Text -Text $semantic
}
'@
$count=([regex]::Matches($text,[regex]::Escape($old.Trim()))).Count
if($count -ne 1){throw "Get-Fingerprint patch target count=$count, expected 1"}
$text=$text.Replace($old.Trim(),$new.Trim())
[IO.File]::WriteAllText((Resolve-Path $path),$text,(New-Object Text.UTF8Encoding($false)))

$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $path),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'Patched reconciler parse failed'}
$check=Get-Content -LiteralPath $path -Raw
if($check -notmatch [regex]::Escape("`$semantic = 'NO_DRIFT'")){throw 'NO_DRIFT canonical fingerprint marker missing'}
Write-Host 'PASS zero-drift fingerprint patch applied and parsed.'
