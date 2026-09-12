# Publish-Kevin-OwnerOutcomes-v1.ps1
# Rebuild reports/owner-outcomes-latest.json from reports/invocations/done (MIXED, autonomy_credit=false).
# HARD GATE: does not mint packs / F17F. Optional -PushPublic publishes the JSON only.
param([switch]$PushPublic)
$ErrorActionPreference = 'Stop'
$ws = Join-Path $env:USERPROFILE '.openclaw\workspace'
$py = Join-Path $env:TEMP 'publish-owner-outcomes-inline.py'
$utf8 = New-Object System.Text.UTF8Encoding $false
@"
from pathlib import Path
import json
from datetime import datetime, timezone
ws = Path(r'$($ws.Replace('\','\\'))')
done = ws / 'reports' / 'invocations' / 'done'
out_path = ws / 'reports' / 'owner-outcomes-latest.json'
outcomes = []
newest = None
newest_at = ''
for p in sorted(done.glob('invoke-*.json'), key=lambda x: x.stat().st_mtime):
    d = json.loads(p.read_text(encoding='utf-8'))
    if d.get('status') != 'PROVEN':
        continue
    inv = str(d.get('invocation_id') or p.stem)
    wid = inv[7:] if inv.startswith('invoke-') else inv
    skill = str(d.get('skill_key') or '')
    receipt = str(d.get('receipt_sha256') or '')
    completed = str(d.get('completed_at') or '')
    if skill.startswith('west-motor-') or skill == 'vehicle-transport-mission-pack@1':
        family = 'west-motor-owner-value'
    elif 'dealership' in skill or skill.startswith('dealer-'):
        family = 'dealership-owner-value'
    elif skill.endswith('-design-pack@1') or 'diagnosis' in skill:
        family = 'platform-design'
    else:
        family = 'other'
    row = {
        'work_id': wid,
        'invocation_id': inv,
        'skill_key': skill,
        'receipt_sha256': receipt,
        'completed_at': completed,
        'status': 'PROVEN',
        'actor': 'MIXED',
        'autonomy_credit': False,
        'family': family,
        'clone_spreadsheet_text': family in {'west-motor-owner-value','dealership-owner-value'},
        'verify_note': 'VERIFY may PASS/MIXED; RUNTIME does not claim PASS',
    }
    outcomes.append(row)
    if completed and completed >= newest_at:
        newest_at = completed
        newest = row
doc = {
    'schema': 1,
    'kind': 'kevin-owner-outcomes-latest',
    'generated_at': datetime.now(timezone.utc).isoformat().replace('+00:00','Z'),
    'authority': 'RUNTIME_REPORT_ONLY',
    'pass_claim': False,
    'freeze': {'clone_prove_minting': 'HARD_STOP'},
    'newest_receipt': {
        'work_id': (newest or {}).get('work_id'),
        'receipt_sha256': (newest or {}).get('receipt_sha256'),
        'completed_at': newest_at,
        'skill_key': (newest or {}).get('skill_key'),
    },
    'count': len(outcomes),
    'outcomes': sorted(outcomes, key=lambda r: r.get('completed_at') or '', reverse=True),
}
out_path.write_text(json.dumps(doc, indent=2) + '\n', encoding='utf-8')
print(out_path)
print('count', len(outcomes))
print('newest', newest_at)
"@ | Set-Content -LiteralPath $py -Encoding UTF8
python $py
if ($LASTEXITCODE -ne 0) { throw 'owner-outcomes rebuild failed' }
if ($PushPublic) {
  $local = Join-Path $ws 'reports\owner-outcomes-latest.json'
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($local))
  $sha = $null; try { $sha = gh api repos/hessmodee/KEVIN-WORK/contents/reports/owner-outcomes-latest.json --jq .sha } catch {}
  $bp = Join-Path $env:TEMP 'gh-owner-outcomes.json'
  $body = @{ message = 'GROKBOT_ACTED: owner-outcomes-latest from done receipts (MIXED, autonomy_credit=false)'; content = $b64 }
  if ($sha) { $body.sha = $sha }
  [IO.File]::WriteAllText($bp, ($body | ConvertTo-Json -Compress), $utf8)
  gh api --method PUT repos/hessmodee/KEVIN-WORK/contents/reports/owner-outcomes-latest.json --input $bp --jq .commit.sha
}
