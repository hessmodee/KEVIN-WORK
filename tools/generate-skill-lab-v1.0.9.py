#!/usr/bin/env python3
from pathlib import Path

SRC = Path('control-plane/skill-lab/kevin-skill-lab-v1.0.8.ps1')
DST = Path('control-plane/skill-lab/kevin-skill-lab-v1.0.9.ps1')
text = SRC.read_text(encoding='utf-8')

old_comment = '# Kevin Skill Lab v1.0.8 - converge replay-safe owner-work execution with the proven mission-lease live wire.'
new_comment = '# Kevin Skill Lab v1.0.9 - accept evidence-backed READY owner work without resetting historical continuation attempts.'
if old_comment not in text:
    raise SystemExit('version comment anchor missing')
text = text.replace(old_comment, new_comment, 1)

owner_stage_anchor = 'function OwnerWorkStage {'
eligibility_helper = r'''function OwnerWorkEligible($item) {
    if(-not$item){return $false}
    if([string]$item.program-ne'owner-value-skills'){return $false}
    if([string]$item.authority_class-ne'GREEN'){return $false}
    if(@('OPEN','READY')-notcontains[string]$item.status){return $false}
    if(-not[bool]$item.dependencies_ready){return $false}
    if([bool]$item.blocked){return $false}
    return $true
}
'''
if owner_stage_anchor not in text:
    raise SystemExit('OwnerWorkStage anchor missing')
text = text.replace(owner_stage_anchor, eligibility_helper + owner_stage_anchor, 1)

old_guard = "if([string]$item.program-ne'owner-value-skills'-or[string]$item.authority_class-ne'GREEN'-or[string]$item.status-ne'OPEN'-or-not[bool]$item.dependencies_ready-or[bool]$item.blocked){throw'owner work item no longer eligible'}"
new_guard = "if(-not(OwnerWorkEligible $item)){throw'owner work item no longer eligible'}"
if old_guard not in text:
    raise SystemExit('owner eligibility guard anchor missing')
text = text.replace(old_guard, new_guard, 1)

old_manifest = "$manifest=OwnerManifest $id;Skill $manifest;$key=[string]$manifest.id+'@'+[string]$manifest.version"
new_manifest = "$manifest=OwnerManifest $id;$manifest|Add-Member -NotePropertyName source_route_fingerprint -NotePropertyValue ([string]$route.fingerprint);$manifest|Add-Member -NotePropertyName source_route_generated_at -NotePropertyValue ([string]$route.generated_at);Skill $manifest;$key=[string]$manifest.id+'@'+[string]$manifest.version"
if old_manifest not in text:
    raise SystemExit('owner manifest correlation anchor missing')
text = text.replace(old_manifest, new_manifest, 1)

compat_old = 'KEVIN SKILL LAB v1.0.3 SELFTEST PASS compatibility=v1.0.8-maintenance-v1.2'
compat_new = 'KEVIN SKILL LAB v1.0.3 SELFTEST PASS compatibility=v1.0.9-maintenance-v1.2'
if compat_old not in text:
    raise SystemExit('compatibility marker anchor missing')
text = text.replace(compat_old, compat_new, 1)

marker_old = "Write-Host 'KEVIN SKILL LAB v1.0.8 SELFTEST PASS primitives=3 owner_work_compiler=fixed_green route_proof_required=true replay_receipt_preserved=true mission_lease_wire=preserved lease_release_on_terminal=true exact_recipe_allowlist=true arbitrary_shell=false authority_expansion=false'"
marker_new = "$elig=[pscustomobject]@{program='owner-value-skills';authority_class='GREEN';status='OPEN';dependencies_ready=$true;blocked=$false};if(-not(OwnerWorkEligible $elig)){throw'OPEN owner work eligibility rejected'};$elig.status='READY';if(-not(OwnerWorkEligible $elig)){throw'READY owner work eligibility rejected'};$elig.status='COMPLETE';if(OwnerWorkEligible $elig){throw'COMPLETE owner work eligibility accepted'};$elig.status='OPEN';$elig.blocked=$true;if(OwnerWorkEligible $elig){throw'blocked owner work eligibility accepted'};Write-Host 'KEVIN SKILL LAB v1.0.9 SELFTEST PASS primitives=3 owner_work_compiler=fixed_green owner_statuses=OPEN,READY route_proof_required=true route_correlation_persisted=true replay_receipt_preserved=true mission_lease_wire=preserved lease_release_on_terminal=true exact_recipe_allowlist=true arbitrary_shell=false authority_expansion=false'"
if marker_old not in text:
    raise SystemExit('v1.0.8 selftest marker anchor missing')
text = text.replace(marker_old, marker_new, 1)

required = [
    '# Kevin Skill Lab v1.0.9',
    'function OwnerWorkEligible',
    "@('OPEN','READY')-notcontains[string]$item.status",
    "if(-not(OwnerWorkEligible $item)){throw'owner work item no longer eligible'}",
    'source_route_fingerprint',
    'source_route_generated_at',
    'Preserve-ProvenReplay',
    "Invoke-MissionLease 'Acquire'",
    "Invoke-MissionLease 'Heartbeat'",
    "Invoke-MissionLease 'Release'",
    'kevin-owner-work-outcome',
    'v1.0.9 SELFTEST PASS',
]
for marker in required:
    if marker not in text:
        raise SystemExit('required marker missing: ' + marker)

for forbidden in ['Invoke-Expression', 'cmd.exe']:
    if forbidden in text:
        raise SystemExit('forbidden execution surface present: ' + forbidden)

DST.write_text(text, encoding='utf-8', newline='\n')
print(f'generated {DST} bytes={DST.stat().st_size}')
