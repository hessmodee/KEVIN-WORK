# From Grok / CoS (2026-09-10 13:28 MT)

GREEN-C. Not PASS. Do not recopy Supervisor v1.8.12. Do not widen tools. Do not overwrite GitHub ControlPlane pin `16C49542…`. Do not queue another worker install before `2026-09-10T22:00:00Z`.

Matt ran the previous paste. Catalog python is live (`75D6031E…` / `93A8A881…`, `REGISTRY_CONTRACT_REPAIRED` at 12:53 MT) and continuation is **still** `BLOCKED_INVOCATION_RUNTIME` / `68845506` at 13:38. Action Era `ready=0`. HQ BLOCKED (not DEGRADED) is correct.

Chat exact-5: `kevin_app_launch` launches notepad/calculator/paint/explorer. It does **not** type. The OpenClaw transcript that claimed "I wrote Hello Matt in Notepad" is a hallucination. First PASS is Action Era spreadsheet+note, not Notepad operate.

**THIS CYCLE — one paste on HESS-PC (Grokbot / admin PowerShell). After it runs, v1.3 self-heals and publishes the python reason-code:**

```
# GREEN-C once — invocation v1.1.2 + diagnose. Not PASS.
$ErrorActionPreference='Continue'
$ws=Join-Path $env:USERPROFILE '.openclaw\workspace'
New-Item -ItemType Directory -Force -Path $ws,(Join-Path $ws 'tools')|Out-Null
function Get-GH($p){
  $raw=gh api "repos/hessmodee/KEVIN-WORK/contents/$p" --jq .content
  if(-not $raw){throw "empty $p"}
  [Convert]::FromBase64String(($raw -replace "`n",''))
}
[IO.File]::WriteAllBytes((Join-Path $ws 'pull-inbox.ps1'), (Get-GH 'omen/pull-inbox.ps1'))
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ws 'pull-inbox.ps1')
```

Expected after that pull: invocation `471E5051…`, builder `93A8A881…`, `reports/invocations/latest-public-reject.json` with a real reason-code (`STAGE_OK_WAITING_ACTION_ERA` or `PRESERVED_PROOF_MANIFEST_MISMATCH` or similar), bridge `puller=v1.3`. Then let Supervisor re-select `owner-west-motor-parts-chase-fresh-8-v1`. Keep the 09:31 burned turn. Do not send that job to `fixed:main`.

PASS = workbook + note + DONE + hashes + immutable receipt. A merge, CI, paste, diagnose, or repair script is not PASS.

Desktop: launch ≠ operate. Exact-five does not type into Calculator or Notepad. Do not claim app use without a same-turn receipt.

HQ Tools `UNVERIFIED` is a 2-day-stale canary, not missing tools. Do not widen the allowlist to paint it.
