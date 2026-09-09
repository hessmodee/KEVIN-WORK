param([switch]$SelfTest)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Workspace = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.openclaw\workspace' } else { $PSScriptRoot }
$Known = @('Kevin Self-Reliance Watchdog v1','KevinGitHubBridge','KevinNightForge','Kevin UI Bridge v0.3','KevinGatewayKeeper')

function Add-HiddenWindowStyle([string]$Arguments) {
    $a = [string]$Arguments
    if ($a -match '(?i)(?:^|\s)-(?:WindowStyle|w)\s+Hidden(?:\s|$)') { return $a }
    if ([string]::IsNullOrWhiteSpace($a)) { return '-WindowStyle Hidden' }
    return ('-WindowStyle Hidden ' + $a.Trim())
}
function Get-HiddenRunnerPath {
    $dir = Join-Path $Workspace 'tools'
    $path = Join-Path $dir 'kevin-hidden-run.vbs'
    $vbs = @"
If WScript.Arguments.Count < 1 Then WScript.Quit 1
Dim i, a, cmd
cmd = ""
For i = 0 To WScript.Arguments.Count - 1
  a = WScript.Arguments(i)
  If (InStr(a, " ") > 0) And (Left(a, 1) <> Chr(34)) Then a = Chr(34) & a & Chr(34)
  If i > 0 Then cmd = cmd & " "
  cmd = cmd & a
Next
CreateObject("WScript.Shell").Run cmd, 0, False
"@
    New-Item -ItemType Directory -Force $dir | Out-Null
    [IO.File]::WriteAllText($path, $vbs, $Utf8)
    return $path
}
function Get-WscriptPath {
    foreach ($c in @((Join-Path $env:SystemRoot 'System32\wscript.exe'), 'wscript.exe')) {
        if (Test-Path -LiteralPath $c -PathType Leaf) { return $c }
    }
    $cmd = Get-Command wscript.exe -ErrorAction SilentlyContinue
    if ($cmd) { return [string]$cmd.Source }
    return $null
}
if ($SelfTest) {
    if ((Add-HiddenWindowStyle '-NoProfile -File x.ps1') -ne '-WindowStyle Hidden -NoProfile -File x.ps1') { throw 'hidden insert' }
    Write-Host 'KEVIN CONSOLE HYGIENE v1.7 SELFTEST PASS'
    exit 0
}
if ($env:OS -ne 'Windows_NT') { throw 'Windows only' }
$wscript = Get-WscriptPath
if (-not $wscript) { throw 'wscript.exe missing' }
$vbs = Get-HiddenRunnerPath
$changed = 0
$failures = 0
$names = New-Object System.Collections.Generic.List[string]
foreach ($n in $Known) { $names.Add($n) }
try {
    foreach ($t in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Kevin*' -or $_.TaskName -like 'OpenClaw*' })) {
        if (-not $names.Contains([string]$t.TaskName)) { $names.Add([string]$t.TaskName) }
    }
} catch {}
foreach ($name in $names) {
    try {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        if (-not $task) { continue }
        $actions = @($task.Actions)
        if ($actions.Count -ne 1) { continue }
        $a = $actions[0]
        $execute = [string]$a.Execute
        $args = [string]$a.Arguments
        $exeName = [IO.Path]::GetFileName($execute)
        if ($exeName -match '(?i)^wscript\.exe$' -and $args -match [regex]::Escape($vbs)) { continue }
        if ($exeName -notmatch '(?i)^(powershell|pwsh|cmd)\.exe$') { continue }
        $quotedExe = if ($execute -match '\s') { '"' + $execute + '"' } else { $execute }
        $hiddenArgs = if ($exeName -match '(?i)^(powershell|pwsh)\.exe$') { Add-HiddenWindowStyle $args } else { $args }
        $wrapped = ('"{0}" {1} {2}' -f $vbs, $quotedExe, $hiddenArgs).Trim()
        $p = @{ Execute = $wscript; Argument = $wrapped }
        if (-not [string]::IsNullOrWhiteSpace([string]$a.WorkingDirectory)) { $p.WorkingDirectory = [string]$a.WorkingDirectory }
        Set-ScheduledTask -TaskName $name -Action (New-ScheduledTaskAction @p) -ErrorAction Stop | Out-Null
        $changed++
        Write-Host ("wrapped {0}" -f $name)
    } catch {
        $failures++
        Write-Host ("fail {0}: {1}" -f $name, $_.Exception.Message)
    }
}
Write-Host ("KEVIN CONSOLE HYGIENE v1.7 done changed={0} failures={1} vbs={2}" -f $changed, $failures, $vbs)
if ($failures -gt 0 -and $changed -eq 0) { exit 1 }
exit 0
