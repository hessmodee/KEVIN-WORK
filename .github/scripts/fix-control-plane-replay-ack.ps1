$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
$p='control-plane/intake/kevin-work-order-intake-v0.1.ps1'
$t=Get-Content -LiteralPath $p -Raw
$old="if(Is-Replay `$ledger `$oIdem){`$ack.status='REPLAY_IGNORED';`$ack.detail='Idempotency key already processed.';Write-JsonAtomic `$ack `$LatestPath;Publish-Ack `$ack;Write-Output 'WORK_ORDER_REPLAY_IGNORED';exit 0}"
$new="if(Is-Replay `$ledger `$oIdem){Write-Output 'WORK_ORDER_REPLAY_IGNORED';exit 0}"
if(([regex]::Matches($t,[regex]::Escape($old))).Count -ne 1){throw 'Expected exactly one replay acknowledgement block.'}
$t=$t.Replace($old,$new)
[IO.File]::WriteAllText($p,$t,(New-Object Text.UTF8Encoding($false)))
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $p),[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count){$errors|ForEach-Object{Write-Error ("line {0}: {1}" -f $_.Extent.StartLineNumber,$_.Message)};throw 'Replay-fix intake parser failed.'}
Write-Host 'PASS replay acknowledgement fix.'
