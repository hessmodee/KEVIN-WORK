# Expired manifest regression design brief

**WorkInstance:** autonomy-expired-manifest-regression-design-fresh-2026-09-11-v1
**Predecessor:** autonomy-expired-manifest-regression-design-v1 (BOUNDED evidence; no history reset)
**Actor staging:** GROKBOT_ACTED (Lab prove path; not Kevin-learned)
**Notepad:** banned
**Primitives:** create_spreadsheet + create_text only
**Production write:** NONE in this research item

## Goal
Confirm Maintenance refuses expired canonical manifests before execution, then design the smallest fail-closed change so expired/terminal input stays non-executable but records a truthful auditable idle/terminal result instead of poisoning scheduled cron health.

## Tests (deterministic)
1. EXPIRED â€” no exec; idle/terminal expired receipt
2. DUPLICATE/TERMINAL â€” no exec; terminal duplicate
3. MALFORMED â€” fail closed with reason-code
4. VALID â€” still executes
5. Preserve rollback + exact-current/exact-after identity + Benchmark gates for later promotion

## Out of scope
No production Maintenance patch apply in this WI. Downstream consumer applies after design acceptance.