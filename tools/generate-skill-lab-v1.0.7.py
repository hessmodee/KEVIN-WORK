#!/usr/bin/env python3
from pathlib import Path

SRC = Path('control-plane/skill-lab/kevin-skill-lab-v1.0.6.ps1')
DST = Path('control-plane/skill-lab/kevin-skill-lab-v1.0.7.ps1')
text = SRC.read_text(encoding='utf-8')

text = text.replace(
    '# Kevin Skill Lab v1.0.6 - preserve learned-skill registry and original completed replay receipts.',
    '# Kevin Skill Lab v1.0.7 - autonomously compile a fixed GREEN owner-work recipe after a fresh Supervisor Skill Lab handoff.'
)
text = text.replace(
    "$reg=Join-Path $ws 'reports\\capabilities\\composite-skills.json';$qr=Join-Path $a 'queue\\ready';$qrun=Join-Path $a 'queue\\running';$qd=Join-Path $a 'queue\\done';$qf=Join-Path $a 'queue\\failed';$staleMin=15;$maxRecover=3",
    "$reg=Join-Path $ws 'reports\\capabilities\\composite-skills.json';$ow=Join-Path $ws 'reports\\owner-work';$owLatest=Join-Path $ow 'latest.json';$qr=Join-Path $a 'queue\\ready';$qrun=Join-Path $a 'queue\\running';$qd=Join-Path $a 'queue\\done';$qf=Join-Path $a 'queue\\failed';$staleMin=15;$maxRecover=3"
)
text = text.replace(
    "foreach($d in @($rr,$run,$sd,$sf,(Split-Path $reg -Parent),$qr,$qrun,$qd,$qf)){New-Item -ItemType Directory -Force $d|Out-Null}",
    "foreach($d in @($rr,$run,$sd,$sf,(Split-Path $reg -Parent),$ow,$qr,$qrun,$qd,$qf)){New-Item -ItemType Directory -Force $d|Out-Null}"
)

insert_before = 'function SelfTest{'
if insert_before not in text:
    raise SystemExit('selftest anchor missing')

owner_code = r'''function RemoteOwnerWorkItems {
    $gh=(Get-Command gh -ErrorAction Stop).Source
    $oldGh=[Environment]::GetEnvironmentVariable('GH_TOKEN','Process');$oldGithub=[Environment]::GetEnvironmentVariable('GITHUB_TOKEN','Process')
    try{
        Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue;Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue;$env:GH_PROMPT_DISABLED='1'
        $old=$ErrorActionPreference
        try{$ErrorActionPreference='Continue';$out=(& $gh api 'repos/hessmodee/KEVIN-WORK/contents/inbox/autonomy/work-items.json' '--jq' '.content' 2>&1|Out-String).Trim();$code=[int]$LASTEXITCODE}finally{$ErrorActionPreference=$old}
        if($code-ne0){throw'owner work catalog fetch failed'}
        $raw=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$out-replace'\s','')))
        $x=$raw|ConvertFrom-Json
        if([int]$x.schema-ne1-or[string]$x.kind-ne'kevin-work-items'-or-not[bool]$x.safe_for_public_repo){throw'owner work catalog contract invalid'}
        return $x
    }finally{
        if($null-ne$oldGh){$env:GH_TOKEN=$oldGh}else{Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue}
        if($null-ne$oldGithub){$env:GITHUB_TOKEN=$oldGithub}else{Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue}
    }
}
function OwnerManifest([string]$id){
    if($id-ne'owner-west-motor-transport-dispatch-template-v1'){throw'owner work recipe not allowlisted'}
    $rows=@(
        @('Request ID','Priority','Origin','Destination','Vehicle / Unit','Driver / Assignee','Target Date','Target Time','Status','Contact / Coordination','Completion','Exception / Follow-up'),
        @('T-001','High','Preston CDJR','Logan','Example SUV','Unassigned','YYYY-MM-DD','09:00','Requested','Confirm keys and pickup contact','',''),
        @('T-002','Normal','Logan','Ogden','Example Truck','Unassigned','YYYY-MM-DD','13:00','Scheduled','Confirm destination contact','','')
    )
    $lists=@(
        @('Priority','Status','Use'),
        @('Urgent','Requested','New request awaiting scheduling'),
        @('High','Scheduled','Driver and timing assigned'),
        @('Normal','In Transit','Vehicle moving'),
        @('Low','Delivered','Destination handoff complete'),
        @('','Exception','Blocked, delayed, or needs follow-up')
    )
    $wb=[pscustomobject]@{schema=1;kind='kevin-xlsx-spec';sheets=@(
        [pscustomobject]@{name='Dispatch Board';rows=$rows},
        [pscustomobject]@{name='Lists';rows=$lists}
    )}
    $guide="# West Motor Transport Dispatch Board`n`nUse the Dispatch Board as the daily handoff list for dealership vehicle movement. Add one row per transport request. Set priority first, then origin/destination, vehicle or unit, assignee, target date/time, and status. Use Contact / Coordination for pickup or delivery coordination without storing sensitive customer data. Mark Completion only after the destination handoff is confirmed. Put delays, missing keys, unavailable drivers, or other blockers in Exception / Follow-up and review those rows first at each handoff.`n`nRecommended flow: Requested -> Scheduled -> In Transit -> Delivered. Use Exception whenever the normal flow is blocked.`n"
    return [pscustomobject]@{schema=1;kind='kevin-composite-skill';id='west-motor-transport-dispatch-board-pack';version='1';authority='GREEN';name='West Motor Transport Dispatch Board';source_work_item_id=$id;steps=@(
        [pscustomobject]@{operation='create_spreadsheet';payload=[pscustomobject]@{filename='west-motor-transport-dispatch-board.xlsx';workbook=$wb}},
        [pscustomobject]@{operation='create_text';payload=[pscustomobject]@{filename='west-motor-transport-dispatch-quick-guide.md';content=$guide}}
    )}
}
function OwnerWorkStage {
    if(@(Get-ChildItem $run -File -Filter '*.json' -ErrorAction SilentlyContinue).Count-or@(Get-ChildItem $rr -File -Filter '*.json' -ErrorAction SilentlyContinue).Count){return $false}
    $route=ReadJ (Join-Path $ws 'reports\\autonomy-continuation-latest.json')
    if(-not$route-or[string]$route.status-ne'ROUTED_TO_SKILL_LAB'-or[string]$route.worker-ne'skill-lab'-or[bool]$route.turn_charged-ne$false){return $false}
    if((Age ([string]$route.generated_at))-gt20){return $false}
    $id=[string]$route.selected_id
    if($id-ne'owner-west-motor-transport-dispatch-template-v1'){return $false}
    $catalog=RemoteOwnerWorkItems
    $hits=@($catalog.items|Where-Object{[string]$_.id-eq$id})
    if($hits.Count-ne1){throw'owner work item uniqueness violation'}
    $item=$hits[0]
    if([string]$item.program-ne'owner-value-skills'-or[string]$item.authority_class-ne'GREEN'-or[string]$item.status-ne'OPEN'-or-not[bool]$item.dependencies_ready-or[bool]$item.blocked){throw'owner work item no longer eligible'}
    $manifest=OwnerManifest $id;Skill $manifest;$key=[string]$manifest.id+'@'+[string]$manifest.version
    $rg=Registry
    if(@($rg.skills|Where-Object{[string]$_.key-eq$key}).Count){return $false}
    $ready=Join-Path $rr ([string]$manifest.id+'--'+[string]$manifest.version+'.json')
    if(Test-Path -LiteralPath $ready -PathType Leaf){return $false}
    W $ready $manifest
    W $owLatest ([ordered]@{schema=1;kind='kevin-owner-work-handoff';at=(Get-Date).ToString('o');status='STAGED_TO_SKILL_LAB';work_item_id=$id;skill_key=$key;route_generated_at=[string]$route.generated_at;route_fingerprint=[string]$route.fingerprint;authority='GREEN';turn_charged=$false})
    Write-Host('SKILL LAB OWNER_WORK_STAGED '+$id+' -> '+$key)
    return $true
}
'''
text = text.replace(insert_before, owner_code + insert_before, 1)

old_complete = ";[void](MoveR $p $sd);Write-Host('SKILL LAB PROVEN '+$key)}"
new_complete = ";[void](MoveR $p $sd);if($s.manifest.PSObject.Properties.Name-contains'source_work_item_id'){W $owLatest ([ordered]@{schema=1;kind='kevin-owner-work-outcome';at=$s.completed_at;status='PROVEN';work_item_id=[string]$s.manifest.source_work_item_id;skill_key=$key;manifest_sha256=[string]$s.manifest_sha256;proof_sha256=[string]$s.proof_sha256;authority='GREEN';outcome_proven=$true})};Write-Host('SKILL LAB PROVEN '+$key)}"
if old_complete not in text:
    raise SystemExit('completion anchor missing')
text = text.replace(old_complete, new_complete, 1)

old_selftest = "Write-Host 'KEVIN SKILL LAB v1.0.3 SELFTEST PASS compatibility=v1.0.6-maintenance-v1.2';Write-Host 'KEVIN SKILL LAB v1.0.6 SELFTEST PASS primitives=3 crash_reconcile=1 registry_fail_closed=1 replay_receipt_preserved=1 arbitrary_shell=false'}"
new_selftest = "Write-Host 'KEVIN SKILL LAB v1.0.3 SELFTEST PASS compatibility=v1.0.7-maintenance-v1.2';$om=OwnerManifest 'owner-west-motor-transport-dispatch-template-v1';Skill $om;if(@($om.steps).Count-ne2-or[string]$om.steps[0].operation-ne'create_spreadsheet'-or[string]$om.steps[1].operation-ne'create_text'){throw'owner recipe selftest failed'};$ownerBlocked=$false;try{[void](OwnerManifest 'not-allowlisted')}catch{$ownerBlocked=$true};if(-not$ownerBlocked){throw'unknown owner work recipe accepted'};Write-Host 'KEVIN SKILL LAB v1.0.7 SELFTEST PASS primitives=3 owner_work_compiler=fixed_green route_proof_required=true exact_recipe_allowlist=true arbitrary_shell=false authority_expansion=false'}"
if old_selftest not in text:
    raise SystemExit('selftest marker anchor missing')
text = text.replace(old_selftest, new_selftest, 1)

old_loop = "try{$own=$m.WaitOne(0);if(-not$own){Write-Host 'SKILL LAB SKIP overlap';exit 0};[void](Registry);$f=Get-ChildItem $run -File -Filter '*.json'"
new_loop = "try{$own=$m.WaitOne(0);if(-not$own){Write-Host 'SKILL LAB SKIP overlap';exit 0};[void](Registry);[void](OwnerWorkStage);$f=Get-ChildItem $run -File -Filter '*.json'"
if old_loop not in text:
    raise SystemExit('main-loop anchor missing')
text = text.replace(old_loop, new_loop, 1)

if 'v1.0.6 SELFTEST PASS' in text:
    raise SystemExit('stale v1.0.6 selftest marker remains')
DST.write_text(text, encoding='utf-8', newline='\n')
print(f'generated {DST} bytes={DST.stat().st_size}')
