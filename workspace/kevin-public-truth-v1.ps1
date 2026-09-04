# Kevin public_truth helper v1 — scrubbed metadata for Support/Engineering publishers.
# Does NOT read or write openclaw.json / Desktop allow-list / Chat ports.
# Slice 1: desktop_tool_inventory_count only.

[CmdletBinding()]
param(
  [switch]$SelfTest
)

$ErrorActionPreference = "Stop"

function Get-KevinPublicTruthV1 {
  param(
    [string]$WorkspaceRoot = $(Join-Path $env:USERPROFILE ".openclaw\workspace"),
    [string]$RepoRoot = $null
  )

  $candidates = @()
  if ($RepoRoot) {
    $candidates += (Join-Path $RepoRoot "reports\engineering\RECEIPT-p01-desktop-crossing-apply-20260904-0809.json")
  }
  $candidates += (Join-Path $WorkspaceRoot "kevin-work-repo\reports\engineering\RECEIPT-p01-desktop-crossing-apply-20260904-0809.json")
  $candidates += (Join-Path $WorkspaceRoot "reports\engineering\RECEIPT-p01-desktop-crossing-apply-20260904-0809.json")

  $receiptPath = $null
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { $receiptPath = $c; break }
  }

  $count = $null
  $source = "unknown"
  $status = "UNKNOWN"

  if ($receiptPath) {
    try {
      $r = Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
      $v = $r.after.visible_tool_count
      if ($null -eq $v) { $v = $r.after.visible_kevin_tool_count }
      if ($null -ne $v -and [int]$v -ge 0) {
        $count = [int]$v
        $source = "p01_desktop_crossing_receipt"
        $status = "REPORTED_NONEMPTY"
        if ($count -eq 0) { $status = "REPORTED_EMPTY" }
      }
    } catch {
      $status = "INVALID"
      $source = "p01_receipt_parse_error"
    }
  }

  return [ordered]@{
    schema = 1
    kind = "kevin-public-truth-v1"
    safe_for_public_repo = $true
    desktop_tool_inventory_count = $count
    desktop_tool_inventory_status = $status
    desktop_tool_inventory_source = $source
    # Placeholders for later Phase A slices — absent/null => HQ unknown
    mission_lease = $null
    routed_to_skill_lab = $null
    drive_interim = $null
    grants_budget_unlock = $null
  }
}

if ($SelfTest) {
  $here = Split-Path -Parent $MyInvocation.MyCommand.Path
  $repo = Split-Path -Parent $here
  $t = Get-KevinPublicTruthV1 -RepoRoot $repo
  if ($null -eq $t.desktop_tool_inventory_count -or [int]$t.desktop_tool_inventory_count -ne 4) {
    throw "SELFTEST FAIL expected desktop_tool_inventory_count=4 got=$($t.desktop_tool_inventory_count)"
  }
  if ($t.desktop_tool_inventory_source -ne "p01_desktop_crossing_receipt") {
    throw "SELFTEST FAIL unexpected source=$($t.desktop_tool_inventory_source)"
  }
  Write-Host "KEVIN PUBLIC TRUTH v1 SELFTEST PASS desktop_tool_inventory_count=4 source=p01_desktop_crossing_receipt openclaw_untouched=true"
  exit 0
}

Get-KevinPublicTruthV1