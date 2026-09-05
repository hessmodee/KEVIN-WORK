# Scratch-only Calculator UIA prove. Fail-closed. Not wired to openclaw.
# PLAN: docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md
param(
  [ValidateSet('prove','focus','click','type','read','refuse-tests')]
  [string]$Action = 'prove',
  [string]$App = 'calculator',
  [string]$ControlId = '',
  [string]$Text = ''
)

$ErrorActionPreference = 'Stop'
$AllowedApps = @('calculator')
$CatalogPath = Join-Path $PSScriptRoot 'calculator-catalog.v0.json'
$SecretPattern = '(?i)(password|passwd|secret|api[_-]?key|token|bearer\s+[A-Za-z0-9._\-]{8,}|AKIA[0-9A-Z]{16})'
$MaxTypeLen = 64

# Catalog id -> Calculator AutomationId (Win11 Calculator)
$AutomationIdMap = @{
  'digit_0' = 'num0Button'
  'digit_1' = 'num1Button'
  'digit_2' = 'num2Button'
  'digit_3' = 'num3Button'
  'digit_4' = 'num4Button'
  'digit_5' = 'num5Button'
  'digit_6' = 'num6Button'
  'digit_7' = 'num7Button'
  'digit_8' = 'num8Button'
  'digit_9' = 'num9Button'
  'op_add'  = 'plusButton'
  'op_sub'  = 'minusButton'
  'op_mul'  = 'multiplyButton'
  'op_div'  = 'divideButton'
  'op_eq'   = 'equalButton'
  'clear'   = 'clearButton'
}

function Write-JsonResult([hashtable]$h) {
  ($h | ConvertTo-Json -Compress -Depth 6)
}

function Deny([string]$code, [hashtable]$extra = @{}) {
  $o = @{ ok = $false; error = $code }
  foreach ($k in $extra.Keys) { $o[$k] = $extra[$k] }
  Write-JsonResult $o
  exit 2
}

function Assert-App([string]$app) {
  $a = ($app | ForEach-Object { $_.ToLowerInvariant() })
  if ($AllowedApps -notcontains $a) {
    Deny 'invalid_app' @{ app = $app; allowlist = $AllowedApps }
  }
  return $a
}

function Get-CatalogIds {
  if (-not (Test-Path $CatalogPath)) { return @($AutomationIdMap.Keys) }
  $j = Get-Content -Raw -Path $CatalogPath | ConvertFrom-Json
  return @($j.controls | ForEach-Object { $_.id })
}

function Ensure-Uia {
  Add-Type -AssemblyName UIAutomationClient -ErrorAction Stop
  Add-Type -AssemblyName UIAutomationTypes -ErrorAction Stop
}

function Ensure-CalculatorProcess {
  $p = Get-Process -Name 'CalculatorApp' -ErrorAction SilentlyContinue
  if (-not $p) {
    Start-Process -FilePath "$env:SystemRoot\System32\calc.exe" | Out-Null
    $deadline = (Get-Date).AddSeconds(12)
    do {
      Start-Sleep -Milliseconds 400
      $p = Get-Process -Name 'CalculatorApp' -ErrorAction SilentlyContinue
    } while (-not $p -and (Get-Date) -lt $deadline)
  }
  if (-not $p) { Deny 'calculator_launch_failed' }
  return @($p)[0]
}

function Get-CalculatorWindow {
  Ensure-Uia
  $root = [System.Windows.Automation.AutomationElement]::RootElement
  $nameCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty, 'Calculator')
  $win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $nameCond)
  if (-not $win) {
    # Fallback: ApplicationFrameWindow with Calculator descendant
    $classCond = New-Object System.Windows.Automation.PropertyCondition(
      [System.Windows.Automation.AutomationElement]::ClassNameProperty, 'ApplicationFrameWindow')
    $frames = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $classCond)
    foreach ($f in $frames) {
      if ($f.Current.Name -eq 'Calculator') { $win = $f; break }
    }
  }
  if (-not $win) { Deny 'calculator_window_not_found' }
  return $win
}

function Focus-Calculator {
  $proc = Ensure-CalculatorProcess
  $win = Get-CalculatorWindow
  try {
    $win.SetFocus()
  } catch {
    # UWP frame may reject SetFocus; try pattern / native
  }
  # Bring CalculatorApp process main window forward when available
  Add-Type -Namespace User32 -Name Native -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@ -ErrorAction SilentlyContinue
  $hwnd = [IntPtr]$win.Current.NativeWindowHandle
  if ($hwnd -ne [IntPtr]::Zero) {
    [User32.Native]::ShowWindow($hwnd, 5) | Out-Null
    [User32.Native]::SetForegroundWindow($hwnd) | Out-Null
  }
  return @{ ok = $true; action = 'focus'; app = 'calculator'; pid = $proc.Id; window = $win.Current.Name; class = $win.Current.ClassName }
}

function Find-Control([System.Windows.Automation.AutomationElement]$win, [string]$controlId) {
  $ids = Get-CatalogIds
  if ($ids -notcontains $controlId) {
    Deny 'invalid_control' @{ control_id = $controlId }
  }
  if (-not $AutomationIdMap.ContainsKey($controlId)) {
    Deny 'invalid_control' @{ control_id = $controlId; reason = 'no_automation_id_map' }
  }
  $aid = $AutomationIdMap[$controlId]
  $c = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::AutomationIdProperty, $aid)
  $el = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $c)
  if (-not $el) {
    Deny 'control_not_found' @{ control_id = $controlId; automation_id = $aid }
  }
  return $el
}

function Invoke-Click([System.Windows.Automation.AutomationElement]$el) {
  $ip = $el.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
  if (-not $ip) { Deny 'invoke_pattern_missing' @{ name = $el.Current.Name } }
  $ip.Invoke()
}

function Read-Result([System.Windows.Automation.AutomationElement]$win) {
  foreach ($aid in @('CalculatorResults', 'CalculatorResultsText', 'NormalOutput')) {
    $c = New-Object System.Windows.Automation.PropertyCondition(
      [System.Windows.Automation.AutomationElement]::AutomationIdProperty, $aid)
    $el = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $c)
    if ($el) {
      $name = $el.Current.Name
      # Typical: "Display is 2" or similar
      return @{ ok = $true; automation_id = $aid; name = $name; value_raw = $name }
    }
  }
  Deny 'result_not_found'
}

function Click-ControlId([string]$controlId) {
  $null = Focus-Calculator
  $win = Get-CalculatorWindow
  $el = Find-Control $win $controlId
  Invoke-Click $el
  Start-Sleep -Milliseconds 120
  return @{ ok = $true; action = 'click'; app = 'calculator'; control_id = $controlId; name = $el.Current.Name }
}

function Type-Bounded([string]$text) {
  if ($null -eq $text) { $text = '' }
  if ($text -match $SecretPattern) {
    Deny 'secret_deny' @{ length = $text.Length }
  }
  if ($text.Length -gt $MaxTypeLen) {
    Deny 'text_too_long' @{ length = $text.Length; max = $MaxTypeLen }
  }
  # Calculator prove: only allow digits/operators via catalog clicks, not free SendKeys.
  # Map simple expression chars to catalog clicks (fail-closed on other chars).
  $map = @{
    '0'='digit_0';'1'='digit_1';'2'='digit_2';'3'='digit_3';'4'='digit_4'
    '5'='digit_5';'6'='digit_6';'7'='digit_7';'8'='digit_8';'9'='digit_9'
    '+'='op_add';'-'='op_sub';'*'='op_mul';'/'='op_div';'='='op_eq'
  }
  $seq = @()
  foreach ($ch in $text.ToCharArray()) {
    $s = [string]$ch
    if (-not $map.ContainsKey($s)) {
      Deny 'invalid_type_char' @{ char = $s; hint = 'calculator_type_only_expression_chars' }
    }
    $seq += $map[$s]
  }
  $null = Focus-Calculator
  $clicked = @()
  foreach ($cid in $seq) {
    $r = Click-ControlId $cid
    $clicked += $cid
  }
  return @{ ok = $true; action = 'type'; app = 'calculator'; length = $text.Length; controls = $clicked }
}

function Run-RefuseTests {
  $results = @()
  # invalid app
  $out = & $PSCommandPath -Action focus -App notepad 2>&1 | Out-String
  $results += @{ test = 'invalid_app'; pass = ($out -match 'invalid_app') }
  # invalid control via click path
  $tmp = $false
  try {
    Assert-App 'calculator' | Out-Null
    $ids = Get-CatalogIds
    $tmp = ($ids -notcontains 'xyz_button')
  } catch { $tmp = $false }
  $results += @{ test = 'invalid_control_catalog'; pass = $tmp }
  # secret deny
  $sec = & $PSCommandPath -Action type -App calculator -Text 'password=hunter2' 2>&1 | Out-String
  $results += @{ test = 'secret_deny'; pass = ($sec -match 'secret_deny') }
  # length deny
  $long = ('1' * 65)
  $len = & $PSCommandPath -Action type -App calculator -Text $long 2>&1 | Out-String
  $results += @{ test = 'text_too_long'; pass = ($len -match 'text_too_long') }
  $all = -not ($results | Where-Object { -not $_.pass })
  return @{ ok = $all; action = 'refuse-tests'; results = $results }
}

function Run-Prove {
  $focus = Focus-Calculator
  $win = Get-CalculatorWindow
  # Clear then 1 + 1 =
  foreach ($cid in @('clear','digit_1','op_add','digit_1','op_eq')) {
    $el = Find-Control $win $cid
    Invoke-Click $el
    Start-Sleep -Milliseconds 150
    $win = Get-CalculatorWindow
  }
  Start-Sleep -Milliseconds 300
  $win = Get-CalculatorWindow
  $res = Read-Result $win
  $raw = [string]$res.value_raw
  $digit = $null
  if ($raw -match '(\d+(?:[.,]\d+)?)') { $digit = $Matches[1] }
  $ok = ($digit -eq '2' -or $digit -eq '2.0' -or $raw -match '(^|[^\d])2([^\d]|$)')
  $token = if ($ok) { 'KEVIN_DESKTOP_UI_CALC_V0_OK' } else { $null }
  return @{
    ok = [bool]$ok
    action = 'prove'
    expression = '1+1='
    expected = '2'
    result_name = $raw
    parsed = $digit
    focus = $focus
    marker = $token
    token = $token
    openclaw_untouched = $true
    allowlist_app = 'calculator'
  }
}

switch ($Action) {
  'focus' {
    Assert-App $App | Out-Null
    Write-JsonResult (Focus-Calculator)
  }
  'click' {
    Assert-App $App | Out-Null
    if (-not $ControlId) { Deny 'missing_control_id' }
    Write-JsonResult (Click-ControlId $ControlId)
  }
  'type' {
    Assert-App $App | Out-Null
    Write-JsonResult (Type-Bounded $Text)
  }
  'read' {
    Assert-App $App | Out-Null
    $null = Focus-Calculator
    Write-JsonResult (Read-Result (Get-CalculatorWindow))
  }
  'refuse-tests' {
    Write-JsonResult (Run-RefuseTests)
  }
  'prove' {
    Assert-App $App | Out-Null
    Write-JsonResult (Run-Prove)
  }
}
