# LESSON — artifact audit mirror + UTF-8 order read (2026-09-11)
**Actor:** GROKBOT_ACTED · **Not PASS**
**Family:** invocation-worker-fail-closed-v1

## Fixes landed (local HESS)
1. `kevin-green-operator.ps1` copies DONE outputs into `reports/invocations/artifacts/` (hash-checked) so reconcile ArtifactRoot sees bytes.
2. Worker v1.1.1 `Sync-DoneArtifactsToAuditRoot` before reconcile (defense in depth). Does not overwrite GitHub pin 16C49542.
3. Green operator `Get-Content -Encoding UTF8` for order JSON — PS 5.1 default encoding was mojibaking em-dash in note payload → FINAL_ORDER_CORRELATION_MISMATCH (req U+2014 vs DONE UTF-8-as-Latin1).

## Quarantine exception
Correlationally-invalid DONE `invoke-invoke-owner-west-motor-parts-chase-fresh-8-v1-s0N` moved to `reports/invocations/quarantine/` so same order ids can re-stage with UTF-8-correct payloads. Not a PROVEN receipt. Burned turn 09:31 preserved. No receipt deleted.

## Next
Supervisor/worker re-select same WI → fresh create_* → mirror → reconcile → VERIFY for PASS.
