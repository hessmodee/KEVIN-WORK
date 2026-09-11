# Design — BLOCKED_INVOCATION honesty
**Target:** `docs/hq-owner-refinement-v3.js` Command hero · Attention · Superv chip (compose; no pin changes)  
**Themes:** ground-truth · invoke fail-closed · Matt control · no celebration fluff  
**Extends:** truth() BLOCKED/WAITING family · celebration guard (#129) · Self-Reliance Bridge Recovery v1  
**Banned:** HESS-PC operate · Minecraft · #122–#133 redos · Supervisor/ControlPlane pin changes · Cos-WASD

## Problem
When continuation is `BLOCKED_INVOCATION_RUNTIME` (or public-reject `failure_sha256` maps to `INVOCATION_WORKER_FAILED`), HQ can still read as READY / soft-DEGRADED / celebrate idle. Matt needs hard **BLOCKED** paint + a short reason chip so west-motor / autonomy recovery is visible — not green fluff.

## Signals (public only)
| Source | Field | Meaning |
|--------|-------|---------|
| `autonomy-continuation-latest` / `cache.continuation` | `status` | `BLOCKED_INVOCATION_RUNTIME` → BLOCKED |
| `reports/invocations/latest-public-reject.json` | `failure_sha256` | Prefix/family `68845506…` → `INVOCATION_WORKER_FAILED` |
| same reject / continuation | `reason` / `reject_reason` / sticky `RequestId` family | Short reason chip text |
| diagnose | `STAGE_OK_WAITING_ACTION_ERA` (+ `supervisor_request_id_reason=STAGE_OK`) | Waiting Supervisor — **still not PASS** |

## Pure API — `invocationHonesty(input)`
```js
invocationHonesty({
  continuationStatus,   // string
  failureSha256,        // string | null
  rejectReason,         // string | null  (public reject / typed reason)
  stickyRequestIdFamily,// string | null
  celebrateAllowedHint  // optional bool from ops-fun path
}) → {
  paint,        // 'BLOCKED' | 'WAITING' | 'READY'
  cls,          // 'bad' | 'warn' | 'ok'
  stateLabel,   // Command .v3state text
  reasonChip,   // short chip: worker exit | fail-closed | sticky RequestId | …
  celebrate,    // always false when paint !== 'READY'
  isPass,       // always false unless paint==='READY' AND no blocked family
  note          // honesty note (STAGE_OK ≠ Action Era ≠ PASS)
}
```

### Rules (first match wins for paint)
1. If `continuationStatus` matches `/BLOCKED_INVOCATION/` **OR** `failureSha256` maps to `INVOCATION_WORKER_FAILED`  
   → `paint='BLOCKED'`, `cls='bad'`, `stateLabel='BLOCKED'`, `celebrate=false`, `isPass=false`
2. Else if status matches `/STAGE_OK_WAITING|WAITING_ACTION_ERA|WAITING_/i` (incl. `STAGE_OK_WAITING_ACTION_ERA`)  
   → `paint='WAITING'`, `cls='warn'`, `stateLabel='BLOCKED · waiting'`, **still not PASS**, `celebrate=false`
3. Else if status matches `/^(BLOCKED|NEEDS_|DEFERRED|COOLDOWN)/`  
   → `paint='BLOCKED'`, `cls='warn'`, `celebrate=false`
4. Else → `paint='READY'`, `cls='ok'` (only when no blocked/waiting family)

### Reason chip (short, public)
Priority:
1. sticky RequestId family if present → `sticky · <family>`
2. else if worker-failed family → `worker exit · fail-closed`
3. else if STAGE_OK waiting → `STAGE_OK · wait Supervisor`
4. else rejectReason truncated ≤48 chars
5. else `fail-closed`

### Honesty gates
- **Never** paint READY / WORKING / celebration when BLOCKED_INVOCATION or worker-failed sha.
- **DEGRADED-as-ok forbidden** — if continuation is blocked/waiting, cls is warn/bad, not ok.
- **Isolated STAGE_OK ≠ Action Era ≠ PASS** — waiting chip must not claim PROVEN/PASS/DONE.
- Do not recopy Supervisor / change pins from HQ — CoS owns HESS runtime paste.

## UI chrome (when applied)
```text
┌ COMMAND · RIGHT NOW                          ┐
│ BLOCKED                                      │  ← .v3state bad (not READY)
│ Invoke fail-closed · worker exit             │
│ [reason chip] sticky · RequestId family …    │
│ Attention: BLOCKED_INVOCATION_RUNTIME        │
└──────────────────────────────────────────────┘
```
- Superv chip: show status verbatim + freshness (P1-4) — do not rewrite to READY.
- Celebration: force `celebrationAllowed=false` when paint≠READY (compose #129).

## Compose, do not redo
- Owl honesty (#126) — starve WORKING; this packet owns invoke BLOCKED paint.
- Celebration guard (#129) — call with blocked-aware proof / explicit flag.
- Four-number hero — TRUST/ATTN compose; this owns invocation status honesty.
- CoS owns HESS FROM_GROK paste — HQ box draft only.

## Test
`test-blocked-invocation-honesty.cjs` + fixtures BLOCKED_INVOCATION · STAGE_OK_WAITING · HEALTHY_READY.
