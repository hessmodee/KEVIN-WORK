# P0 — BLOCKED_INVOCATION honesty
**Updated:** 2026-09-11 13:46 MT  
**Owner:** Kevin HQ (box draft). CoS owns HESS runtime paste.  
**Status:** READY_FOR_HQ_SHIP (design + fixtures + pure test PASS)  
**Not a redo of:** #122–#133 · P1-4 chips · celebration guard (#129) · Realtime Truth Wave

## TLDR
When continuation is `BLOCKED_INVOCATION_RUNTIME` (or `failure_sha256` → `INVOCATION_WORKER_FAILED`), Command/Attention must paint **BLOCKED** — not READY, not DEGRADED-as-ok, no celebration. Short reason chip: worker exit / fail-closed / sticky RequestId family. **Isolated STAGE_OK ≠ Action Era ≠ PASS.**

## Why (for Matt)
Invoke fail-closed is real west-motor / autonomy ground truth. Soft-green HQ hides the blocker Kevin must recover (pull-inbox / sticky / diagnose) without Matt babysitting.

## Deliverables
| Path | Role |
|------|------|
| `DESIGN.md` | Paint rules + reason chip + STAGE_OK honesty |
| `fixtures/` | BLOCKED_INVOCATION · STAGE_OK_WAITING · HEALTHY_READY |
| `test-blocked-invocation-honesty.cjs` | Pure `invocationHonesty()` |

Companion proposal: `proposals/2026-09-11-hq-blocked-canary-honesty-v1.md`

## Acceptance
- [x] BLOCKED_INVOCATION → paint BLOCKED · cls bad · celebrate false
- [x] STAGE_OK_WAITING → WAITING/BLOCKED-waiting · still not PASS
- [x] HEALTHY_READY → READY · ok
- [x] Reason chip prefers sticky RequestId / worker exit · fail-closed
- [x] `node test-blocked-invocation-honesty.cjs` PASS
- [x] No HESS-PC operate · no Minecraft · no pin changes

## Forbidden
Redo #122–#133 · HESS-PC operate · Minecraft · Supervisor/ControlPlane pin changes · invent PASS from STAGE_OK
