from pathlib import Path
import re

BASE = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.13.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.14.ps1')

text = BASE.read_text(encoding='utf-8')
original = text

old_version = "version='1.3.13'"
if text.count(old_version) != 1:
    raise SystemExit(f'expected exactly one {old_version!r}')
text = text.replace(old_version, "version='1.3.14'")

replacement = r'''function Get-FixedGoalOsFile([string]$ExpectedSha) {
    $p=Join-Path $Reports 'goals\goal-os.json'
    if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw 'Fixed Goal OS file missing'}
    $actual=Get-Sha $p
    if($actual-ne$ExpectedSha){throw ('Fixed Goal OS hash mismatch actual='+$actual)}
    return (Get-Item -LiteralPath $p)
}
function Find-ForgeAnchorMatches'''

text, n = re.subn(
    r'function Get-BoundedJsonInventory \{.*?\nfunction Find-ForgeAnchorMatches',
    lambda _m: replacement,
    text,
    count=1,
    flags=re.S,
)
if n != 1:
    raise SystemExit('failed to replace broad Goal OS inventory helpers exactly once')

old_lookup = "$files=@(Find-JsonBySha $goalSha)\n    if($files.Count-ne1){throw ('Goal OS exact-hash file match count must be 1; count='+$files.Count)}\n    $goalFile=$files[0]"
new_lookup = "$goalFile=Get-FixedGoalOsFile $goalSha\n    $files=@($goalFile)"
if text.count(old_lookup) != 1:
    raise SystemExit('failed to find exact Goal OS lookup sequence exactly once')
text = text.replace(old_lookup, new_lookup)

old_contract = "source_contract='Fixed Workspace JSON inventory capped at 500; exact Goal OS SHA from fixed Support snapshot; fixed live Forge SHA. No caller-selected path, hash, property, root, pattern, command, or argv.'"
new_contract = "source_contract='Fixed reports/goals/goal-os.json path; exact Goal OS SHA from fixed Support snapshot; fixed live Forge SHA. No caller-selected path, hash, property, root, pattern, command, or argv.'"
if old_contract not in text:
    raise SystemExit('Goal OS source contract marker missing')
text = text.replace(old_contract, new_contract)

if 'Get-BoundedJsonInventory' in text or 'Find-JsonBySha' in text:
    raise SystemExit('broad Goal OS inventory code remained')
for required in [
    'Get-FixedGoalOsFile',
    "Join-Path $Reports 'goals\\goal-os.json'",
    'Fixed Goal OS hash mismatch',
    'Find-ForgeAnchorMatches',
    'diagnose_goal_os_forge_anchor',
    'Assert-Benchmark30',
]:
    if required not in text:
        raise SystemExit('missing invariant: '+required)
if text == original:
    raise SystemExit('generator produced no change')

OUT.write_text(text, encoding='utf-8', newline='\n')
print(OUT)
