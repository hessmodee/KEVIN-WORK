# P0 — Tools CANARY STALE honesty
**Updated:** 2026-09-11 13:46 MT  
**Owner:** Kevin HQ (box draft). CoS owns HESS runtime paste.  
**Status:** READY_FOR_HQ_SHIP (design + fixtures + pure test PASS)  
**Not a redo of:** #127 P1-4 pulse freshness (complements — canary-specific) · #122–#133

## TLDR
Surface **Tools CANARY STALE** honestly on Command/System/pulse chips. Never imply tools **ON** when canary/evidence is stale or missing. Complements P1-4; does not redo #127.

## Why (for Matt)
`brain.tools=true` + aged/missing canary looks like hands are live. Autonomy / west-motor recovery needs fail-closed Tools truth.

## Deliverables
| Path | Role |
|------|------|
| `DESIGN.md` | Canary gate + implyOn honesty |
| `fixtures/` | TOOLS_ON_FRESH · TOOLS_CANARY_STALE · TOOLS_OFF |
| `test-tools-canary-stale.cjs` | Pure `toolsCanaryHonesty()` |

Companion proposal: `proposals/2026-09-11-hq-blocked-canary-honesty-v1.md`

## Acceptance
- [x] TOOLS_ON_FRESH → ON · implyOn true
- [x] TOOLS_CANARY_STALE → CANARY STALE · implyOn false
- [x] TOOLS_OFF → OFF · implyOn false
- [x] `node test-tools-canary-stale.cjs` PASS
- [x] No redo of #127 gate table · no HESS-PC · no Minecraft · no pin changes

## Forbidden
Redo #127 · HESS-PC operate · Minecraft · Supervisor/ControlPlane pin changes · invent tools ON under stale canary
